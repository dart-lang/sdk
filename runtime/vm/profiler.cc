// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/address_sanitizer.h"
#include "platform/memory_sanitizer.h"
#include "platform/utils.h"

#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/code_patcher.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"

namespace dart {

static const intptr_t kSampleSize = 8;
static const intptr_t kMaxSamplesPerTick = 4;

DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");

#if defined(TARGET_OS_ANDROID) || defined(TARGET_ARCH_ARM64) ||                \
    defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
DEFINE_FLAG(int,
            profile_period,
            10000,
            "Time between profiler samples in microseconds. Minimum 50.");
#else
DEFINE_FLAG(int,
            profile_period,
            1000,
            "Time between profiler samples in microseconds. Minimum 50.");
#endif
DEFINE_FLAG(int,
            max_profile_depth,
            kSampleSize* kMaxSamplesPerTick,
            "Maximum number stack frames walked. Minimum 1. Maximum 255.");
#if defined(USING_SIMULATOR)
DEFINE_FLAG(bool, profile_vm, true, "Always collect native stack traces.");
#else
DEFINE_FLAG(bool, profile_vm, false, "Always collect native stack traces.");
#endif

#ifndef PRODUCT

bool Profiler::initialized_ = false;
SampleBuffer* Profiler::sample_buffer_ = NULL;
ProfilerCounters Profiler::counters_;

void Profiler::InitOnce() {
  // Place some sane restrictions on user controlled flags.
  SetSamplePeriod(FLAG_profile_period);
  SetSampleDepth(FLAG_max_profile_depth);
  Sample::InitOnce();
  if (!FLAG_profiler) {
    return;
  }
  ASSERT(!initialized_);
  sample_buffer_ = new SampleBuffer();
  // Zero counters.
  memset(&counters_, 0, sizeof(counters_));
  NativeSymbolResolver::InitOnce();
  ThreadInterrupter::SetInterruptPeriod(FLAG_profile_period);
  ThreadInterrupter::Startup();
  initialized_ = true;
}


void Profiler::Shutdown() {
  if (!FLAG_profiler) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Shutdown();
  NativeSymbolResolver::ShutdownOnce();
}


void Profiler::SetSampleDepth(intptr_t depth) {
  const int kMinimumDepth = 2;
  const int kMaximumDepth = 255;
  if (depth < kMinimumDepth) {
    FLAG_max_profile_depth = kMinimumDepth;
  } else if (depth > kMaximumDepth) {
    FLAG_max_profile_depth = kMaximumDepth;
  } else {
    FLAG_max_profile_depth = depth;
  }
}


void Profiler::SetSamplePeriod(intptr_t period) {
  const int kMinimumProfilePeriod = 50;
  if (period < kMinimumProfilePeriod) {
    FLAG_profile_period = kMinimumProfilePeriod;
  } else {
    FLAG_profile_period = period;
  }
}


intptr_t Sample::pcs_length_ = 0;
intptr_t Sample::instance_size_ = 0;


void Sample::InitOnce() {
  pcs_length_ = kSampleSize;
  instance_size_ = sizeof(Sample) + (sizeof(uword) * pcs_length_);  // NOLINT.
}


uword* Sample::GetPCArray() const {
  return reinterpret_cast<uword*>(reinterpret_cast<uintptr_t>(this) +
                                  sizeof(*this));
}


SampleBuffer::SampleBuffer(intptr_t capacity) {
  ASSERT(Sample::instance_size() > 0);
  samples_ =
      reinterpret_cast<Sample*>(calloc(capacity, Sample::instance_size()));
  if (FLAG_trace_profiler) {
    OS::Print("Profiler holds %" Pd " samples\n", capacity);
    OS::Print("Profiler sample is %" Pd " bytes\n", Sample::instance_size());
    OS::Print("Profiler memory usage = %" Pd " bytes\n",
              capacity * Sample::instance_size());
  }
  capacity_ = capacity;
  cursor_ = 0;
}


Sample* SampleBuffer::At(intptr_t idx) const {
  ASSERT(idx >= 0);
  ASSERT(idx < capacity_);
  intptr_t offset = idx * Sample::instance_size();
  uint8_t* samples = reinterpret_cast<uint8_t*>(samples_);
  return reinterpret_cast<Sample*>(samples + offset);
}


intptr_t SampleBuffer::ReserveSampleSlot() {
  ASSERT(samples_ != NULL);
  uintptr_t cursor = AtomicOperations::FetchAndIncrement(&cursor_);
  // Map back into sample buffer range.
  cursor = cursor % capacity_;
  return cursor;
}

Sample* SampleBuffer::ReserveSample() {
  return At(ReserveSampleSlot());
}


Sample* SampleBuffer::ReserveSampleAndLink(Sample* previous) {
  ASSERT(previous != NULL);
  intptr_t next_index = ReserveSampleSlot();
  Sample* next = At(next_index);
  next->Init(previous->isolate(), previous->timestamp(), previous->tid());
  next->set_head_sample(false);
  // Mark that previous continues at next.
  previous->SetContinuationIndex(next_index);
  return next;
}


// Attempts to find the true return address when a Dart frame is being setup
// or torn down.
// NOTE: Architecture specific implementations below.
class ReturnAddressLocator : public ValueObject {
 public:
  ReturnAddressLocator(Sample* sample, const Code& code)
      : stack_buffer_(sample->GetStackBuffer()),
        pc_(sample->pc()),
        code_(Code::ZoneHandle(code.raw())) {
    ASSERT(!code_.IsNull());
    ASSERT(code_.ContainsInstructionAt(pc()));
  }

  ReturnAddressLocator(uword pc, uword* stack_buffer, const Code& code)
      : stack_buffer_(stack_buffer),
        pc_(pc),
        code_(Code::ZoneHandle(code.raw())) {
    ASSERT(!code_.IsNull());
    ASSERT(code_.ContainsInstructionAt(pc_));
  }

  uword pc() { return pc_; }

  // Returns false on failure.
  bool LocateReturnAddress(uword* return_address);

  // Returns offset into code object.
  intptr_t RelativePC() {
    ASSERT(pc() >= code_.PayloadStart());
    return static_cast<intptr_t>(pc() - code_.PayloadStart());
  }

  uint8_t* CodePointer(intptr_t offset) {
    const intptr_t size = code_.Size();
    ASSERT(offset < size);
    uint8_t* code_pointer = reinterpret_cast<uint8_t*>(code_.PayloadStart());
    code_pointer += offset;
    return code_pointer;
  }

  uword StackAt(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < Sample::kStackBufferSizeInWords);
    return stack_buffer_[i];
  }

 private:
  uword* stack_buffer_;
  uword pc_;
  const Code& code_;
};


#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  const intptr_t offset = RelativePC();
  ASSERT(offset >= 0);
  const intptr_t size = code_.Size();
  ASSERT(offset < size);
  const intptr_t prologue_offset = code_.GetPrologueOffset();
  if (offset < prologue_offset) {
    // Before the prologue, return address is at the top of the stack.
    // TODO(johnmccutchan): Some intrinsics and stubs do not conform to the
    // expected stack layout. Use a more robust solution for those code objects.
    *return_address = StackAt(0);
    return true;
  }
  // Detect if we are:
  // push ebp      <--- here
  // mov ebp, esp
  // on X64 the register names are different but the sequence is the same.
  ProloguePattern pp(pc());
  if (pp.IsValid()) {
    // Stack layout:
    // 0 RETURN ADDRESS.
    *return_address = StackAt(0);
    return true;
  }
  // Detect if we are:
  // push ebp
  // mov ebp, esp  <--- here
  // on X64 the register names are different but the sequence is the same.
  SetFramePointerPattern sfpp(pc());
  if (sfpp.IsValid()) {
    // Stack layout:
    // 0 CALLER FRAME POINTER
    // 1 RETURN ADDRESS
    *return_address = StackAt(1);
    return true;
  }
  // Detect if we are:
  // ret           <--- here
  ReturnPattern rp(pc());
  if (rp.IsValid()) {
    // Stack layout:
    // 0 RETURN ADDRESS.
    *return_address = StackAt(0);
    return true;
  }
  return false;
}
#elif defined(TARGET_ARCH_ARM)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  return false;
}
#elif defined(TARGET_ARCH_ARM64)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  return false;
}
#elif defined(TARGET_ARCH_MIPS)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  return false;
}
#elif defined(TARGET_ARCH_DBC)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  return false;
}
#else
#error ReturnAddressLocator implementation missing for this architecture.
#endif


bool SampleFilter::TimeFilterSample(Sample* sample) {
  if ((time_origin_micros_ == -1) || (time_extent_micros_ == -1)) {
    // No time filter passed in, always pass.
    return true;
  }
  const int64_t timestamp = sample->timestamp();
  int64_t delta = timestamp - time_origin_micros_;
  return (delta >= 0) && (delta <= time_extent_micros_);
}


bool SampleFilter::TaskFilterSample(Sample* sample) {
  const intptr_t task = static_cast<intptr_t>(sample->thread_task());
  return (task & thread_task_mask_) != 0;
}


ClearProfileVisitor::ClearProfileVisitor(Isolate* isolate)
    : SampleVisitor(isolate) {}


void ClearProfileVisitor::VisitSample(Sample* sample) {
  sample->Clear();
}


static void DumpStackFrame(intptr_t frame_index, uword pc) {
  uintptr_t start = 0;
  char* native_symbol_name = NativeSymbolResolver::LookupSymbolName(pc, &start);
  if (native_symbol_name == NULL) {
    OS::PrintErr("  [0x%" Pp "] Unknown symbol\n", pc);
  } else {
    OS::PrintErr("  [0x%" Pp "] %s\n", pc, native_symbol_name);
    NativeSymbolResolver::FreeSymbolName(native_symbol_name);
  }
}


static void DumpStackFrame(intptr_t frame_index, uword pc, const Code& code) {
  if (code.IsNull()) {
    DumpStackFrame(frame_index, pc);
  } else {
    OS::PrintErr("Frame[%" Pd "] = Dart:`%s` [0x%" Px "]\n", frame_index,
                 code.ToCString(), pc);
  }
}


class ProfilerStackWalker : public ValueObject {
 public:
  ProfilerStackWalker(Isolate* isolate,
                      Sample* head_sample,
                      SampleBuffer* sample_buffer)
      : isolate_(isolate),
        sample_(head_sample),
        sample_buffer_(sample_buffer),
        frame_index_(0),
        total_frames_(0) {
    ASSERT(isolate_ != NULL);
    if (sample_ == NULL) {
      ASSERT(sample_buffer_ == NULL);
    } else {
      ASSERT(sample_buffer_ != NULL);
      ASSERT(sample_->head_sample());
    }
  }

  bool Append(uword pc, const Code& code) {
    if (sample_ == NULL) {
      DumpStackFrame(frame_index_, pc, code);
      frame_index_++;
      total_frames_++;
      return true;
    }
    return Append(pc);
  }

  bool Append(uword pc) {
    if (sample_ == NULL) {
      DumpStackFrame(frame_index_, pc);
      frame_index_++;
      total_frames_++;
      return true;
    }
    if (total_frames_ >= FLAG_max_profile_depth) {
      sample_->set_truncated_trace(true);
      return false;
    }
    ASSERT(sample_ != NULL);
    if (frame_index_ == kSampleSize) {
      Sample* new_sample = sample_buffer_->ReserveSampleAndLink(sample_);
      if (new_sample == NULL) {
        // Could not reserve new sample- mark this as truncated.
        sample_->set_truncated_trace(true);
        return false;
      }
      frame_index_ = 0;
      sample_ = new_sample;
    }
    ASSERT(frame_index_ < kSampleSize);
    sample_->SetAt(frame_index_, pc);
    frame_index_++;
    total_frames_++;
    return true;
  }

 protected:
  Isolate* isolate_;
  Sample* sample_;
  SampleBuffer* sample_buffer_;
  intptr_t frame_index_;
  intptr_t total_frames_;
};


// Executing Dart code, walk the stack.
class ProfilerDartStackWalker : public ProfilerStackWalker {
 public:
  ProfilerDartStackWalker(Thread* thread,
                          Sample* sample,
                          SampleBuffer* sample_buffer,
                          uword stack_lower,
                          uword stack_upper,
                          uword pc,
                          uword fp,
                          uword sp,
                          bool exited_dart_code,
                          bool allocation_sample)
      : ProfilerStackWalker(thread->isolate(), sample, sample_buffer),
        pc_(reinterpret_cast<uword*>(pc)),
        fp_(reinterpret_cast<uword*>(fp)),
        sp_(reinterpret_cast<uword*>(sp)),
        stack_upper_(stack_upper),
        stack_lower_(stack_lower),
        has_exit_frame_(exited_dart_code) {
    if (exited_dart_code) {
      StackFrameIterator iterator(StackFrameIterator::kDontValidateFrames,
                                  thread);
      pc_ = NULL;
      fp_ = NULL;
      sp_ = NULL;
      if (!iterator.HasNextFrame()) {
        return;
      }
      // Ensure we are able to get to the exit frame.
      StackFrame* frame = iterator.NextFrame();
      if (!frame->IsExitFrame()) {
        return;
      }
      // Skip the exit frame.
      if (!iterator.HasNextFrame()) {
        return;
      }
      frame = iterator.NextFrame();
      // Record frame details of the first frame from which we start walking.
      pc_ = reinterpret_cast<uword*>(frame->pc());
      fp_ = reinterpret_cast<uword*>(frame->fp());
      sp_ = reinterpret_cast<uword*>(frame->sp());
    }
  }

  void walk() {
    sample_->set_exit_frame_sample(has_exit_frame_);
    if (!ValidFramePointer()) {
      sample_->set_ignore_sample(true);
      return;
    }
    ASSERT(ValidFramePointer());
    uword return_pc = InitialReturnAddress();
    if (StubCode::InInvocationStub(return_pc)) {
      // Edge case- we have called out from the Invocation Stub but have not
      // created the stack frame of the callee. Attempt to locate the exit
      // frame before walking the stack.
      if (!NextExit() || !ValidFramePointer()) {
        // Nothing to sample.
        sample_->set_ignore_sample(true);
        return;
      }
    }
    while (true) {
      if (!Append(reinterpret_cast<uword>(pc_))) {
        return;
      }
      if (!Next()) {
        return;
      }
    }
  }

 private:
  bool Next() {
    if (!ValidFramePointer()) {
      return false;
    }
    if (StubCode::InInvocationStub(reinterpret_cast<uword>(pc_))) {
      // In invocation stub.
      return NextExit();
    }
    // In regular Dart frame.
    uword* new_pc = CallerPC();
    // Check if we've moved into the invocation stub.
    if (StubCode::InInvocationStub(reinterpret_cast<uword>(new_pc))) {
      // New PC is inside invocation stub, skip.
      return NextExit();
    }
    uword* new_fp = CallerFP();
    if (!IsCalleeFrameOf(reinterpret_cast<uword>(new_fp),
                         reinterpret_cast<uword>(fp_))) {
      // FP didn't move to a caller (higher address on most architectures).
      return false;
    }
    // Success, update fp and pc.
    fp_ = new_fp;
    pc_ = new_pc;
    return true;
  }

  bool NextExit() {
    if (!ValidFramePointer()) {
      return false;
    }
    uword* new_fp = ExitLink();
    if (new_fp == NULL) {
      // No exit link.
      return false;
    }
    if (new_fp <= fp_) {
      // FP didn't move to a higher address.
      return false;
    }
    if (!ValidFramePointer(new_fp)) {
      return false;
    }
    // Success, update fp and pc.
    fp_ = new_fp;
    pc_ = CallerPC();
    return true;
  }

  uword InitialReturnAddress() const {
    ASSERT(sp_ != NULL);
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(sp_, kWordSize);
    ASAN_UNPOISON(sp_, kWordSize);
    return *(sp_);
  }

  uword* CallerPC() const {
    ASSERT(fp_ != NULL);
    uword* caller_pc_ptr = fp_ + kSavedCallerPcSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(caller_pc_ptr, kWordSize);
    ASAN_UNPOISON(caller_pc_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_pc_ptr);
  }

  uword* CallerFP() const {
    ASSERT(fp_ != NULL);
    uword* caller_fp_ptr = fp_ + kSavedCallerFpSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(caller_fp_ptr, kWordSize);
    ASAN_UNPOISON(caller_fp_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_fp_ptr);
  }

  uword* ExitLink() const {
    ASSERT(fp_ != NULL);
    uword* exit_link_ptr = fp_ + kExitLinkSlotFromEntryFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(exit_link_ptr, kWordSize);
    ASAN_UNPOISON(exit_link_ptr, kWordSize);
    return reinterpret_cast<uword*>(*exit_link_ptr);
  }

  bool ValidFramePointer() const { return ValidFramePointer(fp_); }

  bool ValidFramePointer(uword* fp) const {
    if (fp == NULL) {
      return false;
    }
    uword cursor = reinterpret_cast<uword>(fp);
    cursor += sizeof(fp);
    return (cursor >= stack_lower_) && (cursor < stack_upper_);
  }

  uword* pc_;
  uword* fp_;
  uword* sp_;
  const uword stack_upper_;
  const uword stack_lower_;
  bool has_exit_frame_;
};


// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail.
//
class ProfilerNativeStackWalker : public ProfilerStackWalker {
 public:
  ProfilerNativeStackWalker(Isolate* isolate,
                            Sample* sample,
                            SampleBuffer* sample_buffer,
                            uword stack_lower,
                            uword stack_upper,
                            uword pc,
                            uword fp,
                            uword sp)
      : ProfilerStackWalker(isolate, sample, sample_buffer),
        stack_upper_(stack_upper),
        original_pc_(pc),
        original_fp_(fp),
        original_sp_(sp),
        lower_bound_(stack_lower) {}

  void walk() {
    const uword kMaxStep = VirtualMemory::PageSize();
    Append(original_pc_);

    uword* pc = reinterpret_cast<uword*>(original_pc_);
    uword* fp = reinterpret_cast<uword*>(original_fp_);
    uword* previous_fp = fp;

    uword gap = original_fp_ - original_sp_;
    if (gap >= kMaxStep) {
      // Gap between frame pointer and stack pointer is
      // too large.
      return;
    }

    if (!ValidFramePointer(fp)) {
      return;
    }

    while (true) {
      if (!Append(reinterpret_cast<uword>(pc))) {
        return;
      }

      pc = CallerPC(fp);
      previous_fp = fp;
      fp = CallerFP(fp);

      if (fp == NULL) {
        return;
      }

      if (fp <= previous_fp) {
        // Frame pointer did not move to a higher address.
        return;
      }

      gap = fp - previous_fp;
      if (gap >= kMaxStep) {
        // Frame pointer step is too large.
        return;
      }

      if (!ValidFramePointer(fp)) {
        // Frame pointer is outside of isolate stack boundary.
        return;
      }

      // Move the lower bound up.
      lower_bound_ = reinterpret_cast<uword>(fp);
    }
  }

 private:
  uword* CallerPC(uword* fp) const {
    ASSERT(fp != NULL);
    uword* caller_pc_ptr = fp + kSavedCallerPcSlotFromFp;
    // This may actually be uninitialized, by design (see class comment above).
    MSAN_UNPOISON(caller_pc_ptr, kWordSize);
    ASAN_UNPOISON(caller_pc_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_pc_ptr);
  }

  uword* CallerFP(uword* fp) const {
    ASSERT(fp != NULL);
    uword* caller_fp_ptr = fp + kSavedCallerFpSlotFromFp;
    // This may actually be uninitialized, by design (see class comment above).
    MSAN_UNPOISON(caller_fp_ptr, kWordSize);
    ASAN_UNPOISON(caller_fp_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_fp_ptr);
  }

  bool ValidFramePointer(uword* fp) const {
    if (fp == NULL) {
      return false;
    }
    uword cursor = reinterpret_cast<uword>(fp);
    cursor += sizeof(fp);
    bool r = (cursor >= lower_bound_) && (cursor < stack_upper_);
    return r;
  }

  const uword stack_upper_;
  const uword original_pc_;
  const uword original_fp_;
  const uword original_sp_;
  uword lower_bound_;
};


static void CopyStackBuffer(Sample* sample, uword sp_addr) {
  ASSERT(sample != NULL);
  uword* sp = reinterpret_cast<uword*>(sp_addr);
  uword* buffer = sample->GetStackBuffer();
  if (sp != NULL) {
    for (intptr_t i = 0; i < Sample::kStackBufferSizeInWords; i++) {
      MSAN_UNPOISON(sp, kWordSize);
      ASAN_UNPOISON(sp, kWordSize);
      buffer[i] = *sp;
      sp++;
    }
  }
}


#if defined(TARGET_OS_WINDOWS)
// On Windows this code is synchronously executed from the thread interrupter
// thread. This means we can safely have a static fault_address.
static uword fault_address = 0;
static LONG GuardPageExceptionFilter(EXCEPTION_POINTERS* ep) {
  fault_address = 0;
  if (ep->ExceptionRecord->ExceptionCode != STATUS_GUARD_PAGE_VIOLATION) {
    return EXCEPTION_CONTINUE_SEARCH;
  }
  // https://goo.gl/p5Fe10
  fault_address = ep->ExceptionRecord->ExceptionInformation[1];
  // Read access.
  ASSERT(ep->ExceptionRecord->ExceptionInformation[0] == 0);
  return EXCEPTION_EXECUTE_HANDLER;
}
#endif

// All memory access done to collect the sample is performed in CollectSample.
static void CollectSample(Isolate* isolate,
                          bool exited_dart_code,
                          bool in_dart_code,
                          Sample* sample,
                          ProfilerNativeStackWalker* native_stack_walker,
                          ProfilerDartStackWalker* dart_stack_walker,
                          uword pc,
                          uword fp,
                          uword sp,
                          ProfilerCounters* counters) {
  ASSERT(counters != NULL);
#if defined(TARGET_OS_WINDOWS)
  // Use structured exception handling to trap guard page access on Windows.
  __try {
#endif

    if (in_dart_code) {
      // We can only trust the stack pointer if we are executing Dart code.
      // See http://dartbug.com/20421 for details.
      CopyStackBuffer(sample, sp);
    }

    if (FLAG_profile_vm) {
      // Always walk the native stack collecting both native and Dart frames.
      AtomicOperations::IncrementInt64By(&counters->stack_walker_native, 1);
      native_stack_walker->walk();
    } else if (StubCode::HasBeenInitialized() && exited_dart_code) {
      AtomicOperations::IncrementInt64By(&counters->stack_walker_dart_exit, 1);
      // We have a valid exit frame info, use the Dart stack walker.
      dart_stack_walker->walk();
    } else if (StubCode::HasBeenInitialized() && in_dart_code) {
      AtomicOperations::IncrementInt64By(&counters->stack_walker_dart, 1);
      // We are executing Dart code. We have frame pointers.
      dart_stack_walker->walk();
    } else {
      AtomicOperations::IncrementInt64By(&counters->stack_walker_none, 1);
      sample->SetAt(0, pc);
    }

#if defined(TARGET_OS_WINDOWS)
    // Use structured exception handling to trap guard page access.
  } __except (GuardPageExceptionFilter(GetExceptionInformation())) {  // NOLINT
    // Sample collection triggered a guard page fault:
    // 1) discard entire sample.
    sample->set_ignore_sample(true);

    // 2) Reenable guard bit on page that triggered the fault.
    // https://goo.gl/5mCsXW
    DWORD new_protect = PAGE_READWRITE | PAGE_GUARD;
    DWORD old_protect = 0;
    BOOL success =
        VirtualProtect(reinterpret_cast<void*>(fault_address),
                       sizeof(fault_address), new_protect, &old_protect);
    USE(success);
    ASSERT(success);
    ASSERT(old_protect == PAGE_READWRITE);
  }
#endif
}


// Get |isolate|'s stack boundary and verify that |sp| and |fp| are within
// it. Return |false| if anything looks suspicious.
static bool GetAndValidateIsolateStackBounds(Thread* thread,
                                             uintptr_t fp,
                                             uintptr_t sp,
                                             uword* stack_lower,
                                             uword* stack_upper) {
  ASSERT(thread != NULL);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  ASSERT(stack_lower != NULL);
  ASSERT(stack_upper != NULL);
#if defined(USING_SIMULATOR)
  const bool in_dart_code = thread->IsExecutingDartCode();
  if (in_dart_code) {
    Isolate* isolate = thread->isolate();
    ASSERT(isolate != NULL);
    Simulator* simulator = isolate->simulator();
    *stack_lower = simulator->StackBase();
    *stack_upper = simulator->StackTop();
  } else if (!os_thread->GetProfilerStackBounds(stack_lower, stack_upper)) {
    // Could not get stack boundary.
    return false;
  }
  if ((*stack_lower == 0) || (*stack_upper == 0)) {
    return false;
  }
#else
  if (!os_thread->GetProfilerStackBounds(stack_lower, stack_upper) ||
      (*stack_lower == 0) || (*stack_upper == 0)) {
    // Could not get stack boundary.
    return false;
  }
#endif

#if defined(TARGET_ARCH_DBC)
  if (!in_dart_code && (sp > *stack_lower)) {
    // The stack pointer gives us a tighter lower bound.
    *stack_lower = sp;
  }
#else
  if (sp > *stack_lower) {
    // The stack pointer gives us a tighter lower bound.
    *stack_lower = sp;
  }
#endif

  if (*stack_lower >= *stack_upper) {
    // Stack boundary is invalid.
    return false;
  }

  if ((sp < *stack_lower) || (sp >= *stack_upper)) {
    // Stack pointer is outside thread's stack boundary.
    return false;
  }

  if ((fp < *stack_lower) || (fp >= *stack_upper)) {
    // Frame pointer is outside threads's stack boundary.
    return false;
  }

  return true;
}


// Some simple sanity checking of |pc|, |fp|, and |sp|.
static bool InitialRegisterCheck(uintptr_t pc, uintptr_t fp, uintptr_t sp) {
  if ((sp == 0) || (fp == 0) || (pc == 0)) {
    // None of these registers should be zero.
    return false;
  }

  if (sp > fp) {
    // Assuming the stack grows down, we should never have a stack pointer above
    // the frame pointer.
    return false;
  }

  return true;
}


static Sample* SetupSample(Thread* thread,
                           SampleBuffer* sample_buffer,
                           ThreadId tid) {
  ASSERT(thread != NULL);
  Isolate* isolate = thread->isolate();
  ASSERT(sample_buffer != NULL);
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(isolate, OS::GetCurrentMonotonicMicros(), tid);
  uword vm_tag = thread->vm_tag();
#if defined(USING_SIMULATOR) && !defined(TARGET_ARCH_DBC)
  // When running in the simulator, the runtime entry function address
  // (stored as the vm tag) is the address of a redirect function.
  // Attempt to find the real runtime entry function address and use that.
  uword redirect_vm_tag = Simulator::FunctionForRedirect(vm_tag);
  if (redirect_vm_tag != 0) {
    vm_tag = redirect_vm_tag;
  }
#endif
  sample->set_vm_tag(vm_tag);
  sample->set_user_tag(isolate->user_tag());
  sample->set_thread_task(thread->task_kind());
  return sample;
}


static bool CheckIsolate(Isolate* isolate) {
  if ((isolate == NULL) || (Dart::vm_isolate() == NULL)) {
    // No isolate.
    return false;
  }
  return isolate != Dart::vm_isolate();
}


#if defined(TARGET_OS_WINDOWS)
__declspec(noinline) static uintptr_t GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(_ReturnAddress());
}
#else
static uintptr_t __attribute__((noinline)) GetProgramCounter() {
  return reinterpret_cast<uintptr_t>(
      __builtin_extract_return_addr(__builtin_return_address(0)));
}
#endif


void Profiler::DumpStackTrace(void* context) {
#if defined(TARGET_OS_LINUX) || defined(TARGET_OS_MACOS)
  ucontext_t* ucontext = reinterpret_cast<ucontext_t*>(context);
  mcontext_t mcontext = ucontext->uc_mcontext;
  uword pc = SignalHandler::GetProgramCounter(mcontext);
  uword fp = SignalHandler::GetFramePointer(mcontext);
  uword sp = SignalHandler::GetCStackPointer(mcontext);
  DumpStackTrace(sp, fp, pc);
#else
// TODO(fschneider): Add support for more platforms.
// Do nothing on unsupported platforms.
#endif
}


void Profiler::DumpStackTrace() {
  uintptr_t sp = Thread::GetCurrentStackPointer();
  uintptr_t fp = 0;
  uintptr_t pc = GetProgramCounter();

  COPY_FP_REGISTER(fp);

  DumpStackTrace(sp, fp, pc);
}


void Profiler::DumpStackTrace(uword sp, uword fp, uword pc) {
  // Allow only one stack trace to prevent recursively printing stack traces if
  // we hit an assert while printing the stack.
  static uintptr_t started_dump = 0;
  if (AtomicOperations::FetchAndIncrement(&started_dump) != 0) {
    OS::PrintErr("Aborting re-entrant request for stack trace.\n");
    return;
  }

  Thread* thread = Thread::Current();
  if (thread == NULL) {
    return;
  }
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  Isolate* isolate = thread->isolate();
  if (!CheckIsolate(isolate)) {
    return;
  }

  OS::PrintErr("Dumping native stack trace for thread %" Px "\n",
               OSThread::ThreadIdToIntPtr(os_thread->trace_id()));

  uword stack_lower = 0;
  uword stack_upper = 0;

  if (!InitialRegisterCheck(pc, fp, sp)) {
    OS::PrintErr("Stack dump aborted because InitialRegisterCheck.\n");
    return;
  }

  if (!GetAndValidateIsolateStackBounds(thread, fp, sp, &stack_lower,
                                        &stack_upper)) {
    OS::PrintErr(
        "Stack dump aborted because GetAndValidateIsolateStackBounds.\n");
    return;
  }

  ProfilerNativeStackWalker native_stack_walker(
      isolate, NULL, NULL, stack_lower, stack_upper, pc, fp, sp);
  native_stack_walker.walk();
  OS::PrintErr("-- End of DumpStackTrace\n");
}


void Profiler::SampleAllocation(Thread* thread, intptr_t cid) {
  ASSERT(thread != NULL);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  Isolate* isolate = thread->isolate();
  if (!CheckIsolate(isolate)) {
    return;
  }

  const bool exited_dart_code = thread->HasExitedDartCode();

  SampleBuffer* sample_buffer = Profiler::sample_buffer();
  if (sample_buffer == NULL) {
    // Profiler not initialized.
    return;
  }

  uintptr_t sp = Thread::GetCurrentStackPointer();
  uintptr_t fp = 0;
  uintptr_t pc = GetProgramCounter();

  COPY_FP_REGISTER(fp);

  uword stack_lower = 0;
  uword stack_upper = 0;

  if (!InitialRegisterCheck(pc, fp, sp)) {
    return;
  }

  if (!GetAndValidateIsolateStackBounds(thread, fp, sp, &stack_lower,
                                        &stack_upper)) {
    // Could not get stack boundary.
    return;
  }

  Sample* sample = SetupSample(thread, sample_buffer, os_thread->trace_id());
  sample->SetAllocationCid(cid);

  if (FLAG_profile_vm) {
    ProfilerNativeStackWalker native_stack_walker(
        isolate, sample, sample_buffer, stack_lower, stack_upper, pc, fp, sp);
    native_stack_walker.walk();
  } else if (exited_dart_code) {
    ProfilerDartStackWalker dart_exit_stack_walker(
        thread, sample, sample_buffer, stack_lower, stack_upper, pc, fp, sp,
        exited_dart_code, true);
    dart_exit_stack_walker.walk();
  } else {
    // Fall back.
    uintptr_t pc = GetProgramCounter();
    Sample* sample = SetupSample(thread, sample_buffer, os_thread->trace_id());
    sample->SetAllocationCid(cid);
    sample->SetAt(0, pc);
  }
}


void Profiler::SampleThreadSingleFrame(Thread* thread, uintptr_t pc) {
  ASSERT(thread != NULL);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  Isolate* isolate = thread->isolate();

  SampleBuffer* sample_buffer = Profiler::sample_buffer();
  if (sample_buffer == NULL) {
    // Profiler not initialized.
    return;
  }

  // Setup sample.
  Sample* sample = SetupSample(thread, sample_buffer, os_thread->trace_id());
  // Increment counter for vm tag.
  VMTagCounters* counters = isolate->vm_tag_counters();
  ASSERT(counters != NULL);
  if (thread->IsMutatorThread()) {
    counters->Increment(sample->vm_tag());
  }

  // Write the single pc value.
  sample->SetAt(0, pc);
}


void Profiler::SampleThread(Thread* thread,
                            const InterruptedThreadState& state) {
  ASSERT(thread != NULL);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  Isolate* isolate = thread->isolate();

  // Thread is not doing VM work.
  if (thread->task_kind() == Thread::kUnknownTask) {
    AtomicOperations::IncrementInt64By(&counters_.bail_out_unknown_task, 1);
    return;
  }

  if (StubCode::HasBeenInitialized() && StubCode::InJumpToFrameStub(state.pc)) {
    // The JumpToFrame stub manually adjusts the stack pointer, frame
    // pointer, and some isolate state.  It is not safe to walk the
    // stack when executing this stub.
    AtomicOperations::IncrementInt64By(
        &counters_.bail_out_jump_to_exception_handler, 1);
    return;
  }

  const bool in_dart_code = thread->IsExecutingDartCode();

  uintptr_t sp = 0;
  uintptr_t fp = state.fp;
  uintptr_t pc = state.pc;
#if defined(USING_SIMULATOR)
  Simulator* simulator = NULL;
#endif

  if (in_dart_code) {
// If we're in Dart code, use the Dart stack pointer.
#if defined(TARGET_ARCH_DBC)
    simulator = isolate->simulator();
    sp = simulator->get_sp();
    fp = simulator->get_fp();
    pc = simulator->get_pc();
#elif defined(USING_SIMULATOR)
    simulator = isolate->simulator();
    sp = simulator->get_register(SPREG);
    fp = simulator->get_register(FPREG);
    pc = simulator->get_pc();
#else
    sp = state.dsp;
#endif
  } else {
    // If we're in runtime code, use the C stack pointer.
    sp = state.csp;
  }

  if (!CheckIsolate(isolate)) {
    AtomicOperations::IncrementInt64By(&counters_.bail_out_check_isolate, 1);
    return;
  }

  if (thread->IsMutatorThread() && isolate->IsDeoptimizing()) {
    AtomicOperations::IncrementInt64By(
        &counters_.single_frame_sample_deoptimizing, 1);
    SampleThreadSingleFrame(thread, pc);
    return;
  }

  if (!InitialRegisterCheck(pc, fp, sp)) {
    AtomicOperations::IncrementInt64By(
        &counters_.single_frame_sample_register_check, 1);
    SampleThreadSingleFrame(thread, pc);
    return;
  }

  uword stack_lower = 0;
  uword stack_upper = 0;
  if (!GetAndValidateIsolateStackBounds(thread, fp, sp, &stack_lower,
                                        &stack_upper)) {
    AtomicOperations::IncrementInt64By(
        &counters_.single_frame_sample_get_and_validate_stack_bounds, 1);
    // Could not get stack boundary.
    SampleThreadSingleFrame(thread, pc);
    return;
  }

  // At this point we have a valid stack boundary for this isolate and
  // know that our initial stack and frame pointers are within the boundary.
  SampleBuffer* sample_buffer = Profiler::sample_buffer();
  if (sample_buffer == NULL) {
    // Profiler not initialized.
    return;
  }

  // Setup sample.
  Sample* sample = SetupSample(thread, sample_buffer, os_thread->trace_id());
  // Increment counter for vm tag.
  VMTagCounters* counters = isolate->vm_tag_counters();
  ASSERT(counters != NULL);
  if (thread->IsMutatorThread()) {
    counters->Increment(sample->vm_tag());
  }

  ProfilerNativeStackWalker native_stack_walker(
      isolate, sample, sample_buffer, stack_lower, stack_upper, pc, fp, sp);
  const bool exited_dart_code = thread->HasExitedDartCode();
  ProfilerDartStackWalker dart_stack_walker(thread, sample, sample_buffer,
                                            stack_lower, stack_upper, pc, fp,
                                            sp, exited_dart_code, false);

  // All memory access is done inside CollectSample.
  CollectSample(isolate, exited_dart_code, in_dart_code, sample,
                &native_stack_walker, &dart_stack_walker, pc, fp, sp,
                &counters_);
}


CodeDescriptor::CodeDescriptor(const Code& code) : code_(code) {
  ASSERT(!code_.IsNull());
}


uword CodeDescriptor::Start() const {
  return code_.PayloadStart();
}


uword CodeDescriptor::Size() const {
  return code_.Size();
}


int64_t CodeDescriptor::CompileTimestamp() const {
  return code_.compile_timestamp();
}


CodeLookupTable::CodeLookupTable(Thread* thread) {
  Build(thread);
}


class CodeLookupTableBuilder : public ObjectVisitor {
 public:
  explicit CodeLookupTableBuilder(CodeLookupTable* table) : table_(table) {
    ASSERT(table_ != NULL);
  }

  ~CodeLookupTableBuilder() {}

  void VisitObject(RawObject* raw_obj) {
    uword tags = raw_obj->ptr()->tags_;
    if (RawObject::ClassIdTag::decode(tags) == kCodeCid) {
      RawCode* raw_code = reinterpret_cast<RawCode*>(raw_obj);
      const Code& code = Code::Handle(raw_code);
      ASSERT(!code.IsNull());
      const Instructions& instructions =
          Instructions::Handle(code.instructions());
      ASSERT(!instructions.IsNull());
      table_->Add(code);
    }
  }

 private:
  CodeLookupTable* table_;
};


void CodeLookupTable::Build(Thread* thread) {
  ASSERT(thread != NULL);
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  Isolate* vm_isolate = Dart::vm_isolate();
  ASSERT(vm_isolate != NULL);

  // Clear.
  code_objects_.Clear();

  // Add all found Code objects.
  CodeLookupTableBuilder cltb(this);
  vm_isolate->heap()->IterateOldObjects(&cltb);
  isolate->heap()->IterateOldObjects(&cltb);

  // Sort by entry.
  code_objects_.Sort(CodeDescriptor::Compare);

#if defined(DEBUG)
  if (length() <= 1) {
    return;
  }
  ASSERT(FindCode(0) == NULL);
  ASSERT(FindCode(~0) == NULL);
  // Sanity check that we don't have duplicate entries and that the entries
  // are sorted.
  for (intptr_t i = 0; i < length() - 1; i++) {
    const CodeDescriptor* a = At(i);
    const CodeDescriptor* b = At(i + 1);
    ASSERT(a->Start() < b->Start());
    ASSERT(FindCode(a->Start()) == a);
    ASSERT(FindCode(b->Start()) == b);
    ASSERT(FindCode(a->Start() + a->Size() - 1) == a);
    ASSERT(FindCode(b->Start() + b->Size() - 1) == b);
  }
#endif
}


void CodeLookupTable::Add(const Code& code) {
  ASSERT(!code.IsNull());
  CodeDescriptor* cd = new CodeDescriptor(code);
  code_objects_.Add(cd);
}


const CodeDescriptor* CodeLookupTable::FindCode(uword pc) const {
  intptr_t first = 0;
  intptr_t count = length();
  while (count > 0) {
    intptr_t current = first;
    intptr_t step = count / 2;
    current += step;
    const CodeDescriptor* cd = At(current);
    if (pc >= cd->Start()) {
      first = ++current;
      count -= step + 1;
    } else {
      count = step;
    }
  }
  // First points to the first code object whose entry is greater than PC.
  // That means the code object we need to check is first - 1.
  if (first == 0) {
    return NULL;
  }
  first--;
  ASSERT(first >= 0);
  ASSERT(first < length());
  const CodeDescriptor* cd = At(first);
  if (cd->Contains(pc)) {
    return cd;
  }
  return NULL;
}


ProcessedSampleBuffer* SampleBuffer::BuildProcessedSampleBuffer(
    SampleFilter* filter) {
  ASSERT(filter != NULL);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  ProcessedSampleBuffer* buffer = new (zone) ProcessedSampleBuffer();

  const intptr_t length = capacity();
  for (intptr_t i = 0; i < length; i++) {
    Sample* sample = At(i);
    if (sample->ignore_sample()) {
      // Bad sample.
      continue;
    }
    if (!sample->head_sample()) {
      // An inner sample in a chain of samples.
      continue;
    }
    if (sample->isolate() != filter->isolate()) {
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
    if (!filter->TimeFilterSample(sample)) {
      // Did not pass time filter.
      continue;
    }
    if (!filter->TaskFilterSample(sample)) {
      // Did not pass task filter.
      continue;
    }
    if (!filter->FilterSample(sample)) {
      // Did not pass filter.
      continue;
    }
    buffer->Add(BuildProcessedSample(sample, buffer->code_lookup_table()));
  }
  return buffer;
}


ProcessedSample* SampleBuffer::BuildProcessedSample(
    Sample* sample,
    const CodeLookupTable& clt) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  ProcessedSample* processed_sample = new (zone) ProcessedSample();

  // Copy state bits from sample.
  processed_sample->set_timestamp(sample->timestamp());
  processed_sample->set_tid(sample->tid());
  processed_sample->set_vm_tag(sample->vm_tag());
  processed_sample->set_user_tag(sample->user_tag());
  if (sample->is_allocation_sample()) {
    processed_sample->set_allocation_cid(sample->allocation_cid());
  }
  processed_sample->set_first_frame_executing(!sample->exit_frame_sample());

  // Copy stack trace from sample(s).
  bool truncated = false;
  Sample* current = sample;
  while (current != NULL) {
    for (intptr_t i = 0; i < kSampleSize; i++) {
      if (current->At(i) == 0) {
        break;
      }
      processed_sample->Add(current->At(i));
    }

    truncated = truncated || current->truncated_trace();
    current = Next(current);
  }

  if (!sample->exit_frame_sample()) {
    processed_sample->FixupCaller(clt, sample->pc_marker(),
                                  sample->GetStackBuffer());
  }

  processed_sample->set_truncated(truncated);
  return processed_sample;
}


Sample* SampleBuffer::Next(Sample* sample) {
  if (!sample->is_continuation_sample()) return NULL;
  Sample* next_sample = At(sample->continuation_index());
  // Sanity check.
  ASSERT(sample != next_sample);
  // Detect invalid chaining.
  if (sample->isolate() != next_sample->isolate()) {
    return NULL;
  }
  if (sample->timestamp() != next_sample->timestamp()) {
    return NULL;
  }
  if (sample->tid() != next_sample->tid()) {
    return NULL;
  }
  return next_sample;
}


ProcessedSample::ProcessedSample()
    : pcs_(kSampleSize),
      timestamp_(0),
      vm_tag_(0),
      user_tag_(0),
      allocation_cid_(-1),
      truncated_(false),
      timeline_trie_(NULL) {}


void ProcessedSample::FixupCaller(const CodeLookupTable& clt,
                                  uword pc_marker,
                                  uword* stack_buffer) {
  const CodeDescriptor* cd = clt.FindCode(At(0));
  if (cd == NULL) {
    // No Dart code.
    return;
  }
  if (cd->CompileTimestamp() > timestamp()) {
    // Code compiled after sample. Ignore.
    return;
  }
  CheckForMissingDartFrame(clt, cd, pc_marker, stack_buffer);
}


void ProcessedSample::CheckForMissingDartFrame(const CodeLookupTable& clt,
                                               const CodeDescriptor* cd,
                                               uword pc_marker,
                                               uword* stack_buffer) {
  ASSERT(cd != NULL);
  const Code& code = Code::Handle(cd->code());
  ASSERT(!code.IsNull());
  // Some stubs (and intrinsics) do not push a frame onto the stack leaving
  // the frame pointer in the caller.
  //
  // PC -> STUB
  // FP -> DART3  <-+
  //       DART2  <-|  <- TOP FRAME RETURN ADDRESS.
  //       DART1  <-|
  //       .....
  //
  // In this case, traversing the linked stack frames will not collect a PC
  // inside DART3. The stack will incorrectly be: STUB, DART2, DART1.
  // In Dart code, after pushing the FP onto the stack, an IP in the current
  // function is pushed onto the stack as well. This stack slot is called
  // the PC marker. We can use the PC marker to insert DART3 into the stack
  // so that it will correctly be: STUB, DART3, DART2, DART1. Note the
  // inserted PC may not accurately reflect the true return address into DART3.

  // The pc marker is our current best guess of a return address.
  uword return_address = pc_marker;

  // Attempt to find a better return address.
  ReturnAddressLocator ral(At(0), stack_buffer, code);

  if (!ral.LocateReturnAddress(&return_address)) {
    ASSERT(return_address == pc_marker);
    if (code.GetPrologueOffset() == 0) {
      // Code has the prologue at offset 0. The frame is already setup and
      // can be trusted.
      return;
    }
    // Could not find a better return address than the pc_marker.
    if (code.ContainsInstructionAt(return_address)) {
      // PC marker is in the same code as pc, no missing frame.
      return;
    }
  }

  if (clt.FindCode(return_address) == NULL) {
    // Return address is not from a Dart code object. Do not insert.
    return;
  }

  if (return_address != 0) {
    InsertAt(1, return_address);
  }
}


ProcessedSampleBuffer::ProcessedSampleBuffer()
    : code_lookup_table_(new CodeLookupTable(Thread::Current())) {
  ASSERT(code_lookup_table_ != NULL);
}

#endif  // !PRODUCT

}  // namespace dart
