// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdio>

#include "platform/utils.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"

namespace dart {

// Notes on locking and signal handling:

// The ProfilerManager has a single monitor (monitor_). This monitor guards
// access to the schedule list of isolates (isolates_, isolates_size_, etc).
//
// Each isolate has a mutex (profiler_data_mutex_) which protects access
// to the isolate's profiler data.
//
// Locks can be taken in this order:
//   1. ProfilerManager::monitor_
//   2. isolate->profiler_data_mutex_
// In other words, it is not acceptable to take ProfilerManager::monitor_
// after grabbing isolate->profiler_data_mutex_.
//
// ProfileManager::monitor_ taking entry points:
//   InitOnce, Shutdown
//       ProfilerManager::monitor_
//   ScheduleIsolate, DescheduleIsolate.
//       ProfilerManager::monitor_, isolate->profiler_data_mutex_
//   ThreadMain
// isolate->profiler_data_mutex_ taking entry points:
//     SetupIsolateForProfiling, FreeIsolateForProfiling.
//       ProfilerManager::monitor_, isolate->profiler_data_mutex_
//     ScheduleIsolate, DescheduleIsolate.
//       ProfilerManager::monitor_, isolate->profiler_data_mutex_
//     ProfileSignalAction
//       isolate->profiler_data_mutex_
//       ProfilerManager::monitor_, isolate->profiler_data_mutex_
//
// Signal handling and locking:
// On OSes with pthreads (Android, Linux, and Mac) we use signal delivery
// to interrupt the isolate running thread for sampling. After a thread
// is sent the SIGPROF, it is removed from the scheduled isolate list.
// Inside the signal handler, after the sample is taken, the isolate is
// added to the scheduled isolate list again. The side effect of this is
// that the signal handler must be able to acquire the isolate profiler data
// mutex and the profile manager monitor. When an isolate running thread
// (potential signal target) calls into an entry point which acquires
// ProfileManager::monitor_ signal delivery must be blocked. An example is
// Isolate::SetCurrent which blocks signal delivery while removing the old
// current isolate from the scheduled list and adding the new current isolate
// to the scheduled list.


DEFINE_FLAG(bool, profile, true, "Enable Sampling Profiler");

bool ProfilerManager::initialized_ = false;
bool ProfilerManager::shutdown_ = false;
Monitor* ProfilerManager::monitor_ = NULL;
Isolate** ProfilerManager::isolates_ = NULL;
intptr_t ProfilerManager::isolates_capacity_ = 0;
intptr_t ProfilerManager::isolates_size_ = 0;


void ProfilerManager::InitOnce() {
  if (!FLAG_profile) {
    return;
  }
  NativeSymbolResolver::InitOnce();
  ASSERT(!initialized_);
  monitor_ = new Monitor();
  initialized_ = true;
  ResizeIsolates(16);
  Thread::Start(ThreadMain, 0);
}


void ProfilerManager::Shutdown() {
  if (!FLAG_profile) {
    return;
  }
  ScopedMonitor lock(monitor_);
  shutdown_ = true;
  for (intptr_t i = 0; i < isolates_size_; i++) {
    Isolate* isolate = isolates_[i];
    ASSERT(isolate != NULL);
    FreeIsolateProfilingData(isolate);
  }
  isolates_size_ = 0;
  free(isolates_);
  isolates_ = NULL;
  lock.Notify();
  NativeSymbolResolver::ShutdownOnce();
}


void ProfilerManager::SetupIsolateForProfiling(Isolate* isolate) {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(isolate != NULL);
  ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
  SampleBuffer* sample_buffer = new SampleBuffer();
  IsolateProfilerData* profiler_data =
      new IsolateProfilerData(isolate, sample_buffer);
  profiler_data->set_sample_interval_micros(1000);
  isolate->set_profiler_data(profiler_data);
}


void ProfilerManager::FreeIsolateProfilingData(Isolate* isolate) {
  ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    // Already freed.
    return;
  }
  isolate->set_profiler_data(NULL);
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  delete sample_buffer;
  delete profiler_data;
}


void ProfilerManager::ShutdownIsolateForProfiling(Isolate* isolate) {
  ASSERT(isolate != NULL);
  if (!FLAG_profile) {
    return;
  }
  FreeIsolateProfilingData(isolate);
}


void ProfilerManager::ScheduleIsolate(Isolate* isolate) {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ASSERT(isolate != NULL);
  ScopedMonitor lock(monitor_);
  ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  profiler_data->Scheduled(OS::GetCurrentTimeMicros(),
                           Thread::GetCurrentThreadId());
  AddIsolate(isolate);
  lock.Notify();
}


void ProfilerManager::DescheduleIsolate(Isolate* isolate) {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ASSERT(isolate != NULL);
  ScopedMonitor lock(monitor_);
  intptr_t i = FindIsolate(isolate);
  if (i < 0) {
    // Not scheduled.
    return;
  }
  {
    ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    ASSERT(profiler_data != NULL);
    profiler_data->Descheduled();
  }
  RemoveIsolate(i);
  lock.Notify();
}


void PrintToJSONStream(Isolate* isolate, JSONStream* stream) {
  ASSERT(isolate == Isolate::Current());
  {
    // We can't get signals here.
  }
  UNIMPLEMENTED();
}


void ProfilerManager::ResizeIsolates(intptr_t new_capacity) {
  ASSERT(new_capacity < kMaxProfiledIsolates);
  ASSERT(new_capacity > isolates_capacity_);
  Isolate* isolate = NULL;
  isolates_ = reinterpret_cast<Isolate**>(
      realloc(isolates_, sizeof(isolate) * new_capacity));
  isolates_capacity_ = new_capacity;
}


void ProfilerManager::AddIsolate(Isolate* isolate) {
  // Must be called with monitor_ locked.
  if (isolates_size_ == isolates_capacity_) {
    ResizeIsolates(isolates_capacity_ == 0 ? 16 : isolates_capacity_ * 2);
  }
  isolates_[isolates_size_] = isolate;
  isolates_size_++;
}


intptr_t ProfilerManager::FindIsolate(Isolate* isolate) {
  // Must be called with monitor_ locked.
  for (intptr_t i = 0; i < isolates_size_; i++) {
    if (isolates_[i] == isolate) {
      return i;
    }
  }
  return -1;
}


void ProfilerManager::RemoveIsolate(intptr_t i) {
  // Must be called with monitor_ locked.
  ASSERT(i < isolates_size_);
  intptr_t last = isolates_size_ - 1;
  if (i != last) {
    isolates_[i] = isolates_[last];
  }
  // Mark last as NULL.
  isolates_[last] = NULL;
  // Pop.
  isolates_size_--;
}


static char* FindSymbolName(uintptr_t pc, bool* native_symbol) {
  // TODO(johnmccutchan): Differentiate between symbols which can't be found
  // and symbols which were GCed. (Heap::CodeContains).
  ASSERT(native_symbol != NULL);
  const char* symbol_name = "Unknown";
  *native_symbol = false;
  const Code& code = Code::Handle(Code::LookupCode(pc));
  if (code.IsNull()) {
    // Possibly a native symbol.
    char* native_name = NativeSymbolResolver::LookupSymbolName(pc);
    if (native_name != NULL) {
      symbol_name = native_name;
      *native_symbol = true;
    }
  } else {
    const Function& function = Function::Handle(code.function());
    if (!function.IsNull()) {
      const String& name = String::Handle(function.QualifiedUserVisibleName());
      if (!name.IsNull()) {
        symbol_name = name.ToCString();
      }
    }
  }
  return const_cast<char*>(symbol_name);
}


void ProfilerManager::WriteTracing(Isolate* isolate, const char* name,
                                   Dart_Port port) {
  ASSERT(isolate == Isolate::Current());
  ScopedMutex profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  JSONStream stream(10 * MB);
  intptr_t tid = reinterpret_cast<intptr_t>(sample_buffer);
  intptr_t pid = 1;
  {
    JSONArray events(&stream);
    {
      JSONObject thread_name(&events);
      thread_name.AddProperty("name", "thread_name");
      thread_name.AddProperty("ph", "M");
      thread_name.AddProperty("tid", tid);
      thread_name.AddProperty("pid", pid);
      {
        JSONObject args(&thread_name, "args");
        args.AddProperty("name", name);
      }
    }
    {
      JSONObject process_name(&events);
      process_name.AddProperty("name", "process_name");
      process_name.AddProperty("ph", "M");
      process_name.AddProperty("tid", tid);
      process_name.AddProperty("pid", pid);
      {
        JSONObject args(&process_name, "args");
        args.AddProperty("name", "Dart VM");
      }
    }
    uint64_t last_time = 0;
    for (Sample* i = sample_buffer->FirstSample();
         i != sample_buffer->LastSample();
         i = sample_buffer->NextSample(i)) {
      if (last_time == 0) {
        last_time = i->timestamp;
      }
      intptr_t delta = i->timestamp - last_time;
      {
        double percentage = static_cast<double>(i->cpu_usage) /
                            static_cast<double>(delta) * 100.0;
        if (percentage != percentage) {
          percentage = 0.0;
        }
        percentage = percentage < 0.0 ? 0.0 : percentage;
        percentage = percentage > 100.0 ? 100.0 : percentage;
        {
          JSONObject cpu_usage(&events);
          cpu_usage.AddProperty("name", "CPU Usage");
          cpu_usage.AddProperty("ph", "C");
          cpu_usage.AddProperty("tid", tid);
          cpu_usage.AddProperty("pid", pid);
          cpu_usage.AddProperty("ts", static_cast<double>(last_time));
          {
            JSONObject args(&cpu_usage, "args");
            args.AddProperty("CPU", percentage);
          }
        }
        {
          JSONObject cpu_usage(&events);
          cpu_usage.AddProperty("name", "CPU Usage");
          cpu_usage.AddProperty("ph", "C");
          cpu_usage.AddProperty("tid", tid);
          cpu_usage.AddProperty("pid", pid);
          cpu_usage.AddProperty("ts", static_cast<double>(i->timestamp));
          {
            JSONObject args(&cpu_usage, "args");
            args.AddProperty("CPU", percentage);
          }
        }
      }
      for (int j = 0; j < Sample::kNumStackFrames; j++) {
        if (i->pcs[j] == 0) {
          continue;
        }
        bool native_symbol = false;
        char* symbol_name = FindSymbolName(i->pcs[j], &native_symbol);
        {
          JSONObject begin(&events);
          begin.AddProperty("ph", "B");
          begin.AddProperty("tid", tid);
          begin.AddProperty("pid", pid);
          begin.AddProperty("name", symbol_name);
          begin.AddProperty("ts", static_cast<double>(last_time));
        }
        if (native_symbol) {
          NativeSymbolResolver::FreeSymbolName(symbol_name);
        }
      }
      for (int j = Sample::kNumStackFrames-1; j >= 0; j--) {
        if (i->pcs[j] == 0) {
          continue;
        }
        bool native_symbol = false;
        char* symbol_name = FindSymbolName(i->pcs[j], &native_symbol);
        {
          JSONObject end(&events);
          end.AddProperty("ph", "E");
          end.AddProperty("tid", tid);
          end.AddProperty("pid", pid);
          end.AddProperty("name", symbol_name);
          end.AddProperty("ts", static_cast<double>(i->timestamp));
        }
        if (native_symbol) {
          NativeSymbolResolver::FreeSymbolName(symbol_name);
        }
      }
      last_time = i->timestamp;
    }
  }
  char fname[1024];
#if defined(TARGET_OS_WINDOWS)
  snprintf(fname, sizeof(fname)-1, "c:\\tmp\\isolate-%d.prof",
           static_cast<int>(port));
#else
  snprintf(fname, sizeof(fname)-1, "/tmp/isolate-%d.prof",
           static_cast<int>(port));
#endif
  printf("%s\n", fname);
  FILE* f = fopen(fname, "wb");
  ASSERT(f != NULL);
  fputs(stream.ToCString(), f);
  fclose(f);
}





IsolateProfilerData::IsolateProfilerData(Isolate* isolate,
                                         SampleBuffer* sample_buffer) {
  isolate_ = isolate;
  sample_buffer_ = sample_buffer;
  timer_expiration_micros_ = kNoExpirationTime;
  last_sampled_micros_ = 0;
  thread_id_ = 0;
}


IsolateProfilerData::~IsolateProfilerData() {
}


void IsolateProfilerData::SampledAt(int64_t current_time) {
  last_sampled_micros_ = current_time;
}


void IsolateProfilerData::Scheduled(int64_t current_time, ThreadId thread_id) {
  timer_expiration_micros_ = current_time + sample_interval_micros_;
  Thread::GetThreadCpuUsage(thread_id, &cpu_usage_);
  thread_id_ = thread_id;
}


void IsolateProfilerData::Descheduled() {
  // TODO(johnmccutchan): Track when we ran for a fraction of our sample
  // interval and incorporate the time difference when scheduling the
  // isolate again.
  cpu_usage_ = kDescheduledCpuUsage;
  timer_expiration_micros_ = kNoExpirationTime;
  thread_id_ = 0;
  Sample* sample = sample_buffer_->ReserveSample();
  ASSERT(sample != NULL);
  sample->timestamp = OS::GetCurrentTimeMicros();
  sample->cpu_usage = 0;
  sample->vm_tags = Sample::kIdle;
}


const char* Sample::kLookupSymbol = "Symbol Not Looked Up";
const char* Sample::kNoSymbol = "No Symbol Found";

Sample::Sample()  {
  timestamp = 0;
  cpu_usage = 0;
  for (int i = 0; i < kNumStackFrames; i++) {
    pcs[i] = 0;
  }
  vm_tags = kIdle;
  runtime_tags = 0;
}


SampleBuffer::SampleBuffer(intptr_t capacity) {
  start_ = 0;
  end_ = 0;
  capacity_ = capacity;
  samples_ = reinterpret_cast<Sample*>(calloc(capacity, sizeof(Sample)));
}


SampleBuffer::~SampleBuffer() {
  if (samples_ != NULL) {
    free(samples_);
    samples_ = NULL;
  }
}


Sample* SampleBuffer::ReserveSample() {
  intptr_t index = end_;
  end_ = WrapIncrement(end_);
  if (end_ == start_) {
    start_ = WrapIncrement(start_);
  }
  // Reset.
  samples_[index] = Sample();
  return &samples_[index];
}


Sample* SampleBuffer::FirstSample() const {
  return &samples_[start_];
}


Sample* SampleBuffer::NextSample(Sample* sample) const {
  ASSERT(sample >= &samples_[0]);
  ASSERT(sample < &samples_[capacity_]);
  intptr_t index = sample - samples_;
  index = WrapIncrement(index);
  return &samples_[index];
}


Sample* SampleBuffer::LastSample() const {
  return &samples_[end_];
}


intptr_t SampleBuffer::WrapIncrement(intptr_t i) const {
  return (i + 1) % capacity_;
}


ProfilerSampleStackWalker::ProfilerSampleStackWalker(Sample* sample,
                                                     uintptr_t stack_lower,
                                                     uintptr_t stack_upper,
                                                     uintptr_t pc,
                                                     uintptr_t fp,
                                                     uintptr_t sp) :
    sample_(sample),
    stack_lower_(stack_lower),
    stack_upper_(stack_upper),
    original_pc_(pc),
    original_fp_(fp),
    original_sp_(sp) {
  ASSERT(sample_ != NULL);
}


int ProfilerSampleStackWalker::walk() {
  uword* pc = reinterpret_cast<uword*>(original_pc_);
  uword* fp = reinterpret_cast<uword*>(original_fp_);
  int i = 0;
  for (; i < Sample::kNumStackFrames; i++) {
    sample_->pcs[i] = reinterpret_cast<uintptr_t>(pc);
    if (!ValidFramePointer(fp)) {
      break;
    }
    pc = CallerPC(fp);
    uword* previous_fp = fp;
    fp = CallerFP(fp);
    if (fp <= previous_fp) {
      // Frame pointers should only move to higher addresses.
      break;
    }
  }
  return i;
}


uword* ProfilerSampleStackWalker::CallerPC(uword* fp) {
  ASSERT(fp != NULL);
  return reinterpret_cast<uword*>(*(fp+1));
}


uword* ProfilerSampleStackWalker::CallerFP(uword* fp) {
  ASSERT(fp != NULL);
  return reinterpret_cast<uword*>(*fp);
}


bool ProfilerSampleStackWalker::ValidFramePointer(uword* fp) {
  if (fp == NULL) {
    return false;
  }
  uintptr_t cursor = reinterpret_cast<uintptr_t>(fp);
  cursor += sizeof(fp);
  bool r = cursor >= stack_lower_ && cursor <= stack_upper_;
  return r;
}


}  // namespace dart
