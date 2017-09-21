// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_JSON_STREAM_H_
#define RUNTIME_VM_JSON_STREAM_H_

#include "include/dart_api.h"  // for Dart_Port
#include "platform/text_buffer.h"
#include "vm/allocation.h"
#include "vm/service.h"
#include "vm/token_position.h"

namespace dart {

class Array;
class Breakpoint;
class BreakpointLocation;
class Field;
class GrowableObjectArray;
class Instance;
class JSONArray;
class JSONObject;
class MessageQueue;
class Metric;
class Object;
class Script;
class ServiceEvent;
class String;
class TimelineEvent;
class TimelineEventBlock;
class Thread;
class ThreadRegistry;
class Zone;

// Keep this enum in sync with:
//
//  - runtime/vm/service/vmservice.dart
//  - runtime/observatory/lib/src/service/object.dart
//
enum JSONRpcErrorCode {
  kParseError = -32700,
  kInvalidRequest = -32600,
  kMethodNotFound = -32601,
  kInvalidParams = -32602,
  kInternalError = -32603,

  kExtensionError = -32000,

  kFeatureDisabled = 100,
  kCannotAddBreakpoint = 102,
  kStreamAlreadySubscribed = 103,
  kStreamNotSubscribed = 104,
  kIsolateMustBeRunnable = 105,
  kIsolateMustBePaused = 106,
  kCannotResume = 107,
  kIsolateIsReloading = 108,
  kIsolateReloadBarred = 109,
  kIsolateMustHaveReloaded = 110,

  // Experimental (used in private rpcs).
  kFileSystemAlreadyExists = 1001,
  kFileSystemDoesNotExist = 1002,
  kFileDoesNotExist = 1003,
};

class JSONStream : ValueObject {
 public:
  explicit JSONStream(intptr_t buf_size = 256);
  ~JSONStream();

  void Setup(Zone* zone,
             Dart_Port reply_port,
             const Instance& seq,
             const String& method,
             const Array& param_keys,
             const Array& param_values,
             bool parameters_are_dart_objects = false);
  void SetupError();

  void PrintError(intptr_t code, const char* details_format, ...);

  void PostReply();

  void set_id_zone(ServiceIdZone* id_zone) { id_zone_ = id_zone; }
  ServiceIdZone* id_zone() { return id_zone_; }

  TextBuffer* buffer() { return &buffer_; }
  const char* ToCString() { return buffer_.buf(); }

  void Steal(char** buffer, intptr_t* buffer_length);

  void set_reply_port(Dart_Port port);

  void SetParams(const char** param_keys,
                 const char** param_values,
                 intptr_t num_params);

  Dart_Port reply_port() const { return reply_port_; }

  intptr_t NumObjectParameters() const;
  RawObject* GetObjectParameterKey(intptr_t i) const;
  RawObject* GetObjectParameterValue(intptr_t i) const;
  RawObject* LookupObjectParam(const char* key) const;

  intptr_t num_params() const { return num_params_; }
  const char* GetParamKey(intptr_t i) const { return param_keys_[i]; }
  const char* GetParamValue(intptr_t i) const { return param_values_[i]; }

  const char* LookupParam(const char* key) const;

  bool HasParam(const char* key) const;

  // Returns true if there is an param with key and value, false
  // otherwise.
  bool ParamIs(const char* key, const char* value) const;

  const char* method() const { return method_; }
  const char** param_keys() const { return param_keys_; }
  const char** param_values() const { return param_values_; }

  void set_offset(intptr_t value) {
    ASSERT(value > 0);
    offset_ = value;
  }

  void set_count(intptr_t value) {
    ASSERT(value > 0);
    count_ = value;
  }

  void ComputeOffsetAndCount(intptr_t length,
                             intptr_t* offset,
                             intptr_t* count);

  // Append |serialized_object| to the stream.
  void AppendSerializedObject(const char* serialized_object);

  void PrintCommaIfNeeded();

  // Append |buffer| to the stream.
  void AppendSerializedObject(const uint8_t* buffer, intptr_t buffer_length);

  // Append |serialized_object| to the stream with |property_name|.
  void AppendSerializedObject(const char* property_name,
                              const char* serialized_object);

 private:
  void Clear();
  void PostNullReply(Dart_Port port);

  void OpenObject(const char* property_name = NULL);
  void CloseObject();
  void UncloseObject();

  void OpenArray(const char* property_name = NULL);
  void CloseArray();

  void PrintValueNull();
  void PrintValueBool(bool b);
  void PrintValue(intptr_t i);
  void PrintValue64(int64_t i);
  void PrintValueTimeMillis(int64_t millis);
  void PrintValueTimeMicros(int64_t micros);
  void PrintValue(double d);
  void PrintValueBase64(const uint8_t* bytes, intptr_t length);
  void PrintValue(const char* s);
  void PrintValue(const char* s, intptr_t len);
  void PrintValueNoEscape(const char* s);
  void PrintfValue(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void PrintValue(const Object& o, bool ref = true);
  void PrintValue(Breakpoint* bpt);
  void PrintValue(TokenPosition tp);
  void PrintValue(const ServiceEvent* event);
  void PrintValue(Metric* metric);
  void PrintValue(MessageQueue* queue);
  void PrintValue(Isolate* isolate, bool ref = true);
  void PrintValue(ThreadRegistry* reg);
  void PrintValue(Thread* thread);
  bool PrintValueStr(const String& s, intptr_t offset, intptr_t count);
  void PrintValue(const TimelineEvent* timeline_event);
  void PrintValue(const TimelineEventBlock* timeline_event_block);
  void PrintValueVM(bool ref = true);

  void PrintServiceId(const Object& o);
  void PrintPropertyBool(const char* name, bool b);
  void PrintProperty(const char* name, intptr_t i);
  void PrintProperty64(const char* name, int64_t i);
  void PrintPropertyTimeMillis(const char* name, int64_t millis);
  void PrintPropertyTimeMicros(const char* name, int64_t micros);
  void PrintProperty(const char* name, double d);
  void PrintPropertyBase64(const char* name,
                           const uint8_t* bytes,
                           intptr_t length);
  void PrintProperty(const char* name, const char* s);
  bool PrintPropertyStr(const char* name,
                        const String& s,
                        intptr_t offset,
                        intptr_t count);
  void PrintPropertyNoEscape(const char* name, const char* s);
  void PrintfProperty(const char* name, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void PrintProperty(const char* name, const Object& o, bool ref = true);

  void PrintProperty(const char* name, const ServiceEvent* event);
  void PrintProperty(const char* name, Breakpoint* bpt);
  void PrintProperty(const char* name, TokenPosition tp);
  void PrintProperty(const char* name, Metric* metric);
  void PrintProperty(const char* name, MessageQueue* queue);
  void PrintProperty(const char* name, Isolate* isolate);
  void PrintProperty(const char* name, ThreadRegistry* reg);
  void PrintProperty(const char* name, Thread* thread);
  void PrintProperty(const char* name, Zone* zone);
  void PrintProperty(const char* name, const TimelineEvent* timeline_event);
  void PrintProperty(const char* name,
                     const TimelineEventBlock* timeline_event_block);
  void PrintPropertyVM(const char* name, bool ref = true);
  void PrintPropertyName(const char* name);
  bool NeedComma();

  bool AddDartString(const String& s, intptr_t offset, intptr_t count);
  void AddEscapedUTF8String(const char* s);
  void AddEscapedUTF8String(const char* s, intptr_t len);

  intptr_t nesting_level() const { return open_objects_; }

  // Debug only fatal assertion.
  static void EnsureIntegerIsRepresentableInJavaScript(int64_t i);

  intptr_t open_objects_;
  TextBuffer buffer_;
  // Default service id zone.
  RingServiceIdZone default_id_zone_;
  ServiceIdZone* id_zone_;
  Dart_Port reply_port_;
  Instance* seq_;
  Array* parameter_keys_;
  Array* parameter_values_;
  const char* method_;
  const char** param_keys_;
  const char** param_values_;
  intptr_t num_params_;
  intptr_t offset_;
  intptr_t count_;
  int64_t setup_time_micros_;

  friend class JSONObject;
  friend class JSONArray;
  friend class TimelineEvent;
};

class JSONObject : public ValueObject {
 public:
  explicit JSONObject(JSONStream* stream) : stream_(stream) {
    stream_->OpenObject();
  }
  JSONObject(const JSONObject* obj, const char* name) : stream_(obj->stream_) {
    stream_->OpenObject(name);
  }
  explicit JSONObject(const JSONArray* arr);

  ~JSONObject() { stream_->CloseObject(); }

  void AddServiceId(const Object& o) const { stream_->PrintServiceId(o); }

  void AddFixedServiceId(const char* format, ...) const PRINTF_ATTRIBUTE(2, 3);

  void AddLocation(
      const Script& script,
      TokenPosition token_pos,
      TokenPosition end_token_pos = TokenPosition::kNoSource) const;

  void AddLocation(const BreakpointLocation* bpt_loc) const;

  void AddUnresolvedLocation(const BreakpointLocation* bpt_loc) const;

  void AddProperty(const char* name, bool b) const {
    stream_->PrintPropertyBool(name, b);
  }
  void AddProperty(const char* name, intptr_t i) const {
    stream_->PrintProperty(name, i);
  }
  void AddProperty64(const char* name, int64_t i) const {
    stream_->PrintProperty64(name, i);
  }
  void AddPropertyTimeMillis(const char* name, int64_t millis) const {
    stream_->PrintPropertyTimeMillis(name, millis);
  }
  void AddPropertyTimeMicros(const char* name, int64_t micros) const {
    stream_->PrintPropertyTimeMicros(name, micros);
  }
  void AddProperty(const char* name, double d) const {
    stream_->PrintProperty(name, d);
  }
  void AddPropertyBase64(const char* name,
                         const uint8_t* bytes,
                         intptr_t length) const {
    stream_->PrintPropertyBase64(name, bytes, length);
  }
  void AddProperty(const char* name, const char* s) const {
    stream_->PrintProperty(name, s);
  }
  bool AddPropertyStr(const char* name,
                      const String& s,
                      intptr_t offset = 0,
                      intptr_t count = -1) const {
    return stream_->PrintPropertyStr(name, s, offset, count);
  }
  void AddPropertyNoEscape(const char* name, const char* s) const {
    stream_->PrintPropertyNoEscape(name, s);
  }
  void AddProperty(const char* name, const Object& obj, bool ref = true) const {
    stream_->PrintProperty(name, obj, ref);
  }
  void AddProperty(const char* name, const ServiceEvent* event) const {
    stream_->PrintProperty(name, event);
  }
  void AddProperty(const char* name, Breakpoint* bpt) const {
    stream_->PrintProperty(name, bpt);
  }
  void AddProperty(const char* name, TokenPosition tp) const {
    stream_->PrintProperty(name, tp);
  }
  void AddProperty(const char* name, Metric* metric) const {
    stream_->PrintProperty(name, metric);
  }
  void AddProperty(const char* name, MessageQueue* queue) const {
    stream_->PrintProperty(name, queue);
  }
  void AddProperty(const char* name, Isolate* isolate) const {
    stream_->PrintProperty(name, isolate);
  }
  void AddProperty(const char* name, ThreadRegistry* reg) const {
    stream_->PrintProperty(name, reg);
  }
  void AddProperty(const char* name, Thread* thread) const {
    stream_->PrintProperty(name, thread);
  }
  void AddProperty(const char* name, Zone* zone) const {
    stream_->PrintProperty(name, zone);
  }
  void AddProperty(const char* name,
                   const TimelineEvent* timeline_event) const {
    stream_->PrintProperty(name, timeline_event);
  }
  void AddProperty(const char* name,
                   const TimelineEventBlock* timeline_event_block) const {
    stream_->PrintProperty(name, timeline_event_block);
  }
  void AddPropertyVM(const char* name, bool ref = true) const {
    stream_->PrintPropertyVM(name, ref);
  }
  void AddPropertyF(const char* name, const char* format, ...) const
      PRINTF_ATTRIBUTE(3, 4);

 private:
  JSONStream* stream_;

  friend class JSONArray;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(JSONObject);
};

class JSONArray : public ValueObject {
 public:
  explicit JSONArray(JSONStream* stream) : stream_(stream) {
    stream_->OpenArray();
  }
  JSONArray(const JSONObject* obj, const char* name) : stream_(obj->stream_) {
    stream_->OpenArray(name);
  }
  explicit JSONArray(const JSONArray* arr) : stream_(arr->stream_) {
    stream_->OpenArray();
  }
  ~JSONArray() { stream_->CloseArray(); }

  void AddValueNull() const { stream_->PrintValueNull(); }
  void AddValue(bool b) const { stream_->PrintValueBool(b); }
  void AddValue(intptr_t i) const { stream_->PrintValue(i); }
  void AddValue64(int64_t i) const { stream_->PrintValue64(i); }
  void AddValueTimeMillis(int64_t millis) const {
    stream_->PrintValueTimeMillis(millis);
  }
  void AddValueTimeMicros(int64_t micros) const {
    stream_->PrintValueTimeMicros(micros);
  }
  void AddValue(double d) const { stream_->PrintValue(d); }
  void AddValue(const char* s) const { stream_->PrintValue(s); }
  void AddValue(const Object& obj, bool ref = true) const {
    stream_->PrintValue(obj, ref);
  }
  void AddValue(Isolate* isolate, bool ref = true) const {
    stream_->PrintValue(isolate, ref);
  }
  void AddValue(ThreadRegistry* reg) const { stream_->PrintValue(reg); }
  void AddValue(Thread* thread) const { stream_->PrintValue(thread); }
  void AddValue(Breakpoint* bpt) const { stream_->PrintValue(bpt); }
  void AddValue(TokenPosition tp) const { stream_->PrintValue(tp); }
  void AddValue(const ServiceEvent* event) const { stream_->PrintValue(event); }
  void AddValue(Metric* metric) const { stream_->PrintValue(metric); }
  void AddValue(MessageQueue* queue) const { stream_->PrintValue(queue); }
  void AddValue(const TimelineEvent* timeline_event) const {
    stream_->PrintValue(timeline_event);
  }
  void AddValue(const TimelineEventBlock* timeline_event_block) const {
    stream_->PrintValue(timeline_event_block);
  }
  void AddValueVM(bool ref = true) const { stream_->PrintValueVM(ref); }
  void AddValueF(const char* format, ...) const PRINTF_ATTRIBUTE(2, 3);

 private:
  JSONStream* stream_;

  friend class JSONObject;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(JSONArray);
};

}  // namespace dart

#endif  // RUNTIME_VM_JSON_STREAM_H_
