// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMELINE_ANALYSIS_H_
#define VM_TIMELINE_ANALYSIS_H_

#include "vm/growable_array.h"
#include "vm/timeline.h"

namespace dart {

class TimelineAnalysisThread : public ZoneAllocated {
 public:
  explicit TimelineAnalysisThread(ThreadId id);
  ~TimelineAnalysisThread();

  ThreadId id() const {
    return id_;
  }

  intptr_t NumBlocks() const {
    return blocks_.length();
  }

  TimelineEventBlock* At(intptr_t i) const {
    return blocks_.At(i);
  }

 private:
  void AddBlock(TimelineEventBlock* block);
  void Finalize();

  const ThreadId id_;
  ZoneGrowableArray<TimelineEventBlock*> blocks_;

  friend class TimelineAnalysis;
};


class TimelineAnalysisThreadEventIterator : public ValueObject {
 public:
  explicit TimelineAnalysisThreadEventIterator(TimelineAnalysisThread* thread);
  ~TimelineAnalysisThreadEventIterator();

  void Reset(TimelineAnalysisThread* thread);

  bool HasNext() const;

  TimelineEvent* Next();

 private:
  TimelineAnalysisThread* thread_;
  TimelineEvent* current_;
  intptr_t block_cursor_;
  intptr_t event_cursor_;
};


// Base of all timeline analysis classes. Base functionality:
// - discovery of all thread ids in a recording.
// - collecting all ThreadEventBlocks by thread id.
class TimelineAnalysis : public ValueObject {
 public:
  TimelineAnalysis(Zone* zone,
                   Isolate* isolate,
                   TimelineEventRecorder* recorder);
  ~TimelineAnalysis();

  void BuildThreads();

  intptr_t NumThreads() const {
    return threads_.length();
  }

  TimelineAnalysisThread* At(intptr_t i) const {
    return threads_[i];
  }

  TimelineAnalysisThread* GetThread(ThreadId tid);

  bool has_error() const {
    return has_error_;
  }

  const char* error_msg() const {
    return error_msg_;
  }

 protected:
  TimelineAnalysisThread* GetOrAddThread(ThreadId tid);

  void DiscoverThreads();
  void FinalizeThreads();

  void SetError(const char* format, ...);

  Zone* zone_;
  Isolate* isolate_;
  TimelineEventRecorder* recorder_;
  bool has_error_;
  const char* error_msg_;

  ZoneGrowableArray<TimelineAnalysisThread*> threads_;
};


class TimelinePauses : public TimelineAnalysis {
 public:
  TimelinePauses(Zone* zone,
                 Isolate* isolate,
                 TimelineEventRecorder* recorder);

  void CalculatePauseTimes();

 private:
};

}  // namespace dart

#endif  // VM_TIMELINE_ANALYSIS_H_
