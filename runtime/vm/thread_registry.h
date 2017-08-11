// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_REGISTRY_H_
#define RUNTIME_VM_THREAD_REGISTRY_H_

#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/stack_frame.h"
#include "vm/thread.h"

namespace dart {

#ifndef PRODUCT
class JSONStream;
class JSONArray;
#endif

// Unordered collection of threads relating to a particular isolate.
class ThreadRegistry {
 public:
  ThreadRegistry()
      : threads_lock_(new Monitor()),
        active_list_(NULL),
        free_list_(NULL),
        mutator_thread_(NULL) {}
  ~ThreadRegistry();

  void VisitObjectPointers(ObjectPointerVisitor* visitor, bool validate_frames);
  void PrepareForGC();
  Thread* mutator_thread() const { return mutator_thread_; }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

  // Calculates the sum of the max memory usage in bytes of each thread.
  uintptr_t ThreadHighWatermarksTotalLocked() const;

  intptr_t CountZoneHandles() const;
  intptr_t CountScopedHandles() const;

 private:
  Thread* active_list() const { return active_list_; }
  Monitor* threads_lock() const { return threads_lock_; }

  Thread* GetFreeThreadLocked(Isolate* isolate, bool is_mutator);
  void ReturnThreadLocked(bool is_mutator, Thread* thread);
  void AddToActiveListLocked(Thread* thread);
  void RemoveFromActiveListLocked(Thread* thread);
  Thread* GetFromFreelistLocked(Isolate* isolate);
  void ReturnToFreelistLocked(Thread* thread);

  // This monitor protects the threads list for an isolate, it is used whenever
  // we need to iterate over threads (both active and free) in an isolate.
  Monitor* threads_lock_;
  Thread* active_list_;  // List of active threads in the isolate.
  Thread* free_list_;    // Free list of Thread objects that can be reused.

  // TODO(asiva): Currently we treat a mutator thread as a special thread
  // and always schedule execution of Dart code on the same mutator thread
  // object. The ApiLocalScope has been made thread specific but we still
  // have scenarios where we do a temporary exit of an Isolate with live
  // zones/handles in the API scope :
  // - Dart_RunLoop()
  // - IsolateSaver in Dart_NewNativePort
  // - Isolate spawn (function/uri) under FLAG_i_like_slow_isolate_spawn
  // Similarly, tracking async_stack_trace requires that we always reschedule
  // on the same thread.
  // We probably need a mechanism to return to the specific thread only
  // for these specific cases. We should also determine if the embedder
  // should allow exiting an isolate with live state in zones/handles in
  // which case a new API for returning to the specific thread needs to be
  // added.
  Thread* mutator_thread_;

  friend class Isolate;
  friend class SafepointHandler;
  friend class Scavenger;
  DISALLOW_COPY_AND_ASSIGN(ThreadRegistry);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_REGISTRY_H_
