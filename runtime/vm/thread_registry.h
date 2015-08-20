// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_REGISTRY_H_
#define VM_THREAD_REGISTRY_H_

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"

namespace dart {

// Unordered collection of threads relating to a particular isolate.
class ThreadRegistry {
 public:
  ThreadRegistry()
      : monitor_(new Monitor()),
        entries_(),
        in_rendezvous_(false),
        remaining_(0),
        round_(0) {}

  ~ThreadRegistry();

  // Bring all threads in this isolate to a safepoint. The caller is
  // expected to be implicitly at a safepoint. The threads will wait
  // until ResumeAllThreads is called. First participates in any
  // already pending rendezvous requested by another thread. Any
  // thread that tries to enter this isolate during rendezvous will
  // wait in RestoreStateTo. Nesting is not supported: the caller must
  // call ResumeAllThreads before making further calls to
  // SafepointThreads.
  void SafepointThreads();

  // Unblocks all threads participating in the rendezvous that was organized
  // by a prior call to SafepointThreads.
  // TODO(koda): Consider adding a scope helper to avoid omitting this call.
  void ResumeAllThreads();

  // Indicate that the current thread is at a safepoint, and offer to wait for
  // any pending rendezvous request (if none, returns immediately).
  void CheckSafepoint() {
    MonitorLocker ml(monitor_);
    CheckSafepointLocked();
  }

  bool RestoreStateTo(Thread* thread, Thread::State* state) {
    MonitorLocker ml(monitor_);
    // Wait for any rendezvous in progress.
    while (in_rendezvous_) {
      ml.Wait(Monitor::kNoTimeout);
    }
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
    MonitorLocker ml(monitor_);
    Entry* entry = FindEntry(thread);
    ASSERT(entry != NULL);
    ASSERT(entry->scheduled);
    entry->scheduled = false;
    entry->state = state;
    if (in_rendezvous_) {
      // Don't wait for this thread.
      ASSERT(remaining_ > 0);
      if (--remaining_ == 0) {
        ml.NotifyAll();
      }
    }
  }

  bool Contains(Thread* thread) {
    MonitorLocker ml(monitor_);
    return (FindEntry(thread) != NULL);
  }

  void CheckNotScheduled(Isolate* isolate) {
    MonitorLocker ml(monitor_);
    for (int i = 0; i < entries_.length(); ++i) {
      const Entry& entry = entries_[i];
      if (entry.scheduled) {
        FATAL3("Isolate %p still scheduled on %p (whose isolate_ is %p)\n",
               isolate,
               entry.thread,
               entry.thread->isolate());
      }
    }
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           bool validate_frames) {
    MonitorLocker ml(monitor_);
    for (int i = 0; i < entries_.length(); ++i) {
      const Entry& entry = entries_[i];
      const Thread::State& state =
          entry.scheduled ? entry.thread->state_ : entry.state;
      if (state.zone != NULL) {
        state.zone->VisitObjectPointers(visitor);
      }
      // Iterate over all the stack frames and visit objects on the stack.
      StackFrameIterator frames_iterator(state.top_exit_frame_info,
                                         validate_frames);
      StackFrame* frame = frames_iterator.NextFrame();
      while (frame != NULL) {
        frame->VisitObjectPointers(visitor);
        frame = frames_iterator.NextFrame();
      }
    }
  }

  void PruneThread(Thread* thread);

  struct Entry {
    // NOTE: |thread| is deleted automatically when the thread exits.
    // In other words, it is not safe to dereference |thread| unless you are on
    // the thread itself.
    Thread* thread;
    bool scheduled;
    Thread::State state;
  };

  class EntryIterator {
   public:
    explicit EntryIterator(ThreadRegistry* registry);
    ~EntryIterator();

    // Returns false when there are no more entries.
    bool HasNext() const;

    // Returns the next entry and moves forward.
    const Entry& Next();

   private:
    void Reset(ThreadRegistry* registry);

    intptr_t index_;
    ThreadRegistry* registry_;
  };

 private:
  // Returns Entry corresponding to thread in registry or NULL.
  // Note: Lock should be taken before this function is called.
  // TODO(koda): Add method Monitor::IsOwnedByCurrentThread.
  Entry* FindEntry(Thread* thread) {
    for (int i = 0; i < entries_.length(); ++i) {
      if (entries_[i].thread == thread) {
        return &entries_[i];
      }
    }
    return NULL;
  }

  // Note: Lock should be taken before this function is called.
  void CheckSafepointLocked();

  // Returns the number threads that are scheduled on this isolate.
  // Note: Lock should be taken before this function is called.
  intptr_t CountScheduledLocked();

  Monitor* monitor_;  // All access is synchronized through this monitor.
  MallocGrowableArray<Entry> entries_;

  // Safepoint rendezvous state.
  bool in_rendezvous_;    // A safepoint rendezvous request is in progress.
  intptr_t remaining_;    // Number of threads yet to reach their safepoint.
  int64_t round_;         // Counter, to prevent missing updates to remaining_
                          // (see comments in CheckSafepointLocked).

  DISALLOW_COPY_AND_ASSIGN(ThreadRegistry);
};

}  // namespace dart

#endif  // VM_THREAD_REGISTRY_H_
