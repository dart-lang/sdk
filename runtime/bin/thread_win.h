// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_THREAD_WIN_H_
#define RUNTIME_BIN_THREAD_WIN_H_

#if !defined(RUNTIME_BIN_THREAD_H_)
#error Do not include thread_win.h directly; use thread.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

typedef DWORD ThreadLocalKey;
typedef DWORD ThreadId;

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
  friend unsigned int __stdcall ThreadEntry(void* data_ptr);

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
 public:
  static void ThreadExit();

 private:
  explicit MonitorWaitData(HANDLE event) : event_(event), next_(NULL) {}
  ~MonitorWaitData() {
    CloseHandle(event_);
    ASSERT(next_ == NULL);
  }

  // ThreadLocalKey used to fetch and store the MonitorWaitData object
  // for a given thread.
  static ThreadLocalKey monitor_wait_data_key_;

  // Auto-reset event used for waiting.
  HANDLE event_;
  // Link to next element in the singly-linked list of waiters.
  MonitorWaitData* next_;

  friend class Monitor;
  friend class MonitorData;
  friend class Thread;

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
  static MonitorWaitData* GetMonitorWaitDataForThread();

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
  friend class Thread;
  friend unsigned int __stdcall ThreadEntry(void* data_ptr);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_THREAD_WIN_H_
