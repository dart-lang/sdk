// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/message.h"
#include "vm/unit_test.h"

namespace dart {


static uint8_t* AllocMsg(const char* str) {
  return reinterpret_cast<uint8_t*>(strdup(str));
}


TEST_CASE(MessageQueue_BasicOperations) {
  MessageQueue queue;
  EXPECT(queue.IsEmpty());

  Dart_Port port = 1;

  const char* str1 = "msg1";
  const char* str2 = "msg2";
  const char* str3 = "msg3";
  const char* str4 = "msg4";
  const char* str5 = "msg5";
  const char* str6 = "msg6";

  // Add two messages.
  Message* msg1 = new Message(
      port, AllocMsg(str1), strlen(str1) + 1, Message::kNormalPriority);
  queue.Enqueue(msg1, false);
  EXPECT(!queue.IsEmpty());

  Message* msg2 = new Message(
      port, AllocMsg(str2), strlen(str2) + 1, Message::kNormalPriority);
  queue.Enqueue(msg2, false);
  EXPECT(!queue.IsEmpty());

  // Remove two messages.
  Message* msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str1, reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str2, reinterpret_cast<char*>(msg->data()));
  EXPECT(queue.IsEmpty());

  Message* msg3 = new Message(Message::kIllegalPort,
                              AllocMsg(str3), strlen(str3) + 1,
                              Message::kNormalPriority);
  queue.Enqueue(msg3, true);
  EXPECT(!queue.IsEmpty());

  Message* msg4 = new Message(Message::kIllegalPort,
                              AllocMsg(str4), strlen(str4) + 1,
                              Message::kNormalPriority);
  queue.Enqueue(msg4, true);
  EXPECT(!queue.IsEmpty());

  Message* msg5 = new Message(
      port, AllocMsg(str5), strlen(str5) + 1, Message::kNormalPriority);
  queue.Enqueue(msg5, false);
  EXPECT(!queue.IsEmpty());

  Message* msg6 = new Message(Message::kIllegalPort,
                              AllocMsg(str6), strlen(str6) + 1,
                              Message::kNormalPriority);
  queue.Enqueue(msg6, true);
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str3, reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str4, reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str6, reinterpret_cast<char*>(msg->data()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != NULL);
  EXPECT_STREQ(str5, reinterpret_cast<char*>(msg->data()));
  EXPECT(queue.IsEmpty());

  delete msg1;
  delete msg2;
  delete msg3;
  delete msg4;
  delete msg5;
  delete msg6;
}


TEST_CASE(MessageQueue_Clear) {
  MessageQueue queue;
  Dart_Port port1 = 1;
  Dart_Port port2 = 2;

  const char* str1 = "msg1";
  const char* str2 = "msg2";

  // Add two messages.
  Message* msg1 =
      new Message(port1, AllocMsg(str1), strlen(str1) + 1,
                  Message::kNormalPriority);
  queue.Enqueue(msg1, false);
  Message* msg2 =
      new Message(port2, AllocMsg(str2), strlen(str2) + 1,
                  Message::kNormalPriority);
  queue.Enqueue(msg2, false);

  EXPECT(!queue.IsEmpty());
  queue.Clear();
  EXPECT(queue.IsEmpty());

  // msg1 and msg2 already delete by FlushAll.
}

}  // namespace dart
