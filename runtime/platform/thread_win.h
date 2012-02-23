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


class MonitorWaitData {
 private:
  explicit MonitorWaitData(HANDLE event) : event_(event), next_(NULL) {}

  // ThreadLocalKey used to fetch and store the MonitorWaitData object
  // for a given thread.
  static ThreadLocalKey monitor_wait_data_key_;

  // Auto-reset event used for waiting.
  HANDLE event_;
  // Link to next element in the singly-linked list of waiters.
  MonitorWaitData* next_;

  friend class Monitor;
  friend class MonitorData;

  DISALLOW_COPY_AND_ASSIGN(MonitorWaitData);
};


class MonitorData {
 private:
  MonitorData() {}
  ~MonitorData() {}

  // Helper methods to manipulate the list of waiters for this
  // monitor.
  void AddWaiter(MonitorWaitData* wait_data);
  void RemoveWaiter(MonitorWaitData* wait_data);
  void SignalAndRemoveFirstWaiter();
  void SignalAndRemoveAllWaiters();
  MonitorWaitData* GetMonitorWaitDataForThread();

  // The external critical section for the monitor.
  CRITICAL_SECTION cs_;

  // Condition variables are only available since Windows Vista. To
  // support at least Windows XP, we implement our own condition
  // variables using SetEvent on Event objects.

  // Singly-linked list of event objects, one for each thread waiting
  // on this monitor. New waiters are added at the end of the list.
  // Notify signals the first element of the list (FIFO
  // order). NotifyAll, signals all the elements of the list.
  CRITICAL_SECTION waiters_cs_;
  MonitorWaitData* waiters_head_;
  MonitorWaitData* waiters_tail_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace dart

#endif  // PLATFORM_THREAD_WIN_H_
