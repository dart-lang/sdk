// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/service.h"
#include "vm/service_isolate.h"

namespace dart {

// Native implementations for the dart:developer library.

DEFINE_NATIVE_ENTRY(Developer_debugger, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, when, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(String, msg, arguments->NativeArgAt(1));
  Debugger* debugger = isolate->debugger();
  if (!FLAG_support_debugger || !debugger) {
    return when.raw();
  }
  if (when.value()) {
    debugger->PauseDeveloper(msg);
  }
  return when.raw();
}


DEFINE_NATIVE_ENTRY(Developer_inspect, 1) {
  GET_NATIVE_ARGUMENT(Instance, inspectee, arguments->NativeArgAt(0));
  if (FLAG_support_service) {
    Service::SendInspectEvent(isolate, inspectee);
  }
  return inspectee.raw();
}


DEFINE_NATIVE_ENTRY(Developer_log, 8) {
  if (!FLAG_support_service) {
    return Object::null();
  }
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


DEFINE_NATIVE_ENTRY(Developer_postEvent, 2) {
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(String, event_kind, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, event_data, arguments->NativeArgAt(1));
  Service::SendExtensionEvent(isolate, event_kind, event_data);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Developer_lookupExtension, 1) {
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  return isolate->LookupServiceExtensionHandler(name);
}


DEFINE_NATIVE_ENTRY(Developer_registerExtension, 2) {
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, handler, arguments->NativeArgAt(1));
  // We don't allow service extensions to be registered for the
  // service isolate.  This can happen, for example, because the
  // service isolate uses dart:io.  If we decide that we want to start
  // supporting this in the future, it will take some work.
  if (!ServiceIsolate::IsServiceIsolateDescendant(isolate)) {
    isolate->RegisterServiceExtensionHandler(name, handler);
  }
  return Object::null();
}

}  // namespace dart
