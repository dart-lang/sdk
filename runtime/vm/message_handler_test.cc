// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/message_handler.h"
#include "vm/unit_test.h"

namespace dart {

class MessageHandlerTestPeer {
 public:
  explicit MessageHandlerTestPeer(MessageHandler* handler)
      : handler_(handler) {}

  void PostMessage(Message* message) { handler_->PostMessage(message); }
  void ClosePort(Dart_Port port) { handler_->ClosePort(port); }
  void CloseAllPorts() { handler_->CloseAllPorts(); }

  void increment_live_ports() { handler_->increment_live_ports(); }
  void decrement_live_ports() { handler_->decrement_live_ports(); }

  MessageQueue* queue() const { return handler_->queue_; }
  MessageQueue* oob_queue() const { return handler_->oob_queue_; }

 private:
  MessageHandler* handler_;

  DISALLOW_COPY_AND_ASSIGN(MessageHandlerTestPeer);
};


class TestMessageHandler : public MessageHandler {
 public:
  TestMessageHandler()
      : port_buffer_(strdup("")),
        notify_count_(0),
        message_count_(0),
        result_(true) {
  }

  ~TestMessageHandler() {
    free(port_buffer_);
  }

  void MessageNotify(Message::Priority priority) {
    notify_count_++;
  }

  bool HandleMessage(Message* message) {
    // For testing purposes, keep a string with a list of the ports
    // for all messages we receive.
    intptr_t len =
        OS::SNPrint(NULL, 0, "%s %"Pd64"",
                    port_buffer_,
                    message->dest_port()) + 1;
    char* buffer = reinterpret_cast<char*>(malloc(len));
    OS::SNPrint(buffer, len, "%s %"Pd64"",
                port_buffer_,
                message->dest_port());
    free(port_buffer_);
    port_buffer_ = buffer;
    delete message;
    message_count_++;
    return result_;
  }


  bool Start() {
    intptr_t len =
        OS::SNPrint(NULL, 0, "%s start", port_buffer_) + 1;
    char* buffer = reinterpret_cast<char*>(malloc(len));
    OS::SNPrint(buffer, len, "%s start", port_buffer_);
    free(port_buffer_);
    port_buffer_ = buffer;
    return true;
  }


  void End() {
    intptr_t len =
        OS::SNPrint(NULL, 0, "%s end", port_buffer_) + 1;
    char* buffer = reinterpret_cast<char*>(malloc(len));
    OS::SNPrint(buffer, len, "%s end", port_buffer_);
    free(port_buffer_);
    port_buffer_ = buffer;
  }


  const char* port_buffer() const { return port_buffer_; }
  int notify_count() const { return notify_count_; }
  int message_count() const { return message_count_; }

  void set_result(bool result) { result_ = result; }

 private:
  char* port_buffer_;
  int notify_count_;
  int message_count_;
  bool result_;

  DISALLOW_COPY_AND_ASSIGN(TestMessageHandler);
};


bool TestStartFunction(uword data) {
  return (reinterpret_cast<TestMessageHandler*>(data))->Start();
}


void TestEndFunction(uword data) {
  return (reinterpret_cast<TestMessageHandler*>(data))->End();
}


UNIT_TEST_CASE(MessageHandler_PostMessage) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  EXPECT_EQ(0, handler.notify_count());

  // Post a message.
  Message* message = new Message(0, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message);

  // The notify callback is called.
  EXPECT_EQ(1, handler.notify_count());

  // The message has been added to the correct queue.
  EXPECT(message == handler_peer.queue()->Dequeue());
  EXPECT(NULL == handler_peer.oob_queue()->Dequeue());
  delete message;

  // Post an oob message.
  message = new Message(0, 0, NULL, 0, Message::kOOBPriority);
  handler_peer.PostMessage(message);

  // The notify callback is called.
  EXPECT_EQ(2, handler.notify_count());

  // The message has been added to the correct queue.
  EXPECT(message == handler_peer.oob_queue()->Dequeue());
  EXPECT(NULL == handler_peer.queue()->Dequeue());
  delete message;
}


UNIT_TEST_CASE(MessageHandler_ClosePort) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Message* message1 = new Message(1, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message1);
  Message* message2 = new Message(2, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message2);

  handler_peer.ClosePort(1);

  // The message on port 1 is dropped from the queue.
  EXPECT(message2 == handler_peer.queue()->Dequeue());
  EXPECT(NULL == handler_peer.queue()->Dequeue());
  delete message2;
}


UNIT_TEST_CASE(MessageHandler_CloseAllPorts) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Message* message1 = new Message(1, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message1);
  Message* message2 = new Message(2, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message2);

  handler_peer.CloseAllPorts();

  // All messages are dropped from the queue.
  EXPECT(NULL == handler_peer.queue()->Dequeue());
}


UNIT_TEST_CASE(MessageHandler_HandleNextMessage) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Message* message1 = new Message(1, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message1);
  Message* oob_message1 = new Message(3, 0, NULL, 0, Message::kOOBPriority);
  handler_peer.PostMessage(oob_message1);
  Message* message2 = new Message(2, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message2);
  Message* oob_message2 = new Message(4, 0, NULL, 0, Message::kOOBPriority);
  handler_peer.PostMessage(oob_message2);

  // We handle both oob messages and a single normal message.
  EXPECT(handler.HandleNextMessage());
  EXPECT_STREQ(" 3 4 1", handler.port_buffer());
  handler_peer.CloseAllPorts();
}


UNIT_TEST_CASE(MessageHandler_HandleOOBMessages) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Message* message1 = new Message(1, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message1);
  Message* message2 = new Message(2, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message2);
  Message* oob_message1 = new Message(3, 0, NULL, 0, Message::kOOBPriority);
  handler_peer.PostMessage(oob_message1);
  Message* oob_message2 = new Message(4, 0, NULL, 0, Message::kOOBPriority);
  handler_peer.PostMessage(oob_message2);

  // We handle both oob messages but no normal messages.
  EXPECT(handler.HandleOOBMessages());
  EXPECT_STREQ(" 3 4", handler.port_buffer());
  handler_peer.CloseAllPorts();
}


struct ThreadStartInfo {
  MessageHandler* handler;
  int count;
};


static void SendMessages(uword param) {
  ThreadStartInfo* info = reinterpret_cast<ThreadStartInfo*>(param);
  MessageHandler* handler = info->handler;
  MessageHandlerTestPeer handler_peer(handler);
  for (int i = 0; i < info->count; i++) {
    Message* message = new Message(i + 1, 0, NULL, 0, Message::kNormalPriority);
    handler_peer.PostMessage(message);
  }
}


UNIT_TEST_CASE(MessageHandler_Run) {
  ThreadPool pool;
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  int sleep = 0;
  const int kMaxSleep = 20 * 1000;  // 20 seconds.

  EXPECT(!handler.HasLivePorts());
  handler_peer.increment_live_ports();

  handler.Run(&pool,
              TestStartFunction,
              TestEndFunction,
              reinterpret_cast<uword>(&handler));
  Message* message = new Message(100, 0, NULL, 0, Message::kNormalPriority);
  handler_peer.PostMessage(message);

  // Wait for the first message to be handled.
  while (sleep < kMaxSleep && handler.message_count() < 1) {
    OS::Sleep(10);
    sleep += 10;
  }
  EXPECT_STREQ(" start 100", handler.port_buffer());

  // Start a thread which sends more messages.
  ThreadStartInfo info;
  info.handler = &handler;
  info.count = 10;
  Thread::Start(SendMessages, reinterpret_cast<uword>(&info));
  while (sleep < kMaxSleep && handler.message_count() < 11) {
    OS::Sleep(10);
    sleep += 10;
  }
  EXPECT_STREQ(" start 100 1 2 3 4 5 6 7 8 9 10", handler.port_buffer());

  handler_peer.decrement_live_ports();
  EXPECT(!handler.HasLivePorts());
}

}  // namespace dart
