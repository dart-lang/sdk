// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_JSON_STREAM_H_
#define RUNTIME_VM_JSON_STREAM_H_

#include "include/dart_api.h"  // for Dart_Port
#include "platform/allocation.h"
#include "platform/text_buffer.h"
#include "vm/json_writer.h"
#include "vm/os.h"
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
//  - pkg/dds/lib/src/rpc_error_codes.dart
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
  kServiceAlreadyRegistered = 111,
  kServiceDisappeared = 112,
  kExpressionCompilationError = 113,
  kInvalidTimelineRequest = 114,
  kCannotGetQueuedMicrotasks = 115,

  // Experimental (used in private rpcs).
  kFileSystemAlreadyExists = 1001,
  kFileSystemDoesNotExist = 1002,
  kFileDoesNotExist = 1003,
};

// Builds on JSONWriter to provide support for serializing various objects
// used in the VM service protocol.
class JSONStream : ValueObject {
 public:
  explicit JSONStream(intptr_t buf_size = 256);

  // Populates the fields of this |JSONStream| that are required to call
  // certain helper methods related to posting replies to RPCs.
  //
  // WARNING: It is not safe to call the following methods on a |JSONStream|
  // until |Setup| has been called on that |JSONStream|: |PostReply|,
  // |reply_port|, |method|, |NumObjectParameters|, |LookupObjectParam|,
  // |num_params|, |param_keys|, |param_values|, |GetParamKey|, |GetParamValue|,
  // |LookupParam|, |HasParam|, |ParamIs|.
  void Setup(Zone* zone,
             Dart_Port reply_port,
             const Instance& seq,
             const String& method,
             const Array& param_keys,
             const Array& param_values,
             bool parameters_are_dart_objects = false);
  void SetupError();

  void PrintError(intptr_t code, const char* details_format, ...)
      PRINTF_ATTRIBUTE(3, 4);

  void PostReply();

  // WARNING: It is not safe to call |id_zone| or |PrintServiceId| on a
  // |JSONStream| until |set_id_zone| has been called on that |JSONStream|.
  void set_id_zone(RingServiceIdZone& id_zone) { id_zone_ = &id_zone; }
  RingServiceIdZone& id_zone() { return *id_zone_; }

  TextBuffer* buffer() { return writer_.buffer(); }
  const char* ToCString() { return writer_.ToCString(); }

  void Steal(char** buffer, intptr_t* buffer_length) {
    writer_.Steal(buffer, buffer_length);
  }

  void set_reply_port(Dart_Port port);
  Dart_Port reply_port() const { return reply_port_; }

  bool include_private_members() const { return include_private_members_; }
  void set_include_private_members(bool include_private_members) {
    include_private_members_ = include_private_members;
  }

  bool IsAllowableKey(const char* key) {
    if (include_private_members_) {
      return true;
    }
    return *key != '_';
  }

  void SetParams(const char** param_keys,
                 const char** param_values,
                 intptr_t num_params);

  intptr_t NumObjectParameters() const;
  ObjectPtr LookupObjectParam(const char* key) const;

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
    ASSERT(value >= 0);
    offset_ = value;
  }

  void set_count(intptr_t value) {
    ASSERT(value >= 0);
    count_ = value;
  }

  void ComputeOffsetAndCount(intptr_t length,
                             intptr_t* offset,
                             intptr_t* count);

  // Append |buffer| to the stream.
  void AppendBytes(const uint8_t* buffer, intptr_t buffer_length) {
    writer_.AppendBytes(buffer, buffer_length);
  }

  // Append |serialized_object| to the stream.
  void AppendSerializedObject(const char* serialized_object) {
    writer_.AppendSerializedObject(serialized_object);
  }

  // Append |serialized_object| to the stream with |property_name|.
  void AppendSerializedObject(const char* property_name,
                              const char* serialized_object) {
    writer_.AppendSerializedObject(property_name, serialized_object);
  }

  void PrintCommaIfNeeded() { writer_.PrintCommaIfNeeded(); }
  JSONWriter* writer() { return &writer_; }

 private:
  void Clear() { writer_.Clear(); }

  ObjectPtr GetObjectParameterKey(intptr_t i) const;
  ObjectPtr GetObjectParameterValue(intptr_t i) const;

  void PostNullReply(Dart_Port port);

  void OpenObject(const char* property_name = nullptr) {
    if (ignore_object_depth_ > 0 ||
        (property_name != nullptr && !IsAllowableKey(property_name))) {
      ignore_object_depth_++;
      return;
    }
    writer_.OpenObject(property_name);
  }
  void CloseObject() {
    if (ignore_object_depth_ > 0) {
      ignore_object_depth_--;
      return;
    }
    writer_.CloseObject();
  }
  void UncloseObject() {
    // This should be updated to handle unclosing a private object if we need
    // to handle that case, which we don't currently.
    writer_.UncloseObject();
  }

  void OpenArray(const char* property_name = nullptr) {
    if (ignore_object_depth_ > 0 ||
        (property_name != nullptr && !IsAllowableKey(property_name))) {
      ignore_object_depth_++;
      return;
    }
    writer_.OpenArray(property_name);
  }
  void CloseArray() {
    if (ignore_object_depth_ > 0) {
      ignore_object_depth_--;
      return;
    }
    writer_.CloseArray();
  }

  // Append the Base64 encoding of |bytes| to the stream.
  //
  // Beware that padding characters are added when |length| is not a multiple of
  // three. Padding is only valid at the end of Base64 strings, so you must be
  // careful when trying to populate a single Base64 string with multiple calls
  // to this method. |JSONBase64String| should be used for that use-case,
  // because it handles padding management.
  void AppendBytesInBase64(const uint8_t* bytes, intptr_t length) {
    writer_.AppendBytesInBase64(bytes, length);
  }
  void PrintValueNull() { writer_.PrintValueNull(); }
  void PrintValueBool(bool b) { writer_.PrintValueBool(b); }
  void PrintValue(intptr_t i) { writer_.PrintValue(i); }
  void PrintValue64(int64_t i) { writer_.PrintValue64(i); }
  void PrintValueTimeMillis(int64_t millis) { writer_.PrintValue64(millis); }
  void PrintValueTimeMicros(int64_t micros) { writer_.PrintValue64(micros); }
  void PrintValue(double d) { writer_.PrintValue(d); }
  void PrintValueBase64(const uint8_t* bytes, intptr_t length) {
    writer_.PrintValueBase64(bytes, length);
  }
  void PrintValue(const char* s) { writer_.PrintValue(s); }
  void PrintValueNoEscape(const char* s) { writer_.PrintValueNoEscape(s); }
  bool PrintValueStr(const String& s, intptr_t offset, intptr_t count) {
    return writer_.PrintValueStr(s, offset, count);
  }
  void PrintfValue(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void VPrintfValue(const char* format, va_list args) {
    writer_.VPrintfValue(format, args);
  }

  void PrintValue(const Object& o, bool ref = true);
  void PrintValue(Breakpoint* bpt);
  void PrintValue(TokenPosition tp);
  void PrintValue(const ServiceEvent* event);
  void PrintValue(Metric* metric);
  void PrintValue(MessageQueue* queue);
  void PrintValue(Isolate* isolate, bool ref = true);
  void PrintValue(IsolateGroup* isolate, bool ref = true);
  void PrintValue(const TimelineEvent* timeline_event);
  void PrintValue(const TimelineEventBlock* timeline_event_block);
  void PrintValueVM(bool ref = true);

  void PrintServiceId(const Object& o);

#define PRIVATE_NAME_CHECK()                                                   \
  if (!IsAllowableKey(name) || ignore_object_depth_ > 0) {                     \
    return;                                                                    \
  }

  void PrintPropertyBool(const char* name, bool b) {
    PRIVATE_NAME_CHECK();
    writer_.PrintPropertyBool(name, b);
  }
  void PrintProperty(const char* name, intptr_t i) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty(name, i);
  }
  void PrintProperty64(const char* name, int64_t i) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty64(name, i);
  }
  void PrintPropertyTimeMillis(const char* name, int64_t millis) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty64(name, millis);
  }
  void PrintPropertyTimeMicros(const char* name, int64_t micros) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty64(name, micros);
  }
  void PrintProperty(const char* name, double d) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty(name, d);
  }
  void PrintPropertyBase64(const char* name,
                           const uint8_t* bytes,
                           intptr_t length) {
    PRIVATE_NAME_CHECK();
    writer_.PrintPropertyBase64(name, bytes, length);
  }
  void PrintProperty(const char* name, const char* s) {
    PRIVATE_NAME_CHECK();
    writer_.PrintProperty(name, s);
  }
  bool PrintPropertyStr(const char* name,
                        const String& s,
                        intptr_t offset,
                        intptr_t count) {
    if (!IsAllowableKey(name)) {
      return false;
    }
    return writer_.PrintPropertyStr(name, s, offset, count);
  }
  void PrintPropertyNoEscape(const char* name, const char* s) {
    PRIVATE_NAME_CHECK();
    writer_.PrintPropertyNoEscape(name, s);
  }
  void PrintfProperty(const char* name, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void VPrintfProperty(const char* name, const char* format, va_list args) {
    PRIVATE_NAME_CHECK();
    writer_.VPrintfProperty(name, format, args);
  }

#undef PRIVATE_NAME_CHECK

  void PrintProperty(const char* name, const Object& o, bool ref = true);

  void PrintProperty(const char* name, const ServiceEvent* event);
  void PrintProperty(const char* name, Breakpoint* bpt);
  void PrintProperty(const char* name, TokenPosition tp);
  void PrintProperty(const char* name, Metric* metric);
  void PrintProperty(const char* name, MessageQueue* queue);
  void PrintProperty(const char* name, Isolate* isolate);
  void PrintProperty(const char* name, IsolateGroup* isolate_group);
  void PrintProperty(const char* name, Zone* zone);
  void PrintProperty(const char* name, const TimelineEvent* timeline_event);
  void PrintProperty(const char* name,
                     const TimelineEventBlock* timeline_event_block);
  void PrintPropertyVM(const char* name, bool ref = true);
  void PrintPropertyName(const char* name) { writer_.PrintPropertyName(name); }

  void AddEscapedUTF8String(const char* s, intptr_t len) {
    writer_.AddEscapedUTF8String(s, len);
  }

  JSONWriter writer_;
  // The Service ID zone where temporary IDs may be allocated by the RPC
  // associated with this |JSONStream|.
  RingServiceIdZone* id_zone_;
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
  bool include_private_members_;
  intptr_t ignore_object_depth_;
  friend class JSONObject;
  friend class JSONArray;
  friend class JSONBase64String;
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
  void AddServiceId(const char* format, ...) const PRINTF_ATTRIBUTE(2, 3);

  void AddLocation(
      const Script& script,
      TokenPosition token_pos,
      TokenPosition end_token_pos = TokenPosition::kNoSource) const;

  void AddLocation(const BreakpointLocation* bpt_loc) const;
  void AddLocationLine(const Script& script, intptr_t line) const;

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
  void AddProperty(const char* name, IsolateGroup* isolate_group) const {
    stream_->PrintProperty(name, isolate_group);
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
  void AddValue(IsolateGroup* isolate_group, bool ref = true) const {
    stream_->PrintValue(isolate_group, ref);
  }
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

class JSONBase64String : public ValueObject {
 public:
  explicit JSONBase64String(JSONStream* stream)
      : stream_(stream), queued_bytes_(), num_queued_bytes_(0) {
    stream_->AppendBytes(reinterpret_cast<const uint8_t*>("\""), 1);
  }
  ~JSONBase64String() {
    stream_->AppendBytesInBase64(queued_bytes_, num_queued_bytes_);
    stream_->AppendBytes(reinterpret_cast<const uint8_t*>("\""), 1);
  }

  void AppendBytes(const uint8_t* bytes, intptr_t length);

 private:
  JSONStream* stream_;
  uint8_t queued_bytes_[3];
  intptr_t num_queued_bytes_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(JSONBase64String);
};

}  // namespace dart

#endif  // RUNTIME_VM_JSON_STREAM_H_
