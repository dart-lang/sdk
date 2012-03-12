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

  // Gets the next message from the message queue, possibly blocking
  // if no message is available. 'millis' is a timeout in
  // milliseconds. If 'millis' is 0, then this means to block
  // indefinitely. May block if no message is available. May return
  // NULL even if 'millis' is 0 due to spurious wakeups.
  Message* Dequeue(int64_t millis);

  // Gets the next message from the message queue if available.  Will
  // not block.
  Message* DequeueNoWait();

  // Gets the next message of the specified priority or greater from
  // the message queue if available.  Will not block.
  Message* DequeueNoWaitWithPriority(Message::Priority min_priority);

  void Flush(Dart_Port port);
  void FlushAll();

 private:
  friend class MessageQueueTestPeer;

  Message* DequeueNoWaitHoldsLock(Message::Priority min_priority);

  Monitor monitor_;
  Message* head_[Message::kNumPriorities];
  Message* tail_[Message::kNumPriorities];

  DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};

// A MessageHandler is an entity capable of accepting messages.
class MessageHandler {
 protected:
  MessageHandler();

  // Allows subclasses to provide custom message notification.
  virtual void MessageNotify(Message::Priority priority);

 public:
  virtual ~MessageHandler();

  // Allow subclasses to provide a handler name.
  virtual const char* name() const;

#if defined(DEBUG)
  // Check that it is safe to access this message handler.
  //
  // For example, if this MessageHandler is an isolate, then it is
  // only safe to access it when the MessageHandler is the current
  // isolate.
  virtual void CheckAccess();
#endif

  void PostMessage(Message* message);
  void ClosePort(Dart_Port port);
  void CloseAllPorts();

  // A message handler tracks how many live ports it has.
  bool HasLivePorts() const { return live_ports_ > 0; }
  void increment_live_ports() {
#if defined(DEBUG)
    CheckAccess();
#endif
    live_ports_++;
  }
  void decrement_live_ports() {
#if defined(DEBUG)
    CheckAccess();
#endif
    live_ports_--;
  }

  // Returns true if the handler is owned by the PortMap.
  //
  // This is used to delete handlers when their last live port is closed.
  virtual bool OwnedByPortMap() const { return false; }

  MessageQueue* queue() const { return queue_; }

 private:
  intptr_t live_ports_;
  MessageQueue* queue_;
};

}  // namespace dart

#endif  // VM_MESSAGE_H_
