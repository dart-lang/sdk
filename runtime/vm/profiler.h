// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROFILER_H_
#define RUNTIME_VM_PROFILER_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/malloc_hooks.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/tags.h"
#include "vm/thread_interrupter.h"

// Profiler sampling and stack walking support.
// NOTE: For service related code, see profile_service.h.

namespace dart {

// Forward declarations.
class ProcessedSample;
class ProcessedSampleBuffer;

class Sample;
class AllocationSampleBuffer;
class SampleBuffer;
class ProfileTrieNode;

struct ProfilerCounters {
  // Count of bail out reasons:
  int64_t bail_out_unknown_task;
  int64_t bail_out_jump_to_exception_handler;
  int64_t bail_out_check_isolate;
  // Count of single frame sampling reasons:
  int64_t single_frame_sample_deoptimizing;
  int64_t single_frame_sample_register_check;
  int64_t single_frame_sample_get_and_validate_stack_bounds;
  // Count of stack walkers used:
  int64_t stack_walker_native;
  int64_t stack_walker_dart_exit;
  int64_t stack_walker_dart;
  int64_t stack_walker_none;
  // Count of failed checks:
  int64_t failure_native_allocation_sample;
};

class Profiler : public AllStatic {
 public:
  static void InitOnce();
  static void InitAllocationSampleBuffer();
  static void Shutdown();

  static void SetSampleDepth(intptr_t depth);
  static void SetSamplePeriod(intptr_t period);

  static SampleBuffer* sample_buffer() { return sample_buffer_; }
  static AllocationSampleBuffer* allocation_sample_buffer() {
    return allocation_sample_buffer_;
  }

  static void DumpStackTrace(void* context);
  static void DumpStackTrace(bool for_crash = true);

  static void SampleAllocation(Thread* thread, intptr_t cid);
  static Sample* SampleNativeAllocation(intptr_t skip_count,
                                        uword address,
                                        uintptr_t allocation_size);

  // SampleThread is called from inside the signal handler and hence it is very
  // critical that the implementation of SampleThread does not do any of the
  // following:
  //   * Accessing TLS -- Because on Windows the callback will be running in a
  //                      different thread.
  //   * Allocating memory -- Because this takes locks which may already be
  //                          held, resulting in a dead lock.
  //   * Taking a lock -- See above.
  static void SampleThread(Thread* thread, const InterruptedThreadState& state);

  static ProfilerCounters counters() {
    // Copies the counter values.
    return counters_;
  }

 private:
  static void DumpStackTrace(uword sp, uword fp, uword pc, bool for_crash);

  // Does not walk the thread's stack.
  static void SampleThreadSingleFrame(Thread* thread, uintptr_t pc);
  static bool initialized_;

  static SampleBuffer* sample_buffer_;
  static AllocationSampleBuffer* allocation_sample_buffer_;

  static ProfilerCounters counters_;

  friend class Thread;
};

class SampleVisitor : public ValueObject {
 public:
  explicit SampleVisitor(Dart_Port port) : port_(port), visited_(0) {}
  virtual ~SampleVisitor() {}

  virtual void VisitSample(Sample* sample) = 0;

  intptr_t visited() const { return visited_; }

  void IncrementVisited() { visited_++; }

  Dart_Port port() const { return port_; }

 private:
  Dart_Port port_;
  intptr_t visited_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(SampleVisitor);
};

class SampleFilter : public ValueObject {
 public:
  SampleFilter(Dart_Port port,
               intptr_t thread_task_mask,
               int64_t time_origin_micros,
               int64_t time_extent_micros)
      : port_(port),
        thread_task_mask_(thread_task_mask),
        time_origin_micros_(time_origin_micros),
        time_extent_micros_(time_extent_micros) {
    ASSERT(thread_task_mask != 0);
    ASSERT(time_origin_micros_ >= -1);
    ASSERT(time_extent_micros_ >= -1);
  }
  virtual ~SampleFilter() {}

  // Override this function.
  // Return |true| if |sample| passes the filter.
  virtual bool FilterSample(Sample* sample) { return true; }

  Dart_Port port() const { return port_; }

  // Returns |true| if |sample| passes the time filter.
  bool TimeFilterSample(Sample* sample);

  // Returns |true| if |sample| passes the thread task filter.
  bool TaskFilterSample(Sample* sample);

  static const intptr_t kNoTaskFilter = -1;

 private:
  Dart_Port port_;
  intptr_t thread_task_mask_;
  int64_t time_origin_micros_;
  int64_t time_extent_micros_;
};

class ClearProfileVisitor : public SampleVisitor {
 public:
  explicit ClearProfileVisitor(Isolate* isolate);

  virtual void VisitSample(Sample* sample);
};

// Each Sample holds a stack trace from an isolate.
class Sample {
 public:
  void Init(Dart_Port port, int64_t timestamp, ThreadId tid) {
    Clear();
    timestamp_ = timestamp;
    tid_ = tid;
    port_ = port;
  }

  Dart_Port port() const { return port_; }

  // Thread sample was taken on.
  ThreadId tid() const { return tid_; }

  void Clear() {
    port_ = ILLEGAL_PORT;
    pc_marker_ = 0;
    for (intptr_t i = 0; i < kStackBufferSizeInWords; i++) {
      stack_buffer_[i] = 0;
    }
    vm_tag_ = VMTag::kInvalidTagId;
    user_tag_ = UserTags::kDefaultUserTag;
    lr_ = 0;
    metadata_ = 0;
    state_ = 0;
    native_allocation_address_ = 0;
    native_allocation_size_bytes_ = 0;
    continuation_index_ = -1;
    next_free_ = NULL;
    uword* pcs = GetPCArray();
    for (intptr_t i = 0; i < pcs_length_; i++) {
      pcs[i] = 0;
    }
    set_head_sample(true);
  }

  // Timestamp sample was taken at.
  int64_t timestamp() const { return timestamp_; }

  // Top most pc.
  uword pc() const { return At(0); }

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

  void DumpStackTrace() {
    for (intptr_t i = 0; i < pcs_length_; ++i) {
      uintptr_t start = 0;
      uword pc = At(i);
      char* native_symbol_name =
          NativeSymbolResolver::LookupSymbolName(pc, &start);
      if (native_symbol_name == NULL) {
        OS::PrintErr("  [0x%" Pp "] Unknown symbol\n", pc);
      } else {
        OS::PrintErr("  [0x%" Pp "] %s\n", pc, native_symbol_name);
        NativeSymbolResolver::FreeSymbolName(native_symbol_name);
      }
    }
  }

  uword vm_tag() const { return vm_tag_; }
  void set_vm_tag(uword tag) {
    ASSERT(tag != VMTag::kInvalidTagId);
    vm_tag_ = tag;
  }

  uword user_tag() const { return user_tag_; }
  void set_user_tag(uword tag) { user_tag_ = tag; }

  uword pc_marker() const { return pc_marker_; }

  void set_pc_marker(uword pc_marker) { pc_marker_ = pc_marker; }

  uword lr() const { return lr_; }

  void set_lr(uword link_register) { lr_ = link_register; }

  bool leaf_frame_is_dart() const { return LeafFrameIsDart::decode(state_); }

  void set_leaf_frame_is_dart(bool leaf_frame_is_dart) {
    state_ = LeafFrameIsDart::update(leaf_frame_is_dart, state_);
  }

  bool ignore_sample() const { return IgnoreBit::decode(state_); }

  void set_ignore_sample(bool ignore_sample) {
    state_ = IgnoreBit::update(ignore_sample, state_);
  }

  bool exit_frame_sample() const { return ExitFrameBit::decode(state_); }

  void set_exit_frame_sample(bool exit_frame_sample) {
    state_ = ExitFrameBit::update(exit_frame_sample, state_);
  }

  bool missing_frame_inserted() const {
    return MissingFrameInsertedBit::decode(state_);
  }

  void set_missing_frame_inserted(bool missing_frame_inserted) {
    state_ = MissingFrameInsertedBit::update(missing_frame_inserted, state_);
  }

  bool truncated_trace() const { return TruncatedTraceBit::decode(state_); }

  void set_truncated_trace(bool truncated_trace) {
    state_ = TruncatedTraceBit::update(truncated_trace, state_);
  }

  bool is_allocation_sample() const {
    return ClassAllocationSampleBit::decode(state_);
  }

  void set_is_allocation_sample(bool allocation_sample) {
    state_ = ClassAllocationSampleBit::update(allocation_sample, state_);
  }

  uword native_allocation_address() const { return native_allocation_address_; }

  void set_native_allocation_address(uword address) {
    native_allocation_address_ = address;
  }

  uintptr_t native_allocation_size_bytes() const {
    return native_allocation_size_bytes_;
  }

  void set_native_allocation_size_bytes(uintptr_t size) {
    native_allocation_size_bytes_ = size;
  }

  Sample* next_free() const { return next_free_; }
  void set_next_free(Sample* next_free) { next_free_ = next_free; }

  Thread::TaskKind thread_task() const { return ThreadTaskBit::decode(state_); }

  void set_thread_task(Thread::TaskKind task) {
    state_ = ThreadTaskBit::update(task, state_);
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

  bool head_sample() const { return HeadSampleBit::decode(state_); }

  void set_metadata(intptr_t metadata) { metadata_ = metadata; }

  void SetAllocationCid(intptr_t cid) {
    set_is_allocation_sample(true);
    set_metadata(cid);
  }

  static void InitOnce();

  static intptr_t instance_size() { return instance_size_; }

  uword* GetPCArray() const;

  static const int kStackBufferSizeInWords = 2;
  uword* GetStackBuffer() { return &stack_buffer_[0]; }

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
    kThreadTaskBit = 8,  // 5 bits.
    kNextFreeBit = 13,
  };
  class HeadSampleBit : public BitField<uword, bool, kHeadSampleBit, 1> {};
  class LeafFrameIsDart : public BitField<uword, bool, kLeafFrameIsDartBit, 1> {
  };
  class IgnoreBit : public BitField<uword, bool, kIgnoreBit, 1> {};
  class ExitFrameBit : public BitField<uword, bool, kExitFrameBit, 1> {};
  class MissingFrameInsertedBit
      : public BitField<uword, bool, kMissingFrameInsertedBit, 1> {};
  class TruncatedTraceBit
      : public BitField<uword, bool, kTruncatedTraceBit, 1> {};
  class ClassAllocationSampleBit
      : public BitField<uword, bool, kClassAllocationSampleBit, 1> {};
  class ContinuationSampleBit
      : public BitField<uword, bool, kContinuationSampleBit, 1> {};
  class ThreadTaskBit
      : public BitField<uword, Thread::TaskKind, kThreadTaskBit, 5> {};

  int64_t timestamp_;
  ThreadId tid_;
  Dart_Port port_;
  uword pc_marker_;
  uword stack_buffer_[kStackBufferSizeInWords];
  uword vm_tag_;
  uword user_tag_;
  uword metadata_;
  uword lr_;
  uword state_;
  uword native_allocation_address_;
  uintptr_t native_allocation_size_bytes_;
  intptr_t continuation_index_;
  Sample* next_free_;

  /* There are a variable number of words that follow, the words hold the
   * sampled pc values. Access via GetPCArray() */
  DISALLOW_COPY_AND_ASSIGN(Sample);
};

class NativeAllocationSampleFilter : public SampleFilter {
 public:
  NativeAllocationSampleFilter(int64_t time_origin_micros,
                               int64_t time_extent_micros)
      : SampleFilter(ILLEGAL_PORT,
                     SampleFilter::kNoTaskFilter,
                     time_origin_micros,
                     time_extent_micros) {}

  bool FilterSample(Sample* sample) {
    // If the sample is an allocation sample, we need to check that the
    // memory at the address hasn't been freed, and if the address associated
    // with the allocation has been freed and then reissued.
    void* alloc_address =
        reinterpret_cast<void*>(sample->native_allocation_address());
    ASSERT(alloc_address != NULL);
    Sample* recorded_sample = MallocHooks::GetSample(alloc_address);
    return (sample == recorded_sample);
  }
};

// A Code object descriptor.
class CodeDescriptor : public ZoneAllocated {
 public:
  explicit CodeDescriptor(const Code& code);

  uword Start() const;

  uword Size() const;

  int64_t CompileTimestamp() const;

  RawCode* code() const { return code_.raw(); }

  const char* Name() const { return code_.Name(); }

  bool Contains(uword pc) const {
    uword end = Start() + Size();
    return (pc >= Start()) && (pc < end);
  }

  static int Compare(CodeDescriptor* const* a, CodeDescriptor* const* b) {
    ASSERT(a != NULL);
    ASSERT(b != NULL);

    uword a_start = (*a)->Start();
    uword b_start = (*b)->Start();

    if (a_start < b_start) {
      return -1;
    } else if (a_start > b_start) {
      return 1;
    } else {
      return 0;
    }
  }

 private:
  const Code& code_;

  DISALLOW_COPY_AND_ASSIGN(CodeDescriptor);
};

// Fast lookup of Dart code objects.
class CodeLookupTable : public ZoneAllocated {
 public:
  explicit CodeLookupTable(Thread* thread);

  intptr_t length() const { return code_objects_.length(); }

  const CodeDescriptor* At(intptr_t index) const {
    return code_objects_.At(index);
  }

  const CodeDescriptor* FindCode(uword pc) const;

 private:
  void Build(Thread* thread);

  void Add(const Code& code);

  // Code objects sorted by entry.
  ZoneGrowableArray<CodeDescriptor*> code_objects_;

  friend class CodeLookupTableBuilder;

  DISALLOW_COPY_AND_ASSIGN(CodeLookupTable);
};

// Ring buffer of Samples that is (usually) shared by many isolates.
class SampleBuffer {
 public:
  static const intptr_t kDefaultBufferCapacity = 120000;  // 2 minutes @ 1000hz.

  explicit SampleBuffer(intptr_t capacity = kDefaultBufferCapacity);
  virtual ~SampleBuffer();

  intptr_t capacity() const { return capacity_; }

  Sample* At(intptr_t idx) const;
  intptr_t ReserveSampleSlot();
  virtual Sample* ReserveSample();
  virtual Sample* ReserveSampleAndLink(Sample* previous);

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
      if (sample->port() != visitor->port()) {
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

 protected:
  ProcessedSample* BuildProcessedSample(Sample* sample,
                                        const CodeLookupTable& clt);
  Sample* Next(Sample* sample);

  VirtualMemory* memory_;
  Sample* samples_;
  intptr_t capacity_;
  uintptr_t cursor_;

 private:
  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};

class AllocationSampleBuffer : public SampleBuffer {
 public:
  explicit AllocationSampleBuffer(intptr_t capacity = kDefaultBufferCapacity);
  virtual ~AllocationSampleBuffer();

  intptr_t ReserveSampleSlotLocked();
  virtual Sample* ReserveSample();
  virtual Sample* ReserveSampleAndLink(Sample* previous);
  void FreeAllocationSample(Sample* sample);

 private:
  Mutex* mutex_;
  Sample* free_sample_list_;

  DISALLOW_COPY_AND_ASSIGN(AllocationSampleBuffer);
};

// A |ProcessedSample| is a combination of 1 (or more) |Sample|(s) that have
// been merged into a logical sample. The raw data may have been processed to
// improve the quality of the stack trace.
class ProcessedSample : public ZoneAllocated {
 public:
  ProcessedSample();

  // Add |pc| to stack trace.
  void Add(uword pc) { pcs_.Add(pc); }

  // Insert |pc| at |index|.
  void InsertAt(intptr_t index, uword pc) { pcs_.InsertAt(index, pc); }

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

  ThreadId tid() const { return tid_; }
  void set_tid(ThreadId tid) { tid_ = tid; }

  // The VM tag.
  uword vm_tag() const { return vm_tag_; }
  void set_vm_tag(uword tag) { vm_tag_ = tag; }

  // The user tag.
  uword user_tag() const { return user_tag_; }
  void set_user_tag(uword tag) { user_tag_ = tag; }

  // The class id if this is an allocation profile sample. -1 otherwise.
  intptr_t allocation_cid() const { return allocation_cid_; }
  void set_allocation_cid(intptr_t cid) { allocation_cid_ = cid; }

  bool IsAllocationSample() const { return allocation_cid_ > 0; }

  bool is_native_allocation_sample() const {
    return native_allocation_size_bytes_ != 0;
  }

  uintptr_t native_allocation_size_bytes() const {
    return native_allocation_size_bytes_;
  }
  void set_native_allocation_size_bytes(uintptr_t allocation_size) {
    native_allocation_size_bytes_ = allocation_size;
  }

  // Was the stack trace truncated?
  bool truncated() const { return truncated_; }
  void set_truncated(bool truncated) { truncated_ = truncated; }

  // Was the first frame in the stack trace executing?
  bool first_frame_executing() const { return first_frame_executing_; }
  void set_first_frame_executing(bool first_frame_executing) {
    first_frame_executing_ = first_frame_executing;
  }

  ProfileTrieNode* timeline_trie() const { return timeline_trie_; }
  void set_timeline_trie(ProfileTrieNode* trie) {
    ASSERT(timeline_trie_ == NULL);
    timeline_trie_ = trie;
  }

 private:
  void FixupCaller(const CodeLookupTable& clt,
                   uword pc_marker,
                   uword* stack_buffer);

  void CheckForMissingDartFrame(const CodeLookupTable& clt,
                                const CodeDescriptor* code,
                                uword pc_marker,
                                uword* stack_buffer);

  ZoneGrowableArray<uword> pcs_;
  int64_t timestamp_;
  ThreadId tid_;
  uword vm_tag_;
  uword user_tag_;
  intptr_t allocation_cid_;
  bool truncated_;
  bool first_frame_executing_;
  uword native_allocation_address_;
  uintptr_t native_allocation_size_bytes_;
  ProfileTrieNode* timeline_trie_;

  friend class SampleBuffer;
  DISALLOW_COPY_AND_ASSIGN(ProcessedSample);
};

// A collection of |ProcessedSample|s.
class ProcessedSampleBuffer : public ZoneAllocated {
 public:
  ProcessedSampleBuffer();

  void Add(ProcessedSample* sample) { samples_.Add(sample); }

  intptr_t length() const { return samples_.length(); }

  ProcessedSample* At(intptr_t index) { return samples_.At(index); }

  const CodeLookupTable& code_lookup_table() const {
    return *code_lookup_table_;
  }

 private:
  ZoneGrowableArray<ProcessedSample*> samples_;
  CodeLookupTable* code_lookup_table_;

  DISALLOW_COPY_AND_ASSIGN(ProcessedSampleBuffer);
};

}  // namespace dart

#endif  // RUNTIME_VM_PROFILER_H_
