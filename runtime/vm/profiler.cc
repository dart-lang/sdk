// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/address_sanitizer.h"
#include "platform/memory_sanitizer.h"
#include "platform/utils.h"

#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/code_patcher.h"
#include "vm/instructions.h"
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


DEFINE_FLAG(bool, profile, true, "Enable Sampling Profiler");
DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");
#if defined(TARGET_OS_ANDROID) || defined(TARGET_ARCH_ARM64) ||                \
    defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_MIPS)
  DEFINE_FLAG(int, profile_period, 10000,
              "Time between profiler samples in microseconds. Minimum 50.");
#else
  DEFINE_FLAG(int, profile_period, 1000,
              "Time between profiler samples in microseconds. Minimum 50.");
#endif
DEFINE_FLAG(int, profile_depth, 8,
            "Maximum number stack frames walked. Minimum 1. Maximum 255.");
#if defined(USING_SIMULATOR)
DEFINE_FLAG(bool, profile_vm, true,
            "Always collect native stack traces.");
#else
DEFINE_FLAG(bool, profile_vm, true,
            "Always collect native stack traces.");
#endif

bool Profiler::initialized_ = false;
SampleBuffer* Profiler::sample_buffer_ = NULL;

static intptr_t NumberOfFramesToCollect() {
  if (FLAG_profile_depth <= 0) {
    return 0;
  }
  // Subtract to reserve space for the possible missing frame.
  return FLAG_profile_depth - 1;
}

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
  const int kMinimumDepth = 2;
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
  ASSERT(FLAG_profile_depth >= 2);
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


// Attempts to find the true return address when a Dart frame is being setup
// or torn down.
// NOTE: Architecture specific implementations below.
class ReturnAddressLocator : public ValueObject {
 public:
  ReturnAddressLocator(Sample* sample, const Code& code)
      : sample_(sample),
        code_(Code::ZoneHandle(code.raw())),
        is_optimized_(code.is_optimized()) {
    ASSERT(!code_.IsNull());
    ASSERT(code_.ContainsInstructionAt(pc()));
  }

  bool is_code_optimized() {
    return is_optimized_;
  }

  uword pc() {
    return sample_->pc();
  }

  // Returns false on failure.
  bool LocateReturnAddress(uword* return_address);

  // Returns offset into code object.
  uword RelativePC() {
    return pc() - code_.EntryPoint();
  }

  uint8_t* CodePointer(uword offset) {
    const uword size = code_.Size();
    ASSERT(offset < size);
    uint8_t* code_pointer = reinterpret_cast<uint8_t*>(code_.EntryPoint());
    code_pointer += offset;
    return code_pointer;
  }

  uword StackAt(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < Sample::kStackBufferSizeInWords);
    return sample_->GetStackBuffer()[i];
  }

 private:
  Sample* sample_;
  const Code& code_;
  const bool is_optimized_;
};


#if defined(TARGET_ARCH_IA32)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  const uword offset = RelativePC();
  const uword size = code_.Size();
  if (is_optimized_) {
    // 0: push ebp
    // 1: mov ebp, esp
    // 3: ...
    if (offset == 0x0) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    if (offset == 0x1) {
      // Stack layout:
      // 0 CALLER FRAME POINTER
      // 1 RETURN ADDRESS
      *return_address = StackAt(1);
      return true;
    }
    ReturnPattern rp(pc());
    if (rp.IsValid()) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    return false;
  } else {
    // 0x00: mov edi, function
    // 0x05: incl (inc usage count)   <-- this is optional.
    // 0x08: cmpl (compare usage count)
    // 0x0f: jump to optimize function
    // 0x15: push ebp
    // 0x16: mov ebp, esp
    // 0x18: ...
    ASSERT(size >= 0x08);
    const uword incl_offset = 0x05;
    const uword incl_length = 0x03;
    const uint8_t incl_op_code = 0xFF;
    const bool has_incl = (*CodePointer(incl_offset) == incl_op_code);
    const uword push_fp_offset = has_incl ? 0x15 : 0x15 - incl_length;
    if (offset <= push_fp_offset) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    if (offset == (push_fp_offset + 1)) {
      // Stack layout:
      // 0 CALLER FRAME POINTER
      // 1 RETURN ADDRESS
      *return_address = StackAt(1);
      return true;
    }
    ReturnPattern rp(pc());
    if (rp.IsValid()) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    return false;
  }
  UNREACHABLE();
  return false;
}
#elif defined(TARGET_ARCH_X64)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != NULL);
  const uword offset = RelativePC();
  const uword size = code_.Size();
  if (is_optimized_) {
    // 0x00: leaq (load pc marker)
    // 0x07: movq (load pool pointer)
    // 0x0c: push rpb
    // 0x0d: movq rbp, rsp
    // 0x10: ...
    const uword push_fp_offset = 0x0c;
    if (offset <= push_fp_offset) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    if (offset == (push_fp_offset + 1)) {
      // Stack layout:
      // 0 CALLER FRAME POINTER
      // 1 RETURN ADDRESS
      *return_address = StackAt(1);
      return true;
    }
    ReturnPattern rp(pc());
    if (rp.IsValid()) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    return false;
  } else {
    // 0x00: leaq (load pc marker)
    // 0x07: movq (load pool pointer)
    // 0x0c: movq (load function)
    // 0x13: incl (inc usage count)   <-- this is optional.
    // 0x16: cmpl (compare usage count)
    // 0x1d: jl + 0x
    // 0x23: jmp [pool pointer]
    // 0x27: push rbp
    // 0x28: movq rbp, rsp
    // 0x2b: ...
    ASSERT(size >= 0x16);
    const uword incl_offset = 0x13;
    const uword incl_length = 0x03;
    const uint8_t incl_op_code = 0xFF;
    const bool has_incl = (*CodePointer(incl_offset) == incl_op_code);
    const uword push_fp_offset = has_incl ? 0x27 : 0x27 - incl_length;
    if (offset <= push_fp_offset) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    if (offset == (push_fp_offset + 1)) {
      // Stack layout:
      // 0 CALLER FRAME POINTER
      // 1 RETURN ADDRESS
      *return_address = StackAt(1);
      return true;
    }
    ReturnPattern rp(pc());
    if (rp.IsValid()) {
      // Stack layout:
      // 0 RETURN ADDRESS.
      *return_address = StackAt(0);
      return true;
    }
    return false;
  }
  UNREACHABLE();
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
#else
#error ReturnAddressLocator implementation missing for this architecture.
#endif


PreprocessVisitor::PreprocessVisitor(Isolate* isolate)
    : SampleVisitor(isolate),
      vm_isolate_(Dart::vm_isolate()) {
}


void PreprocessVisitor::VisitSample(Sample* sample) {
  if (sample->processed()) {
    // Already processed.
    return;
  }
  // Mark that we've processed this sample.
  sample->set_processed(true);

  if (sample->exit_frame_sample()) {
    // Exit frame sample, no preprocessing required.
    return;
  }
  REUSABLE_CODE_HANDLESCOPE(isolate());
  // Lookup code object for leaf frame.
  Code& code = reused_code_handle.Handle();
  code = FindCodeForPC(sample->At(0));
  sample->set_leaf_frame_is_dart(!code.IsNull());
  if (!code.IsNull() && (code.compile_timestamp() > sample->timestamp())) {
    // Code compiled after sample. Ignore.
    return;
  }
  if (sample->leaf_frame_is_dart()) {
    CheckForMissingDartFrame(code, sample);
  }
}


void PreprocessVisitor::CheckForMissingDartFrame(const Code& code,
                                                 Sample* sample) const {
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
  ASSERT(!code.IsNull());

  // The pc marker is our current best guess of a return address.
  uword return_address = sample->pc_marker();

  // Attempt to find a better return address.
  ReturnAddressLocator ral(sample, code);

  if (!ral.LocateReturnAddress(&return_address)) {
    ASSERT(return_address == sample->pc_marker());
    // Could not find a better return address than the pc_marker.
    if (code.ContainsInstructionAt(return_address)) {
      // PC marker is in the same code as pc, no missing frame.
      return;
    }
  }

  if (!ContainedInDartCodeHeaps(return_address)) {
    // return address is not from the Dart heap. Do not insert.
    return;
  }

  if (return_address != 0) {
    sample->InsertCallerForTopFrame(return_address);
  }
}


bool PreprocessVisitor::ContainedInDartCodeHeaps(uword pc) const {
  return isolate()->heap()->CodeContains(pc) ||
         vm_isolate()->heap()->CodeContains(pc);
}


RawCode* PreprocessVisitor::FindCodeForPC(uword pc) const {
  // Check current isolate for pc.
  if (isolate()->heap()->CodeContains(pc)) {
    return Code::LookupCode(pc);
  }
  // Check VM isolate for pc.
  if (vm_isolate()->heap()->CodeContains(pc)) {
    return Code::LookupCodeInVmIsolate(pc);
  }
  return Code::null();
}


ClearProfileVisitor::ClearProfileVisitor(Isolate* isolate)
    : SampleVisitor(isolate) {
}


void ClearProfileVisitor::VisitSample(Sample* sample) {
  sample->Clear();
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
      if (frame_index >= NumberOfFramesToCollect()) {
        sample_->set_truncated_trace(true);
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
    for (int i = 0; i < NumberOfFramesToCollect(); i++) {
      sample_->SetAt(i, reinterpret_cast<uword>(pc_));
      if (!Next()) {
        return;
      }
    }
    sample_->set_truncated_trace(true);
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

    for (int i = 0; i < NumberOfFramesToCollect(); i++) {
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

    sample_->set_truncated_trace(true);
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


static void CopyPCMarkerIfSafe(Sample* sample) {
  ASSERT(sample != NULL);

  if (sample->vm_tag() != VMTag::kDartTagId) {
    // We can only trust the stack pointer if we are executing Dart code.
    // See http://dartbug.com/20421 for details.
    return;
  }
  uword* fp = reinterpret_cast<uword*>(sample->fp());
  uword* sp = reinterpret_cast<uword*>(sample->sp());

  // If FP == SP, the pc marker hasn't been pushed.
  if (fp > sp) {
    uword* pc_marker_ptr = fp + kPcMarkerSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(pc_marker_ptr, kWordSize);
    ASAN_UNPOISON(pc_marker_ptr, kWordSize);
    sample->set_pc_marker(*pc_marker_ptr);
  }
}


static void CopyStackBuffer(Sample* sample) {
  ASSERT(sample != NULL);
  if (sample->vm_tag() != VMTag::kDartTagId) {
    // We can only trust the stack pointer if we are executing Dart code.
    // See http://dartbug.com/20421 for details.
    return;
  }
  uword* sp = reinterpret_cast<uword*>(sample->sp());
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
                          uword stack_lower,
                          uword stack_upper,
                          uword pc,
                          uword fp,
                          uword sp) {
#if defined(TARGET_OS_WINDOWS)
  // Use structured exception handling to trap guard page access on Windows.
  __try {
#endif

  CopyStackBuffer(sample);
  CopyPCMarkerIfSafe(sample);

  if (FLAG_profile_vm) {
    // Always walk the native stack collecting both native and Dart frames.
    ProfilerNativeStackWalker stackWalker(sample,
                                          stack_lower,
                                          stack_upper,
                                          pc,
                                          fp,
                                          sp);
    stackWalker.walk();
  } else if (exited_dart_code) {
    // We have a valid exit frame info, use the Dart stack walker.
    ProfilerDartExitStackWalker stackWalker(isolate, sample);
    stackWalker.walk();
  } else if (in_dart_code) {
    // We are executing Dart code. We have frame pointers.
    ProfilerDartStackWalker stackWalker(isolate,
                                        sample,
                                        stack_lower,
                                        stack_upper,
                                        pc,
                                        fp,
                                        sp);
    stackWalker.walk();
  } else {
    sample->set_vm_tag(VMTag::kEmbedderTagId);
    sample->SetAt(0, pc);
  }

#if defined(TARGET_OS_WINDOWS)
  // Use structured exception handling to trap guard page access.
  } __except(GuardPageExceptionFilter(GetExceptionInformation())) {
    // Sample collection triggered a guard page fault:
    // 1) discard entire sample.
    sample->set_ignore_sample(true);

    // 2) Reenable guard bit on page that triggered the fault.
    // https://goo.gl/5mCsXW
    DWORD new_protect = PAGE_READWRITE | PAGE_GUARD;
    DWORD old_protect = 0;
    BOOL success = VirtualProtect(reinterpret_cast<void*>(fault_address),
                                  sizeof(fault_address),
                                  new_protect,
                                  &old_protect);
    USE(success);
    ASSERT(success);
    ASSERT(old_protect == PAGE_READWRITE);
  }
#endif
}


void Profiler::RecordSampleInterruptCallback(
    const InterruptedThreadState& state,
    void* data) {
  Isolate* isolate = reinterpret_cast<Isolate*>(data);
  if ((isolate == NULL) || (Dart::vm_isolate() == NULL)) {
    // No isolate.
    return;
  }

  ASSERT(isolate != Dart::vm_isolate());

  const bool exited_dart_code = (isolate->stub_code() != NULL) &&
                                (isolate->top_exit_frame_info() != 0) &&
                                (isolate->vm_tag() != VMTag::kDartTagId);
  const bool in_dart_code = (isolate->stub_code() != NULL) &&
                            (isolate->top_exit_frame_info() == 0) &&
                            (isolate->vm_tag() == VMTag::kDartTagId);

  uintptr_t sp = 0;
  uintptr_t fp = state.fp;
  uintptr_t pc = state.pc;
  uintptr_t lr = state.lr;
#if defined(USING_SIMULATOR)
  Simulator* simulator = NULL;
#endif

  if (in_dart_code) {
    // If we're in Dart code, use the Dart stack pointer.
#if defined(USING_SIMULATOR)
    simulator = isolate->simulator();
    sp = simulator->get_register(SPREG);
    fp = simulator->get_register(FPREG);
    pc = simulator->get_pc();
    lr = simulator->get_register(LRREG);
#else
    sp = state.dsp;
#endif
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

  if ((sp == 0) || (fp == 0) || (pc == 0)) {
    // None of these registers should be zero.
    return;
  }

  if (sp > fp) {
    // Assuming the stack grows down, we should never have a stack pointer above
    // the frame pointer.
    return;
  }

  if (StubCode::InJumpToExceptionHandlerStub(pc)) {
    // The JumpToExceptionHandler stub manually adjusts the stack pointer,
    // frame pointer, and some isolate state before jumping to a catch entry.
    // It is not safe to walk the stack when executing this stub.
    return;
  }

  uword stack_lower = 0;
  uword stack_upper = 0;
#if defined(USING_SIMULATOR)
  if (in_dart_code) {
    stack_lower = simulator->StackBase();
    stack_upper = simulator->StackTop();
  } else if (!isolate->GetProfilerStackBounds(&stack_lower, &stack_upper)) {
    // Could not get stack boundary.
    return;
  }
  if ((stack_lower == 0) || (stack_upper == 0)) {
    return;
  }
#else
  if (!isolate->GetProfilerStackBounds(&stack_lower, &stack_upper) ||
      (stack_lower == 0) || (stack_upper == 0)) {
    // Could not get stack boundary.
    return;
  }
#endif

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

  if ((fp < stack_lower) || (fp >= stack_upper)) {
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
  sample->set_fp(fp);
  sample->set_lr(lr);

  // All memory access is done inside CollectSample.
  CollectSample(isolate,
                exited_dart_code,
                in_dart_code,
                sample,
                stack_lower,
                stack_upper,
                pc,
                fp,
                sp);
}

}  // namespace dart
