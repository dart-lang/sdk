// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/message_queue.h"
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


// Intercept the post message callback and just store a copy of the message.
static const int kMaxSavedMsg = 80;
static char saved_msg[kMaxSavedMsg];
static bool MyPostMessageCallback(Dart_Isolate dest_isolate,
                                  Dart_Port dest_port,
                                  Dart_Port reply_port,
                                  Dart_Message dart_message) {
  const char* msg = reinterpret_cast<char*>(dart_message);
  OS::SNPrint(saved_msg, kMaxSavedMsg, "%s", msg);
  bool result = (strcmp(msg, "fail") != 0);
  free(dart_message);
  return result;
}


// Intercept the close port callback and remember which port was closed.
static Dart_Port saved_port = 0;
static void MyClosePortCallback(Dart_Isolate dart_isolate,
                                Dart_Port port) {
  saved_port = port;
}


static void InitPortMapTest() {
  Dart_SetMessageCallbacks(&MyPostMessageCallback, &MyClosePortCallback);
  saved_port = 0;
  saved_msg[0] = '\0';
}


TEST_CASE(PortMap_CreateAndCloseOnePort) {
  InitPortMapTest();
  intptr_t port = PortMap::CreatePort();
  EXPECT_NE(0, port);
  EXPECT(PortMapTestPeer::IsActivePort(port));

  PortMap::ClosePort(port);
  EXPECT(!PortMapTestPeer::IsActivePort(port));

  // Embedder was notified of port closure.
  EXPECT_EQ(port, saved_port);
}


TEST_CASE(PortMap_CreateAndCloseTwoPorts) {
  InitPortMapTest();
  Dart_Port port1 = PortMap::CreatePort();
  Dart_Port port2 = PortMap::CreatePort();
  EXPECT(PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));

  // Uniqueness.
  EXPECT_NE(port1, port2);

  PortMap::ClosePort(port1);
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));
  EXPECT_EQ(port1, saved_port);

  PortMap::ClosePort(port2);
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(!PortMapTestPeer::IsActivePort(port2));
  EXPECT_EQ(port2, saved_port);
}


TEST_CASE(PortMap_ClosePorts) {
  InitPortMapTest();
  Dart_Port port1 = PortMap::CreatePort();
  Dart_Port port2 = PortMap::CreatePort();
  EXPECT(PortMapTestPeer::IsActivePort(port1));
  EXPECT(PortMapTestPeer::IsActivePort(port2));

  // Close all ports at once.
  PortMap::ClosePorts();
  EXPECT(!PortMapTestPeer::IsActivePort(port1));
  EXPECT(!PortMapTestPeer::IsActivePort(port2));

  // Embedder is notified to close all ports as well.
  EXPECT_EQ(kCloseAllPorts, saved_port);
}


TEST_CASE(PortMap_CreateManyPorts) {
  InitPortMapTest();
  for (int i = 0; i < 32; i++) {
    Dart_Port port = PortMap::CreatePort();
    EXPECT(PortMapTestPeer::IsActivePort(port));
    PortMap::ClosePort(port);
    EXPECT(!PortMapTestPeer::IsActivePort(port));
  }
}


TEST_CASE(PortMap_SetLive) {
  InitPortMapTest();
  intptr_t port = PortMap::CreatePort();
  EXPECT_NE(0, port);
  EXPECT(PortMapTestPeer::IsActivePort(port));
  EXPECT(!PortMapTestPeer::IsLivePort(port));

  PortMap::SetLive(port);
  EXPECT(PortMapTestPeer::IsActivePort(port));
  EXPECT(PortMapTestPeer::IsLivePort(port));

  PortMap::ClosePort(port);
  EXPECT(!PortMapTestPeer::IsActivePort(port));
  EXPECT(!PortMapTestPeer::IsLivePort(port));

  // Embedder was notified of port closure.
  EXPECT_EQ(port, saved_port);
}


TEST_CASE(PortMap_PostMessage) {
  InitPortMapTest();
  Dart_Port port = PortMap::CreatePort();
  EXPECT(PortMap::PostMessage(
      port, 0, reinterpret_cast<Dart_Message>(strdup("msg"))));

  // Check that the post message callback was called.
  EXPECT_STREQ("msg", saved_msg);
  PortMap::ClosePorts();
}


TEST_CASE(PortMap_PostMessageInvalidPort) {
  InitPortMapTest();
  EXPECT(!PortMap::PostMessage(
      0, 0, reinterpret_cast<Dart_Message>(strdup("msg"))));

  // Check that the post message callback was not called.
  EXPECT_STREQ("", saved_msg);
}


TEST_CASE(PortMap_PostMessageFailureInCallback) {
  InitPortMapTest();
  Dart_Port port = PortMap::CreatePort();

  // Our callback is rigged to return false when it sees the message
  // "fail".  This return value is propagated out of PostMessage.
  EXPECT(!PortMap::PostMessage(
      port, 0, reinterpret_cast<Dart_Message>(strdup("fail"))));

  // Check that the post message callback was called.
  EXPECT_STREQ("fail", saved_msg);
  PortMap::ClosePorts();
}


// End-of-test marker.
static const intptr_t kEOT = 0xFFFF;

void* AllocIntData(intptr_t payload) {
  intptr_t* result = reinterpret_cast<intptr_t*>(malloc(sizeof(payload)));
  *result = payload;
  return result;
}


intptr_t GetIntData(void* data) {
  return *reinterpret_cast<intptr_t*>(data);
}


static PortMessage* NextMessage() {
  Isolate* isolate = Isolate::Current();
  PortMessage* result = isolate->message_queue()->Dequeue(0);
  return result;
}


void ThreadedPort_start(uword parameter) {
  // We only need an isolate here because the MutexLocker in
  // PortMap::CreatePort expects it, we don't need to initialize
  // the isolate as it does not run any dart code.
  Dart::CreateIsolate();

  intptr_t remote = parameter;
  intptr_t local = PortMap::CreatePort();

  PortMap::PostMessage(remote, 0, AllocIntData(local));

  intptr_t count = 0;
  while (true) {
    PortMessage* msg = NextMessage();
    EXPECT_EQ(local, msg->dest_port());
    EXPECT(msg != NULL);
    if (GetIntData(msg->data()) == kEOT) {
      break;
    }
    EXPECT(GetIntData(msg->data()) == count);
    delete msg;
    PortMap::PostMessage(remote, 0, AllocIntData(count * 2));
    count++;
  }
  PortMap::PostMessage(remote, 0, AllocIntData(kEOT));

  Dart::ShutdownIsolate();
}


TEST_CASE(ThreadedPort) {
  intptr_t local = PortMap::CreatePort();

  Thread* thr = new Thread(ThreadedPort_start, local);
  EXPECT(thr != NULL);

  PortMessage* msg = NextMessage();
  EXPECT_EQ(local, msg->dest_port());
  EXPECT(msg != NULL);
  intptr_t remote = GetIntData(msg->data());  // Get the remote port.
  delete msg;

  for (intptr_t i = 0; i < 10; i++) {
    PortMap::PostMessage(remote, 0, AllocIntData(i));
    PortMessage* msg = NextMessage();
    EXPECT_EQ(local, msg->dest_port());
    EXPECT(msg != NULL);
    EXPECT_EQ(i * 2, GetIntData(msg->data()));
    delete msg;
  }

  PortMap::PostMessage(remote, 0, AllocIntData(kEOT));
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
