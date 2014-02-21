// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMER_SCOPE_H_
#define VM_TIMER_SCOPE_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/os.h"
#include "vm/timer.h"

namespace dart {

// Transition from executing VM code to executing Native code.
class VmToNativeTimerScope : public ValueObject {
 public:
  explicit VmToNativeTimerScope(Isolate* isolate) {
    native_timer_ = &(isolate->timer_list().time_native_execution());
    native_timer_->Start();
  }
  ~VmToNativeTimerScope() {
    native_timer_->Stop();
  }

 private:
  Timer* native_timer_;
  DISALLOW_COPY_AND_ASSIGN(VmToNativeTimerScope);
};

// Transition from executing Native code to executing VM code.
class NativeToVmTimerScope : public ValueObject {
 public:
  explicit NativeToVmTimerScope(Isolate* isolate)
      : dart_running_(false),
        timer_list_(&(isolate->timer_list())) {
    Timer* dart_timer = &(timer_list_->time_dart_execution());
    // Currently when a native function is setup without the auto scope
    // setup parameter (leaf function) we would have the dart timer still
    // running as we have not done any transitioning. If for some reason
    // such a native function makes API call backs we should account for
    // that.
    if (dart_timer->running()) {
      dart_running_ = true;
      dart_timer->Stop();
    } else {
      Timer* native_timer = &(timer_list_->time_native_execution());
      native_timer->Stop();
    }
  }
  ~NativeToVmTimerScope() {
    if (dart_running_) {
      Timer* dart_timer = &(timer_list_->time_dart_execution());
      dart_timer->Start();
    } else {
      Timer* native_timer = &(timer_list_->time_native_execution());
      native_timer->Start();
    }
  }

 private:
  bool dart_running_;
  TimerList* timer_list_;
  DISALLOW_COPY_AND_ASSIGN(NativeToVmTimerScope);
};

// Transition from executing Dart code to executing Native code.
class DartToNativeTimerScope : public ValueObject {
 public:
  explicit DartToNativeTimerScope(Isolate* isolate) {
    dart_timer_ = &(isolate->timer_list().time_dart_execution());
    native_timer_ = &(isolate->timer_list().time_native_execution());
    dart_timer_->Stop();
    native_timer_->Start();
  }
  ~DartToNativeTimerScope() {
    native_timer_->Stop();
    dart_timer_->Start();
  }

 private:
  Timer* native_timer_;
  Timer* dart_timer_;
  DISALLOW_COPY_AND_ASSIGN(DartToNativeTimerScope);
};

// Transition from executing Dart code to executing VM code.
class DartToVmTimerScope : public ValueObject {
 public:
  explicit DartToVmTimerScope(Isolate* isolate) {
    dart_timer_ = &(isolate->timer_list().time_dart_execution());
    dart_timer_->Stop();
  }
  ~DartToVmTimerScope() {
    dart_timer_->Start();
  }

 private:
  Timer* dart_timer_;
  DISALLOW_COPY_AND_ASSIGN(DartToVmTimerScope);
};

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
  TimerScope(bool flag, Timer* timer, BaseIsolate* isolate)
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

#define TIMERSCOPE(isolate, name)                                              \
  TimerScope vm_internal_timer_(true, &(isolate->timer_list().name()), isolate)

}  // namespace dart

#endif  // VM_TIMER_SCOPE_H_
