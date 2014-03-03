// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/json_stream.h"
#include "vm/message.h"
#include "vm/object.h"


namespace dart {

DECLARE_FLAG(bool, trace_service);

JSONStream::JSONStream(intptr_t buf_size)
    : open_objects_(0),
      buffer_(buf_size),
      reply_port_(ILLEGAL_PORT),
      command_(""),
      arguments_(NULL),
      num_arguments_(0),
      option_keys_(NULL),
      option_values_(NULL),
      num_options_(0) {
}


JSONStream::~JSONStream() {
}


void JSONStream::Setup(Zone* zone,
                       const Instance& reply_port,
                       const GrowableObjectArray& path,
                       const GrowableObjectArray& option_keys,
                       const GrowableObjectArray& option_values) {
  // Setup the reply port.
  const Object& id_obj = Object::Handle(
      DartLibraryCalls::PortGetId(reply_port));
  if (id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(id_obj));
  }
  const Integer& id = Integer::Cast(id_obj);
  Dart_Port port = static_cast<Dart_Port>(id.AsInt64Value());
  ASSERT(port != ILLEGAL_PORT);
  set_reply_port(port);

  // Setup JSONStream arguments and options. The arguments and options
  // are zone allocated and will be freed immediately after handling the
  // message.
  const char** arguments = zone->Alloc<const char*>(path.Length());
  String& string_iterator = String::Handle();
  for (intptr_t i = 0; i < path.Length(); i++) {
    string_iterator ^= path.At(i);
    arguments[i] = zone->MakeCopyOfString(string_iterator.ToCString());
    if (i == 0) {
      command_ = arguments[i];
    }
  }
  SetArguments(arguments, path.Length());
  if (option_keys.Length() > 0) {
    const char** option_keys_native =
        zone->Alloc<const char*>(option_keys.Length());
    const char** option_values_native =
        zone->Alloc<const char*>(option_keys.Length());
    for (intptr_t i = 0; i < option_keys.Length(); i++) {
      string_iterator ^= option_keys.At(i);
      option_keys_native[i] =
          zone->MakeCopyOfString(string_iterator.ToCString());
      string_iterator ^= option_values.At(i);
      option_values_native[i] =
          zone->MakeCopyOfString(string_iterator.ToCString());
    }
    SetOptions(option_keys_native, option_values_native, option_keys.Length());
  }
  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    const char* isolate_name = isolate->name();
    OS::Print("Isolate %s processing service request /%s\n",
              isolate_name, command_);
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
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(reply);
  PortMap::PostMessage(new Message(port, data,
                                   writer.BytesWritten(),
                                   Message::kNormalPriority));
  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    const char* isolate_name = isolate->name();
    OS::Print("Isolate %s processed service request /%s in %" Pd64" us.\n",
              isolate_name, command_, process_delta_micros);
  }
}


const char* JSONStream::LookupOption(const char* key) const {
  for (int i = 0; i < num_options(); i++) {
    if (!strcmp(key, option_keys_[i])) {
      return option_values_[i];
    }
  }
  return NULL;
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
  buffer_.AddEscapedString(s);
  buffer_.AddChar('"');
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
  buffer_.AddEscapedString(p);
  buffer_.AddChar('"');
  free(p);
}


void JSONStream::PrintValue(const Object& o, bool ref) {
  PrintCommaIfNeeded();
  o.PrintToJSONStream(this, ref);
}


void JSONStream::PrintValue(SourceBreakpoint* bpt) {
  PrintCommaIfNeeded();
  bpt->PrintToJSONStream(this);
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
  buffer_.AddEscapedString(p);
  buffer_.AddChar('"');
  free(p);
}


void JSONStream::set_reply_port(Dart_Port port) {
  reply_port_ = port;
}


void JSONStream::SetArguments(const char** arguments, intptr_t num_arguments) {
  arguments_ = arguments;
  num_arguments_ = num_arguments;
}


void JSONStream::SetOptions(const char** option_keys,
                            const char** option_values,
                            intptr_t num_options) {
  option_keys_ = option_keys;
  option_values_ = option_values;
  num_options_ = num_options;
}


void JSONStream::PrintProperty(const char* name, const Object& o, bool ref) {
  PrintPropertyName(name);
  PrintValue(o, ref);
}


void JSONStream::PrintPropertyName(const char* name) {
  ASSERT(name != NULL);
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  buffer_.AddEscapedString(name);
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
  stream_->buffer_.AddEscapedString(p);
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
  stream_->buffer_.AddEscapedString(p);
  stream_->buffer_.AddChar('"');
  free(p);
}

}  // namespace dart
