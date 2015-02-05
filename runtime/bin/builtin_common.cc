// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/platform.h"

namespace dart {
namespace bin {

void Builtin::SetLoadPort(Dart_Port port) {
  load_port_ = port;
  ASSERT(load_port_ != ILLEGAL_PORT);
  Dart_Handle field_name = DartUtils::NewString("_loadPort");
  ASSERT(!Dart_IsError(field_name));
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  ASSERT(!Dart_IsError(builtin_lib));
  Dart_Handle send_port = Dart_GetField(builtin_lib, field_name);
  ASSERT(!Dart_IsError(send_port));
  if (!Dart_IsNull(send_port)) {
    // Already created and set.
    return;
  }
  send_port = Dart_NewSendPort(load_port_);
  ASSERT(!Dart_IsError(send_port));
  Dart_Handle result = Dart_SetField(builtin_lib, field_name, send_port);
  ASSERT(!Dart_IsError(result));
}

}  // namespace bin
}  // namespace dart
