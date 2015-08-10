// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMER_H_
#define VM_TIMER_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

class JSONObject;

// Timer class allows timing of specific operations in the VM.
class Timer : public ValueObject {
 public:
  Timer(bool report, const char* message)
      : report_(report), message_(message) {
    Reset();
  }
  ~Timer() {}

  // Start timer.
  void Start() {
    start_ = OS::GetCurrentTimeMicros();
    running_ = true;
  }

  // Stop timer.
  void Stop() {
    ASSERT(start_ != 0);
    ASSERT(running());
    stop_ = OS::GetCurrentTimeMicros();
    int64_t elapsed = ElapsedMicros();
    max_contiguous_ = Utils::Maximum(max_contiguous_, elapsed);
    total_ += elapsed;
    running_ = false;
  }

  // Get total cummulative elapsed time in micros.
  int64_t TotalElapsedTime() const {
    int64_t result = total_;
    if (running_) {
      int64_t now = OS::GetCurrentTimeMicros();
      result += (now - start_);
    }
    return result;
  }

  int64_t MaxContiguous() const {
    int64_t result = max_contiguous_;
    if (running_) {
      int64_t now = OS::GetCurrentTimeMicros();
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

// List of per isolate timers.
#define TIMER_LIST(V)                                                          \
  V(time_script_loading, "Script Loading")                                     \
  V(time_creating_snapshot, "Snapshot Creation")                               \
  V(time_isolate_initialization, "Isolate initialization")                     \
  V(time_compilation, "Function compilation")                                  \
  V(time_bootstrap, "Bootstrap of core classes")                               \
  V(time_dart_execution, "Dart execution")                                     \
  V(time_total_runtime, "Total runtime for isolate")                           \
  V(time_gc, "Garbage collection")                                             \

// Maintains a list of timers per isolate.
class TimerList : public ValueObject {
 public:
  TimerList();
  ~TimerList() {}

  // Accessors.
#define TIMER_FIELD_ACCESSOR(name, msg)                                        \
  Timer& name() { return name##_; }
  TIMER_LIST(TIMER_FIELD_ACCESSOR)
#undef TIMER_FIELD_ACCESSOR

  void ReportTimers();

  void PrintTimersToJSONProperty(JSONObject* jsobj);

 private:
#define TIMER_FIELD(name, msg) Timer name##_;
  TIMER_LIST(TIMER_FIELD)
#undef TIMER_FIELD
  bool padding_;
  DISALLOW_COPY_AND_ASSIGN(TimerList);
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
      : StackResource(thread),
        nested_(false),
        timer_(flag ? timer : NULL) {
    Init();
  }

  TimerScope(bool flag, Timer* timer, Isolate* isolate = NULL)
      : StackResource(isolate),
        nested_(false),
        timer_(flag ? timer : NULL) {
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
  PauseTimerScope(bool flag, Timer* timer, Isolate* isolate = NULL)
      : StackResource(isolate),
        nested_(false),
        timer_(flag ? timer : NULL) {
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


// Macros to deal with named timers in the isolate.
#define START_TIMER(isolate, name)                                             \
isolate->timer_list().name().Start();

#define STOP_TIMER(isolate, name)                                              \
isolate->timer_list().name().Stop();

#define TIMERSCOPE(isolate, name)                                              \
  TimerScope vm_internal_timer_(true, &(isolate->timer_list().name()), isolate)

#define PAUSETIMERSCOPE(isolate, name)                                         \
PauseTimerScope vm_internal_timer_(true,                                       \
                                   &(isolate->timer_list().name()),            \
                                   isolate)

}  // namespace dart

#endif  // VM_TIMER_H_
