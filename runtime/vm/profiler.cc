// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/address_sanitizer.h"
#include "platform/memory_sanitizer.h"
#include "platform/utils.h"

#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/code_patcher.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"

namespace dart {


#if defined(TARGET_OS_ANDROID) || defined(HOST_ARCH_ARM64)
  DEFINE_FLAG(bool, profile, false, "Enable Sampling Profiler");
#else
  DEFINE_FLAG(bool, profile, true, "Enable Sampling Profiler");
#endif
DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");
DEFINE_FLAG(bool, trace_profiler, false, "Trace profiler.");
DEFINE_FLAG(int, profile_period, 1000,
            "Time between profiler samples in microseconds. Minimum 50.");
DEFINE_FLAG(int, profile_depth, 8,
            "Maximum number stack frames walked. Minimum 1. Maximum 255.");
#if defined(PROFILE_NATIVE_CODE) || defined(USING_SIMULATOR)
DEFINE_FLAG(bool, profile_vm, true,
            "Always collect native stack traces.");
#else
DEFINE_FLAG(bool, profile_vm, false,
            "Always collect native stack traces.");
#endif

bool Profiler::initialized_ = false;
SampleBuffer* Profiler::sample_buffer_ = NULL;

void Profiler::InitOnce() {
  // Place some sane restrictions on user controlled flags.
  SetSamplePeriod(FLAG_profile_period);
  SetSampleDepth(FLAG_profile_depth);
  Sample::InitOnce();
  if (!FLAG_profile) {
    return;
  }
  ASSERT(!initialized_);
  sample_buffer_ = new SampleBuffer();
  NativeSymbolResolver::InitOnce();
  ThreadInterrupter::SetInterruptPeriod(FLAG_profile_period);
  ThreadInterrupter::Startup();
  initialized_ = true;
}


void Profiler::Shutdown() {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Shutdown();
  NativeSymbolResolver::ShutdownOnce();
}


void Profiler::SetSampleDepth(intptr_t depth) {
  const int kMinimumDepth = 1;
  const int kMaximumDepth = 255;
  if (depth < kMinimumDepth) {
    FLAG_profile_depth = kMinimumDepth;
  } else if (depth > kMaximumDepth) {
    FLAG_profile_depth = kMaximumDepth;
  } else {
    FLAG_profile_depth = depth;
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


void Profiler::InitProfilingForIsolate(Isolate* isolate, bool shared_buffer) {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(isolate == Isolate::Current());
  ASSERT(isolate != NULL);
  ASSERT(sample_buffer_ != NULL);
  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    SampleBuffer* sample_buffer = sample_buffer_;
    if (!shared_buffer) {
      sample_buffer = new SampleBuffer();
    }
    IsolateProfilerData* profiler_data =
        new IsolateProfilerData(sample_buffer, !shared_buffer);
    ASSERT(profiler_data != NULL);
    isolate->set_profiler_data(profiler_data);
    if (FLAG_trace_profiled_isolates) {
      OS::Print("Profiler Setup %p %s\n", isolate, isolate->name());
    }
  }
  BeginExecution(isolate);
}


void Profiler::ShutdownProfilingForIsolate(Isolate* isolate) {
  ASSERT(isolate != NULL);
  if (!FLAG_profile) {
    return;
  }
  // We do not have a current isolate.
  ASSERT(Isolate::Current() == NULL);
  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if (profiler_data == NULL) {
      // Already freed.
      return;
    }
    isolate->set_profiler_data(NULL);
    delete profiler_data;
    if (FLAG_trace_profiled_isolates) {
      OS::Print("Profiler Shutdown %p %s\n", isolate, isolate->name());
    }
  }
}


void Profiler::BeginExecution(Isolate* isolate) {
  if (isolate == NULL) {
    return;
  }
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  ThreadInterrupter::Register(RecordSampleInterruptCallback, isolate);
  ThreadInterrupter::WakeUp();
}


void Profiler::EndExecution(Isolate* isolate) {
  if (isolate == NULL) {
    return;
  }
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Unregister();
}


IsolateProfilerData::IsolateProfilerData(SampleBuffer* sample_buffer,
                                         bool own_sample_buffer) {
  ASSERT(sample_buffer != NULL);
  sample_buffer_ = sample_buffer;
  own_sample_buffer_ = own_sample_buffer;
  block_count_ = 0;
}


IsolateProfilerData::~IsolateProfilerData() {
  if (own_sample_buffer_) {
    delete sample_buffer_;
    sample_buffer_ = NULL;
    own_sample_buffer_ = false;
  }
}


void IsolateProfilerData::Block() {
  block_count_++;
}


void IsolateProfilerData::Unblock() {
  block_count_--;
  if (block_count_ < 0) {
    FATAL("Too many calls to Dart_IsolateUnblocked.");
  }
  if (!blocked()) {
    // We just unblocked this isolate, wake up the thread interrupter.
    ThreadInterrupter::WakeUp();
  }
}


intptr_t Sample::pcs_length_ = 0;
intptr_t Sample::instance_size_ = 0;


void Sample::InitOnce() {
  ASSERT(FLAG_profile_depth >= 1);
  pcs_length_ = FLAG_profile_depth;
  instance_size_ =
      sizeof(Sample) + (sizeof(uword) * pcs_length_);  // NOLINT.
}


uword* Sample::GetPCArray() const {
  return reinterpret_cast<uword*>(
        reinterpret_cast<uintptr_t>(this) + sizeof(*this));
}


SampleBuffer::SampleBuffer(intptr_t capacity) {
  ASSERT(Sample::instance_size() > 0);
  samples_ = reinterpret_cast<Sample*>(
      calloc(capacity, Sample::instance_size()));
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


Sample* SampleBuffer::ReserveSample() {
  ASSERT(samples_ != NULL);
  uintptr_t cursor = AtomicOperations::FetchAndIncrement(&cursor_);
  // Map back into sample buffer range.
  cursor = cursor % capacity_;
  return At(cursor);
}


static void SetPCMarkerIfSafe(Sample* sample) {
  ASSERT(sample != NULL);

  uword* fp = reinterpret_cast<uword*>(sample->fp());
  uword* sp = reinterpret_cast<uword*>(sample->sp());

  // If FP == SP, the pc marker hasn't been pushed.
  if (fp > sp) {
#if defined(TARGET_OS_WINDOWS)
    // If the fp is at the beginning of a page, it may be unsafe to access
    // the pc marker, because we are reading it from a different thread on
    // Windows. The marker is below fp and the previous page may be a guard
    // page.
    const intptr_t kPageMask = VirtualMemory::PageSize() - 1;
    if ((sample->fp() & kPageMask) == 0) {
      return;
    }
#endif
    uword* pc_marker_ptr = fp + kPcMarkerSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(pc_marker_ptr, kWordSize);
    ASAN_UNPOISON(pc_marker_ptr, kWordSize);
    sample->set_pc_marker(*pc_marker_ptr);
  }
}


// Given an exit frame, walk the Dart stack.
class ProfilerDartExitStackWalker : public ValueObject {
 public:
  ProfilerDartExitStackWalker(Isolate* isolate, Sample* sample)
      : sample_(sample),
        frame_iterator_(isolate) {
    ASSERT(sample_ != NULL);
    // Mark that this sample was collected from an exit frame.
    sample_->set_exit_frame_sample(true);
  }

  void walk() {
    intptr_t frame_index = 0;
    StackFrame* frame = frame_iterator_.NextFrame();
    while (frame != NULL) {
      sample_->SetAt(frame_index, frame->pc());
      frame_index++;
      if (frame_index >= FLAG_profile_depth) {
        break;
      }
      frame = frame_iterator_.NextFrame();
    }
  }

 private:
  Sample* sample_;
  DartFrameIterator frame_iterator_;
};


// Executing Dart code, walk the stack.
class ProfilerDartStackWalker : public ValueObject {
 public:
  ProfilerDartStackWalker(Isolate* isolate,
                          Sample* sample,
                          uword stack_lower,
                          uword stack_upper,
                          uword pc,
                          uword fp,
                          uword sp)
      : isolate_(isolate),
        sample_(sample),
        stack_upper_(stack_upper),
        stack_lower_(stack_lower) {
    ASSERT(sample_ != NULL);
    pc_ = reinterpret_cast<uword*>(pc);
    fp_ = reinterpret_cast<uword*>(fp);
    sp_ = reinterpret_cast<uword*>(sp);
  }

  void walk() {
    if (!ValidFramePointer()) {
      sample_->set_ignore_sample(true);
      return;
    }
    ASSERT(ValidFramePointer());
    uword return_pc = InitialReturnAddress();
    if (StubCode::InInvocationStubForIsolate(isolate_, return_pc)) {
      // Edge case- we have called out from the Invocation Stub but have not
      // created the stack frame of the callee. Attempt to locate the exit
      // frame before walking the stack.
      if (!NextExit() || !ValidFramePointer()) {
        // Nothing to sample.
        sample_->set_ignore_sample(true);
        return;
      }
    }
    for (int i = 0; i < FLAG_profile_depth; i++) {
      sample_->SetAt(i, reinterpret_cast<uword>(pc_));
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
    if (StubCode::InInvocationStubForIsolate(isolate_,
                                             reinterpret_cast<uword>(pc_))) {
      // In invocation stub.
      return NextExit();
    }
    // In regular Dart frame.
    uword* new_pc = CallerPC();
    // Check if we've moved into the invocation stub.
    if (StubCode::InInvocationStubForIsolate(isolate_,
                                             reinterpret_cast<uword>(new_pc))) {
      // New PC is inside invocation stub, skip.
      return NextExit();
    }
    uword* new_fp = CallerFP();
    if (new_fp <= fp_) {
      // FP didn't move to a higher address.
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

  bool ValidFramePointer() const {
    return ValidFramePointer(fp_);
  }

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
  Isolate* isolate_;
  Sample* sample_;
  const uword stack_upper_;
  uword stack_lower_;
};


// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail.
//
class ProfilerNativeStackWalker : public ValueObject {
 public:
  ProfilerNativeStackWalker(Sample* sample,
                            uword stack_lower,
                            uword stack_upper,
                            uword pc,
                            uword fp,
                            uword sp)
      : sample_(sample),
        stack_upper_(stack_upper),
        original_pc_(pc),
        original_fp_(fp),
        original_sp_(sp),
        lower_bound_(stack_lower) {
    ASSERT(sample_ != NULL);
  }

  void walk() {
    const uword kMaxStep = VirtualMemory::PageSize();

    sample_->SetAt(0, original_pc_);

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

    for (int i = 0; i < FLAG_profile_depth; i++) {
      sample_->SetAt(i, reinterpret_cast<uword>(pc));

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

  Sample* sample_;
  const uword stack_upper_;
  const uword original_pc_;
  const uword original_fp_;
  const uword original_sp_;
  uword lower_bound_;
};


void Profiler::RecordSampleInterruptCallback(
    const InterruptedThreadState& state,
    void* data) {
  Isolate* isolate = reinterpret_cast<Isolate*>(data);
  if ((isolate == NULL) || (Dart::vm_isolate() == NULL)) {
    // No isolate.
    return;
  }

  ASSERT(isolate != Dart::vm_isolate());

  uintptr_t sp = 0;
  if ((isolate->stub_code() != NULL) &&
      (isolate->top_exit_frame_info() == 0) &&
      (isolate->vm_tag() == VMTag::kDartTagId)) {
    // If we're in Dart code, use the Dart stack pointer.
    sp = state.dsp;
  } else {
    // If we're in runtime code, use the C stack pointer.
    sp = state.csp;
  }

  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    // Profiler not initialized.
    return;
  }

  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  if (sample_buffer == NULL) {
    // Profiler not initialized.
    return;
  }

  if ((sp == 0) || (state.fp == 0) || (state.pc == 0)) {
    // None of these registers should be zero.
    return;
  }

  if (sp > state.fp) {
    // Assuming the stack grows down, we should never have a stack pointer above
    // the frame pointer.
    return;
  }

  if (StubCode::InJumpToExceptionHandlerStub(state.pc)) {
    // The JumpToExceptionHandler stub manually adjusts the stack pointer,
    // frame pointer, and some isolate state before jumping to a catch entry.
    // It is not safe to walk the stack when executing this stub.
    return;
  }

  uword stack_lower = 0;
  uword stack_upper = 0;
  if (!isolate->GetProfilerStackBounds(&stack_lower, &stack_upper) ||
      (stack_lower == 0) || (stack_upper == 0)) {
    // Could not get stack boundary.
    return;
  }

  if (sp > stack_lower) {
    // The stack pointer gives us a tighter lower bound.
    stack_lower = sp;
  }

  if (stack_lower >= stack_upper) {
    // Stack boundary is invalid.
    return;
  }

  if ((sp < stack_lower) || (sp >= stack_upper)) {
    // Stack pointer is outside isolate stack boundary.
    return;
  }

  if ((state.fp < stack_lower) || (state.fp >= stack_upper)) {
    // Frame pointer is outside isolate stack boundary.
    return;
  }

  // At this point we have a valid stack boundary for this isolate and
  // know that our initial stack and frame pointers are within the boundary.

  // Setup sample.
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(isolate, OS::GetCurrentTimeMicros(), state.tid);
  uword vm_tag = isolate->vm_tag();
#if defined(USING_SIMULATOR)
  // When running in the simulator, the runtime entry function address
  // (stored as the vm tag) is the address of a redirect function.
  // Attempt to find the real runtime entry function address and use that.
  uword redirect_vm_tag = Simulator::FunctionForRedirect(vm_tag);
  if (redirect_vm_tag != 0) {
    vm_tag = redirect_vm_tag;
  }
#endif
  // Increment counter for vm tag.
  VMTagCounters* counters = isolate->vm_tag_counters();
  ASSERT(counters != NULL);
  counters->Increment(vm_tag);
  sample->set_vm_tag(vm_tag);
  sample->set_user_tag(isolate->user_tag());
  sample->set_sp(sp);
  sample->set_fp(state.fp);
#if !(defined(TARGET_OS_WINDOWS) && defined(TARGET_ARCH_X64))
  // It is never safe to read other thread's stack unless on Win64
  // other thread is inside Dart code.
  SetPCMarkerIfSafe(sample);
#endif

  // Walk the call stack.
  if (FLAG_profile_vm) {
    // Always walk the native stack collecting both native and Dart frames.
    ProfilerNativeStackWalker stackWalker(sample,
                                          stack_lower,
                                          stack_upper,
                                          state.pc,
                                          state.fp,
                                          sp);
    stackWalker.walk();
  } else {
    // Attempt to walk only the Dart call stack, falling back to walking
    // the native stack.
    if ((isolate->stub_code() != NULL) &&
        (isolate->top_exit_frame_info() != 0) &&
        (isolate->vm_tag() != VMTag::kDartTagId)) {
      // We have a valid exit frame info, use the Dart stack walker.
      ProfilerDartExitStackWalker stackWalker(isolate, sample);
      stackWalker.walk();
    } else if ((isolate->stub_code() != NULL) &&
               (isolate->top_exit_frame_info() == 0) &&
               (isolate->vm_tag() == VMTag::kDartTagId)) {
      // We are executing Dart code. We have frame pointers.
      ProfilerDartStackWalker stackWalker(isolate,
                                          sample,
                                          stack_lower,
                                          stack_upper,
                                          state.pc,
                                          state.fp,
                                          sp);
      stackWalker.walk();
    } else {
#if defined(TARGET_OS_WINDOWS) && defined(TARGET_ARCH_X64)
      // ProfilerNativeStackWalker is known to cause crashes on Win64.
      // BUG=20423.
      sample->set_ignore_sample(true);
#else
      // Fall back to an extremely conservative stack walker.
      ProfilerNativeStackWalker stackWalker(sample,
                                            stack_lower,
                                            stack_upper,
                                            state.pc,
                                            state.fp,
                                            sp);
      stackWalker.walk();
#endif
    }
  }
}

}  // namespace dart
