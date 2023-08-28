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

// Unordered collection of threads relating to a particular isolate group.
class ThreadRegistry {
 public:
  ThreadRegistry()
      : threads_lock_(),
        active_list_(nullptr),
        free_list_(nullptr),
        active_isolates_count_(0) {}
  ~ThreadRegistry();

  void VisitObjectPointers(IsolateGroup* isolate_group_of_interest,
                           ObjectPointerVisitor* visitor,
                           ValidationPolicy validate_frames);

  void ForEachThread(std::function<void(Thread* thread)> callback);
  void ReleaseStoreBuffers();
  void AcquireMarkingStacks();
  void ReleaseMarkingStacks();

  // Concurrent-approximate number of active isolates in the active_list
  intptr_t active_isolates_count() { return active_isolates_count_.load(); }

  Monitor* threads_lock() const { return &threads_lock_; }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

 private:
  Thread* active_list() const { return active_list_; }

  Thread* GetFreeThreadLocked(bool is_vm_isolate);
  void ReturnThreadLocked(Thread* thread);
  void AddToActiveListLocked(Thread* thread);
  void RemoveFromActiveListLocked(Thread* thread);
  Thread* GetFromFreelistLocked(bool is_vm_isolate);
  void ReturnToFreelistLocked(Thread* thread);

  // This monitor protects the threads list for an isolate, it is used whenever
  // we need to iterate over threads (both active and free) in an isolate.
  mutable Monitor threads_lock_;
  Thread* active_list_;  // List of active threads in the isolate.
  Thread* free_list_;    // Free list of Thread objects that can be reused.
  RelaxedAtomic<intptr_t> active_isolates_count_;

  friend class Thread;
  friend class SafepointHandler;
  DISALLOW_COPY_AND_ASSIGN(ThreadRegistry);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_REGISTRY_H_
