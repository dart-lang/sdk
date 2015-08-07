// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/stub_code.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"

namespace dart {

// The single thread local key which stores all the thread local data
// for a thread.
ThreadLocalKey Thread::thread_key_ = OSThread::kUnsetThreadLocalKey;


static void DeleteThread(void* thread) {
  delete reinterpret_cast<Thread*>(thread);
}


Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
}


void Thread::InitOnceBeforeIsolate() {
  ASSERT(thread_key_ == OSThread::kUnsetThreadLocalKey);
  thread_key_ = OSThread::CreateThreadLocal(DeleteThread);
  ASSERT(thread_key_ != OSThread::kUnsetThreadLocalKey);
  ASSERT(Thread::Current() == NULL);
  // Postpone initialization of VM constants for this first thread.
  SetCurrent(new Thread(false));
}


void Thread::InitOnceAfterObjectAndStubCode() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == Dart::vm_isolate());
  thread->InitVMConstants();
}


void Thread::SetCurrent(Thread* current) {
  OSThread::SetThreadLocal(thread_key_, reinterpret_cast<uword>(current));
}


void Thread::EnsureInit() {
  if (Thread::Current() == NULL) {
    SetCurrent(new Thread());
  }
}


#if defined(TARGET_OS_WINDOWS)
void Thread::CleanUp() {
  Thread* current = Current();
  if (current != NULL) {
    delete current;
  }
  SetCurrent(NULL);
}
#endif


Thread::Thread(bool init_vm_constants)
    : isolate_(NULL),
      store_buffer_block_(NULL) {
  ClearState();
#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT
  if (init_vm_constants) {
    InitVMConstants();
  }
}


void Thread::InitVMConstants() {
#define ASSERT_VM_HEAP(type_name, member_name, init_expr, default_init_value)  \
  ASSERT((init_expr)->IsOldObject());
CACHED_VM_OBJECTS_LIST(ASSERT_VM_HEAP)
#undef ASSERT_VM_HEAP

#define INIT_VALUE(type_name, member_name, init_expr, default_init_value)      \
  ASSERT(member_name == default_init_value);                                   \
  member_name = (init_expr);
CACHED_CONSTANTS_LIST(INIT_VALUE)
#undef INIT_VALUE
}


void Thread::Schedule(Isolate* isolate) {
  State st;
  if (isolate->thread_registry()->RestoreStateTo(this, &st)) {
    ASSERT(isolate->thread_registry()->Contains(this));
    state_ = st;
  }
}


void Thread::Unschedule() {
  ThreadRegistry* reg = isolate_->thread_registry();
  ASSERT(reg->Contains(this));
  reg->SaveStateFrom(this, state_);
  ClearState();
}


void Thread::EnterIsolate(Isolate* isolate) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == NULL);
  ASSERT(!isolate->HasMutatorThread());
  thread->isolate_ = isolate;
  isolate->MakeCurrentThreadMutator(thread);
  isolate->set_vm_tag(VMTag::kVMTagId);
  ASSERT(thread->store_buffer_block_ == NULL);
  thread->store_buffer_block_ = isolate->store_buffer()->PopNonFullBlock();
  ASSERT(isolate->heap() != NULL);
  thread->heap_ = isolate->heap();
  thread->Schedule(isolate);
  ASSERT(thread->thread_state() == NULL);
  InterruptableThreadState* thread_state =
      ThreadInterrupter::GetCurrentThreadState();
#if defined(DEBUG)
  thread->set_thread_state(NULL);  // Exclude thread itself from the dupe check.
  Isolate::CheckForDuplicateThreadState(thread_state);
  thread->set_thread_state(thread_state);
#endif
  ASSERT(thread_state != NULL);
  // TODO(koda): Migrate profiler interface to use Thread.
  Profiler::BeginExecution(isolate);
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  // TODO(koda): Audit callers; they should know whether they're in an isolate.
  if (thread == NULL || thread->isolate() == NULL) return;
  Isolate* isolate = thread->isolate();
  Profiler::EndExecution(isolate);
  thread->set_thread_state(NULL);
  thread->Unschedule();
  StoreBufferBlock* block = thread->store_buffer_block_;
  thread->store_buffer_block_ = NULL;
  isolate->store_buffer()->PushBlock(block);
  if (isolate->is_runnable()) {
    isolate->set_vm_tag(VMTag::kIdleTagId);
  } else {
    isolate->set_vm_tag(VMTag::kLoadWaitTagId);
  }
  isolate->ClearMutatorThread();
  thread->isolate_ = NULL;
  ASSERT(Isolate::Current() == NULL);
  thread->heap_ = NULL;
}


void Thread::EnterIsolateAsHelper(Isolate* isolate) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == NULL);
  thread->isolate_ = isolate;
  ASSERT(isolate->heap() != NULL);
  thread->heap_ = isolate->heap();
  ASSERT(thread->thread_state() == NULL);
  // Do not update isolate->mutator_thread, but perform sanity check:
  // this thread should not be both the main mutator and helper.
  ASSERT(!isolate->MutatorThreadIsCurrentThread());
  thread->Schedule(isolate);
}


void Thread::ExitIsolateAsHelper() {
  Thread* thread = Thread::Current();
  // If the helper thread chose to use the store buffer, check that it has
  // already been flushed manually.
  ASSERT(thread->store_buffer_block_ == NULL);
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  thread->Unschedule();
  thread->set_thread_state(NULL);
  thread->isolate_ = NULL;
  thread->heap_ = NULL;
  ASSERT(!isolate->MutatorThreadIsCurrentThread());
}


void Thread::PrepareForGC() {
  Thread* thread = Thread::Current();
  StoreBuffer* sb = thread->isolate()->store_buffer();
  StoreBufferBlock* block = thread->store_buffer_block_;
  thread->store_buffer_block_ = NULL;
  const bool kCheckThreshold = false;  // Prevent scheduling another GC.
  sb->PushBlock(block, kCheckThreshold);
  thread->store_buffer_block_ = sb->PopEmptyBlock();
}


void Thread::StoreBufferBlockProcess(bool check_threshold) {
  StoreBuffer* sb = isolate()->store_buffer();
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = NULL;
  sb->PushBlock(block, check_threshold);
  store_buffer_block_ = sb->PopNonFullBlock();
}


void Thread::StoreBufferAddObject(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(true);
  }
}


void Thread::StoreBufferAddObjectGC(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(false);
  }
}


CHA* Thread::cha() const {
  ASSERT(isolate_ != NULL);
  return isolate_->cha_;
}


void Thread::set_cha(CHA* value) {
  ASSERT(isolate_ != NULL);
  isolate_->cha_ = value;
}


bool Thread::CanLoadFromThread(const Object& object) {
#define CHECK_OBJECT(type_name, member_name, expr, default_init_value)         \
  if (object.raw() == expr) return true;
CACHED_VM_OBJECTS_LIST(CHECK_OBJECT)
#undef CHECK_OBJECT
  return false;
}


intptr_t Thread::OffsetFromThread(const Object& object) {
#define COMPUTE_OFFSET(type_name, member_name, expr, default_init_value)       \
  ASSERT((expr)->IsVMHeapObject());                                            \
  if (object.raw() == expr) return Thread::member_name##offset();
CACHED_VM_OBJECTS_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET
  UNREACHABLE();
  return -1;
}

}  // namespace dart
