// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(Stdin_ReadByte)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int c = getchar();
  if (c == EOF) {
    c = -1;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(c));
  Dart_ExitScope();
}

}  // namespace bin
}  // namespace dart
