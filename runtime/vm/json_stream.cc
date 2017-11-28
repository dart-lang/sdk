// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "include/dart_native_api.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/json_stream.h"
#include "vm/message.h"
#include "vm/metrics.h"
#include "vm/object.h"
#include "vm/safepoint.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/unicode.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, trace_service);

JSONStream::JSONStream(intptr_t buf_size)
    : writer_(buf_size),
      default_id_zone_(),
      id_zone_(&default_id_zone_),
      reply_port_(ILLEGAL_PORT),
      seq_(NULL),
      parameter_keys_(NULL),
      parameter_values_(NULL),
      method_(""),
      param_keys_(NULL),
      param_values_(NULL),
      num_params_(0),
      offset_(0),
      count_(-1) {
  ObjectIdRing* ring = NULL;
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    ring = isolate->object_id_ring();
  }
  default_id_zone_.Init(ring, ObjectIdRing::kAllocateId);
}

void JSONStream::Setup(Zone* zone,
                       Dart_Port reply_port,
                       const Instance& seq,
                       const String& method,
                       const Array& param_keys,
                       const Array& param_values,
                       bool parameters_are_dart_objects) {
  set_reply_port(reply_port);
  seq_ = &Instance::ZoneHandle(seq.raw());
  method_ = method.ToCString();

  if (parameters_are_dart_objects) {
    parameter_keys_ = &Array::ZoneHandle(param_keys.raw());
    parameter_values_ = &Array::ZoneHandle(param_values.raw());
    ASSERT(parameter_keys_->Length() == parameter_values_->Length());
  } else if (param_keys.Length() > 0) {
    String& string_iterator = String::Handle();
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
    int64_t main_port = static_cast<int64_t>(isolate->main_port());
    const char* isolate_name = isolate->name();
    setup_time_micros_ = OS::GetCurrentTimeMicros();
    OS::PrintErr("[+%" Pd64 "ms] Isolate (%" Pd64
                 ") %s processing service "
                 "request %s\n",
                 Dart::UptimeMillis(), main_port, isolate_name, method_);
  }
  buffer()->Printf("{\"jsonrpc\":\"2.0\", \"result\":");
}

void JSONStream::SetupError() {
  Clear();
  buffer()->Printf("{\"jsonrpc\":\"2.0\", \"error\":");
}

static const char* GetJSONRpcErrorMessage(intptr_t code) {
  switch (code) {
    case kParseError:
      return "Parse error";
    case kInvalidRequest:
      return "Invalid Request";
    case kMethodNotFound:
      return "Method not found";
    case kInvalidParams:
      return "Invalid params";
    case kInternalError:
      return "Internal error";
    case kFeatureDisabled:
      return "Feature is disabled";
    case kCannotAddBreakpoint:
      return "Cannot add breakpoint";
    case kStreamAlreadySubscribed:
      return "Stream already subscribed";
    case kStreamNotSubscribed:
      return "Stream not subscribed";
    case kIsolateMustBeRunnable:
      return "Isolate must be runnable";
    case kIsolateMustBePaused:
      return "Isolate must be paused";
    case kCannotResume:
      return "Cannot resume execution";
    case kIsolateIsReloading:
      return "Isolate is reloading";
    case kIsolateReloadBarred:
      return "Isolate cannot be reloaded";
    case kIsolateMustHaveReloaded:
      return "Isolate must have reloaded";
    case kFileSystemAlreadyExists:
      return "File system already exists";
    case kFileSystemDoesNotExist:
      return "File system does not exist";
    case kFileDoesNotExist:
      return "File does not exist";
    default:
      return "Extension error";
  }
}

static void PrintRequest(JSONObject* obj, JSONStream* js) {
  JSONObject jsobj(obj, "request");
  jsobj.AddProperty("method", js->method());
  {
    JSONObject params(&jsobj, "params");
    for (intptr_t i = 0; i < js->num_params(); i++) {
      params.AddProperty(js->GetParamKey(i), js->GetParamValue(i));
    }
  }
}

void JSONStream::PrintError(intptr_t code, const char* details_format, ...) {
  SetupError();
  JSONObject jsobj(this);
  jsobj.AddProperty("code", code);
  jsobj.AddProperty("message", GetJSONRpcErrorMessage(code));
  {
    JSONObject data(&jsobj, "data");
    PrintRequest(&data, this);
    if (details_format != NULL) {
      va_list args;
      va_start(args, details_format);
      intptr_t len = OS::VSNPrint(NULL, 0, details_format, args);
      va_end(args);

      char* buffer = Thread::Current()->zone()->Alloc<char>(len + 1);
      va_list args2;
      va_start(args2, details_format);
      OS::VSNPrint(buffer, (len + 1), details_format, args2);
      va_end(args2);

      data.AddProperty("details", buffer);
    }
  }
}

void JSONStream::PostNullReply(Dart_Port port) {
  PortMap::PostMessage(
      new Message(port, Object::null(), Message::kNormalPriority));
}

static void Finalizer(void* isolate_callback_data,
                      Dart_WeakPersistentHandle handle,
                      void* buffer) {
  free(buffer);
}

void JSONStream::PostReply() {
  ASSERT(seq_ != NULL);
  Dart_Port port = reply_port();
  set_reply_port(ILLEGAL_PORT);  // Prevent double replies.
  if (seq_->IsString()) {
    const String& str = String::Cast(*seq_);
    PrintProperty("id", str.ToCString());
  } else if (seq_->IsInteger()) {
    const Integer& integer = Integer::Cast(*seq_);
    PrintProperty64("id", integer.AsInt64Value());
  } else if (seq_->IsDouble()) {
    const Double& dbl = Double::Cast(*seq_);
    PrintProperty("id", dbl.value());
  } else if (seq_->IsNull()) {
    if (port == ILLEGAL_PORT) {
      // This path is only used in tests.
      buffer()->AddChar('}');  // Finish our message.
      char* cstr;
      intptr_t length;
      Steal(&cstr, &length);
      OS::PrintErr("-----\nDropping reply:\n%s\n-----\n", cstr);
      free(cstr);
    }
    // JSON-RPC 2.0 says that a request with a null ID shouldn't get a reply.
    PostNullReply(port);
    return;
  }
  ASSERT(port != ILLEGAL_PORT);

  buffer()->AddChar('}');  // Finish our message.
  char* cstr;
  intptr_t length;
  Steal(&cstr, &length);

  bool result;
  {
    TransitionVMToNative transition(Thread::Current());
    Dart_CObject bytes;
    bytes.type = Dart_CObject_kExternalTypedData;
    bytes.value.as_external_typed_data.type = Dart_TypedData_kUint8;
    bytes.value.as_external_typed_data.length = length;
    bytes.value.as_external_typed_data.data = reinterpret_cast<uint8_t*>(cstr);
    bytes.value.as_external_typed_data.peer = cstr;
    bytes.value.as_external_typed_data.callback = Finalizer;
    Dart_CObject* elements[1];
    elements[0] = &bytes;
    Dart_CObject message;
    message.type = Dart_CObject_kArray;
    message.value.as_array.length = 1;
    message.value.as_array.values = elements;
    result = Dart_PostCObject(port, &message);
  }

  if (!result) {
    free(cstr);
  }

  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    int64_t main_port = static_cast<int64_t>(isolate->main_port());
    const char* isolate_name = isolate->name();
    int64_t total_time = OS::GetCurrentTimeMicros() - setup_time_micros_;
    if (result) {
      OS::PrintErr("[+%" Pd64 "ms] Isolate (%" Pd64
                   ") %s processed service request %s (%" Pd64 "us)\n",
                   Dart::UptimeMillis(), main_port, isolate_name, method_,
                   total_time);
    } else {
      OS::PrintErr("[+%" Pd64 "ms] Isolate (%" Pd64
                   ") %s processed service request %s (%" Pd64 "us) FAILED\n",
                   Dart::UptimeMillis(), main_port, isolate_name, method_,
                   total_time);
    }
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

void JSONStream::ComputeOffsetAndCount(intptr_t length,
                                       intptr_t* offset,
                                       intptr_t* count) {
  // This function is written to avoid adding (count + offset) in case
  // that triggers an integer overflow.
  *offset = offset_;
  if (*offset > length) {
    *offset = length;
  }
  intptr_t remaining = length - *offset;
  *count = count_;
  if (*count < 0 || *count > remaining) {
    *count = remaining;
  }
}
void JSONStream::PrintfValue(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VPrintfValue(format, args);
  va_end(args);
}

void JSONStream::PrintValue(const Object& o, bool ref) {
  PrintCommaIfNeeded();
  o.PrintJSON(this, ref);
}

void JSONStream::PrintValue(Breakpoint* bpt) {
  PrintCommaIfNeeded();
  bpt->PrintJSON(this);
}

void JSONStream::PrintValue(TokenPosition tp) {
  PrintCommaIfNeeded();
  PrintValue(tp.value());
}

void JSONStream::PrintValue(const ServiceEvent* event) {
  PrintCommaIfNeeded();
  event->PrintJSON(this);
}

void JSONStream::PrintValue(Metric* metric) {
  PrintCommaIfNeeded();
  metric->PrintJSON(this);
}

void JSONStream::PrintValue(MessageQueue* queue) {
  PrintCommaIfNeeded();
  queue->PrintJSON(this);
}

void JSONStream::PrintValue(Isolate* isolate, bool ref) {
  PrintCommaIfNeeded();
  isolate->PrintJSON(this, ref);
}

void JSONStream::PrintValue(ThreadRegistry* reg) {
  PrintCommaIfNeeded();
  reg->PrintJSON(this);
}

void JSONStream::PrintValue(Thread* thread) {
  PrintCommaIfNeeded();
  thread->PrintJSON(this);
}

void JSONStream::PrintValue(const TimelineEvent* timeline_event) {
  PrintCommaIfNeeded();
  timeline_event->PrintJSON(this);
}

void JSONStream::PrintValue(const TimelineEventBlock* timeline_event_block) {
  PrintCommaIfNeeded();
  timeline_event_block->PrintJSON(this);
}

void JSONStream::PrintValueVM(bool ref) {
  PrintCommaIfNeeded();
  Service::PrintJSONForVM(this, ref);
}

void JSONStream::PrintServiceId(const Object& o) {
  ASSERT(id_zone_ != NULL);
  PrintProperty("id", id_zone_->GetServiceId(o));
}

void JSONStream::PrintProperty(const char* name, const ServiceEvent* event) {
  PrintPropertyName(name);
  PrintValue(event);
}

void JSONStream::PrintProperty(const char* name, Breakpoint* bpt) {
  PrintPropertyName(name);
  PrintValue(bpt);
}

void JSONStream::PrintProperty(const char* name, TokenPosition tp) {
  PrintPropertyName(name);
  PrintValue(tp);
}

void JSONStream::PrintProperty(const char* name, Metric* metric) {
  PrintPropertyName(name);
  PrintValue(metric);
}

void JSONStream::PrintProperty(const char* name, MessageQueue* queue) {
  PrintPropertyName(name);
  PrintValue(queue);
}

void JSONStream::PrintProperty(const char* name, Isolate* isolate) {
  PrintPropertyName(name);
  PrintValue(isolate);
}

void JSONStream::PrintProperty(const char* name, ThreadRegistry* reg) {
  PrintPropertyName(name);
  PrintValue(reg);
}

void JSONStream::PrintProperty(const char* name, Thread* thread) {
  PrintPropertyName(name);
  PrintValue(thread);
}

void JSONStream::PrintProperty(const char* name,
                               const TimelineEvent* timeline_event) {
  PrintPropertyName(name);
  PrintValue(timeline_event);
}

void JSONStream::PrintProperty(const char* name,
                               const TimelineEventBlock* timeline_event_block) {
  PrintPropertyName(name);
  PrintValue(timeline_event_block);
}

void JSONStream::PrintfProperty(const char* name, const char* format, ...) {
  va_list args;
  va_start(args, format);
  writer_.VPrintfProperty(name, format, args);
  va_end(args);
}

void JSONStream::set_reply_port(Dart_Port port) {
  reply_port_ = port;
}

intptr_t JSONStream::NumObjectParameters() const {
  if (parameter_keys_ == NULL) {
    return 0;
  }
  ASSERT(parameter_keys_ != NULL);
  ASSERT(parameter_values_ != NULL);
  return parameter_keys_->Length();
}

RawObject* JSONStream::GetObjectParameterKey(intptr_t i) const {
  ASSERT((i >= 0) && (i < NumObjectParameters()));
  return parameter_keys_->At(i);
}

RawObject* JSONStream::GetObjectParameterValue(intptr_t i) const {
  ASSERT((i >= 0) && (i < NumObjectParameters()));
  return parameter_values_->At(i);
}

RawObject* JSONStream::LookupObjectParam(const char* c_key) const {
  const String& key = String::Handle(String::New(c_key));
  Object& test = Object::Handle();
  const intptr_t num_object_parameters = NumObjectParameters();
  for (intptr_t i = 0; i < num_object_parameters; i++) {
    test = GetObjectParameterKey(i);
    if (test.IsString() && String::Cast(test).Equals(key)) {
      return GetObjectParameterValue(i);
    }
  }
  return Object::null();
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

void JSONStream::PrintPropertyVM(const char* name, bool ref) {
  PrintPropertyName(name);
  PrintValueVM(ref);
}

JSONObject::JSONObject(const JSONArray* arr) : stream_(arr->stream_) {
  stream_->OpenObject();
}

void JSONObject::AddFixedServiceId(const char* format, ...) const {
  // Mark that this id is fixed.
  AddProperty("fixedId", true);
  // Add the id property.
  va_list args;
  va_start(args, format);
  stream_->VPrintfProperty("id", format, args);
  va_end(args);
}

void JSONObject::AddLocation(const Script& script,
                             TokenPosition token_pos,
                             TokenPosition end_token_pos) const {
  JSONObject location(this, "location");
  location.AddProperty("type", "SourceLocation");
  location.AddProperty("script", script);
  location.AddProperty("tokenPos", token_pos);
  if (end_token_pos.IsReal()) {
    location.AddProperty("endTokenPos", end_token_pos);
  }
}

void JSONObject::AddLocation(const BreakpointLocation* bpt_loc) const {
  ASSERT(bpt_loc->IsResolved());

  Zone* zone = Thread::Current()->zone();
  Library& library = Library::Handle(zone);
  Script& script = Script::Handle(zone);
  TokenPosition token_pos = TokenPosition::kNoSource;
  bpt_loc->GetCodeLocation(&library, &script, &token_pos);
  AddLocation(script, token_pos);
}

void JSONObject::AddUnresolvedLocation(
    const BreakpointLocation* bpt_loc) const {
  ASSERT(!bpt_loc->IsResolved());

  Zone* zone = Thread::Current()->zone();
  Library& library = Library::Handle(zone);
  Script& script = Script::Handle(zone);
  TokenPosition token_pos = TokenPosition::kNoSource;
  bpt_loc->GetCodeLocation(&library, &script, &token_pos);

  JSONObject location(this, "location");
  location.AddProperty("type", "UnresolvedSourceLocation");
  if (!script.IsNull()) {
    location.AddProperty("script", script);
  } else {
    const String& scriptUri = String::Handle(zone, bpt_loc->url());
    location.AddPropertyStr("scriptUri", scriptUri);
  }
  if (bpt_loc->requested_line_number() >= 0) {
    // This unresolved breakpoint was specified at a particular line.
    location.AddProperty("line", bpt_loc->requested_line_number());
    if (bpt_loc->requested_column_number() >= 0) {
      location.AddProperty("column", bpt_loc->requested_column_number());
    }
  } else {
    // This unresolved breakpoint was requested at some function entry.
    location.AddProperty("tokenPos", token_pos);
  }
}

void JSONObject::AddPropertyF(const char* name, const char* format, ...) const {
  va_list args;
  va_start(args, format);
  stream_->VPrintfProperty(name, format, args);
  va_end(args);
}

void JSONArray::AddValueF(const char* format, ...) const {
  va_list args;
  va_start(args, format);
  stream_->VPrintfValue(format, args);
  va_end(args);
}

#endif  // !PRODUCT

}  // namespace dart
