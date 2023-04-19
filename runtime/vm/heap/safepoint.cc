// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/safepoint.h"

#include "vm/heap/heap.h"
#include "vm/thread.h"
#include "vm/thread_registry.h"

namespace dart {

DEFINE_FLAG(bool, trace_safepoint, false, "Trace Safepoint logic.");

SafepointOperationScope::SafepointOperationScope(Thread* T,
                                                 SafepointLevel level)
    : ThreadStackResource(T), level_(level) {
  ASSERT(T != nullptr && T->isolate_group() != nullptr);

  auto handler = T->isolate_group()->safepoint_handler();
  handler->SafepointThreads(T, level_);
}

SafepointOperationScope::~SafepointOperationScope() {
  Thread* T = thread();
  ASSERT(T != nullptr && T->isolate_group() != nullptr);

  auto handler = T->isolate_group()->safepoint_handler();
  handler->ResumeThreads(T, level_);
}

ForceGrowthSafepointOperationScope::ForceGrowthSafepointOperationScope(
    Thread* T,
    SafepointLevel level)
    : ThreadStackResource(T), level_(level) {
  ASSERT(T != nullptr);
  IsolateGroup* IG = T->isolate_group();
  ASSERT(IG != nullptr);

  T->IncrementForceGrowthScopeDepth();

  auto handler = IG->safepoint_handler();
  handler->SafepointThreads(T, level_);
}

ForceGrowthSafepointOperationScope::~ForceGrowthSafepointOperationScope() {
  Thread* T = thread();
  ASSERT(T != nullptr);
  IsolateGroup* IG = T->isolate_group();
  ASSERT(IG != nullptr);

  auto handler = IG->safepoint_handler();
  handler->ResumeThreads(T, level_);

  T->DecrementForceGrowthScopeDepth();
  if (!T->force_growth()) {
    // Check if we passed the growth limit during the scope.
    T->heap()->CheckCatchUp(T);
  }
}

SafepointHandler::SafepointHandler(IsolateGroup* isolate_group)
    : isolate_group_(isolate_group) {
  handlers_[SafepointLevel::kGC] =
      new LevelHandler(isolate_group, SafepointLevel::kGC);
  handlers_[SafepointLevel::kGCAndDeopt] =
      new LevelHandler(isolate_group, SafepointLevel::kGCAndDeopt);
}

SafepointHandler::~SafepointHandler() {
  for (intptr_t level = 0; level < SafepointLevel::kNumLevels; ++level) {
    ASSERT(handlers_[level]->owner_ == nullptr);
    delete handlers_[level];
  }
}

void SafepointHandler::SafepointThreads(Thread* T, SafepointLevel level) {
  ASSERT(T->no_safepoint_scope_depth() == 0);
  ASSERT(T->execution_state() == Thread::kThreadInVM);
  ASSERT(T->current_safepoint_level() >= level);

  {
    MonitorLocker tl(threads_lock());

    // Allow recursive deopt safepoint operation.
    if (handlers_[level]->owner_ == T) {
      // If we own this safepoint level already we have to own the lower levels
      // as well.
      AssertWeOwnLowerLevelSafepoints(T, level);

      for (intptr_t i = 0; i <= level; ++i) {
        handlers_[i]->operation_count_++;
      }
      return;
    }

    // This level of nesting is not allowed (this thread cannot own lower levels
    // and then later try acquire higher levels).
    AssertWeDoNotOwnLowerLevelSafepoints(T, level);

    // Mark this thread at safepoint and possibly notify waiting threads.
    {
      MonitorLocker tl(T->thread_lock());
      // We only enter [level] here. That means a higher level that is waiting
      // for us to check-in will not consider us as not parked. This is required
      // since we are not actually parked (we can finish running this method and
      // then caller continues).
      EnterSafepointLocked(T, &tl, level);
    }

    // Wait until other safepoint operations are done & mark us as owning
    // the safepoint - so no other thread can.
    while (handlers_[level]->SafepointInProgress()) {
      tl.Wait();
    }
    handlers_[level]->SetSafepointInProgress(T);

    // Ensure a thread is at a safepoint or notify it to get to one.
    handlers_[level]->NotifyThreadsToGetToSafepointLevel(T);
  }

  // Now wait for all threads that are not already at a safepoint to check-in.
  handlers_[level]->WaitUntilThreadsReachedSafepointLevel();

  // No other mutator is running at this point. We'll set ourselves as owners of
  // all the lower levels as well - since higher levels provide even more
  // guarantees that lower levels (e.g. others being stopped at places where
  // one can deopt also implies one can gc)
  AcquireLowerLevelSafepoints(T, level);
}

void SafepointHandler::AssertWeOwnLowerLevelSafepoints(Thread* T,
                                                       SafepointLevel level) {
  for (intptr_t lower_level = level - 1; lower_level >= 0; --lower_level) {
    RELEASE_ASSERT(handlers_[lower_level]->owner_ == T);
  }
}

void SafepointHandler::AssertWeDoNotOwnLowerLevelSafepoints(
    Thread* T,
    SafepointLevel level) {
  for (intptr_t lower_level = level - 1; lower_level >= 0; --lower_level) {
    RELEASE_ASSERT(handlers_[lower_level]->owner_ != T);
  }
}

void SafepointHandler::LevelHandler::NotifyThreadsToGetToSafepointLevel(
    Thread* T) {
  ASSERT(num_threads_not_parked_ == 0);
  for (auto current = isolate_group()->thread_registry()->active_list();
       current != nullptr; current = current->next()) {
    MonitorLocker tl(current->thread_lock());
    if (!current->BypassSafepoints() && current != T) {
      const uint32_t state = current->SetSafepointRequested(level_, true);
      if (!Thread::IsAtSafepoint(level_, state)) {
        // Send OOB message to get it to safepoint.
        if (current->IsMutatorThread()) {
          current->ScheduleInterrupts(Thread::kVMInterrupt);
        }
        MonitorLocker sl(&parked_lock_);
        num_threads_not_parked_++;
      }
    }
  }
}

void SafepointHandler::ResumeThreads(Thread* T, SafepointLevel level) {
  {
    MonitorLocker sl(threads_lock());

    ASSERT(handlers_[level]->SafepointInProgress());
    ASSERT(handlers_[level]->owner_ == T);
    AssertWeOwnLowerLevelSafepoints(T, level);

    // We allow recursive safepoints.
    if (handlers_[level]->operation_count_ > 1) {
      for (intptr_t i = 0; i <= level; ++i) {
        handlers_[i]->operation_count_--;
      }
      return;
    }

    ReleaseLowerLevelSafepoints(T, level);
    handlers_[level]->ResetSafepointInProgress(T);
    handlers_[level]->NotifyThreadsToContinue(T);
    sl.NotifyAll();
  }
  {
    MonitorLocker tl(T->thread_lock());
    // We only enter [level] here. That means a higher level that is waiting
    // for us to check-in will not consider us as not parked. This is required
    // since we are not actually parked (we can finish running this method and
    // then caller continues).
    ExitSafepointLocked(T, &tl, level);
  }
}

void SafepointHandler::LevelHandler::WaitUntilThreadsReachedSafepointLevel() {
  MonitorLocker sl(&parked_lock_);
  intptr_t num_attempts = 0;
  while (num_threads_not_parked_ > 0) {
    Monitor::WaitResult retval = sl.Wait(1000);
    if (retval == Monitor::kTimedOut) {
      num_attempts += 1;
      if (FLAG_trace_safepoint && num_attempts > 10) {
        for (auto current = isolate_group()->thread_registry()->active_list();
             current != nullptr; current = current->next()) {
          if (!current->IsAtSafepoint(level_)) {
            OS::PrintErr("Attempt:%" Pd " waiting for thread %s to check in\n",
                         num_attempts, current->os_thread()->name());
          }
        }
      }
    }
  }
}

void SafepointHandler::AcquireLowerLevelSafepoints(Thread* T,
                                                   SafepointLevel level) {
  MonitorLocker tl(threads_lock());
  ASSERT(handlers_[level]->owner_ == T);
  for (intptr_t lower_level = level - 1; lower_level >= 0; --lower_level) {
    ASSERT(!handlers_[lower_level]->SafepointInProgress());
    handlers_[lower_level]->SetSafepointInProgress(T);
    ASSERT(handlers_[lower_level]->owner_ == T);
  }
}

void SafepointHandler::ReleaseLowerLevelSafepoints(Thread* T,
                                                   SafepointLevel level) {
  for (intptr_t lower_level = 0; lower_level < level; ++lower_level) {
    handlers_[lower_level]->ResetSafepointInProgress(T);
  }
}

void SafepointHandler::LevelHandler::NotifyThreadsToContinue(Thread* T) {
  for (auto current = isolate_group()->thread_registry()->active_list();
       current != nullptr; current = current->next()) {
    MonitorLocker tl(current->thread_lock());
    if (!current->BypassSafepoints() && current != T) {
      bool resume = false;
      for (intptr_t lower_level = level_; lower_level >= 0; --lower_level) {
        if (Thread::IsBlockedForSafepoint(current->SetSafepointRequested(
                static_cast<SafepointLevel>(lower_level), false))) {
          resume = true;
        }
      }
      if (resume) {
        tl.Notify();
      }
    }
  }
}

void SafepointHandler::EnterSafepointUsingLock(Thread* T) {
  MonitorLocker tl(T->thread_lock());
  EnterSafepointLocked(T, &tl, T->current_safepoint_level());
}

void SafepointHandler::ExitSafepointUsingLock(Thread* T) {
  MonitorLocker tl(T->thread_lock());
  ASSERT(T->IsAtSafepoint());
  ExitSafepointLocked(T, &tl, T->current_safepoint_level());
  ASSERT(!T->IsSafepointRequestedLocked(T->current_safepoint_level()));
}

void SafepointHandler::BlockForSafepoint(Thread* T) {
  ASSERT(!T->BypassSafepoints());
  MonitorLocker tl(T->thread_lock());
  // This takes into account the safepoint level the thread can participate in.
  const SafepointLevel level = T->current_safepoint_level();
  if (T->IsSafepointRequestedLocked(level)) {
    EnterSafepointLocked(T, &tl, level);
    ExitSafepointLocked(T, &tl, level);
    ASSERT(!T->IsSafepointRequestedLocked(level));
  }
}

void SafepointHandler::EnterSafepointLocked(Thread* T,
                                            MonitorLocker* tl,
                                            SafepointLevel level) {
  T->SetAtSafepoint(true, level);
  // Several safepointing operations (at different) levels may happen at same
  // time. Ensure we notify all of them that we are parked now.
  for (intptr_t i = 0; i <= level; ++i) {
    if (T->IsSafepointLevelRequestedLocked(static_cast<SafepointLevel>(i))) {
      handlers_[i]->NotifyWeAreParked(T);
    }
  }
}

void SafepointHandler::LevelHandler::NotifyWeAreParked(Thread* T) {
  ASSERT(owner_ != nullptr);
  MonitorLocker sl(&parked_lock_);
  ASSERT(num_threads_not_parked_ > 0);
  num_threads_not_parked_ -= 1;
  if (num_threads_not_parked_ == 0) {
    sl.Notify();
  }
}

void SafepointHandler::ExitSafepointLocked(Thread* T,
                                           MonitorLocker* tl,
                                           SafepointLevel level) {
  while (T->IsSafepointRequestedLocked(level)) {
    T->SetBlockedForSafepoint(true);
    tl->Wait();
    T->SetBlockedForSafepoint(false);
  }
  T->SetAtSafepoint(false, level);
}

}  // namespace dart
