// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_GZIP_H_
#define RUNTIME_BIN_GZIP_H_

#include "platform/globals.h"

namespace dart {
namespace bin {

// |input| is assumed to be a gzipped stream.
// This function allocates the output buffer in the C heap and the caller
// is responsible for freeing it.
void Decompress(const uint8_t* input,
                intptr_t input_len,
                uint8_t** output,
                intptr_t* output_length);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_GZIP_H_
