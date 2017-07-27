// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS) && !defined(PRODUCT)

#include "vm/timeline.h"

namespace dart {

TimelineEventPlatformRecorder::TimelineEventPlatformRecorder(intptr_t capacity)
    : TimelineEventFixedBufferRecorder(capacity) {
  OS::PrintErr(
      "Warning: The systrace timeline recorder is equivalent to the"
      "ring recorder on this platform.");
}

TimelineEventPlatformRecorder::~TimelineEventPlatformRecorder() {}

TimelineEventPlatformRecorder*
TimelineEventPlatformRecorder::CreatePlatformRecorder(intptr_t capacity) {
  return new TimelineEventPlatformRecorder(capacity);
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
  if (event == NULL) {
    return;
  }
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

#endif  // defined(HOST_OS_MACOS) && !defined(PRODUCT)
