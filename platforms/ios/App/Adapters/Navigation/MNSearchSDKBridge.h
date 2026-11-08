#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Device-only AMap calls. No SDK manager is created before explicit consent.
@interface MNSearchSDKBridge : NSObject
@property(class, nonatomic, readonly) BOOL available;
- (instancetype)initWithAPIKey:(NSString *)key NS_SWIFT_NAME(init(apiKey:));
- (void)search:(NSString *)keywords longitude:(double)longitude latitude:(double)latitude
    completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion
    NS_SWIFT_NAME(search(keywords:longitude:latitude:completion:));
- (void)routesFromLongitude:(double)originLongitude latitude:(double)originLatitude
    toLongitude:(double)destinationLongitude latitude:(double)destinationLatitude
    completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion
    NS_SWIFT_NAME(routes(originLongitude:originLatitude:destinationLongitude:destinationLatitude:completion:));
- (void)invalidate;
- (void)districts:(NSString *)keywords completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion
    NS_SWIFT_NAME(districts(keywords:completion:));
@end
NS_ASSUME_NONNULL_END
