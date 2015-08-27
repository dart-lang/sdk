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
#include "vm/service.h"

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


DEFINE_NATIVE_ENTRY(Developer_inspect, 1) {
  GET_NATIVE_ARGUMENT(Instance, inspectee, arguments->NativeArgAt(0));
  Service::SendInspectEvent(isolate, inspectee);
  return inspectee.raw();
}


DEFINE_NATIVE_ENTRY(Developer_log, 8) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, message, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, timestamp, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, sequence, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, level, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(Instance, dart_zone, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(Instance, error, arguments->NativeArgAt(6));
  GET_NATIVE_ARGUMENT(Instance, stack_trace, arguments->NativeArgAt(7));
  Service::SendLogEvent(isolate,
                        sequence.AsInt64Value(),
                        timestamp.AsInt64Value(),
                        level.Value(),
                        name,
                        message,
                        dart_zone,
                        error,
                        stack_trace);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Developer_lookupExtension, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  return isolate->LookupServiceExtensionHandler(name);
}


DEFINE_NATIVE_ENTRY(Developer_registerExtension, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, handler, arguments->NativeArgAt(1));
  isolate->RegisterServiceExtensionHandler(name, handler);
  return Object::null();
}

}  // namespace dart
