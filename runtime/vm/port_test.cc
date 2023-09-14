// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/port.h"
#include "platform/assert.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/os.h"
#include "vm/unit_test.h"

namespace dart {

class PortTestMessageHandler : public MessageHandler {
 public:
  PortTestMessageHandler() : notify_count(0) {}

  void MessageNotify(Message::Priority priority) { notify_count++; }

  MessageStatus HandleMessage(std::unique_ptr<Message> message) { return kOK; }

  int notify_count;
};

TEST_CASE(PortMap_CreateAndCloseOnePort) {
  PortTestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  EXPECT_NE(0, port);
  EXPECT(PortMap::PortExists(port));

  PortMap::ClosePort(port);
  EXPECT(!PortMap::PortExists(port));
}

TEST_CASE(PortMap_CreateAndCloseTwoPorts) {
  PortTestMessageHandler handler;
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  EXPECT(PortMap::PortExists(port1));
  EXPECT(PortMap::PortExists(port2));

  // Uniqueness.
  EXPECT_NE(port1, port2);

  PortMap::ClosePort(port1);
  EXPECT(!PortMap::PortExists(port1));
  EXPECT(PortMap::PortExists(port2));

  PortMap::ClosePort(port2);
  EXPECT(!PortMap::PortExists(port1));
  EXPECT(!PortMap::PortExists(port2));
}

TEST_CASE(PortMap_ClosePorts) {
  PortTestMessageHandler handler;
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  EXPECT(PortMap::PortExists(port1));
  EXPECT(PortMap::PortExists(port2));

  // Close all ports at once.
  PortMap::ClosePorts(&handler);
  EXPECT(!PortMap::PortExists(port1));
  EXPECT(!PortMap::PortExists(port2));
}

TEST_CASE(PortMap_CreateManyPorts) {
  PortTestMessageHandler handler;
  for (int i = 0; i < 32; i++) {
    Dart_Port port = PortMap::CreatePort(&handler);
    EXPECT(PortMap::PortExists(port));
    PortMap::ClosePort(port);
    EXPECT(!PortMap::PortExists(port));
  }
}

TEST_CASE(PortMap_PostMessage) {
  PortTestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  EXPECT_EQ(0, handler.notify_count);

  const char* message = "msg";
  intptr_t message_len = strlen(message) + 1;

  EXPECT(PortMap::PostMessage(
      Message::New(port, reinterpret_cast<uint8_t*>(Utils::StrDup(message)),
                   message_len, nullptr, Message::kNormalPriority)));

  // Check that the message notify callback was called.
  EXPECT_EQ(1, handler.notify_count);
  PortMap::ClosePorts(&handler);
}

TEST_CASE(PortMap_PostIntegerMessage) {
  PortTestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  EXPECT_EQ(0, handler.notify_count);

  EXPECT(PortMap::PostMessage(
      Message::New(port, Smi::New(42), Message::kNormalPriority)));

  // Check that the message notify callback was called.
  EXPECT_EQ(1, handler.notify_count);
  PortMap::ClosePorts(&handler);
}

TEST_CASE(PortMap_PostNullMessage) {
  PortTestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  EXPECT_EQ(0, handler.notify_count);

  EXPECT(PortMap::PostMessage(
      Message::New(port, Object::null(), Message::kNormalPriority)));

  // Check that the message notify callback was called.
  EXPECT_EQ(1, handler.notify_count);
  PortMap::ClosePorts(&handler);
}

TEST_CASE(PortMap_PostMessageClosedPort) {
  // Create a port id and make it invalid.
  PortTestMessageHandler handler;
  Dart_Port port = PortMap::CreatePort(&handler);
  PortMap::ClosePort(port);

  const char* message = "msg";
  intptr_t message_len = strlen(message) + 1;

  EXPECT(!PortMap::PostMessage(
      Message::New(port, reinterpret_cast<uint8_t*>(Utils::StrDup(message)),
                   message_len, nullptr, Message::kNormalPriority)));
}

}  // namespace dart
