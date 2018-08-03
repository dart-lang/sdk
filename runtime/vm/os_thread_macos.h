// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_THREAD_MACOS_H_
#define RUNTIME_VM_OS_THREAD_MACOS_H_

#if !defined(RUNTIME_VM_OS_THREAD_H_)
#error Do not include os_thread_macos.h directly; use os_thread.h instead.
#endif

#include <pthread.h>

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

typedef pthread_key_t ThreadLocalKey;
typedef pthread_t ThreadId;
typedef pthread_t ThreadJoinId;

static const ThreadLocalKey kUnsetThreadLocalKey =
    static_cast<pthread_key_t>(-1);

class ThreadInlineImpl {
 private:
  ThreadInlineImpl() {}
  ~ThreadInlineImpl() {}

  static uword GetThreadLocal(ThreadLocalKey key) {
    static ThreadLocalKey kUnsetThreadLocalKey = static_cast<pthread_key_t>(-1);
    ASSERT(key != kUnsetThreadLocalKey);
    return reinterpret_cast<uword>(pthread_getspecific(key));
  }

  friend class OSThread;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ThreadInlineImpl);
};

class MutexData {
 private:
  MutexData() {}
  ~MutexData() {}

  pthread_mutex_t* mutex() { return &mutex_; }

  pthread_mutex_t mutex_;

  friend class Mutex;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MutexData);
};

class MonitorData {
 private:
  MonitorData() {}
  ~MonitorData() {}

  pthread_mutex_t* mutex() { return &mutex_; }
  pthread_cond_t* cond() { return &cond_; }

  pthread_mutex_t mutex_;
  pthread_cond_t cond_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_MACOS_H_
