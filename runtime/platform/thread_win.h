// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_THREAD_WIN_H_
#define PLATFORM_THREAD_WIN_H_

#if !defined(PLATFORM_THREAD_H_)
#error Do not include thread_win.h directly; use thread.h instead.
#endif

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

#endif  // PLATFORM_THREAD_WIN_H_
