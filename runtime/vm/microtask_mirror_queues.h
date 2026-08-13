// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MICROTASK_MIRROR_QUEUES_H_
#define RUNTIME_VM_MICROTASK_MIRROR_QUEUES_H_

#include <utility>

#include "platform/hashmap.h"
#include "platform/list_queue.h"
#include "platform/synchronization.h"
#include "platform/utils.h"
#include "vm/json_stream.h"
#include "vm/stack_frame.h"

namespace dart {

class MicrotaskMirrorQueueEntry : public ValueObject {
 public:
  static constexpr intptr_t kInvalidId = -1;

  MicrotaskMirrorQueueEntry() : id_(kInvalidId), stack_trace_(nullptr) {}
  MicrotaskMirrorQueueEntry(intptr_t id, CStringUniquePtr&& st)
      : id_(id), stack_trace_(std::move(st)) {}

  void operator=(MicrotaskMirrorQueueEntry&& other) {
    id_ = other.id_;
    stack_trace_.swap(other.stack_trace_);
  }

  intptr_t id() const { return id_; }
  CStringUniquePtr const& stack_trace() const { return stack_trace_; }
  /// Releases ownership of the stack trace string that this entry is holding.
  char* ReleaseStackTrace() { return stack_trace_.release(); }

 private:
  intptr_t id_;
  CStringUniquePtr stack_trace_;
};

/// A queue that mirrors the microtask queue of an isolate. This allows the VM
/// Service to return information about microtasks.
class MicrotaskMirrorQueue {
 public:
  MicrotaskMirrorQueue()
      : is_disabled_(false), queue_(), next_available_id_(0) {}

  bool is_disabled() const { return is_disabled_; }
  void OnScheduleAsyncCallback(const StackTrace& st);
  void OnSchedulePriorityAsyncCallback();
  void OnAsyncCallbackComplete(int64_t start_time, int64_t end_time);
  void PrintJSON(JSONStream& js) const;

 private:
  bool is_disabled_;
  ListQueue<MicrotaskMirrorQueueEntry> queue_;
  // The unique ID that will be assigned to the next |MicrotaskMirrorQueueEntry|
  // added to |queue_|.
  intptr_t next_available_id_;

  DISALLOW_COPY_AND_ASSIGN(MicrotaskMirrorQueue);
};

/// A wrapper around a map from isolate IDs to |MicrotaskMirrorQueue|s.
class MicrotaskMirrorQueues : public AllStatic {
 public:
  static MicrotaskMirrorQueue* GetQueue(int64_t isolate_id);
  static void CleanUp();

 private:
  static constexpr intptr_t kIsolateIdToQueueInitialCapacity = 1 << 4;  // 16
  static Mutex isolate_id_to_queue_lock_;
  static SimpleHashMap isolate_id_to_queue_;

  DISALLOW_COPY_AND_ASSIGN(MicrotaskMirrorQueues);
};

}  // namespace dart

#endif  // RUNTIME_VM_MICROTASK_MIRROR_QUEUES_H_
