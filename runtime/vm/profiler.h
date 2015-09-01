// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PROFILER_H_
#define VM_PROFILER_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"

// Profiler sampling and stack walking support.
// NOTE: For service related code, see profile_service.h.

namespace dart {

// Forward declarations.
class ProcessedSample;
class ProcessedSampleBuffer;

class Sample;
class SampleBuffer;

class Profiler : public AllStatic {
 public:
  static void InitOnce();
  static void Shutdown();

  static void SetSampleDepth(intptr_t depth);
  static void SetSamplePeriod(intptr_t period);

  static void InitProfilingForIsolate(Isolate* isolate,
                                      bool shared_buffer = true);
  static void ShutdownProfilingForIsolate(Isolate* isolate);

  static void BeginExecution(Isolate* isolate);
  static void EndExecution(Isolate* isolate);

  static SampleBuffer* sample_buffer() {
    return sample_buffer_;
  }

  static void RecordAllocation(Isolate* isolate, intptr_t cid);

 private:
  static bool initialized_;
  static Monitor* monitor_;

  static void RecordSampleInterruptCallback(const InterruptedThreadState& state,
                                            void* data);

  static SampleBuffer* sample_buffer_;
};


class IsolateProfilerData {
 public:
  IsolateProfilerData(SampleBuffer* sample_buffer, bool own_sample_buffer);
  ~IsolateProfilerData();

  SampleBuffer* sample_buffer() const { return sample_buffer_; }

  void set_sample_buffer(SampleBuffer* sample_buffer) {
    sample_buffer_ = sample_buffer;
  }

  bool blocked() const {
    return block_count_ > 0;
  }

  void Block();

  void Unblock();

 private:
  SampleBuffer* sample_buffer_;
  bool own_sample_buffer_;
  intptr_t block_count_;

  DISALLOW_COPY_AND_ASSIGN(IsolateProfilerData);
};


class SampleVisitor : public ValueObject {
 public:
  explicit SampleVisitor(Isolate* isolate) : isolate_(isolate), visited_(0) { }
  virtual ~SampleVisitor() {}

  virtual void VisitSample(Sample* sample) = 0;

  intptr_t visited() const {
    return visited_;
  }

  void IncrementVisited() {
    visited_++;
  }

  Isolate* isolate() const {
    return isolate_;
  }

 private:
  Isolate* isolate_;
  intptr_t visited_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(SampleVisitor);
};


class SampleFilter : public ValueObject {
 public:
  explicit SampleFilter(Isolate* isolate) : isolate_(isolate) { }
  virtual ~SampleFilter() { }

  // Override this function.
  // Return |true| if |sample| passes the filter.
  virtual bool FilterSample(Sample* sample) {
    return true;
  }

  Isolate* isolate() const {
    return isolate_;
  }

 private:
  Isolate* isolate_;
};


class ClearProfileVisitor : public SampleVisitor {
 public:
  explicit ClearProfileVisitor(Isolate* isolate);

  virtual void VisitSample(Sample* sample);
};


// Each Sample holds a stack trace from an isolate.
class Sample {
 public:
  void Init(Isolate* isolate, int64_t timestamp, ThreadId tid) {
    Clear();
    timestamp_ = timestamp;
    tid_ = tid;
    isolate_ = isolate;
  }

  // Isolate sample was taken from.
  Isolate* isolate() const {
    return isolate_;
  }

  // Thread sample was taken on.
  ThreadId tid() const {
    return tid_;
  }

  void Clear() {
    isolate_ = NULL;
    pc_marker_ = 0;
    for (intptr_t i = 0; i < kStackBufferSizeInWords; i++) {
      stack_buffer_[i] = 0;
    }
    vm_tag_ = VMTag::kInvalidTagId;
    user_tag_ = UserTags::kDefaultUserTag;
    lr_ = 0;
    metadata_ = 0;
    state_ = 0;
    continuation_index_ = -1;
    uword* pcs = GetPCArray();
    for (intptr_t i = 0; i < pcs_length_; i++) {
      pcs[i] = 0;
    }
    set_head_sample(true);
  }

  // Timestamp sample was taken at.
  int64_t timestamp() const {
    return timestamp_;
  }

  // Top most pc.
  uword pc() const {
    return At(0);
  }

  // Get stack trace entry.
  uword At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < pcs_length_);
    uword* pcs = GetPCArray();
    return pcs[i];
  }

  // Set stack trace entry.
  void SetAt(intptr_t i, uword pc) {
    ASSERT(i >= 0);
    ASSERT(i < pcs_length_);
    uword* pcs = GetPCArray();
    pcs[i] = pc;
  }

  uword vm_tag() const {
    return vm_tag_;
  }
  void set_vm_tag(uword tag) {
    ASSERT(tag != VMTag::kInvalidTagId);
    vm_tag_ = tag;
  }

  uword user_tag() const {
    return user_tag_;
  }
  void set_user_tag(uword tag) {
    user_tag_ = tag;
  }

  uword pc_marker() const {
    return pc_marker_;
  }

  void set_pc_marker(uword pc_marker) {
    pc_marker_ = pc_marker;
  }

  uword lr() const {
    return lr_;
  }

  void set_lr(uword link_register) {
    lr_ = link_register;
  }

  bool leaf_frame_is_dart() const {
    return LeafFrameIsDart::decode(state_);
  }

  void set_leaf_frame_is_dart(bool leaf_frame_is_dart) {
    state_ = LeafFrameIsDart::update(leaf_frame_is_dart, state_);
  }

  bool ignore_sample() const {
    return IgnoreBit::decode(state_);
  }

  void set_ignore_sample(bool ignore_sample) {
    state_ = IgnoreBit::update(ignore_sample, state_);
  }

  bool exit_frame_sample() const {
    return ExitFrameBit::decode(state_);
  }

  void set_exit_frame_sample(bool exit_frame_sample) {
    state_ = ExitFrameBit::update(exit_frame_sample, state_);
  }

  bool missing_frame_inserted() const {
    return MissingFrameInsertedBit::decode(state_);
  }

  void set_missing_frame_inserted(bool missing_frame_inserted) {
    state_ = MissingFrameInsertedBit::update(missing_frame_inserted, state_);
  }

  bool truncated_trace() const {
    return TruncatedTraceBit::decode(state_);
  }

  void set_truncated_trace(bool truncated_trace) {
    state_ = TruncatedTraceBit::update(truncated_trace, state_);
  }

  bool is_allocation_sample() const {
    return ClassAllocationSampleBit::decode(state_);
  }

  void set_is_allocation_sample(bool allocation_sample) {
    state_ = ClassAllocationSampleBit::update(allocation_sample, state_);
  }

  bool is_continuation_sample() const {
    return ContinuationSampleBit::decode(state_);
  }

  void SetContinuationIndex(intptr_t index) {
    ASSERT(!is_continuation_sample());
    ASSERT(continuation_index_ == -1);
    state_ = ContinuationSampleBit::update(true, state_);
    continuation_index_ = index;
    ASSERT(is_continuation_sample());
  }

  intptr_t continuation_index() const {
    ASSERT(is_continuation_sample());
    return continuation_index_;
  }

  intptr_t allocation_cid() const {
    ASSERT(is_allocation_sample());
    return metadata_;
  }

  void set_head_sample(bool head_sample) {
    state_ = HeadSampleBit::update(head_sample, state_);
  }

  bool head_sample() const {
    return HeadSampleBit::decode(state_);
  }

  void set_metadata(intptr_t metadata) {
    metadata_ = metadata;
  }

  void SetAllocationCid(intptr_t cid) {
    set_is_allocation_sample(true);
    set_metadata(cid);
  }

  static void InitOnce();

  static intptr_t instance_size() {
    return instance_size_;
  }

  uword* GetPCArray() const;

  static const int kStackBufferSizeInWords = 2;
  uword* GetStackBuffer() {
    return &stack_buffer_[0];
  }

 private:
  static intptr_t instance_size_;
  static intptr_t pcs_length_;
  enum StateBits {
    kHeadSampleBit = 0,
    kLeafFrameIsDartBit = 1,
    kIgnoreBit = 2,
    kExitFrameBit = 3,
    kMissingFrameInsertedBit = 4,
    kTruncatedTraceBit = 5,
    kClassAllocationSampleBit = 6,
    kContinuationSampleBit = 7,
  };
  class HeadSampleBit : public BitField<bool, kHeadSampleBit, 1> {};
  class LeafFrameIsDart : public BitField<bool, kLeafFrameIsDartBit, 1> {};
  class IgnoreBit : public BitField<bool, kIgnoreBit, 1> {};
  class ExitFrameBit : public BitField<bool, kExitFrameBit, 1> {};
  class MissingFrameInsertedBit
      : public BitField<bool, kMissingFrameInsertedBit, 1> {};
  class TruncatedTraceBit : public BitField<bool, kTruncatedTraceBit, 1> {};
  class ClassAllocationSampleBit
      : public BitField<bool, kClassAllocationSampleBit, 1> {};
  class ContinuationSampleBit
      : public BitField<bool, kContinuationSampleBit, 1> {};

  int64_t timestamp_;
  ThreadId tid_;
  Isolate* isolate_;
  uword pc_marker_;
  uword stack_buffer_[kStackBufferSizeInWords];
  uword vm_tag_;
  uword user_tag_;
  uword metadata_;
  uword lr_;
  uword state_;
  intptr_t continuation_index_;

  /* There are a variable number of words that follow, the words hold the
   * sampled pc values. Access via GetPCArray() */

  DISALLOW_COPY_AND_ASSIGN(Sample);
};


// Ring buffer of Samples that is (usually) shared by many isolates.
class SampleBuffer {
 public:
  static const intptr_t kDefaultBufferCapacity = 120000;  // 2 minutes @ 1000hz.

  explicit SampleBuffer(intptr_t capacity = kDefaultBufferCapacity);

  ~SampleBuffer() {
    if (samples_ != NULL) {
      free(samples_);
      samples_ = NULL;
      cursor_ = 0;
      capacity_ = 0;
    }
  }

  intptr_t capacity() const { return capacity_; }

  Sample* At(intptr_t idx) const;
  intptr_t ReserveSampleSlot();
  Sample* ReserveSample();
  Sample* ReserveSampleAndLink(Sample* previous);

  void VisitSamples(SampleVisitor* visitor) {
    ASSERT(visitor != NULL);
    const intptr_t length = capacity();
    for (intptr_t i = 0; i < length; i++) {
      Sample* sample = At(i);
      if (!sample->head_sample()) {
        // An inner sample in a chain of samples.
        continue;
      }
      if (sample->ignore_sample()) {
        // Bad sample.
        continue;
      }
      if (sample->isolate() != visitor->isolate()) {
        // Another isolate.
        continue;
      }
      if (sample->timestamp() == 0) {
        // Empty.
        continue;
      }
      if (sample->At(0) == 0) {
        // No frames.
        continue;
      }
      visitor->IncrementVisited();
      visitor->VisitSample(sample);
    }
  }

  ProcessedSampleBuffer* BuildProcessedSampleBuffer(SampleFilter* filter);

 private:
  ProcessedSample* BuildProcessedSample(Sample* sample);
  Sample* Next(Sample* sample);

  Sample* samples_;
  intptr_t capacity_;
  uintptr_t cursor_;

  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};


// A |ProcessedSample| is a combination of 1 (or more) |Sample|(s) that have
// been merged into a logical sample. The raw data may have been processed to
// improve the quality of the stack trace.
class ProcessedSample : public ZoneAllocated {
 public:
  ProcessedSample();

  // Add |pc| to stack trace.
  void Add(uword pc) {
    pcs_.Add(pc);
  }

  // Insert |pc| at |index|.
  void InsertAt(intptr_t index, uword pc) {
    pcs_.InsertAt(index, pc);
  }

  // Number of pcs in stack trace.
  intptr_t length() const { return pcs_.length(); }

  // Get |pc| at |index|.
  uword At(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < length());
    return pcs_[index];
  }

  // Timestamp sample was taken at.
  int64_t timestamp() const { return timestamp_; }
  void set_timestamp(int64_t timestamp) { timestamp_ = timestamp; }

  // The VM tag.
  uword vm_tag() const { return vm_tag_; }
  void set_vm_tag(uword tag) { vm_tag_ = tag; }

  // The user tag.
  uword user_tag() const { return user_tag_; }
  void set_user_tag(uword tag) { user_tag_ = tag; }

  // The class id if this is an allocation profile sample. -1 otherwise.
  intptr_t allocation_cid() const { return allocation_cid_; }
  void set_allocation_cid(intptr_t cid) { allocation_cid_ = cid; }

  bool IsAllocationSample() const {
    return allocation_cid_ > 0;
  }

  // Was the stack trace truncated?
  bool truncated() const { return truncated_; }
  void set_truncated(bool truncated) { truncated_ = truncated; }

  // Was the first frame in the stack trace executing?
  bool first_frame_executing() const { return first_frame_executing_; }
  void set_first_frame_executing(bool first_frame_executing) {
    first_frame_executing_ = first_frame_executing;
  }

 private:
  void FixupCaller(Isolate* isolate,
                   Isolate* vm_isolate,
                   uword pc_marker,
                   uword* stack_buffer);

  void CheckForMissingDartFrame(Isolate* isolate,
                                Isolate* vm_isolate,
                                const Code& code,
                                uword pc_marker,
                                uword* stack_buffer);

  static RawCode* FindCodeForPC(Isolate* isolate,
                                Isolate* vm_isolate,
                                uword pc);

  static bool ContainedInDartCodeHeaps(Isolate* isolate,
                                       Isolate* vm_isolate,
                                       uword pc);

  ZoneGrowableArray<uword> pcs_;
  int64_t timestamp_;
  uword vm_tag_;
  uword user_tag_;
  intptr_t allocation_cid_;
  bool truncated_;
  bool first_frame_executing_;

  friend class SampleBuffer;
  DISALLOW_COPY_AND_ASSIGN(ProcessedSample);
};


// A collection of |ProcessedSample|s.
class ProcessedSampleBuffer : public ZoneAllocated {
 public:
  ProcessedSampleBuffer();

  void Add(ProcessedSample* sample) {
    samples_.Add(sample);
  }

  intptr_t length() const {
    return samples_.length();
  }

  ProcessedSample* At(intptr_t index) {
    return samples_.At(index);
  }

 private:
  ZoneGrowableArray<ProcessedSample*> samples_;

  DISALLOW_COPY_AND_ASSIGN(ProcessedSampleBuffer);
};

}  // namespace dart

#endif  // VM_PROFILER_H_
