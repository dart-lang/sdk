// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/message.h"
#include "vm/os.h"
#include "vm/port.h"
#include "vm/unit_test.h"

namespace dart {

// Provides private access to PortMap for testing.
class PortMapTestPeer {
 public:
  static bool IsActivePort(Dart_Port port) {
    MutexLocker ml(PortMap::mutex_);
    return (PortMap::FindPort(port) >= 0);
  }

  static bool IsLivePort(Dart_Port port) {
    MutexLocker ml(PortMap::mutex_);
    intptr_t index = PortMap::FindPort(port);
    if (index < 0) {
      return false;
    }
    return PortMap::map_[index].live;
  }
};


class TestMessageHandler : public MessageHandler {
 public:
  TestMessageHandler() : notify_count(0) {}

  void MessageNotify(Message::Priority priority) {
    notify_count++;
  }

  int notify_count;
};


TEST_CASE(PortMap_CreateAndCloseOnePort) {
  TestMessageHandler handler;
  intptr_t port = PortMap::CreatePort(&handler);
  EXPECT_NE(0, port);
  EXPECT(PortMapTestPeer::IsActivePort(port));

  PortMap::ClosePort(port);
  EXPECT(!PortMapTestPeer::IsActivePort(port));
}


TEST_CASE(PortMap_CreateAndCloseTwoPorts) {
  TestMessageHandler handler;
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  EXPECT(PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));

  // Uniqueness.
  EXPECT_NE(port1, port2);

  PortMap::ClosePort(port1);
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));

  PortMap::ClosePort(port2);
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(!PortMapTestPeer::IsActivePort(port2));
}


TEST_CASE(PortMap_ClosePorts) {
  TestMessageHandler handler;
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  EXPECT(PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));

  // Close all ports at once.
  PortMap::ClosePorts(&handler);
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(!PortMapTestPeer::IsActivePort(port2));
}


TEST_CASE(PortMap_CreateManyPorts) {
  TestMessageHandler handler;
  for (int i = 0; i < 32; i++) {
    Dart_Port port = PortMap::CreatePort(&handler);
    EXPECT(PortMapTestPeer::IsActivePort(port));
    PortMap::ClosePort(port);
    EXPECT(!PortMapTestPeer::IsActivePort(port));
  }
}


TEST_CASE(PortMap_SetLive) {
  TestMessageHandler handler;
  intptr_t port = PortMap::CreatePort(&handler);
  EXPECT_NE(0, port);
  EXPECT(PortMapTestPeer::IsActivePort(port));
  EXPECT(!PortMapTestPeer::IsLivePort(port));

  PortMap::SetLive(port);
  EXPECT(PortMapTestPeer::IsActivePort(port));
  EXPECT(PortMapTestPeer::IsLivePort(port));

  PortMap::ClosePort(port);
  EXPECT(!PortMapTestPeer::IsActivePort(port));
  EXPECT(!PortMapTestPeer::IsLivePort(port));
}


TEST_CASE(PortMap_PostMessage) {
  TestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  EXPECT_EQ(0, handler.notify_count);

  EXPECT(PortMap::PostMessage(new Message(
      port, 0, reinterpret_cast<uint8_t*>(strdup("msg")),
      Message::kNormalPriority)));

  // Check that the message notify callback was called.
  EXPECT_EQ(1, handler.notify_count);
  PortMap::ClosePorts(&handler);
}


TEST_CASE(PortMap_PostMessageInvalidPort) {
  EXPECT(!PortMap::PostMessage(new Message(
      0, 0, reinterpret_cast<uint8_t*>(strdup("msg")),
      Message::kNormalPriority)));
}


// End-of-test marker.
static const intptr_t kEOT = 0xFFFF;


uint8_t* AllocIntData(intptr_t payload) {
  intptr_t* result = reinterpret_cast<intptr_t*>(malloc(sizeof(payload)));
  *result = payload;
  return reinterpret_cast<uint8_t*>(result);
}


intptr_t GetIntData(uint8_t* data) {
  return *reinterpret_cast<intptr_t*>(data);
}


static Message* NextMessage() {
  Isolate* isolate = Isolate::Current();
  Message* result = isolate->message_handler()->Dequeue(0);
  return result;
}


void ThreadedPort_start(uword parameter) {
  // TODO(turnidge): We only use the isolate to get access to its
  // message handler.  I should rewrite this test to use a
  // TestMessageHandler instead.
  Isolate* isolate = Dart::CreateIsolate(NULL);

  intptr_t remote = parameter;
  intptr_t local = PortMap::CreatePort(isolate->message_handler());

  PortMap::PostMessage(new Message(
      remote, 0, AllocIntData(local), Message::kNormalPriority));
  intptr_t count = 0;
  while (true) {
    Message* msg = NextMessage();
    EXPECT_EQ(local, msg->dest_port());
    EXPECT(msg != NULL);
    if (GetIntData(msg->data()) == kEOT) {
      break;
    }
    EXPECT(GetIntData(msg->data()) == count);
    delete msg;
    PortMap::PostMessage(new Message(
        remote, 0, AllocIntData(count * 2), Message::kNormalPriority));
    count++;
  }
  PortMap::PostMessage(new Message(
      remote, 0, AllocIntData(kEOT), Message::kNormalPriority));
  Dart::ShutdownIsolate();
}


TEST_CASE(ThreadedPort) {
  intptr_t local = PortMap::CreatePort(Isolate::Current()->message_handler());

  int result = Thread::Start(ThreadedPort_start, local);
  EXPECT_EQ(0, result);

  Message* msg = NextMessage();
  EXPECT_EQ(local, msg->dest_port());
  EXPECT(msg != NULL);
  intptr_t remote = GetIntData(msg->data());  // Get the remote port.
  delete msg;

  for (intptr_t i = 0; i < 10; i++) {
    PortMap::PostMessage(
        new Message(remote, 0, AllocIntData(i), Message::kNormalPriority));
    Message* msg = NextMessage();
    EXPECT_EQ(local, msg->dest_port());
    EXPECT(msg != NULL);
    EXPECT_EQ(i * 2, GetIntData(msg->data()));
    delete msg;
  }

  PortMap::PostMessage(
      new Message(remote, 0, AllocIntData(kEOT), Message::kNormalPriority));
  msg = NextMessage();
  EXPECT_EQ(local, msg->dest_port());
  EXPECT(msg != NULL);
  EXPECT_EQ(kEOT, GetIntData(msg->data()));
  delete msg;

  // Give the spawned thread enough time to properly exit.
  Monitor* waiter = new Monitor();
  {
    MonitorLocker ml(waiter);
    ml.Wait(20);
  }
  delete waiter;
}

}  // namespace dart
