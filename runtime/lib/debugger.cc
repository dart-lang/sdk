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

// dart:debugger.

DEFINE_NATIVE_ENTRY(Debugger_breakHere, 0) {
  Debugger* debugger = isolate->debugger();
  if (!debugger) {
    return Object::null();
  }
  debugger->BreakHere();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Debugger_breakHereIf, 1) {
  Debugger* debugger = isolate->debugger();
  if (!debugger) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, expr, arguments->NativeArgAt(0));
  if (expr.value()) {
    debugger->BreakHere();
  }
  return Object::null();
}


}  // namespace dart
