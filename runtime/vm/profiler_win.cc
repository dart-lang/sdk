// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/isolate.h"
#include "vm/profiler.h"

namespace dart {

#define kThreadError -1

DECLARE_FLAG(bool, profile);
DECLARE_FLAG(bool, trace_profiled_isolates);

static void CollectSample(IsolateProfilerData* profiler_data,
                          uintptr_t pc,
                          uintptr_t fp,
                          uintptr_t stack_lower,
                          uintptr_t stack_upper) {
  uintptr_t sp = stack_lower;
  ASSERT(profiler_data != NULL);
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  Sample* sample = sample_buffer->ReserveSample();
  ASSERT(sample != NULL);
  sample->timestamp = OS::GetCurrentTimeMicros();
  // TODO(johnmccutchan): Make real use of vm_tags and runtime_tags.
  // Issue # 14777
  sample->vm_tags = Sample::kExecuting;
  sample->runtime_tags = 0;
  int64_t cpu_usage;
  Thread::GetThreadCpuUsage(profiler_data->thread_id(), &cpu_usage);
  sample->cpu_usage = profiler_data->ComputeDeltaAndSetCpuUsage(cpu_usage);
  ProfilerSampleStackWalker stackWalker(sample, stack_lower, stack_upper,
                                        pc, fp, sp);
  stackWalker.walk();
}


static bool GrabRegisters(ThreadId thread, uintptr_t* pc, uintptr_t* fp,
                          uintptr_t* sp) {
  CONTEXT context;
  memset(&context, 0, sizeof(context));
  context.ContextFlags = CONTEXT_FULL;
  if (GetThreadContext(thread, &context) != 0) {
#if defined(TARGET_ARCH_IA32)
    *pc = static_cast<uintptr_t>(context.Eip);
    *fp = static_cast<uintptr_t>(context.Ebp);
    *sp = static_cast<uintptr_t>(context.Esp);
#elif defined(TARGET_ARCH_X64)
    *pc = reinterpret_cast<uintptr_t>(context.Rip);
    *fp = reinterpret_cast<uintptr_t>(context.Rbp);
    *sp = reinterpret_cast<uintptr_t>(context.Rsp);
#else
    UNIMPLEMENTED();
#endif
    return true;
  }
  return false;
}


static void SuspendAndSample(Isolate* isolate,
                             IsolateProfilerData* profiler_data) {
  ASSERT(GetCurrentThread() != profiler_data->thread_id());
  DWORD result = SuspendThread(profiler_data->thread_id());
  if (result == kThreadError) {
    return;
  }
  uintptr_t PC;
  uintptr_t FP;
  uintptr_t stack_lower;
  uintptr_t stack_upper;
  bool r = isolate->GetStackBounds(&stack_lower, &stack_upper);
  if (r) {
    r = GrabRegisters(profiler_data->thread_id(), &PC, &FP, &stack_lower);
    if (r) {
      int64_t sample_time = OS::GetCurrentTimeMicros();
      profiler_data->SampledAt(sample_time);
      CollectSample(profiler_data, PC, FP, stack_lower, stack_upper);
    }
  }

  ResumeThread(profiler_data->thread_id());
}


static void Reschedule(IsolateProfilerData* profiler_data) {
  profiler_data->Scheduled(OS::GetCurrentTimeMicros(),
                           profiler_data->thread_id());
}


int64_t ProfilerManager::SampleAndRescheduleIsolates(int64_t current_time) {
  if (isolates_size_ == 0) {
    return 0;
  }
  static const int64_t max_time = 0x7fffffffffffffffLL;
  int64_t lowest = max_time;
  for (intptr_t i = 0; i < isolates_size_; i++) {
    Isolate* isolate = isolates_[i];
    ScopedMutex isolate_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if ((profiler_data == NULL) || !profiler_data->CanExpire() ||
        (profiler_data->sample_buffer() == NULL)) {
      // Descheduled.
      continue;
    }
    if (profiler_data->ShouldSample(current_time)) {
      SuspendAndSample(isolate, profiler_data);
      Reschedule(profiler_data);
    }
    if (profiler_data->CanExpire()) {
      int64_t isolate_time_left =
          profiler_data->TimeUntilExpiration(current_time);
      if (isolate_time_left < 0) {
        continue;
      }
      if (isolate_time_left < lowest) {
        lowest = isolate_time_left;
      }
    }
  }
  if (isolates_size_ == 0) {
    return 0;
  }
  if (lowest == max_time) {
    return 0;
  }
  ASSERT(lowest != max_time);
  ASSERT(lowest > 0);
  return lowest;
}


void ProfilerManager::ThreadMain(uword parameters) {
  ASSERT(initialized_);
  ASSERT(FLAG_profile);
  if (FLAG_trace_profiled_isolates) {
    OS::Print("ProfilerManager Windows ready.\n");
  }
  {
    // Signal to main thread we are ready.
    ScopedMonitor startup_lock(start_stop_monitor_);
    thread_running_ = true;
    startup_lock.Notify();
  }
  ScopedMonitor lock(monitor_);
  while (!shutdown_) {
    int64_t current_time = OS::GetCurrentTimeMicros();
    int64_t next_sample = SampleAndRescheduleIsolates(current_time);
    lock.WaitMicros(next_sample);
  }
  if (FLAG_trace_profiled_isolates) {
    OS::Print("ProfilerManager Windows exiting.\n");
  }
  {
    // Signal to main thread we are exiting.
    ScopedMonitor shutdown_lock(start_stop_monitor_);
    thread_running_ = false;
    shutdown_lock.Notify();
  }
}

}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
