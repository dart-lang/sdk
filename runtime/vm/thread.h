// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "vm/base_isolate.h"
#include "vm/globals.h"
#include "vm/os_thread.h"

namespace dart {

class CHA;
class Isolate;

// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation. The Thread structure associated with
// a thread is allocated when the thread enters an isolate, and destroyed
// upon exiting an isolate or an explicit call to CleanUp.
class Thread {
 public:
  // The currently executing thread, or NULL if not yet initialized.
  static Thread* Current() {
    return reinterpret_cast<Thread*>(OSThread::GetThreadLocal(thread_key_));
  }

  // Makes the current thread enter 'isolate'. Also calls EnsureInit.
  static void EnterIsolate(Isolate* isolate);
  // Makes the current thread exit its isolate. Also calls CleanUp.
  static void ExitIsolate();

  // Initializes the current thread as a VM thread, if not already done.
  static void EnsureInit();
  // Clears the state of the current thread.
  static void CleanUp();

  // Called at VM startup.
  static void InitOnce();

  // The topmost zone used for allocation in this thread.
  Zone* zone() {
    return reinterpret_cast<BaseIsolate*>(isolate())->current_zone();
  }

  // The isolate that this thread is operating on, or NULL if none.
  Isolate* isolate() const { return isolate_; }

  // The (topmost) CHA for the compilation in this thread.
  CHA* cha() const { return cha_; }
  void set_cha(CHA* value) { cha_ = value; }

 private:
  static ThreadLocalKey thread_key_;

  Isolate* isolate_;
  CHA* cha_;

  Thread()
      : isolate_(NULL),
        cha_(NULL) {}

  static void SetCurrent(Thread* current);

  DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace dart

#endif  // VM_THREAD_H_
