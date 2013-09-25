// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(IOService_NewServicePort)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartArgumentError(
      "IOService is unsupported on this platform"));
}

}  // namespace bin
}  // namespace dart

