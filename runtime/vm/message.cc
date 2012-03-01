// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"

namespace dart {

DECLARE_FLAG(bool, trace_isolates);


MessageHandler::MessageHandler()
    : live_ports_(0),
      queue_(new MessageQueue()) {
  ASSERT(queue_ != NULL);
}


MessageHandler::~MessageHandler() {
  delete queue_;
}


const char* MessageHandler::name() const {
  return "<unnamed>";
}


#if defined(DEBUG)
void MessageHandler::CheckAccess() {
  // By default there is no checking.
}
#endif


void MessageHandler::MessageNotify(Message::Priority priority) {
  // By default, there is no custom message notification.
}


void MessageHandler::PostMessage(Message* message) {
  if (FLAG_trace_isolates) {
    const char* source_name = "<native code>";
    Isolate* source_isolate = Isolate::Current();
    if (source_isolate) {
      source_name = source_isolate->name();
    }
    OS::Print("[>] Posting message:\n"
              "\tsource:     %s\n"
              "\treply_port: %lld\n"
              "\tdest:       %s\n"
              "\tdest_port:  %lld\n",
              source_name, message->reply_port(), name(), message->dest_port());
  }

  Message::Priority priority = message->priority();
  {
    MonitorLocker ml(&monitor_);
    queue_->Enqueue(message);
    monitor_.Notify();
    message = NULL;  // Do not access message.  May have been deleted.
  }

  // Invoke any custom message notification.
  MessageNotify(priority);
}


Message* MessageHandler::DequeueNoWait() {
  MonitorLocker ml(&monitor_);
  return queue_->Dequeue();
}


Message* MessageHandler::Dequeue(int64_t millis) {
  ASSERT(millis >= 0);
  MonitorLocker ml(&monitor_);
  Message* result = queue_->Dequeue();
  if (result == NULL) {
    // No message available at any priority.
    monitor_.Wait(millis);
    result = queue_->Dequeue();
  }
  return result;
}


void MessageHandler::ClosePort(Dart_Port port) {
  MonitorLocker ml(&monitor_);
  queue_->Flush(port);
}


void MessageHandler::CloseAllPorts() {
  MonitorLocker ml(&monitor_);
  queue_->FlushAll();
}


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
  Message::Priority p = msg->priority();
  // Make sure messages are not reused.
  ASSERT(msg->next_ == NULL);
  if (head_[p] == NULL) {
    // Only element in the queue.
    head_[p] = msg;
    tail_[p] = msg;
  } else {
    ASSERT(tail_[p] != NULL);
    // Append at the tail.
    tail_[p]->next_ = msg;
    tail_[p] = msg;
  }
}


Message* MessageQueue::Dequeue() {
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


void MessageQueue::Flush(Dart_Port port) {
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
