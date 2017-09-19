// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA) && !defined(PRODUCT)

#include <trace-engine/context.h>
#include <trace-engine/instrumentation.h>
#include <zircon/syscalls.h>

#include "platform/utils.h"
#include "vm/object.h"
#include "vm/timeline.h"

namespace dart {

// A recorder that sends events to Fuchsia's tracing app. Events are also stored
// in a buffer of fixed capacity. When the buffer is full, new events overwrite
// old events.
// See: https://fuchsia.googlesource.com/tracing/+/HEAD/docs/usage_guide.md

TimelineEventPlatformRecorder::TimelineEventPlatformRecorder(intptr_t capacity)
    : TimelineEventFixedBufferRecorder(capacity) {}

TimelineEventPlatformRecorder::~TimelineEventPlatformRecorder() {}

TimelineEventPlatformRecorder*
TimelineEventPlatformRecorder::CreatePlatformRecorder(intptr_t capacity) {
  return new TimelineEventPlatformRecorder(capacity);
}

const char* TimelineEventPlatformRecorder::name() const {
  return "Fuchsia";
}

TimelineEventBlock* TimelineEventPlatformRecorder::GetNewBlockLocked() {
  // TODO(johnmccutchan): This function should only hand out blocks
  // which have been marked as finished.
  if (block_cursor_ == num_blocks_) {
    block_cursor_ = 0;
  }
  TimelineEventBlock* block = &blocks_[block_cursor_++];
  block->Reset();
  block->Open();
  return block;
}

void TimelineEventPlatformRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  trace_string_ref_t category;
  trace_context_t* context =
      trace_acquire_context_for_category("dart", &category);
  if (context == NULL) {
    ThreadBlockCompleteEvent(event);
    return;
  }

  trace_string_ref_t name;
  if (event->owns_label()) {
    // If the event owns the name, then the name will be deallocated, so
    // instruct the system trace to make a copy.
    name = trace_context_make_registered_string_copy(
        context, event->label(), strlen(event->label()));
  } else {
    // If the event doesn't own the name, then it is a string literal, and
    // the system trace can use the pointer and not a copy.
    name = trace_context_make_registered_string_literal(
        context, event->label());
  }

  trace_thread_ref_t thread;
  trace_context_register_current_thread(context, &thread);

  trace_arg_t args[TRACE_MAX_ARGS];
  const intptr_t num_args = Utils::Minimum(
      event->arguments_length(), static_cast<intptr_t>(TRACE_MAX_ARGS));

  for (intptr_t i = 0; i < num_args; i++) {
    const char* name = event->arguments()[i].name;
    const char* value = event->arguments()[i].value;
    trace_string_ref_t arg_name =
        trace_context_make_registered_string_literal(context, name);
    trace_string_ref_t arg_value =
        trace_make_inline_string_ref(value, strlen(value));
    args[i] = trace_make_arg(arg_name, trace_make_string_arg_value(arg_value));
  }

  const uint64_t time_scale = zx_ticks_per_second() / kMicrosecondsPerSecond;
  const uint64_t start_time = event->LowTime() * time_scale;
  const uint64_t end_time = event->HighTime() * time_scale;

  // TODO(zra): The functions below emit Dart's timeline events all as category
  // "dart". Instead, we could have finer-grained categories that make use of
  // the name of the timeline stream, e.g. "VM", "GC", etc.
  switch (event->event_type()) {
    case TimelineEvent::kBegin:
      trace_context_write_duration_begin_event_record(
          context, start_time, &thread, &category, &name, args, num_args);
      break;
    case TimelineEvent::kEnd:
      trace_context_write_duration_end_event_record(
          context, start_time, &thread, &category, &name, args, num_args);
      break;
    case TimelineEvent::kInstant:
      trace_context_write_instant_event_record(
          context, start_time, &thread, &category, &name, TRACE_SCOPE_THREAD,
          args, num_args);
      break;
    case TimelineEvent::kAsyncBegin:
      trace_context_write_async_begin_event_record(
          context, start_time, &thread, &category, &name, event->AsyncId(),
          args, num_args);
      break;
    case TimelineEvent::kAsyncEnd:
      trace_context_write_async_end_event_record(
          context, end_time, &thread, &category, &name, event->AsyncId(), args,
          num_args);
      break;
    case TimelineEvent::kAsyncInstant:
      trace_context_write_async_instant_event_record(
          context, start_time, &thread, &category, &name, event->AsyncId(),
          args, num_args);
      break;
    case TimelineEvent::kDuration:
      trace_context_write_duration_event_record(context, start_time, end_time,
                                                &thread, &category, &name, args,
                                                num_args);
      break;
    case TimelineEvent::kFlowBegin:
      trace_context_write_flow_begin_event_record(
          context, start_time, &thread, &category, &name, event->AsyncId(),
          args, num_args);
      break;
    case TimelineEvent::kFlowStep:
      trace_context_write_flow_step_event_record(
          context, start_time, &thread, &category, &name, event->AsyncId(),
          args, num_args);
      break;
    case TimelineEvent::kFlowEnd:
      trace_context_write_flow_end_event_record(
          context, start_time, &thread, &category, &name, event->AsyncId(),
          args, num_args);
      break;
    default:
      // TODO(zra): Figure out what to do with kCounter and kMetadata.
      break;
  }
  trace_release_context(context);
  ThreadBlockCompleteEvent(event);
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA) && !defined(PRODUCT)
