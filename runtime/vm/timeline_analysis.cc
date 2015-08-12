// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/timeline_analysis.h"

#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, trace_timeline);


TimelineAnalysisThread::TimelineAnalysisThread(ThreadId id)
    : id_(id) {
}


TimelineAnalysisThread::~TimelineAnalysisThread() {
}


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
}


TimelineAnalysis::TimelineAnalysis(Zone* zone,
                                   Isolate* isolate,
                                   TimelineEventEndlessRecorder* recorder)
    : zone_(zone),
      isolate_(isolate),
      recorder_(recorder),
      has_error_(false),
      error_msg_(NULL) {
  ASSERT(zone_ != NULL);
  ASSERT(isolate_ != NULL);
  ASSERT(recorder_ != NULL);
}


TimelineAnalysis::~TimelineAnalysis() {
}


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
  while (it.Next()) {
    TimelineEventBlock* block = it.current();
    ASSERT(block != NULL);
    if (block->IsEmpty()) {
      // Skip empty blocks.
      continue;
    }
    if (!block->CheckBlock()) {
      // Skip bad blocks.
      // TODO(johnmccutchan): Make this into an error?
      continue;
    }
    TimelineAnalysisThread* thread = GetOrAddThread(block->thread());
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
}


TimelinePauses::TimelinePauses(Zone* zone,
                               Isolate* isolate,
                               TimelineEventEndlessRecorder* recorder)
    : TimelineAnalysis(zone, isolate, recorder) {
}

}  // namespace dart
