// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA) && !defined(PRODUCT)

#include "apps/tracing/lib/trace/cwriter.h"
#include "apps/tracing/lib/trace/event.h"
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
  TimelineEventBlock* block = blocks_[block_cursor_++];
  block->Reset();
  block->Open();
  return block;
}

void TimelineEventPlatformRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  if (!ctrace_is_enabled()) {
    ThreadBlockCompleteEvent(event);
    return;
  }
  auto writer = ctrace_writer_acquire();

  // XXX: use ctrace_register_category_string();
  ctrace_stringref_t category;
  ctrace_register_string(writer, "dart", &category);

  ctrace_stringref_t name;
  ctrace_register_string(writer, event->label(), &name);

  ctrace_threadref_t thread;
  ctrace_register_current_thread(writer, &thread);

  ctrace_argspec_t args[2];
  ctrace_arglist_t arglist = {0, args};

  if (event->arguments_length() >= 1) {
    args[0].type = CTRACE_ARGUMENT_STRING;
    args[0].name = event->arguments()[0].name;
    args[0].u.s = event->arguments()[0].value;
    arglist.n_args += 1;
  }
  if (event->arguments_length() >= 2) {
    args[1].type = CTRACE_ARGUMENT_STRING;
    args[1].name = event->arguments()[1].name;
    args[1].u.s = event->arguments()[1].value;
    arglist.n_args += 1;
  }

  const uint64_t time_scale = mx_ticks_per_second() / kMicrosecondsPerSecond;
  const uint64_t start_time = event->LowTime() * time_scale;
  const uint64_t end_time = event->HighTime() * time_scale;

  // TODO(zra): The functions below emit Dart's timeline events all as category
  // "dart". Instead, we could have finer-grained categories that make use of
  // the name of the timeline stream, e.g. "VM", "GC", etc.
  switch (event->event_type()) {
    case TimelineEvent::kBegin:
      ctrace_write_duration_begin_event_record(writer, start_time, &thread,
                                               &category, &name, &arglist);
      break;
    case TimelineEvent::kEnd:
      ctrace_write_duration_end_event_record(writer, end_time, &thread,
                                             &category, &name, &arglist);
      break;
    case TimelineEvent::kInstant:
      ctrace_write_instant_event_record(writer, start_time, &thread, &category,
                                        &name, CTRACE_SCOPE_THREAD, &arglist);
      break;
    case TimelineEvent::kAsyncBegin:
      ctrace_write_async_begin_event_record(writer, start_time, &thread,
                                            &category, &name, event->AsyncId(),
                                            &arglist);
      break;
    case TimelineEvent::kAsyncEnd:
      ctrace_write_async_end_event_record(writer, end_time, &thread, &category,
                                          &name, event->AsyncId(), &arglist);
      break;
    case TimelineEvent::kAsyncInstant:
      ctrace_write_async_instant_event_record(writer, start_time, &thread,
                                              &category, &name,
                                              event->AsyncId(), &arglist);
      break;
    case TimelineEvent::kDuration:
      ctrace_write_duration_event_record(writer, start_time, end_time, &thread,
                                         &category, &name, &arglist);
      break;
    case TimelineEvent::kFlowBegin:
      ctrace_write_flow_begin_event_record(writer, start_time, &thread,
                                           &category, &name, event->AsyncId(),
                                           &arglist);
      break;
    case TimelineEvent::kFlowStep:
      ctrace_write_flow_step_event_record(writer, start_time, &thread,
                                          &category, &name, event->AsyncId(),
                                          &arglist);
      break;
    case TimelineEvent::kFlowEnd:
      ctrace_write_flow_end_event_record(writer, start_time, &thread, &category,
                                         &name, event->AsyncId(), &arglist);
      break;
    default:
      // TODO(zra): Figure out what to do with kCounter and kMetadata.
      break;
  }
  ctrace_writer_release(writer);
  ThreadBlockCompleteEvent(event);
}

void DartTimelineEventHelpers::ReportTaskEvent(Thread* thread,
                                               Zone* zone,
                                               TimelineEvent* event,
                                               int64_t start,
                                               int64_t id,
                                               const char* phase,
                                               const char* category,
                                               const char* name,
                                               const char* args) {
  char* name_string = strdup(name);
  ASSERT(phase != NULL);
  ASSERT((phase[0] == 'n') || (phase[0] == 'b') || (phase[0] == 'e'));
  ASSERT(phase[1] == '\0');
  switch (phase[0]) {
    case 'n':
      event->AsyncInstant(name_string, id, start);
      break;
    case 'b':
      event->AsyncBegin(name_string, id, start);
      break;
    case 'e':
      event->AsyncEnd(name_string, id, start);
      break;
    default:
      UNREACHABLE();
  }
  event->set_owns_label(true);
  event->SetNumArguments(1);
  event->CopyArgument(0, "args", args);
  event->Complete();
}

void DartTimelineEventHelpers::ReportCompleteEvent(Thread* thread,
                                                   Zone* zone,
                                                   TimelineEvent* event,
                                                   int64_t start,
                                                   int64_t start_cpu,
                                                   const char* category,
                                                   const char* name,
                                                   const char* args) {
  const int64_t end = OS::GetCurrentMonotonicMicros();
  const int64_t end_cpu = OS::GetCurrentThreadCPUMicros();
  event->Duration(strdup(name), start, end, start_cpu, end_cpu);
  event->set_owns_label(true);
  event->SetNumArguments(1);
  event->CopyArgument(0, "args", args);
  event->Complete();
}

void DartTimelineEventHelpers::ReportInstantEvent(Thread* thread,
                                                  Zone* zone,
                                                  TimelineEvent* event,
                                                  int64_t start,
                                                  const char* category,
                                                  const char* name,
                                                  const char* args) {
  event->Instant(strdup(name), start);
  event->set_owns_label(true);
  event->SetNumArguments(1);
  event->CopyArgument(0, "args", args);
  event->Complete();
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA) && !defined(PRODUCT)
