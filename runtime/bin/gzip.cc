// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/gzip.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "zlib/zlib.h"

namespace dart {
namespace bin {

void Decompress(const uint8_t* input,
                intptr_t input_len,
                uint8_t** output,
                intptr_t* output_length) {
  ASSERT(input != NULL);
  ASSERT(input_len > 0);
  ASSERT(output != NULL);
  ASSERT(output_length != NULL);

  const intptr_t kChunkSize = 256 * 1024;

  // Initialize output.
  intptr_t output_capacity = input_len * 2;
  if (output_capacity < kChunkSize) {
    output_capacity = kChunkSize;
  }
  *output = reinterpret_cast<uint8_t*>(malloc(output_capacity));

  uint8_t chunk_out[kChunkSize];
  z_stream strm;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.avail_in = 0;
  strm.next_in = 0;
  int ret = inflateInit2(&strm, 32 + MAX_WBITS);
  ASSERT(ret == Z_OK);

  intptr_t input_cursor = 0;
  intptr_t output_cursor = 0;
  do {
    // Setup input.
    intptr_t size_in = input_len - input_cursor;
    if (size_in > kChunkSize) {
      size_in = kChunkSize;
    }
    strm.avail_in = size_in;
    strm.next_in = const_cast<uint8_t*>(&input[input_cursor]);

    // Inflate until we've exhausted the current input chunk.
    do {
      // Setup output.
      strm.avail_out = kChunkSize;
      strm.next_out = &chunk_out[0];
      // Inflate.
      ret = inflate(&strm, Z_SYNC_FLUSH);
      // We either hit the end of the stream or made forward progress.
      ASSERT((ret == Z_STREAM_END) || (ret == Z_OK));
      // Grow output buffer size.
      intptr_t size_out = kChunkSize - strm.avail_out;
      if (size_out > (output_capacity - output_cursor)) {
        output_capacity *= 2;
        ASSERT(size_out <= (output_capacity - output_cursor));
        *output = reinterpret_cast<uint8_t*>(realloc(*output, output_capacity));
      }
      // Copy output.
      memmove(&((*output)[output_cursor]), &chunk_out[0], size_out);
      output_cursor += size_out;
    } while (strm.avail_out == 0);

    // We've processed size_in bytes.
    input_cursor += size_in;

    // We're finished decompressing when zlib tells us.
  } while (ret != Z_STREAM_END);

  inflateEnd(&strm);

  *output_length = output_cursor;
}

}  // namespace bin
}  // namespace dart
