// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MESSAGE_H_
#define RUNTIME_VM_MESSAGE_H_

#include <memory>
#include <utility>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/finalizable_data.h"
#include "vm/globals.h"
#include "vm/tagged_pointer.h"

// Duplicated from dart_api.h to avoid including the whole header.
typedef int64_t Dart_Port;

namespace dart {

class Bequest;
class JSONStream;
class PersistentHandle;
class OldPage;
class WeakTable;
class FreeList;

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
  static const Dart_Port kIllegalPort;

  // A new message to be sent between two isolates. The data handed to this
  // message will be disposed by calling free() once the message object is
  // being destructed (after delivery or when the receiving port is closed).
  Message(Dart_Port dest_port,
          uint8_t* snapshot,
          intptr_t snapshot_length,
          MessageFinalizableData* finalizable_data,
          Priority priority,
          Dart_Port delivery_failure_port = kIllegalPort);

  // Message objects can also carry RawObject pointers for Smis and objects in
  // the VM heap. This is indicated by setting the len_ field to 0.
  Message(Dart_Port dest_port,
          ObjectPtr raw_obj,
          Priority priority,
          Dart_Port delivery_failure_port = kIllegalPort);

  Message(Dart_Port dest_port,
          Bequest* bequest,
          Priority priority,
          Dart_Port delivery_failure_port = kIllegalPort);

  ~Message();

  template <typename... Args>
  static std::unique_ptr<Message> New(Args&&... args) {
    return std::unique_ptr<Message>(new Message(std::forward<Args>(args)...));
  }

  Dart_Port dest_port() const { return dest_port_; }

  uint8_t* snapshot() const {
    ASSERT(IsSnapshot());
    return payload_.snapshot_;
  }
  intptr_t snapshot_length() const { return snapshot_length_; }

  MessageFinalizableData* finalizable_data() { return finalizable_data_; }

  intptr_t Size() const {
    intptr_t size = snapshot_length_;
    if (finalizable_data_ != NULL) {
      size += finalizable_data_->external_size();
    }
    return size;
  }

  ObjectPtr raw_obj() const {
    ASSERT(IsRaw());
    return payload_.raw_obj_;
  }
  Bequest* bequest() const {
    ASSERT(IsBequest());
    return payload_.bequest_;
  }
  Priority priority() const { return priority_; }

  // A message processed at any interrupt point (stack overflow check) instead
  // of at the top of the message loop. Control messages from dart:isolate or
  // vm-service requests.
  bool IsOOB() const { return priority_ == Message::kOOBPriority; }
  bool IsSnapshot() const { return !IsRaw() && !IsBequest(); }
  // A message whose object is an immortal object from the vm-isolate's heap.
  bool IsRaw() const { return snapshot_length_ == 0; }
  // A message sent from sendAndExit.
  bool IsBequest() const { return snapshot_length_ == -1; }

  bool RedirectToDeliveryFailurePort();

  void DropFinalizers() {
    if (finalizable_data_ != nullptr) {
      finalizable_data_->DropFinalizers();
    }
  }

  intptr_t Id() const;

  static const char* PriorityAsString(Priority priority);

 private:
  friend class MessageQueue;

  Message* next_;
  Dart_Port dest_port_;
  Dart_Port delivery_failure_port_;
  union Payload {
    Payload(uint8_t* snapshot) : snapshot_(snapshot) {}
    Payload(ObjectPtr raw_obj) : raw_obj_(raw_obj) {}
    Payload(Bequest* bequest) : bequest_(bequest) {}

    uint8_t* snapshot_;
    ObjectPtr raw_obj_;
    Bequest* bequest_;
  } payload_;
  intptr_t snapshot_length_;
  MessageFinalizableData* finalizable_data_;
  Priority priority_;

  DISALLOW_COPY_AND_ASSIGN(Message);
};

// There is a message queue per isolate.
class MessageQueue {
 public:
  MessageQueue();
  ~MessageQueue();

  void Enqueue(std::unique_ptr<Message> msg, bool before_events);

  // Gets the next message from the message queue or NULL if no
  // message is available.  This function will not block.
  std::unique_ptr<Message> Dequeue();

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

#endif  // RUNTIME_VM_MESSAGE_H_
