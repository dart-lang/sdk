// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_IO_DISABLED)

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Filter_CreateZLibInflate)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "ZLibInflater and Deflater not supported on this platform"));
}

void FUNCTION_NAME(Filter_CreateZLibDeflate)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "ZLibInflater and Deflater not supported on this platform"));
}

void FUNCTION_NAME(Filter_Process)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "ZLibInflater and Deflater not supported on this platform"));
}

void FUNCTION_NAME(Filter_Processed)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewInternalError(
      "ZLibInflater and Deflater not supported on this platform"));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_IO_DISABLED)
