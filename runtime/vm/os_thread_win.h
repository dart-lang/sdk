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

  SRWLOCK lock_;

  friend class Mutex;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MutexData);
};

class MonitorData {
 private:
  MonitorData() {}
  ~MonitorData() {}

  SRWLOCK lock_;
  CONDITION_VARIABLE cond_;

  friend class Monitor;

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

  static void Init();
  static void Cleanup();

  friend class OS;
  friend class OSThread;
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_WIN_H_
