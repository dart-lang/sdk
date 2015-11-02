// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"

namespace dart {

// The single thread local key which stores all the thread local data
// for a thread.
ThreadLocalKey Thread::thread_key_ = OSThread::kUnsetThreadLocalKey;
Thread* Thread::thread_list_head_ = NULL;
Mutex* Thread::thread_list_lock_ = NULL;

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


void Thread::AddThreadToList(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == NULL);
  ASSERT(thread_list_lock_ != NULL);
  MutexLocker ml(thread_list_lock_);

  ASSERT(thread->thread_list_next_ == NULL);

#if defined(DEBUG)
  {
    // Ensure that we aren't already in the list.
    Thread* current = thread_list_head_;
    while (current != NULL) {
      ASSERT(current != thread);
      current = current->thread_list_next_;
    }
  }
#endif

  // Insert at head of list.
  thread->thread_list_next_ = thread_list_head_;
  thread_list_head_ = thread;
}


void Thread::RemoveThreadFromList(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == NULL);
  ASSERT(thread_list_lock_ != NULL);
  MutexLocker ml(thread_list_lock_);

  // Handle case where |thread| is head of list.
  if (thread_list_head_ == thread) {
    thread_list_head_ = thread->thread_list_next_;
    thread->thread_list_next_ = NULL;
    return;
  }

  Thread* current = thread_list_head_;
  Thread* previous = NULL;

  // Scan across list and remove |thread|.
  while (current != NULL) {
    previous = current;
    current = current->thread_list_next_;
    if (current == thread) {
      // We found |thread|, remove from list.
      previous->thread_list_next_ = current->thread_list_next_;
      thread->thread_list_next_ = NULL;
      return;
    }
  }

  UNREACHABLE();
}


bool Thread::IsThreadInList(ThreadId join_id) {
  if (join_id == OSThread::kInvalidThreadJoinId) {
    return false;
  }
  ThreadIterator it;
  while (it.HasNext()) {
    Thread* t = it.Next();
    // An address test is not sufficient because the allocator may recycle
    // the address for another Thread. Test against the thread's join id.
    if (t->join_id() == join_id) {
      return true;
    }
  }
  return false;
}


static void DeleteThread(void* thread) {
  delete reinterpret_cast<Thread*>(thread);
}


void Thread::Shutdown() {
  if (thread_list_lock_ != NULL) {
    // Delete the current thread.
    Thread* thread = Current();
    ASSERT(thread != NULL);
    delete thread;
    thread = NULL;
    SetCurrent(NULL);

    // Check that there are no more threads, then delete the lock.
    {
      MutexLocker ml(thread_list_lock_);
      ASSERT(thread_list_head_ == NULL);
    }

    // Clean up TLS.
    OSThread::DeleteThreadLocal(thread_key_);
    thread_key_ = OSThread::kUnsetThreadLocalKey;

    // Delete the thread list lock.
    delete thread_list_lock_;
    thread_list_lock_ = NULL;
  }
}


Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
  // Clear |this| from all isolate's thread registry.
  ThreadPruner pruner(this);
  Isolate::VisitIsolates(&pruner);
  delete log_;
  log_ = NULL;
  RemoveThreadFromList(this);
}


void Thread::InitOnceBeforeIsolate() {
  ASSERT(thread_list_lock_ == NULL);
  thread_list_lock_ = new Mutex();
  ASSERT(thread_list_lock_ != NULL);
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


#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object)                                   \
  object##_handle_(NULL),


Thread::Thread(bool init_vm_constants)
    : id_(OSThread::GetCurrentThreadId()),
      join_id_(OSThread::GetCurrentThreadJoinId()),
      thread_interrupt_disabled_(1),  // Thread interrupts disabled by default.
      isolate_(NULL),
      heap_(NULL),
      timeline_block_(NULL),
      store_buffer_block_(NULL),
      log_(new class Log()),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
      reusable_handles_(),
      cha_(NULL),
      deopt_id_(0),
      vm_tag_(0),
      pending_functions_(GrowableObjectArray::null()),
      no_callback_scope_depth_(0),
      thread_list_next_(NULL) {
  ClearState();

#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#define DEFAULT_INIT(name)                                                     \
  name##_entry_point_ = 0;
RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#define DEFAULT_INIT(returntype, name, ...)                                    \
  name##_entry_point_ = 0;
LEAF_RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

  if (init_vm_constants) {
    InitVMConstants();
  }
  SetCurrent(this);
  AddThreadToList(this);
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

#define INIT_VALUE(name)                                                       \
  ASSERT(name##_entry_point_ == 0);                                            \
  name##_entry_point_ = k##name##RuntimeEntry.GetEntryPoint();
RUNTIME_ENTRY_LIST(INIT_VALUE)
#undef INIT_VALUE

#define INIT_VALUE(returntype, name, ...)                                      \
  ASSERT(name##_entry_point_ == 0);                                            \
  name##_entry_point_ = k##name##RuntimeEntry.GetEntryPoint();
LEAF_RUNTIME_ENTRY_LIST(INIT_VALUE)
#undef INIT_VALUE

  // Setup the thread specific reusable handles.
#define REUSABLE_HANDLE_ALLOCATION(object)                                     \
  this->object##_handle_ = this->AllocateReusableHandle<object>();
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ALLOCATION)
#undef REUSABLE_HANDLE_ALLOCATION
}


void Thread::ClearState() {
  memset(&state_, 0, sizeof(state_));
  pending_functions_ = GrowableObjectArray::null();
}


RawGrowableObjectArray* Thread::pending_functions() {
  if (pending_functions_ == GrowableObjectArray::null()) {
    pending_functions_ = GrowableObjectArray::New(Heap::kOld);
  }
  return pending_functions_;
}


void Thread::Schedule(Isolate* isolate, bool bypass_safepoint) {
  State st;
  if (isolate->thread_registry()->RestoreStateTo(this, &st, bypass_safepoint)) {
    ASSERT(isolate->thread_registry()->Contains(this));
    state_ = st;
  }
}


void Thread::Unschedule(bool bypass_safepoint) {
  ThreadRegistry* reg = isolate_->thread_registry();
  ASSERT(reg->Contains(this));
  reg->SaveStateFrom(this, state_, bypass_safepoint);
  ClearState();
}


void Thread::EnterIsolate(Isolate* isolate) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() == NULL);
  ASSERT(!isolate->HasMutatorThread());
  thread->isolate_ = isolate;
  isolate->MakeCurrentThreadMutator(thread);
  thread->set_vm_tag(VMTag::kVMTagId);
  ASSERT(thread->store_buffer_block_ == NULL);
  thread->StoreBufferAcquire();
  ASSERT(isolate->heap() != NULL);
  thread->heap_ = isolate->heap();
  thread->Schedule(isolate);
  thread->EnableThreadInterrupts();
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  // TODO(koda): Audit callers; they should know whether they're in an isolate.
  if (thread == NULL || thread->isolate() == NULL) return;
#if defined(DEBUG)
  ASSERT(!thread->IsAnyReusableHandleScopeActive());
#endif  // DEBUG
  thread->DisableThreadInterrupts();
  // Clear since GC will not visit the thread once it is unscheduled.
  thread->ClearReusableHandles();
  Isolate* isolate = thread->isolate();
  thread->Unschedule();
  // TODO(koda): Move store_buffer_block_ into State.
  thread->StoreBufferRelease();
  if (isolate->is_runnable()) {
    thread->set_vm_tag(VMTag::kIdleTagId);
  } else {
    thread->set_vm_tag(VMTag::kLoadWaitTagId);
  }
  isolate->ClearMutatorThread();
  thread->isolate_ = NULL;
  ASSERT(Isolate::Current() == NULL);
  thread->heap_ = NULL;
}


void Thread::EnterIsolateAsHelper(Isolate* isolate, bool bypass_safepoint) {
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
  // Do not update isolate->mutator_thread, but perform sanity check:
  // this thread should not be both the main mutator and helper.
  ASSERT(!thread->IsMutatorThread());
  thread->Schedule(isolate, bypass_safepoint);
  thread->EnableThreadInterrupts();
}


void Thread::ExitIsolateAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  thread->DisableThreadInterrupts();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  thread->Unschedule(bypass_safepoint);
  // TODO(koda): Move store_buffer_block_ into State.
  thread->StoreBufferRelease();
  thread->isolate_ = NULL;
  thread->heap_ = NULL;
  ASSERT(!thread->IsMutatorThread());
}


// TODO(koda): Make non-static and invoke in SafepointThreads.
void Thread::PrepareForGC() {
  Thread* thread = Thread::Current();
  // Prevent scheduling another GC.
  thread->StoreBufferRelease(StoreBuffer::kIgnoreThreshold);
  // Make sure to get an *empty* block; the isolate needs all entries
  // at GC time.
  // TODO(koda): Replace with an epilogue (PrepareAfterGC) that acquires.
  thread->store_buffer_block_ =
      thread->isolate()->store_buffer()->PopEmptyBlock();
}


void Thread::StoreBufferBlockProcess(StoreBuffer::ThresholdPolicy policy) {
  StoreBufferRelease(policy);
  StoreBufferAcquire();
}


void Thread::StoreBufferAddObject(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
  }
}


void Thread::StoreBufferAddObjectGC(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kIgnoreThreshold);
  }
}


void Thread::StoreBufferRelease(StoreBuffer::ThresholdPolicy policy) {
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = NULL;
  isolate_->store_buffer()->PushBlock(block, policy);
}


void Thread::StoreBufferAcquire() {
  store_buffer_block_ = isolate()->store_buffer()->PopNonFullBlock();
}


bool Thread::IsMutatorThread() const {
  return ((isolate_ != NULL) && (isolate_->mutator_thread() == this));
}


bool Thread::IsExecutingDartCode() const {
  return (top_exit_frame_info() == 0) &&
         (vm_tag() == VMTag::kDartTagId);
}


bool Thread::HasExitedDartCode() const {
  return (top_exit_frame_info() != 0) &&
         (vm_tag() != VMTag::kDartTagId);
}


CHA* Thread::cha() const {
  ASSERT(isolate_ != NULL);
  return cha_;
}


void Thread::set_cha(CHA* value) {
  ASSERT(isolate_ != NULL);
  cha_ = value;
}


Log* Thread::log() const {
  return log_;
}


template<class C>
C* Thread::AllocateReusableHandle() {
  C* handle = reinterpret_cast<C*>(reusable_handles_.AllocateScopedHandle());
  C::initializeHandle(handle, C::null());
  return handle;
}


void Thread::ClearReusableHandles() {
#define CLEAR_REUSABLE_HANDLE(object)                                          \
  *object##_handle_ = object::null();
  REUSABLE_HANDLE_LIST(CLEAR_REUSABLE_HANDLE)
#undef CLEAR_REUSABLE_HANDLE
}


void Thread::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);

  // Visit objects in thread specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

  if (pending_functions_ != GrowableObjectArray::null()) {
    visitor->VisitPointer(
        reinterpret_cast<RawObject**>(&pending_functions_));
  }
}


void Thread::DisableThreadInterrupts() {
  ASSERT(Thread::Current() == this);
  AtomicOperations::FetchAndIncrement(&thread_interrupt_disabled_);
}


void Thread::EnableThreadInterrupts() {
  ASSERT(Thread::Current() == this);
  uintptr_t old =
      AtomicOperations::FetchAndDecrement(&thread_interrupt_disabled_);
  if (old == 1) {
    // We just decremented from 1 to 0.
    // Make sure the thread interrupter is awake.
    ThreadInterrupter::WakeUp();
  }
  if (old == 0) {
    // We just decremented from 0, this means we've got a mismatched pair
    // of calls to EnableThreadInterrupts and DisableThreadInterrupts.
    FATAL("Invalid call to Thread::EnableThreadInterrupts()");
  }
}


bool Thread::ThreadInterruptsEnabled() {
  return AtomicOperations::LoadRelaxed(&thread_interrupt_disabled_) == 0;
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


intptr_t Thread::OffsetFromThread(const RuntimeEntry* runtime_entry) {
#define COMPUTE_OFFSET(name)                                                   \
  if (runtime_entry->function() == k##name##RuntimeEntry.function())         { \
    return Thread::name##_entry_point_offset();                                \
  }
RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

#define COMPUTE_OFFSET(returntype, name, ...)                                  \
  if (runtime_entry->function() == k##name##RuntimeEntry.function())         { \
    return Thread::name##_entry_point_offset();                                \
  }
LEAF_RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

  UNREACHABLE();
  return -1;
}


ThreadIterator::ThreadIterator() {
  ASSERT(Thread::thread_list_lock_ != NULL);
  // Lock the thread list while iterating.
  Thread::thread_list_lock_->Lock();
  next_ = Thread::thread_list_head_;
}


ThreadIterator::~ThreadIterator() {
  ASSERT(Thread::thread_list_lock_ != NULL);
  // Unlock the thread list when done.
  Thread::thread_list_lock_->Unlock();
}


bool ThreadIterator::HasNext() const {
  ASSERT(Thread::thread_list_lock_ != NULL);
  ASSERT(Thread::thread_list_lock_->IsOwnedByCurrentThread());
  return next_ != NULL;
}


Thread* ThreadIterator::Next() {
  ASSERT(Thread::thread_list_lock_ != NULL);
  ASSERT(Thread::thread_list_lock_->IsOwnedByCurrentThread());
  Thread* current = next_;
  next_ = next_->thread_list_next_;
  return current;
}


DisableThreadInterruptsScope::DisableThreadInterruptsScope(Thread* thread)
    : StackResource(thread) {
  if (thread != NULL) {
    thread->DisableThreadInterrupts();
  }
}


DisableThreadInterruptsScope::~DisableThreadInterruptsScope() {
  if (thread() != NULL) {
    thread()->EnableThreadInterrupts();
  }
}

}  // namespace dart
