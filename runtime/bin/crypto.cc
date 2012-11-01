// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/crypto.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


void FUNCTION_NAME(Crypto_GetRandomBytes)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle count_obj = Dart_GetNativeArgument(args, 0);
  int64_t count = 0;
  if (!DartUtils::GetInt64Value(count_obj, &count)) {
    Dart_Handle error =
        DartUtils::NewString("Invalid argument, must be an int.");
    Dart_ThrowException(error);
  }
  uint8_t* buffer = new uint8_t[count];
  ASSERT(buffer != NULL);
  if (!Crypto::GetRandomBytes(count, buffer)) {
    delete[] buffer;
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
  Dart_Handle result = Dart_NewByteArray(count);
  if (Dart_IsError(result)) {
    delete[] buffer;
    Dart_Handle error = DartUtils::NewString("Failed to allocate storage.");
    Dart_ThrowException(error);
  }
  Dart_ListSetAsBytes(result, 0, buffer, count);
  Dart_SetReturnValue(args, result);
  delete[] buffer;
  Dart_ExitScope();
}
