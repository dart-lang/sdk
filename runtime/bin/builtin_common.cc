// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/platform.h"

// Return the error from the containing function if handle is in error handle.
#define RETURN_IF_ERROR(handle)                                                \
  {                                                                            \
    Dart_Handle __handle = handle;                                             \
    if (Dart_IsError((__handle))) {                                            \
      return __handle;                                                         \
    }                                                                          \
  }

namespace dart {
namespace bin {

Dart_Handle Builtin::SetLoadPort(Dart_Port port) {
  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  RETURN_IF_ERROR(builtin_lib);
  // Set the _isolateId field.
  Dart_Handle result =
      Dart_SetField(builtin_lib, DartUtils::NewString("_isolateId"),
                    Dart_NewInteger(Dart_GetMainPortId()));
  RETURN_IF_ERROR(result);
  load_port_ = port;
  ASSERT(load_port_ != ILLEGAL_PORT);
  Dart_Handle field_name = DartUtils::NewString("_loadPort");
  RETURN_IF_ERROR(field_name);
  Dart_Handle send_port = Dart_GetField(builtin_lib, field_name);
  RETURN_IF_ERROR(send_port);
  if (!Dart_IsNull(send_port)) {
    // Already created and set.
    return Dart_True();
  }
  send_port = Dart_NewSendPort(load_port_);
  RETURN_IF_ERROR(send_port);
  result = Dart_SetField(builtin_lib, field_name, send_port);
  RETURN_IF_ERROR(result);
  return Dart_True();
}

}  // namespace bin
}  // namespace dart
