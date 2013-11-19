// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"

namespace dart {

DECLARE_FLAG(bool, profile);

static void CollectSample(IsolateProfilerData* profiler_data,
                          uintptr_t pc,
                          uintptr_t fp,
                          uintptr_t sp,
                          uintptr_t stack_lower,
                          uintptr_t stack_upper) {
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
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


static void ProfileSignalAction(int signal, siginfo_t* info, void* context_) {
  if (signal != SIGPROF) {
    return;
  }
  ucontext_t* context = reinterpret_cast<ucontext_t*>(context_);
  mcontext_t mcontext = context->uc_mcontext;
  Isolate* isolate = Isolate::Current();
  if (isolate == NULL) {
    return;
  }
  // Thread owns no profiler locks at this point.
  {
    // Thread owns isolate profiler data mutex.
    ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if (profiler_data == NULL) {
      return;
    }

    uintptr_t stack_lower = 0;
    uintptr_t stack_upper = 0;
    isolate->GetStackBounds(&stack_lower, &stack_upper);
    uintptr_t PC = SignalHandler::GetProgramCounter(mcontext);
    uintptr_t FP = SignalHandler::GetFramePointer(mcontext);
    uintptr_t SP = SignalHandler::GetStackPointer(mcontext);
    int64_t sample_time = OS::GetCurrentTimeMicros();
    profiler_data->SampledAt(sample_time);
    CollectSample(profiler_data, PC, FP, SP, stack_lower, stack_upper);
  }
  // Thread owns no profiler locks at this point.
  // This call will acquire both ProfilerManager::monitor and the
  // isolate's profiler data mutex.
  ProfilerManager::ScheduleIsolate(isolate);
}


int64_t ProfilerManager::SampleAndRescheduleIsolates(int64_t current_time) {
  if (isolates_size_ == 0) {
    return 0;
  }
  static const int64_t max_time = 0x7fffffffffffffffLL;
  int64_t lowest = max_time;
  intptr_t i = 0;
  while (i < isolates_size_) {
    Isolate* isolate = isolates_[i];
    ScopedMutex isolate_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    ASSERT(profiler_data != NULL);
    if (profiler_data->ShouldSample(current_time)) {
      pthread_kill(profiler_data->thread_id(), SIGPROF);
      RemoveIsolate(i);
      // Remove moves the last element into i, do not increment i.
      continue;
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
    i++;
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
  SignalHandler::Install(ProfileSignalAction);
  ScopedMonitor lock(monitor_);
  while (!shutdown_) {
    int64_t current_time = OS::GetCurrentTimeMicros();
    int64_t next_sample = SampleAndRescheduleIsolates(current_time);
    lock.WaitMicros(next_sample);
  }
}


}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
