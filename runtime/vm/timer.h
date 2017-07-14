// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TIMER_H_
#define RUNTIME_VM_TIMER_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

// Timer class allows timing of specific operations in the VM.
class Timer : public ValueObject {
 public:
  Timer(bool report, const char* message) : report_(report), message_(message) {
    Reset();
  }
  ~Timer() {}

  // Start timer.
  void Start() {
    start_ = OS::GetCurrentMonotonicMicros();
    running_ = true;
  }

  // Stop timer.
  void Stop() {
    ASSERT(start_ != 0);
    ASSERT(running());
    stop_ = OS::GetCurrentMonotonicMicros();
    int64_t elapsed = ElapsedMicros();
    max_contiguous_ = Utils::Maximum(max_contiguous_, elapsed);
    // Make increment atomic in case it occurs in parallel with aggregation.
    AtomicOperations::IncrementInt64By(&total_, elapsed);
    running_ = false;
  }

  // Get total cumulative elapsed time in micros.
  int64_t TotalElapsedTime() const {
    int64_t result = total_;
    if (running_) {
      int64_t now = OS::GetCurrentMonotonicMicros();
      result += (now - start_);
    }
    return result;
  }

  int64_t MaxContiguous() const {
    int64_t result = max_contiguous_;
    if (running_) {
      int64_t now = OS::GetCurrentMonotonicMicros();
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

  void AddTotal(const Timer& other) {
    AtomicOperations::IncrementInt64By(&total_, other.total_);
  }

  // Accessors.
  bool report() const { return report_; }
  bool running() const { return running_; }
  const char* message() const { return message_; }

 private:
  int64_t ElapsedMicros() const {
    ASSERT(start_ != 0);
    ASSERT(stop_ != 0);
    return stop_ - start_;
  }

  int64_t start_;
  int64_t stop_;
  int64_t total_;
  int64_t max_contiguous_;
  bool report_;
  bool running_;
  const char* message_;

  DISALLOW_COPY_AND_ASSIGN(Timer);
};

// The class TimerScope is used to start and stop a timer within a scope.
// It is used as follows:
// {
//   TimerScope timer(FLAG_name_of_flag, timer, isolate);
//   .....
//   code that needs to be timed.
//   ....
// }
class TimerScope : public StackResource {
 public:
  TimerScope(bool flag, Timer* timer, Thread* thread = NULL)
      : StackResource(thread), nested_(false), timer_(flag ? timer : NULL) {
    Init();
  }

  void Init() {
    if (timer_ != NULL) {
      if (!timer_->running()) {
        timer_->Start();
      } else {
        nested_ = true;
      }
    }
  }
  ~TimerScope() {
    if (timer_ != NULL) {
      if (!nested_) {
        timer_->Stop();
      }
    }
  }

 private:
  bool nested_;
  Timer* const timer_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(TimerScope);
};

class PauseTimerScope : public StackResource {
 public:
  PauseTimerScope(bool flag, Timer* timer, Thread* thread = NULL)
      : StackResource(thread), nested_(false), timer_(flag ? timer : NULL) {
    if (timer_) {
      if (timer_->running()) {
        timer_->Stop();
      } else {
        nested_ = true;
      }
    }
  }
  ~PauseTimerScope() {
    if (timer_) {
      if (!nested_) {
        timer_->Start();
      }
    }
  }

 private:
  bool nested_;
  Timer* const timer_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(PauseTimerScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_TIMER_H_
