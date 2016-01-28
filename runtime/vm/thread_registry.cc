// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_registry.h"

#include "vm/isolate.h"
#include "vm/lockers.h"

namespace dart {

ThreadRegistry::~ThreadRegistry() {
  // Go over the free thread list and delete the thread objects.
  {
    MonitorLocker ml(monitor_);
    // At this point the active list should be empty.
    ASSERT(active_list_ == NULL);
    // We have cached the mutator thread, delete it.
    delete mutator_thread_;
    mutator_thread_ = NULL;
    // Now delete all the threads in the free list.
    while (free_list_ != NULL) {
      Thread* thread = free_list_;
      free_list_ = thread->next_;
      delete thread;
    }
  }

  // Delete monitor.
  delete monitor_;
}


void ThreadRegistry::SafepointThreads() {
  MonitorLocker ml(monitor_);
  // First wait for any older rounds that are still in progress.
  while (in_rendezvous_) {
    // Assert we are not the organizer trying to nest calls to SafepointThreads.
    ASSERT(remaining_ > 0);
    CheckSafepointLocked();
  }
  // Start a new round.
  in_rendezvous_ = true;
  ++round_;  // Overflows after 240+ years @ 10^9 safepoints per second.
  remaining_ = CountScheduledLocked();
  Isolate* isolate = Isolate::Current();
  // We only expect this method to be called from within the isolate itself.
  ASSERT(isolate->thread_registry() == this);
  --remaining_;  // Exclude this thread from the count.
  // Ensure the main mutator will reach a safepoint (could be running Dart).
  if (!Thread::Current()->IsMutatorThread()) {
    isolate->ScheduleInterrupts(Isolate::kVMInterrupt);
  }
  while (remaining_ > 0) {
    ml.Wait(Monitor::kNoTimeout);
  }
}


void ThreadRegistry::ResumeAllThreads() {
  MonitorLocker ml(monitor_);
  ASSERT(in_rendezvous_);
  in_rendezvous_ = false;
  ml.NotifyAll();
}


Thread* ThreadRegistry::Schedule(Isolate* isolate,
                                 bool is_mutator,
                                 bool bypass_safepoint) {
  MonitorLocker ml(monitor_);
  // Wait for any rendezvous in progress.
  while (!bypass_safepoint && in_rendezvous_) {
    ml.Wait(Monitor::kNoTimeout);
  }
  Thread* thread = NULL;
  OSThread* os_thread = OSThread::Current();
  if (os_thread != NULL) {
    ASSERT(isolate->heap() != NULL);
    // First get a Thread structure. (we special case the mutator thread
    // by reusing the cached structure, see comment in 'thread_registry.h').
    if (is_mutator) {
      if (mutator_thread_ == NULL) {
        mutator_thread_ = GetThreadFromFreelist(isolate);
      }
      thread = mutator_thread_;
    } else {
      thread = GetThreadFromFreelist(isolate);
      ASSERT(thread->api_top_scope() == NULL);
    }
    // Now add this Thread to the active list for the isolate.
    AddThreadToActiveList(thread);
    // Set up other values and set the TLS value.
    thread->isolate_ = isolate;
    thread->heap_ = isolate->heap();
    thread->set_os_thread(os_thread);
    os_thread->set_thread(thread);
    Thread::SetCurrent(thread);
    os_thread->EnableThreadInterrupts();
  }
  return thread;
}


void ThreadRegistry::Unschedule(Thread* thread,
                                bool is_mutator,
                                bool bypass_safepoint) {
  MonitorLocker ml(monitor_);
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  os_thread->DisableThreadInterrupts();
  os_thread->set_thread(NULL);
  OSThread::SetCurrent(os_thread);
  thread->isolate_ = NULL;
  thread->heap_ = NULL;
  thread->set_os_thread(NULL);
  // Remove thread from the active list for the isolate.
  RemoveThreadFromActiveList(thread);
  // Return thread to the free list (we special case the mutator
  // thread by holding on to it, see comment in 'thread_registry.h').
  if (!is_mutator) {
    ASSERT(thread->api_top_scope() == NULL);
    ReturnThreadToFreelist(thread);
  }
  if (!bypass_safepoint && in_rendezvous_) {
    // Don't wait for this thread.
    ASSERT(remaining_ > 0);
    if (--remaining_ == 0) {
      ml.NotifyAll();
    }
  }
}


void ThreadRegistry::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                         bool validate_frames) {
  MonitorLocker ml(monitor_);
  Thread* thread = active_list_;
  while (thread != NULL) {
    if (thread->zone() != NULL) {
      thread->zone()->VisitObjectPointers(visitor);
    }
    thread->VisitObjectPointers(visitor);
    // Iterate over all the stack frames and visit objects on the stack.
    StackFrameIterator frames_iterator(thread->top_exit_frame_info(),
                                       validate_frames);
    StackFrame* frame = frames_iterator.NextFrame();
    while (frame != NULL) {
      frame->VisitObjectPointers(visitor);
      frame = frames_iterator.NextFrame();
    }
    thread = thread->next_;
  }
}


void ThreadRegistry::PrepareForGC() {
  MonitorLocker ml(monitor_);
  Thread* thread = active_list_;
  while (thread != NULL) {
    thread->PrepareForGC();
    thread = thread->next_;
  }
}


void ThreadRegistry::AddThreadToActiveList(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(monitor_->IsOwnedByCurrentThread());
  thread->next_ = active_list_;
  active_list_ = thread;
}


void ThreadRegistry::RemoveThreadFromActiveList(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(monitor_->IsOwnedByCurrentThread());
  Thread* prev = NULL;
  Thread* current = active_list_;
  while (current != NULL) {
    if (current == thread) {
      if (prev == NULL) {
        active_list_ = current->next_;
      } else {
        prev->next_ = current->next_;
      }
      break;
    }
    prev = current;
    current = current->next_;
  }
}


Thread* ThreadRegistry::GetThreadFromFreelist(Isolate* isolate) {
  ASSERT(monitor_->IsOwnedByCurrentThread());
  Thread* thread = NULL;
  // Get thread structure from free list or create a new one.
  if (free_list_ == NULL) {
    thread = new Thread(isolate);
  } else {
    thread = free_list_;
    free_list_ = thread->next_;
  }
  return thread;
}

void ThreadRegistry::ReturnThreadToFreelist(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(thread->os_thread_ == NULL);
  ASSERT(thread->isolate_ == NULL);
  ASSERT(thread->heap_ == NULL);
  ASSERT(monitor_->IsOwnedByCurrentThread());
  // Add thread to the free list.
  thread->next_ = free_list_;
  free_list_ = thread;
}


void ThreadRegistry::CheckSafepointLocked() {
  int64_t last_round = -1;
  while (in_rendezvous_) {
    ASSERT(round_ >= last_round);
    if (round_ != last_round) {
      ASSERT((last_round == -1) || (round_ == (last_round + 1)));
      last_round = round_;
      // Participate in this round.
      if (--remaining_ == 0) {
        // Ensure the organizing thread is notified.
        // TODO(koda): Use separate condition variables and plain 'Notify'.
        monitor_->NotifyAll();
      }
    }
    monitor_->Wait(Monitor::kNoTimeout);
    // Note: Here, round_ is needed to detect and distinguish two cases:
    // a) The old rendezvous is still in progress, so just keep waiting, or
    // b) after ResumeAllThreads, another call to SafepointThreads was
    // made before this thread got a chance to reaquire monitor_, thus this
    // thread should (again) decrease remaining_ to indicate cooperation in
    // this new round.
  }
}


intptr_t ThreadRegistry::CountScheduledLocked() {
  intptr_t count = 0;
  Thread* current = active_list_;
  while (current != NULL) {
    ++count;
    current = current->next_;
  }
  return count;
}

}  // namespace dart
