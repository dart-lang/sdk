// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dbg_connection.h"
#include "bin/dbg_message.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/json.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"

bool MessageParser::IsValidMessage() const {
  if (buf_length_ == 0) {
    return false;
  }
  dart::JSONReader msg_reader(buf_);
  return msg_reader.EndOfObject() != NULL;
}


int MessageParser::MessageId() const {
  dart::JSONReader r(buf_);
  r.Seek("id");
  if (r.Type() == dart::JSONReader::kInteger) {
    return atoi(r.ValueChars());
  } else {
    return -1;
  }
}


const char* MessageParser::Params() const {
  dart::JSONReader r(buf_);
  r.Seek("params");
  if (r.Type() == dart::JSONReader::kObject) {
    return r.ValueChars();
  } else {
    return NULL;
  }
}


intptr_t MessageParser::GetIntParam(const char* name) const {
  const char* params = Params();
  ASSERT(params != NULL);
  dart::JSONReader r(params);
  r.Seek(name);
  ASSERT(r.Type() == dart::JSONReader::kInteger);
  return strtol(r.ValueChars(), NULL, 10);
}


intptr_t MessageParser::GetOptIntParam(const char* name,
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


char* MessageParser::GetStringParam(const char* name) const {
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


static void FormatTextualValue(dart::TextBuffer* buf, Dart_Handle object) {
  Dart_Handle text;
  if (Dart_IsNull(object)) {
    text = Dart_Null();
  } else {
    Dart_ExceptionPauseInfo savedState = Dart_GetExceptionPauseInfo();

    // TODO(hausner): Check whether recursive/reentrant pauses on exceptions
    // should be prevented in Debugger::SignalExceptionThrown() instead.
    if (savedState != kNoPauseOnExceptions) {
      Dart_Handle res = Dart_SetExceptionPauseInfo(kNoPauseOnExceptions);
      ASSERT_NOT_ERROR(res);
    }

    text = Dart_ToString(object);

    if (savedState != kNoPauseOnExceptions) {
      Dart_Handle res = Dart_SetExceptionPauseInfo(savedState);
      ASSERT_NOT_ERROR(res);
    }
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


typedef bool (*CommandHandler)(DbgMessage* msg);

struct JSONDebuggerCommand {
  const char* cmd_string;
  CommandHandler handler_function;
};


static JSONDebuggerCommand debugger_commands[] = {
  { "resume", DbgMessage::HandleResumeCmd },
  { "stepInto", DbgMessage::HandleStepIntoCmd },
  { "stepOut", DbgMessage::HandleStepOutCmd },
  { "stepOver", DbgMessage::HandleStepOverCmd },
  { "getLibraries", DbgMessage::HandleGetLibrariesCmd },
  { "getClassProperties", DbgMessage::HandleGetClassPropsCmd },
  { "getLibraryProperties", DbgMessage::HandleGetLibPropsCmd },
  { "setLibraryProperties", DbgMessage::HandleSetLibPropsCmd },
  { "getObjectProperties", DbgMessage::HandleGetObjPropsCmd },
  { "getListElements", DbgMessage::HandleGetListCmd },
  { "getGlobalVariables", DbgMessage::HandleGetGlobalsCmd },
  { "getScriptURLs", DbgMessage::HandleGetScriptURLsCmd },
  { "getScriptSource", DbgMessage::HandleGetSourceCmd },
  { "getStackTrace", DbgMessage::HandleGetStackTraceCmd },
  { "setBreakpoint", DbgMessage::HandleSetBpCmd },
  { "setPauseOnException", DbgMessage::HandlePauseOnExcCmd },
  { "removeBreakpoint", DbgMessage::HandleRemBpCmd },
  { NULL, NULL }
};


bool DbgMessage::HandleMessage() {
  // Dispatch to the appropriate handler for the command.
  int max_index = (sizeof(debugger_commands) / sizeof(JSONDebuggerCommand));
  ASSERT(cmd_idx_ < max_index);
  return (*debugger_commands[cmd_idx_].handler_function)(this);
}


void DbgMessage::SendReply(dart::TextBuffer* reply) {
  DebuggerConnectionHandler::SendMsg(debug_fd(), reply);
}


void DbgMessage::SendErrorReply(int msg_id, const char* err_msg) {
  DebuggerConnectionHandler::SendError(debug_fd(), msg_id, err_msg);
}


bool DbgMessage::HandleResumeCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d }", msg_id);
  in_msg->SendReply(&msg);
  return true;
}


bool DbgMessage::HandleStepIntoCmd(DbgMessage* in_msg) {
  Dart_Handle res = Dart_SetStepInto();
  ASSERT_NOT_ERROR(res);
  return HandleResumeCmd(in_msg);
}


bool DbgMessage::HandleStepOutCmd(DbgMessage* in_msg) {
  Dart_Handle res = Dart_SetStepOut();
  ASSERT_NOT_ERROR(res);
  return HandleResumeCmd(in_msg);
}


bool DbgMessage::HandleStepOverCmd(DbgMessage* in_msg) {
  Dart_Handle res = Dart_SetStepOver();
  ASSERT_NOT_ERROR(res);
  return HandleResumeCmd(in_msg);
}


bool DbgMessage::HandleGetLibrariesCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
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
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetClassPropsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t cls_id = msg_parser.GetIntParam("classId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatClassProps(&msg, cls_id);
  if (err != NULL) {
    in_msg->SendErrorReply(msg_id, err);
    return false;
  }
  msg.Printf("}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetLibPropsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t lib_id = msg_parser.GetIntParam("libraryId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatLibraryProps(&msg, lib_id);
  if (err != NULL) {
    in_msg->SendErrorReply(msg_id, err);
    return false;
  }
  msg.Printf("}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleSetLibPropsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t lib_id = msg_parser.GetIntParam("libraryId");
  const char* enable_request = msg_parser.GetStringParam("debuggingEnabled");
  bool enable;
  if (strcmp(enable_request, "true") == 0) {
    enable = true;
  } else if (strcmp(enable_request, "false") == 0) {
    enable = false;
  } else {
    in_msg->SendErrorReply(msg_id, "illegal argument for 'debuggingEnabled'");
    return false;
  }
  Dart_Handle res = Dart_SetLibraryDebuggable(lib_id, enable);
  if (Dart_IsError(res)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(res));
    return false;
  }
  bool enabled = false;
  res = Dart_GetLibraryDebuggable(lib_id, &enabled);
  if (Dart_IsError(res)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(res));
    return false;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\": {\"debuggingEnabled\": \"%s\"}}",
             msg_id,
             enabled ? "true" : "false");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetObjPropsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t obj_id = msg_parser.GetIntParam("objectId");
  Dart_Handle obj = Dart_GetCachedObject(obj_id);
  if (Dart_IsError(obj)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(obj));
    return false;
  }
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\":", msg_id);
  const char* err = FormatObjProps(&msg, obj);
  if (err != NULL) {
    in_msg->SendErrorReply(msg_id, err);
    return false;
  }
  msg.Printf("}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetListCmd(DbgMessage* in_msg) {
  const intptr_t kDefaultSliceLength = 100;
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t obj_id = msg_parser.GetIntParam("objectId");
  Dart_Handle list = Dart_GetCachedObject(obj_id);
  if (Dart_IsError(list)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(list));
    return false;
  }
  if (!Dart_IsList(list)) {
    in_msg->SendErrorReply(msg_id, "object is not a list");
    return false;
  }
  intptr_t list_length = 0;
  Dart_Handle res = Dart_ListLength(list, &list_length);
  if (Dart_IsError(res)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(res));
    return false;
  }

  intptr_t index = msg_parser.GetIntParam("index");
  if (index < 0) {
    index = 0;
  } else if (index > list_length) {
    index = list_length;
  }

  // If no slice length is given, get only one element. If slice length
  // is given as 0, get entire list.
  intptr_t slice_length = msg_parser.GetOptIntParam("length", 1);
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
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetGlobalsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  intptr_t lib_id = msg_parser.GetIntParam("libraryId");
  dart::TextBuffer msg(64);
  msg.Printf("{\"id\":%d, \"result\": { \"globals\":", msg_id);
  Dart_Handle globals = Dart_GetGlobalVariables(lib_id);
  ASSERT_NOT_ERROR(globals);
  FormatNamedValueList(&msg, globals);
  msg.Printf("}}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetScriptURLsCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  dart::TextBuffer msg(64);
  intptr_t lib_id = msg_parser.GetIntParam("libraryId");
  Dart_Handle lib_url = Dart_GetLibraryURL(lib_id);
  ASSERT_NOT_ERROR(lib_url);
  Dart_Handle urls = Dart_GetScriptURLs(lib_url);
  if (Dart_IsError(urls)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(urls));
    return false;
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
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetSourceCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  dart::TextBuffer msg(64);
  intptr_t lib_id = msg_parser.GetIntParam("libraryId");
  char* url_chars = msg_parser.GetStringParam("url");
  ASSERT(url_chars != NULL);
  Dart_Handle url = Dart_NewString(url_chars);
  ASSERT_NOT_ERROR(url);
  free(url_chars);
  url_chars = NULL;
  Dart_Handle source = Dart_ScriptGetSource(lib_id, url);
  if (Dart_IsError(source)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(source));
    return false;
  }
  msg.Printf("{ \"id\": %d, ", msg_id);
  msg.Printf("\"result\": { \"text\": ");
  FormatEncodedString(&msg, source);
  msg.Printf("}}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleGetStackTraceCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  Dart_StackTrace trace;
  Dart_Handle res = Dart_GetStackTrace(&trace);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(128);
  msg.Printf("{ \"id\": %d, \"result\": {", msg_id);
  FormatCallFrames(&msg, trace);
  msg.Printf("}}");
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleSetBpCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  char* url_chars = msg_parser.GetStringParam("url");
  ASSERT(url_chars != NULL);
  Dart_Handle url = Dart_NewString(url_chars);
  ASSERT_NOT_ERROR(url);
  free(url_chars);
  url_chars = NULL;
  intptr_t line_number = msg_parser.GetIntParam("line");
  Dart_Handle bp_id = Dart_SetBreakpoint(url, line_number);
  if (Dart_IsError(bp_id)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(bp_id));
    return false;
  }
  ASSERT(Dart_IsInteger(bp_id));
  uint64_t bp_id_value;
  Dart_Handle res = Dart_IntegerToUint64(bp_id, &bp_id_value);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(64);
  msg.Printf("{ \"id\": %d, \"result\": { \"breakpointId\": %"Pu64" }}",
             msg_id, bp_id_value);
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandlePauseOnExcCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  char* exc_chars = msg_parser.GetStringParam("exceptions");
  Dart_ExceptionPauseInfo info = kNoPauseOnExceptions;
  if (strcmp(exc_chars, "none") == 0) {
    info = kNoPauseOnExceptions;
  } else if (strcmp(exc_chars, "all") == 0) {
    info = kPauseOnAllExceptions;
  } else if (strcmp(exc_chars, "unhandled") == 0) {
    info = kPauseOnUnhandledExceptions;
  } else {
    in_msg->SendErrorReply(msg_id, "illegal value for parameter 'exceptions'");
    return false;
  }
  Dart_Handle res = Dart_SetExceptionPauseInfo(info);
  ASSERT_NOT_ERROR(res);
  dart::TextBuffer msg(32);
  msg.Printf("{ \"id\": %d }", msg_id);
  in_msg->SendReply(&msg);
  return false;
}


bool DbgMessage::HandleRemBpCmd(DbgMessage* in_msg) {
  ASSERT(in_msg != NULL);
  MessageParser msg_parser(in_msg->buffer(), in_msg->buffer_len());
  int msg_id = msg_parser.MessageId();
  int bpt_id = msg_parser.GetIntParam("breakpointId");
  Dart_Handle res = Dart_RemoveBreakpoint(bpt_id);
  if (Dart_IsError(res)) {
    in_msg->SendErrorReply(msg_id, Dart_GetError(res));
    return false;
  }
  dart::TextBuffer msg(32);
  msg.Printf("{ \"id\": %d }", msg_id);
  in_msg->SendReply(&msg);
  return false;
}


void DbgMessageQueue::AddMessage(int32_t cmd_idx,
                                 const char* start,
                                 const char* end,
                                 int debug_fd) {
  if ((end > start) && ((end - start) < kMaxInt32)) {
    MonitorLocker ml(&msg_queue_lock_);
    DbgMessage* msg = new DbgMessage(cmd_idx, start, end, debug_fd);
    if (msglist_head_ == NULL) {
      ASSERT(msglist_tail_ == NULL);
      msglist_head_ = msg;
      msglist_tail_ = msg;
      ml.Notify();
    } else {
      ASSERT(msglist_tail_ != NULL);
      msglist_tail_->set_next(msg);
      msglist_tail_ = msg;
    }
  }
}


void DbgMessageQueue::HandleMessages() {
  bool resume_requested = false;
  MonitorLocker ml(&msg_queue_lock_);
  is_running_ = false;
  while (!resume_requested) {
    while (msglist_head_ == NULL) {
      ASSERT(msglist_tail_ == NULL);
      dart::Monitor::WaitResult res = ml.Wait();  // Wait for debugger commands.
      ASSERT(res == dart::Monitor::kNotified);
    }
    while (msglist_head_ != NULL && !resume_requested) {
      ASSERT(msglist_tail_ != NULL);
      DbgMessage* msg = msglist_head_;
      msglist_head_ = msglist_head_->next();
      resume_requested = msg->HandleMessage();
      delete msg;
    }
    if (msglist_head_ == NULL) {
      msglist_tail_ = NULL;
    }
  }
  is_running_ = true;
}


void DbgMessageQueue::QueueOutputMsg(dart::TextBuffer* msg) {
  queued_output_messages_.Printf("%s", msg->buf());
}


void DbgMessageQueue::SendQueuedMsgs() {
  if (queued_output_messages_.length() > 0) {
    DebuggerConnectionHandler::BroadcastMsg(&queued_output_messages_);
    queued_output_messages_.Clear();
  }
}


void DbgMessageQueue::SendBreakpointEvent(Dart_StackTrace trace) {
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"paused\", \"params\": { ");
  msg.Printf("\"reason\": \"breakpoint\", ");
  FormatCallFrames(&msg, trace);
  msg.Printf("}}");
  DebuggerConnectionHandler::BroadcastMsg(&msg);
}


void DbgMessageQueue::SendExceptionEvent(Dart_Handle exception,
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
  DebuggerConnectionHandler::BroadcastMsg(&msg);
}


// TODO(asiva): Get rid of this static variable one we have a means
// for associating an isolate with a debugger message queue object.
static DbgMessageQueue* message_queue = NULL;


void DbgMessageQueue::Initialize() {
  // TODO(asiva): Need to setup a message queue when an Isolate is created.
  // For now we use a static message queue object as we are only supporting
  // debugging of a single isolate.
  message_queue = new DbgMessageQueue();

  // Setup handlers for isolate events, breakpoints, exceptions and
  // delayed breakpoints.
  Dart_SetIsolateEventHandler(IsolateEventHandler);
  Dart_SetBreakpointHandler(BreakpointHandler);
  Dart_SetBreakpointResolvedHandler(BptResolvedHandler);
  Dart_SetExceptionThrownHandler(ExceptionThrownHandler);
}


int32_t DbgMessageQueue::LookupIsolateCommand(const char* buf,
                                              int32_t buflen) {
  // Check if we have a isolate specific debugger command.
  int32_t i = 0;
  while (debugger_commands[i].cmd_string != NULL) {
    if (strncmp(buf, debugger_commands[i].cmd_string, buflen) == 0) {
      return i;
    }
    i++;
  }
  return kInvalidCommand;
}


DbgMessageQueue* DbgMessageQueue::GetIsolateMessageQueue(Dart_Isolate isolate) {
  // TODO(asiva): Return a message queue corresponding to the isolate.
  // For now we use a static message queue object as we are only supporting
  // debugging of a single isolate.
  return message_queue;
}


void DbgMessageQueue::BptResolvedHandler(intptr_t bp_id,
                                         Dart_Handle url,
                                         intptr_t line_number) {
  Dart_EnterScope();
  dart::TextBuffer msg(128);
  msg.Printf("{ \"event\": \"breakpointResolved\", \"params\": {");
  msg.Printf("\"breakpointId\": %"Pd", \"url\":", bp_id);
  FormatEncodedString(&msg, url);
  msg.Printf(",\"line\": %"Pd" }}", line_number);
  DbgMessageQueue* msg_queue = GetIsolateMessageQueue(Dart_CurrentIsolate());
  ASSERT(msg_queue != NULL);
  msg_queue->QueueOutputMsg(&msg);
  Dart_ExitScope();
}


void DbgMessageQueue::BreakpointHandler(Dart_Breakpoint bpt,
                                        Dart_StackTrace trace) {
  DebuggerConnectionHandler::WaitForConnection();
  Dart_EnterScope();
  DbgMessageQueue* msg_queue = GetIsolateMessageQueue(Dart_CurrentIsolate());
  ASSERT(msg_queue != NULL);
  msg_queue->SendQueuedMsgs();
  msg_queue->SendBreakpointEvent(trace);
  msg_queue->HandleMessages();
  Dart_ExitScope();
}


void DbgMessageQueue::ExceptionThrownHandler(Dart_Handle exception,
                                             Dart_StackTrace stack_trace) {
  DebuggerConnectionHandler::WaitForConnection();
  Dart_EnterScope();
  DbgMessageQueue* msg_queue = GetIsolateMessageQueue(Dart_CurrentIsolate());
  ASSERT(msg_queue != NULL);
  msg_queue->SendQueuedMsgs();
  msg_queue->SendExceptionEvent(exception, stack_trace);
  msg_queue->HandleMessages();
  Dart_ExitScope();
}


void DbgMessageQueue::IsolateEventHandler(Dart_IsolateId isolate_id,
                                          Dart_IsolateEvent kind) {
  DebuggerConnectionHandler::WaitForConnection();
  // TODO(asiva): Add code to send isolate events over to the debugger client.
}
