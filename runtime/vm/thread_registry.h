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
        active_list_(NULL),
        free_list_(NULL),
        mutator_thread_(NULL),
        in_rendezvous_(false),
        remaining_(0),
        round_(0) {}

  ~ThreadRegistry();

  Thread* active_list() const { return active_list_; }

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

  bool AtSafepoint() const { return in_rendezvous_; }
  Thread* Schedule(Isolate* isolate, bool is_mutator, bool bypass_safepoint);
  void Unschedule(Thread* thread, bool is_mutator, bool bypass_safepoint);
  void VisitObjectPointers(ObjectPointerVisitor* visitor, bool validate_frames);
  void PrepareForGC();

 private:
  void AddThreadToActiveList(Thread* thread);
  void RemoveThreadFromActiveList(Thread* thread);
  Thread* GetThreadFromFreelist(Isolate* isolate);
  void ReturnThreadToFreelist(Thread* thread);

  // Note: Lock should be taken before this function is called.
  void CheckSafepointLocked();

  // Returns the number threads that are scheduled on this isolate.
  // Note: Lock should be taken before this function is called.
  intptr_t CountScheduledLocked();

  Monitor* monitor_;  // All access is synchronized through this monitor.
  Thread* active_list_;  // List of active threads in the isolate.
  Thread* free_list_;  // Free list of Thread objects that can be reused.
  // TODO(asiva): Currently we treat a mutator thread as a special thread
  // and always schedule execution of Dart code on the same mutator thread
  // object. The ApiLocalScope has been made thread specific but we still
  // have scenarios where we do a temporary exit of an Isolate with live
  // zones/handles in the the API scope :
  // - Dart_RunLoop()
  // - IsolateSaver in Dart_NewNativePort
  // - Isolate spawn (function/uri) under FLAG_i_like_slow_isolate_spawn
  // We probably need a mechanism to return to the specific thread only
  // for these specific cases. We should also determine if the embedder
  // should allow exiting an isolate with live state in zones/handles in
  // which case a new API for returning to the specific thread needs to be
  // added.
  Thread* mutator_thread_;

  // Safepoint rendezvous state.
  bool in_rendezvous_;    // A safepoint rendezvous request is in progress.
  intptr_t remaining_;    // Number of threads yet to reach their safepoint.
  int64_t round_;         // Counter, to prevent missing updates to remaining_
                          // (see comments in CheckSafepointLocked).

  DISALLOW_COPY_AND_ASSIGN(ThreadRegistry);
};

}  // namespace dart

#endif  // VM_THREAD_REGISTRY_H_
