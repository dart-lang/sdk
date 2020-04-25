// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"

#include <utility>

#include "vm/dart_entry.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/port.h"

namespace dart {

const Dart_Port Message::kIllegalPort = 0;

Message::Message(Dart_Port dest_port,
                 uint8_t* snapshot,
                 intptr_t snapshot_length,
                 MessageFinalizableData* finalizable_data,
                 Priority priority,
                 Dart_Port delivery_failure_port)
    : next_(NULL),
      dest_port_(dest_port),
      delivery_failure_port_(delivery_failure_port),
      payload_(snapshot),
      snapshot_length_(snapshot_length),
      finalizable_data_(finalizable_data),
      priority_(priority) {
  ASSERT((priority == kNormalPriority) ||
         (delivery_failure_port == kIllegalPort));
  ASSERT(IsSnapshot());
}

Message::Message(Dart_Port dest_port,
                 ObjectPtr raw_obj,
                 Priority priority,
                 Dart_Port delivery_failure_port)
    : next_(NULL),
      dest_port_(dest_port),
      delivery_failure_port_(delivery_failure_port),
      payload_(raw_obj),
      snapshot_length_(0),
      finalizable_data_(NULL),
      priority_(priority) {
  ASSERT(!raw_obj->IsHeapObject() || raw_obj->ptr()->InVMIsolateHeap());
  ASSERT((priority == kNormalPriority) ||
         (delivery_failure_port == kIllegalPort));
  ASSERT(IsRaw());
}

Message::Message(Dart_Port dest_port,
                 Bequest* bequest,
                 Priority priority,
                 Dart_Port delivery_failure_port)
    : next_(nullptr),
      dest_port_(dest_port),
      delivery_failure_port_(delivery_failure_port),
      payload_(bequest),
      snapshot_length_(-1),
      finalizable_data_(nullptr),
      priority_(priority) {
  ASSERT((priority == kNormalPriority) ||
         (delivery_failure_port == kIllegalPort));
  ASSERT(IsBequest());
}

Message::~Message() {
  ASSERT(delivery_failure_port_ == kIllegalPort);
  if (IsSnapshot()) {
    free(payload_.snapshot_);
  }
  delete finalizable_data_;
  if (IsBequest()) {
    delete (payload_.bequest_);
  }
}

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

void MessageQueue::Enqueue(std::unique_ptr<Message> msg0, bool before_events) {
  // TODO(mdempsky): Use unique_ptr internally?
  Message* msg = msg0.release();

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
    if (cur->RedirectToDeliveryFailurePort()) {
      PortMap::PostMessage(std::move(cur));
    }
    cur = std::move(next);
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
    message.AddProperty("size", current->Size());
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
