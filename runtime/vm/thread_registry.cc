// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_registry.h"

#include "vm/isolate.h"
#include "vm/lockers.h"

namespace dart {

ThreadRegistry::~ThreadRegistry() {
  {
    // Each thread that is scheduled in this isolate may have a cached timeline
    // block. Mark these timeline blocks as finished.
    MonitorLocker ml(monitor_);
    TimelineEventRecorder* recorder = Timeline::recorder();
    if (recorder != NULL) {
      MutexLocker recorder_lock(&recorder->lock_);
      for (intptr_t i = 0; i < entries_.length(); i++) {
        // NOTE: It is only safe to access |entry.state| here.
        const Entry& entry = entries_.At(i);
        if (entry.state.timeline_block != NULL) {
          entry.state.timeline_block->Finish();
        }
      }
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
  // TODO(koda): Rename Thread::PrepareForGC and call it here?
  --remaining_;  // Exclude this thread from the count.
  // Ensure the main mutator will reach a safepoint (could be running Dart).
  if (!isolate->MutatorThreadIsCurrentThread()) {
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


void ThreadRegistry::PruneThread(Thread* thread) {
  MonitorLocker ml(monitor_);
  intptr_t length = entries_.length();
  if (length == 0) {
    return;
  }
  intptr_t found_index = -1;
  for (intptr_t index = 0; index < length; index++) {
    if (entries_.At(index).thread == thread) {
      found_index = index;
      break;
    }
  }
  if (found_index < 0) {
    return;
  }
  if (found_index != (length - 1)) {
    // Swap with last entry.
    entries_.Swap(found_index, length - 1);
  }
  entries_.RemoveLast();
}


ThreadRegistry::EntryIterator::EntryIterator(ThreadRegistry* registry)
    : index_(0),
      registry_(NULL) {
  Reset(registry);
}


ThreadRegistry::EntryIterator::~EntryIterator() {
  Reset(NULL);
}


void ThreadRegistry::EntryIterator::Reset(ThreadRegistry* registry) {
  // Reset index.
  index_ = 0;

  // Unlock old registry.
  if (registry_ != NULL) {
    registry_->monitor_->Exit();
  }

  registry_ = registry;

  // Lock new registry.
  if (registry_ != NULL) {
    registry_->monitor_->Enter();
  }
}


bool ThreadRegistry::EntryIterator::HasNext() const {
  if (registry_ == NULL) {
    return false;
  }
  return index_ < registry_->entries_.length();
}


const ThreadRegistry::Entry& ThreadRegistry::EntryIterator::Next() {
  ASSERT(HasNext());
  return registry_->entries_.At(index_++);
}


void ThreadRegistry::CheckSafepointLocked() {
  int64_t last_round = -1;
  while (in_rendezvous_) {
    ASSERT(round_ >= last_round);
    if (round_ != last_round) {
      ASSERT((last_round == -1) || (round_ == (last_round + 1)));
      last_round = round_;
      // Participate in this round.
      // TODO(koda): Rename Thread::PrepareForGC and call it here?
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
  for (int i = 0; i < entries_.length(); ++i) {
    const Entry& entry = entries_[i];
    if (entry.scheduled) {
      ++count;
    }
  }
  return count;
}

}  // namespace dart
