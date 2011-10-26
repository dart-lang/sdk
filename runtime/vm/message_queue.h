// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_MESSAGE_QUEUE_H_
#define VM_MESSAGE_QUEUE_H_

#include "include/dart_api.h"
#include "vm/thread.h"

namespace dart {

class PortMessage {
 public:
  // A new message to be sent between two isolates. The data handed to this
  // message will be disposed by calling free() once the message object is
  // being destructed (after delivery or when the receiving port is closed).
  PortMessage(Dart_Port dest_port, Dart_Port reply_port, Dart_Message data)
      : next_(NULL),
        dest_port_(dest_port),
        reply_port_(reply_port),
        data_(data) {}
  ~PortMessage() {
    free(data_);
  }

  Dart_Port dest_port() const { return dest_port_; }
  Dart_Port reply_port() const { return reply_port_; }
  Dart_Message data() const { return data_; }

 private:
  friend class MessageQueue;

  PortMessage* next_;
  Dart_Port dest_port_;
  Dart_Port reply_port_;
  Dart_Message data_;

  DISALLOW_COPY_AND_ASSIGN(PortMessage);
};


// There is a message queue per isolate.
class MessageQueue {
 public:
  MessageQueue() : head_(NULL), tail_(NULL) {}
  ~MessageQueue();

  void Enqueue(PortMessage* msg);

  // Gets the next message from the message queue, possibly blocking
  // if no message is available. 'millis' is a timeout in
  // milliseconds. If 'millis' is 0, then this means to block
  // indefinitely. May block if no message is available. May return
  // NULL even if 'millis' is 0 due to spurious wakeups.
  PortMessage* Dequeue(int64_t millis);

  void Flush(Dart_Port port);
  void FlushAll();

 private:
  friend class MessageQueueTestPeer;

  Monitor monitor_;
  PortMessage* head_;
  PortMessage* tail_;

  DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};

}  // namespace dart

#endif  // VM_MESSAGE_QUEUE_H_
