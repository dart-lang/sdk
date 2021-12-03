// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TIMER_H_
#define RUNTIME_VM_TIMER_H_

#include "platform/atomic.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

struct MeasureMonotonic {
  static inline int64_t Now() { return OS::GetCurrentMonotonicMicros(); }
};

struct MeasureCpu {
  static inline int64_t Now() { return OS::GetCurrentThreadCPUMicros(); }
};

// Timer class allows timing of specific operations in the VM.
template <typename Measure>
class TimerImpl : public ValueObject {
 public:
  TimerImpl() { Reset(); }
  ~TimerImpl() {}

  // Start timer.
  void Start() {
    start_ = Measure::Now();
    running_ = true;
  }

  // Stop timer.
  void Stop() {
    ASSERT(start_ != 0);
    ASSERT(running());
    stop_ = Measure::Now();
    int64_t elapsed = ElapsedMicros();
    max_contiguous_ = Utils::Maximum(max_contiguous_.load(), elapsed);
    // Make increment atomic in case it occurs in parallel with aggregation.
    total_.fetch_add(elapsed);
    running_ = false;
  }

  // Get total cumulative elapsed time in micros.
  int64_t TotalElapsedTime() const {
    int64_t result = total_;
    if (running_) {
      int64_t now = Measure::Now();
      result += (now - start_);
    }
    return result;
  }

  int64_t MaxContiguous() const {
    int64_t result = max_contiguous_;
    if (running_) {
      int64_t now = Measure::Now();
      result = Utils::Maximum(result, now - start_);
    }
    return result;
  }

  void Reset() {
    start_ = 0;
    stop_ = 0;
    total_ = 0;
    max_contiguous_ = 0;
    running_ = false;
  }

  bool IsReset() const {
    return (start_ == 0) && (stop_ == 0) && (total_ == 0) &&
           (max_contiguous_ == 0) && !running_;
  }

  void AddTotal(const TimerImpl& other) { total_.fetch_add(other.total_); }

  // Accessors.
  bool running() const { return running_; }

 private:
  friend class Timer;

  explicit TimerImpl(int64_t elapsed)
      : total_(elapsed), max_contiguous_(elapsed) {}

  int64_t ElapsedMicros() const {
    ASSERT(start_ != 0);
    ASSERT(stop_ != 0);
    return stop_ - start_;
  }

  RelaxedAtomic<int64_t> start_;
  RelaxedAtomic<int64_t> stop_;
  RelaxedAtomic<int64_t> total_;
  RelaxedAtomic<int64_t> max_contiguous_;

  bool running_ = false;

  DISALLOW_COPY_AND_ASSIGN(TimerImpl);
};

class Timer : public ValueObject {
 public:
  Timer(int64_t elapsed, int64_t elapsed_cpu)
      : monotonic_(elapsed), cpu_(elapsed) {}
  Timer() { Reset(); }
  ~Timer() {}

  // Start timer.
  void Start() {
    cpu_.Start();
    monotonic_.Start();
  }

  // Stop timer.
  void Stop() {
    cpu_.Stop();
    monotonic_.Stop();
  }

  // Get total cumulative elapsed time in micros.
  int64_t TotalElapsedTime() const { return monotonic_.TotalElapsedTime(); }
  int64_t TotalElapsedTimeCpu() const { return cpu_.TotalElapsedTime(); }

  int64_t MaxContiguous() const { return monotonic_.MaxContiguous(); }

  void Reset() {
    monotonic_.Reset();
    cpu_.Reset();
  }

  bool IsReset() const { return monotonic_.IsReset(); }

  void AddTotal(const Timer& other) {
    monotonic_.AddTotal(other.monotonic_);
    cpu_.AddTotal(other.cpu_);
  }

  const char* FormatElapsedHumanReadable(Zone* zone) const {
    return FormatElapsedHumanReadable(zone, TotalElapsedTime(),
                                      TotalElapsedTimeCpu());
  }

  static const char* FormatTime(Zone* zone, int64_t total) {
    if (total > kMicrosecondsPerSecond) {
      return OS::SCreate(zone, "%6.2f s", MicrosecondsToSeconds(total));
    } else if (total > kMicrosecondsPerMillisecond) {
      return OS::SCreate(zone, "%6.2f ms", MicrosecondsToMilliseconds(total));
    } else {
      return OS::SCreate(zone, "%6" Pd64 " \u00B5s", total);
    }
  }

  static constexpr double kCpuTimeReportingThreshold = 0.05;

  // Formats the given monotonic and CPU times as a human readable string.
  //
  // CPU time is included into the formated string only if
  // it is |kCpuTimeReportingThreshold| percent different from the monotonic
  // time.
  static const char* FormatElapsedHumanReadable(Zone* zone,
                                                int64_t total_elapsed,
                                                int64_t total_elapsed_cpu) {
    if ((total_elapsed == 0) ||
        static_cast<double>(Utils::Abs(total_elapsed - total_elapsed_cpu) /
                            total_elapsed) < kCpuTimeReportingThreshold) {
      return FormatTime(zone, total_elapsed);
    } else {
      return OS::SCreate(zone, "%s (cpu %s)", FormatTime(zone, total_elapsed),
                         FormatTime(zone, total_elapsed_cpu));
    }
  }

 private:
  TimerImpl<MeasureMonotonic> monotonic_;
  TimerImpl<MeasureCpu> cpu_;

  DISALLOW_COPY_AND_ASSIGN(Timer);
};

class TimerScope : public StackResource {
 public:
  TimerScope(ThreadState* thread, Timer* timer)
      : StackResource(thread), timer_(timer) {
    if (timer_ != nullptr) timer_->Start();
  }
  ~TimerScope() {
    if (timer_ != nullptr) timer_->Stop();
  }

 private:
  Timer* const timer_;
};

class PrintTimeScope : public ValueObject {
 public:
  explicit PrintTimeScope(const char* name) : name_(name) { timer_.Start(); }
  ~PrintTimeScope();

 private:
  Timer timer_;
  const char* name_;
};

}  // namespace dart

#endif  // RUNTIME_VM_TIMER_H_
