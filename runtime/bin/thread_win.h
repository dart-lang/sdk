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

  SRWLOCK lock_;

  friend class Mutex;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MutexData);
};

class MonitorData {
 private:
  MonitorData() {}
  ~MonitorData() {}

  CRITICAL_SECTION cs_;
  CONDITION_VARIABLE cond_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_THREAD_WIN_H_
