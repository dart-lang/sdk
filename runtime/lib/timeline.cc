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

DEFINE_NATIVE_ENTRY(Timeline_getIsolateNum, 0) {
  return Integer::New(static_cast<int64_t>(isolate->main_port()),
                      Heap::kOld,
                      true);
}


DEFINE_NATIVE_ENTRY(Timeline_getNextAsyncId, 0) {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Integer::New(0);
  }
  return Integer::New(recorder->GetNextAsyncId());
}


DEFINE_NATIVE_ENTRY(Timeline_getTraceClock, 0) {
  return Integer::New(OS::GetCurrentMonotonicMicros(), Heap::kNew, true);
}


DEFINE_NATIVE_ENTRY(Timeline_reportTaskEvent, 6) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, id, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, phase, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(4));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(5));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = isolate->GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());
  // Convert phase to a C string and perform a sanity check.
  const char* phase_string = phase.ToCString();
  ASSERT(phase_string != NULL);
  ASSERT((phase_string[0] == 'n') ||
         (phase_string[0] == 'b') ||
         (phase_string[0] == 'e'));
  ASSERT(phase_string[1] == '\0');
  char* json = OS::SCreate(zone,
      "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64 ","
      "\"ts\":%" Pd64 ",\"ph\":\"%s\",\"id\":%" Pd64 ", \"args\":%s}",
      name.ToCString(),
      category.ToCString(),
      tid,
      pid,
      start.AsInt64Value(),
      phase_string,
      id.AsInt64Value(),
      args.ToCString());

  switch (phase_string[0]) {
    case 'n':
      event->AsyncInstant("", id.AsInt64Value(), start.AsInt64Value());
    break;
    case 'b':
      event->AsyncBegin("", id.AsInt64Value(), start.AsInt64Value());
    break;
    case 'e':
      event->AsyncEnd("", id.AsInt64Value(), start.AsInt64Value());
    break;
    default:
      UNREACHABLE();
  }

  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);

  return Object::null();
}


DEFINE_NATIVE_ENTRY(Timeline_reportCompleteEvent, 5) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, end, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(4));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = isolate->GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  int64_t duration = end.AsInt64Value() - start.AsInt64Value();
  int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());

  char* json = OS::SCreate(zone,
      "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64 ","
      "\"ts\":%" Pd64 ",\"ph\":\"X\",\"dur\":%" Pd64 ",\"args\":%s}",
      name.ToCString(),
      category.ToCString(),
      tid,
      pid,
      start.AsInt64Value(),
      duration,
      args.ToCString());

  event->Duration("", start.AsInt64Value(), end.AsInt64Value());
  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);

  return Object::null();
}


DEFINE_NATIVE_ENTRY(Timeline_reportInstantEvent, 4) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(3));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = isolate->GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());

  char* json = OS::SCreate(zone,
      "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64 ","
      "\"ts\":%" Pd64 ",\"ph\":\"I\",\"args\":%s}",
      name.ToCString(),
      category.ToCString(),
      tid,
      pid,
      start.AsInt64Value(),
      args.ToCString());

  event->Instant("", start.AsInt64Value());
  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);

  return Object::null();
}

}  // namespace dart
