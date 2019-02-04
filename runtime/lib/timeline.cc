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

DEFINE_NATIVE_ENTRY(Timeline_isDartStreamEnabled, 0, 0) {
#if defined(SUPPORT_TIMELINE)
  if (Timeline::GetDartStream()->enabled()) {
    return Bool::True().raw();
  }
#endif
  return Bool::False().raw();
}

DEFINE_NATIVE_ENTRY(Timeline_getNextAsyncId, 0, 0) {
#if !defined(SUPPORT_TIMELINE)
  return Integer::New(0);
#else
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Integer::New(0);
  }
  return Integer::New(recorder->GetNextAsyncId());
#endif
}

DEFINE_NATIVE_ENTRY(Timeline_getTraceClock, 0, 0) {
  return Integer::New(OS::GetCurrentMonotonicMicros(), Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Timeline_getThreadCpuClock, 0, 0) {
  return Integer::New(OS::GetCurrentThreadCPUMicros(), Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Timeline_reportTaskEvent, 0, 6) {
#if defined(SUPPORT_TIMELINE)
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

  TimelineEvent* event = Timeline::GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  DartTimelineEventHelpers::ReportTaskEvent(
      thread, event, start.AsInt64Value(), id.AsInt64Value(), phase.ToCString(),
      category.ToCString(), name.ToMallocCString(), args.ToMallocCString());
#endif  // SUPPORT_TIMELINE
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Timeline_reportCompleteEvent, 0, 5) {
#if defined(SUPPORT_TIMELINE)
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start_cpu, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(4));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = Timeline::GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  DartTimelineEventHelpers::ReportCompleteEvent(
      thread, event, start.AsInt64Value(), start_cpu.AsInt64Value(),
      category.ToCString(), name.ToMallocCString(), args.ToMallocCString());
#endif  // SUPPORT_TIMELINE
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Timeline_reportFlowEvent, 0, 7) {
#if defined(SUPPORT_TIMELINE)
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start_cpu, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, type, arguments->NativeArgAt(4));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, flow_id, arguments->NativeArgAt(5));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(6));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = Timeline::GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  DartTimelineEventHelpers::ReportFlowEvent(
      thread, event, start.AsInt64Value(), start_cpu.AsInt64Value(),
      category.ToCString(), name.ToMallocCString(), type.AsInt64Value(),
      flow_id.AsInt64Value(), args.ToMallocCString());
#endif  // SUPPORT_TIMELINE
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Timeline_reportInstantEvent, 0, 4) {
#if defined(SUPPORT_TIMELINE)
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, category, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(String, args, arguments->NativeArgAt(3));

  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return Object::null();
  }

  TimelineEvent* event = Timeline::GetDartStream()->StartEvent();
  if (event == NULL) {
    // Stream was turned off.
    return Object::null();
  }

  DartTimelineEventHelpers::ReportInstantEvent(
      thread, event, start.AsInt64Value(), category.ToCString(),
      name.ToMallocCString(), args.ToMallocCString());
#endif  // SUPPORT_TIMELINE
  return Object::null();
}

}  // namespace dart
