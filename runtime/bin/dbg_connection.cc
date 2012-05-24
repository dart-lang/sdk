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

dart::TextBuffer DebuggerConnectionHandler::queued_messages_(64);


// TODO(hausner): Need better error handling.
#define ASSERT_NOT_ERROR(handle)          \
  ASSERT(!Dart_IsError(handle))

#define RETURN_IF_ERROR(handle)           \
  if (Dart_IsError(handle)) {             \
    return Dart_GetError(handle);         \
  }


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
  intptr_t GetIntParam(const char* name) const;
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
  r.Seek("params");
  if (r.Type() == dart::JSONReader::kObject) {
    return r.ValueChars();
  } else {
    return NULL;
  }
}


intptr_t MessageBuffer::GetIntParam(const char* name) const {
  const char* params = Params();
  ASSERT(params != NULL);
  dart::JSONReader r(params);
  r.Seek(name);
  ASSERT(r.Type() == dart::JSONReader::kInteger);
  return strtol(r.ValueChars(), NULL, 10);
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


void DebuggerConnectionHandler::SendMsg(dart::TextBuffer* msg) {
  ASSERT(debugger_fd_ >= 0);
  Socket::Write(debugger_fd_, msg->buf(), msg->length());
  // TODO(hausner): Error checking. Probably just shut down the debugger
  // session if we there is an error while writing.
}


void DebuggerConnectionHandler::QueueMsg(dart::TextBuffer* msg) {
  queued_messages_.Printf("%s", msg->buf());
}


void DebuggerConnectionHandler::SendQueuedMsgs() {
  if (queued_messages_.length() > 0) {
    SendMsg(&queued_messages_);
    queued_messages_.Clear();
  }
}


void DebuggerConnectionHandler::SendError(int msg_id,
                                          const char* err_msg) {
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\": %d, \"error\": \"Error: %s\"}", msg_id, err_msg);
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleResumeCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d }", msg_id);
  SendMsg(&msg);
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
  SendMsg(&msg);
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
  SendMsg(&msg);
}


static const char* GetStringChars(Dart_Handle str) {
  ASSERT(Dart_IsString(str));
  const char* chars;
  Dart_Handle res = Dart_StringToCString(str, &chars);
  ASSERT(!Dart_IsError(res));
  return chars;
}


static void FormatField(dart::TextBuffer* buf,
                        Dart_Handle object_name,
                        Dart_Handle object) {
  ASSERT(Dart_IsString(object_name));
  buf->Printf("{\"name\":\"%s\",", GetStringChars(object_name));
  intptr_t obj_id = Dart_CacheObject(object);
  ASSERT(obj_id >= 0);
  buf->Printf("\"value\":{\"objectId\":%d,", obj_id);
  const char* kind = "object";
  if (Dart_IsInteger(object)) {
    kind = "integer";
  } else if (Dart_IsString(object)) {
    kind = "string";
  } else if (Dart_IsBoolean(object)) {
    kind = "boolean";
  }
  buf->Printf("\"kind\":\"%s\",", kind);
  Dart_Handle text = Dart_ToString(object);
  buf->Printf("\"text\":\"%s\"}}", GetStringChars(text));
}


static void FormatFieldList(dart::TextBuffer* buf,
                            Dart_Handle obj_list) {
  ASSERT(Dart_IsList(obj_list));
  intptr_t list_length = 0;
  Dart_Handle res = Dart_ListLength(obj_list, &list_length);
  ASSERT_NOT_ERROR(res);
  ASSERT(list_length % 2 == 0);
  buf->Printf("[");
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle name_handle = Dart_ListGetAt(obj_list, i);
    ASSERT_NOT_ERROR(name_handle);
    Dart_Handle value_handle = Dart_ListGetAt(obj_list, i + 1);
    ASSERT_NOT_ERROR(value_handle);
    if (i > 0) {
      buf->Printf(",");
    }
    FormatField(buf, name_handle, value_handle);
  }
  buf->Printf("]");
}


static const char* FormatClassProps(dart::TextBuffer* buf,
                                    intptr_t cls_id) {
  Dart_Handle name, library, static_fields;
  intptr_t super_id;
  Dart_Handle res =
      Dart_GetClassInfo(cls_id, &name, &library, &super_id, &static_fields);
  RETURN_IF_ERROR(res);
  RETURN_IF_ERROR(name);
  buf->Printf("{\"name\":\"%s\",", GetStringChars(name));
  if (super_id > 0) {
    buf->Printf("\"superclassId\":%d,", super_id);
  }
  RETURN_IF_ERROR(library);
  ASSERT(!Dart_IsNull(library));
  // TODO(hausner): get proper library id.
  intptr_t libId = 0;
  buf->Printf("\"libraryId\":%d,", libId);
  RETURN_IF_ERROR(static_fields);
  buf->Printf("\"fields\":");
  FormatFieldList(buf, static_fields);
  buf->Printf("}");
  return NULL;
}


static const char* FormatObjProps(dart::TextBuffer* buf,
                                  Dart_Handle object) {
  intptr_t class_id;
  Dart_Handle res = Dart_GetObjClassId(object, &class_id);
  RETURN_IF_ERROR(res);
  buf->Printf("{\"classId\": %d, \"fields\":", class_id);
  Dart_Handle fields = Dart_GetInstanceFields(object);
  RETURN_IF_ERROR(fields);
  FormatFieldList(buf, fields);
  buf->Printf("}");
  return NULL;
}


static void FormatCallFrames(dart::TextBuffer* msg, Dart_StackTrace trace) {
  intptr_t trace_len = 0;
  Dart_Handle res = Dart_StackTraceLength(trace, &trace_len);
  ASSERT_NOT_ERROR(res);
  msg->Printf("\"callFrames\" : [ ");
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
    msg->Printf("%s { \"functionName\": \"%s\" , ",
               i > 0 ? "," : "",
               func_name_chars);
    ASSERT(Dart_IsString(script_url));
    const char* script_url_chars;
    Dart_StringToCString(script_url, &script_url_chars);
    msg->Printf("\"location\": { \"url\": \"%s\", \"lineNumber\":%d},",
               script_url_chars, line_number);
    Dart_Handle locals = Dart_GetLocalVariables(frame);
    ASSERT_NOT_ERROR(locals);
    msg->Printf("\"locals\":");
    FormatFieldList(msg, locals);
    msg->Printf("}");
  }
  msg->Printf("]");
}


void DebuggerConnectionHandler::HandleGetStackTraceCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  Dart_StackTrace trace;
  Dart_Handle res = Dart_GetStackTrace(&trace);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(128);
  msg.Printf("{ \"id\": %d, \"result\": {", msg_id);
  FormatCallFrames(&msg, trace);
  msg.Printf("}}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleSetBpCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  const char* params = msgbuf_->Params();
  ASSERT(params != NULL);
  dart::JSONReader pr(params);
  pr.Seek("url");
  ASSERT(pr.Type() == dart::JSONReader::kString);
  char url_chars[128];
  pr.GetValueChars(url_chars, sizeof(url_chars));
  Dart_Handle url = Dart_NewString(url_chars);
  ASSERT_NOT_ERROR(url);
  pr.Seek("line");
  ASSERT(pr.Type() == dart::JSONReader::kInteger);
  intptr_t line_number = atoi(pr.ValueChars());
  Dart_Handle bp_id = Dart_SetBreakpoint(url, line_number);
  if (Dart_IsError(bp_id)) {
    SendError(msg_id, Dart_GetError(bp_id));
    return;
  }
  ASSERT(Dart_IsInteger(bp_id));
  uint64_t bp_id_value;
  Dart_Handle res = Dart_IntegerToUint64(bp_id, &bp_id_value);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d, \"result\": { \"breakpointId\": %d }}",
             msg_id, bp_id_value);
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleGetObjPropsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  intptr_t obj_id = msgbuf_->GetIntParam("objectId");
  Dart_Handle obj = Dart_GetCachedObject(obj_id);
  if (Dart_IsError(obj)) {
    SendError(msg_id, Dart_GetError(obj));
    return;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatObjProps(&msg, obj);
  if (err != NULL) {
    SendError(msg_id, err);
    return;
  }
  msg.Printf("}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleGetClassPropsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  intptr_t cls_id = msgbuf_->GetIntParam("classId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatClassProps(&msg, cls_id);
  if (err != NULL) {
    SendError(msg_id, err);
    return;
  }
  msg.Printf("}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleUnknownMsg(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  ASSERT(msg_id >= 0);
  SendError(msg_id, "unknown debugger command");
}


void DebuggerConnectionHandler::HandleMessages() {
  static JSONDebuggerCommand debugger_commands[] = {
    { "resume", HandleResumeCmd },
    { "getLibraryURLs", HandleGetLibraryURLsCmd },
    { "getClassProperties", HandleGetClassPropsCmd },
    { "getObjectProperties", HandleGetObjPropsCmd },
    { "getScriptURLs", HandleGetScriptURLsCmd },
    { "getStackTrace", HandleGetStackTraceCmd },
    { "setBreakpoint", HandleSetBpCmd },
    { "stepInto", HandleStepIntoCmd },
    { "stepOut", HandleStepOutCmd },
    { "stepOver", HandleStepOverCmd },
    { NULL, NULL }
  };

  for (;;) {
    SendQueuedMsgs();
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
      HandleUnknownMsg(msgbuf_->buf());
      msgbuf_->PopMessage();
    }
  }
}


void DebuggerConnectionHandler::SendBreakpointEvent(Dart_Breakpoint bpt,
                                                    Dart_StackTrace trace) {
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"paused\", \"params\": { ");
  FormatCallFrames(&msg, trace);
  msg.Printf("}}");
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
  SendQueuedMsgs();
  SendBreakpointEvent(bpt, trace);
  HandleMessages();
  if (!msgbuf_->Alive()) {
    CloseDbgConnection();
  }
  Dart_ExitScope();
}


void DebuggerConnectionHandler::BptResolvedHandler(intptr_t bp_id,
                                                   Dart_Handle url,
                                                   intptr_t line_number) {
  Dart_EnterScope();
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"breakpointResolved\", \"params\": {");
  msg.Printf("\"breakpointId\": %d, ", bp_id);
  char const* url_chars;
  Dart_StringToCString(url, &url_chars);
  msg.Printf("\"url\": \"%s\", ", url_chars);
  msg.Printf("\"line\": %d }}", line_number);
  QueueMsg(&msg);
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
  Dart_SetBreakpointResolvedHandler(BptResolvedHandler);
}


DebuggerConnectionHandler::~DebuggerConnectionHandler() {
  CloseDbgConnection();
}
