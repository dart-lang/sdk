// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/profiler.h"

#include "platform/address_sanitizer.h"
#include "platform/atomic.h"
#include "platform/memory_sanitizer.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/code_patcher.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/compiler_state.h"
#endif
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler_service.h"
#include "vm/reusable_handles.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/timeline.h"
#include "vm/version.h"

namespace dart {

static constexpr intptr_t kMaxSamplesPerTick = 4;

DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");

DEFINE_FLAG(int,
            profile_period,
            1000,
            "Time between profiler samples in microseconds. Minimum 50.");
DEFINE_FLAG(int,
            max_profile_depth,
            Sample::kPCArraySizeInWords* kMaxSamplesPerTick,
            "Maximum number stack frames walked. Minimum 1. Maximum 255.");
#if defined(USING_SIMULATOR)
DEFINE_FLAG(bool, profile_vm, true, "Always collect native stack traces.");
#else
DEFINE_FLAG(bool, profile_vm, false, "Always collect native stack traces.");
#endif
DEFINE_FLAG(bool,
            profile_vm_allocation,
            false,
            "Collect native stack traces when tracing Dart allocations.");

DEFINE_FLAG(
    int,
    sample_buffer_duration,
    0,
    "Defines the size of the profiler sample buffer to contain at least "
    "N seconds of samples at a given sample rate. If not provided, the "
    "default is ~4 seconds. Large values will greatly increase memory "
    "consumption.");

// Include native stack dumping helpers into AOT compiler even in PRODUCT
// mode. This allows to report more informative errors when gen_snapshot
// crashes.
#if !defined(PRODUCT) || defined(DART_PRECOMPILER)
ProfilerCounters Profiler::counters_ = {};

static void DumpStackFrame(intptr_t frame_index, uword pc, uword fp) {
  uword start = 0;
  // The pc for all frames except the top frame is a return address, which can
  // belong to a different inlining interval than the call. Subtract one to get
  // the symbolization for the call.
  uword lookup_pc = frame_index == 0 ? pc : pc - 1;
  if (auto const name =
          NativeSymbolResolver::LookupSymbolName(lookup_pc, &start)) {
    uword offset = pc - start;
    OS::PrintErr("  pc 0x%" Pp " fp 0x%" Pp " %s+0x%" Px "\n", pc, fp, name,
                 offset);
    NativeSymbolResolver::FreeSymbolName(name);
    return;
  }

  char* dso_name;
  uword dso_base;
  if (NativeSymbolResolver::LookupSharedObject(pc, &dso_base, &dso_name)) {
    uword dso_offset = pc - dso_base;
    OS::PrintErr("  pc 0x%" Pp " fp 0x%" Pp " %s+0x%" Px "\n", pc, fp, dso_name,
                 dso_offset);
    NativeSymbolResolver::FreeSymbolName(dso_name);
    return;
  }

  OS::PrintErr("  pc 0x%" Pp " fp 0x%" Pp " Unknown symbol\n", pc, fp);
}

class ProfilerStackWalker : public ValueObject {
 public:
  ProfilerStackWalker(Dart_Port port_id,
                      Sample* head_sample,
                      SampleBuffer* sample_buffer,
                      intptr_t skip_count = 0)
      : port_id_(port_id),
        sample_(head_sample),
        sample_buffer_(sample_buffer),
        skip_count_(skip_count),
        frames_skipped_(0),
        frame_index_(0),
        total_frames_(0) {
    if (sample_ == nullptr) {
      ASSERT(sample_buffer_ == nullptr);
    } else {
      ASSERT(sample_buffer_ != nullptr);
      ASSERT(sample_->head_sample());
    }
  }

  bool Append(uword pc, uword fp) {
    if (frames_skipped_ < skip_count_) {
      frames_skipped_++;
      return true;
    }

    if (sample_ == nullptr) {
      DumpStackFrame(frame_index_, pc, fp);
      frame_index_++;
      total_frames_++;
      return true;
    }
    if (total_frames_ >= FLAG_max_profile_depth) {
      sample_->set_truncated_trace(true);
      return false;
    }
    ASSERT(sample_ != nullptr);
    if (frame_index_ == Sample::kPCArraySizeInWords) {
      Sample* new_sample = sample_buffer_->ReserveSampleAndLink(sample_);
      if (new_sample == nullptr) {
        // Could not reserve new sample- mark this as truncated.
        sample_->set_truncated_trace(true);
        return false;
      }
      frame_index_ = 0;
      sample_ = new_sample;
    }
    ASSERT(frame_index_ < Sample::kPCArraySizeInWords);
    sample_->SetAt(frame_index_, pc);
    frame_index_++;
    total_frames_++;
    return true;
  }

 protected:
  Dart_Port port_id_;
  Sample* sample_;
  SampleBuffer* sample_buffer_;
  intptr_t skip_count_;
  intptr_t frames_skipped_;
  intptr_t frame_index_;
  intptr_t total_frames_;
};

// The layout of C stack frames.
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64) ||                       \
    defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
// +-------------+
// | saved IP/LR |
// +-------------+
// | saved FP    |  <- FP
// +-------------+
static constexpr intptr_t kHostSavedCallerPcSlotFromFp = 1;
static constexpr intptr_t kHostSavedCallerFpSlotFromFp = 0;
#elif defined(HOST_ARCH_RISCV32) || defined(HOST_ARCH_RISCV64)
// +-------------+
// |             | <- FP
// +-------------+
// | saved RA    |
// +-------------+
// | saved FP    |
// +-------------+
static constexpr intptr_t kHostSavedCallerPcSlotFromFp = -1;
static constexpr intptr_t kHostSavedCallerFpSlotFromFp = -2;
#else
#error What architecture?
#endif

// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail.
//
class ProfilerNativeStackWalker : public ProfilerStackWalker {
 public:
  ProfilerNativeStackWalker(ProfilerCounters* counters,
                            Dart_Port port_id,
                            Sample* sample,
                            SampleBuffer* sample_buffer,
                            uword stack_lower,
                            uword stack_upper,
                            uword pc,
                            uword fp,
                            uword sp,
                            intptr_t skip_count = 0)
      : ProfilerStackWalker(port_id, sample, sample_buffer, skip_count),
        counters_(counters),
        stack_upper_(stack_upper),
        original_pc_(pc),
        original_fp_(fp),
        original_sp_(sp),
        lower_bound_(stack_lower) {}

  void walk() {
    const uword kMaxStep = VirtualMemory::PageSize();

    Append(original_pc_, original_fp_);

    uword* pc = reinterpret_cast<uword*>(original_pc_);
    uword* fp = reinterpret_cast<uword*>(original_fp_);
    uword* previous_fp = fp;

    uword gap = original_fp_ - original_sp_;
    if (gap >= kMaxStep) {
      // Gap between frame pointer and stack pointer is
      // too large.
      counters_->incomplete_sample_fp_step.fetch_add(1);
      return;
    }

    if (!ValidFramePointer(fp)) {
      counters_->incomplete_sample_fp_bounds.fetch_add(1);
      return;
    }

    while (true) {
      pc = CallerPC(fp);
      previous_fp = fp;
      fp = CallerFP(fp);

      if (fp == nullptr) {
        return;
      }

      if (fp <= previous_fp) {
        // Frame pointer did not move to a higher address.
        counters_->incomplete_sample_fp_step.fetch_add(1);
        return;
      }

      gap = fp - previous_fp;
      if (gap >= kMaxStep) {
        // Frame pointer step is too large.
        counters_->incomplete_sample_fp_step.fetch_add(1);
        return;
      }

      if (!ValidFramePointer(fp)) {
        // Frame pointer is outside of isolate stack boundary.
        counters_->incomplete_sample_fp_bounds.fetch_add(1);
        return;
      }

      const uword pc_value = reinterpret_cast<uword>(pc);
      if ((pc_value + 1) < pc_value) {
        // It is not uncommon to encounter an invalid pc as we
        // traverse a stack frame.  Most of these we can tolerate.  If
        // the pc is so large that adding one to it will cause an
        // overflow it is invalid and it will cause headaches later
        // while we are building the profile.  Discard it.
        counters_->incomplete_sample_bad_pc.fetch_add(1);
        return;
      }

      // Move the lower bound up.
      lower_bound_ = reinterpret_cast<uword>(fp);

      if (!Append(pc_value, reinterpret_cast<uword>(fp))) {
        return;
      }
    }
  }

 private:
  uword* CallerPC(uword* fp) const {
    ASSERT(fp != nullptr);
    uword* caller_pc_ptr = fp + kHostSavedCallerPcSlotFromFp;
    // This may actually be uninitialized, by design (see class comment above).
    MSAN_UNPOISON(caller_pc_ptr, kWordSize);
    ASAN_UNPOISON(caller_pc_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_pc_ptr);
  }

  uword* CallerFP(uword* fp) const {
    ASSERT(fp != nullptr);
    uword* caller_fp_ptr = fp + kHostSavedCallerFpSlotFromFp;
    // This may actually be uninitialized, by design (see class comment above).
    MSAN_UNPOISON(caller_fp_ptr, kWordSize);
    ASAN_UNPOISON(caller_fp_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_fp_ptr);
  }

  bool ValidFramePointer(uword* fp) const {
    if (fp == nullptr) {
      return false;
    }
    uword cursor = reinterpret_cast<uword>(fp);
    cursor += sizeof(fp);
    bool r = (cursor >= lower_bound_) && (cursor < stack_upper_);
    return r;
  }

  ProfilerCounters* const counters_;
  const uword stack_upper_;
  const uword original_pc_;
  const uword original_fp_;
  const uword original_sp_;
  uword lower_bound_;
};

static bool ValidateThreadStackBounds(uintptr_t fp,
                                      uintptr_t sp,
                                      uword stack_lower,
                                      uword stack_upper) {
  if (stack_lower >= stack_upper) {
    // Stack boundary is invalid.
    return false;
  }

  if ((sp < stack_lower) || (sp >= stack_upper)) {
    // Stack pointer is outside thread's stack boundary.
    return false;
  }

  if ((fp < stack_lower) || (fp >= stack_upper)) {
    // Frame pointer is outside threads's stack boundary.
    return false;
  }

  return true;
}

// Get |thread|'s stack boundary and verify that |sp| and |fp| are within
// it. Return |false| if anything looks suspicious.
static bool GetAndValidateThreadStackBounds(OSThread* os_thread,
                                            Thread* thread,
                                            uintptr_t fp,
                                            uintptr_t sp,
                                            uword* stack_lower,
                                            uword* stack_upper) {
  ASSERT(os_thread != nullptr);
  ASSERT(stack_lower != nullptr);
  ASSERT(stack_upper != nullptr);

#if defined(USING_SIMULATOR)
  const bool use_simulator_stack_bounds =
      thread != nullptr && thread->IsExecutingDartCode();
  if (use_simulator_stack_bounds) {
    Isolate* isolate = thread->isolate();
    ASSERT(isolate != nullptr);
    Simulator* simulator = isolate->simulator();
    *stack_lower = simulator->stack_limit();
    *stack_upper = simulator->stack_base();
  }
#else
  const bool use_simulator_stack_bounds = false;
#endif  // defined(USING_SIMULATOR)

  if (!use_simulator_stack_bounds) {
    *stack_lower = os_thread->stack_limit();
    *stack_upper = os_thread->stack_base();
  }

  if ((*stack_lower == 0) || (*stack_upper == 0)) {
    return false;
  }

  if (!use_simulator_stack_bounds && (sp > *stack_lower)) {
    // The stack pointer gives us a tighter lower bound.
    *stack_lower = sp;
  }

  return ValidateThreadStackBounds(fp, sp, *stack_lower, *stack_upper);
}

void Profiler::DumpStackTrace(void* context) {
  if (context == nullptr) {
    DumpStackTrace(/*for_crash=*/true);
    return;
  }
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||              \
    defined(DART_HOST_OS_ANDROID)
  ucontext_t* ucontext = reinterpret_cast<ucontext_t*>(context);
  mcontext_t mcontext = ucontext->uc_mcontext;
  uword pc = SignalHandler::GetProgramCounter(mcontext);
  uword fp = SignalHandler::GetFramePointer(mcontext);
  uword sp = SignalHandler::GetCStackPointer(mcontext);
  DumpStackTrace(sp, fp, pc, /*for_crash=*/true);
#elif defined(DART_HOST_OS_WINDOWS)
  CONTEXT* ctx = reinterpret_cast<CONTEXT*>(context);
#if defined(HOST_ARCH_IA32)
  uword pc = static_cast<uword>(ctx->Eip);
  uword fp = static_cast<uword>(ctx->Ebp);
  uword sp = static_cast<uword>(ctx->Esp);
#elif defined(HOST_ARCH_X64)
  uword pc = static_cast<uword>(ctx->Rip);
  uword fp = static_cast<uword>(ctx->Rbp);
  uword sp = static_cast<uword>(ctx->Rsp);
#elif defined(HOST_ARCH_ARM)
  uword pc = static_cast<uword>(ctx->Pc);
  uword fp = static_cast<uword>(ctx->R11);
  uword sp = static_cast<uword>(ctx->Sp);
#elif defined(HOST_ARCH_ARM64)
  uword pc = static_cast<uword>(ctx->Pc);
  uword fp = static_cast<uword>(ctx->Fp);
  uword sp = static_cast<uword>(ctx->Sp);
#else
#error Unsupported architecture.
#endif
  DumpStackTrace(sp, fp, pc, /*for_crash=*/true);
#else
// TODO(fschneider): Add support for more platforms.
// Do nothing on unsupported platforms.
#endif
}

void Profiler::DumpStackTrace(bool for_crash) {
  uintptr_t sp = OSThread::GetCurrentStackPointer();
  uintptr_t fp = 0;
  uintptr_t pc = OS::GetProgramCounter();

  COPY_FP_REGISTER(fp);

  DumpStackTrace(sp, fp, pc, for_crash);
}

static void DumpCompilerState(Thread* thread) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (thread != nullptr && thread->execution_state() == Thread::kThreadInVM &&
      thread->HasCompilerState()) {
    thread->compiler_state().ReportCrash();
  }
#endif
}

void Profiler::DumpStackTrace(uword sp, uword fp, uword pc, bool for_crash) {
  if (for_crash) {
    // Allow only one stack trace to prevent recursively printing stack traces
    // if we hit an assert while printing the stack.
    static RelaxedAtomic<uintptr_t> started_dump = 0;
    if (started_dump.fetch_add(1u) != 0) {
      OS::PrintErr("Aborting reentrant request for stack trace.\n");
      return;
    }
  }

  auto os_thread = OSThread::Current();
  ASSERT(os_thread != nullptr);
  auto thread = Thread::Current();  // nullptr if no current isolate.
  auto isolate = thread == nullptr ? nullptr : thread->isolate();
  auto isolate_group = thread == nullptr ? nullptr : thread->isolate_group();
  auto source = isolate_group == nullptr ? nullptr : isolate_group->source();
  auto vm_source =
      Dart::vm_isolate() == nullptr ? nullptr : Dart::vm_isolate()->source();
  const char* isolate_group_name =
      isolate_group == nullptr ? "(nil)" : isolate_group->source()->name;
  const char* isolate_name = isolate == nullptr ? "(nil)" : isolate->name();
#if defined(PRODUCT)
  const intptr_t thread_id = -1;
#else
  const intptr_t thread_id = OSThread::ThreadIdToIntPtr(os_thread->trace_id());
#endif

  OS::PrintErr("version=%s\n", Version::String());
  OS::PrintErr("pid=%" Pd ", thread=%" Pd
               ", isolate_group=%s(%p), isolate=%s(%p)\n",
               static_cast<intptr_t>(OS::ProcessId()), thread_id,
               isolate_group_name, isolate_group, isolate_name, isolate);
#if defined(DART_COMPRESSED_POINTERS)
  const char kCompressedPointers[] = "yes";
#else
  const char kCompressedPointers[] = "no";
#endif
#if defined(USING_SIMULATOR)
  const char kUsingSimulator[] = "yes";
#else
  const char kUsingSimulator[] = "no";
#endif
  OS::PrintErr("os=%s, arch=%s, comp=%s, sim=%s\n", kHostOperatingSystemName,
               kTargetArchitectureName, kCompressedPointers, kUsingSimulator);
  OS::PrintErr("isolate_instructions=%" Px ", vm_instructions=%" Px "\n",
               source == nullptr
                   ? 0
                   : reinterpret_cast<uword>(source->snapshot_instructions),
               vm_source == nullptr
                   ? 0
                   : reinterpret_cast<uword>(vm_source->snapshot_instructions));
  OS::PrintErr("fp=%" Px ", sp=%" Px ", pc=%" Px "\n", fp, sp, pc);

  uword stack_lower = 0;
  uword stack_upper = 0;
  if (!GetAndValidateThreadStackBounds(os_thread, thread, fp, sp, &stack_lower,
                                       &stack_upper)) {
    OS::PrintErr(
        "Stack dump aborted because GetAndValidateThreadStackBounds failed.\n");
    if (pc != 0) {  // At the very least dump the top frame.
      DumpStackFrame(0, pc, fp);
    }
    DumpCompilerState(thread);
    return;
  }

  ProfilerNativeStackWalker native_stack_walker(&counters_, ILLEGAL_PORT,
                                                nullptr, nullptr, stack_lower,
                                                stack_upper, pc, fp, sp,
                                                /*skip_count=*/0);
  native_stack_walker.walk();
  OS::PrintErr("-- End of DumpStackTrace\n");

  if (thread != nullptr) {
    if (thread->execution_state() == Thread::kThreadInNative) {
      TransitionNativeToVM transition(thread);
      StackFrame::DumpCurrentTrace();
    } else if (thread->execution_state() == Thread::kThreadInVM) {
      StackFrame::DumpCurrentTrace();
    }
  }

  DumpCompilerState(thread);
}
#endif  // !defined(PRODUCT) || defined(DART_PRECOMPILER)

#ifndef PRODUCT

RelaxedAtomic<bool> Profiler::initialized_ = false;
SampleBlockBuffer* Profiler::sample_block_buffer_ = nullptr;

bool SampleBlockProcessor::initialized_ = false;
bool SampleBlockProcessor::shutdown_ = false;
bool SampleBlockProcessor::thread_running_ = false;
ThreadJoinId SampleBlockProcessor::processor_thread_id_ =
    OSThread::kInvalidThreadJoinId;
Monitor* SampleBlockProcessor::monitor_ = nullptr;

void Profiler::Init() {
  // Place some sane restrictions on user controlled flags.
  SetSampleDepth(FLAG_max_profile_depth);
  if (!FLAG_profiler) {
    return;
  }
  ASSERT(!initialized_);
  SetSamplePeriod(FLAG_profile_period);
  // The profiler may have been shutdown previously, in which case the sample
  // buffer will have already been initialized.
  if (sample_block_buffer_ == nullptr) {
    intptr_t num_blocks = CalculateSampleBufferCapacity();
    sample_block_buffer_ = new SampleBlockBuffer(num_blocks);
  }
  ThreadInterrupter::Init();
  ThreadInterrupter::Startup();
  SampleBlockProcessor::Init();
  SampleBlockProcessor::Startup();
  initialized_ = true;
}

class SampleBlockCleanupVisitor : public IsolateVisitor {
 public:
  SampleBlockCleanupVisitor() = default;
  virtual ~SampleBlockCleanupVisitor() = default;

  void VisitIsolate(Isolate* isolate) {
    isolate->set_current_allocation_sample_block(nullptr);
    isolate->set_current_sample_block(nullptr);
  }
};

void Profiler::Cleanup() {
  if (!FLAG_profiler) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Cleanup();
  SampleBlockProcessor::Cleanup();
  SampleBlockCleanupVisitor visitor;
  Isolate::VisitIsolates(&visitor);
  initialized_ = false;
}

void Profiler::UpdateRunningState() {
  if (!FLAG_profiler && initialized_) {
    Cleanup();
  } else if (FLAG_profiler && !initialized_) {
    Init();
  }
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

static intptr_t SamplesPerSecond() {
  const intptr_t kMicrosPerSec = 1000000;
  return kMicrosPerSec / FLAG_profile_period;
}

intptr_t Profiler::CalculateSampleBufferCapacity() {
  if (FLAG_sample_buffer_duration <= 0) {
    return SampleBlockBuffer::kDefaultBlockCount;
  }
  // Deeper stacks require more than a single Sample object to be represented
  // correctly. These samples are chained, so we need to determine the worst
  // case sample chain length for a single stack.
  const intptr_t max_sample_chain_length =
      FLAG_max_profile_depth / kMaxSamplesPerTick;
  const intptr_t sample_count = FLAG_sample_buffer_duration *
                                SamplesPerSecond() * max_sample_chain_length;
  return (sample_count / SampleBlock::kSamplesPerBlock) + 1;
}

void Profiler::SetSamplePeriod(intptr_t period) {
  const int kMinimumProfilePeriod = 50;
  if (period < kMinimumProfilePeriod) {
    FLAG_profile_period = kMinimumProfilePeriod;
  } else {
    FLAG_profile_period = period;
  }
  ThreadInterrupter::SetInterruptPeriod(FLAG_profile_period);
}

void Profiler::UpdateSamplePeriod() {
  SetSamplePeriod(FLAG_profile_period);
}

SampleBlockBuffer::SampleBlockBuffer(intptr_t blocks,
                                     intptr_t samples_per_block) {
  const intptr_t size = Utils::RoundUp(
      blocks * samples_per_block * sizeof(Sample), VirtualMemory::PageSize());
  const bool executable = false;
  const bool compressed = false;
  memory_ =
      VirtualMemory::Allocate(size, executable, compressed, "dart-profiler");
  if (memory_ == nullptr) {
    OUT_OF_MEMORY();
  }
  sample_buffer_ = reinterpret_cast<Sample*>(memory_->address());
  blocks_ = new SampleBlock[blocks];
  for (intptr_t i = 0; i < blocks; ++i) {
    blocks_[i].Init(&sample_buffer_[i * samples_per_block], samples_per_block);
  }
  capacity_ = blocks;
  cursor_ = 0;
}

SampleBlockBuffer::~SampleBlockBuffer() {
  delete[] blocks_;
  blocks_ = nullptr;
  delete memory_;
  memory_ = nullptr;
  capacity_ = 0;
  cursor_ = 0;
}

SampleBlock* SampleBlockBuffer::ReserveSampleBlock() {
  intptr_t capacity = capacity_;
  intptr_t start = cursor_.fetch_add(1) % capacity;
  intptr_t i = start;
  do {
    SampleBlock* block = &blocks_[i];
    if (block->TryAllocateFree()) {
      return block;
    }
    i = (i + 1) % capacity;
  } while (i != start);

  // No free blocks: try for completed block instead.
  i = start;
  do {
    SampleBlock* block = &blocks_[i];
    if (block->TryAllocateCompleted()) {
      return block;
    }
    i = (i + 1) % capacity;
  } while (i != start);

  return nullptr;
}

void SampleBlockBuffer::FreeCompletedBlocks() {
  for (intptr_t i = 0; i < capacity_; i++) {
    blocks_[i].FreeCompleted();
  }
}

bool SampleBlock::HasStreamableSamples(const GrowableObjectArray& tag_table,
                                       UserTag* tag) {
  for (intptr_t i = 0; i < capacity_; ++i) {
    Sample* sample = At(i);
    uword sample_tag = sample->user_tag();
    for (intptr_t j = 0; j < tag_table.Length(); ++j) {
      *tag ^= tag_table.At(j);
      if (tag->tag() == sample_tag && tag->streamable()) {
        return true;
      }
    }
  }
  return false;
}

static void FlushSampleBlocks(Isolate* isolate) {
  ASSERT(isolate != nullptr);

  SampleBlock* block = isolate->current_sample_block();
  if (block != nullptr) {
    isolate->set_current_sample_block(nullptr);
    block->MarkCompleted();
  }

  block = isolate->current_allocation_sample_block();
  if (block != nullptr) {
    isolate->set_current_allocation_sample_block(nullptr);
    block->MarkCompleted();
  }
}

ProcessedSampleBuffer* SampleBlockBuffer::BuildProcessedSampleBuffer(
    Isolate* isolate,
    SampleFilter* filter,
    ProcessedSampleBuffer* buffer) {
  ASSERT(isolate != nullptr);

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  if (buffer == nullptr) {
    buffer = new (zone) ProcessedSampleBuffer();
  }

  FlushSampleBlocks(isolate);

  for (intptr_t i = 0; i < capacity_; ++i) {
    SampleBlock* block = &blocks_[i];
    if (block->TryAcquireStreaming(isolate)) {
      block->BuildProcessedSampleBuffer(filter, buffer);
      if (filter->take_samples()) {
        block->StreamingToFree();
      } else {
        block->StreamingToCompleted();
      }
    }
  }

  return buffer;
}

Sample* SampleBlock::ReserveSample() {
  intptr_t slot = cursor_.fetch_add(1u);
  if (slot < capacity_) {
    return At(slot);
  }
  return nullptr;
}

Sample* SampleBlock::ReserveSampleAndLink(Sample* previous) {
  ASSERT(previous != nullptr);
  SampleBlockBuffer* buffer = Profiler::sample_block_buffer();
  Isolate* isolate = owner_;
  ASSERT(isolate != nullptr);
  Sample* next = previous->is_allocation_sample()
                     ? buffer->ReserveAllocationSample(isolate)
                     : buffer->ReserveCPUSample(isolate);
  if (next == nullptr) {
    return nullptr;  // No blocks left, so drop sample.
  }
  next->Init(previous->port(), previous->timestamp(), previous->tid());
  next->set_head_sample(false);
  // Mark that previous continues at next.
  previous->SetContinuation(next);
  return next;
}

Sample* SampleBlockBuffer::ReserveCPUSample(Isolate* isolate) {
  return ReserveSampleImpl(isolate, false);
}

Sample* SampleBlockBuffer::ReserveAllocationSample(Isolate* isolate) {
  return ReserveSampleImpl(isolate, true);
}

Sample* SampleBlockBuffer::ReserveSampleImpl(Isolate* isolate,
                                             bool allocation_sample) {
  SampleBlock* block = allocation_sample
                           ? isolate->current_allocation_sample_block()
                           : isolate->current_sample_block();
  Sample* sample = nullptr;
  if (block != nullptr) {
    sample = block->ReserveSample();
  }
  if (sample != nullptr) {
    return sample;
  }

  SampleBlock* next = ReserveSampleBlock();
  if (next == nullptr) {
    // We're out of blocks to reserve. Drop the sample.
    return nullptr;
  }

  next->set_owner(isolate);
  if (allocation_sample) {
    isolate->set_current_allocation_sample_block(next);
  } else {
    isolate->set_current_sample_block(next);
  }
  if (block != nullptr) {
    block->MarkCompleted();
    if (!Isolate::IsSystemIsolate(isolate)) {
      Thread* mutator = isolate->mutator_thread();
      // The mutator thread might be NULL if we sample in the middle of
      // Thread::Enter/ExitIsolate.
      if ((mutator != nullptr) && isolate->TrySetHasCompletedBlocks()) {
        mutator->ScheduleInterrupts(Thread::kVMInterrupt);
      }
    }
  }
  return next->ReserveSample();
}

// Attempts to find the true return address when a Dart frame is being setup
// or torn down.
// NOTE: Architecture specific implementations below.
class ReturnAddressLocator : public ValueObject {
 public:
  ReturnAddressLocator(Sample* sample, const Code& code)
      : stack_buffer_(sample->GetStackBuffer()),
        pc_(sample->pc()),
        code_(Code::ZoneHandle(code.ptr())) {
    ASSERT(!code_.IsNull());
    ASSERT(code_.ContainsInstructionAt(pc()));
  }

  ReturnAddressLocator(uword pc, uword* stack_buffer, const Code& code)
      : stack_buffer_(stack_buffer),
        pc_(pc),
        code_(Code::ZoneHandle(code.ptr())) {
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
  ASSERT(return_address != nullptr);
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
#elif defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64) ||                \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
bool ReturnAddressLocator::LocateReturnAddress(uword* return_address) {
  ASSERT(return_address != nullptr);
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
  if (thread_task_mask_ == kNoTaskFilter) {
    return true;
  }
  return (task & thread_task_mask_) != 0;
}

ClearProfileVisitor::ClearProfileVisitor(Isolate* isolate)
    : SampleVisitor(isolate->main_port()) {}

void ClearProfileVisitor::VisitSample(Sample* sample) {
  sample->Clear();
}

// Executing Dart code, walk the stack.
class ProfilerDartStackWalker : public ProfilerStackWalker {
 public:
  ProfilerDartStackWalker(Thread* thread,
                          Sample* sample,
                          SampleBuffer* sample_buffer,
                          uword pc,
                          uword fp,
                          uword sp,
                          uword lr,
                          bool allocation_sample,
                          intptr_t skip_count = 0)
      : ProfilerStackWalker((thread->isolate() != nullptr)
                                ? thread->isolate()->main_port()
                                : ILLEGAL_PORT,
                            sample,
                            sample_buffer,
                            skip_count),
        thread_(thread),
        pc_(reinterpret_cast<uword*>(pc)),
        fp_(reinterpret_cast<uword*>(fp)),
        sp_(reinterpret_cast<uword*>(sp)),
        lr_(reinterpret_cast<uword*>(lr)) {}

  void walk() {
    RELEASE_ASSERT(StubCode::HasBeenInitialized());
    if (thread_->isolate()->IsDeoptimizing()) {
      sample_->set_ignore_sample(true);
      return;
    }

    uword* exit_fp = reinterpret_cast<uword*>(thread_->top_exit_frame_info());
    bool has_exit_frame = exit_fp != nullptr;
    if (has_exit_frame) {
      // Exited from compiled code.
      pc_ = nullptr;
      fp_ = exit_fp;

      // Skip exit frame.
      pc_ = CallerPC();
      fp_ = CallerFP();
    } else {
      if (thread_->vm_tag() == VMTag::kDartTagId) {
        // Running compiled code.
        // Use the FP and PC from the thread interrupt or simulator; already set
        // in the constructor.
      } else {
        // No Dart on the stack; caller shouldn't use this walker.
        UNREACHABLE();
      }

      const bool is_entry_frame =
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
          StubCode::InInvocationStub(Stack(0)) ||
          StubCode::InInvocationStub(Stack(1));
#else
          StubCode::InInvocationStub(reinterpret_cast<uword>(lr_));
#endif
      if (is_entry_frame) {
        // During the prologue of a function, CallerPC will return the caller's
        // caller. For most frames, the missing PC will be added during profile
        // processing. However, during this stack walk, it can cause us to fail
        // to identify the entry frame and lead the stack walk into the weeds.
        // Do not continue the stalk walk since this might be a false positive
        // from a Smi or unboxed value.
        sample_->set_ignore_sample(true);
        return;
      }
    }

    sample_->set_exit_frame_sample(has_exit_frame);

    for (;;) {
      // Skip entry frame.
      if (StubCode::InInvocationStub(reinterpret_cast<uword>(pc_))) {
        pc_ = nullptr;
        fp_ = ExitLink();
        if (fp_ == nullptr) {
          break;  // End of Dart stack.
        }

        // Skip exit frame.
        pc_ = CallerPC();
        fp_ = CallerFP();

        // At least one frame between exit and next entry frame.
        RELEASE_ASSERT(
            !StubCode::InInvocationStub(reinterpret_cast<uword>(pc_)));
      }

      if (!Append(reinterpret_cast<uword>(pc_), reinterpret_cast<uword>(fp_))) {
        break;  // Sample is full.
      }

      pc_ = CallerPC();
      fp_ = CallerFP();
    }
  }

 private:
  uword* CallerPC() const {
    ASSERT(fp_ != nullptr);
    uword* caller_pc_ptr = fp_ + kSavedCallerPcSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(caller_pc_ptr, kWordSize);
    ASAN_UNPOISON(caller_pc_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_pc_ptr);
  }

  uword* CallerFP() const {
    ASSERT(fp_ != nullptr);
    uword* caller_fp_ptr = fp_ + kSavedCallerFpSlotFromFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(caller_fp_ptr, kWordSize);
    ASAN_UNPOISON(caller_fp_ptr, kWordSize);
    return reinterpret_cast<uword*>(*caller_fp_ptr);
  }

  uword* ExitLink() const {
    ASSERT(fp_ != nullptr);
    uword* exit_link_ptr = fp_ + kExitLinkSlotFromEntryFp;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(exit_link_ptr, kWordSize);
    ASAN_UNPOISON(exit_link_ptr, kWordSize);
    return reinterpret_cast<uword*>(*exit_link_ptr);
  }

  uword Stack(intptr_t index) const {
    ASSERT(sp_ != nullptr);
    uword* stack_ptr = sp_ + index;
    // MSan/ASan are unaware of frames initialized by generated code.
    MSAN_UNPOISON(stack_ptr, kWordSize);
    ASAN_UNPOISON(stack_ptr, kWordSize);
    return *stack_ptr;
  }

  Thread* const thread_;
  uword* pc_;
  uword* fp_;
  uword* sp_;
  uword* lr_;
};

static void CopyStackBuffer(Sample* sample, uword sp_addr) {
  ASSERT(sample != nullptr);
  uword* sp = reinterpret_cast<uword*>(sp_addr);
  uword* buffer = sample->GetStackBuffer();
  if (sp != nullptr) {
    for (intptr_t i = 0; i < Sample::kStackBufferSizeInWords; i++) {
      MSAN_UNPOISON(sp, kWordSize);
      ASAN_UNPOISON(sp, kWordSize);
      buffer[i] = *sp;
      sp++;
    }
  }
}

#if defined(DART_HOST_OS_WINDOWS)
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
  ASSERT(counters != nullptr);
#if defined(DART_HOST_OS_WINDOWS)
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
      counters->stack_walker_native.fetch_add(1);
      native_stack_walker->walk();
    } else if (StubCode::HasBeenInitialized() && exited_dart_code) {
      counters->stack_walker_dart_exit.fetch_add(1);
      // We have a valid exit frame info, use the Dart stack walker.
      dart_stack_walker->walk();
    } else if (StubCode::HasBeenInitialized() && in_dart_code) {
      counters->stack_walker_dart.fetch_add(1);
      // We are executing Dart code. We have frame pointers.
      dart_stack_walker->walk();
    } else {
      counters->stack_walker_none.fetch_add(1);
      sample->SetAt(0, pc);
    }

#if defined(DART_HOST_OS_WINDOWS)
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

static Sample* SetupSample(Thread* thread,
                           bool allocation_sample,
                           ThreadId tid) {
  ASSERT(thread != nullptr);
  Isolate* isolate = thread->isolate();
  SampleBlockBuffer* buffer = Profiler::sample_block_buffer();
  Sample* sample = allocation_sample ? buffer->ReserveAllocationSample(isolate)
                                     : buffer->ReserveCPUSample(isolate);
  if (sample == nullptr) {
    return nullptr;
  }
  sample->Init(isolate->main_port(), OS::GetCurrentMonotonicMicros(), tid);
  uword vm_tag = thread->vm_tag();
#if defined(USING_SIMULATOR)
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
  if ((isolate == nullptr) || (Dart::vm_isolate() == nullptr)) {
    // No isolate.
    return false;
  }
  return isolate != Dart::vm_isolate();
}

void Profiler::SampleAllocation(Thread* thread,
                                intptr_t cid,
                                uint32_t identity_hash) {
  ASSERT(thread != nullptr);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != nullptr);
  Isolate* isolate = thread->isolate();
  if (!CheckIsolate(isolate)) {
    return;
  }
  const bool exited_dart_code = thread->HasExitedDartCode();

  SampleBlockBuffer* buffer = Profiler::sample_block_buffer();
  if (buffer == nullptr) {
    // Profiler not initialized.
    return;
  }

  uintptr_t sp = OSThread::GetCurrentStackPointer();
  uintptr_t fp = 0;
  uintptr_t pc = OS::GetProgramCounter();
  uintptr_t lr = 0;

  COPY_FP_REGISTER(fp);

  uword stack_lower = 0;
  uword stack_upper = 0;

  if (!GetAndValidateThreadStackBounds(os_thread, thread, fp, sp, &stack_lower,
                                       &stack_upper)) {
    // Could not get stack boundary.
    return;
  }

  Sample* sample =
      SetupSample(thread, /*allocation_block*/ true, os_thread->trace_id());
  if (sample == nullptr) {
    // We were unable to assign a sample for this allocation.
    counters_.sample_allocation_failure++;
    return;
  }
  sample->SetAllocationCid(cid);
  sample->set_allocation_identity_hash(identity_hash);

  if (FLAG_profile_vm_allocation) {
    ProfilerNativeStackWalker native_stack_walker(
        &counters_, (isolate != nullptr) ? isolate->main_port() : ILLEGAL_PORT,
        sample, isolate->current_allocation_sample_block(), stack_lower,
        stack_upper, pc, fp, sp);
    native_stack_walker.walk();
  } else if (exited_dart_code) {
    ProfilerDartStackWalker dart_exit_stack_walker(
        thread, sample, isolate->current_allocation_sample_block(), pc, fp, sp,
        lr, /* allocation_sample*/ true);
    dart_exit_stack_walker.walk();
  } else {
    // Fall back.
    uintptr_t pc = OS::GetProgramCounter();
    sample->SetAt(0, pc);
  }
}

void Profiler::SampleThreadSingleFrame(Thread* thread,
                                       Sample* sample,
                                       uintptr_t pc) {
  ASSERT(thread != nullptr);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != nullptr);
  Isolate* isolate = thread->isolate();

  ASSERT(Profiler::sample_block_buffer() != nullptr);

  // Increment counter for vm tag.
  VMTagCounters* counters = isolate->vm_tag_counters();
  ASSERT(counters != nullptr);
  if (thread->IsDartMutatorThread()) {
    counters->Increment(sample->vm_tag());
  }

  // Write the single pc value.
  sample->SetAt(0, pc);
}

void Profiler::SampleThread(Thread* thread,
                            const InterruptedThreadState& state) {
  ASSERT(thread != nullptr);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != nullptr);
  Isolate* isolate = thread->isolate();

  // Thread is not doing VM work.
  if (thread->task_kind() == Thread::kUnknownTask) {
    counters_.bail_out_unknown_task.fetch_add(1);
    return;
  }

  if (StubCode::HasBeenInitialized() && StubCode::InJumpToFrameStub(state.pc)) {
    // The JumpToFrame stub manually adjusts the stack pointer, frame
    // pointer, and some isolate state.  It is not safe to walk the
    // stack when executing this stub.
    counters_.bail_out_jump_to_exception_handler.fetch_add(1);
    return;
  }

  const bool in_dart_code = thread->IsExecutingDartCode();

  uintptr_t sp = 0;
  uintptr_t fp = state.fp;
  uintptr_t pc = state.pc;
  uintptr_t lr = state.lr;
#if defined(USING_SIMULATOR)
  Simulator* simulator = nullptr;
#endif

  if (in_dart_code) {
// If we're in Dart code, use the Dart stack pointer.
#if defined(USING_SIMULATOR)
    simulator = isolate->simulator();
    sp = simulator->get_register(SPREG);
    fp = simulator->get_register(FPREG);
    pc = simulator->get_pc();
    lr = simulator->get_lr();
#else
    sp = state.dsp;
#endif
  } else {
    // If we're in runtime code, use the C stack pointer.
    sp = state.csp;
  }

  if (!CheckIsolate(isolate)) {
    counters_.bail_out_check_isolate.fetch_add(1);
    return;
  }

  SampleBlockBuffer* sample_block_buffer = Profiler::sample_block_buffer();
  if (sample_block_buffer == nullptr) {
    // Profiler not initialized.
    return;
  }

  // Setup sample.
  Sample* sample =
      SetupSample(thread, /*allocation_block*/ false, os_thread->trace_id());
  if (sample == nullptr) {
    // We were unable to assign a sample for this profiler tick.
    counters_.sample_allocation_failure++;
    return;
  }

  if (thread->IsDartMutatorThread()) {
    if (isolate->IsDeoptimizing()) {
      counters_.single_frame_sample_deoptimizing.fetch_add(1);
      SampleThreadSingleFrame(thread, sample, pc);
      return;
    }
  }

  uword stack_lower = 0;
  uword stack_upper = 0;
  if (!GetAndValidateThreadStackBounds(os_thread, thread, fp, sp, &stack_lower,
                                       &stack_upper)) {
    counters_.single_frame_sample_get_and_validate_stack_bounds.fetch_add(1);
    // Could not get stack boundary.
    SampleThreadSingleFrame(thread, sample, pc);
    return;
  }

  // At this point we have a valid stack boundary for this isolate and
  // know that our initial stack and frame pointers are within the boundary.

  // Increment counter for vm tag.
  VMTagCounters* counters = isolate->vm_tag_counters();
  ASSERT(counters != nullptr);
  if (thread->IsDartMutatorThread()) {
    counters->Increment(sample->vm_tag());
  }

  ProfilerNativeStackWalker native_stack_walker(
      &counters_, (isolate != nullptr) ? isolate->main_port() : ILLEGAL_PORT,
      sample, isolate->current_sample_block(), stack_lower, stack_upper, pc, fp,
      sp);
  const bool exited_dart_code = thread->HasExitedDartCode();
  ProfilerDartStackWalker dart_stack_walker(
      thread, sample, isolate->current_sample_block(), pc, fp, sp, lr,
      /* allocation_sample*/ false);

  // All memory access is done inside CollectSample.
  CollectSample(isolate, exited_dart_code, in_dart_code, sample,
                &native_stack_walker, &dart_stack_walker, pc, fp, sp,
                &counters_);
}

CodeDescriptor::CodeDescriptor(const AbstractCode code) : code_(code) {}

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
    ASSERT(table_ != nullptr);
  }

  ~CodeLookupTableBuilder() {}

  void VisitObject(ObjectPtr raw_obj) override {
    if (raw_obj->IsCode() && !Code::IsUnknownDartCode(Code::RawCast(raw_obj))) {
      table_->Add(Code::Handle(Code::RawCast(raw_obj)));
    }
  }

 private:
  CodeLookupTable* table_;
};

void CodeLookupTable::Build(Thread* thread) {
  ASSERT(thread != nullptr);
  Isolate* vm_isolate = Dart::vm_isolate();
  ASSERT(vm_isolate != nullptr);

  // Clear.
  code_objects_.Clear();

  thread->CheckForSafepoint();
  // Add all found Code objects.
  {
    TimelineBeginEndScope tl(Timeline::GetIsolateStream(),
                             "CodeLookupTable::Build HeapIterationScope");
    HeapIterationScope iteration(thread);
    CodeLookupTableBuilder cltb(this);
    iteration.IterateVMIsolateObjects(&cltb);
    iteration.IterateOldObjects(&cltb);
  }
  thread->CheckForSafepoint();

  // Sort by entry.
  code_objects_.Sort(CodeDescriptor::Compare);

#if defined(DEBUG)
  if (length() <= 1) {
    return;
  }
  ASSERT(FindCode(0) == nullptr);
  ASSERT(FindCode(~0) == nullptr);
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

void CodeLookupTable::Add(const Object& code) {
  ASSERT(!code.IsNull());
  ASSERT(code.IsCode());
  CodeDescriptor* cd = new CodeDescriptor(AbstractCode(code.ptr()));
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
    return nullptr;
  }
  first--;
  ASSERT(first >= 0);
  ASSERT(first < length());
  const CodeDescriptor* cd = At(first);
  if (cd->Contains(pc)) {
    return cd;
  }
  return nullptr;
}

ProcessedSampleBuffer* SampleBuffer::BuildProcessedSampleBuffer(
    SampleFilter* filter,
    ProcessedSampleBuffer* buffer) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  if (buffer == nullptr) {
    buffer = new (zone) ProcessedSampleBuffer();
  }

  const intptr_t length = capacity();
  for (intptr_t i = 0; i < length; i++) {
    thread->CheckForSafepoint();
    Sample* sample = At(i);
    if (sample->ignore_sample()) {
      // Bad sample.
      continue;
    }
    if (!sample->head_sample()) {
      // An inner sample in a chain of samples.
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
    if (filter != nullptr) {
      // If we're requesting all the native allocation samples, we don't care
      // whether or not we're in the same isolate as the sample.
      if (sample->port() != filter->port()) {
        // Another isolate.
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
    processed_sample->set_allocation_identity_hash(
        sample->allocation_identity_hash());
  }
  processed_sample->set_first_frame_executing(!sample->exit_frame_sample());

  // Copy stack trace from sample(s).
  bool truncated = false;
  Sample* current = sample;
  while (current != nullptr) {
    for (intptr_t i = 0; i < Sample::kPCArraySizeInWords; i++) {
      if (current->At(i) == 0) {
        break;
      }
      processed_sample->Add(current->At(i));
    }

    truncated = truncated || current->truncated_trace();
    current = Next(current);
  }

  if (!sample->exit_frame_sample()) {
    processed_sample->FixupCaller(clt, /* pc_marker */ 0,
                                  sample->GetStackBuffer());
  }

  processed_sample->set_truncated(truncated);
  return processed_sample;
}

Sample* SampleBuffer::Next(Sample* sample) {
  if (!sample->is_continuation_sample()) return nullptr;
  Sample* next_sample = sample->continuation_sample();
  // Sanity check.
  ASSERT(sample != next_sample);
  // Detect invalid chaining.
  if (sample->port() != next_sample->port()) {
    return nullptr;
  }
  if (sample->timestamp() != next_sample->timestamp()) {
    return nullptr;
  }
  if (sample->tid() != next_sample->tid()) {
    return nullptr;
  }
  return next_sample;
}

ProcessedSample::ProcessedSample()
    : pcs_(Sample::kPCArraySizeInWords),
      timestamp_(0),
      vm_tag_(0),
      user_tag_(0),
      allocation_cid_(-1),
      allocation_identity_hash_(0),
      truncated_(false) {}

void ProcessedSample::FixupCaller(const CodeLookupTable& clt,
                                  uword pc_marker,
                                  uword* stack_buffer) {
  const CodeDescriptor* cd = clt.FindCode(At(0));
  if (cd == nullptr) {
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
  ASSERT(cd != nullptr);
  const Code& code = Code::Handle(Code::RawCast(cd->code().ptr()));
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

  if (clt.FindCode(return_address) == nullptr) {
    // Return address is not from a Dart code object. Do not insert.
    return;
  }

  if (return_address != 0) {
    InsertAt(1, return_address);
  }
}

ProcessedSampleBuffer::ProcessedSampleBuffer()
    : code_lookup_table_(new CodeLookupTable(Thread::Current())) {
  ASSERT(code_lookup_table_ != nullptr);
}

void SampleBlockProcessor::Init() {
  ASSERT(!initialized_);
  if (monitor_ == nullptr) {
    monitor_ = new Monitor();
  }
  ASSERT(monitor_ != nullptr);
  initialized_ = true;
  shutdown_ = false;
}

void SampleBlockProcessor::Startup() {
  ASSERT(initialized_);
  ASSERT(processor_thread_id_ == OSThread::kInvalidThreadJoinId);
  MonitorLocker startup_ml(monitor_);
  OSThread::Start("Dart Profiler SampleBlockProcessor", ThreadMain, 0);
  while (!thread_running_) {
    startup_ml.Wait();
  }
  ASSERT(processor_thread_id_ != OSThread::kInvalidThreadJoinId);
}

void SampleBlockProcessor::Cleanup() {
  {
    MonitorLocker shutdown_ml(monitor_);
    if (shutdown_) {
      // Already shutdown.
      return;
    }
    shutdown_ = true;
    // Notify.
    shutdown_ml.Notify();
    ASSERT(initialized_);
  }

  // Join the thread.
  ASSERT(processor_thread_id_ != OSThread::kInvalidThreadJoinId);
  OSThread::Join(processor_thread_id_);
  processor_thread_id_ = OSThread::kInvalidThreadJoinId;
  initialized_ = false;
  ASSERT(!thread_running_);
}

class StreamableSampleFilter : public SampleFilter {
 public:
  StreamableSampleFilter(Dart_Port port, const Isolate* isolate)
      : SampleFilter(port, kNoTaskFilter, -1, -1, true), isolate_(isolate) {}

  bool FilterSample(Sample* sample) override {
    const UserTag& tag =
        UserTag::Handle(UserTag::FindTagById(isolate_, sample->user_tag()));
    return tag.streamable();
  }

 private:
  const Isolate* isolate_;
};

void Profiler::ProcessCompletedBlocks(Isolate* isolate) {
  if (!Service::profiler_stream.enabled()) return;
  auto thread = Thread::Current();
  if (Isolate::IsSystemIsolate(isolate)) return;

  TIMELINE_DURATION(thread, Isolate, "Profiler::ProcessCompletedBlocks")
  DisableThreadInterruptsScope dtis(thread);
  StackZone zone(thread);
  HandleScope handle_scope(thread);
  StreamableSampleFilter filter(isolate->main_port(), isolate);
  Profile profile;
  profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
  ServiceEvent event(isolate, ServiceEvent::kCpuSamples);
  event.set_cpu_profile(&profile);
  Service::HandleEvent(&event);
}

void Profiler::IsolateShutdown(Thread* thread) {
  FlushSampleBlocks(thread->isolate());
  ProcessCompletedBlocks(thread->isolate());
}

class SampleBlockProcessorVisitor : public IsolateVisitor {
 public:
  SampleBlockProcessorVisitor() = default;
  virtual ~SampleBlockProcessorVisitor() = default;

  void VisitIsolate(Isolate* isolate) {
    if (isolate->TakeHasCompletedBlocks()) {
      const bool kBypassSafepoint = false;
      Thread::EnterIsolateGroupAsHelper(
          isolate->group(), Thread::kSampleBlockTask, kBypassSafepoint);
      Profiler::ProcessCompletedBlocks(isolate);
      Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    }
  }
};

void SampleBlockProcessor::ThreadMain(uword parameters) {
  ASSERT(initialized_);
  {
    // Signal to main thread we are ready.
    MonitorLocker startup_ml(monitor_);
    OSThread* os_thread = OSThread::Current();
    ASSERT(os_thread != nullptr);
    processor_thread_id_ = OSThread::GetCurrentThreadJoinId(os_thread);
    thread_running_ = true;
    startup_ml.Notify();
  }

  SampleBlockProcessorVisitor visitor;
  MonitorLocker wait_ml(monitor_);
  // Wakeup every 100ms.
  const int64_t wakeup_interval = 1000 * 100;
  while (true) {
    wait_ml.WaitMicros(wakeup_interval);
    if (shutdown_) {
      break;
    }
    Isolate::VisitIsolates(&visitor);
  }
  // Signal to main thread we are exiting.
  thread_running_ = false;
}

#endif  // !PRODUCT

}  // namespace dart
