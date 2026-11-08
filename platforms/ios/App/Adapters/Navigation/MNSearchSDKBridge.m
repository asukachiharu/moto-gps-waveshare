#import "MNSearchSDKBridge.h"
#import <TargetConditionals.h>
#import <math.h>
#if !TARGET_OS_SIMULATOR && __has_include(<AMapNaviKit/AMapNaviKit.h>)
#define MOTO_REAL_SEARCH 1
#import <AMapNaviKit/AMapNaviKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
@interface MNSearchSDKBridge () <AMapSearchDelegate>
@property(nonatomic, strong) AMapSearchAPI *searcher;
@property(nonatomic, strong) NSMutableDictionary<NSValue *, id> *pending;
@end
#endif

static NSError *MotoSDKError(NSInteger code) {
    return [NSError errorWithDomain:@"MotoGPS.AMapSDK" code:code userInfo:@{NSLocalizedDescriptionKey:
        [NSString stringWithFormat:@"高德 SDK 请求未完成（%ld）", (long)code]}];
}
@implementation MNSearchSDKBridge
+ (BOOL)available {
#ifdef MOTO_REAL_SEARCH
    return YES;
#else
    return NO;
#endif
}
- (instancetype)initWithAPIKey:(NSString *)key {
    self = [super init];
#ifdef MOTO_REAL_SEARCH
    if (self) {
        [AMapSearchAPI updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
        [AMapSearchAPI updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
        [AMapServices sharedServices].apiKey = key;
        _pending = [NSMutableDictionary dictionary];
        _searcher = [[AMapSearchAPI alloc] init]; _searcher.delegate = self;
    }
#endif
    return self;
}
#ifdef MOTO_REAL_SEARCH
- (BOOL)registerRequest:(id)request completion:(void (^)(NSData *, NSError *))completion {
    if (self.pending.count >= 8) { completion(nil, MotoSDKError(-2)); return NO; }
    NSValue *token = [NSValue valueWithNonretainedObject:request];
    self.pending[token] = [completion copy];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        MNSearchSDKBridge *owner = weakSelf;
        // Retain the request through the deadline so its pointer cannot be
        // reused by another request before an older timeout fires.
        NSValue *timeoutToken = [NSValue valueWithNonretainedObject:request];
        void (^callback)(NSData *, NSError *) = owner.pending[timeoutToken];
        [owner.pending removeObjectForKey:timeoutToken];
        if (callback) callback(nil, MotoSDKError(-1001));
    });
    return YES;
}
- (void)completeRequest:(id)request object:(id)object error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSValue *token = [NSValue valueWithNonretainedObject:request];
        void (^callback)(NSData *, NSError *) = self.pending[token];
        [self.pending removeObjectForKey:token];
        if (!callback) return;
        NSError *failure = error;
        NSData *data = object ? [NSJSONSerialization dataWithJSONObject:object options:0 error:nil] : nil;
        if (data.length > 2000000) { data = nil; failure = MotoSDKError(-3); }
        callback(data, failure ?: (data ? nil : MotoSDKError(-4)));
    });
}
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    [self completeRequest:request object:nil error:MotoSDKError(error.code)];
}
#endif
- (void)invalidate {
#ifdef MOTO_REAL_SEARCH
    NSArray *callbacks = self.pending.allValues;
    [self.pending removeAllObjects]; self.searcher.delegate = nil;
    for (id block in callbacks) {
        void (^callback)(NSData *, NSError *) = block;
        callback(nil, MotoSDKError(NSURLErrorCancelled));
    }
#endif
}
- (void)search:(NSString *)keywords longitude:(double)longitude latitude:(double)latitude
    completion:(void (^)(NSData *, NSError *))completion {
#ifdef MOTO_REAL_SEARCH
    AMapPOIKeywordsSearchRequest *request = [[AMapPOIKeywordsSearchRequest alloc] init];
    request.keywords = keywords; request.offset = 20; request.page = 1;
    if (isfinite(longitude) && isfinite(latitude)) {
        CLLocationCoordinate2D point = AMapCoordinateConvert(CLLocationCoordinate2DMake(latitude, longitude), AMapCoordinateTypeGPS);
        request.location = [AMapGeoPoint locationWithLatitude:point.latitude longitude:point.longitude];
        request.sortrule = 0;
    }
    if ([self registerRequest:request completion:completion]) [self.searcher AMapPOIKeywordsSearch:request];
#else
    completion(nil, MotoSDKError(-1));
#endif
}
- (void)routesFromLongitude:(double)originLongitude latitude:(double)originLatitude
    toLongitude:(double)destinationLongitude latitude:(double)destinationLatitude
    completion:(void (^)(NSData *, NSError *))completion {
#ifdef MOTO_REAL_SEARCH
    CLLocationCoordinate2D start = AMapCoordinateConvert(CLLocationCoordinate2DMake(originLatitude, originLongitude), AMapCoordinateTypeGPS);
    CLLocationCoordinate2D end = AMapCoordinateConvert(CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude), AMapCoordinateTypeGPS);
    AMapDrivingRouteSearchRequest *request = [[AMapDrivingRouteSearchRequest alloc] init];
    request.origin = [AMapGeoPoint locationWithLatitude:start.latitude longitude:start.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:end.latitude longitude:end.longitude];
    request.strategy = 10; request.requireExtension = YES;
    if ([self registerRequest:request completion:completion]) [self.searcher AMapDrivingRouteSearch:request];
#else
    completion(nil, MotoSDKError(-1));
#endif
}
- (void)districts:(NSString *)keywords completion:(void (^)(NSData *, NSError *))completion {
#ifdef MOTO_REAL_SEARCH
    AMapDistrictSearchRequest *request = [[AMapDistrictSearchRequest alloc] init];
    request.keywords = keywords; request.requireExtension = YES; request.subdistrict = 0;
    if ([self registerRequest:request completion:completion]) [self.searcher AMapDistrictSearch:request];
#else
    completion(nil, MotoSDKError(-1));
#endif
}
#ifdef MOTO_REAL_SEARCH
- (void)onDistrictSearchDone:(AMapDistrictSearchRequest *)request response:(AMapDistrictSearchResponse *)response {
    NSMutableArray *districts = [NSMutableArray array];
    NSUInteger bytes = 0;
    for (AMapDistrict *district in response.districts) {
        if (districts.count >= 20) break;
        if (![district.level isEqualToString:@"city"] && ![district.level isEqualToString:@"district"] &&
            ![district.level isEqualToString:@"province"]) continue;
        for (NSString *ring in district.polylines) bytes += [ring lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        if (bytes > 1500000) { [self completeRequest:request object:nil error:MotoSDKError(-3)]; return; }
        [districts addObject:@{@"id":district.adcode ?: @"", @"name":district.name ?: @"",
            @"level":district.level ?: @"", @"polylines":district.polylines ?: @[]}];
    }
    [self completeRequest:request object:districts error:nil];
}
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    NSMutableArray *places = [NSMutableArray array];
    for (AMapPOI *poi in response.pois) {
        if (places.count >= 20) break;
        if (!poi.location) continue;
        [places addObject:@{@"id":poi.uid ?: @"", @"name":poi.name ?: @"", @"address":poi.address ?: @"",
            @"city":poi.city ?: @"", @"district":poi.district ?: @"",
            @"longitude":@(poi.location.longitude), @"latitude":@(poi.location.latitude)}];
    }
    [self completeRequest:request object:places error:nil];
}
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response {
    NSMutableArray *paths = [NSMutableArray array];
    for (AMapPath *path in response.route.paths) {
        if (paths.count >= 3) break;
        if (path.steps.count > 4096 || path.distance <= 0 || path.duration <= 0) continue;
        NSMutableArray *steps = [NSMutableArray array];
        NSUInteger geometryBytes = 0;
        for (AMapStep *step in path.steps) {
            geometryBytes += [step.polyline lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (geometryBytes > 1500000) break;
            NSMutableArray *traffic = [NSMutableArray array];
            for (AMapTMC *tmc in step.tmcs) {
                if (traffic.count >= 4096) break;
                [traffic addObject:@{@"distance":@(tmc.distance), @"status":tmc.status ?: @"未知"}];
            }
            [steps addObject:@{@"distance":@(step.distance), @"polyline":step.polyline ?: @"",
                @"road":step.road ?: @"", @"instruction":step.instruction ?: @"",
                @"action":step.action ?: @"", @"assistant":step.assistantAction ?: @"", @"traffic":traffic}];
        }
        if (geometryBytes <= 1500000) [paths addObject:@{@"distance":@(path.distance), @"duration":@(path.duration), @"steps":steps}];
    }
    [self completeRequest:request object:paths error:nil];
}
#endif
@end
