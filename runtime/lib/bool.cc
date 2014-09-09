// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
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
  const String& env_value =
      String::Handle(Api::CallEnvironmentCallback(isolate, name));
  if (!env_value.IsNull()) {
    if (Symbols::True().Equals(env_value)) {
      return Bool::True().raw();
    }
    if (Symbols::False().Equals(env_value)) {
      return Bool::False().raw();
    }
  }
  return default_value.raw();
}

}  // namespace dart
