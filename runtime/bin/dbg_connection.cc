// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dbg_connection.h"
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
int DebuggerConnectionHandler::debugger_fd_ = -1;
MessageBuffer* DebuggerConnectionHandler::msgbuf_ = NULL;

bool DebuggerConnectionHandler::handler_started_ = false;


// TODO(hausner): Need better error handling.
#define ASSERT_NOT_ERROR(handle)                                               \
  ASSERT(!Dart_IsError(handle))


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


void DebuggerConnectionHandler::HandleResumeCmd() {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d }", msg_id);
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::HandleMessages() {
  for (;;) {
    while (!msgbuf_->IsValidMessage() && msgbuf_->Alive()) {
      msgbuf_->ReadData();
    }
    if (!msgbuf_->Alive()) {
      return;
    }
    dart::JSONReader r(msgbuf_->buf());
    bool found = r.Seek("command");
    if (r.Error()) {
      FATAL("Illegal JSON message received");
    }
    if (!found) {
      printf("'command' not found in JSON message: '%s'\n", msgbuf_->buf());
      msgbuf_->PopMessage();
    } else if (r.IsStringLiteral("resume")) {
      HandleResumeCmd();
      msgbuf_->PopMessage();
      return;
    } else {
      printf("unrecognized command received: '%s'\n", msgbuf_->buf());
      msgbuf_->PopMessage();
    }
  }
}


void DebuggerConnectionHandler::SendBreakpointEvent(Dart_Breakpoint bpt,
                                                    Dart_StackTrace trace) {
  dart::TextBuffer msg(128);
  intptr_t trace_len = 0;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  ASSERT_NOT_ERROR(res);
  msg.Printf("{ \"command\" : \"paused\", \"params\" : ");
  msg.Printf("{ \"callFrames\" : [ ");
  for (int i = 0; i < trace_len; i++) {
    Dart_ActivationFrame frame;
    res = Dart_GetActivationFrame(trace, i, &frame);
    ASSERT_NOT_ERROR(res);
    Dart_Handle func_name;
    Dart_Handle script_url;
    intptr_t line_number = 0;
    res = Dart_ActivationFrameInfo(
              frame, &func_name, &script_url, &line_number);
    ASSERT_NOT_ERROR(res);
    ASSERT(Dart_IsString(func_name));
    const char* func_name_chars;
    Dart_StringToCString(func_name, &func_name_chars);
    msg.Printf("%s { \"functionName\" : \"%s\" , ",
              i > 0 ? "," : "",
              func_name_chars);
    ASSERT(Dart_IsString(script_url));
    const char* script_url_chars;
    Dart_StringToCString(script_url, &script_url_chars);
    msg.Printf("\"location\": { \"scriptId\": \"%s\", \"lineNumber\": %d }}",
               script_url_chars, line_number);
  }
  msg.Printf("]}}");
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  ASSERT(IsValidJSON(msg.buf()));
}


void DebuggerConnectionHandler::BreakpointHandler(Dart_Breakpoint bpt,
                                                  Dart_StackTrace trace) {
  // TODO(hausner): rather than busy-waiting, block on the pipe to the
  // debugger thread and wait until a debugger connection has been
  // established.
  while (!IsConnected()) {
    // Busy wait.
  }
  SendBreakpointEvent(bpt, trace);
  HandleMessages();
  if (!msgbuf_->Alive()) {
    CloseDbgConnection();
  }
}


void DebuggerConnectionHandler::AcceptDbgConnection(int debugger_fd) {
  debugger_fd_ = debugger_fd;
  ASSERT(msgbuf_ == NULL);
  msgbuf_ = new MessageBuffer(debugger_fd_);
}

void DebuggerConnectionHandler::CloseDbgConnection() {
  if (debugger_fd_ >= 0) {
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
  if (handler_started_) {
    return;
  }
  ASSERT(listener_fd_ == -1);
  listener_fd_ = ServerSocket::CreateBindListen(address, port_number, 1);

  handler_started_ = true;
  DebuggerConnectionImpl::StartHandler(port_number);
  Dart_SetBreakpointHandler(BreakpointHandler);
}


DebuggerConnectionHandler::~DebuggerConnectionHandler() {
  CloseDbgConnection();
}
