// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_registry.h"

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"

namespace dart {

ThreadRegistry::~ThreadRegistry() {
  // Go over the free thread list and delete the thread objects.
  {
    MonitorLocker ml(threads_lock());
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
  delete threads_lock_;
}

// Gets a free Thread structure, we special case the mutator thread
// by reusing the cached structure, see comment in 'thread_registry.h'.
Thread* ThreadRegistry::GetFreeThreadLocked(Isolate* isolate, bool is_mutator) {
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
  Thread* thread;
  if (is_mutator) {
    if (mutator_thread_ == NULL) {
      mutator_thread_ = GetFromFreelistLocked(isolate);
    }
    thread = mutator_thread_;
  } else {
    thread = GetFromFreelistLocked(isolate);
    ASSERT(thread->api_top_scope() == NULL);
  }
  // Now add this Thread to the active list for the isolate.
  AddToActiveListLocked(thread);
  return thread;
}

void ThreadRegistry::ReturnThreadLocked(bool is_mutator, Thread* thread) {
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
  // Remove thread from the active list for the isolate.
  RemoveFromActiveListLocked(thread);
  if (!is_mutator) {
    ReturnToFreelistLocked(thread);
  }
}

void ThreadRegistry::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                         bool validate_frames) {
  MonitorLocker ml(threads_lock());
  bool mutator_thread_visited = false;
  Thread* thread = active_list_;
  while (thread != NULL) {
    thread->VisitObjectPointers(visitor, validate_frames);
    if (mutator_thread_ == thread) {
      mutator_thread_visited = true;
    }
    thread = thread->next_;
  }
  // Visit mutator thread even if it is not in the active list because of
  // api handles.
  if (!mutator_thread_visited && (mutator_thread_ != NULL)) {
    mutator_thread_->VisitObjectPointers(visitor, validate_frames);
  }
}

void ThreadRegistry::PrepareForGC() {
  MonitorLocker ml(threads_lock());
  Thread* thread = active_list_;
  while (thread != NULL) {
    thread->PrepareForGC();
    thread = thread->next_;
  }
}

#ifndef PRODUCT
void ThreadRegistry::PrintJSON(JSONStream* stream) const {
  MonitorLocker ml(threads_lock());
  JSONArray threads(stream);
  Thread* current = active_list_;
  while (current != NULL) {
    threads.AddValue(current);
    current = current->next_;
  }
}
#endif

intptr_t ThreadRegistry::CountZoneHandles() const {
  MonitorLocker ml(threads_lock());
  intptr_t count = 0;
  Thread* current = active_list_;
  while (current != NULL) {
    count += current->CountZoneHandles();
    current = current->next_;
  }
  return count;
}

intptr_t ThreadRegistry::CountScopedHandles() const {
  MonitorLocker ml(threads_lock());
  intptr_t count = 0;
  Thread* current = active_list_;
  while (current != NULL) {
    count += current->CountScopedHandles();
    current = current->next_;
  }
  return count;
}

void ThreadRegistry::AddToActiveListLocked(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
  thread->next_ = active_list_;
  active_list_ = thread;
}

void ThreadRegistry::RemoveFromActiveListLocked(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
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

Thread* ThreadRegistry::GetFromFreelistLocked(Isolate* isolate) {
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
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

void ThreadRegistry::ReturnToFreelistLocked(Thread* thread) {
  ASSERT(thread != NULL);
  ASSERT(thread->os_thread_ == NULL);
  ASSERT(thread->isolate_ == NULL);
  ASSERT(thread->heap_ == NULL);
  ASSERT(threads_lock()->IsOwnedByCurrentThread());
  // Add thread to the free list.
  thread->next_ = free_list_;
  free_list_ = thread;
}

}  // namespace dart
