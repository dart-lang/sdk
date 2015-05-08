// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

// Native implementations for the dart:developer library.

DEFINE_NATIVE_ENTRY(Developer_debugger, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, when, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(String, msg, arguments->NativeArgAt(1));
  Debugger* debugger = isolate->debugger();
  if (!debugger) {
    return when.raw();
  }
  if (when.value()) {
    debugger->BreakHere(msg);
  }
  return when.raw();
}

}  // namespace dart
