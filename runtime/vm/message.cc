// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"

#include <utility>

#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/port.h"

namespace dart {

const Dart_Port Message::kIllegalPort = 0;

Message::Message(Dart_Port dest_port,
                 uint8_t* snapshot,
                 intptr_t snapshot_length,
                 MessageFinalizableData* finalizable_data,
                 Priority priority)
    : dest_port_(dest_port),
      payload_(snapshot),
      snapshot_length_(snapshot_length),
      finalizable_data_(finalizable_data),
      priority_(priority) {
  ASSERT(IsSnapshot());
}

Message::Message(Dart_Port dest_port, ObjectPtr raw_obj, Priority priority)
    : dest_port_(dest_port), payload_(raw_obj), priority_(priority) {
  ASSERT(!raw_obj->IsHeapObject());
  ASSERT(IsRaw());
}

Message::Message(Dart_Port dest_port,
                 PersistentHandle* handle,
                 Priority priority)
    : dest_port_(dest_port),
      payload_(handle),
      snapshot_length_(kPersistentHandleSnapshotLen),
      priority_(priority) {
  ASSERT(IsPersistentHandle());
}

Message::Message(PersistentHandle* handle, Priority priority)
    : dest_port_(ILLEGAL_PORT),
      payload_(handle),
      snapshot_length_(kFinalizerSnapshotLen),
      priority_(priority) {
  ASSERT(IsFinalizerInvocationRequest());
}

Message::~Message() {
  if (IsSnapshot()) {
    free(payload_.snapshot_);
  }
  delete finalizable_data_;
  if (IsPersistentHandle() || IsFinalizerInvocationRequest()) {
    auto isolate_group = IsolateGroup::Current();
    isolate_group->api_state()->FreePersistentHandle(
        payload_.persistent_handle_);
  }
}

MessageQueue::MessageQueue() {
  head_ = nullptr;
  tail_ = nullptr;
}

MessageQueue::~MessageQueue() {
  // Ensure that all pending messages have been released.
  Clear();
  ASSERT(head_ == nullptr);
}

void MessageQueue::Enqueue(std::unique_ptr<Message> msg0, bool before_events) {
  // TODO(mdempsky): Use unique_ptr internally?
  Message* msg = msg0.release();

  // Make sure messages are not reused.
  ASSERT(msg->next_ == nullptr);
  if (head_ == nullptr) {
    // Only element in the queue.
    ASSERT(tail_ == nullptr);
    head_ = msg;
    tail_ = msg;
  } else {
    ASSERT(tail_ != nullptr);
    if (!before_events) {
      // Append at the tail.
      tail_->next_ = msg;
      tail_ = msg;
    } else {
      ASSERT(msg->dest_port() == Message::kIllegalPort);
      if (head_->dest_port() != Message::kIllegalPort) {
        msg->next_ = head_;
        head_ = msg;
      } else {
        Message* cur = head_;
        while (cur->next_ != nullptr) {
          if (cur->next_->dest_port() != Message::kIllegalPort) {
            // Splice in the new message at the break.
            msg->next_ = cur->next_;
            cur->next_ = msg;
            return;
          }
          cur = cur->next_;
        }
        // All pending messages are isolate library control messages. Append at
        // the tail.
        ASSERT(tail_ == cur);
        ASSERT(tail_->dest_port() == Message::kIllegalPort);
        tail_->next_ = msg;
        tail_ = msg;
      }
    }
  }
}

std::unique_ptr<Message> MessageQueue::Dequeue() {
  Message* result = head_;
  if (result != nullptr) {
    head_ = result->next_;
    // The following update to tail_ is not strictly needed.
    if (head_ == nullptr) {
      tail_ = nullptr;
    }
#if defined(DEBUG)
    result->next_ = result;  // Make sure to trigger ASSERT in Enqueue.
#endif                       // DEBUG
    return std::unique_ptr<Message>(result);
  }
  return nullptr;
}

void MessageQueue::Clear() {
  std::unique_ptr<Message> cur(head_);
  head_ = nullptr;
  tail_ = nullptr;
  while (cur != nullptr) {
    std::unique_ptr<Message> next(cur->next_);
    cur = std::move(next);
  }
}

MessageQueue::Iterator::Iterator(const MessageQueue* queue) : next_(nullptr) {
  Reset(queue);
}

MessageQueue::Iterator::~Iterator() {}

void MessageQueue::Iterator::Reset(const MessageQueue* queue) {
  ASSERT(queue != nullptr);
  next_ = queue->head_;
}

// returns false when there are no more messages left.
bool MessageQueue::Iterator::HasNext() {
  return next_ != nullptr;
}

// Returns the current message and moves forward.
Message* MessageQueue::Iterator::Next() {
  Message* current = next_;
  next_ = next_->next_;
  return current;
}

intptr_t MessageQueue::Length() const {
  MessageQueue::Iterator it(this);
  intptr_t length = 0;
  while (it.HasNext()) {
    it.Next();
    length++;
  }
  return length;
}

}  // namespace dart
