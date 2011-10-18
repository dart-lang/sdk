// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_queue.h"

namespace dart {

MessageQueue::~MessageQueue() {
  // Ensure that all pending messages have been released.
  ASSERT(head_ == NULL);
}


void MessageQueue::Enqueue(PortMessage* msg) {
  // TODO(turnidge): Can't use MonitorLocker here because
  // MonitorLocker is a StackResource, which requires a current
  // isolate.  Should MonitorLocker really be a StackResource?
  monitor_.Enter();
  // Make sure messages are not reused.
  ASSERT(msg->next_ == NULL);
  if (head_ == NULL) {
    // Only element in the queue.
    head_ = msg;
    tail_ = msg;

    // We only need to notify if the queue was empty.
    monitor_.Notify();
  } else {
    ASSERT(tail_ != NULL);
    // Append at the tail.
    tail_->next_ = msg;
    tail_ = msg;
  }

  monitor_.Exit();
}


PortMessage* MessageQueue::Dequeue(int64_t millis) {
  MonitorLocker ml(&monitor_);
  PortMessage* result = head_;
  if (result == NULL) {
    ml.Wait(millis);
    result = head_;
  }
  if (result != NULL) {
    head_ = result->next_;
    // The following update to tail_ is not strictly needed.
    if (head_ == NULL) {
      tail_ = NULL;
    }
#if DEBUG
    result->next_ = result;  // Make sure to trigger ASSERT in Enqueue.
#endif  // DEBUG
  }
  return result;
}


void MessageQueue::Flush(Dart_Port port) {
  MonitorLocker ml(&monitor_);
  PortMessage* cur = head_;
  PortMessage* prev = NULL;
  while (cur != NULL) {
    PortMessage* next = cur->next_;
    // If the message matches, then remove it from the queue and delete it.
    if (cur->dest_port() == port) {
      if (prev != NULL) {
        prev->next_ = next;
      } else {
        head_ = next;
      }
      delete cur;
    } else {
      // Move prev forward.
      prev = cur;
    }
    // Advance to the next message in the queue.
    cur = next;
  }
  tail_ = prev;
}


void MessageQueue::FlushAll() {
  MonitorLocker ml(&monitor_);
  PortMessage* cur = head_;
  head_ = NULL;
  tail_ = NULL;
  while (cur != NULL) {
    PortMessage* next = cur->next_;
    delete next;
    cur = next;
  }
}


}  // namespace dart
