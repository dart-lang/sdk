// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_CONCURRENT_NATIVES_H_
#define RUNTIME_BIN_CONCURRENT_NATIVES_H_

#include "include/dart_api.h"

namespace dart {
namespace bin {

Dart_NativeFunction ConcurrentNativeLookup(Dart_Handle name,
                                           int argument_count,
                                           bool* auto_setup_scope);

const uint8_t* ConcurrentNativeSymbol(Dart_NativeFunction nf);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_CONCURRENT_NATIVES_H_
