// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PROFILER_H_
#define RUNTIME_VM_PROFILER_H_

#include "platform/atomic.h"

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
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
class SampleBlock;

#define PROFILER_COUNTERS(V)                                                   \
  V(bail_out_unknown_task)                                                     \
  V(bail_out_jump_to_exception_handler)                                        \
  V(bail_out_check_isolate)                                                    \
  V(single_frame_sample_deoptimizing)                                          \
  V(single_frame_sample_get_and_validate_stack_bounds)                         \
  V(stack_walker_native)                                                       \
  V(stack_walker_dart_exit)                                                    \
  V(stack_walker_dart)                                                         \
  V(stack_walker_none)                                                         \
  V(incomplete_sample_fp_bounds)                                               \
  V(incomplete_sample_fp_step)                                                 \
  V(incomplete_sample_bad_pc)                                                  \
  V(sample_allocation_failure)

struct ProfilerCounters {
#define DECLARE_PROFILER_COUNTER(name) RelaxedAtomic<int64_t> name;
  PROFILER_COUNTERS(DECLARE_PROFILER_COUNTER)
#undef DECLARE_PROFILER_COUNTER
};

class Profiler : public AllStatic {
 public:
  static void Init();
  static void Cleanup();

  static void SetSampleDepth(intptr_t depth);
  static void SetSamplePeriod(intptr_t period);
  // Restarts sampling with a given profile period. This is called after the
  // profile period is changed via the service protocol.
  static void UpdateSamplePeriod();
  // Starts or shuts down the profiler after --profiler is changed via the
  // service protocol.
  static void UpdateRunningState();

  static SampleBlockBuffer* sample_block_buffer() {
    return sample_block_buffer_;
  }
  static void set_sample_block_buffer(SampleBlockBuffer* buffer) {
    sample_block_buffer_ = buffer;
  }

  static void DumpStackTrace(void* context);
  static void DumpStackTrace(bool for_crash = true);

  static void SampleAllocation(Thread* thread,
                               intptr_t cid,
                               uint32_t identity_hash);

  // SampleThread is called from inside the signal handler and hence it is very
  // critical that the implementation of SampleThread does not do any of the
  // following:
  //   * Accessing TLS -- Because on Fuchsia, Mac and Windows the callback will
  //                      be running in a different thread.
  //   * Allocating memory -- Because this takes locks which may already be
  //                          held, resulting in a dead lock.
  //   * Taking a lock -- See above.
  static void SampleThread(Thread* thread, const InterruptedThreadState& state);

  static ProfilerCounters counters() {
    // Copies the counter values.
    return counters_;
  }
  inline static intptr_t Size();

  static void ProcessCompletedBlocks(Isolate* isolate);
  static void IsolateShutdown(Thread* thread);

 private:
  static void DumpStackTrace(uword sp, uword fp, uword pc, bool for_crash);

  // Calculates the sample buffer capacity. Returns
  // SampleBuffer::kDefaultBufferCapacity if --sample-buffer-duration is not
  // provided. Otherwise, the capacity is based on the sample rate, maximum
  // sample stack depth, and the number of seconds of samples the sample buffer
  // should be able to accomodate.
  static intptr_t CalculateSampleBufferCapacity();

  // Does not walk the thread's stack.
  static void SampleThreadSingleFrame(Thread* thread,
                                      Sample* sample,
                                      uintptr_t pc);
  static RelaxedAtomic<bool> initialized_;

  static SampleBlockBuffer* sample_block_buffer_;

  static ProfilerCounters counters_;

  friend class Thread;
};

class SampleVisitor : public ValueObject {
 public:
  explicit SampleVisitor(Dart_Port port) : port_(port), visited_(0) {}
  virtual ~SampleVisitor() {}

  virtual void VisitSample(Sample* sample) = 0;

  virtual void Reset() { visited_ = 0; }

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
               int64_t time_extent_micros,
               bool take_samples = false)
      : port_(port),
        thread_task_mask_(thread_task_mask),
        time_origin_micros_(time_origin_micros),
        time_extent_micros_(time_extent_micros),
        take_samples_(take_samples) {
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

  bool take_samples() const { return take_samples_; }

  static constexpr intptr_t kNoTaskFilter = -1;

 private:
  Dart_Port port_;
  intptr_t thread_task_mask_;
  int64_t time_origin_micros_;
  int64_t time_extent_micros_;
  bool take_samples_;
};

class ClearProfileVisitor : public SampleVisitor {
 public:
  explicit ClearProfileVisitor(Isolate* isolate);

  virtual void VisitSample(Sample* sample);
};

// Each Sample holds a stack trace from an isolate.
class Sample {
 public:
  Sample() = default;

  void Init(Dart_Port port, int64_t timestamp, ThreadId tid) {
    Clear();
    timestamp_ = timestamp;
    tid_ = tid;
    port_ = port;
    next_ = nullptr;
  }

  Dart_Port port() const { return port_; }

  // Thread sample was taken on.
  ThreadId tid() const { return tid_; }

  void Clear() {
    timestamp_ = 0;
    port_ = ILLEGAL_PORT;
    tid_ = OSThread::kInvalidThreadId;
    for (intptr_t i = 0; i < kStackBufferSizeInWords; i++) {
      stack_buffer_[i] = 0;
    }
    for (intptr_t i = 0; i < kPCArraySizeInWords; i++) {
      pc_array_[i] = 0;
    }
    vm_tag_ = VMTag::kInvalidTagId;
    user_tag_ = UserTags::kDefaultUserTag;
    state_ = 0;
    next_ = nullptr;
    allocation_identity_hash_ = 0;
    set_head_sample(true);
  }

  // Timestamp sample was taken at.
  int64_t timestamp() const { return timestamp_; }

  // Top most pc.
  uword pc() const { return At(0); }

  // Get stack trace entry.
  uword At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < kPCArraySizeInWords);
    return pc_array_[i];
  }

  // Set stack trace entry.
  void SetAt(intptr_t i, uword pc) {
    ASSERT(i >= 0);
    ASSERT(i < kPCArraySizeInWords);
    pc_array_[i] = pc;
  }

  void DumpStackTrace() {
    for (intptr_t i = 0; i < kPCArraySizeInWords; ++i) {
      uintptr_t start = 0;
      uword pc = At(i);
      char* native_symbol_name =
          NativeSymbolResolver::LookupSymbolName(pc, &start);
      if (native_symbol_name == nullptr) {
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

  uint32_t allocation_identity_hash() const {
    return allocation_identity_hash_;
  }

  void set_allocation_identity_hash(uint32_t hash) {
    allocation_identity_hash_ = hash;
  }

  Thread::TaskKind thread_task() const { return ThreadTaskBit::decode(state_); }

  void set_thread_task(Thread::TaskKind task) {
    state_ = ThreadTaskBit::update(task, state_);
  }

  bool is_continuation_sample() const {
    return ContinuationSampleBit::decode(state_);
  }

  void SetContinuation(Sample* next) {
    ASSERT(!is_continuation_sample());
    ASSERT(next_ == nullptr);
    state_ = ContinuationSampleBit::update(true, state_);
    next_ = next;
  }

  Sample* continuation_sample() const { return next_; }

  intptr_t allocation_cid() const {
    ASSERT(is_allocation_sample());
    return metadata();
  }

  void set_head_sample(bool head_sample) {
    state_ = HeadSampleBit::update(head_sample, state_);
  }

  bool head_sample() const { return HeadSampleBit::decode(state_); }

  intptr_t metadata() const { return MetadataBits::decode(state_); }
  void set_metadata(intptr_t metadata) {
    state_ = MetadataBits::update(metadata, state_);
  }

  void SetAllocationCid(intptr_t cid) {
    set_is_allocation_sample(true);
    set_metadata(cid);
  }

  static constexpr int kPCArraySizeInWords = 32;
  uword* GetPCArray() { return &pc_array_[0]; }

  static constexpr int kStackBufferSizeInWords = 2;
  uword* GetStackBuffer() { return &stack_buffer_[0]; }

 private:
  enum StateBits {
    kHeadSampleBit = 0,
    kLeafFrameIsDartBit = 1,
    kIgnoreBit = 2,
    kExitFrameBit = 3,
    kMissingFrameInsertedBit = 4,
    kTruncatedTraceBit = 5,
    kClassAllocationSampleBit = 6,
    kContinuationSampleBit = 7,
    kThreadTaskBit = 8,  // 7 bits.
    kMetadataBit = 15,   // 16 bits.
    kNextFreeBit = 31,
  };
  class HeadSampleBit : public BitField<uint32_t, bool, kHeadSampleBit, 1> {};
  class LeafFrameIsDart
      : public BitField<uint32_t, bool, kLeafFrameIsDartBit, 1> {};
  class IgnoreBit : public BitField<uint32_t, bool, kIgnoreBit, 1> {};
  class ExitFrameBit : public BitField<uint32_t, bool, kExitFrameBit, 1> {};
  class MissingFrameInsertedBit
      : public BitField<uint32_t, bool, kMissingFrameInsertedBit, 1> {};
  class TruncatedTraceBit
      : public BitField<uint32_t, bool, kTruncatedTraceBit, 1> {};
  class ClassAllocationSampleBit
      : public BitField<uint32_t, bool, kClassAllocationSampleBit, 1> {};
  class ContinuationSampleBit
      : public BitField<uint32_t, bool, kContinuationSampleBit, 1> {};
  class ThreadTaskBit
      : public BitField<uint32_t, Thread::TaskKind, kThreadTaskBit, 7> {};
  class MetadataBits : public BitField<uint32_t, intptr_t, kMetadataBit, 16> {};

  int64_t timestamp_;
  Dart_Port port_;
  ThreadId tid_;
  uword stack_buffer_[kStackBufferSizeInWords];
  uword pc_array_[kPCArraySizeInWords];
  uword vm_tag_;
  uword user_tag_;
  uint32_t state_;
  Sample* next_;
  uint32_t allocation_identity_hash_;

  DISALLOW_COPY_AND_ASSIGN(Sample);
};

class AbstractCode {
 public:
  explicit AbstractCode(ObjectPtr code) : code_(Object::Handle(code)) {
    ASSERT(code_.IsNull() || code_.IsCode());
  }

  ObjectPtr ptr() const { return code_.ptr(); }
  const Object* handle() const { return &code_; }

  uword PayloadStart() const {
    ASSERT(code_.IsCode());
    return Code::Cast(code_).PayloadStart();
  }

  uword Size() const {
    ASSERT(code_.IsCode());
    return Code::Cast(code_).Size();
  }

  int64_t compile_timestamp() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).compile_timestamp();
    } else {
      return 0;
    }
  }

  const char* Name() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).Name();
    } else {
      return "";
    }
  }

  const char* QualifiedName() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).QualifiedName(
          NameFormattingParams(Object::kUserVisibleName));
    } else {
      return "";
    }
  }

  bool IsStubCode() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).IsStubCode();
    } else {
      return false;
    }
  }

  bool IsAllocationStubCode() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).IsAllocationStubCode();
    } else {
      return false;
    }
  }

  bool IsTypeTestStubCode() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).IsTypeTestStubCode();
    } else {
      return false;
    }
  }

  ObjectPtr owner() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).owner();
    } else {
      return Object::null();
    }
  }

  bool IsNull() const { return code_.IsNull(); }
  bool IsCode() const { return code_.IsCode(); }

  bool is_optimized() const {
    if (code_.IsCode()) {
      return Code::Cast(code_).is_optimized();
    } else {
      return false;
    }
  }

 private:
  const Object& code_;
};

// A Code object descriptor.
class CodeDescriptor : public ZoneAllocated {
 public:
  explicit CodeDescriptor(const AbstractCode code);

  uword Start() const;

  uword Size() const;

  int64_t CompileTimestamp() const;

  const AbstractCode code() const { return code_; }

  const char* Name() const { return code_.Name(); }

  bool Contains(uword pc) const {
    uword end = Start() + Size();
    return (pc >= Start()) && (pc < end);
  }

  static int Compare(CodeDescriptor* const* a, CodeDescriptor* const* b) {
    ASSERT(a != nullptr);
    ASSERT(b != nullptr);

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
  const AbstractCode code_;

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

  void Add(const Object& code);

  // Code objects sorted by entry.
  ZoneGrowableArray<CodeDescriptor*> code_objects_;

  friend class CodeLookupTableBuilder;

  DISALLOW_COPY_AND_ASSIGN(CodeLookupTable);
};

class SampleBuffer {
 public:
  SampleBuffer() = default;
  virtual ~SampleBuffer() = default;

  virtual void Init(Sample* samples, intptr_t capacity) {
    ASSERT(samples != nullptr);
    ASSERT(capacity > 0);
    samples_ = samples;
    capacity_ = capacity;
  }

  void VisitSamples(SampleVisitor* visitor) {
    ASSERT(visitor != nullptr);
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

  virtual Sample* ReserveSample() = 0;
  virtual Sample* ReserveSampleAndLink(Sample* previous) = 0;

  Sample* At(intptr_t idx) const {
    ASSERT(idx >= 0);
    ASSERT(idx < capacity_);
    return &samples_[idx];
  }

  intptr_t capacity() const { return capacity_; }

  ProcessedSampleBuffer* BuildProcessedSampleBuffer(
      SampleFilter* filter,
      ProcessedSampleBuffer* buffer = nullptr);

 protected:
  Sample* Next(Sample* sample);

  ProcessedSample* BuildProcessedSample(Sample* sample,
                                        const CodeLookupTable& clt);

  Sample* samples_;
  intptr_t capacity_;

  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};

class SampleBlock : public SampleBuffer {
 public:
  // The default number of samples per block. Overridden by some tests.
  static constexpr intptr_t kSamplesPerBlock = 100;

  SampleBlock() = default;
  virtual ~SampleBlock() = default;

  // Returns the number of samples contained within this block.
  intptr_t capacity() const { return capacity_; }

  Isolate* owner() const { return owner_; }
  void set_owner(Isolate* isolate) { owner_ = isolate; }

  virtual Sample* ReserveSample();
  virtual Sample* ReserveSampleAndLink(Sample* previous);

  bool TryAllocateFree() {
    State expected = kFree;
    State desired = kSampling;
    std::memory_order success_order = std::memory_order_acquire;
    std::memory_order failure_order = std::memory_order_relaxed;
    return state_.compare_exchange_strong(expected, desired, success_order,
                                          failure_order);
  }
  bool TryAllocateCompleted() {
    State expected = kCompleted;
    State desired = kSampling;
    std::memory_order success_order = std::memory_order_acquire;
    std::memory_order failure_order = std::memory_order_relaxed;
    if (state_.compare_exchange_strong(expected, desired, success_order,
                                       failure_order)) {
      owner_ = nullptr;
      cursor_ = 0;
      return true;
    }
    return false;
  }
  void MarkCompleted() {
    ASSERT(state_.load(std::memory_order_relaxed) == kSampling);
    state_.store(kCompleted, std::memory_order_release);
  }
  bool TryAcquireStreaming(Isolate* isolate) {
    if (state_.load(std::memory_order_relaxed) != kCompleted) return false;
    if (owner_ != isolate) return false;

    State expected = kCompleted;
    State desired = kStreaming;
    std::memory_order success_order = std::memory_order_acquire;
    std::memory_order failure_order = std::memory_order_relaxed;
    return state_.compare_exchange_strong(expected, desired, success_order,
                                          failure_order);
  }
  void StreamingToCompleted() {
    ASSERT(state_.load(std::memory_order_relaxed) == kStreaming);
    state_.store(kCompleted, std::memory_order_relaxed);
  }
  void StreamingToFree() {
    ASSERT(state_.load(std::memory_order_relaxed) == kStreaming);
    owner_ = nullptr;
    cursor_ = 0;
    state_.store(kFree, std::memory_order_release);
  }
  void FreeCompleted() {
    State expected = kCompleted;
    State desired = kStreaming;
    std::memory_order success_order = std::memory_order_acquire;
    std::memory_order failure_order = std::memory_order_relaxed;
    if (state_.compare_exchange_strong(expected, desired, success_order,
                                       failure_order)) {
      StreamingToFree();
    }
  }

 protected:
  bool HasStreamableSamples(const GrowableObjectArray& tag_table, UserTag* tag);

  enum State : uint32_t {
    kFree,
    kSampling,  // I.e., writing.
    kCompleted,
    kStreaming,  // I.e., reading.
  };
  std::atomic<State> state_ = kFree;
  RelaxedAtomic<uint32_t> cursor_ = 0;
  Isolate* owner_ = nullptr;

 private:
  friend class SampleBlockListProcessor;
  friend class SampleBlockBuffer;

  DISALLOW_COPY_AND_ASSIGN(SampleBlock);
};

class SampleBlockBuffer {
 public:
  static constexpr intptr_t kDefaultBlockCount = 600;

  // Creates a SampleBlockBuffer with a predetermined number of blocks.
  //
  // Defaults to kDefaultBlockCount blocks. Block size is fixed to
  // SampleBlock::kSamplesPerBlock samples per block, except for in tests.
  explicit SampleBlockBuffer(
      intptr_t blocks = kDefaultBlockCount,
      intptr_t samples_per_block = SampleBlock::kSamplesPerBlock);

  virtual ~SampleBlockBuffer();

  void VisitSamples(SampleVisitor* visitor) {
    ASSERT(visitor != nullptr);
    for (intptr_t i = 0; i < capacity_; ++i) {
      blocks_[i].VisitSamples(visitor);
    }
  }

  void FreeCompletedBlocks();

  // Reserves a sample for a CPU profile.
  //
  // Returns nullptr when a sample can't be reserved.
  Sample* ReserveCPUSample(Isolate* isolate);

  // Reserves a sample for a Dart object allocation profile.
  //
  // Returns nullptr when a sample can't be reserved.
  Sample* ReserveAllocationSample(Isolate* isolate);

  intptr_t Size() const { return memory_->size(); }

  ProcessedSampleBuffer* BuildProcessedSampleBuffer(
      Isolate* isolate,
      SampleFilter* filter,
      ProcessedSampleBuffer* buffer = nullptr);

 private:
  Sample* ReserveSampleImpl(Isolate* isolate, bool allocation_sample);

  // Returns nullptr if there are no available blocks.
  SampleBlock* ReserveSampleBlock();

  // Sample block management.
  RelaxedAtomic<int> cursor_;
  SampleBlock* blocks_;
  intptr_t capacity_;

  // Sample buffer management.
  VirtualMemory* memory_;
  Sample* sample_buffer_;

  friend class Isolate;
  DISALLOW_COPY_AND_ASSIGN(SampleBlockBuffer);
};

intptr_t Profiler::Size() {
  intptr_t size = 0;
  if (sample_block_buffer_ != nullptr) {
    size += sample_block_buffer_->Size();
  }
  return size;
}

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

  // The identity hash code of the allocated object if this is an allocation
  // profile sample. -1 otherwise.
  uint32_t allocation_identity_hash() const {
    return allocation_identity_hash_;
  }
  void set_allocation_identity_hash(uint32_t hash) {
    allocation_identity_hash_ = hash;
  }

  bool IsAllocationSample() const { return allocation_cid_ > 0; }

  // Was the stack trace truncated?
  bool truncated() const { return truncated_; }
  void set_truncated(bool truncated) { truncated_ = truncated; }

  // Was the first frame in the stack trace executing?
  bool first_frame_executing() const { return first_frame_executing_; }
  void set_first_frame_executing(bool first_frame_executing) {
    first_frame_executing_ = first_frame_executing;
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
  uint32_t allocation_identity_hash_;
  bool truncated_;
  bool first_frame_executing_;

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

class SampleBlockProcessor : public AllStatic {
 public:
  static void Init();

  static void Startup();
  static void Cleanup();

 private:
  static constexpr intptr_t kMaxThreads = 4096;
  static bool initialized_;
  static bool shutdown_;
  static bool thread_running_;
  static ThreadJoinId processor_thread_id_;
  static Monitor* monitor_;

  static void ThreadMain(uword parameters);
};

}  // namespace dart

#endif  // RUNTIME_VM_PROFILER_H_
