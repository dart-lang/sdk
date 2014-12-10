// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"

#include "vm/port.h"

namespace dart {

bool Message::RedirectToDeliveryFailurePort() {
  if (delivery_failure_port_ == kIllegalPort) {
    return false;
  }
  dest_port_ = delivery_failure_port_;
  delivery_failure_port_ = kIllegalPort;
  return true;
}


MessageQueue::MessageQueue() {
  head_ = NULL;
  tail_ = NULL;
}


MessageQueue::~MessageQueue() {
  // Ensure that all pending messages have been released.
  Clear();
  ASSERT(head_ == NULL);
}


void MessageQueue::Enqueue(Message* msg, bool before_events) {
  // Make sure messages are not reused.
  ASSERT(msg->next_ == NULL);
  if (head_ == NULL) {
    // Only element in the queue.
    ASSERT(tail_ == NULL);
    head_ = msg;
    tail_ = msg;
  } else {
    ASSERT(tail_ != NULL);
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
        while (cur->next_ != NULL) {
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


Message* MessageQueue::Dequeue() {
  Message* result = head_;
  if (result != NULL) {
    head_ = result->next_;
    // The following update to tail_ is not strictly needed.
    if (head_ == NULL) {
      tail_ = NULL;
    }
#if defined(DEBUG)
    result->next_ = result;  // Make sure to trigger ASSERT in Enqueue.
#endif  // DEBUG
    return result;
  }
  return NULL;
}


void MessageQueue::Clear() {
  Message* cur = head_;
  head_ = NULL;
  tail_ = NULL;
  while (cur != NULL) {
    Message* next = cur->next_;
    if (cur->RedirectToDeliveryFailurePort()) {
      PortMap::PostMessage(cur);
    } else {
      delete cur;
    }
    cur = next;
  }
}


}  // namespace dart
