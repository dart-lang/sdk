// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"

#include "vm/dart_entry.h"
#include "vm/json_stream.h"
#include "vm/object.h"
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

intptr_t Message::Id() const {
  // Messages are allocated on the C heap. Use the raw address as the id.
  return reinterpret_cast<intptr_t>(this);
}

const char* Message::PriorityAsString(Priority priority) {
  switch (priority) {
    case kNormalPriority:
      return "Normal";
      break;
    case kOOBPriority:
      return "OOB";
      break;
    default:
      UNIMPLEMENTED();
      return NULL;
  }
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
#endif                       // DEBUG
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

MessageQueue::Iterator::Iterator(const MessageQueue* queue) : next_(NULL) {
  Reset(queue);
}

MessageQueue::Iterator::~Iterator() {}

void MessageQueue::Iterator::Reset(const MessageQueue* queue) {
  ASSERT(queue != NULL);
  next_ = queue->head_;
}

// returns false when there are no more messages left.
bool MessageQueue::Iterator::HasNext() {
  return next_ != NULL;
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

Message* MessageQueue::FindMessageById(intptr_t id) {
  MessageQueue::Iterator it(this);
  while (it.HasNext()) {
    Message* current = it.Next();
    ASSERT(current != NULL);
    if (current->Id() == id) {
      return current;
    }
  }
  return NULL;
}

void MessageQueue::PrintJSON(JSONStream* stream) {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return;
  }
  JSONArray messages(stream);

  Object& msg_handler = Object::Handle();

  MessageQueue::Iterator it(this);
  intptr_t depth = 0;
  while (it.HasNext()) {
    Message* current = it.Next();
    JSONObject message(&messages);
    message.AddProperty("type", "Message");
    message.AddPropertyF("name", "Isolate Message (%" Px ")", current->Id());
    message.AddPropertyF("messageObjectId", "messages/%" Px "", current->Id());
    message.AddProperty("size", current->len());
    message.AddProperty("index", depth++);
    message.AddPropertyF("_destinationPort", "%" Pd64 "",
                         static_cast<int64_t>(current->dest_port()));
    message.AddProperty("_priority",
                        Message::PriorityAsString(current->priority()));
    // TODO(johnmccutchan): Move port -> handler map out of Dart and into the
    // VM, that way we can lookup the handler without invoking Dart code.
    msg_handler = DartLibraryCalls::LookupHandler(current->dest_port());
    if (msg_handler.IsClosure()) {
      // Grab function from closure.
      msg_handler = Closure::Cast(msg_handler).function();
    }
    if (msg_handler.IsFunction()) {
      const Function& function = Function::Cast(msg_handler);
      message.AddProperty("handler", function);

      const Script& script = Script::Handle(function.script());
      if (!script.IsNull()) {
        message.AddLocation(script, function.token_pos(),
                            function.end_token_pos());
      }
    }
  }
#endif  // !PRODUCT
}

}  // namespace dart
