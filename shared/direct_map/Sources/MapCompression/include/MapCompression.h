#include <stddef.h>
#include <stdint.h>
// Returns 0 on success. Rejects truncation, trailing streams and output bombs.
int mn_map_gunzip(const uint8_t *input, size_t count, uint8_t *output, size_t capacity, size_t *written);
