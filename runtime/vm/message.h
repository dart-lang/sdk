// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MESSAGE_H_
#define VM_MESSAGE_H_

#include "vm/thread.h"

// Duplicated from dart_api.h to avoid including the whole header.
typedef int64_t Dart_Port;

namespace dart {

class Message {
 public:
  typedef enum {
    kNormalPriority = 0,  // Deliver message when idle.
    kOOBPriority = 1,     // Deliver message asap.

    // Iteration.
    kFirstPriority = 0,
    kNumPriorities = 2,
  } Priority;

  // A port number which is never used.
  static const Dart_Port kIllegalPort = 0;

  // A new message to be sent between two isolates. The data handed to this
  // message will be disposed by calling free() once the message object is
  // being destructed (after delivery or when the receiving port is closed).
  //
  // If reply_port is kIllegalPort, then there is no reply port.
  Message(Dart_Port dest_port, Dart_Port reply_port,
          uint8_t* data, Priority priority)
      : next_(NULL),
        dest_port_(dest_port),
        reply_port_(reply_port),
        data_(data),
        priority_(priority) {}
  ~Message() {
    free(data_);
  }

  Dart_Port dest_port() const { return dest_port_; }
  Dart_Port reply_port() const { return reply_port_; }
  uint8_t* data() const { return data_; }
  Priority priority() const { return priority_; }

  bool IsOOB() const { return priority_ == Message::kOOBPriority; }

 private:
  friend class MessageQueue;

  Message* next_;
  Dart_Port dest_port_;
  Dart_Port reply_port_;
  uint8_t* data_;
  Priority priority_;

  DISALLOW_COPY_AND_ASSIGN(Message);
};

// There is a message queue per isolate.
class MessageQueue {
 public:
  MessageQueue();
  ~MessageQueue();

  void Enqueue(Message* msg);

  // Gets the next message from the message queue or NULL if no
  // message is available.  This function will not block.
  Message* Dequeue();

  void Flush(Dart_Port port);
  void FlushAll();

 private:
  friend class MessageQueueTestPeer;

  Message* head_;
  Message* tail_;

  DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};

}  // namespace dart

#endif  // VM_MESSAGE_H_
