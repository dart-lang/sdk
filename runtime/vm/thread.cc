// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/isolate.h"
#include "vm/os_thread.h"


namespace dart {

// The single thread local key which stores all the thread local data
// for a thread.
// TODO(koda): Can we merge this with ThreadInterrupter::thread_state_key_?
ThreadLocalKey Thread::thread_key_ = OSThread::kUnsetThreadLocalKey;


void Thread::InitOnce() {
  ASSERT(thread_key_ == OSThread::kUnsetThreadLocalKey);
  thread_key_ = OSThread::CreateThreadLocal();
  ASSERT(thread_key_ != OSThread::kUnsetThreadLocalKey);
}


void Thread::SetCurrent(Thread* current) {
  OSThread::SetThreadLocal(thread_key_, reinterpret_cast<uword>(current));
}

}  // namespace dart
