// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/isolate.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/thread_interrupter.h"


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


void Thread::EnsureInit() {
  if (Thread::Current() == NULL) {
    SetCurrent(new Thread());
  }
}


void Thread::CleanUp() {
  // We currently deallocate the Thread, to ensure that embedder threads don't
  // leak the Thread structure. An alternative approach would be to clear and
  // reuse it, but register a destructor at the OS level.
  Thread* current = Current();
  if (current != NULL) {
    delete current;
  }
  SetCurrent(NULL);
}


void Thread::EnterIsolate(Isolate* isolate) {
  EnsureInit();
  Thread* thread = Thread::Current();
  ASSERT(thread->isolate() == NULL);
  ASSERT(isolate->mutator_thread() == NULL);
  isolate->set_mutator_thread(thread);
  // TODO(koda): Migrate thread_state_ and profile_data_ to Thread, to allow
  // helper threads concurrent with mutator.
  ASSERT(isolate->thread_state() == NULL);
  InterruptableThreadState* thread_state =
      ThreadInterrupter::GetCurrentThreadState();
#if defined(DEBUG)
  Isolate::CheckForDuplicateThreadState(thread_state);
#endif
  ASSERT(thread_state != NULL);
  Profiler::BeginExecution(isolate);
  isolate->set_thread_state(thread_state);
  isolate->set_vm_tag(VMTag::kVMTagId);
  thread->isolate_ = isolate;
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  // TODO(koda): Audit callers; they should know whether they're in an isolate.
  if (thread == NULL) return;
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  isolate->set_vm_tag(VMTag::kIdleTagId);
  isolate->set_thread_state(NULL);
  Profiler::EndExecution(isolate);
  isolate->set_mutator_thread(NULL);
  thread->isolate_ = NULL;
  ASSERT(Isolate::Current() == NULL);
  CleanUp();
}


}  // namespace dart
