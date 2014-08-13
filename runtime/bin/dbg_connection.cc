// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dbg_connection.h"
#include "bin/dbg_message.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/json.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

extern bool trace_debug_protocol;

intptr_t DebuggerConnectionHandler::listener_fd_ = -1;
dart::Monitor* DebuggerConnectionHandler::handler_lock_ = new dart::Monitor();

// TODO(asiva): Remove this once we have support for multiple debugger
// connections. For now we just store the single debugger connection
// handler in a static variable.
static DebuggerConnectionHandler* singleton_handler = NULL;

// The maximum message length to print when --trace_debug_protocol is
// specified.
static const int kMaxPrintMessageLen = 1024;

class MessageBuffer {
 public:
  explicit MessageBuffer(intptr_t fd);
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
  intptr_t fd_;
  int data_length_;
  bool connection_is_alive_;

  DISALLOW_COPY_AND_ASSIGN(MessageBuffer);
};


MessageBuffer::MessageBuffer(intptr_t fd)
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
  int bytes_read =
      DebuggerConnectionImpl::Receive(fd_, buf_ + data_length_, max_read);
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
  return r.CheckMessage();
}


DebuggerConnectionHandler::DebuggerConnectionHandler(intptr_t debug_fd)
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


typedef void (*CommandHandler)(DbgMessage* msg);

struct JSONDebuggerCommand {
  const char* cmd_string;
  CommandHandler handler_function;
};


void DebuggerConnectionHandler::HandleMessages() {
  static JSONDebuggerCommand generic_debugger_commands[] = {
    { "interrupt", HandleInterruptCmd },
    { "getIsolateIds", HandleIsolatesListCmd },
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

    if (trace_debug_protocol) {
      dart::JSONReader r(msgbuf_->buf());
      const char* msg_end = r.EndOfObject();
      if (msg_end != NULL) {
        intptr_t msg_len = msg_end - msgbuf_->buf();
        int print_len = ((msg_len > kMaxPrintMessageLen)
                         ? kMaxPrintMessageLen : msg_len);
        Log::Print("[<<<] Receiving message from debug fd %" Pd ":\n%.*s%s\n",
                   debug_fd_, print_len, msgbuf_->buf(),
                   ((msg_len > print_len) ? "..." : ""));
      }
    }

    // Parse out the command portion from the message.
    dart::JSONReader r(msgbuf_->buf());
    bool found = r.Seek("command");
    if (r.Error()) {
      FATAL("Illegal JSON message received");
    }
    if (!found) {
      Log::Print("'command' not found in JSON message: '%s'\n",
                      msgbuf_->buf());
      msgbuf_->PopMessage();
    }

    // Check if this is a generic command (not isolate specific).
    int i = 0;
    bool is_handled = false;
    while (generic_debugger_commands[i].cmd_string != NULL) {
      if (r.IsStringLiteral(generic_debugger_commands[i].cmd_string)) {
        DbgMessage* msg = new DbgMessage(i,
                                         msgbuf_->buf(),
                                         r.EndOfObject(),
                                         debug_fd_);
        (*generic_debugger_commands[i].handler_function)(msg);
        is_handled = true;
        msgbuf_->PopMessage();
        delete msg;
        break;
      }
      i++;
    }
    if (!is_handled) {
      // Check if this is an isolate specific command.
      int32_t cmd_idx = DbgMsgQueueList::LookupIsolateCommand(r.ValueChars(),
                                                              r.ValueLen());
      if (cmd_idx != DbgMsgQueueList::kInvalidCommand) {
        const char* start = msgbuf_->buf();
        const char* end = r.EndOfObject();
        // Get debug message queue corresponding to isolate.
        MessageParser msg_parser(start, (end - start));
        Dart_IsolateId isolate_id = msg_parser.GetInt64Param("isolateId");
        if (!DbgMsgQueueList::AddIsolateMessage(isolate_id,
                                                cmd_idx,
                                                msgbuf_->buf(),
                                                r.EndOfObject(),
                                                debug_fd_)) {
          SendError(debug_fd_, MessageId(), "Invalid isolate specified");
        }
        msgbuf_->PopMessage();
        continue;
      }

      // This is an unrecognized command, report error and move on to next.
      Log::Print("unrecognized command received: '%s'\n", msgbuf_->buf());
      HandleUnknownMsg();
      msgbuf_->PopMessage();
    }
  }
}


void DebuggerConnectionHandler::SendError(intptr_t debug_fd,
                                          int msg_id,
                                          const char* err_msg) {
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\": %d, \"error\": \"Error: ", msg_id);
  msg.AddEscapedString(err_msg);
  msg.Printf("\"}");
  SendMsg(debug_fd, &msg);
}


void DebuggerConnectionHandler::CloseDbgConnection() {
  if (debug_fd_ >= 0) {
    Socket::Close(debug_fd_);
  }
  if (msgbuf_ != NULL) {
    delete msgbuf_;
    msgbuf_ = NULL;
  }
  // TODO(hausner): Need to tell the VM debugger object to remove all
  // breakpoints.
}


// The vm service relies on certain debugger functionality.
void DebuggerConnectionHandler::InitForVmService() {
  MonitorLocker ml(handler_lock_);
  DbgMsgQueueList::Initialize();
}


int DebuggerConnectionHandler::StartHandler(const char* address,
                                            int port_number) {
  ASSERT(handler_lock_ != NULL);
  MonitorLocker ml(handler_lock_);
  if (IsListening()) {
    // The debugger connection handler was already started.
    return Socket::GetPort(listener_fd_);
  }

  // First setup breakpoint, exception and delayed breakpoint handlers.
  DbgMsgQueueList::Initialize();

  // Initialize the socket implementation.
  if (!Socket::Initialize()) {
    FATAL("Failed initializing socket implementation.");
  }

  // Now setup a listener socket and start a thread which will
  // listen, accept connections from debuggers, read and handle/dispatch
  // debugger commands received on these connections.
  ASSERT(listener_fd_ == -1);
  OSError *os_error;
  AddressList<SocketAddress>* addresses =
      Socket::LookupAddress(address, -1, &os_error);
  listener_fd_ = ServerSocket::CreateBindListen(
      addresses->GetAt(0)->addr(), port_number, 1);
  delete addresses;
  port_number = Socket::GetPort(listener_fd_);
  DebuggerConnectionImpl::StartHandler(port_number);
  return port_number;
}


void DebuggerConnectionHandler::WaitForConnection() {
  ASSERT(handler_lock_ != NULL);
  MonitorLocker ml(handler_lock_);
  if (!IsListening()) {
    // If we are only running the vm service, don't wait for
    // connections.
    return;
  }
  while (!IsConnected()) {
    dart::Monitor::WaitResult res = ml.Wait();
    ASSERT(res == dart::Monitor::kNotified);
  }
}


void DebuggerConnectionHandler::SendMsg(intptr_t debug_fd,
                                        dart::TextBuffer* msg) {
  ASSERT(handler_lock_ != NULL);
  MonitorLocker ml(handler_lock_);
  SendMsgHelper(debug_fd, msg);
}


void DebuggerConnectionHandler::BroadcastMsg(dart::TextBuffer* msg) {
  ASSERT(handler_lock_ != NULL);
  MonitorLocker ml(handler_lock_);
  if (!IsListening()) {
    // If we are only running the vm service, don't try to broadcast
    // to debugger clients.
    return;
  }
  // TODO(asiva): Once we support connection to multiple debuggers
  // we need to send the message to all of them.
  ASSERT(singleton_handler != NULL);
  SendMsgHelper(singleton_handler->debug_fd(), msg);
}


void DebuggerConnectionHandler::SendMsgHelper(intptr_t debug_fd,
                                              dart::TextBuffer* msg) {
  ASSERT(debug_fd >= 0);
  ASSERT(IsValidJSON(msg->buf()));

  if (trace_debug_protocol) {
    int print_len = ((msg->length() > kMaxPrintMessageLen)
                     ? kMaxPrintMessageLen : msg->length());
    Log::Print("[>>>] Sending message to debug fd %" Pd ":\n%.*s%s\n",
               debug_fd, print_len, msg->buf(),
               ((msg->length() > print_len) ? "..." : ""));
  }

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
          DebuggerConnectionImpl::Send(debug_fd, msg->buf() + sent, piece_len);
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
  intptr_t bytes_written =
      DebuggerConnectionImpl::Send(debug_fd, msg->buf(), msg->length());
  ASSERT(msg->length() == bytes_written);
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::AcceptDbgConnection(intptr_t debug_fd) {
  Socket::SetNoDelay(debug_fd, true);
  AddNewDebuggerConnection(debug_fd);
  {
    ASSERT(handler_lock_ != NULL);
    MonitorLocker ml(handler_lock_);
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


void DebuggerConnectionHandler::HandleInterruptCmd(DbgMessage* in_msg) {
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  Dart_IsolateId isolate_id = msg_parser.GetInt64Param("isolateId");
  if (isolate_id == ILLEGAL_ISOLATE_ID || Dart_GetIsolate(isolate_id) == NULL) {
    in_msg->SendErrorReply(msg_id, "Invalid isolate specified");
    return;
  }
  if (!DbgMsgQueueList::InterruptIsolate(isolate_id)) {
    in_msg->SendErrorReply(msg_id, "Invalid isolate specified");
    return;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d }", msg_id);
  in_msg->SendReply(&msg);
}


void DebuggerConnectionHandler::HandleIsolatesListCmd(DbgMessage* in_msg) {
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  ASSERT(msg_id >= 0);
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d, \"result\": { \"isolateIds\": [", msg_id);
  DbgMsgQueueList::ListIsolateIds(&msg);
  msg.Printf("]}}");
  in_msg->SendReply(&msg);
}


void DebuggerConnectionHandler::AddNewDebuggerConnection(intptr_t debug_fd) {
  // TODO(asiva): Support multiple debugger connections, for now we just
  // create one handler, store it in a static variable and use it.
  ASSERT(singleton_handler == NULL);
  singleton_handler = new DebuggerConnectionHandler(debug_fd);
}


void DebuggerConnectionHandler::RemoveDebuggerConnection(intptr_t debug_fd) {
  // TODO(asiva): Support multiple debugger connections, for now we just
  // set the static handler back to NULL.
  ASSERT(singleton_handler != NULL);
  singleton_handler = NULL;
}


DebuggerConnectionHandler*
DebuggerConnectionHandler::GetDebuggerConnectionHandler(intptr_t debug_fd) {
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

}  // namespace bin
}  // namespace dart
