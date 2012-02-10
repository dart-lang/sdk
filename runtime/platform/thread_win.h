// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_THREAD_WIN_H_
#define PLATFORM_THREAD_WIN_H_

#if !defined(PLATFORM_THREAD_H_)
#error Do not include thread_win.h directly; use thread.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

typedef DWORD ThreadLocalKey;

class ThreadInlineImpl {
 private:
  ThreadInlineImpl() {}
  ~ThreadInlineImpl() {}

  static uword GetThreadLocal(ThreadLocalKey key) {
    static ThreadLocalKey kUnsetThreadLocalKey = TLS_OUT_OF_INDEXES;
    ASSERT(key != kUnsetThreadLocalKey);
    return reinterpret_cast<uword>(TlsGetValue(key));
  }

  friend class Thread;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ThreadInlineImpl);
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

  // Condition variables are only available since Windows Vista. To
  // support at least Windows XP, we implement our own condition
  // variables using SetEvent on Event objects.

  // The notify_event_ is an auto-reset event which means that
  // SetEvent only wakes up one waiter.
  HANDLE notify_event_;

  // The notify_all_event_ is a manual-reset event which means that
  // SetEvent wakes up all waiters.
  HANDLE notify_all_event_;

  // Counter with protection used to determine the right time to reset
  // the notify_all_event_.
  CRITICAL_SECTION waiters_cs_;
  intptr_t waiters_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace dart

#endif  // PLATFORM_THREAD_WIN_H_
