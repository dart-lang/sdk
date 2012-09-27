// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"

#include "include/dart_api.h"

void FUNCTION_NAME(Common_IsBuiltinList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle list = Dart_GetNativeArgument(args, 0);
  Dart_Handle list_class = Dart_InstanceGetClass(list);
  ASSERT(!Dart_IsError(list_class));
  Dart_Handle coreimpl_lib =
      Dart_LookupLibrary(Dart_NewString("dart:coreimpl"));
  ASSERT(!Dart_IsError(coreimpl_lib));
  Dart_Handle object_array_class =
      Dart_GetClass(coreimpl_lib, Dart_NewString("_ObjectArray"));
  ASSERT(!Dart_IsError(object_array_class));
  Dart_Handle immutable_array_class =
      Dart_GetClass(coreimpl_lib, Dart_NewString("_ImmutableArray"));
  ASSERT(!Dart_IsError(immutable_array_class));
  // TODO(5474): We should be able to allow _GrowableObjectArrays here as well.
  bool builtin_array = (Dart_IdentityEquals(list_class, object_array_class) ||
                        Dart_IdentityEquals(list_class, immutable_array_class));
  Dart_SetReturnValue(args, Dart_NewBoolean(builtin_array));
  Dart_ExitScope();
}
