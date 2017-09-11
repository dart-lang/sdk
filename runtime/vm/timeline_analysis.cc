// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/timeline_analysis.h"

#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/os_thread.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, trace_timeline_analysis);
DECLARE_FLAG(bool, timing);

TimelineAnalysisThread::TimelineAnalysisThread(ThreadId id) : id_(id) {}

TimelineAnalysisThread::~TimelineAnalysisThread() {}

void TimelineAnalysisThread::AddBlock(TimelineEventBlock* block) {
  blocks_.Add(block);
}

static int CompareBlocksLowerTimeBound(TimelineEventBlock* const* a,
                                       TimelineEventBlock* const* b) {
  ASSERT(a != NULL);
  ASSERT(*a != NULL);
  ASSERT(b != NULL);
  ASSERT(*b != NULL);
  return (*a)->LowerTimeBound() - (*b)->LowerTimeBound();
}

void TimelineAnalysisThread::Finalize() {
  blocks_.Sort(CompareBlocksLowerTimeBound);
  if (FLAG_trace_timeline_analysis) {
    THR_Print("Thread %" Px " has %" Pd " blocks\n",
              OSThread::ThreadIdToIntPtr(id_), blocks_.length());
  }
}

TimelineAnalysisThreadEventIterator::TimelineAnalysisThreadEventIterator(
    TimelineAnalysisThread* thread) {
  Reset(thread);
}

TimelineAnalysisThreadEventIterator::~TimelineAnalysisThreadEventIterator() {
  Reset(NULL);
}

void TimelineAnalysisThreadEventIterator::Reset(
    TimelineAnalysisThread* thread) {
  current_ = NULL;
  thread_ = thread;
  block_cursor_ = 0;
  event_cursor_ = 0;
  if (thread_ == NULL) {
    return;
  }
  if (thread_->NumBlocks() == 0) {
    return;
  }
  TimelineEventBlock* block = thread_->At(block_cursor_);
  ASSERT(!block->IsEmpty());
  current_ = block->At(event_cursor_++);
}

bool TimelineAnalysisThreadEventIterator::HasNext() const {
  return current_ != NULL;
}

TimelineEvent* TimelineAnalysisThreadEventIterator::Next() {
  ASSERT(current_ != NULL);
  TimelineEvent* r = current_;
  current_ = NULL;

  TimelineEventBlock* block = thread_->At(block_cursor_);
  if (event_cursor_ == block->length()) {
    // Reached the end of this block, move to the next.
    block_cursor_++;
    if (block_cursor_ == thread_->NumBlocks()) {
      // Exhausted our supply of blocks.
      return r;
    }
    // Grab next block.
    block = thread_->At(block_cursor_);
    event_cursor_ = 0;
    ASSERT(!block->IsEmpty());
  }
  current_ = block->At(event_cursor_++);
  return r;
}

TimelineAnalysis::TimelineAnalysis(Zone* zone,
                                   Isolate* isolate,
                                   TimelineEventRecorder* recorder)
    : zone_(zone),
      isolate_(isolate),
      recorder_(recorder),
      has_error_(false),
      error_msg_(NULL) {
  ASSERT(zone_ != NULL);
  ASSERT(isolate_ != NULL);
  ASSERT(recorder_ != NULL);
}

TimelineAnalysis::~TimelineAnalysis() {}

void TimelineAnalysis::BuildThreads() {
  DiscoverThreads();
  FinalizeThreads();
}

TimelineAnalysisThread* TimelineAnalysis::GetThread(ThreadId tid) {
  // Linear lookup because we expect N (# of threads in an isolate) to be small.
  for (intptr_t i = 0; i < threads_.length(); i++) {
    TimelineAnalysisThread* thread = threads_.At(i);
    ASSERT(thread != NULL);
    if (thread->id() == tid) {
      return thread;
    }
  }
  return NULL;
}

TimelineAnalysisThread* TimelineAnalysis::GetOrAddThread(ThreadId tid) {
  TimelineAnalysisThread* thread = GetThread(tid);
  if (thread != NULL) {
    return thread;
  }
  // New thread.
  thread = new TimelineAnalysisThread(tid);
  threads_.Add(thread);
  return thread;
}

void TimelineAnalysis::DiscoverThreads() {
  TimelineEventBlockIterator it(recorder_);
  while (it.HasNext()) {
    TimelineEventBlock* block = it.Next();
    ASSERT(block != NULL);
    if (block->IsEmpty()) {
      // Skip empty blocks.
      continue;
    }
    if (!block->CheckBlock()) {
      if (FLAG_trace_timeline_analysis) {
        THR_Print("DiscoverThreads block %" Pd
                  " "
                  "violates invariants.\n",
                  block->block_index());
      }
      SetError("Block %" Pd
               " violates invariants. See "
               "TimelineEventBlock::CheckBlock",
               block->block_index());
      return;
    }
    TimelineAnalysisThread* thread = GetOrAddThread(block->thread_id());
    ASSERT(thread != NULL);
    thread->AddBlock(block);
  }
}

void TimelineAnalysis::FinalizeThreads() {
  for (intptr_t i = 0; i < threads_.length(); i++) {
    TimelineAnalysisThread* thread = threads_.At(i);
    ASSERT(thread != NULL);
    thread->Finalize();
  }
}

void TimelineAnalysis::SetError(const char* format, ...) {
  ASSERT(!has_error_);
  ASSERT(error_msg_ == NULL);
  has_error_ = true;
  va_list args;
  va_start(args, format);
  error_msg_ = zone_->VPrint(format, args);
  ASSERT(error_msg_ != NULL);
  if (FLAG_trace_timeline_analysis) {
    OS::Print("TimelineAnalysis error = %s\n", error_msg_);
  }
}

TimelineLabelPauseInfo::TimelineLabelPauseInfo(const char* name)
    : name_(name),
      inclusive_micros_(0),
      exclusive_micros_(0),
      max_inclusive_micros_(0),
      max_exclusive_micros_(0) {
  ASSERT(name_ != NULL);
}

void TimelineLabelPauseInfo::OnPush(int64_t micros, bool already_on_stack) {
  UpdateInclusiveMicros(micros, already_on_stack);
}

void TimelineLabelPauseInfo::OnPop(int64_t exclusive_micros) {
  UpdateExclusiveMicros(exclusive_micros);
}

void TimelineLabelPauseInfo::OnBeginPop(int64_t inclusive_micros,
                                        int64_t exclusive_micros,
                                        bool already_on_stack) {
  UpdateInclusiveMicros(inclusive_micros, already_on_stack);
  UpdateExclusiveMicros(exclusive_micros);
}

void TimelineLabelPauseInfo::UpdateInclusiveMicros(int64_t inclusive_micros,
                                                   bool already_on_stack) {
  if (!already_on_stack) {
    // Only adjust inclusive counts if we aren't already on the stack.
    add_inclusive_micros(inclusive_micros);
    if (inclusive_micros > max_inclusive_micros_) {
      max_inclusive_micros_ = inclusive_micros;
    }
  }
}

void TimelineLabelPauseInfo::UpdateExclusiveMicros(int64_t exclusive_micros) {
  add_exclusive_micros(exclusive_micros);
  if (exclusive_micros > max_exclusive_micros_) {
    max_exclusive_micros_ = exclusive_micros;
  }
}

void TimelineLabelPauseInfo::Aggregate(
    const TimelineLabelPauseInfo* thread_pause_info) {
  ASSERT(thread_pause_info != NULL);
  inclusive_micros_ += thread_pause_info->inclusive_micros_;
  exclusive_micros_ += thread_pause_info->exclusive_micros_;
  if (max_inclusive_micros_ < thread_pause_info->max_inclusive_micros_) {
    max_inclusive_micros_ = thread_pause_info->max_inclusive_micros_;
  }
  if (max_exclusive_micros_ < thread_pause_info->max_exclusive_micros_) {
    max_exclusive_micros_ = thread_pause_info->max_exclusive_micros_;
  }
}

TimelinePauses::TimelinePauses(Zone* zone,
                               Isolate* isolate,
                               TimelineEventRecorder* recorder)
    : TimelineAnalysis(zone, isolate, recorder) {}

void TimelinePauses::Setup() {
  BuildThreads();
}

void TimelinePauses::CalculatePauseTimesForThread(ThreadId tid) {
  if (has_error()) {
    return;
  }
  TimelineAnalysisThread* thread = GetThread(tid);
  if (thread == NULL) {
    SetError("Thread %" Px " does not exist.", OSThread::ThreadIdToIntPtr(tid));
    return;
  }
  ProcessThread(thread);
}

TimelineLabelPauseInfo* TimelinePauses::GetLabelPauseInfo(
    const char* name) const {
  ASSERT(name != NULL);
  // Linear lookup because we expect N (# of labels in an isolate) to be small.
  for (intptr_t i = 0; i < labels_.length(); i++) {
    TimelineLabelPauseInfo* label = labels_.At(i);
    if (strcmp(label->name(), name) == 0) {
      return label;
    }
  }
  return NULL;
}

int64_t TimelinePauses::InclusiveTime(const char* name) const {
  TimelineLabelPauseInfo* pause_info = GetLabelPauseInfo(name);
  ASSERT(pause_info != NULL);
  return pause_info->inclusive_micros();
}

int64_t TimelinePauses::ExclusiveTime(const char* name) const {
  TimelineLabelPauseInfo* pause_info = GetLabelPauseInfo(name);
  ASSERT(pause_info != NULL);
  return pause_info->exclusive_micros();
}

int64_t TimelinePauses::MaxInclusiveTime(const char* name) const {
  TimelineLabelPauseInfo* pause_info = GetLabelPauseInfo(name);
  ASSERT(pause_info != NULL);
  return pause_info->max_inclusive_micros();
}

int64_t TimelinePauses::MaxExclusiveTime(const char* name) const {
  TimelineLabelPauseInfo* pause_info = GetLabelPauseInfo(name);
  ASSERT(pause_info != NULL);
  return pause_info->max_exclusive_micros();
}

void TimelinePauses::ProcessThread(TimelineAnalysisThread* thread) {
  ASSERT(thread != NULL);
  stack_.Clear();
  labels_.Clear();

  TimelineAnalysisThreadEventIterator it(thread);
  if (FLAG_trace_timeline_analysis) {
    THR_Print(">>> TimelinePauses::ProcessThread %" Px "\n",
              OSThread::ThreadIdToIntPtr(thread->id()));
  }
  intptr_t event_count = 0;
  while (!has_error() && it.HasNext()) {
    TimelineEvent* event = it.Next();
    if (event->isolate_id() != isolate_->main_port()) {
      // Skip events that do not belong to the isolate.
      continue;
    }
    if (event->IsFinishedDuration()) {
      int64_t start = event->TimeOrigin();
      PopFinishedDurations(start);
      if (!CheckStack(event)) {
        SetError("Duration check fail.");
        return;
      }
      event_count++;
      Push(event);
    } else if (event->IsBeginOrEnd()) {
      event_count++;
      if (event->IsBegin()) {
        PopFinishedDurations(event->TimeOrigin());
        Push(event);
      } else {
        ASSERT(event->IsEnd());
        PopFinishedDurations(event->TimeOrigin());
        PopBegin(event->label(), event->TimeOrigin());
      }
    } else {
      // Skip other event kinds.
    }
  }
  // Pop remaining duration stack.
  PopFinishedDurations(kMaxInt64);
  if (FLAG_trace_timeline_analysis) {
    THR_Print("<<< TimelinePauses::ProcessThread %" Px " had %" Pd " events\n",
              OSThread::ThreadIdToIntPtr(thread->id()), event_count);
  }
}

// Verify that |event| is contained within all parent events on the stack.
bool TimelinePauses::CheckStack(TimelineEvent* event) {
  ASSERT(event != NULL);
  for (intptr_t i = 0; i < stack_.length(); i++) {
    const StackItem& slot = stack_.At(i);
    if (slot.event->IsDuration()) {
      if (!slot.event->DurationContains(event)) {
        return false;
      }
    } else {
      ASSERT(slot.event->IsBegin());
      if (slot.event->TimeOrigin() > event->TimeOrigin()) {
        return false;
      }
    }
  }
  return true;
}

void TimelinePauses::PopFinishedDurations(int64_t start) {
  while (stack_.length() > 0) {
    const StackItem& top = stack_.Last();
    if (top.event->IsDuration() && top.event->DurationFinishedBefore(start)) {
      top.pause_info->OnPop(top.exclusive_micros);
      // Top of stack completes before |start|.
      stack_.RemoveLast();
      if (FLAG_trace_timeline_analysis) {
        THR_Print("Popping %s (%" Pd64 " <= %" Pd64 ")\n", top.event->label(),
                  top.event->TimeEnd(), start);
      }
    } else {
      return;
    }
  }
}

void TimelinePauses::PopBegin(const char* label, int64_t end) {
  if (stack_.length() == 0) {
    SetError("PopBegin(%s, ...) called with empty stack.", label);
    return;
  }
  ASSERT(stack_.length() > 0);
  const StackItem& top = stack_.Last();
  const char* top_label = top.event->label();
  const bool top_is_begin = top.event->IsBegin();
  const int64_t start = top.event->TimeOrigin();
  if (start > end) {
    SetError("Bad time stamps for PopBegin(%s, ...) %" Pd64 " > %" Pd64 "",
             label, start, end);
    return;
  }
  const int64_t duration = end - start;
  // Sanity checks.
  if (strcmp(top_label, label) != 0) {
    SetError("PopBegin(%s, ...) called with %s at the top of stack", label,
             top.event->label());
    return;
  }
  if (!top_is_begin) {
    SetError("kEnd event not paired with kBegin event for label %s", label);
    return;
  }
  // Pop this event.
  // Add duration to exclusive micros.
  if (FLAG_trace_timeline_analysis) {
    THR_Print("Popping %s (%" Pd64 ")\n", top.event->label(), duration);
  }
  const int64_t exclusive_micros = top.exclusive_micros + duration;
  stack_.RemoveLast();
  top.pause_info->OnBeginPop(duration, exclusive_micros,
                             IsLabelOnStack(top_label));
  if (StackDepth() > 0) {
    StackItem& top = GetStackTop();
    // |top| is under the popped |event|'s shadow, adjust the exclusive micros.
    top.exclusive_micros -= duration;
  }
}

void TimelinePauses::Push(TimelineEvent* event) {
  TimelineLabelPauseInfo* pause_info = GetOrAddLabelPauseInfo(event->label());
  ASSERT(pause_info != NULL);
  // |pause_info| will be running for |event->TimeDuration()|.
  if (FLAG_trace_timeline_analysis) {
    THR_Print("Pushing %s %" Pd64 " us\n", pause_info->name(),
              event->TimeDuration());
  }
  if (event->IsDuration()) {
    pause_info->OnPush(event->TimeDuration(), IsLabelOnStack(event->label()));
    if (StackDepth() > 0) {
      StackItem& top = GetStackTop();
      // |top| is under |event|'s shadow, adjust the exclusive micros.
      top.exclusive_micros -= event->TimeDuration();
    }
    // Push onto the stack.
    StackItem item;
    item.event = event;
    item.pause_info = pause_info;
    item.exclusive_micros = event->TimeDuration();
    stack_.Add(item);
  } else {
    ASSERT(event->IsBegin());
    pause_info->OnPush(0, IsLabelOnStack(event->label()));
    // Push onto the stack.
    StackItem item;
    item.event = event;
    item.pause_info = pause_info;
    item.exclusive_micros = 0;
    stack_.Add(item);
  }
}

bool TimelinePauses::IsLabelOnStack(const char* label) const {
  ASSERT(label != NULL);
  for (intptr_t i = 0; i < stack_.length(); i++) {
    const StackItem& slot = stack_.At(i);
    if (strcmp(slot.event->label(), label) == 0) {
      return true;
    }
  }
  return false;
}

intptr_t TimelinePauses::StackDepth() const {
  return stack_.length();
}

TimelinePauses::StackItem& TimelinePauses::GetStackTop() {
  ASSERT(stack_.length() > 0);
  return stack_.Last();
}

TimelineLabelPauseInfo* TimelinePauses::GetOrAddLabelPauseInfo(
    const char* name) {
  ASSERT(name != NULL);
  TimelineLabelPauseInfo* pause_info = GetLabelPauseInfo(name);
  if (pause_info != NULL) {
    return pause_info;
  }
  // New label.
  pause_info = new TimelineLabelPauseInfo(name);
  labels_.Add(pause_info);
  return pause_info;
}

TimelinePauseTrace::TimelinePauseTrace() {}

TimelinePauseTrace::~TimelinePauseTrace() {}

void TimelinePauseTrace::Print() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  Zone* zone = thread->zone();
  ASSERT(zone != NULL);
  TimelineEventRecorder* recorder = Timeline::recorder();
  ASSERT(recorder != NULL);
  TimelinePauses pauses(zone, isolate, recorder);
  pauses.Setup();

  THR_Print("Timing for isolate (%" Pd64 ") '%s' (from %" Pd " threads)\n",
            static_cast<int64_t>(isolate->main_port()), isolate->name(),
            pauses.NumThreads());
  THR_Print("\n");
  for (intptr_t t_idx = 0; t_idx < pauses.NumThreads(); t_idx++) {
    TimelineAnalysisThread* tat = pauses.At(t_idx);
    ASSERT(tat != NULL);
    pauses.CalculatePauseTimesForThread(tat->id());
    THR_Print("Thread %" Pd " (%" Px "):\n", t_idx,
              OSThread::ThreadIdToIntPtr(tat->id()));
    for (intptr_t j = 0; j < pauses.NumPauseInfos(); j++) {
      const TimelineLabelPauseInfo* pause_info = pauses.PauseInfoAt(j);
      ASSERT(pause_info != NULL);
      Aggregate(pause_info);
      PrintPauseInfo(pause_info);
    }
    THR_Print("\n");
  }
  THR_Print("Totals:\n");
  for (intptr_t i = 0; i < isolate_labels_.length(); i++) {
    TimelineLabelPauseInfo* pause_info = isolate_labels_.At(i);
    ASSERT(pause_info != NULL);
    PrintPauseInfo(pause_info);
  }
  THR_Print("\n");
}

TimelineLabelPauseInfo* TimelinePauseTrace::GetOrAddLabelPauseInfo(
    const char* name) {
  ASSERT(name != NULL);
  // Linear lookup because we expect N (# of labels in an isolate) to be small.
  for (intptr_t i = 0; i < isolate_labels_.length(); i++) {
    TimelineLabelPauseInfo* label = isolate_labels_.At(i);
    if (strcmp(label->name(), name) == 0) {
      return label;
    }
  }
  // New label.
  TimelineLabelPauseInfo* pause_info = new TimelineLabelPauseInfo(name);
  isolate_labels_.Add(pause_info);
  return pause_info;
}

void TimelinePauseTrace::Aggregate(
    const TimelineLabelPauseInfo* thread_pause_info) {
  ASSERT(thread_pause_info != NULL);
  TimelineLabelPauseInfo* isolate_pause_info =
      GetOrAddLabelPauseInfo(thread_pause_info->name());
  ASSERT(isolate_pause_info != NULL);
  isolate_pause_info->Aggregate(thread_pause_info);
}

void TimelinePauseTrace::PrintPauseInfo(
    const TimelineLabelPauseInfo* pause_info) {
  ASSERT(pause_info != NULL);
  THR_Print("%s : ", pause_info->name());
  THR_Print("%.3f ms total on stack; ",
            MicrosecondsToMilliseconds(pause_info->inclusive_micros()));
  THR_Print("%.3f ms total executing; ",
            MicrosecondsToMilliseconds(pause_info->exclusive_micros()));
  THR_Print("%.3f ms max on stack; ",
            MicrosecondsToMilliseconds(pause_info->max_inclusive_micros()));
  THR_Print("%.3f ms max executing.\n",
            MicrosecondsToMilliseconds(pause_info->max_exclusive_micros()));
}

#endif  // !PRODUCT

}  // namespace dart
