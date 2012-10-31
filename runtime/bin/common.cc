// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/isolate_data.h"
#include "include/dart_api.h"

void FUNCTION_NAME(Common_IsBuiltinList)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle list = Dart_GetNativeArgument(args, 0);
  Dart_Handle list_class = Dart_InstanceGetClass(list);
  ASSERT(!Dart_IsError(list_class));

  // Fetch the cached builtin array types for this isolate.
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  Dart_Handle object_array_class = isolate_data->object_array_class;
  Dart_Handle growable_object_array_class =
      isolate_data->growable_object_array_class;
  Dart_Handle immutable_array_class = isolate_data->immutable_array_class;

  // If we have not cached the class pointers in the isolate data,
  // look them up and cache them now.
  if (object_array_class == NULL) {
    Dart_Handle core_lib =
        Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
    ASSERT(!Dart_IsError(core_lib));
    object_array_class =
        Dart_GetClass(core_lib, Dart_NewStringFromCString("_ObjectArray"));
    ASSERT(!Dart_IsError(object_array_class));
    immutable_array_class =
        Dart_GetClass(core_lib, Dart_NewStringFromCString("_ImmutableArray"));
    ASSERT(!Dart_IsError(immutable_array_class));
    growable_object_array_class = Dart_GetClass(
        core_lib, Dart_NewStringFromCString("_GrowableObjectArray"));
    ASSERT(!Dart_IsError(growable_object_array_class));
    // Update the cache.
    isolate_data->object_array_class =
        Dart_NewPersistentHandle(object_array_class);
    ASSERT(!Dart_IsError(isolate_data->object_array_class));
    isolate_data->growable_object_array_class =
        Dart_NewPersistentHandle(growable_object_array_class);
    ASSERT(!Dart_IsError(isolate_data->growable_object_array_class));
    isolate_data->immutable_array_class =
        Dart_NewPersistentHandle(immutable_array_class);
    ASSERT(!Dart_IsError(isolate_data->immutable_array_class));
  }

  bool builtin_array =
      (Dart_IdentityEquals(list_class, growable_object_array_class) ||
       Dart_IdentityEquals(list_class, object_array_class) ||
       Dart_IdentityEquals(list_class, immutable_array_class));
  Dart_SetReturnValue(args, Dart_NewBoolean(builtin_array));
  Dart_ExitScope();
}
