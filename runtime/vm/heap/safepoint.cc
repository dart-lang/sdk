// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/safepoint.h"

#include "vm/heap/heap.h"
#include "vm/thread.h"
#include "vm/thread_registry.h"

namespace dart {

DEFINE_FLAG(bool, trace_safepoint, false, "Trace Safepoint logic.");

SafepointOperationScope::SafepointOperationScope(Thread* T)
    : ThreadStackResource(T) {
  ASSERT(T != nullptr && T->isolate_group() != nullptr);

  SafepointHandler* handler = T->isolate_group()->safepoint_handler();
  ASSERT(handler != NULL);

  // Signal all threads to get to a safepoint and wait for them to
  // get to a safepoint.
  handler->SafepointThreads(T);
}

SafepointOperationScope::~SafepointOperationScope() {
  Thread* T = thread();
  ASSERT(T != nullptr && T->isolate_group() != nullptr);

  // Resume all threads which are blocked for the safepoint operation.
  SafepointHandler* handler = T->isolate_group()->safepoint_handler();
  ASSERT(handler != NULL);
  handler->ResumeThreads(T);
}

ForceGrowthSafepointOperationScope::ForceGrowthSafepointOperationScope(
    Thread* T)
    : ThreadStackResource(T) {
  ASSERT(T != NULL);
  IsolateGroup* IG = T->isolate_group();
  ASSERT(IG != NULL);

  SafepointHandler* handler = IG->safepoint_handler();
  ASSERT(handler != NULL);

  // Signal all threads to get to a safepoint and wait for them to
  // get to a safepoint.
  handler->SafepointThreads(T);

  // N.B.: Change growth policy inside the safepoint to prevent racy access.
  Heap* heap = IG->heap();
  current_growth_controller_state_ = heap->GrowthControlState();
  heap->DisableGrowthControl();
}

ForceGrowthSafepointOperationScope::~ForceGrowthSafepointOperationScope() {
  Thread* T = thread();
  ASSERT(T != NULL);
  IsolateGroup* IG = T->isolate_group();
  ASSERT(IG != NULL);

  // N.B.: Change growth policy inside the safepoint to prevent racy access.
  Heap* heap = IG->heap();
  heap->SetGrowthControlState(current_growth_controller_state_);

  // Resume all threads which are blocked for the safepoint operation.
  SafepointHandler* handler = IG->safepoint_handler();
  ASSERT(handler != NULL);
  handler->ResumeThreads(T);

  if (current_growth_controller_state_) {
    ASSERT(T->CanCollectGarbage());
    // Check if we passed the growth limit during the scope.
    if (heap->old_space()->ReachedHardThreshold()) {
      heap->CollectGarbage(Heap::kMarkSweep, Heap::kOldSpace);
    } else {
      heap->CheckStartConcurrentMarking(T, Heap::kOldSpace);
    }
  }
}

SafepointHandler::SafepointHandler(IsolateGroup* isolate_group)
    : isolate_group_(isolate_group),
      safepoint_lock_(),
      number_threads_not_at_safepoint_(0),
      safepoint_operation_count_(0),
      owner_(NULL) {}

SafepointHandler::~SafepointHandler() {
  ASSERT(owner_ == NULL);
  ASSERT(safepoint_operation_count_ == 0);
  isolate_group_ = NULL;
}

void SafepointHandler::SafepointThreads(Thread* T) {
  ASSERT(T->no_safepoint_scope_depth() == 0);
  ASSERT(T->execution_state() == Thread::kThreadInVM);

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
    Thread* current = isolate_group()->thread_registry()->active_list();
    while (current != NULL) {
      MonitorLocker tl(current->thread_lock());
      if (!current->BypassSafepoints()) {
        if (current == T) {
          current->SetAtSafepoint(true);
        } else {
          uint32_t state = current->SetSafepointRequested(true);
          if (!Thread::IsAtSafepoint(state)) {
            // Thread is not already at a safepoint so try to
            // get it to a safepoint and wait for it to check in.
            if (current->IsMutatorThread()) {
              current->ScheduleInterruptsLocked(Thread::kVMInterrupt);
            }
            MonitorLocker sl(&safepoint_lock_);
            ++number_threads_not_at_safepoint_;
          }
        }
      }
      current = current->next();
    }
  }
  // Now wait for all threads that are not already at a safepoint to check-in.
  {
    MonitorLocker sl(&safepoint_lock_);
    intptr_t num_attempts = 0;
    while (number_threads_not_at_safepoint_ > 0) {
      Monitor::WaitResult retval = sl.Wait(1000);
      if (retval == Monitor::kTimedOut) {
        num_attempts += 1;
        if (FLAG_trace_safepoint && num_attempts > 10) {
          // We have been waiting too long, start logging this as we might
          // have an issue where a thread is not checking in for a safepoint.
          for (Thread* current =
                   isolate_group()->thread_registry()->active_list();
               current != NULL; current = current->next()) {
            if (!current->IsAtSafepoint()) {
              OS::PrintErr("Attempt:%" Pd
                           " waiting for thread %s to check in\n",
                           num_attempts, current->os_thread()->name());
            }
          }
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
  Thread* current = isolate_group()->thread_registry()->active_list();
  while (current != NULL) {
    MonitorLocker tl(current->thread_lock());
    if (!current->BypassSafepoints()) {
      if (current == T) {
        current->SetAtSafepoint(false);
      } else {
        uint32_t state = current->SetSafepointRequested(false);
        if (Thread::IsBlockedForSafepoint(state)) {
          tl.Notify();
        }
      }
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
    MonitorLocker sl(&safepoint_lock_);
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
  ASSERT(!T->BypassSafepoints());
  MonitorLocker tl(T->thread_lock());
  if (T->IsSafepointRequested()) {
    T->SetAtSafepoint(true);
    {
      MonitorLocker sl(&safepoint_lock_);
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
