// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMER_H_
#define VM_TIMER_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

// Timer class allows timing of specific operations in the VM.
class Timer : public ValueObject {
 public:
  Timer(bool enabled, const char* message)
      : start_(0), stop_(0), total_(0),
        enabled_(enabled), running_(false), message_(message) {}
  ~Timer() {}

  // Start timer.
  void Start() {
    if (enabled_) {
      start_ = OS::GetCurrentTimeMicros();
      running_ = true;
    }
  }

  // Stop timer.
  void Stop() {
    if (enabled_) {
      ASSERT(start_ != 0);
      ASSERT(running());
      stop_ = OS::GetCurrentTimeMicros();
      total_ += ElapsedMicros();
      running_ = false;
    }
  }

  // Get total cummulative elapsed time in micros.
  int64_t TotalElapsedTime() const {
    if (enabled_) {
      int64_t result = total_;
      return result;
    }
    return 0;
  }

  void Reset() {
    if (enabled_) {
      start_ = 0;
      stop_ = 0;
      total_ = 0;
      running_ = false;
    }
  }

  // Accessors.
  bool enabled() const { return enabled_; }
  bool running() const { return running_; }
  const char* message() const { return message_; }

 private:
  int64_t ElapsedMicros() const {
    if (enabled_) {
      ASSERT(start_ != 0);
      ASSERT(stop_ != 0);
      return stop_ - start_;
    }
    return 0;
  }

  int64_t start_;
  int64_t stop_;
  int64_t total_;
  bool enabled_;
  bool running_;
  const char* message_;

  DISALLOW_COPY_AND_ASSIGN(Timer);
};

// List of per isolate timers.
#define TIMER_LIST(V)                                                          \
  V(time_script_loading, "Script Loading : ")                                  \
  V(time_creating_snapshot, "Snapshot Creation : ")                            \
  V(time_isolate_initialization, "Isolate initialization : ")                  \
  V(time_compilation, "Function compilation : ")                               \
  V(time_bootstrap, "Bootstrap of core classes : ")                            \
  V(time_total_runtime, "Total runtime for isolate : ")                        \

// Declare command line flags for the timers.
#define DECLARE_TIMER_FLAG(name, msg)                                          \
  DECLARE_FLAG(bool, name);
TIMER_LIST(DECLARE_TIMER_FLAG)
#undef DECLARE_TIMER_FLAG
DECLARE_FLAG(bool, time_all);  // In order to turn on all the timer flags.

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

 private:
#define TIMER_FIELD(name, msg) Timer name##_;
  TIMER_LIST(TIMER_FIELD)
#undef TIMER_FIELD
  bool padding_;
  DISALLOW_COPY_AND_ASSIGN(TimerList);
};

// Timer Usage.
#define START_TIMER(name)                                                      \
  if (FLAG_##name || FLAG_time_all) {                                          \
    Isolate::Current()->timer_list().name().Start();                           \
  }
#define STOP_TIMER(name)                                                       \
  if (FLAG_##name || FLAG_time_all) {                                          \
    Isolate::Current()->timer_list().name().Stop();                            \
  }


// The class TimerScope is used to start and stop a timer within a scope.
// It is used as follows:
// {
//   TIMERSCOPE(name_of_timer);
//   ....
//   .....
//   code that needs to be timed.
//   ....
// }
class TimerScope : public StackResource {
 public:
  TimerScope(bool flag, Timer* timer, BaseIsolate* isolate = NULL)
      : StackResource(isolate), flag_(flag), nested_(false), timer_(timer) {
    if (flag_) {
      if (!timer_->running()) {
        timer_->Start();
      } else {
        nested_ = true;
      }
    }
  }
  ~TimerScope() {
    if (flag_) {
      if (!nested_) {
        timer_->Stop();
      }
    }
  }

 private:
  bool flag_;
  bool nested_;
  Timer* timer_;
  DISALLOW_COPY_AND_ASSIGN(TimerScope);
};

#define TIMERSCOPE(name)                                                       \
  TimerScope vm_internal_timer_((FLAG_##name || FLAG_time_all),                \
                                &(Isolate::Current()->timer_list().name()))

}  // namespace dart

#endif  // VM_TIMER_H_
