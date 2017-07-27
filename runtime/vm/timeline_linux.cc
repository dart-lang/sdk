// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX) && !defined(PRODUCT)

#include <errno.h>
#include <fcntl.h>
#include <cstdlib>

#include "vm/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/service_event.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DECLARE_FLAG(bool, trace_timeline);

TimelineEventSystraceRecorder::TimelineEventSystraceRecorder(intptr_t capacity)
    : TimelineEventPlatformRecorder(capacity), systrace_fd_(-1) {
  const char* kSystracePath = "/sys/kernel/debug/tracing/trace_marker";
  systrace_fd_ = open(kSystracePath, O_WRONLY);
  if ((systrace_fd_ < 0) && FLAG_trace_timeline) {
    OS::PrintErr("TimelineEventSystraceRecorder: Could not open `%s`\n",
                 kSystracePath);
  }
}

TimelineEventSystraceRecorder::~TimelineEventSystraceRecorder() {
  if (systrace_fd_ >= 0) {
    close(systrace_fd_);
  }
}

intptr_t TimelineEventSystraceRecorder::PrintSystrace(TimelineEvent* event,
                                                      char* buffer,
                                                      intptr_t buffer_size) {
  ASSERT(buffer != NULL);
  ASSERT(buffer_size > 0);
  buffer[0] = '\0';
  intptr_t length = 0;
  int64_t pid = OS::ProcessId();
  switch (event->event_type()) {
    case TimelineEvent::kBegin: {
      length = OS::SNPrint(buffer, buffer_size, "B|%" Pd64 "|%s", pid,
                           event->label());
    } break;
    case TimelineEvent::kEnd: {
      length = OS::SNPrint(buffer, buffer_size, "E");
    } break;
    case TimelineEvent::kCounter: {
      if (event->arguments_length() > 0) {
        // We only report the first counter value.
        length = OS::SNPrint(buffer, buffer_size, "C|%" Pd64 "|%s|%s", pid,
                             event->label(), event->arguments()[0].value);
      }
    }
    default:
      // Ignore event types that we cannot serialize to the Systrace format.
      break;
  }
  return length;
}

void TimelineEventSystraceRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  if (systrace_fd_ >= 0) {
    // Serialize to the systrace format.
    const intptr_t kBufferLength = 1024;
    char buffer[kBufferLength];
    const intptr_t event_length =
        PrintSystrace(event, &buffer[0], kBufferLength);
    if (event_length > 0) {
      ssize_t result;
      // Repeatedly attempt the write while we are being interrupted.
      do {
        result = write(systrace_fd_, buffer, event_length);
      } while ((result == -1L) && (errno == EINTR));
    }
  }
  ThreadBlockCompleteEvent(event);
}

TimelineEventPlatformRecorder::TimelineEventPlatformRecorder(intptr_t capacity)
    : TimelineEventFixedBufferRecorder(capacity) {}

TimelineEventPlatformRecorder::~TimelineEventPlatformRecorder() {}

TimelineEventPlatformRecorder*
TimelineEventPlatformRecorder::CreatePlatformRecorder(intptr_t capacity) {
  return new TimelineEventSystraceRecorder(capacity);
}

const char* TimelineEventPlatformRecorder::name() const {
  return "Systrace";
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
  UNREACHABLE();
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
  DartCommonTimelineEventHelpers::ReportTaskEvent(
      thread, zone, event, start, id, phase, category, name, args);
}

void DartTimelineEventHelpers::ReportCompleteEvent(Thread* thread,
                                                   Zone* zone,
                                                   TimelineEvent* event,
                                                   int64_t start,
                                                   int64_t start_cpu,
                                                   const char* category,
                                                   const char* name,
                                                   const char* args) {
  DartCommonTimelineEventHelpers::ReportCompleteEvent(
      thread, zone, event, start, start_cpu, category, name, args);
}

void DartTimelineEventHelpers::ReportInstantEvent(Thread* thread,
                                                  Zone* zone,
                                                  TimelineEvent* event,
                                                  int64_t start,
                                                  const char* category,
                                                  const char* name,
                                                  const char* args) {
  DartCommonTimelineEventHelpers::ReportInstantEvent(thread, zone, event, start,
                                                     category, name, args);
}

}  // namespace dart

#endif  // defined(HOST_OS_LINUX) && !defined(PRODUCT)
