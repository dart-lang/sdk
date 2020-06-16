// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os_thread.h"

#include "platform/address_sanitizer.h"
#include "platform/atomic.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/thread_interrupter.h"
#include "vm/timeline.h"

namespace dart {

// The single thread local key which stores all the thread local data
// for a thread.
ThreadLocalKey OSThread::thread_key_ = kUnsetThreadLocalKey;
OSThread* OSThread::thread_list_head_ = NULL;
Mutex* OSThread::thread_list_lock_ = NULL;
bool OSThread::creation_enabled_ = false;

#if defined(HAS_C11_THREAD_LOCAL)
thread_local ThreadState* OSThread::current_vm_thread_ = NULL;
#endif

OSThread::OSThread()
    : BaseThread(true),
      id_(OSThread::GetCurrentThreadId()),
#if defined(DEBUG)
      join_id_(kInvalidThreadJoinId),
#endif
#ifdef SUPPORT_TIMELINE
      trace_id_(OSThread::GetCurrentThreadTraceId()),
#endif
      name_(NULL),
      timeline_block_lock_(),
      timeline_block_(NULL),
      thread_list_next_(NULL),
      thread_interrupt_disabled_(1),  // Thread interrupts disabled by default.
      log_(new class Log()),
      stack_base_(0),
      stack_limit_(0),
      stack_headroom_(0),
      thread_(NULL) {
  // Try to get accurate stack bounds from pthreads, etc.
  if (!GetCurrentStackBounds(&stack_limit_, &stack_base_)) {
    FATAL("Failed to retrieve stack bounds");
  }

  stack_headroom_ = CalculateHeadroom(stack_base_ - stack_limit_);

  ASSERT(stack_base_ != 0);
  ASSERT(stack_limit_ != 0);
  ASSERT(stack_base_ > stack_limit_);
  ASSERT(stack_base_ > GetCurrentStackPointer());
  ASSERT(stack_limit_ < GetCurrentStackPointer());
  RELEASE_ASSERT(HasStackHeadroom());
}

OSThread* OSThread::CreateOSThread() {
  ASSERT(thread_list_lock_ != NULL);
  MutexLocker ml(thread_list_lock_);
  if (!creation_enabled_) {
    return NULL;
  }
  OSThread* os_thread = new OSThread();
  AddThreadToListLocked(os_thread);
  return os_thread;
}

OSThread::~OSThread() {
  if (!is_os_thread()) {
    // If the embedder enters an isolate on this thread and does not exit the
    // isolate, the thread local at thread_key_, which we are destructing here,
    // will contain a dart::Thread instead of a dart::OSThread.
    FATAL("Thread exited without calling Dart_ExitIsolate");
  }
  RemoveThreadFromList(this);
  delete log_;
  log_ = NULL;
#if defined(SUPPORT_TIMELINE)
  if (Timeline::recorder() != NULL) {
    Timeline::recorder()->FinishBlock(timeline_block_);
  }
#endif
  timeline_block_ = NULL;
  free(name_);
}

void OSThread::SetName(const char* name) {
  MutexLocker ml(thread_list_lock_);
  // Clear the old thread name.
  if (name_ != NULL) {
    free(name_);
    name_ = NULL;
  }
  set_name(name);
}

// Disable AdressSanitizer and SafeStack transformation on this function. In
// particular, taking the address of a local gives an address on the stack
// instead of an address in the shadow memory (AddressSanitizer) or the safe
// stack (SafeStack).
NO_SANITIZE_ADDRESS
NO_SANITIZE_SAFE_STACK
DART_NOINLINE
uword OSThread::GetCurrentStackPointer() {
  uword stack_allocated_local = reinterpret_cast<uword>(&stack_allocated_local);
  return stack_allocated_local;
}

void OSThread::DisableThreadInterrupts() {
  ASSERT(OSThread::Current() == this);
  thread_interrupt_disabled_.fetch_add(1u);
}

void OSThread::EnableThreadInterrupts() {
  ASSERT(OSThread::Current() == this);
  uintptr_t old = thread_interrupt_disabled_.fetch_sub(1u);
  if (FLAG_profiler && (old == 1)) {
    // We just decremented from 1 to 0.
    // Make sure the thread interrupter is awake.
    ThreadInterrupter::WakeUp();
  }
  if (old == 0) {
    // We just decremented from 0, this means we've got a mismatched pair
    // of calls to EnableThreadInterrupts and DisableThreadInterrupts.
    FATAL("Invalid call to OSThread::EnableThreadInterrupts()");
  }
}

bool OSThread::ThreadInterruptsEnabled() {
  return thread_interrupt_disabled_ == 0;
}

static void DeleteThread(void* thread) {
  delete reinterpret_cast<OSThread*>(thread);
}

void OSThread::Init() {
  // Allocate the global OSThread lock.
  if (thread_list_lock_ == NULL) {
    thread_list_lock_ = new Mutex();
  }
  ASSERT(thread_list_lock_ != NULL);

  // Create the thread local key.
  if (thread_key_ == kUnsetThreadLocalKey) {
    thread_key_ = CreateThreadLocal(DeleteThread);
  }
  ASSERT(thread_key_ != kUnsetThreadLocalKey);

  // Enable creation of OSThread structures in the VM.
  EnableOSThreadCreation();

  // Create a new OSThread strcture and set it as the TLS.
  OSThread* os_thread = CreateOSThread();
  ASSERT(os_thread != NULL);
  OSThread::SetCurrent(os_thread);
  os_thread->set_name("Dart_Initialize");
}

void OSThread::Cleanup() {
// We cannot delete the thread local key and thread list lock,  yet.
// See the note on thread_list_lock_ in os_thread.h.
#if 0
  if (thread_list_lock_ != NULL) {
    // Delete the thread local key.
    ASSERT(thread_key_ != kUnsetThreadLocalKey);
    DeleteThreadLocal(thread_key_);
    thread_key_ = kUnsetThreadLocalKey;

    // Delete the global OSThread lock.
    ASSERT(thread_list_lock_ != NULL);
    delete thread_list_lock_;
    thread_list_lock_ = NULL;
  }
#endif
}

OSThread* OSThread::CreateAndSetUnknownThread() {
  ASSERT(OSThread::GetCurrentTLS() == NULL);
  OSThread* os_thread = CreateOSThread();
  if (os_thread != NULL) {
    OSThread::SetCurrent(os_thread);
    os_thread->set_name("Unknown");
  }
  return os_thread;
}

bool OSThread::IsThreadInList(ThreadId id) {
  if (id == OSThread::kInvalidThreadId) {
    return false;
  }
  OSThreadIterator it;
  while (it.HasNext()) {
    ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
    OSThread* t = it.Next();
    // An address test is not sufficient because the allocator may recycle
    // the address for another Thread. Test against the thread's id.
    if (t->id() == id) {
      return true;
    }
  }
  return false;
}

void OSThread::DisableOSThreadCreation() {
  MutexLocker ml(thread_list_lock_);
  creation_enabled_ = false;
}

void OSThread::EnableOSThreadCreation() {
  MutexLocker ml(thread_list_lock_);
  creation_enabled_ = true;
}

OSThread* OSThread::GetOSThreadFromThread(ThreadState* thread) {
  ASSERT(thread->os_thread() != NULL);
  return thread->os_thread();
}

void OSThread::AddThreadToListLocked(OSThread* thread) {
  ASSERT(thread != NULL);
  ASSERT(thread_list_lock_ != NULL);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  ASSERT(creation_enabled_);
  ASSERT(thread->thread_list_next_ == NULL);

#if defined(DEBUG)
  {
    // Ensure that we aren't already in the list.
    OSThread* current = thread_list_head_;
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

void OSThread::RemoveThreadFromList(OSThread* thread) {
  bool final_thread = false;
  {
    ASSERT(thread != NULL);
    ASSERT(thread_list_lock_ != NULL);
    MutexLocker ml(thread_list_lock_);
    OSThread* current = thread_list_head_;
    OSThread* previous = NULL;

    // Scan across list and remove |thread|.
    while (current != NULL) {
      if (current == thread) {
        // We found |thread|, remove from list.
        if (previous == NULL) {
          thread_list_head_ = thread->thread_list_next_;
        } else {
          previous->thread_list_next_ = current->thread_list_next_;
        }
        thread->thread_list_next_ = NULL;
        final_thread = !creation_enabled_ && (thread_list_head_ == NULL);
        break;
      }
      previous = current;
      current = current->thread_list_next_;
    }
  }
  // Check if this is the last thread. The last thread does a cleanup
  // which removes the thread local key and the associated mutex.
  if (final_thread) {
    Cleanup();
  }
}

void OSThread::SetCurrentTLS(BaseThread* value) {
  // Provides thread-local destructors.
  SetThreadLocal(thread_key_, reinterpret_cast<uword>(value));

#if defined(HAS_C11_THREAD_LOCAL)
  // Allows the C compiler more freedom to optimize.
  if ((value != NULL) && !value->is_os_thread()) {
    current_vm_thread_ = static_cast<Thread*>(value);
  } else {
    current_vm_thread_ = NULL;
  }
#endif
}

OSThreadIterator::OSThreadIterator() {
  ASSERT(OSThread::thread_list_lock_ != NULL);
  // Lock the thread list while iterating.
  OSThread::thread_list_lock_->Lock();
  next_ = OSThread::thread_list_head_;
}

OSThreadIterator::~OSThreadIterator() {
  ASSERT(OSThread::thread_list_lock_ != NULL);
  // Unlock the thread list when done.
  OSThread::thread_list_lock_->Unlock();
}

bool OSThreadIterator::HasNext() const {
  ASSERT(OSThread::thread_list_lock_ != NULL);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  return next_ != NULL;
}

OSThread* OSThreadIterator::Next() {
  ASSERT(OSThread::thread_list_lock_ != NULL);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  OSThread* current = next_;
  next_ = next_->thread_list_next_;
  return current;
}

}  // namespace dart
