// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Object_toString, 1) {
  const Instance& instance = Instance::CheckedHandle(arguments->At(0));
  const char* c_str = instance.ToCString();
  arguments->SetReturn(String::Handle(String::New(c_str)));
}


DEFINE_NATIVE_ENTRY(Object_noSuchMethod, 3) {
  const Instance& instance = Instance::CheckedHandle(arguments->At(0));
  if (instance.IsNull()) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kNullPointer, args);
  }
  GET_NATIVE_ARGUMENT(String, function_name, arguments->At(1));
  GET_NATIVE_ARGUMENT(Array, func_args, arguments->At(2));
  GrowableArray<const Object*> dart_arguments(3);
  dart_arguments.Add(&instance);
  dart_arguments.Add(&function_name);
  dart_arguments.Add(&func_args);
  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, dart_arguments);
}

}  // namespace dart
