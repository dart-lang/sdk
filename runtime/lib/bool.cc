// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
#include "vm/bigint_operations.h"
#include "vm/dart_entry.h"
#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
#include "vm/isolate.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Bool_fromEnvironment, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(Bool, default_value, arguments->NativeArgAt(2));
  // Call the embedder to supply us with the environment.
  Dart_EnvironmentCallback callback = isolate->environment_callback();
  if (callback != NULL) {
    Dart_Handle result = callback(Api::NewHandle(isolate, name.raw()));
    if (Dart_IsString(result)) {
      const char *chars;
      Dart_StringToCString(result, &chars);
      return (strcmp("true", chars) == 0)
          ? Bool::True().raw() : Bool::False().raw();
    } else if (Dart_IsError(result)) {
      const Object& error =
          Object::Handle(isolate, Api::UnwrapHandle(result));
      Exceptions::ThrowArgumentError(
          String::Handle(
              String::New(Error::Cast(error).ToErrorCString())));
    } else if (!Dart_IsNull(result)) {
      Exceptions::ThrowArgumentError(
          String::Handle(String::New("Illegal environment value")));
    }
  }
  return default_value.raw();
}

}  // namespace dart
