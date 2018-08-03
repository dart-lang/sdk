// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_THREAD_WIN_H_
#define RUNTIME_VM_OS_THREAD_WIN_H_

#if !defined(RUNTIME_VM_OS_THREAD_H_)
#error Do not include os_thread_win.h directly; use os_thread.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/allocation.h"

namespace dart {

typedef DWORD ThreadLocalKey;
typedef DWORD ThreadId;
typedef HANDLE ThreadJoinId;

static const ThreadLocalKey kUnsetThreadLocalKey = TLS_OUT_OF_INDEXES;

class ThreadInlineImpl {
 private:
  ThreadInlineImpl() {}
  ~ThreadInlineImpl() {}

  static uword GetThreadLocal(ThreadLocalKey key) {
    ASSERT(key != kUnsetThreadLocalKey);
    return reinterpret_cast<uword>(TlsGetValue(key));
  }

  friend class OSThread;
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
  friend class OS;

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
  friend class OS;
  friend unsigned int __stdcall ThreadEntry(void* data_ptr);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

typedef void (*ThreadDestructor)(void* parameter);

class ThreadLocalEntry {
 public:
  ThreadLocalEntry(ThreadLocalKey key, ThreadDestructor destructor)
      : key_(key), destructor_(destructor) {}

  ThreadLocalKey key() const { return key_; }

  ThreadDestructor destructor() const { return destructor_; }

 private:
  ThreadLocalKey key_;
  ThreadDestructor destructor_;

  DISALLOW_ALLOCATION();
};

template <typename T>
class MallocGrowableArray;

class ThreadLocalData : public AllStatic {
 public:
  static void RunDestructors();

 private:
  static void AddThreadLocal(ThreadLocalKey key, ThreadDestructor destructor);
  static void RemoveThreadLocal(ThreadLocalKey key);

  static Mutex* mutex_;
  static MallocGrowableArray<ThreadLocalEntry>* thread_locals_;

  static void InitOnce();
  static void Shutdown();

  friend class OS;
  friend class OSThread;
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_WIN_H_
