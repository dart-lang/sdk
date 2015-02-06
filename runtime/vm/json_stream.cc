// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/json_stream.h"
#include "vm/message.h"
#include "vm/metrics.h"
#include "vm/object.h"
#include "vm/unicode.h"


namespace dart {

DECLARE_FLAG(bool, trace_service);

JSONStream::JSONStream(intptr_t buf_size)
    : open_objects_(0),
      buffer_(buf_size),
      reply_port_(ILLEGAL_PORT),
      method_(""),
      param_keys_(NULL),
      param_values_(NULL),
      num_params_(0) {
}


JSONStream::~JSONStream() {
}


void JSONStream::Setup(Zone* zone,
                       Dart_Port reply_port,
                       const String& method,
                       const Array& param_keys,
                       const Array& param_values) {
  set_reply_port(reply_port);
  method_ = method.ToCString();

  String& string_iterator = String::Handle();
  if (param_keys.Length() > 0) {
    ASSERT(param_keys.Length() == param_values.Length());
    const char** param_keys_native =
        zone->Alloc<const char*>(param_keys.Length());
    const char** param_values_native =
        zone->Alloc<const char*>(param_keys.Length());
    for (intptr_t i = 0; i < param_keys.Length(); i++) {
      string_iterator ^= param_keys.At(i);
      param_keys_native[i] =
          zone->MakeCopyOfString(string_iterator.ToCString());
      string_iterator ^= param_values.At(i);
      param_values_native[i] =
          zone->MakeCopyOfString(string_iterator.ToCString());
    }
    SetParams(param_keys_native, param_values_native, param_keys.Length());
  }
  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    const char* isolate_name = isolate->name();
    OS::Print("Isolate %s processing service request %s\n",
              isolate_name, method_);
    setup_time_micros_ = OS::GetCurrentTimeMicros();
  }
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


void JSONStream::PostReply() {
  Dart_Port port = reply_port();
  ASSERT(port != ILLEGAL_PORT);
  set_reply_port(ILLEGAL_PORT);  // Prevent double replies.
  int64_t process_delta_micros = 0;
  if (FLAG_trace_service) {
    process_delta_micros = OS::GetCurrentTimeMicros() - setup_time_micros_;
  }
  const String& reply = String::Handle(String::New(ToCString()));
  ASSERT(!reply.IsNull());

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(reply);
  PortMap::PostMessage(new Message(port, data,
                                   writer.BytesWritten(),
                                   Message::kNormalPriority));
  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    const char* isolate_name = isolate->name();
    OS::Print("Isolate %s processed service request %s in %" Pd64" us.\n",
              isolate_name, method_, process_delta_micros);
  }
}


const char* JSONStream::LookupParam(const char* key) const {
  for (int i = 0; i < num_params(); i++) {
    if (!strcmp(key, param_keys_[i])) {
      return param_values_[i];
    }
  }
  return NULL;
}


bool JSONStream::HasParam(const char* key) const {
  ASSERT(key);
  return LookupParam(key) != NULL;
}


bool JSONStream::ParamIs(const char* key, const char* value) const {
  ASSERT(key);
  ASSERT(value);
  const char* key_value = LookupParam(key);
  return (key_value != NULL) && (strcmp(key_value, value) == 0);
}


void JSONStream::Clear() {
  buffer_.Clear();
  open_objects_ = 0;
}


void JSONStream::OpenObject(const char* property_name) {
  PrintCommaIfNeeded();
  open_objects_++;
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  buffer_.AddChar('{');
}


void JSONStream::CloseObject() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_.AddChar('}');
}


void JSONStream::OpenArray(const char* property_name) {
  PrintCommaIfNeeded();
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  open_objects_++;
  buffer_.AddChar('[');
}


void JSONStream::CloseArray() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_.AddChar(']');
}


void JSONStream::PrintValueBool(bool b) {
  PrintCommaIfNeeded();
  buffer_.Printf("%s", b ? "true" : "false");
}


void JSONStream::PrintValue(intptr_t i) {
  PrintCommaIfNeeded();
  buffer_.Printf("%" Pd "", i);
}


void JSONStream::PrintValue64(int64_t i) {
  PrintCommaIfNeeded();
  buffer_.Printf("%" Pd64 "", i);
}


void JSONStream::PrintValue(double d) {
  PrintCommaIfNeeded();
  buffer_.Printf("%f", d);
}


void JSONStream::PrintValue(const char* s) {
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  AddEscapedUTF8String(s);
  buffer_.AddChar('"');
}


bool JSONStream::PrintValueStr(const String& s, intptr_t limit) {
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  bool did_truncate = AddDartString(s, limit);
  buffer_.AddChar('"');
  return did_truncate;
}


void JSONStream::PrintValueNoEscape(const char* s) {
  PrintCommaIfNeeded();
  buffer_.Printf("%s", s);
}


void JSONStream::PrintfValue(const char* format, ...) {
  PrintCommaIfNeeded();

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len+1, format, args);
  va_end(args);
  ASSERT(len == len2);
  buffer_.AddChar('"');
  AddEscapedUTF8String(p);
  buffer_.AddChar('"');
  free(p);
}


void JSONStream::PrintValue(const Object& o, bool ref) {
  PrintCommaIfNeeded();
  o.PrintJSON(this, ref);
}


void JSONStream::PrintValue(SourceBreakpoint* bpt) {
  PrintCommaIfNeeded();
  bpt->PrintJSON(this);
}


void JSONStream::PrintValue(const DebuggerEvent* event) {
  PrintCommaIfNeeded();
  event->PrintJSON(this);
}


void JSONStream::PrintValue(Metric* metric) {
  PrintCommaIfNeeded();
  metric->PrintJSON(this);
}


void JSONStream::PrintValue(Isolate* isolate, bool ref) {
  PrintCommaIfNeeded();
  isolate->PrintJSON(this, ref);
}


void JSONStream::PrintPropertyBool(const char* name, bool b) {
  PrintPropertyName(name);
  PrintValueBool(b);
}


void JSONStream::PrintProperty(const char* name, intptr_t i) {
  PrintPropertyName(name);
  PrintValue(i);
}


void JSONStream::PrintProperty64(const char* name, int64_t i) {
  PrintPropertyName(name);
  PrintValue64(i);
}


void JSONStream::PrintProperty(const char* name, double d) {
  PrintPropertyName(name);
  PrintValue(d);
}


void JSONStream::PrintProperty(const char* name, const char* s) {
  PrintPropertyName(name);
  PrintValue(s);
}


bool JSONStream::PrintPropertyStr(const char* name,
                                  const String& s,
                                  intptr_t limit) {
  PrintPropertyName(name);
  return PrintValueStr(s, limit);
}


void JSONStream::PrintPropertyNoEscape(const char* name, const char* s) {
  PrintPropertyName(name);
  PrintValueNoEscape(s);
}


void JSONStream::PrintProperty(const char* name, const DebuggerEvent* event) {
  PrintPropertyName(name);
  PrintValue(event);
}


void JSONStream::PrintProperty(const char* name, SourceBreakpoint* bpt) {
  PrintPropertyName(name);
  PrintValue(bpt);
}


void JSONStream::PrintProperty(const char* name, Metric* metric) {
  PrintPropertyName(name);
  PrintValue(metric);
}

void JSONStream::PrintProperty(const char* name, Isolate* isolate) {
  PrintPropertyName(name);
  PrintValue(isolate);
}


void JSONStream::PrintfProperty(const char* name, const char* format, ...) {
  PrintPropertyName(name);
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len+1, format, args);
  va_end(args);
  ASSERT(len == len2);
  buffer_.AddChar('"');
  AddEscapedUTF8String(p);
  buffer_.AddChar('"');
  free(p);
}


void JSONStream::set_reply_port(Dart_Port port) {
  reply_port_ = port;
}


void JSONStream::SetParams(const char** param_keys,
                           const char** param_values,
                           intptr_t num_params) {
  param_keys_ = param_keys;
  param_values_ = param_values;
  num_params_ = num_params;
}


void JSONStream::PrintProperty(const char* name, const Object& o, bool ref) {
  PrintPropertyName(name);
  PrintValue(o, ref);
}


void JSONStream::PrintPropertyName(const char* name) {
  ASSERT(name != NULL);
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  AddEscapedUTF8String(name);
  buffer_.AddChar('"');
  buffer_.AddChar(':');
}


void JSONStream::PrintCommaIfNeeded() {
  if (NeedComma()) {
    buffer_.AddChar(',');
  }
}


bool JSONStream::NeedComma() {
  const char* buffer = buffer_.buf();
  intptr_t length = buffer_.length();
  if (length == 0) {
    return false;
  }
  char ch = buffer[length-1];
  return (ch != '[') && (ch != '{') && (ch != ':') && (ch != ',');
}


void JSONStream::AddEscapedUTF8String(const char* s) {
  if (s == NULL) {
    return;
  }
  intptr_t len = strlen(s);
  AddEscapedUTF8String(s, len);
}


void JSONStream::AddEscapedUTF8String(const char* s, intptr_t len) {
  if (s == NULL) {
    return;
  }
  const uint8_t* s8 = reinterpret_cast<const uint8_t*>(s);
  intptr_t i = 0;
  for (; i < len; ) {
    // Extract next UTF8 character.
    int32_t ch = 0;
    int32_t ch_len = Utf8::Decode(&s8[i], len - i, &ch);
    ASSERT(ch_len != 0);
    buffer_.EscapeAndAddCodeUnit(ch);
    // Move i forward.
    i += ch_len;
  }
  ASSERT(i == len);
}


bool JSONStream::AddDartString(const String& s, intptr_t limit) {
  bool did_truncate = false;
  intptr_t length = s.Length();
  if (limit == -1) {
    limit = length;
  }
  if (length <= limit) {
    limit = length;
  } else {
    did_truncate = true;
  }

  for (intptr_t i = 0; i < limit; i++) {
    intptr_t code_unit = s.CharAt(i);
    buffer_.EscapeAndAddCodeUnit(code_unit);
  }
  return did_truncate;
}


JSONObject::JSONObject(const JSONArray* arr) : stream_(arr->stream_) {
  stream_->OpenObject();
}


void JSONObject::AddPropertyF(const char* name,
                              const char* format, ...) const {
  stream_->PrintPropertyName(name);
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len+1, format, args);
  va_end(args);
  ASSERT(len == len2);
  stream_->buffer_.AddChar('"');
  stream_->AddEscapedUTF8String(p);
  stream_->buffer_.AddChar('"');
  free(p);
}


void JSONArray::AddValueF(const char* format, ...) const {
  stream_->PrintCommaIfNeeded();
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len+1, format, args);
  va_end(args);
  ASSERT(len == len2);
  stream_->buffer_.AddChar('"');
  stream_->AddEscapedUTF8String(p);
  stream_->buffer_.AddChar('"');
  free(p);
}

}  // namespace dart
