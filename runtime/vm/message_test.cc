// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

static uint8_t* AllocMsg(const char* str) {
  return reinterpret_cast<uint8_t*>(Utils::StrDup(str));
}

TEST_CASE(MessageQueue_BasicOperations) {
  MessageQueue queue;
  EXPECT(queue.IsEmpty());
  MessageQueue::Iterator it(&queue);
  // Queue is empty.
  EXPECT(!it.HasNext());

  Dart_Port port = 1;

  const char* str1 = "msg1";
  const char* str2 = "msg2";
  const char* str3 = "msg3";
  const char* str4 = "msg4";
  const char* str5 = "msg5";
  const char* str6 = "msg6";

  // Add two messages.
  std::unique_ptr<Message> msg =
      Message::New(port, AllocMsg(str1), strlen(str1) + 1, nullptr,
                   Message::kNormalPriority);
  Message* msg1 = msg.get();
  queue.Enqueue(std::move(msg), false);
  EXPECT(queue.Length() == 1);
  EXPECT(!queue.IsEmpty());
  it.Reset(&queue);
  EXPECT(it.HasNext());
  EXPECT(it.Next() == msg1);
  EXPECT(!it.HasNext());

  msg = Message::New(port, AllocMsg(str2), strlen(str2) + 1, nullptr,
                     Message::kNormalPriority);
  Message* msg2 = msg.get();
  queue.Enqueue(std::move(msg), false);
  EXPECT(queue.Length() == 2);
  EXPECT(!queue.IsEmpty());
  it.Reset(&queue);
  EXPECT(it.HasNext());
  EXPECT(it.Next() == msg1);
  EXPECT(it.HasNext());
  EXPECT(it.Next() == msg2);
  EXPECT(!it.HasNext());

  // Lookup messages by id.
  EXPECT(queue.FindMessageById(reinterpret_cast<intptr_t>(msg1)) == msg1);
  EXPECT(queue.FindMessageById(reinterpret_cast<intptr_t>(msg2)) == msg2);

  // Lookup bad id.
  EXPECT(queue.FindMessageById(0x1) == NULL);

  // Remove message 1
  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str1, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(!queue.IsEmpty());

  it.Reset(&queue);
  EXPECT(it.HasNext());
  EXPECT(it.Next() == msg2);

  // Remove message 2
  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str2, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(queue.IsEmpty());

  msg = Message::New(Message::kIllegalPort, AllocMsg(str3), strlen(str3) + 1,
                     nullptr, Message::kNormalPriority);
  queue.Enqueue(std::move(msg), true);
  EXPECT(!queue.IsEmpty());

  msg = Message::New(Message::kIllegalPort, AllocMsg(str4), strlen(str4) + 1,
                     nullptr, Message::kNormalPriority);
  queue.Enqueue(std::move(msg), true);
  EXPECT(!queue.IsEmpty());

  msg = Message::New(port, AllocMsg(str5), strlen(str5) + 1, nullptr,
                     Message::kNormalPriority);
  queue.Enqueue(std::move(msg), false);
  EXPECT(!queue.IsEmpty());

  msg = Message::New(Message::kIllegalPort, AllocMsg(str6), strlen(str6) + 1,
                     nullptr, Message::kNormalPriority);
  queue.Enqueue(std::move(msg), true);
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str3, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str4, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str6, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(!queue.IsEmpty());

  msg = queue.Dequeue();
  EXPECT(msg != nullptr);
  EXPECT_STREQ(str5, reinterpret_cast<char*>(msg->snapshot()));
  EXPECT(queue.IsEmpty());
}

TEST_CASE(MessageQueue_Clear) {
  MessageQueue queue;
  Dart_Port port1 = 1;
  Dart_Port port2 = 2;

  const char* str1 = "msg1";
  const char* str2 = "msg2";

  // Add two messages.
  std::unique_ptr<Message> msg;
  msg = Message::New(port1, AllocMsg(str1), strlen(str1) + 1, nullptr,
                     Message::kNormalPriority);
  queue.Enqueue(std::move(msg), false);
  msg = Message::New(port2, AllocMsg(str2), strlen(str2) + 1, nullptr,
                     Message::kNormalPriority);
  queue.Enqueue(std::move(msg), false);

  EXPECT(!queue.IsEmpty());
  queue.Clear();
  EXPECT(queue.IsEmpty());
}

}  // namespace dart
