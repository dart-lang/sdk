// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_REGISTRY_H_
#define VM_THREAD_REGISTRY_H_

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread.h"

namespace dart {

// Unordered collection of threads relating to a particular isolate.
class ThreadRegistry {
 public:
  ThreadRegistry() : mutex_(new Mutex()), entries_() {}

  bool RestoreStateTo(Thread* thread, Thread::State* state) {
    MutexLocker ml(mutex_);
    Entry* entry = FindEntry(thread);
    if (entry != NULL) {
      Thread::State st = entry->state;
      // TODO(koda): Support same thread re-entering same isolate with
      // Dart frames in between. For now, just assert it doesn't happen.
      if (st.top_exit_frame_info != thread->top_exit_frame_info()) {
        ASSERT(thread->top_exit_frame_info() == 0 ||
               thread->top_exit_frame_info() > st.top_exit_frame_info);
      }
      ASSERT(!entry->scheduled);
      entry->scheduled = true;
#if defined(DEBUG)
      // State field is not in use, so zap it.
      memset(&entry->state, 0xda, sizeof(entry->state));
#endif
      *state = st;
      return true;
    }
    Entry new_entry;
    new_entry.thread = thread;
    new_entry.scheduled = true;
#if defined(DEBUG)
    // State field is not in use, so zap it.
    memset(&new_entry.state, 0xda, sizeof(new_entry.state));
#endif
    entries_.Add(new_entry);
    return false;
  }

  void SaveStateFrom(Thread* thread, const Thread::State& state) {
    MutexLocker ml(mutex_);
    Entry* entry = FindEntry(thread);
    ASSERT(entry != NULL);
    ASSERT(entry->scheduled);
    entry->scheduled = false;
    entry->state = state;
  }

  bool Contains(Thread* thread) {
    MutexLocker ml(mutex_);
    return (FindEntry(thread) != NULL);
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    MutexLocker ml(mutex_);
    for (int i = 0; i < entries_.length(); ++i) {
      const Entry& entry = entries_[i];
      Zone* zone = entry.scheduled ? entry.thread->zone() : entry.state.zone;
      if (zone != NULL) {
        zone->VisitObjectPointers(visitor);
      }
    }
  }

 private:
  struct Entry {
    Thread* thread;
    bool scheduled;
    Thread::State state;
  };

  // Returns Entry corresponding to thread in registry or NULL.
  // Note: Lock should be taken before this function is called.
  Entry* FindEntry(Thread* thread) {
    DEBUG_ASSERT(mutex_->IsOwnedByCurrentThread());
    for (int i = 0; i < entries_.length(); ++i) {
      if (entries_[i].thread == thread) {
        return &entries_[i];
      }
    }
    return NULL;
  }

  Mutex* mutex_;
  MallocGrowableArray<Entry> entries_;


  DISALLOW_COPY_AND_ASSIGN(ThreadRegistry);
};

}  // namespace dart

#endif  // VM_THREAD_REGISTRY_H_
