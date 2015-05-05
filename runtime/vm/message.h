// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MESSAGE_H_
#define VM_MESSAGE_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"

// Duplicated from dart_api.h to avoid including the whole header.
typedef int64_t Dart_Port;

namespace dart {

class JSONStream;

class Message {
 public:
  typedef enum {
    kNormalPriority = 0,  // Deliver message when idle.
    kOOBPriority = 1,     // Deliver message asap.

    // Iteration.
    kFirstPriority = 0,
    kNumPriorities = 2,
  } Priority;

  // Values defining the type of OOB messages. OOB messages can only be
  // fixed length arrays where the first element is a Smi with one of the
  // valid values below.
  typedef enum {
    kIllegalOOB = 0,
    kServiceOOBMsg = 1,
    kIsolateLibOOBMsg = 2,
    kDelayedIsolateLibOOBMsg = 3,
  } OOBMsgTag;

  // A port number which is never used.
  static const Dart_Port kIllegalPort = 0;

  // A new message to be sent between two isolates. The data handed to this
  // message will be disposed by calling free() once the message object is
  // being destructed (after delivery or when the receiving port is closed).
  Message(Dart_Port dest_port,
          uint8_t* data,
          intptr_t len,
          Priority priority,
          Dart_Port delivery_failure_port = kIllegalPort)
      : next_(NULL),
        dest_port_(dest_port),
        delivery_failure_port_(delivery_failure_port),
        data_(data),
        len_(len),
        priority_(priority) {
    ASSERT((priority == kNormalPriority) ||
           (delivery_failure_port == kIllegalPort));
  }
  ~Message() {
    ASSERT(delivery_failure_port_ == kIllegalPort);
    free(data_);
  }

  Dart_Port dest_port() const { return dest_port_; }
  uint8_t* data() const { return data_; }
  intptr_t len() const { return len_; }
  Priority priority() const { return priority_; }

  bool IsOOB() const { return priority_ == Message::kOOBPriority; }

  bool RedirectToDeliveryFailurePort();

  intptr_t Id() const;

  static const char* PriorityAsString(Priority priority);

 private:
  friend class MessageQueue;

  Message* next_;
  Dart_Port dest_port_;
  Dart_Port delivery_failure_port_;
  uint8_t* data_;
  intptr_t len_;
  Priority priority_;

  DISALLOW_COPY_AND_ASSIGN(Message);
};

// There is a message queue per isolate.
class MessageQueue {
 public:
  MessageQueue();
  ~MessageQueue();

  void Enqueue(Message* msg, bool before_events);

  // Gets the next message from the message queue or NULL if no
  // message is available.  This function will not block.
  Message* Dequeue();

  bool IsEmpty() { return head_ == NULL; }

  // Clear all messages from the message queue.
  void Clear();

  // Iterator class.
  class Iterator : public ValueObject {
   public:
    explicit Iterator(const MessageQueue* queue);
    virtual ~Iterator();

    void Reset(const MessageQueue* queue);

    // Returns false when there are no more messages left.
    bool HasNext();

    // Returns the current message and moves forward.
    Message* Next();

   private:
    Message* next_;
  };

  intptr_t Length() const;

  // Returns the message with id or NULL.
  Message* FindMessageById(intptr_t id);

  void PrintJSON(JSONStream* stream);

 private:
  Message* head_;
  Message* tail_;

  DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};

}  // namespace dart

#endif  // VM_MESSAGE_H_
