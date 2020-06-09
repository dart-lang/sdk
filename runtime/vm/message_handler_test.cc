// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/message_handler.h"
#include "vm/port.h"
#include "vm/unit_test.h"

namespace dart {

class MessageHandlerTestPeer {
 public:
  explicit MessageHandlerTestPeer(MessageHandler* handler)
      : handler_(handler) {}

  void PostMessage(std::unique_ptr<Message> message) {
    handler_->PostMessage(std::move(message));
  }
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
      : port_buffer_(NULL),
        port_buffer_size_(0),
        notify_count_(0),
        message_count_(0),
        start_called_(false),
        end_called_(false),
        results_(NULL),
        monitor_() {}

  ~TestMessageHandler() {
    PortMap::ClosePorts(this);
    delete[] port_buffer_;
  }

  void MessageNotify(Message::Priority priority) {
    MonitorLocker ml(&monitor_);
    notify_count_++;
    ml.Notify();
  }

  MessageStatus HandleMessage(std::unique_ptr<Message> message) {
    // For testing purposes, keep a list of the ports
    // for all messages we receive.
    MonitorLocker ml(&monitor_);
    AddPortToBuffer(message->dest_port());
    message_count_++;
    MessageStatus status = kOK;
    if (results_ != NULL) {
      status = results_[0];
      results_++;
    }
    ml.Notify();
    return status;
  }

  MessageStatus Start() {
    start_called_ = true;
    return kOK;
  }

  void End() {
    MonitorLocker ml(&monitor_);
    end_called_ = true;
    AddPortToBuffer(-2);
    ml.Notify();
  }

  Dart_Port* port_buffer() const { return port_buffer_; }
  int notify_count() const { return notify_count_; }
  int message_count() const { return message_count_; }
  bool start_called() const { return start_called_; }
  bool end_called() const { return end_called_; }

  void set_results(MessageStatus* results) { results_ = results; }

  Monitor* monitor() { return &monitor_; }

 private:
  void AddPortToBuffer(Dart_Port port) {
    if (port_buffer_ == NULL) {
      port_buffer_ = new Dart_Port[10];
      port_buffer_size_ = 10;
    } else if (message_count_ == port_buffer_size_) {
      int new_port_buffer_size_ = 2 * port_buffer_size_;
      Dart_Port* new_port_buffer_ = new Dart_Port[new_port_buffer_size_];
      for (int i = 0; i < port_buffer_size_; i++) {
        new_port_buffer_[i] = port_buffer_[i];
      }
      delete[] port_buffer_;
      port_buffer_ = new_port_buffer_;
      port_buffer_size_ = new_port_buffer_size_;
    }
    port_buffer_[message_count_] = port;
  }

  Dart_Port* port_buffer_;
  int port_buffer_size_;
  int notify_count_;
  int message_count_;
  bool start_called_;
  bool end_called_;
  MessageStatus* results_;
  Monitor monitor_;

  DISALLOW_COPY_AND_ASSIGN(TestMessageHandler);
};

MessageHandler::MessageStatus TestStartFunction(uword data) {
  return (reinterpret_cast<TestMessageHandler*>(data))->Start();
}

void TestEndFunction(uword data) {
  return (reinterpret_cast<TestMessageHandler*>(data))->End();
}

static std::unique_ptr<Message> BlankMessage(Dart_Port dest,
                                             Message::Priority priority) {
  return Message::New(dest, reinterpret_cast<uint8_t*>(malloc(1)), 1, nullptr,
                      priority);
}

VM_UNIT_TEST_CASE(MessageHandler_PostMessage) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  EXPECT_EQ(0, handler.notify_count());

  // Post a message.
  std::unique_ptr<Message> message = BlankMessage(1, Message::kNormalPriority);
  Message* raw_message = message.get();
  handler_peer.PostMessage(std::move(message));

  // The notify callback is called.
  EXPECT_EQ(1, handler.notify_count());

  // The message has been added to the correct queue.
  EXPECT(raw_message == handler_peer.queue()->Dequeue().get());
  EXPECT(nullptr == handler_peer.oob_queue()->Dequeue());

  // Post an oob message.
  message = BlankMessage(1, Message::kOOBPriority);
  raw_message = message.get();
  handler_peer.PostMessage(std::move(message));

  // The notify callback is called.
  EXPECT_EQ(2, handler.notify_count());

  // The message has been added to the correct queue.
  EXPECT(raw_message == handler_peer.oob_queue()->Dequeue().get());
  EXPECT(nullptr == handler_peer.queue()->Dequeue());
}

VM_UNIT_TEST_CASE(MessageHandler_HasOOBMessages) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);

  EXPECT(!handler.HasOOBMessages());

  // Post a normal message.
  std::unique_ptr<Message> message = BlankMessage(1, Message::kNormalPriority);
  handler_peer.PostMessage(std::move(message));
  EXPECT(!handler.HasOOBMessages());
  {
    // Acquire ownership of message handler queues, verify one regular message.
    MessageHandler::AcquiredQueues aq(&handler);
    EXPECT(aq.queue()->Length() == 1);
  }

  // Post an oob message.
  message = BlankMessage(1, Message::kOOBPriority);
  handler_peer.PostMessage(std::move(message));
  EXPECT(handler.HasOOBMessages());
  {
    // Acquire ownership of message handler queues, verify one regular and one
    // OOB message.
    MessageHandler::AcquiredQueues aq(&handler);
    EXPECT(aq.queue()->Length() == 1);
    EXPECT(aq.oob_queue()->Length() == 1);
  }

  // Delete all pending messages.
  handler_peer.CloseAllPorts();
}

VM_UNIT_TEST_CASE(MessageHandler_ClosePort) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  std::unique_ptr<Message> message;
  message = BlankMessage(1, Message::kNormalPriority);
  Message* raw_message1 = message.get();
  handler_peer.PostMessage(std::move(message));
  message = BlankMessage(2, Message::kNormalPriority);
  Message* raw_message2 = message.get();
  handler_peer.PostMessage(std::move(message));

  handler_peer.ClosePort(1);

  // Closing the port does not drop the messages from the queue.
  EXPECT(raw_message1 == handler_peer.queue()->Dequeue().get());
  EXPECT(raw_message2 == handler_peer.queue()->Dequeue().get());
}

VM_UNIT_TEST_CASE(MessageHandler_CloseAllPorts) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  handler_peer.PostMessage(BlankMessage(1, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(2, Message::kNormalPriority));

  handler_peer.CloseAllPorts();

  // All messages are dropped from the queue.
  EXPECT(nullptr == handler_peer.queue()->Dequeue());
}

VM_UNIT_TEST_CASE(MessageHandler_HandleNextMessage) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  Dart_Port port3 = PortMap::CreatePort(&handler);
  handler_peer.PostMessage(BlankMessage(port1, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port2, Message::kOOBPriority));
  handler_peer.PostMessage(BlankMessage(port2, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port3, Message::kOOBPriority));

  // We handle both oob messages and a single normal message.
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_EQ(3, handler.message_count());
  Dart_Port* ports = handler.port_buffer();
  EXPECT_EQ(port2, ports[0]);
  EXPECT_EQ(port3, ports[1]);
  EXPECT_EQ(port1, ports[2]);
}

VM_UNIT_TEST_CASE(MessageHandler_HandleNextMessage_ProcessOOBAfterError) {
  TestMessageHandler handler;
  MessageHandler::MessageStatus results[] = {
      MessageHandler::kError,  // oob_message1
      MessageHandler::kOK,     // oob_message2
      MessageHandler::kOK,     // unused
  };
  handler.set_results(results);
  MessageHandlerTestPeer handler_peer(&handler);
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  Dart_Port port3 = PortMap::CreatePort(&handler);
  handler_peer.PostMessage(BlankMessage(port1, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port2, Message::kOOBPriority));
  handler_peer.PostMessage(BlankMessage(port3, Message::kOOBPriority));

  // When we get an error, we continue processing oob messages but
  // stop handling normal messages.
  EXPECT_EQ(MessageHandler::kError, handler.HandleNextMessage());
  EXPECT_EQ(2, handler.message_count());
  Dart_Port* ports = handler.port_buffer();
  EXPECT_EQ(port2, ports[0]);  // oob_message1, error
  EXPECT_EQ(port3, ports[1]);  // oob_message2, ok
  handler_peer.CloseAllPorts();
}

VM_UNIT_TEST_CASE(MessageHandler_HandleNextMessage_Shutdown) {
  TestMessageHandler handler;
  MessageHandler::MessageStatus results[] = {
      MessageHandler::kOK,        // oob_message1
      MessageHandler::kShutdown,  // oob_message2
      MessageHandler::kOK,        // unused
      MessageHandler::kOK,        // unused
  };
  handler.set_results(results);
  MessageHandlerTestPeer handler_peer(&handler);
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  Dart_Port port3 = PortMap::CreatePort(&handler);
  Dart_Port port4 = PortMap::CreatePort(&handler);
  handler_peer.PostMessage(BlankMessage(port1, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port2, Message::kOOBPriority));
  handler_peer.PostMessage(BlankMessage(port3, Message::kOOBPriority));
  handler_peer.PostMessage(BlankMessage(port4, Message::kOOBPriority));

  // When we get a shutdown message, we stop processing all messages.
  EXPECT_EQ(MessageHandler::kShutdown, handler.HandleNextMessage());
  EXPECT_EQ(2, handler.message_count());
  Dart_Port* ports = handler.port_buffer();
  EXPECT_EQ(port2, ports[0]);  // oob_message1, ok
  EXPECT_EQ(port3, ports[1]);  // oob_message2, shutdown
  {
    // The oob queue has been cleared.  oob_message3 is gone.
    MessageHandler::AcquiredQueues aq(&handler);
    EXPECT(aq.oob_queue()->Length() == 0);
  }
  handler_peer.CloseAllPorts();
}

VM_UNIT_TEST_CASE(MessageHandler_HandleOOBMessages) {
  TestMessageHandler handler;
  MessageHandlerTestPeer handler_peer(&handler);
  Dart_Port port1 = PortMap::CreatePort(&handler);
  Dart_Port port2 = PortMap::CreatePort(&handler);
  Dart_Port port3 = PortMap::CreatePort(&handler);
  Dart_Port port4 = PortMap::CreatePort(&handler);
  handler_peer.PostMessage(BlankMessage(port1, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port2, Message::kNormalPriority));
  handler_peer.PostMessage(BlankMessage(port3, Message::kOOBPriority));
  handler_peer.PostMessage(BlankMessage(port4, Message::kOOBPriority));

  // We handle both oob messages but no normal messages.
  EXPECT_EQ(MessageHandler::kOK, handler.HandleOOBMessages());
  EXPECT_EQ(2, handler.message_count());
  Dart_Port* ports = handler.port_buffer();
  EXPECT_EQ(port3, ports[0]);
  EXPECT_EQ(port4, ports[1]);
  handler_peer.CloseAllPorts();
}

struct ThreadStartInfo {
  MessageHandler* handler;
  Dart_Port* ports;
  int count;
  ThreadJoinId join_id;
};

static void SendMessages(uword param) {
  ThreadStartInfo* info = reinterpret_cast<ThreadStartInfo*>(param);
  info->join_id = OSThread::GetCurrentThreadJoinId(OSThread::Current());
  MessageHandler* handler = info->handler;
  MessageHandlerTestPeer handler_peer(handler);
  for (int i = 0; i < info->count; i++) {
    handler_peer.PostMessage(
        BlankMessage(info->ports[i], Message::kNormalPriority));
  }
}

VM_UNIT_TEST_CASE(MessageHandler_Run) {
  TestMessageHandler handler;
  ThreadPool pool;
  MessageHandlerTestPeer handler_peer(&handler);

  EXPECT(!handler.HasLivePorts());
  handler_peer.increment_live_ports();

  handler.Run(&pool, TestStartFunction, TestEndFunction,
              reinterpret_cast<uword>(&handler));
  Dart_Port port = PortMap::CreatePort(&handler);
  handler_peer.PostMessage(BlankMessage(port, Message::kNormalPriority));

  // Wait for the first message to be handled.
  {
    MonitorLocker ml(handler.monitor());
    while (handler.message_count() < 1) {
      ml.Wait();
    }
    EXPECT_EQ(1, handler.message_count());
    EXPECT(handler.start_called());
    EXPECT(!handler.end_called());
    Dart_Port* handler_ports = handler.port_buffer();
    EXPECT_EQ(port, handler_ports[0]);
  }

  // Start a thread which sends more messages.
  Dart_Port ports[10];
  for (int i = 0; i < 10; i++) {
    ports[i] = PortMap::CreatePort(&handler);
  }
  ThreadStartInfo info;
  info.handler = &handler;
  info.ports = ports;
  info.count = 10;
  info.join_id = OSThread::kInvalidThreadJoinId;
  OSThread::Start("SendMessages", SendMessages, reinterpret_cast<uword>(&info));

  // Wait for the messages to be handled.
  {
    MonitorLocker ml(handler.monitor());
    while (handler.message_count() < 11) {
      ml.Wait();
    }
    Dart_Port* handler_ports = handler.port_buffer();
    EXPECT_EQ(11, handler.message_count());
    EXPECT(handler.start_called());
    EXPECT(!handler.end_called());
    EXPECT_EQ(port, handler_ports[0]);
    for (int i = 1; i < 11; i++) {
      EXPECT_EQ(ports[i - 1], handler_ports[i]);
    }
    handler_peer.decrement_live_ports();
    EXPECT(!handler.HasLivePorts());
  }

  // Must join the thread or the VM shutdown is racing with any VM state the
  // thread touched.
  ASSERT(info.join_id != OSThread::kInvalidThreadJoinId);
  OSThread::Join(info.join_id);
}

}  // namespace dart
