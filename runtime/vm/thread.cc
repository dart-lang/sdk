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


// Remove |thread| from each isolate's thread registry.
class ThreadPruner : public IsolateVisitor {
 public:
  explicit ThreadPruner(Thread* thread)
      : thread_(thread) {
    ASSERT(thread_ != NULL);
  }

  void VisitIsolate(Isolate* isolate) {
    ThreadRegistry* registry = isolate->thread_registry();
    ASSERT(registry != NULL);
    registry->PruneThread(thread_);
  }
 private:
  Thread* thread_;
};


static void DeleteThread(void* thread) {
  delete reinterpret_cast<Thread*>(thread);
}


Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
  // Clear |this| from all isolate's thread registry.
  ThreadPruner pruner(this);
  Isolate::VisitIsolates(&pruner);
}


void Thread::InitOnceBeforeIsolate() {
  ASSERT(thread_key_ == OSThread::kUnsetThreadLocalKey);
  thread_key_ = OSThread::CreateThreadLocal(DeleteThread);
  ASSERT(thread_key_ != OSThread::kUnsetThreadLocalKey);
  ASSERT(Thread::Current() == NULL);
  // Allocate a new Thread and postpone initialization of VM constants for
  // this first thread.
  Thread* thread = new Thread(false);
  // Verify that current thread was set.
  ASSERT(Thread::Current() == thread);
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
    // Allocate a new Thread.
    Thread* thread = new Thread();
    // Verify that current thread was set.
    ASSERT(Thread::Current() == thread);
  }
}


#if defined(TARGET_OS_WINDOWS)
void Thread::CleanUp() {
  Thread* current = Current();
  if (current != NULL) {
    SetCurrent(NULL);
    delete current;
  }
}
#endif


Thread::Thread(bool init_vm_constants)
    : id_(OSThread::GetCurrentThreadId()),
      thread_interrupt_callback_(NULL),
      thread_interrupt_data_(NULL),
      isolate_(NULL),
      heap_(NULL),
      store_buffer_block_(NULL) {
  ClearState();
#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT
  if (init_vm_constants) {
    InitVMConstants();
  }
  SetCurrent(this);
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
  thread->StoreBufferAcquire();
  ASSERT(isolate->heap() != NULL);
  thread->heap_ = isolate->heap();
  thread->Schedule(isolate);
  // TODO(koda): Migrate profiler interface to use Thread.
  Profiler::BeginExecution(isolate);
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  // TODO(koda): Audit callers; they should know whether they're in an isolate.
  if (thread == NULL || thread->isolate() == NULL) return;
  Isolate* isolate = thread->isolate();
  Profiler::EndExecution(isolate);
  thread->Unschedule();
  // TODO(koda): Move store_buffer_block_ into State.
  thread->StoreBufferRelease();
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
  ASSERT(thread->store_buffer_block_ == NULL);
  // TODO(koda): Use StoreBufferAcquire once we properly flush before Scavenge.
  thread->store_buffer_block_ =
      thread->isolate()->store_buffer()->PopEmptyBlock();
  ASSERT(isolate->heap() != NULL);
  thread->heap_ = isolate->heap();
  ASSERT(thread->thread_interrupt_callback_ == NULL);
  ASSERT(thread->thread_interrupt_data_ == NULL);
  // Do not update isolate->mutator_thread, but perform sanity check:
  // this thread should not be both the main mutator and helper.
  ASSERT(!isolate->MutatorThreadIsCurrentThread());
  thread->Schedule(isolate);
}


void Thread::ExitIsolateAsHelper() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  thread->Unschedule();
  // TODO(koda): Move store_buffer_block_ into State.
  thread->StoreBufferRelease();
  thread->isolate_ = NULL;
  thread->heap_ = NULL;
  ASSERT(!isolate->MutatorThreadIsCurrentThread());
}


// TODO(koda): Make non-static and invoke in SafepointThreads.
void Thread::PrepareForGC() {
  Thread* thread = Thread::Current();
  const bool kDoNotCheckThreshold = false;  // Prevent scheduling another GC.
  thread->StoreBufferRelease(kDoNotCheckThreshold);
  // Make sure to get an *empty* block; the isolate needs all entries
  // at GC time.
  // TODO(koda): Replace with an epilogue (PrepareAfterGC) that acquires.
  thread->store_buffer_block_ =
      thread->isolate()->store_buffer()->PopEmptyBlock();
}


void Thread::StoreBufferBlockProcess(bool check_threshold) {
  StoreBufferRelease(check_threshold);
  StoreBufferAcquire();
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


void Thread::StoreBufferRelease(bool check_threshold) {
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = NULL;
  isolate_->store_buffer()->PushBlock(block, check_threshold);
}


void Thread::StoreBufferAcquire() {
  store_buffer_block_ = isolate()->store_buffer()->PopNonFullBlock();
}


CHA* Thread::cha() const {
  ASSERT(isolate_ != NULL);
  return isolate_->cha_;
}


void Thread::set_cha(CHA* value) {
  ASSERT(isolate_ != NULL);
  isolate_->cha_ = value;
}


void Thread::SetThreadInterrupter(ThreadInterruptCallback callback,
                                  void* data) {
  ASSERT(Thread::Current() == this);
  thread_interrupt_callback_ = callback;
  thread_interrupt_data_ = data;
}


bool Thread::IsThreadInterrupterEnabled(ThreadInterruptCallback* callback,
                                        void** data) const {
#if defined(TARGET_OS_WINDOWS)
  // On Windows we expect this to be called from the thread interrupter thread.
  ASSERT(id() != OSThread::GetCurrentThreadId());
#else
  // On posix platforms, we expect this to be called from signal handler.
  ASSERT(id() == OSThread::GetCurrentThreadId());
#endif
  ASSERT(callback != NULL);
  ASSERT(data != NULL);
  *callback = thread_interrupt_callback_;
  *data = thread_interrupt_data_;
  return (*callback != NULL) &&
         (*data != NULL);
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
