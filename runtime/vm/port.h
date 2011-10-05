// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PORT_H_
#define VM_PORT_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/thread.h"

namespace dart {

class PortMessage {
 public:
  // A new message to be sent between two isolates. The data handed to this
  // message will be disposed by calling free() once the message object is
  // being destructed (after delivery or when the receiving port is closed).
  PortMessage(intptr_t dest_id, intptr_t reply_id, void* data)
      : next_(NULL),
        dest_id_(dest_id),
        reply_id_(reply_id),
        data_(data) {}
  ~PortMessage() {
    free(data_);
  }

  intptr_t dest_id() const { return dest_id_; }
  intptr_t reply_id() const { return reply_id_; }
  void* data() const { return data_; }

  void Handle();

 private:
  PortMessage* next_;
  intptr_t dest_id_;
  intptr_t reply_id_;
  void* data_;

  friend class MessageQueue;

  DISALLOW_COPY_AND_ASSIGN(PortMessage);
};


// There is a message queue per isolate. Access to the message queue should be
// protected by the isolate monitor.
class MessageQueue {
 public:
  MessageQueue() : head_(NULL), tail_(NULL) {}
  ~MessageQueue();

  void Enqueue(PortMessage* msg);
  PortMessage* Dequeue();

  void Flush(intptr_t id);
  void FlushAll();

 private:
  PortMessage* head_;
  PortMessage* tail_;

  DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};


class PortMap: public AllStatic {
 public:
  // Allocate a port in the current isolate and return its VM-global id.
  static intptr_t CreatePort();

  // Close the port with id. All pending messages will be dropped.
  static void ClosePort(intptr_t id);

  // Close all the ports of the current isolate.
  static void ClosePorts();

  static bool IsActivePort(intptr_t id);

  // Enqueues the message in the port with id. Returns false if the port is not
  // active any longer.
  static bool PostMessage(PortMessage* msg);

  // Dequeue the next message pending for this isolate. Returns null if timeout
  // was reached before a message was posted.
  static PortMessage* ReceiveMessage(int64_t millis);

  static void InitOnce();

 private:
  // Mapping between port numbers and isolates.
  // Free entries have id == 0 and isolate == NULL. Deleted entries have id == 0
  // and isolate == deleted_entry_.
  typedef struct {
    intptr_t id;
    Isolate* isolate;
  } Entry;

  // Allocate a new unique port id.
  static intptr_t AllocateId();

  static intptr_t FindId(intptr_t id);
  static void Rehash(intptr_t new_capacity);

  static void MaintainInvariants();

  // Lock protecting access to the port map.
  static Mutex* mutex_;

  // Hashmap of ports.
  static Entry* map_;
  static Isolate* deleted_entry_;
  static intptr_t capacity_;
  static intptr_t used_;
  static intptr_t deleted_;

  static intptr_t next_id_;
};

}  // namespace dart

#endif  // VM_PORT_H_
