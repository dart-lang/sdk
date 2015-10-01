// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/timeline.h"

namespace dart {

// Native implementations for the dart:developer library.
DEFINE_NATIVE_ENTRY(Timeline_getTraceClock, 0) {
  return Integer::New(OS::GetCurrentTraceMicros(), Heap::kNew, true);
}


DEFINE_NATIVE_ENTRY(Timeline_reportCompleteEvent, 5) {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  if (!isolate->GetDartStream()->Enabled()) {
    // Dart stream is not enabled for this isolate, do nothing.
    return Object::null();
  }

  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, end, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(4));

  int64_t duration = end.AsInt64Value() - start.AsInt64Value();
  int64_t pid = OS::ProcessId();
  int64_t tid = OSThread::ThreadIdToIntPtr(OSThread::GetCurrentThreadTraceId());

  char* event = OS::SCreate(zone,
      "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%"Pd64",\"pid\":%"Pd64","
      "\"ts\":%"Pd64",\"ph\":\"X\",\"dur\":%"Pd64",\"args\":%s}",
      name.ToCString(),
      category.ToCString(),
      tid,
      pid,
      start.AsInt64Value(),
      duration,
      args.ToCString());

  // event was allocated in the zone and will be copied by AppendDartEvent.
  recorder->AppendDartEvent(isolate, event);

  return Object::null();
}

}  // namespace dart
