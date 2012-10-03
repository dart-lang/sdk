// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dbg_connection.h"
#include "bin/dbg_message.h"
#include "bin/dartutils.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/json.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"


int DebuggerConnectionHandler::listener_fd_ = -1;
dart::Monitor DebuggerConnectionHandler::handler_lock_;

// TODO(asiva): Remove this once we have support for multiple debugger
// connections. For now we just store the single debugger connection
// handler in a static variable.
static DebuggerConnectionHandler* singleton_handler = NULL;


class MessageBuffer {
 public:
  explicit MessageBuffer(int fd);
  ~MessageBuffer();
  void ReadData();
  bool IsValidMessage() const;
  void PopMessage();
  int MessageId() const;
  char* buf() const { return buf_; }
  bool Alive() const { return connection_is_alive_; }

 private:
  static const int kInitialBufferSize = 256;
  char* buf_;
  int buf_length_;
  int fd_;
  int data_length_;
  bool connection_is_alive_;

  DISALLOW_COPY_AND_ASSIGN(MessageBuffer);
};


MessageBuffer::MessageBuffer(int fd)
    :  buf_(NULL),
       buf_length_(0),
       fd_(fd),
       data_length_(0),
       connection_is_alive_(true) {
  buf_ = reinterpret_cast<char*>(malloc(kInitialBufferSize));
  if (buf_ == NULL) {
    FATAL("Failed to allocate message buffer\n");
  }
  buf_length_ = kInitialBufferSize;
  buf_[0] = '\0';
  data_length_ = 0;
}


MessageBuffer::~MessageBuffer() {
  free(buf_);
  buf_ = NULL;
  fd_ = -1;
}


bool MessageBuffer::IsValidMessage() const {
  if (data_length_ == 0) {
    return false;
  }
  dart::JSONReader msg_reader(buf_);
  return msg_reader.EndOfObject() != NULL;
}


int MessageBuffer::MessageId() const {
  dart::JSONReader r(buf_);
  r.Seek("id");
  if (r.Type() == dart::JSONReader::kInteger) {
    return atoi(r.ValueChars());
  } else {
    return -1;
  }
}


void MessageBuffer::ReadData() {
  ASSERT(data_length_ >= 0);
  ASSERT(data_length_ < buf_length_);
  int max_read = buf_length_ - data_length_ - 1;
  if (max_read == 0) {
    // TODO(hausner):
    // Buffer is full. What should we do if there is no valid message
    // in the buffer? This might be possible if the client sends a message
    // that's larger than the buffer, of if the client sends malformed
    // messages that keep piling up.
    ASSERT(IsValidMessage());
    return;
  }
  // TODO(hausner): Handle error conditions returned by Read. We may
  // want to close the debugger connection if we get any errors.
  int bytes_read = Socket::Read(fd_, buf_ + data_length_, max_read);
  if (bytes_read == 0) {
    connection_is_alive_ = false;
    return;
  }
  ASSERT(bytes_read > 0);
  data_length_ += bytes_read;
  ASSERT(data_length_ < buf_length_);
  buf_[data_length_] = '\0';
}


void MessageBuffer::PopMessage() {
  dart::JSONReader msg_reader(buf_);
  const char* end = msg_reader.EndOfObject();
  if (end != NULL) {
    ASSERT(*end == '}');
    end++;
    data_length_ = 0;
    while (*end != '\0') {
      buf_[data_length_] = *end++;
      data_length_++;
    }
    buf_[data_length_] = '\0';
    ASSERT(data_length_ < buf_length_);
  }
}


static bool IsValidJSON(const char* msg) {
  dart::JSONReader r(msg);
  return r.EndOfObject() != NULL;
}


DebuggerConnectionHandler::DebuggerConnectionHandler(int debug_fd)
    : debug_fd_(debug_fd), msgbuf_(NULL) {
  msgbuf_ = new MessageBuffer(debug_fd_);
}


DebuggerConnectionHandler::~DebuggerConnectionHandler() {
  CloseDbgConnection();
  DebuggerConnectionHandler::RemoveDebuggerConnection(debug_fd_);
}


int DebuggerConnectionHandler::MessageId() {
  ASSERT(msgbuf_ != NULL);
  return msgbuf_->MessageId();
}


void DebuggerConnectionHandler::HandleUnknownMsg() {
  int msg_id = msgbuf_->MessageId();
  ASSERT(msg_id >= 0);
  SendError(debug_fd_, msg_id, "unknown debugger command");
}


typedef void (*CommandHandler)(DebuggerConnectionHandler* handler);

struct JSONDebuggerCommand {
  const char* cmd_string;
  CommandHandler handler_function;
};


void DebuggerConnectionHandler::HandleMessages() {
  static JSONDebuggerCommand generic_debugger_commands[] = {
    { "interrupt", HandleInterruptCmd },
    { "isolates", HandleIsolatesListCmd },
    { "quit", HandleQuitCmd },
    { NULL, NULL }
  };

  for (;;) {
    // Read a message.
    while (!msgbuf_->IsValidMessage() && msgbuf_->Alive()) {
      msgbuf_->ReadData();
    }
    if (!msgbuf_->Alive()) {
      return;
    }

    // Parse out the command portion from the message.
    dart::JSONReader r(msgbuf_->buf());
    bool found = r.Seek("command");
    if (r.Error()) {
      FATAL("Illegal JSON message received");
    }
    if (!found) {
      printf("'command' not found in JSON message: '%s'\n", msgbuf_->buf());
      msgbuf_->PopMessage();
    }

    // Check if this is a generic command (not isolate specific).
    int i = 0;
    bool is_handled = false;
    while (generic_debugger_commands[i].cmd_string != NULL) {
      if (r.IsStringLiteral(generic_debugger_commands[i].cmd_string)) {
        (*generic_debugger_commands[i].handler_function)(this);
        is_handled = true;
        msgbuf_->PopMessage();
        break;
      }
      i++;
    }
    if (!is_handled) {
      // Check if this is an isolate specific command.
      int32_t cmd_idx = DbgMessageQueue::LookupIsolateCommand(r.ValueChars(),
                                                              r.ValueLen());
      if (cmd_idx != DbgMessageQueue::kInvalidCommand) {
        // Get debug message queue corresponding to isolate.
        // TODO(asiva): Need to read the isolate id, map it to the appropriate
        // isolate and pass it down to GetIsolateMessageQueue to get the
        // appropriate debug message queue.
        DbgMessageQueue* queue = DbgMessageQueue::GetIsolateMessageQueue(NULL);
        ASSERT(queue != NULL);
        queue->AddMessage(cmd_idx, msgbuf_->buf(), r.EndOfObject(), debug_fd_);
        msgbuf_->PopMessage();
        continue;
      }

      // This is an unrecognized command, report error and move on to next.
      printf("unrecognized command received: '%s'\n", msgbuf_->buf());
      HandleUnknownMsg();
      msgbuf_->PopMessage();
    }
  }
}


void DebuggerConnectionHandler::SendError(int debug_fd,
                                          int msg_id,
                                          const char* err_msg) {
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\": %d, \"error\": \"Error: %s\"}", msg_id, err_msg);
  SendMsg(debug_fd, &msg);
}


void DebuggerConnectionHandler::CloseDbgConnection() {
  if (debug_fd_ >= 0) {
    // TODO(hausner): need a Socket::Close() function.
  }
  if (msgbuf_ != NULL) {
    delete msgbuf_;
    msgbuf_ = NULL;
  }
  // TODO(hausner): Need to tell the VM debugger object to remove all
  // breakpoints.
}


void DebuggerConnectionHandler::StartHandler(const char* address,
                                             int port_number) {
  MonitorLocker ml(&handler_lock_);
  if (listener_fd_ != -1) {
    return;  // The debugger connection handler was already started.
  }

  // First setup breakpoint, exception and delayed breakpoint handlers.
  DbgMessageQueue::Initialize();

  // Now setup a listener socket and start a thread which will
  // listen, accept connections from debuggers, read and handle/dispatch
  // debugger commands received on these connections.
  ASSERT(listener_fd_ == -1);
  listener_fd_ = ServerSocket::CreateBindListen(address, port_number, 1);
  DebuggerConnectionImpl::StartHandler(port_number);
}


void DebuggerConnectionHandler::WaitForConnection() {
  MonitorLocker ml(&handler_lock_);
  while (!IsConnected()) {
    dart::Monitor::WaitResult res = ml.Wait();
    ASSERT(res == dart::Monitor::kNotified);
  }
}


void DebuggerConnectionHandler::SendMsg(int debug_fd, dart::TextBuffer* msg) {
  MonitorLocker ml(&handler_lock_);
  SendMsgHelper(debug_fd, msg);
}


void DebuggerConnectionHandler::BroadcastMsg(dart::TextBuffer* msg) {
  MonitorLocker ml(&handler_lock_);
  // TODO(asiva): Once we support connection to multiple debuggers
  // we need to send the message to all of them.
  ASSERT(singleton_handler != NULL);
  SendMsgHelper(singleton_handler->debug_fd(), msg);
}


void DebuggerConnectionHandler::SendMsgHelper(int debug_fd,
                                              dart::TextBuffer* msg) {
  ASSERT(debug_fd >= 0);
  ASSERT(IsValidJSON(msg->buf()));
  // Sending messages in short pieces can be used to stress test the
  // debugger front-end's message handling code.
  const bool send_in_pieces = false;
  if (send_in_pieces) {
    intptr_t remaining = msg->length();
    intptr_t sent = 0;
    const intptr_t max_piece_len = 122;  // Pretty arbitrary, not a power of 2.
    dart::Monitor sleep;
    while (remaining > 0) {
      intptr_t piece_len = remaining;
      if (piece_len > max_piece_len) {
        piece_len = max_piece_len;
      }
      intptr_t written =
        Socket::Write(debug_fd, msg->buf() + sent, piece_len);
      ASSERT(written == piece_len);
      sent += written;
      remaining -= written;
      // Wait briefly so the OS does not coalesce message fragments.
      {
        MonitorLocker ml(&sleep);
        ml.Wait(10);
      }
    }
    return;
  }
  intptr_t bytes_written = Socket::Write(debug_fd, msg->buf(), msg->length());
  ASSERT(msg->length() == bytes_written);
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::AcceptDbgConnection(int debug_fd) {
  AddNewDebuggerConnection(debug_fd);
  {
    MonitorLocker ml(&handler_lock_);
    ml.NotifyAll();
  }
  // TODO(asiva): Once we implement support for multiple connections
  // we should have a different callback for wakeups on fds which
  // are not the listener_fd_.
  // In that callback we would lookup the handler object
  // corresponding to that fd and invoke HandleMessages on it.
  // For now we run that code here.
  DebuggerConnectionHandler* handler = GetDebuggerConnectionHandler(debug_fd);
  if (handler != NULL) {
    handler->HandleMessages();
    delete handler;
  }
}


void DebuggerConnectionHandler::HandleInterruptCmd(
    DebuggerConnectionHandler* handler) {
  int msg_id = handler->MessageId();
  ASSERT(msg_id >= 0);
  SendError(handler->debug_fd(), msg_id, "interrupt command unimplemented");
}


void DebuggerConnectionHandler::HandleIsolatesListCmd(
    DebuggerConnectionHandler* handler) {
  int msg_id = handler->MessageId();
  ASSERT(msg_id >= 0);
  SendError(handler->debug_fd(), msg_id, "isolate list command unimplemented");
}


void DebuggerConnectionHandler::HandleQuitCmd(
    DebuggerConnectionHandler* handler) {
  int msg_id = handler->MessageId();
  ASSERT(msg_id >= 0);
  SendError(handler->debug_fd(), msg_id, "quit command unimplemented");
}


void DebuggerConnectionHandler::AddNewDebuggerConnection(int debug_fd) {
  // TODO(asiva): Support multiple debugger connections, for now we just
  // create one handler, store it in a static variable and use it.
  ASSERT(singleton_handler == NULL);
  singleton_handler = new DebuggerConnectionHandler(debug_fd);
}


void DebuggerConnectionHandler::RemoveDebuggerConnection(int debug_fd) {
  // TODO(asiva): Support multiple debugger connections, for now we just
  // set the static handler back to NULL.
  ASSERT(singleton_handler != NULL);
  singleton_handler = NULL;
}


DebuggerConnectionHandler*
DebuggerConnectionHandler::GetDebuggerConnectionHandler(int debug_fd) {
  // TODO(asiva): Support multiple debugger connections, for now we just
  // return the one static handler that was created.
  ASSERT(singleton_handler != NULL);
  return singleton_handler;
}


bool DebuggerConnectionHandler::IsConnected() {
  // TODO(asiva): Support multiple debugger connections.
  // Return true if a connection has been established.
  return singleton_handler != NULL;
}
