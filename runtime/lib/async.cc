// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_NATIVE_ENTRY(AsyncStarMoveNext_debuggerStepCheck, 1) {
#if !defined(PRODUCT)
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, async_op, arguments->NativeArgAt(0));
  Debugger* debugger = isolate->debugger();
  if (debugger != NULL) {
    debugger->MaybeAsyncStepInto(async_op);
  }
#endif
  return Object::null();
}

}  // namespace dart
