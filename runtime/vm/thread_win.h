// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_WIN_H_
#define VM_THREAD_WIN_H_

#include "vm/globals.h"

namespace dart {

class ThreadData {
 private:
  ThreadData() {}
  ~ThreadData() {}

  uintptr_t thread_handle_;
  uint32_t tid_;

  friend class Thread;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ThreadData);
};


class MutexData {
 private:
  MutexData() {}
  ~MutexData() {}

  HANDLE semaphore_;

  friend class Mutex;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MutexData);
};


class MonitorData {
 private:
  MonitorData() {}
  ~MonitorData() {}

  CRITICAL_SECTION cs_;
  // TODO(ager): Condition variables only available since Windows
  // Vista. Therefore, this is only a temporary solution. We will have
  // to implement simple condition variables for use in Windows XP and
  // earlier.
  CONDITION_VARIABLE cond_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace dart

#endif  // VM_THREAD_WIN_H_
