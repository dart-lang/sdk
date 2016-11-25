// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/crypto.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(Crypto_GetRandomBytes)(Dart_NativeArguments args) {
  Dart_Handle count_obj = Dart_GetNativeArgument(args, 0);
  const int64_t kMaxRandomBytes = 4096;
  int64_t count64 = 0;
  if (!DartUtils::GetInt64Value(count_obj, &count64) || (count64 < 0) ||
      (count64 > kMaxRandomBytes)) {
    Dart_Handle error = DartUtils::NewString(
        "Invalid argument: count must be a positive int "
        "less than or equal to 4096.");
    Dart_ThrowException(error);
  }
  intptr_t count = static_cast<intptr_t>(count64);
  uint8_t* buffer = Dart_ScopeAllocate(count);
  ASSERT(buffer != NULL);
  if (!Crypto::GetRandomBytes(count, buffer)) {
    Dart_ThrowException(DartUtils::NewDartOSError());
    UNREACHABLE();
  }
  Dart_Handle result = Dart_NewTypedData(Dart_TypedData_kUint8, count);
  if (Dart_IsError(result)) {
    Dart_Handle error = DartUtils::NewString("Failed to allocate storage.");
    Dart_ThrowException(error);
    UNREACHABLE();
  }
  Dart_ListSetAsBytes(result, 0, buffer, count);
  Dart_SetReturnValue(args, result);
}

}  // namespace bin
}  // namespace dart
