// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/safepoint.h"

#include "vm/thread.h"
#include "vm/thread_registry.h"

namespace dart {

SafepointOperationScope::SafepointOperationScope(Thread* T) : StackResource(T) {
  ASSERT(T != NULL);
  Isolate* I = T->isolate();
  ASSERT(I != NULL);
  ASSERT(T->no_safepoint_scope_depth() == 0);

  SafepointHandler* handler = I->safepoint_handler();
  ASSERT(handler != NULL);

  // Signal all threads to get to a safepoint and wait for them to
  // get to a safepoint.
  handler->SafepointThreads(T);
}

SafepointOperationScope::~SafepointOperationScope() {
  Thread* T = thread();
  ASSERT(T != NULL);
  Isolate* I = T->isolate();
  ASSERT(I != NULL);

  // Resume all threads which are blocked for the safepoint operation.
  SafepointHandler* handler = I->safepoint_handler();
  ASSERT(handler != NULL);
  handler->ResumeThreads(T);
}

SafepointHandler::SafepointHandler(Isolate* isolate)
    : isolate_(isolate),
      safepoint_lock_(new Monitor()),
      number_threads_not_at_safepoint_(0),
      safepoint_operation_count_(0),
      owner_(NULL) {}

SafepointHandler::~SafepointHandler() {
  ASSERT(owner_ == NULL);
  ASSERT(safepoint_operation_count_ == 0);
  delete safepoint_lock_;
  safepoint_lock_ = NULL;
  isolate_ = NULL;
}

void SafepointHandler::SafepointThreads(Thread* T) {
  {
    // First grab the threads list lock for this isolate
    // and check if a safepoint is already in progress. This
    // ensures that two threads do not start a safepoint operation
    // at the same time.
    MonitorLocker sl(threads_lock());

    // Now check to see if a safepoint operation is already in progress
    // for this isolate, block if an operation is in progress.
    while (SafepointInProgress()) {
      // If we are recursively invoking a Safepoint operation then we
      // just increment the count and return, otherwise we wait for the
      // safepoint operation to be done.
      if (owner_ == T) {
        increment_safepoint_operation_count();
        return;
      }
      sl.WaitWithSafepointCheck(T);
    }

    // Set safepoint in progress state by this thread.
    SetSafepointInProgress(T);

    // Go over the active thread list and ensure that all threads active
    // in the isolate reach a safepoint.
    Thread* current = isolate()->thread_registry()->active_list();
    while (current != NULL) {
      MonitorLocker tl(current->thread_lock());
      if (current != T) {
        uint32_t state = current->SetSafepointRequested(true);
        if (!Thread::IsAtSafepoint(state)) {
          // Thread is not already at a safepoint so try to
          // get it to a safepoint and wait for it to check in.
          if (current->IsMutatorThread()) {
            ASSERT(T->isolate() != NULL);
            current->ScheduleInterruptsLocked(Thread::kVMInterrupt);
          }
          MonitorLocker sl(safepoint_lock_);
          ++number_threads_not_at_safepoint_;
        }
      } else {
        current->SetAtSafepoint(true);
      }
      current = current->next();
    }
  }
  // Now wait for all threads that are not already at a safepoint to check-in.
  {
    MonitorLocker sl(safepoint_lock_);
    intptr_t num_attempts = 0;
    while (number_threads_not_at_safepoint_ > 0) {
      Monitor::WaitResult retval = sl.Wait(1000);
      if (retval == Monitor::kTimedOut) {
        num_attempts += 1;
        if (num_attempts > 10) {
          // We have been waiting too long, start logging this as we might
          // have an issue where a thread is not checking in for a safepoint.
          OS::Print("Attempt:%" Pd " waiting for %d threads to check in\n",
                    num_attempts, number_threads_not_at_safepoint_);
        }
      }
    }
  }
}

void SafepointHandler::ResumeThreads(Thread* T) {
  // First resume all the threads which are blocked for the safepoint
  // operation.
  MonitorLocker sl(threads_lock());

  // First check if we are in a recursive safepoint operation, in that case
  // we just decrement safepoint_operation_count and return.
  ASSERT(SafepointInProgress());
  if (safepoint_operation_count() > 1) {
    decrement_safepoint_operation_count();
    return;
  }
  Thread* current = isolate()->thread_registry()->active_list();
  while (current != NULL) {
    MonitorLocker tl(current->thread_lock());
    if (current != T) {
      uint32_t state = current->SetSafepointRequested(false);
      if (Thread::IsBlockedForSafepoint(state)) {
        tl.Notify();
      }
    } else {
      current->SetAtSafepoint(false);
    }
    current = current->next();
  }
  // Now reset the safepoint_in_progress_ state and notify all threads
  // that are waiting to enter the isolate or waiting to start another
  // safepoint operation.
  ResetSafepointInProgress(T);
  sl.NotifyAll();
}

void SafepointHandler::EnterSafepointUsingLock(Thread* T) {
  MonitorLocker tl(T->thread_lock());
  T->SetAtSafepoint(true);
  if (T->IsSafepointRequested()) {
    MonitorLocker sl(safepoint_lock_);
    ASSERT(number_threads_not_at_safepoint_ > 0);
    number_threads_not_at_safepoint_ -= 1;
    sl.Notify();
  }
}

void SafepointHandler::ExitSafepointUsingLock(Thread* T) {
  MonitorLocker tl(T->thread_lock());
  ASSERT(T->IsAtSafepoint());
  while (T->IsSafepointRequested()) {
    T->SetBlockedForSafepoint(true);
    tl.Wait();
    T->SetBlockedForSafepoint(false);
  }
  T->SetAtSafepoint(false);
}

void SafepointHandler::BlockForSafepoint(Thread* T) {
  MonitorLocker tl(T->thread_lock());
  if (T->IsSafepointRequested()) {
    T->SetAtSafepoint(true);
    {
      MonitorLocker sl(safepoint_lock_);
      ASSERT(number_threads_not_at_safepoint_ > 0);
      number_threads_not_at_safepoint_ -= 1;
      sl.Notify();
    }
    while (T->IsSafepointRequested()) {
      T->SetBlockedForSafepoint(true);
      tl.Wait();
      T->SetBlockedForSafepoint(false);
    }
    T->SetAtSafepoint(false);
  }
}

}  // namespace dart
