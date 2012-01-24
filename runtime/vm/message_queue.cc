// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_queue.h"

namespace dart {

MessageQueue::MessageQueue() {
  for (int p = Message::kFirstPriority; p < Message::kNumPriorities; p++) {
    head_[p] = NULL;
    tail_[p] = NULL;
  }
}


MessageQueue::~MessageQueue() {
  // Ensure that all pending messages have been released.
#if defined(DEBUG)
  for (int p = Message::kFirstPriority; p < Message::kNumPriorities; p++) {
    ASSERT(head_[p] == NULL);
  }
#endif
}


void MessageQueue::Enqueue(Message* msg) {
  // TODO(turnidge): Add a scoped locker for monitors which is not a
  // stack resource.  This would probably be useful in the platform
  // headers.
  monitor_.Enter();

  Message::Priority p = msg->priority();
  // Make sure messages are not reused.
  ASSERT(msg->next_ == NULL);
  if (head_[p] == NULL) {
    // Only element in the queue.
    head_[p] = msg;
    tail_[p] = msg;

    // We only need to notify if the queue was empty.
    monitor_.Notify();
  } else {
    ASSERT(tail_[p] != NULL);
    // Append at the tail.
    tail_[p]->next_ = msg;
    tail_[p] = msg;
  }

  monitor_.Exit();
}

Message* MessageQueue::DequeueNoWait() {
  MonitorLocker ml(&monitor_);
  return DequeueNoWaitHoldsLock();
}

Message* MessageQueue::DequeueNoWaitHoldsLock() {
  // Look for the highest priority available message.
  for (int p = Message::kNumPriorities-1; p >= Message::kFirstPriority; p--) {
    Message* result = head_[p];
    if (result != NULL) {
      head_[p] = result->next_;
      // The following update to tail_ is not strictly needed.
      if (head_[p] == NULL) {
        tail_[p] = NULL;
      }
#if defined(DEBUG)
      result->next_ = result;  // Make sure to trigger ASSERT in Enqueue.
#endif  // DEBUG
      return result;
    }
  }
  return NULL;
}


Message* MessageQueue::Dequeue(int64_t millis) {
  ASSERT(millis >= 0);
  MonitorLocker ml(&monitor_);

  Message* result = DequeueNoWaitHoldsLock();
  if (result == NULL) {
    // No message available at any priority.
    ml.Wait(millis);
    result = DequeueNoWaitHoldsLock();
  }
  return result;
}


void MessageQueue::Flush(Dart_Port port) {
  MonitorLocker ml(&monitor_);
  for (int p = Message::kFirstPriority; p < Message::kNumPriorities; p++) {
    Message* cur = head_[p];
    Message* prev = NULL;
    while (cur != NULL) {
      Message* next = cur->next_;
      // If the message matches, then remove it from the queue and delete it.
      if (cur->dest_port() == port) {
        if (prev != NULL) {
          prev->next_ = next;
        } else {
          head_[p] = next;
        }
        delete cur;
      } else {
        // Move prev forward.
        prev = cur;
      }
      // Advance to the next message in the queue.
      cur = next;
    }
    tail_[p] = prev;
  }
}


void MessageQueue::FlushAll() {
  MonitorLocker ml(&monitor_);
  for (int p = Message::kFirstPriority; p < Message::kNumPriorities; p++) {
    Message* cur = head_[p];
    head_[p] = NULL;
    tail_[p] = NULL;
    while (cur != NULL) {
      Message* next = cur->next_;
      delete cur;
      cur = next;
    }
  }
}


}  // namespace dart
