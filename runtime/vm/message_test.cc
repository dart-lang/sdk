// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/message.h"
#include "vm/unit_test.h"

namespace dart {


// Provide access to private members of MessageQueue for testing.
class MessageQueueTestPeer {
 public:
  explicit MessageQueueTestPeer(MessageQueue* queue) : queue_(queue) {}

  bool HasMessage() const {
    // We don't really need to grab the monitor during the unit test,
    // but it doesn't hurt.
    queue_->monitor_.Enter();
    bool result = (queue_->head_[Message::kNormalPriority] != NULL ||
                   queue_->head_[Message::kOOBPriority] != NULL);
    queue_->monitor_.Exit();
    return result;
  }

 private:
  MessageQueue* queue_;
};


static uint8_t* AllocMsg(const char* str) {
  return reinterpret_cast<uint8_t*>(strdup(str));
}


TEST_CASE(MessageQueue_BasicOperations) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  EXPECT(!queue_peer.HasMessage());

  Dart_Port port = 1;

  // Add two messages.
  Message* msg1 =
      new Message(port, 0, AllocMsg("msg1"), Message::kNormalPriority);
  queue.Enqueue(msg1);
  EXPECT(queue_peer.HasMessage());

  Message* msg2 =
      new Message(port, 0, AllocMsg("msg2"), Message::kNormalPriority);

  queue.Enqueue(msg2);
  EXPECT(queue_peer.HasMessage());

  // Remove two messages.
  Message* msg = queue.Dequeue(0);
  EXPECT(msg != NULL);
  EXPECT_STREQ("msg1", reinterpret_cast<char*>(msg->data()));
  EXPECT(queue_peer.HasMessage());

  msg = queue.Dequeue(0);
  EXPECT(msg != NULL);
  EXPECT_STREQ("msg2", reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue_peer.HasMessage());

  delete msg1;
  delete msg2;
}


TEST_CASE(MessageQueue_Priorities) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  EXPECT(!queue_peer.HasMessage());

  Dart_Port port = 1;

  // Add two messages.
  Message* msg1 =
      new Message(port, 0, AllocMsg("msg1"), Message::kNormalPriority);
  queue.Enqueue(msg1);
  EXPECT(queue_peer.HasMessage());

  Message* msg2 =
      new Message(port, 0, AllocMsg("msg2"), Message::kOOBPriority);

  queue.Enqueue(msg2);
  EXPECT(queue_peer.HasMessage());

  // The higher priority message is delivered first.
  Message* msg = queue.Dequeue(0);
  EXPECT(msg != NULL);
  EXPECT_STREQ("msg2", reinterpret_cast<char*>(msg->data()));
  EXPECT(queue_peer.HasMessage());

  msg = queue.Dequeue(0);
  EXPECT(msg != NULL);
  EXPECT_STREQ("msg1", reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue_peer.HasMessage());

  delete msg1;
  delete msg2;
}


// A thread which receives an expected sequence of messages.
static Monitor* sync = NULL;
static MessageQueue* shared_queue = NULL;
void MessageReceiver_start(uword unused) {
  // We only need an isolate here because the MonitorLocker in the
  // MessageQueue expects it, we don't need to initialize the isolate
  // as it does not run any dart code.
  Dart::CreateIsolate(NULL);

  // Create a message queue and share it.
  MessageQueue* queue = new MessageQueue();
  MessageQueueTestPeer peer(queue);
  shared_queue = queue;

  // Tell the other thread that the shared queue is ready.
  {
    MonitorLocker ml(sync);
    ml.Notify();
  }

  // Wait for the other thread to fill the queue a bit.
  while (!peer.HasMessage()) {
    MonitorLocker ml(sync);
    ml.Wait(5);
  }

  int i = 0;
  while (i < 3) {
    Message* msg = queue->Dequeue(0);
    // Dequeue(0) can return NULL due to spurious wakeup.
    if (msg != NULL) {
      EXPECT_EQ(i + 10, msg->dest_port());
      EXPECT_EQ(i + 100, msg->reply_port());
      EXPECT_EQ(i + 1000, *(reinterpret_cast<int*>(msg->data())));
      delete msg;
      i++;
    }
  }

  i = 0;
  while (i < 3) {
    Message* msg = queue->Dequeue(0);
    // Dequeue(0) can return NULL due to spurious wakeup.
    if (msg != NULL) {
      EXPECT_EQ(i + 20, msg->dest_port());
      EXPECT_EQ(i + 200, msg->reply_port());
      EXPECT_EQ(i + 2000, *(reinterpret_cast<int*>(msg->data())));
      delete msg;
      i++;
    }
  }
  shared_queue = NULL;
  delete queue;
  Dart::ShutdownIsolate();
}


TEST_CASE(MessageQueue_WaitNotify) {
  sync = new Monitor();

  int result = Thread::Start(MessageReceiver_start, 0);
  EXPECT_EQ(0, result);

  // Wait for the shared queue to be created.
  while (shared_queue == NULL) {
    MonitorLocker ml(sync);
    ml.Wait(5);
  }
  ASSERT(shared_queue != NULL);

  // Pile up three messages before the other thread runs.
  for (int i = 0; i < 3; i++) {
    int* data = reinterpret_cast<int*>(malloc(sizeof(*data)));
    *data = i + 1000;
    Message* msg =
        new Message(i + 10, i + 100, reinterpret_cast<uint8_t*>(data),
                    Message::kNormalPriority);
    shared_queue->Enqueue(msg);
  }

  // Wake the other thread and have it start consuming messages.
  {
    MonitorLocker ml(sync);
    ml.Notify();
  }

  // Add a few more messages after sleeping to allow the other thread
  // to potentially exercise the blocking code path in Dequeue.
  OS::Sleep(5);
  for (int i = 0; i < 3; i++) {
    int* data = reinterpret_cast<int*>(malloc(sizeof(*data)));
    *data = i + 2000;
    Message* msg =
        new Message(i + 20, i + 200, reinterpret_cast<uint8_t*>(data),
                    Message::kNormalPriority);
    shared_queue->Enqueue(msg);
  }

  sync = NULL;
  delete sync;

  // Give the spawned thread enough time to properly exit.
  OS::Sleep(20);
}


TEST_CASE(MessageQueue_FlushAll) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  Dart_Port port1 = 1;
  Dart_Port port2 = 2;

  // Add two messages.
  Message* msg1 =
      new Message(port1, 0, AllocMsg("msg1"), Message::kNormalPriority);
  queue.Enqueue(msg1);
  Message* msg2 =
      new Message(port2, 0, AllocMsg("msg2"), Message::kNormalPriority);
  queue.Enqueue(msg2);

  EXPECT(queue_peer.HasMessage());
  queue.FlushAll();
  EXPECT(!queue_peer.HasMessage());

  // msg1 and msg2 already delete by FlushAll.
}


TEST_CASE(MessageQueue_Flush) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  Dart_Port port1 = 1;
  Dart_Port port2 = 2;

  // Add two messages on different ports.
  Message* msg1 =
      new Message(port1, 0, AllocMsg("msg1"), Message::kNormalPriority);
  queue.Enqueue(msg1);
  Message* msg2 =
      new Message(port2, 0, AllocMsg("msg2"), Message::kNormalPriority);
  queue.Enqueue(msg2);
  EXPECT(queue_peer.HasMessage());

  queue.Flush(port1);

  // One message is left in the queue.
  EXPECT(queue_peer.HasMessage());
  Message* msg = queue.Dequeue(0);
  EXPECT(msg != NULL);
  EXPECT_STREQ("msg2", reinterpret_cast<char*>(msg->data()));

  EXPECT(!queue_peer.HasMessage());

  // msg1 is already deleted by Flush.
  delete msg2;
}


TEST_CASE(MessageQueue_Flush_MultipleMessages) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  Dart_Port port1 = 1;

  Message* msg1 =
      new Message(port1, 0, AllocMsg("msg1"), Message::kNormalPriority);
  queue.Enqueue(msg1);
  Message* msg2 =
      new Message(port1, 0, AllocMsg("msg2"), Message::kNormalPriority);
  queue.Enqueue(msg2);
  EXPECT(queue_peer.HasMessage());

  queue.Flush(port1);

  // Queue is empty.
  EXPECT(!queue_peer.HasMessage());
  // msg1 and msg2 are already deleted by Flush.
}


TEST_CASE(MessageQueue_Flush_EmptyQueue) {
  MessageQueue queue;
  MessageQueueTestPeer queue_peer(&queue);
  Dart_Port port1 = 1;

  EXPECT(!queue_peer.HasMessage());
  queue.Flush(port1);

  // Queue is still empty.
  EXPECT(!queue_peer.HasMessage());
}

}  // namespace dart
