#include "MapCompression.h"
#include <limits.h>
#include <string.h>
#include <zlib.h>
int mn_map_gunzip(const uint8_t *input,size_t count,uint8_t *output,size_t capacity,size_t *written) {
    if(!input||!output||!written||count>UINT_MAX||capacity>UINT_MAX)return -1;
    z_stream stream;memset(&stream,0,sizeof(stream));
    stream.next_in=(Bytef *)input;stream.avail_in=(uInt)count;
    stream.next_out=output;stream.avail_out=(uInt)capacity;
    if(inflateInit2(&stream,15+16)!=Z_OK)return -1;
    int status=inflate(&stream,Z_FINISH);
    int ok=status==Z_STREAM_END&&stream.avail_in==0;
    *written=stream.total_out;inflateEnd(&stream);return ok?0:-1;
}
