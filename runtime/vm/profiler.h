// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PROFILER_H_
#define VM_PROFILER_H_

#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/thread_interrupter.h"

namespace dart {

// Forward declarations.
class JSONArray;
class JSONStream;
class ProfilerCodeRegionTable;
class Sample;
class SampleBuffer;

// Profiler
class Profiler : public AllStatic {
 public:
  enum TagOrder {
    kNoTags,
    kUser,
    kUserVM,
    kVM,
    kVMUser
  };

  static void InitOnce();
  static void Shutdown();

  static void SetSampleDepth(intptr_t depth);
  static void SetSamplePeriod(intptr_t period);

  static void InitProfilingForIsolate(Isolate* isolate,
                                      bool shared_buffer = true);
  static void ShutdownProfilingForIsolate(Isolate* isolate);

  static void BeginExecution(Isolate* isolate);
  static void EndExecution(Isolate* isolate);

  static void PrintJSON(Isolate* isolate, JSONStream* stream,
                        bool full, TagOrder tag_order);
  static void WriteProfile(Isolate* isolate);

  static SampleBuffer* sample_buffer() {
    return sample_buffer_;
  }

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

// Each Sample holds a stack trace from an isolate.
class Sample {
 public:
  void Init(Isolate* isolate, int64_t timestamp, ThreadId tid) {
    timestamp_ = timestamp;
    tid_ = tid;
    isolate_ = isolate;
    pc_marker_ = 0;
    vm_tag_ = VMTag::kInvalidTagId;
    user_tag_ = UserTags::kDefaultUserTag;
    sp_ = 0;
    fp_ = 0;
    state_ = 0;
    uword* pcs = GetPCArray();
    for (intptr_t i = 0; i < pcs_length_; i++) {
      pcs[i] = 0;
    }
  }

  // Isolate sample was taken from.
  Isolate* isolate() const {
    return isolate_;
  }

  // Timestamp sample was taken at.
  int64_t timestamp() const {
    return timestamp_;
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

  uword sp() const {
    return sp_;
  }

  void set_sp(uword sp) {
    sp_ = sp;
  }

  uword fp() const {
    return fp_;
  }

  void set_fp(uword fp) {
    fp_ = fp;
  }

  void InsertCallerForTopFrame(uword pc) {
    if (pcs_length_ == 1) {
      // Only sampling top frame.
      return;
    }
    uword* pcs = GetPCArray();
    // The caller for the top frame is store at index 1.
    // Shift all entries down by one.
    for (intptr_t i = pcs_length_ - 1; i >= 2; i--) {
      pcs[i] = pcs[i - 1];
    }
    // Insert caller for top frame.
    pcs[1] = pc;
  }

  bool processed() const {
    return ProcessedBit::decode(state_);
  }

  void set_processed(bool processed) {
    state_ = ProcessedBit::update(processed, state_);
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

  static void InitOnce();

  static intptr_t instance_size() {
    return instance_size_;
  }

  uword* GetPCArray() const;

 private:
  static intptr_t instance_size_;
  static intptr_t pcs_length_;
  enum StateBits {
    kProcessedBit = 0,
    kLeafFrameIsDartBit = 1,
    kIgnoreBit = 2,
    kExitFrameBit = 3,
  };
  class ProcessedBit : public BitField<bool, kProcessedBit, 1> {};
  class LeafFrameIsDart : public BitField<bool, kLeafFrameIsDartBit, 1> {};
  class IgnoreBit : public BitField<bool, kIgnoreBit, 1> {};
  class ExitFrameBit : public BitField<bool, kExitFrameBit, 1> {};

  int64_t timestamp_;
  ThreadId tid_;
  Isolate* isolate_;
  uword pc_marker_;
  uword vm_tag_;
  uword user_tag_;
  uword sp_;
  uword fp_;
  uword state_;

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
  Sample* ReserveSample();

  void VisitSamples(SampleVisitor* visitor) {
    ASSERT(visitor != NULL);
    const intptr_t length = capacity();
    for (intptr_t i = 0; i < length; i++) {
      Sample* sample = At(i);
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

 private:
  Sample* samples_;
  intptr_t capacity_;
  uintptr_t cursor_;

  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};


}  // namespace dart

#endif  // VM_PROFILER_H_
