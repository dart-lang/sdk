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
dart::Monitor DebuggerConnectionHandler::is_connected_;
MessageBuffer* DebuggerConnectionHandler::msgbuf_ = NULL;

bool DebuggerConnectionHandler::handler_started_ = false;
bool DebuggerConnectionHandler::request_resume_ = false;


// TODO(hausner): Need better error handling.
#define ASSERT_NOT_ERROR(handle)                                               \
  ASSERT(!Dart_IsError(handle))

typedef void (*CommandHandler)(const char* json_cmd);

struct JSONDebuggerCommand {
  const char* cmd_string;
  CommandHandler handler_function;
};


class MessageBuffer {
 public:
  explicit MessageBuffer(int fd);
  ~MessageBuffer();
  void ReadData();
  bool IsValidMessage() const;
  void PopMessage();
  int MessageId() const;
  const char* Params() const;
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


const char* MessageBuffer::Params() const {
  dart::JSONReader r(buf_);
  r.Seek("param");
  if (r.Type() == dart::JSONReader::kObject) {
    return r.ValueChars();
  } else {
    return NULL;
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


void DebuggerConnectionHandler::SendError(int msg_id,
                                          const char* err_msg) {
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\": %d, \"error\": \"Error: %s\"}", msg_id, err_msg);
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::HandleResumeCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d }", msg_id);
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
  request_resume_ = true;
}


void DebuggerConnectionHandler::HandleStepIntoCmd(const char* json_msg) {
  Dart_Handle res = Dart_SetStepInto();
  ASSERT_NOT_ERROR(res);
  HandleResumeCmd(json_msg);
}


void DebuggerConnectionHandler::HandleStepOutCmd(const char* json_msg) {
  Dart_Handle res = Dart_SetStepOut();
  ASSERT_NOT_ERROR(res);
  HandleResumeCmd(json_msg);
}


void DebuggerConnectionHandler::HandleStepOverCmd(const char* json_msg) {
  Dart_Handle res = Dart_SetStepOver();
  ASSERT_NOT_ERROR(res);
  HandleResumeCmd(json_msg);
}


void DebuggerConnectionHandler::HandleGetScriptURLsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  const char* params = msgbuf_->Params();
  ASSERT(params != NULL);
  dart::JSONReader pr(params);
  pr.Seek("library");
  ASSERT(pr.Type() == dart::JSONReader::kString);
  char lib_url_chars[128];
  pr.GetValueChars(lib_url_chars, sizeof(lib_url_chars));
  Dart_Handle lib_url = Dart_NewString(lib_url_chars);
  ASSERT_NOT_ERROR(lib_url);
  Dart_Handle urls = Dart_GetScriptURLs(lib_url);
  if (Dart_IsError(urls)) {
    SendError(msg_id, Dart_GetError(urls));
    return;
  }
  ASSERT(Dart_IsList(urls));
  intptr_t num_urls = 0;
  Dart_ListLength(urls, &num_urls);
  msg.Printf("{ \"id\": %d, ", msg_id);
  msg.Printf("\"result\": { \"urls\": [");
  for (int i = 0; i < num_urls; i++) {
    Dart_Handle script_url = Dart_ListGetAt(urls, i);
    ASSERT(Dart_IsString(script_url));
    char const* chars;
    Dart_StringToCString(lib_url, &chars);
    msg.Printf("%s\"%s\"", (i == 0) ? "" : ", ", chars);
  }
  msg.Printf("] }}");
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::HandleGetLibraryURLsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d, \"result\": { \"urls\": [", msg_id);
  Dart_Handle urls = Dart_GetLibraryURLs();
  ASSERT_NOT_ERROR(urls);
  intptr_t num_libs;
  Dart_ListLength(urls, &num_libs);
  for (int i = 0; i < num_libs; i++) {
    Dart_Handle lib_url = Dart_ListGetAt(urls, i);
    ASSERT(Dart_IsString(lib_url));
    char const* chars;
    Dart_StringToCString(lib_url, &chars);
    msg.Printf("%s\"%s\"", (i == 0) ? "" : ", ", chars);
  }
  msg.Printf("] }}");
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::HandleMessages() {
  static JSONDebuggerCommand debugger_commands[] = {
    { "resume", HandleResumeCmd },
    { "getLibraryURLs", HandleGetLibraryURLsCmd},
    { "getScriptURLs", HandleGetScriptURLsCmd },
    { "stepInto", HandleStepIntoCmd },
    { "stepOut", HandleStepOutCmd },
    { "stepOver", HandleStepOverCmd },
    { NULL, NULL }
  };

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
    }
    int i = 0;
    bool is_handled = false;
    request_resume_ = false;
    while (debugger_commands[i].cmd_string != NULL) {
      if (r.IsStringLiteral(debugger_commands[i].cmd_string)) {
        is_handled = true;
        (*debugger_commands[i].handler_function)(msgbuf_->buf());
        msgbuf_->PopMessage();
        if (request_resume_) {
          return;
        }
        break;
      }
      i++;
    }
    if (!is_handled) {
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
  msg.Printf("{ \"event\": \"paused\", \"params\": ");
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
    msg.Printf("%s { \"functionName\": \"%s\" , ",
              i > 0 ? "," : "",
              func_name_chars);
    ASSERT(Dart_IsString(script_url));
    const char* script_url_chars;
    Dart_StringToCString(script_url, &script_url_chars);
    msg.Printf("\"location\": { \"url\": \"%s\", \"lineNumber\": %d }}",
               script_url_chars, line_number);
  }
  msg.Printf("]}}");
  Socket::Write(debugger_fd_, msg.buf(), msg.length());
  ASSERT(IsValidJSON(msg.buf()));
}


void DebuggerConnectionHandler::BreakpointHandler(Dart_Breakpoint bpt,
                                                  Dart_StackTrace trace) {
  {
    MonitorLocker ml(&is_connected_);
    while (!IsConnected()) {
      printf("Waiting for debugger connection...\n");
      dart::Monitor::WaitResult res = ml.Wait(dart::Monitor::kNoTimeout);
      ASSERT(res == dart::Monitor::kNotified);
    }
  }
  Dart_EnterScope();
  SendBreakpointEvent(bpt, trace);
  HandleMessages();
  if (!msgbuf_->Alive()) {
    CloseDbgConnection();
  }
  Dart_ExitScope();
}


void DebuggerConnectionHandler::AcceptDbgConnection(int debugger_fd) {
  debugger_fd_ = debugger_fd;
  ASSERT(msgbuf_ == NULL);
  msgbuf_ = new MessageBuffer(debugger_fd_);
  {
    MonitorLocker ml(&is_connected_);
    ml.Notify();
  }
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
