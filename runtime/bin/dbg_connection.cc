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
  intptr_t GetOptIntParam(const char* name, intptr_t default_val) const;
  // GetStringParam mallocs the buffer that it returns. Caller must free.
  char* GetStringParam(const char* name) const;
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


intptr_t MessageBuffer::GetOptIntParam(const char* name,
                                       intptr_t default_val) const {
  const char* params = Params();
  ASSERT(params != NULL);
  dart::JSONReader r(params);
  r.Seek(name);
  if (r.Type() == dart::JSONReader::kInteger) {
    return strtol(r.ValueChars(), NULL, 10);
  } else {
    return default_val;
  }
}


char* MessageBuffer::GetStringParam(const char* name) const {
  const char* params = Params();
  ASSERT(params != NULL);
  dart::JSONReader pr(params);
  pr.Seek(name);
  if (pr.Type() != dart::JSONReader::kString) {
    return NULL;
  }
  intptr_t buflen = pr.ValueLen() + 1;
  char* param_chars = reinterpret_cast<char*>(malloc(buflen));
  pr.GetValueChars(param_chars, buflen);
  // TODO(hausner): Decode escape sequences.
  return param_chars;
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
        Socket::Write(debugger_fd_, msg->buf() + sent, piece_len);
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
      Socket::Write(debugger_fd_, msg->buf(), msg->length());
  ASSERT(msg->length() == bytes_written);
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


static const char* GetStringChars(Dart_Handle str) {
  ASSERT(Dart_IsString(str));
  const char* chars;
  Dart_Handle res = Dart_StringToCString(str, &chars);
  ASSERT(!Dart_IsError(res));
  return chars;
}


static int GetIntValue(Dart_Handle int_handle) {
  int64_t int64_val = -1;
  ASSERT(Dart_IsInteger(int_handle));
  Dart_Handle res = Dart_IntegerToInt64(int_handle, &int64_val);
  ASSERT_NOT_ERROR(res);
  // TODO(hausner): Range check.
  return int64_val;
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


static void FormatEncodedString(dart::TextBuffer* buf, Dart_Handle str) {
  intptr_t str_len = 0;
  Dart_Handle res = Dart_StringLength(str, &str_len);
  ASSERT_NOT_ERROR(res);
  uint32_t* codepoints =
      reinterpret_cast<uint32_t*>(malloc(str_len * sizeof(uint32_t)));
  ASSERT(codepoints != NULL);
  intptr_t actual_len = str_len;
  res = Dart_StringGet32(str, codepoints, &actual_len);
  ASSERT_NOT_ERROR(res);
  ASSERT(str_len == actual_len);
  buf->AddChar('\"');
  for (int i = 0; i < str_len; i++) {
    buf->AddEscapedChar(codepoints[i]);
  }
  buf->AddChar('\"');
  free(codepoints);
}


static void FormatErrorMsg(dart::TextBuffer* buf, Dart_Handle err) {
  // TODO(hausner): Turn message into Dart string and
  // properly encode the message.
  ASSERT(Dart_IsError(err));
  const char* msg = Dart_GetError(err);
  buf->Printf("\"%s\"", msg);
}


void DebuggerConnectionHandler::HandleGetScriptURLsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  intptr_t lib_id = msgbuf_->GetIntParam("libraryId");
  Dart_Handle lib_url = Dart_GetLibraryURL(lib_id);
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
    if (i > 0) {
      msg.Printf(",");
    }
    FormatEncodedString(&msg, script_url);
  }
  msg.Printf("]}}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleGetSourceCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  intptr_t lib_id = msgbuf_->GetIntParam("libraryId");
  char* url_chars = msgbuf_->GetStringParam("url");
  ASSERT(url_chars != NULL);
  Dart_Handle url = Dart_NewString(url_chars);
  ASSERT_NOT_ERROR(url);
  free(url_chars);
  url_chars = NULL;
  Dart_Handle source = Dart_ScriptGetSource(lib_id, url);
  if (Dart_IsError(source)) {
    SendError(msg_id, Dart_GetError(source));
    return;
  }
  msg.Printf("{ \"id\": %d, ", msg_id);
  msg.Printf("\"result\": { \"text\": ");
  FormatEncodedString(&msg, source);
  msg.Printf("}}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleGetLibrariesCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d, \"result\": { \"libraries\": [", msg_id);
  Dart_Handle lib_ids = Dart_GetLibraryIds();
  ASSERT_NOT_ERROR(lib_ids);
  intptr_t num_libs;
  Dart_Handle res = Dart_ListLength(lib_ids, &num_libs);
  ASSERT_NOT_ERROR(res);
  for (int i = 0; i < num_libs; i++) {
    Dart_Handle lib_id_handle = Dart_ListGetAt(lib_ids, i);
    ASSERT(Dart_IsInteger(lib_id_handle));
    int lib_id = GetIntValue(lib_id_handle);
    Dart_Handle lib_url = Dart_GetLibraryURL(lib_id);
    ASSERT_NOT_ERROR(lib_url);
    ASSERT(Dart_IsString(lib_url));
    msg.Printf("%s{\"id\":%d,\"url\":", (i == 0) ? "" : ", ", lib_id);
    FormatEncodedString(&msg, lib_url);
    msg.Printf("}");
  }
  msg.Printf("]}}");
  SendMsg(&msg);
}


static void FormatTextualValue(dart::TextBuffer* buf, Dart_Handle object) {
  Dart_Handle text;
  if (Dart_IsNull(object)) {
    text = Dart_Null();
  } else {
    text = Dart_ToString(object);
  }
  buf->Printf("\"text\":");
  if (Dart_IsNull(text)) {
    buf->Printf("null");
  } else if (Dart_IsError(text)) {
    FormatErrorMsg(buf, text);
  } else {
    FormatEncodedString(buf, text);
  }
}


static void FormatValue(dart::TextBuffer* buf, Dart_Handle object) {
  if (Dart_IsInteger(object)) {
    buf->Printf("\"kind\":\"integer\",");
  } else if (Dart_IsString(object)) {
    buf->Printf("\"kind\":\"string\",");
  } else if (Dart_IsBoolean(object)) {
    buf->Printf("\"kind\":\"boolean\",");
  } else if (Dart_IsList(object)) {
    intptr_t len = 0;
    Dart_Handle res = Dart_ListLength(object, &len);
    ASSERT_NOT_ERROR(res);
    buf->Printf("\"kind\":\"list\",\"length\":%"Pd",", len);
  } else {
    buf->Printf("\"kind\":\"object\",");
  }
  FormatTextualValue(buf, object);
}


static void FormatValueObj(dart::TextBuffer* buf, Dart_Handle object) {
  buf->Printf("{");
  FormatValue(buf, object);
  buf->Printf("}");
}


static void FormatRemoteObj(dart::TextBuffer* buf, Dart_Handle object) {
  intptr_t obj_id = Dart_CacheObject(object);
  ASSERT(obj_id >= 0);
  buf->Printf("{\"objectId\":%"Pd",", obj_id);
  FormatValue(buf, object);
  buf->Printf("}");
}


static void FormatNamedValue(dart::TextBuffer* buf,
                             Dart_Handle object_name,
                             Dart_Handle object) {
  ASSERT(Dart_IsString(object_name));
  buf->Printf("{\"name\":\"%s\",", GetStringChars(object_name));
  buf->Printf("\"value\":");
  FormatRemoteObj(buf, object);
  buf->Printf("}");
}


static void FormatNamedValueList(dart::TextBuffer* buf,
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
    FormatNamedValue(buf, name_handle, value_handle);
  }
  buf->Printf("]");
}


static const char* FormatClassProps(dart::TextBuffer* buf,
                                    intptr_t cls_id) {
  Dart_Handle name, static_fields;
  intptr_t super_id = -1;
  intptr_t library_id = -1;
  Dart_Handle res =
      Dart_GetClassInfo(cls_id, &name, &library_id, &super_id, &static_fields);
  RETURN_IF_ERROR(res);
  RETURN_IF_ERROR(name);
  buf->Printf("{\"name\":\"%s\",", GetStringChars(name));
  if (super_id > 0) {
    buf->Printf("\"superclassId\":%"Pd",", super_id);
  }
  buf->Printf("\"libraryId\":%"Pd",", library_id);
  RETURN_IF_ERROR(static_fields);
  buf->Printf("\"fields\":");
  FormatNamedValueList(buf, static_fields);
  buf->Printf("}");
  return NULL;
}


static const char* FormatLibraryProps(dart::TextBuffer* buf,
                                      intptr_t lib_id) {
  Dart_Handle url = Dart_GetLibraryURL(lib_id);
  RETURN_IF_ERROR(url);
  buf->Printf("{\"url\":");
  FormatEncodedString(buf, url);

  // Whether debugging is enabled.
  bool is_debuggable = false;
  Dart_Handle res = Dart_GetLibraryDebuggable(lib_id, &is_debuggable);
  RETURN_IF_ERROR(res);
  buf->Printf(",\"debuggingEnabled\":%s",
              is_debuggable ? "\"true\"" : "\"false\"");

  // Imports and prefixes.
  Dart_Handle import_list = Dart_GetLibraryImports(lib_id);
  RETURN_IF_ERROR(import_list);
  ASSERT(Dart_IsList(import_list));
  intptr_t list_length = 0;
  res = Dart_ListLength(import_list, &list_length);
  RETURN_IF_ERROR(res);
  buf->Printf(",\"imports\":[");
  for (int i = 0; i + 1 < list_length; i += 2) {
    Dart_Handle lib_id = Dart_ListGetAt(import_list, i + 1);
    ASSERT_NOT_ERROR(lib_id);
    buf->Printf("%s{\"libraryId\":%d,",
                (i > 0) ? ",": "",
                GetIntValue(lib_id));

    Dart_Handle name = Dart_ListGetAt(import_list, i);
    ASSERT_NOT_ERROR(name);
    buf->Printf("\"prefix\":\"%s\"}",
                Dart_IsNull(name) ? "" : GetStringChars(name));
  }
  buf->Printf("],");

  // Global variables in the library.
  Dart_Handle global_vars = Dart_GetLibraryFields(lib_id);
  RETURN_IF_ERROR(global_vars);
  buf->Printf("\"globals\":");
  FormatNamedValueList(buf, global_vars);
  buf->Printf("}");
  return NULL;
}


static const char* FormatObjProps(dart::TextBuffer* buf,
                                  Dart_Handle object) {
  intptr_t class_id;
  if (Dart_IsNull(object)) {
    buf->Printf("{\"classId\":-1,\"fields\":[]}");
    return NULL;
  }
  Dart_Handle res = Dart_GetObjClassId(object, &class_id);
  RETURN_IF_ERROR(res);
  buf->Printf("{\"classId\": %"Pd",", class_id);
  buf->Printf("\"kind\":\"object\",\"fields\":");
  Dart_Handle fields = Dart_GetInstanceFields(object);
  RETURN_IF_ERROR(fields);
  FormatNamedValueList(buf, fields);
  buf->Printf("}");
  return NULL;
}


static const char* FormatListSlice(dart::TextBuffer* buf,
                                   Dart_Handle list,
                                   intptr_t list_length,
                                   intptr_t index,
                                   intptr_t slice_length) {
  intptr_t end_index = index + slice_length;
  ASSERT(end_index <= list_length);
  buf->Printf("{\"index\":%"Pd",", index);
  buf->Printf("\"length\":%"Pd",", slice_length);
  buf->Printf("\"elements\":[");
  for (intptr_t i = index; i < end_index; i++) {
    Dart_Handle value = Dart_ListGetAt(list, i);
    if (i > index) {
      buf->Printf(",");
    }
    FormatValueObj(buf, value);
  }
  buf->Printf("]}");
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
    intptr_t library_id = 0;
    res = Dart_ActivationFrameInfo(
        frame, &func_name, &script_url, &line_number, &library_id);
    ASSERT_NOT_ERROR(res);
    ASSERT(Dart_IsString(func_name));
    msg->Printf("%s{\"functionName\":", (i > 0) ? "," : "");
    FormatEncodedString(msg, func_name);
    msg->Printf(",\"libraryId\": %"Pd",", library_id);

    ASSERT(Dart_IsString(script_url));
    msg->Printf("\"location\": { \"url\":");
    FormatEncodedString(msg, script_url);
    msg->Printf(",\"lineNumber\":%"Pd"},", line_number);

    Dart_Handle locals = Dart_GetLocalVariables(frame);
    ASSERT_NOT_ERROR(locals);
    msg->Printf("\"locals\":");
    FormatNamedValueList(msg, locals);
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
  char* url_chars = msgbuf_->GetStringParam("url");
  ASSERT(url_chars != NULL);
  Dart_Handle url = Dart_NewString(url_chars);
  ASSERT_NOT_ERROR(url);
  free(url_chars);
  url_chars = NULL;
  intptr_t line_number = msgbuf_->GetIntParam("line");
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
  msg.Printf("{ \"id\": %d, \"result\": { \"breakpointId\": %"Pu64" }}",
             msg_id, bp_id_value);
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandlePauseOnExcCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  char* exc_chars = msgbuf_->GetStringParam("exceptions");
  Dart_ExceptionPauseInfo info = kNoPauseOnExceptions;
  if (strcmp(exc_chars, "none") == 0) {
    info = kNoPauseOnExceptions;
  } else if (strcmp(exc_chars, "all") == 0) {
    info = kPauseOnAllExceptions;
  } else if (strcmp(exc_chars, "unhandled") == 0) {
    info = kPauseOnUnhandledExceptions;
  } else {
    SendError(msg_id, "illegal value for parameter 'exceptions'");
    return;
  }
  Dart_Handle res = Dart_SetExceptionPauseInfo(info);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(32);
  msg.Printf("{ \"id\": %d }", msg_id);
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleRemBpCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  int bpt_id = msgbuf_->GetIntParam("breakpointId");
  Dart_Handle res = Dart_RemoveBreakpoint(bpt_id);
  if (Dart_IsError(res)) {
    SendError(msg_id, Dart_GetError(res));
    return;
  }
  dart::TextBuffer msg(32);
  msg.Printf("{ \"id\": %d }", msg_id);
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


void DebuggerConnectionHandler::HandleGetListCmd(const char* json_msg) {
  const intptr_t kDefaultSliceLength = 100;
  int msg_id = msgbuf_->MessageId();
  intptr_t obj_id = msgbuf_->GetIntParam("objectId");
  Dart_Handle list = Dart_GetCachedObject(obj_id);
  if (Dart_IsError(list)) {
    SendError(msg_id, Dart_GetError(list));
    return;
  }
  if (!Dart_IsList(list)) {
    SendError(msg_id, "object is not a list");
    return;
  }
  intptr_t list_length = 0;
  Dart_Handle res = Dart_ListLength(list, &list_length);
  if (Dart_IsError(res)) {
    SendError(msg_id, Dart_GetError(res));
    return;
  }

  intptr_t index = msgbuf_->GetIntParam("index");
  if (index < 0) {
    index = 0;
  } else if (index > list_length) {
    index = list_length;
  }

  // If no slice length is given, get only one element. If slice length
  // is given as 0, get entire list.
  intptr_t slice_length = msgbuf_->GetOptIntParam("length", 1);
  if (slice_length == 0) {
    slice_length = list_length - index;
  }
  if ((index + slice_length) > list_length) {
    slice_length = list_length - index;
  }
  ASSERT(slice_length >= 0);
  if (slice_length > kDefaultSliceLength) {
    slice_length = kDefaultSliceLength;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  if (slice_length == 1) {
    Dart_Handle value = Dart_ListGetAt(list, index);
    FormatRemoteObj(&msg, value);
  } else {
    FormatListSlice(&msg, list, list_length, index, slice_length);
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


void DebuggerConnectionHandler::HandleGetLibPropsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  intptr_t lib_id = msgbuf_->GetIntParam("libraryId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatLibraryProps(&msg, lib_id);
  if (err != NULL) {
    SendError(msg_id, err);
    return;
  }
  msg.Printf("}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleSetLibPropsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  intptr_t lib_id = msgbuf_->GetIntParam("libraryId");
  const char* enable_request = msgbuf_->GetStringParam("debuggingEnabled");
  bool enable;
  if (strcmp(enable_request, "true") == 0) {
    enable = true;
  } else if (strcmp(enable_request, "false") == 0) {
    enable = false;
  } else {
    SendError(msg_id, "illegal argument for 'debuggingEnabled'");
    return;
  }
  Dart_Handle res = Dart_SetLibraryDebuggable(lib_id, enable);
  if (Dart_IsError(res)) {
    SendError(msg_id, Dart_GetError(res));
    return;
  }
  bool enabled = false;
  res = Dart_GetLibraryDebuggable(lib_id, &enabled);
  if (Dart_IsError(res)) {
    SendError(msg_id, Dart_GetError(res));
    return;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\": {\"debuggingEnabled\": \"%s\"}}",
             msg_id,
             enabled ? "true" : "false");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::HandleGetGlobalsCmd(const char* json_msg) {
  int msg_id = msgbuf_->MessageId();
  intptr_t lib_id = msgbuf_->GetIntParam("libraryId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\": { \"globals\":", msg_id);
  Dart_Handle globals = Dart_GetGlobalVariables(lib_id);
  ASSERT_NOT_ERROR(globals);
  FormatNamedValueList(&msg, globals);
  msg.Printf("}}");
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
    { "getLibraries", HandleGetLibrariesCmd },
    { "getClassProperties", HandleGetClassPropsCmd },
    { "getLibraryProperties", HandleGetLibPropsCmd },
    { "setLibraryProperties", HandleSetLibPropsCmd },
    { "getObjectProperties", HandleGetObjPropsCmd },
    { "getListElements", HandleGetListCmd },
    { "getGlobalVariables", HandleGetGlobalsCmd },
    { "getScriptURLs", HandleGetScriptURLsCmd },
    { "getScriptSource", HandleGetSourceCmd },
    { "getStackTrace", HandleGetStackTraceCmd },
    { "setBreakpoint", HandleSetBpCmd },
    { "setPauseOnException", HandlePauseOnExcCmd },
    { "removeBreakpoint", HandleRemBpCmd },
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


void DebuggerConnectionHandler::WaitForConnection() {
  MonitorLocker ml(&is_connected_);
  while (!IsConnected()) {
    dart::Monitor::WaitResult res = ml.Wait(dart::Monitor::kNoTimeout);
    ASSERT(res == dart::Monitor::kNotified);
  }
}


void DebuggerConnectionHandler::SendBreakpointEvent(Dart_StackTrace trace) {
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"paused\", \"params\": { ");
  msg.Printf("\"reason\": \"breakpoint\", ");
  FormatCallFrames(&msg, trace);
  msg.Printf("}}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::BreakpointHandler(Dart_Breakpoint bpt,
                                                  Dart_StackTrace trace) {
  WaitForConnection();
  Dart_EnterScope();
  SendQueuedMsgs();
  SendBreakpointEvent(trace);
  HandleMessages();
  if (!msgbuf_->Alive()) {
    CloseDbgConnection();
  }
  Dart_ExitScope();
}


void DebuggerConnectionHandler::SendExceptionEvent(
                                    Dart_Handle exception,
                                    Dart_StackTrace stack_trace) {
  intptr_t exception_id = Dart_CacheObject(exception);
  ASSERT(exception_id >= 0);
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"paused\", \"params\": {");
  msg.Printf("\"reason\": \"exception\", ");
  msg.Printf("\"exception\":");
  FormatRemoteObj(&msg, exception);
  msg.Printf(", ");
  FormatCallFrames(&msg, stack_trace);
  msg.Printf("}}");
  SendMsg(&msg);
}


void DebuggerConnectionHandler::ExceptionThrownHandler(
                                    Dart_Handle exception,
                                    Dart_StackTrace stack_trace) {
  WaitForConnection();
  Dart_EnterScope();
  SendQueuedMsgs();
  SendExceptionEvent(exception, stack_trace);
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
  msg.Printf("\"breakpointId\": %"Pd", \"url\":", bp_id);
  FormatEncodedString(&msg, url);
  msg.Printf(",\"line\": %"Pd" }}", line_number);
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
  Dart_SetExceptionThrownHandler(ExceptionThrownHandler);
}


DebuggerConnectionHandler::~DebuggerConnectionHandler() {
  CloseDbgConnection();
}
