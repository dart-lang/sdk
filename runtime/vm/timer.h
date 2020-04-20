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
    max_contiguous_ = Utils::Maximum(max_contiguous_.load(), elapsed);
    // Make increment atomic in case it occurs in parallel with aggregation.
    total_.fetch_add(elapsed);
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

  void AddTotal(const Timer& other) { total_.fetch_add(other.total_); }

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

  RelaxedAtomic<int64_t> start_;
  RelaxedAtomic<int64_t> stop_;
  RelaxedAtomic<int64_t> total_;
  RelaxedAtomic<int64_t> max_contiguous_;
  bool report_;
  bool running_;
  const char* message_;

  DISALLOW_COPY_AND_ASSIGN(Timer);
};

}  // namespace dart

#endif  // RUNTIME_VM_TIMER_H_
