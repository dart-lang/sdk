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


class TimelineLabelPauseInfo : public ZoneAllocated {
 public:
  explicit TimelineLabelPauseInfo(const char* name);

  const char* name() const {
    return name_;
  }

  int64_t inclusive_micros() const {
    return inclusive_micros_;
  }

  int64_t exclusive_micros() const {
    return exclusive_micros_;
  }

  int64_t max_inclusive_micros() const {
    return max_inclusive_micros_;
  }

  int64_t max_exclusive_micros() const {
    return max_exclusive_micros_;
  }

 private:
  // Adjusts |inclusive_micros_| and |exclusive_micros_| by |micros|.
  // Also, may adjust, max_inclusive_micros_.
  void OnPush(int64_t micros, bool already_on_stack);

  // Adjusts |exclusive_micros_| by |exclusive_micros|.
  // Also, may adjust |max_exclusive_micros_|.
  void OnPop(int64_t exclusive_micros);

  // Adjust inclusive micros.
  void add_inclusive_micros(int64_t delta_micros) {
    inclusive_micros_ += delta_micros;
    ASSERT(inclusive_micros_ >= 0);
  }

  // Adjust exclusive micros.
  void add_exclusive_micros(int64_t delta_micros) {
    exclusive_micros_ += delta_micros;
    ASSERT(exclusive_micros_ >= 0);
  }

  const char* name_;
  int64_t inclusive_micros_;
  int64_t exclusive_micros_;
  int64_t max_inclusive_micros_;
  int64_t max_exclusive_micros_;

  friend class TimelinePauses;
};


class TimelinePauses : public TimelineAnalysis {
 public:
  TimelinePauses(Zone* zone,
                 Isolate* isolate,
                 TimelineEventRecorder* recorder);

  void Setup();

  void CalculatePauseTimesForThread(ThreadId tid);

  TimelineLabelPauseInfo* GetLabelPauseInfo(const char* name) const;

  int64_t InclusiveTime(const char* name) const;
  int64_t ExclusiveTime(const char* name) const;
  int64_t MaxInclusiveTime(const char* name) const;
  int64_t MaxExclusiveTime(const char* name) const;

 private:
  struct StackItem {
    TimelineEvent* event;
    TimelineLabelPauseInfo* pause_info;
    int64_t exclusive_micros;
  };

  void ProcessThread(TimelineAnalysisThread* thread);
  bool CheckStack(TimelineEvent* event);
  void PopFinished(int64_t start);
  void Push(TimelineEvent* event);
  bool IsLabelOnStack(const char* label);
  intptr_t StackDepth() const;
  StackItem& GetStackTop();
  TimelineLabelPauseInfo* GetOrAddLabelPauseInfo(const char* name);

  ZoneGrowableArray<StackItem> stack_;
  ZoneGrowableArray<TimelineLabelPauseInfo*> labels_;
};

}  // namespace dart

#endif  // VM_TIMELINE_ANALYSIS_H_
