// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PROFILER_H_
#define VM_PROFILER_H_

#include "platform/hashmap.h"
#include "platform/thread.h"
#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class JSONStream;

// Profiler manager.
class ProfilerManager : public AllStatic {
 public:
  static void InitOnce();
  static void Shutdown();

  static void SetupIsolateForProfiling(Isolate* isolate);
  static void ShutdownIsolateForProfiling(Isolate* isolate);
  static void ScheduleIsolate(Isolate* isolate, bool inside_signal = false);
  static void DescheduleIsolate(Isolate* isolate);

  static void PrintToJSONStream(Isolate* isolate, JSONStream* stream);

  static void WriteTracing(Isolate* isolate, const char* name, Dart_Port port);

 private:
  static const intptr_t kMaxProfiledIsolates = 4096;
  static bool initialized_;
  static bool shutdown_;
  static Monitor* monitor_;

  static Isolate** isolates_;
  static intptr_t isolates_capacity_;
  static intptr_t isolates_size_;

  static void ScheduleIsolateHelper(Isolate* isolate);
  static void ResizeIsolates(intptr_t new_capacity);
  static void AddIsolate(Isolate* isolate);
  static intptr_t FindIsolate(Isolate* isolate);
  static void RemoveIsolate(intptr_t i);

  // Returns the microseconds until the next live timer fires.
  static int64_t SampleAndRescheduleIsolates(int64_t current_time);
  static void FreeIsolateProfilingData(Isolate* isolate);
  static void ThreadMain(uword parameters);
};


class IsolateProfilerData {
 public:
  static const int64_t kDescheduledCpuUsage = -1;
  static const int64_t kNoExpirationTime = -2;

  IsolateProfilerData(Isolate* isolate, SampleBuffer* sample_buffer);
  ~IsolateProfilerData();

  int64_t sample_interval_micros() const { return sample_interval_micros_; }

  void set_sample_interval_micros(int64_t sample_interval) {
    sample_interval_micros_ = sample_interval;
  }

  bool CanExpire() const {
    return timer_expiration_micros_ != kNoExpirationTime;
  }

  bool ShouldSample(int64_t current_time) const {
    return CanExpire() && TimeUntilExpiration(current_time) <= 0;
  }

  int64_t TimeUntilExpiration(int64_t current_time_micros) const {
    ASSERT(CanExpire());
    return timer_expiration_micros_ - current_time_micros;
  }

  void set_cpu_usage(int64_t cpu_usage) {
    cpu_usage_ = cpu_usage;
  }

  void SampledAt(int64_t current_time);

  void Scheduled(int64_t current_time, ThreadId thread);

  void Descheduled();

  int64_t cpu_usage() const { return cpu_usage_; }

  int64_t ComputeDeltaAndSetCpuUsage(int64_t cpu_usage) {
    int64_t delta = 0;
    if (cpu_usage_ != kDescheduledCpuUsage) {
      // Only compute the real delta if we are being sampled regularly.
      delta = cpu_usage - cpu_usage_;
    }
    set_cpu_usage(cpu_usage);
    return delta;
  }

  ThreadId thread_id() const { return thread_id_; }

  Isolate* isolate() const { return isolate_; }

  SampleBuffer* sample_buffer() const { return sample_buffer_; }

 private:
  int64_t last_sampled_micros_;
  int64_t timer_expiration_micros_;
  int64_t sample_interval_micros_;
  int64_t cpu_usage_;
  ThreadId thread_id_;
  Isolate* isolate_;
  SampleBuffer* sample_buffer_;
  DISALLOW_COPY_AND_ASSIGN(IsolateProfilerData);
};


// Profile sample.
struct Sample {
  static const char* kLookupSymbol;
  static const char* kNoSymbol;
  static const intptr_t kNumStackFrames = 4;
  enum SampleState {
    kIdle = 0,
    kExecuting = 1,
    kNumSampleStates
  };
  int64_t timestamp;
  int64_t cpu_usage;
  uintptr_t pcs[kNumStackFrames];
  uint16_t vm_tags;
  uint16_t runtime_tags;
  Sample();
};


// Ring buffer of samples. One per isolate.
class SampleBuffer {
 public:
  static const intptr_t kDefaultBufferCapacity = 1000000;

  explicit SampleBuffer(intptr_t capacity = kDefaultBufferCapacity);
  ~SampleBuffer();

  intptr_t capacity() const { return capacity_; }

  Sample* ReserveSample();

  Sample* FirstSample() const;
  Sample* NextSample(Sample* sample) const;
  Sample* LastSample() const;
 private:
  Sample* samples_;
  intptr_t capacity_;
  intptr_t start_;
  intptr_t end_;

  intptr_t WrapIncrement(intptr_t i) const;
  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};


class ProfilerSampleStackWalker : public ValueObject {
 public:
  ProfilerSampleStackWalker(Sample* sample,
                            uintptr_t stack_lower,
                            uintptr_t stack_upper,
                            uintptr_t pc,
                            uintptr_t fp,
                            uintptr_t sp);

  int walk();

 private:
  uword* CallerPC(uword* fp);
  uword* CallerFP(uword* fp);

  bool ValidInstructionPointer(uword* pc);

  bool ValidFramePointer(uword* fp);

  Sample* sample_;
  const uintptr_t stack_lower_;
  const uintptr_t stack_upper_;
  const uintptr_t original_pc_;
  const uintptr_t original_fp_;
  const uintptr_t original_sp_;
  uintptr_t lower_bound_;
};


}  // namespace dart

#endif  // VM_PROFILER_H_
