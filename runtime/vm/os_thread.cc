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
OSThread* OSThread::thread_list_head_ = nullptr;
Mutex* OSThread::thread_list_lock_ = nullptr;
bool OSThread::creation_enabled_ = false;

#if defined(SUPPORT_TIMELINE)
inline void UpdateTimelineTrackMetadata(const OSThread& thread) {
  RecorderSynchronizationLockScope ls;
  if (!ls.IsActive()) {
    return;
  }
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder != nullptr) {
    recorder->AddTrackMetadataBasedOnThread(
        OS::ProcessId(), OSThread::ThreadIdToIntPtr(thread.trace_id()),
        thread.name());
  }
}
#endif  // defined(SUPPORT_TIMELINE)

OSThread::OSThread()
    : BaseThread(true),
      id_(OSThread::GetCurrentThreadId()),
#if defined(DEBUG)
      join_id_(kInvalidThreadJoinId),
#endif
#ifdef SUPPORT_TIMELINE
      trace_id_(OSThread::GetCurrentThreadTraceId()),
#endif
      name_(OSThread::GetCurrentThreadName()),
      timeline_block_lock_(),
      timeline_block_(nullptr),
      thread_list_next_(nullptr),
      thread_interrupt_disabled_(1),  // Thread interrupts disabled by default.
      log_(new class Log()),
      stack_base_(0),
      stack_limit_(0),
      stack_headroom_(0),
      thread_(nullptr) {
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

#if defined(SUPPORT_TIMELINE)
  UpdateTimelineTrackMetadata(*this);
#endif  // defined(SUPPORT_TIMELINE)
}

OSThread* OSThread::CreateOSThread() {
  ASSERT(thread_list_lock_ != nullptr);
  MutexLocker ml(thread_list_lock_);
  if (!creation_enabled_) {
    return nullptr;
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
  log_ = nullptr;
#if defined(SUPPORT_TIMELINE)
  if (Timeline::recorder() != nullptr) {
    Timeline::recorder()->FinishBlock(timeline_block_);
  }
#endif
  timeline_block_ = nullptr;
  free(name_);
}

void OSThread::SetName(const char* name) {
  MutexLocker ml(thread_list_lock_);
  // Clear the old thread name.
  if (name_ != nullptr) {
    free(name_);
    name_ = nullptr;
  }
  ASSERT(OSThread::Current() == this);
  ASSERT(name != nullptr);
  name_ = Utils::StrDup(name);

#if defined(SUPPORT_TIMELINE)
  UpdateTimelineTrackMetadata(*this);
#endif  // defined(SUPPORT_TIMELINE)
}

// Disable AddressSanitizer and SafeStack transformation on this function. In
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
  MSAN_UNPOISON(&thread, sizeof(thread));
  delete reinterpret_cast<OSThread*>(thread);
}

void OSThread::Init() {
  // Allocate the global OSThread lock.
  if (thread_list_lock_ == nullptr) {
    thread_list_lock_ = new Mutex();
  }
  ASSERT(thread_list_lock_ != nullptr);

  // Create the thread local key.
  if (thread_key_ == kUnsetThreadLocalKey) {
    thread_key_ = CreateThreadLocal(DeleteThread);
  }
  ASSERT(thread_key_ != kUnsetThreadLocalKey);

  // Enable creation of OSThread structures in the VM.
  EnableOSThreadCreation();

  // Create a new OSThread structure and set it as the TLS.
  OSThread* os_thread = CreateOSThread();
  ASSERT(os_thread != nullptr);
  OSThread::SetCurrent(os_thread);
  os_thread->SetName("Dart_Initialize");
}

void OSThread::Cleanup() {
// We cannot delete the thread local key and thread list lock,  yet.
// See the note on thread_list_lock_ in os_thread.h.
#if 0
  if (thread_list_lock_ != nullptr) {
    // Delete the thread local key.
    ASSERT(thread_key_ != kUnsetThreadLocalKey);
    DeleteThreadLocal(thread_key_);
    thread_key_ = kUnsetThreadLocalKey;

    // Delete the global OSThread lock.
    ASSERT(thread_list_lock_ != nullptr);
    delete thread_list_lock_;
    thread_list_lock_ = nullptr;
  }
#endif
}

OSThread* OSThread::CreateAndSetUnknownThread() {
  ASSERT(OSThread::GetCurrentTLS() == nullptr);
  OSThread* os_thread = CreateOSThread();
  if (os_thread != nullptr) {
    OSThread::SetCurrent(os_thread);
    if (os_thread->name() == nullptr) {
      os_thread->SetName("Unknown");
    }
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
  ASSERT(thread->os_thread() != nullptr);
  return thread->os_thread();
}

void OSThread::AddThreadToListLocked(OSThread* thread) {
  ASSERT(thread != nullptr);
  ASSERT(thread_list_lock_ != nullptr);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  ASSERT(creation_enabled_);
  ASSERT(thread->thread_list_next_ == nullptr);

#if defined(DEBUG)
  {
    // Ensure that we aren't already in the list.
    OSThread* current = thread_list_head_;
    while (current != nullptr) {
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
    ASSERT(thread != nullptr);
    ASSERT(thread_list_lock_ != nullptr);
    MutexLocker ml(thread_list_lock_);
    OSThread* current = thread_list_head_;
    OSThread* previous = nullptr;

    // Scan across list and remove |thread|.
    while (current != nullptr) {
      if (current == thread) {
        // We found |thread|, remove from list.
        if (previous == nullptr) {
          thread_list_head_ = thread->thread_list_next_;
        } else {
          previous->thread_list_next_ = current->thread_list_next_;
        }
        thread->thread_list_next_ = nullptr;
        final_thread = !creation_enabled_ && (thread_list_head_ == nullptr);
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

  // Allows the C compiler more freedom to optimize.
  if ((value != nullptr) && !value->is_os_thread()) {
    current_vm_thread_ = static_cast<Thread*>(value);
  } else {
    current_vm_thread_ = nullptr;
  }
}

OSThreadIterator::OSThreadIterator() {
  ASSERT(OSThread::thread_list_lock_ != nullptr);
  // Lock the thread list while iterating.
  OSThread::thread_list_lock_->Lock();
  next_ = OSThread::thread_list_head_;
}

OSThreadIterator::~OSThreadIterator() {
  ASSERT(OSThread::thread_list_lock_ != nullptr);
  // Unlock the thread list when done.
  OSThread::thread_list_lock_->Unlock();
}

bool OSThreadIterator::HasNext() const {
  ASSERT(OSThread::thread_list_lock_ != nullptr);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  return next_ != nullptr;
}

OSThread* OSThreadIterator::Next() {
  ASSERT(OSThread::thread_list_lock_ != nullptr);
  ASSERT(OSThread::thread_list_lock_->IsOwnedByCurrentThread());
  OSThread* current = next_;
  next_ = next_->thread_list_next_;
  return current;
}

}  // namespace dart
