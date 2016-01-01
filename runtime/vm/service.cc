// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service.h"

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/globals.h"

#include "vm/compiler.h"
#include "vm/coverage.h"
#include "vm/cpu.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/profiler_service.h"
#include "vm/reusable_handles.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/unicode.h"
#include "vm/version.h"

namespace dart {

#define Z (T->zone())


DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_pause_events);
DEFINE_FLAG(charp, vm_name, "vm",
            "The default name of this vm as reported by the VM service "
            "protocol");

// The name of this of this vm as reported by the VM service protocol.
static char* vm_name = NULL;


static const char* GetVMName() {
  if (vm_name == NULL) {
    return FLAG_vm_name;
  }
  return vm_name;
}


ServiceIdZone::ServiceIdZone() {
}


ServiceIdZone::~ServiceIdZone() {
}


RingServiceIdZone::RingServiceIdZone()
    : ring_(NULL),
      policy_(ObjectIdRing::kAllocateId) {
}


RingServiceIdZone::~RingServiceIdZone() {
}


void RingServiceIdZone::Init(
    ObjectIdRing* ring, ObjectIdRing::IdPolicy policy) {
  ring_ = ring;
  policy_ = policy;
}


char* RingServiceIdZone::GetServiceId(const Object& obj) {
  ASSERT(ring_ != NULL);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(zone != NULL);
  const intptr_t id = ring_->GetIdForObject(obj.raw(), policy_);
  return zone->PrintToString("objects/%" Pd "", id);
}


// TODO(johnmccutchan): Unify embedder service handler lists and their APIs.
EmbedderServiceHandler* Service::isolate_service_handler_head_ = NULL;
EmbedderServiceHandler* Service::root_service_handler_head_ = NULL;
struct ServiceMethodDescriptor;
const ServiceMethodDescriptor* FindMethod(const char* method_name);


// Support for streams defined in embedders.
Dart_ServiceStreamListenCallback Service::stream_listen_callback_ = NULL;
Dart_ServiceStreamCancelCallback Service::stream_cancel_callback_ = NULL;
Dart_GetVMServiceAssetsArchive Service::get_service_assets_callback_ = NULL;

// These are the set of streams known to the core VM.
StreamInfo Service::vm_stream("VM");
StreamInfo Service::isolate_stream("Isolate");
StreamInfo Service::debug_stream("Debug");
StreamInfo Service::gc_stream("GC");
StreamInfo Service::echo_stream("_Echo");
StreamInfo Service::graph_stream("_Graph");
StreamInfo Service::logging_stream("_Logging");
StreamInfo Service::extension_stream("Extension");

static StreamInfo* streams_[] = {
  &Service::vm_stream,
  &Service::isolate_stream,
  &Service::debug_stream,
  &Service::gc_stream,
  &Service::echo_stream,
  &Service::graph_stream,
  &Service::logging_stream,
  &Service::extension_stream,
};


bool Service::ListenStream(const char* stream_id) {
  if (FLAG_trace_service) {
    OS::Print("vm-service: starting stream '%s'\n",
              stream_id);
  }
  intptr_t num_streams = sizeof(streams_) /
                         sizeof(streams_[0]);
  for (intptr_t i = 0; i < num_streams; i++) {
    if (strcmp(stream_id, streams_[i]->id()) == 0) {
      streams_[i]->set_enabled(true);
      return true;
    }
  }
  if (stream_listen_callback_) {
    return (*stream_listen_callback_)(stream_id);
  }
  return false;
}


void Service::CancelStream(const char* stream_id) {
  if (FLAG_trace_service) {
    OS::Print("vm-service: stopping stream '%s'\n",
              stream_id);
  }
  intptr_t num_streams = sizeof(streams_) /
                         sizeof(streams_[0]);
  for (intptr_t i = 0; i < num_streams; i++) {
    if (strcmp(stream_id, streams_[i]->id()) == 0) {
      streams_[i]->set_enabled(false);
      return;
    }
  }
  if (stream_cancel_callback_) {
    return (*stream_cancel_callback_)(stream_id);
  }
}

RawObject* Service::RequestAssets() {
  Thread* T = Thread::Current();
  Api::Scope api_scope(T);
  if (get_service_assets_callback_ == NULL) {
    return Object::null();
  }
  Dart_Handle handle = get_service_assets_callback_();
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
  }
  const Object& object = Object::Handle(Api::UnwrapHandle(handle));
  if (object.IsNull()) {
    return Object::null();
  }
  if (!object.IsTypedData()) {
    const String& error_message =
        String::Handle(
            String::New("An implementation of Dart_GetVMServiceAssetsArchive "
                        "should return a Uint8Array or null."));
    const Error& error = Error::Handle(ApiError::New(error_message));
    Exceptions::PropagateError(error);
    return Object::null();
  }
  const TypedData& typed_data = TypedData::Cast(object);
  if (typed_data.ElementSizeInBytes() != 1) {
    const String& error_message =
        String::Handle(
            String::New("An implementation of Dart_GetVMServiceAssetsArchive "
                        "should return a Uint8Array or null."));
    const Error& error = Error::Handle(ApiError::New(error_message));
    Exceptions::PropagateError(error);
    return Object::null();
  }
  return Api::UnwrapHandle(handle);
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void PrintMissingParamError(JSONStream* js,
                                   const char* param) {
  js->PrintError(kInvalidParams,
                 "%s expects the '%s' parameter", js->method(), param);
}


static void PrintInvalidParamError(JSONStream* js,
                                   const char* param) {
  js->PrintError(kInvalidParams,
                 "%s: invalid '%s' parameter: %s",
                 js->method(), param, js->LookupParam(param));
}


static void PrintUnrecognizedMethodError(JSONStream* js) {
  js->PrintError(kMethodNotFound, NULL);
}


static void PrintSuccess(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}

static bool GetIntegerId(const char* s, intptr_t* id, int base = 10) {
  if ((s == NULL) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == NULL) {
    // No id pointer.
    return false;
  }
  intptr_t r = 0;
  char* end_ptr = NULL;
  r = strtol(s, &end_ptr, base);
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}


static bool GetUnsignedIntegerId(const char* s, uintptr_t* id, int base = 10) {
  if ((s == NULL) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == NULL) {
    // No id pointer.
    return false;
  }
  uintptr_t r = 0;
  char* end_ptr = NULL;
  r = strtoul(s, &end_ptr, base);
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}


static bool GetInteger64Id(const char* s, int64_t* id, int base = 10) {
  if ((s == NULL) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == NULL) {
    // No id pointer.
    return false;
  }
  int64_t r = 0;
  char* end_ptr = NULL;
  r = strtoll(s, &end_ptr, base);
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}


// Scans the string until the '-' character. Returns pointer to string
// at '-' character. Returns NULL if not found.
static const char* ScanUntilDash(const char* s) {
  if ((s == NULL) || (*s == '\0')) {
    // Empty string.
    return NULL;
  }
  while (*s != '\0') {
    if (*s == '-') {
      return s;
    }
    s++;
  }
  return NULL;
}


static bool GetCodeId(const char* s, int64_t* timestamp, uword* address) {
  if ((s == NULL) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if ((timestamp == NULL) || (address == NULL)) {
    // Bad arguments.
    return false;
  }
  // Extract the timestamp.
  if (!GetInteger64Id(s, timestamp, 16) || (*timestamp < 0)) {
    return false;
  }
  s = ScanUntilDash(s);
  if (s == NULL) {
    return false;
  }
  // Skip the dash.
  s++;
  // Extract the PC.
  if (!GetUnsignedIntegerId(s, address, 16)) {
    return false;
  }
  return true;
}


// Verifies that |s| begins with |prefix| and then calls |GetIntegerId| on
// the remainder of |s|.
static bool GetPrefixedIntegerId(const char* s,
                                 const char* prefix,
                                 intptr_t* service_id) {
  if (s == NULL) {
    return false;
  }
  ASSERT(prefix != NULL);
  const intptr_t kInputLen = strlen(s);
  const intptr_t kPrefixLen = strlen(prefix);
  ASSERT(kPrefixLen > 0);
  if (kInputLen <= kPrefixLen) {
    return false;
  }
  if (strncmp(s, prefix, kPrefixLen) != 0) {
    return false;
  }
  // Prefix satisfied. Move forward.
  s += kPrefixLen;
  // Attempt to read integer id.
  return GetIntegerId(s, service_id);
}


static bool IsValidClassId(Isolate* isolate, intptr_t cid) {
  ASSERT(isolate != NULL);
  ClassTable* class_table = isolate->class_table();
  ASSERT(class_table != NULL);
  return class_table->IsValidIndex(cid) && class_table->HasValidClassAt(cid);
}


static RawClass* GetClassForId(Isolate* isolate, intptr_t cid) {
  ASSERT(isolate == Isolate::Current());
  ASSERT(isolate != NULL);
  ClassTable* class_table = isolate->class_table();
  ASSERT(class_table != NULL);
  return class_table->At(cid);
}


// TODO(johnmccutchan): Split into separate file and write unit tests.
class MethodParameter {
 public:
  MethodParameter(const char* name, bool required)
      : name_(name), required_(required) {
  }

  virtual ~MethodParameter() { }

  virtual bool Validate(const char* value) const {
    return true;
  }

  const char* name() const {
    return name_;
  }

  bool required() const {
    return required_;
  }

 private:
  const char* name_;
  bool required_;
};


class NoSuchParameter : public MethodParameter {
 public:
  explicit NoSuchParameter(const char* name)
    : MethodParameter(name, false) {
  }

  virtual bool Validate(const char* value) const {
    return (value == NULL);
  }
};


#define NO_ISOLATE_PARAMETER new NoSuchParameter("isolateId")


class BoolParameter : public MethodParameter {
 public:
  BoolParameter(const char* name, bool required)
      : MethodParameter(name, required) {
  }

  virtual bool Validate(const char* value) const {
    if (value == NULL) {
      return false;
    }
    return (strcmp("true", value) == 0) || (strcmp("false", value) == 0);
  }

  static bool Parse(const char* value, bool default_value = false) {
    if (value == NULL) {
      return default_value;
    }
    return strcmp("true", value) == 0;
  }
};


class UIntParameter : public MethodParameter {
 public:
  UIntParameter(const char* name, bool required)
      : MethodParameter(name, required) {
  }

  virtual bool Validate(const char* value) const {
    if (value == NULL) {
      return false;
    }
    for (const char* cp = value; *cp != '\0'; cp++) {
      if (*cp < '0' || *cp > '9') {
        return false;
      }
    }
    return true;
  }

  static intptr_t Parse(const char* value) {
    if (value == NULL) {
      return -1;
    }
    char* end_ptr = NULL;
    uintptr_t result = strtoul(value, &end_ptr, 10);
    ASSERT(*end_ptr == '\0');  // Parsed full string
    return result;
  }
};


class Int64Parameter : public MethodParameter {
 public:
  Int64Parameter(const char* name, bool required)
      : MethodParameter(name, required) {
  }

  virtual bool Validate(const char* value) const {
    if (value == NULL) {
      return false;
    }
    for (const char* cp = value; *cp != '\0'; cp++) {
      if ((*cp < '0' || *cp > '9') && (*cp != '-')) {
        return false;
      }
    }
    return true;
  }

  static int64_t Parse(const char* value, int64_t default_value = -1) {
    if ((value == NULL) || (*value == '\0')) {
      return default_value;
    }
    char* end_ptr = NULL;
    int64_t result = strtoll(value, &end_ptr, 10);
    ASSERT(*end_ptr == '\0');  // Parsed full string
    return result;
  }
};


class IdParameter : public MethodParameter {
 public:
  IdParameter(const char* name, bool required)
      : MethodParameter(name, required) {
  }

  virtual bool Validate(const char* value) const {
    return (value != NULL);
  }
};


#define ISOLATE_PARAMETER new IdParameter("isolateId", true)


class EnumParameter : public MethodParameter {
 public:
  EnumParameter(const char* name, bool required, const char* const* enums)
      : MethodParameter(name, required),
        enums_(enums) {
  }

  virtual bool Validate(const char* value) const {
    if (value == NULL) {
      return true;
    }
    for (intptr_t i = 0; enums_[i] != NULL; i++) {
      if (strcmp(value, enums_[i]) == 0) {
        return true;
      }
    }
    return false;
  }

 private:
  const char* const* enums_;
};


// If the key is not found, this function returns the last element in the
// values array. This can be used to encode the default value.
template<typename T>
T EnumMapper(const char* value, const char* const* enums, T* values) {
  ASSERT(value != NULL);
  intptr_t i = 0;
  for (i = 0; enums[i] != NULL; i++) {
    if (strcmp(value, enums[i]) == 0) {
      return values[i];
    }
  }
  // Default value.
  return values[i];
}


typedef bool (*ServiceMethodEntry)(Thread* thread, JSONStream* js);


struct ServiceMethodDescriptor {
  const char* name;
  const ServiceMethodEntry entry;
  const MethodParameter* const * parameters;
};


// TODO(johnmccutchan): Do we reject unexpected parameters?
static bool ValidateParameters(const MethodParameter* const* parameters,
                              JSONStream* js) {
  if (parameters == NULL) {
    return true;
  }
  for (intptr_t i = 0; parameters[i] != NULL; i++) {
    const MethodParameter* parameter = parameters[i];
    const char* name = parameter->name();
    const bool required = parameter->required();
    const char* value = js->LookupParam(name);
    const bool has_parameter = (value != NULL);
    if (required && !has_parameter) {
      PrintMissingParamError(js, name);
      return false;
    }
    if (has_parameter && !parameter->Validate(value)) {
      PrintInvalidParamError(js, name);
      return false;
    }
  }
  return true;
}


void Service::PostError(const String& method_name,
                        const Array& parameter_keys,
                        const Array& parameter_values,
                        const Instance& reply_port,
                        const Instance& id,
                        const Error& error) {
  Thread* T = Thread::Current();
  StackZone zone(T);
  HANDLESCOPE(T);
  JSONStream js;
  js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(),
           id, method_name, parameter_keys, parameter_values);
  js.PrintError(kExtensionError,
                "Error in extension `%s`: %s",
                js.method(), error.ToErrorCString());
  js.PostReply();
}


void Service::InvokeMethod(Isolate* I, const Array& msg) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != NULL);
  ASSERT(!msg.IsNull());
  ASSERT(msg.Length() == 6);

  {
    StackZone zone(T);
    HANDLESCOPE(T);

    Instance& reply_port = Instance::Handle(Z);
    Instance& seq = String::Handle(Z);
    String& method_name = String::Handle(Z);
    Array& param_keys = Array::Handle(Z);
    Array& param_values = Array::Handle(Z);
    reply_port ^= msg.At(1);
    seq ^= msg.At(2);
    method_name ^= msg.At(3);
    param_keys ^= msg.At(4);
    param_values ^= msg.At(5);

    ASSERT(!method_name.IsNull());
    ASSERT(seq.IsNull() || seq.IsString() || seq.IsNumber());
    ASSERT(!param_keys.IsNull());
    ASSERT(!param_values.IsNull());
    ASSERT(param_keys.Length() == param_values.Length());

    if (!reply_port.IsSendPort()) {
      FATAL("SendPort expected.");
    }

    JSONStream js;
    js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(),
             seq, method_name, param_keys, param_values);

    // RPC came in with a custom service id zone.
    const char* id_zone_param = js.LookupParam("_idZone");

    if (id_zone_param != NULL) {
      // Override id zone.
      if (strcmp("default", id_zone_param) == 0) {
        // Ring with eager id allocation. This is the default ring and default
        // policy.
        // Nothing to do.
      } else if (strcmp("default.reuse", id_zone_param) == 0) {
        // Change the default ring's policy.
        RingServiceIdZone* zone =
            reinterpret_cast<RingServiceIdZone*>(js.id_zone());
        zone->set_policy(ObjectIdRing::kReuseId);
      } else {
        // TODO(johnmccutchan): Support creating, deleting, and selecting
        // custom service id zones.
        // For now, always return an error.
        PrintInvalidParamError(&js, "_idZone");
        js.PostReply();
        return;
      }
    }
    const char* c_method_name = method_name.ToCString();

    const ServiceMethodDescriptor* method = FindMethod(c_method_name);
    if (method != NULL) {
      if (!ValidateParameters(method->parameters, &js)) {
        js.PostReply();
        return;
      }
      if (method->entry(T, &js)) {
        js.PostReply();
      } else {
        // NOTE(turnidge): All message handlers currently return true,
        // so this case shouldn't be reached, at present.
        UNIMPLEMENTED();
      }
      return;
    }

    EmbedderServiceHandler* handler = FindIsolateEmbedderHandler(c_method_name);
    if (handler == NULL) {
      handler = FindRootEmbedderHandler(c_method_name);
    }

    if (handler != NULL) {
      EmbedderHandleMessage(handler, &js);
      js.PostReply();
      return;
    }

    const Instance& extension_handler = Instance::Handle(Z,
        I->LookupServiceExtensionHandler(method_name));
    if (!extension_handler.IsNull()) {
      ScheduleExtensionHandler(extension_handler,
                               method_name,
                               param_keys,
                               param_values,
                               reply_port,
                               seq);
      // Schedule was successful. Extension code will post a reply
      // asynchronously.
      return;
    }

    PrintUnrecognizedMethodError(&js);
    js.PostReply();
    return;
  }
}


void Service::HandleRootMessage(const Array& msg_instance) {
  Isolate* isolate = Isolate::Current();
  InvokeMethod(isolate, msg_instance);
}


void Service::HandleIsolateMessage(Isolate* isolate, const Array& msg) {
  ASSERT(isolate != NULL);
  InvokeMethod(isolate, msg);
}


void Service::SendEvent(const char* stream_id,
                        const char* event_type,
                        const Object& event_message) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  ASSERT(!ServiceIsolate::IsServiceIsolateDescendant(isolate));
  if (!ServiceIsolate::IsRunning()) {
    return;
  }
  HANDLESCOPE(thread);

  const Array& list = Array::Handle(Array::New(2));
  ASSERT(!list.IsNull());
  const String& stream_id_str = String::Handle(String::New(stream_id));
  list.SetAt(0, stream_id_str);
  list.SetAt(1, event_message);

  // Push the event to port_.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("vm-service: Pushing ServiceEvent(isolate='%s', kind='%s',"
              " len=%" Pd ") to stream %s\n",
              isolate->name(), event_type, len, stream_id);
  }
  // TODO(turnidge): For now we ignore failure to send an event.  Revisit?
  PortMap::PostMessage(
      new Message(ServiceIsolate::Port(), data, len, Message::kNormalPriority));
}


// TODO(turnidge): Rewrite this method to use Post_CObject instead.
void Service::SendEventWithData(const char* stream_id,
                                const char* event_type,
                                const String& meta,
                                const uint8_t* data,
                                intptr_t size) {
  // Bitstream: [meta data size (big-endian 64 bit)] [meta data (UTF-8)] [data]
  const intptr_t meta_bytes = Utf8::Length(meta);
  const intptr_t total_bytes = sizeof(uint64_t) + meta_bytes + size;
  const TypedData& message = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, total_bytes));
  intptr_t offset = 0;
  // TODO(koda): Rename these methods SetHostUint64, etc.
  message.SetUint64(0, Utils::HostToBigEndian64(meta_bytes));
  offset += sizeof(uint64_t);
  {
    NoSafepointScope no_safepoint;
    meta.ToUTF8(static_cast<uint8_t*>(message.DataAddr(offset)), meta_bytes);
    offset += meta_bytes;
  }
  // TODO(koda): It would be nice to avoid this copy (requires changes to
  // MessageWriter code).
  {
    NoSafepointScope no_safepoint;
    memmove(message.DataAddr(offset), data, size);
    offset += size;
  }
  ASSERT(offset == total_bytes);
  SendEvent(stream_id, event_type, message);
}


void Service::HandleEvent(ServiceEvent* event) {
  if (event->isolate() != NULL &&
      ServiceIsolate::IsServiceIsolateDescendant(event->isolate())) {
    return;
  }
  if (!ServiceIsolate::IsRunning()) {
    return;
  }
  JSONStream js;
  const char* stream_id = event->stream_id();
  ASSERT(stream_id != NULL);
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("jsonrpc", "2.0");
    jsobj.AddProperty("method", "streamNotify");
    JSONObject params(&jsobj, "params");
    params.AddProperty("streamId", stream_id);
    params.AddProperty("event", event);
  }
  PostEvent(stream_id, event->KindAsCString(), &js);
}


void Service::PostEvent(const char* stream_id,
                        const char* kind,
                        JSONStream* event) {
  ASSERT(stream_id != NULL);
  ASSERT(kind != NULL);
  ASSERT(event != NULL);

  // Message is of the format [<stream id>, <json string>].
  //
  // Build the event message in the C heap to avoid dart heap
  // allocation.  This method can be called while we have acquired a
  // direct pointer to typed data, so we can't allocate here.
  Dart_CObject list_cobj;
  Dart_CObject* list_values[2];
  list_cobj.type = Dart_CObject_kArray;
  list_cobj.value.as_array.length = 2;
  list_cobj.value.as_array.values = list_values;

  Dart_CObject stream_id_cobj;
  stream_id_cobj.type = Dart_CObject_kString;
  stream_id_cobj.value.as_string = const_cast<char*>(stream_id);
  list_values[0] = &stream_id_cobj;

  Dart_CObject json_cobj;
  json_cobj.type = Dart_CObject_kString;
  json_cobj.value.as_string = const_cast<char*>(event->ToCString());
  list_values[1] = &json_cobj;

  if (FLAG_trace_service) {
    Isolate* isolate = Isolate::Current();
    const char* isolate_name = "<no current isolate>";
    if (isolate != NULL) {
      isolate_name = isolate->name();
    }
    OS::Print("vm-service: Pushing ServiceEvent(isolate='%s', kind='%s') "
              "to stream %s\n",
              isolate_name, kind, stream_id);
  }

  Dart_PostCObject(ServiceIsolate::Port(), &list_cobj);
}


class EmbedderServiceHandler {
 public:
  explicit EmbedderServiceHandler(const char* name) : name_(NULL),
                                                      callback_(NULL),
                                                      user_data_(NULL),
                                                      next_(NULL) {
    ASSERT(name != NULL);
    name_ = strdup(name);
  }

  ~EmbedderServiceHandler() {
    free(name_);
  }

  const char* name() const { return name_; }

  Dart_ServiceRequestCallback callback() const { return callback_; }
  void set_callback(Dart_ServiceRequestCallback callback) {
    callback_ = callback;
  }

  void* user_data() const { return user_data_; }
  void set_user_data(void* user_data) {
    user_data_ = user_data;
  }

  EmbedderServiceHandler* next() const { return next_; }
  void set_next(EmbedderServiceHandler* next) {
    next_ = next;
  }

 private:
  char* name_;
  Dart_ServiceRequestCallback callback_;
  void* user_data_;
  EmbedderServiceHandler* next_;
};


void Service::EmbedderHandleMessage(EmbedderServiceHandler* handler,
                                    JSONStream* js) {
  ASSERT(handler != NULL);
  Dart_ServiceRequestCallback callback = handler->callback();
  ASSERT(callback != NULL);
  const char* r = NULL;
  const char* method = js->method();
  const char** keys = js->param_keys();
  const char** values = js->param_values();
  r = callback(method, keys, values, js->num_params(), handler->user_data());
  ASSERT(r != NULL);
  // TODO(johnmccutchan): Allow for NULL returns?
  TextBuffer* buffer = js->buffer();
  buffer->AddString(r);
  free(const_cast<char*>(r));
}


void Service::RegisterIsolateEmbedderCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  if (name == NULL) {
    return;
  }
  EmbedderServiceHandler* handler = FindIsolateEmbedderHandler(name);
  if (handler != NULL) {
    // Update existing handler entry.
    handler->set_callback(callback);
    handler->set_user_data(user_data);
    return;
  }
  // Create a new handler.
  handler = new EmbedderServiceHandler(name);
  handler->set_callback(callback);
  handler->set_user_data(user_data);

  // Insert into isolate_service_handler_head_ list.
  handler->set_next(isolate_service_handler_head_);
  isolate_service_handler_head_ = handler;
}


EmbedderServiceHandler* Service::FindIsolateEmbedderHandler(
    const char* name) {
  EmbedderServiceHandler* current = isolate_service_handler_head_;
  while (current != NULL) {
    if (strcmp(name, current->name()) == 0) {
      return current;
    }
    current = current->next();
  }
  return NULL;
}


void Service::RegisterRootEmbedderCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  if (name == NULL) {
    return;
  }
  EmbedderServiceHandler* handler = FindRootEmbedderHandler(name);
  if (handler != NULL) {
    // Update existing handler entry.
    handler->set_callback(callback);
    handler->set_user_data(user_data);
    return;
  }
  // Create a new handler.
  handler = new EmbedderServiceHandler(name);
  handler->set_callback(callback);
  handler->set_user_data(user_data);

  // Insert into root_service_handler_head_ list.
  handler->set_next(root_service_handler_head_);
  root_service_handler_head_ = handler;
}


void Service::SetEmbedderStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
  stream_listen_callback_ = listen_callback;
  stream_cancel_callback_ = cancel_callback;
}


void Service::SetGetServiceAssetsCallback(
    Dart_GetVMServiceAssetsArchive get_service_assets) {
  get_service_assets_callback_ = get_service_assets;
}


EmbedderServiceHandler* Service::FindRootEmbedderHandler(
    const char* name) {
  EmbedderServiceHandler* current = root_service_handler_head_;
  while (current != NULL) {
    if (strcmp(name, current->name()) == 0) {
      return current;
    }
    current = current->next();
  }
  return NULL;
}


void Service::ScheduleExtensionHandler(const Instance& handler,
                                       const String& method_name,
                                       const Array& parameter_keys,
                                       const Array& parameter_values,
                                       const Instance& reply_port,
                                       const Instance& id) {
  ASSERT(!handler.IsNull());
  ASSERT(!method_name.IsNull());
  ASSERT(!parameter_keys.IsNull());
  ASSERT(!parameter_values.IsNull());
  ASSERT(!reply_port.IsNull());
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  isolate->AppendServiceExtensionCall(handler,
                                      method_name,
                                      parameter_keys,
                                      parameter_values,
                                      reply_port,
                                      id);
}


static const MethodParameter* get_isolate_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetIsolate(Thread* thread, JSONStream* js) {
  thread->isolate()->PrintJSON(js, false);
  return true;
}


static const MethodParameter* get_stack_params[] = {
  ISOLATE_PARAMETER,
  new BoolParameter("_full", false),
  NULL,
};


static bool GetStack(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot get stack when running a precompiled program.");
    return true;
  }
  Isolate* isolate = thread->isolate();
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  // Do we want the complete script object and complete local variable objects?
  // This is true for dump requests.
  const bool full = BoolParameter::Parse(js->LookupParam("_full"), false);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Stack");
  {
    JSONArray jsarr(&jsobj, "frames");

    intptr_t num_frames = stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      JSONObject jsobj(&jsarr);
      frame->PrintToJSONObject(&jsobj, full);
      jsobj.AddProperty("index", i);
    }
  }

  {
    MessageHandler::AcquiredQueues aq;
    isolate->message_handler()->AcquireQueues(&aq);
    jsobj.AddProperty("messages", aq.queue());
  }

  return true;
}


static bool HandleCommonEcho(JSONObject* jsobj, JSONStream* js) {
  jsobj->AddProperty("type", "_EchoResponse");
  if (js->HasParam("text")) {
    jsobj->AddProperty("text", js->LookupParam("text"));
  }
  return true;
}


void Service::SendEchoEvent(Isolate* isolate, const char* text) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("jsonrpc", "2.0");
    jsobj.AddProperty("method", "streamNotify");
    {
      JSONObject params(&jsobj, "params");
      params.AddProperty("streamId", echo_stream.id());
      {
        JSONObject event(&params, "event");
        event.AddProperty("type", "Event");
        event.AddProperty("kind", "_Echo");
        event.AddProperty("isolate", isolate);
        if (text != NULL) {
          event.AddProperty("text", text);
        }
        event.AddPropertyTimeMillis("timestamp", OS::GetCurrentTimeMillis());
      }
    }
  }
  const String& message = String::Handle(String::New(js.ToCString()));
  uint8_t data[] = {0, 128, 255};
  SendEventWithData(echo_stream.id(), "_Echo", message, data, sizeof(data));
}


static bool TriggerEchoEvent(Thread* thread, JSONStream* js) {
  if (Service::echo_stream.enabled()) {
    Service::SendEchoEvent(thread->isolate(), js->LookupParam("text"));
  }
  JSONObject jsobj(js);
  return HandleCommonEcho(&jsobj, js);
}


static bool DumpIdZone(Thread* thread, JSONStream* js) {
  // TODO(johnmccutchan): Respect _idZone parameter passed to RPC. For now,
  // always send the ObjectIdRing.
  //
  ObjectIdRing* ring = thread->isolate()->object_id_ring();
  ASSERT(ring != NULL);
  // When printing the ObjectIdRing, force object id reuse policy.
  RingServiceIdZone reuse_zone;
  reuse_zone.Init(ring, ObjectIdRing::kReuseId);
  js->set_id_zone(&reuse_zone);
  ring->PrintJSON(js);
  return true;
}


static bool Echo(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  return HandleCommonEcho(&jsobj, js);
}


static bool ContainsNonInstance(const Object& obj) {
  if (obj.IsArray()) {
    const Array& array = Array::Cast(obj);
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < array.Length(); ++i) {
      element = array.At(i);
      if (!(element.IsInstance() || element.IsNull())) {
        return true;
      }
    }
    return false;
  } else if (obj.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(obj);
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < array.Length(); ++i) {
      element = array.At(i);
      if (!(element.IsInstance() || element.IsNull())) {
        return true;
      }
    }
    return false;
  } else {
    return !(obj.IsInstance() || obj.IsNull());
  }
}


static RawObject* LookupObjectId(Thread* thread,
                                 const char* arg,
                                 ObjectIdRing::LookupResult* kind) {
  *kind = ObjectIdRing::kValid;
  if (strncmp(arg, "int-", 4) == 0) {
    arg += 4;
    int64_t value = 0;
    if (!OS::StringToInt64(arg, &value) ||
        !Smi::IsValid(value)) {
      *kind = ObjectIdRing::kInvalid;
      return Object::null();
    }
    const Integer& obj = Integer::Handle(thread->zone(),
        Smi::New(static_cast<intptr_t>(value)));
    return obj.raw();
  } else if (strcmp(arg, "bool-true") == 0) {
    return Bool::True().raw();
  } else if (strcmp(arg, "bool-false") == 0) {
    return Bool::False().raw();
  } else if (strcmp(arg, "null") == 0) {
    return Object::null();
  }

  ObjectIdRing* ring = thread->isolate()->object_id_ring();
  ASSERT(ring != NULL);
  intptr_t id = -1;
  if (!GetIntegerId(arg, &id)) {
    *kind = ObjectIdRing::kInvalid;
    return Object::null();
  }
  return ring->GetObjectForId(id, kind);
}


static RawObject* LookupHeapObjectLibraries(Isolate* isolate,
                                            char** parts, int num_parts) {
  // Library ids look like "libraries/35"
  if (num_parts < 2) {
    return Object::sentinel().raw();
  }
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  ASSERT(!libs.IsNull());
  intptr_t id = 0;
  if (!GetIntegerId(parts[1], &id)) {
    return Object::sentinel().raw();
  }
  if ((id < 0) || (id >= libs.Length())) {
    return Object::sentinel().raw();
  }
  Library& lib = Library::Handle();
  lib ^= libs.At(id);
  ASSERT(!lib.IsNull());
  if (num_parts == 2) {
    return lib.raw();
  }
  if (strcmp(parts[2], "scripts") == 0) {
    // Script ids look like "libraries/35/scripts/library%2Furl.dart"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    const String& id = String::Handle(String::New(parts[3]));
    ASSERT(!id.IsNull());
    // The id is the url of the script % encoded, decode it.
    const String& requested_url = String::Handle(String::DecodeIRI(id));
    Script& script = Script::Handle();
    String& script_url = String::Handle();
    const Array& loaded_scripts = Array::Handle(lib.LoadedScripts());
    ASSERT(!loaded_scripts.IsNull());
    intptr_t i;
    for (i = 0; i < loaded_scripts.Length(); i++) {
      script ^= loaded_scripts.At(i);
      ASSERT(!script.IsNull());
      script_url ^= script.url();
      if (script_url.Equals(requested_url)) {
        return script.raw();
      }
    }
  }

  // Not found.
  return Object::sentinel().raw();
}

static RawObject* LookupHeapObjectClasses(Thread* thread,
                                          char** parts, int num_parts) {
  // Class ids look like: "classes/17"
  if (num_parts < 2) {
    return Object::sentinel().raw();
  }
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  ClassTable* table = isolate->class_table();
  intptr_t id;
  if (!GetIntegerId(parts[1], &id) ||
      !table->IsValidIndex(id)) {
    return Object::sentinel().raw();
  }
  Class& cls = Class::Handle(zone, table->At(id));
  if (num_parts == 2) {
    return cls.raw();
  }
  if (strcmp(parts[2], "closures") == 0) {
    // Closure ids look like: "classes/17/closures/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().raw();
    }
    Function& func = Function::Handle(zone);
    func ^= isolate->ClosureFunctionFromIndex(id);
    if (func.IsNull()) {
      return Object::sentinel().raw();
    }
    return func.raw();

  } else if (strcmp(parts[2], "fields") == 0) {
    // Field ids look like: "classes/17/fields/name"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    const char* encoded_id = parts[3];
    String& id = String::Handle(zone, String::New(encoded_id));
    id = String::DecodeIRI(id);
    if (id.IsNull()) {
      return Object::sentinel().raw();
    }
    Field& field = Field::Handle(zone, cls.LookupField(id));
    if (field.IsNull()) {
      return Object::sentinel().raw();
    }
    return field.raw();

  } else if (strcmp(parts[2], "functions") == 0) {
    // Function ids look like: "classes/17/functions/name"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    const char* encoded_id = parts[3];
    String& id = String::Handle(zone, String::New(encoded_id));
    id = String::DecodeIRI(id);
    if (id.IsNull()) {
      return Object::sentinel().raw();
    }
    Function& func = Function::Handle(zone, cls.LookupFunction(id));
    if (func.IsNull()) {
      return Object::sentinel().raw();
    }
    return func.raw();

  } else if (strcmp(parts[2], "implicit_closures") == 0) {
    // Function ids look like: "classes/17/implicit_closures/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().raw();
    }
    Function& func = Function::Handle(zone);
    func ^= cls.ImplicitClosureFunctionFromIndex(id);
    if (func.IsNull()) {
      return Object::sentinel().raw();
    }
    return func.raw();

  } else if (strcmp(parts[2], "dispatchers") == 0) {
    // Dispatcher Function ids look like: "classes/17/dispatchers/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().raw();
    }
    Function& func = Function::Handle(zone);
    func ^= cls.InvocationDispatcherFunctionFromIndex(id);
    if (func.IsNull()) {
      return Object::sentinel().raw();
    }
    return func.raw();

  } else if (strcmp(parts[2], "types") == 0) {
    // Type ids look like: "classes/17/types/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().raw();
    }
    Type& type = Type::Handle(zone);
    type ^= cls.CanonicalTypeFromIndex(id);
    if (type.IsNull()) {
      return Object::sentinel().raw();
    }
    return type.raw();
  }

  // Not found.
  return Object::sentinel().raw();
}


static RawObject* LookupHeapObjectTypeArguments(Thread* thread,
                                                char** parts, int num_parts) {
  Isolate* isolate = thread->isolate();
  // TypeArguments ids look like: "typearguments/17"
  if (num_parts < 2) {
    return Object::sentinel().raw();
  }
  intptr_t id;
  if (!GetIntegerId(parts[1], &id)) {
    return Object::sentinel().raw();
  }
  ObjectStore* object_store = isolate->object_store();
  const Array& table = Array::Handle(thread->zone(),
                                     object_store->canonical_type_arguments());
  ASSERT(table.Length() > 0);
  const intptr_t table_size = table.Length() - 1;
  if ((id < 0) || (id >= table_size) || (table.At(id) == Object::null())) {
    return Object::sentinel().raw();
  }
  return table.At(id);
}


static RawObject* LookupHeapObjectCode(Isolate* isolate,
                                       char** parts, int num_parts) {
  if (num_parts != 2) {
    return Object::sentinel().raw();
  }
  uword pc;
  static const char* const kCollectedPrefix = "collected-";
  static intptr_t kCollectedPrefixLen = strlen(kCollectedPrefix);
  static const char* const kNativePrefix = "native-";
  static const intptr_t kNativePrefixLen = strlen(kNativePrefix);
  static const char* const kReusedPrefix = "reused-";
  static const intptr_t kReusedPrefixLen = strlen(kReusedPrefix);
  const char* id = parts[1];
  if (strncmp(kCollectedPrefix, id, kCollectedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kCollectedPrefixLen], &pc, 16)) {
      return Object::sentinel().raw();
    }
    // TODO(turnidge): Return "collected" instead.
    return Object::null();
  }
  if (strncmp(kNativePrefix, id, kNativePrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kNativePrefixLen], &pc, 16)) {
      return Object::sentinel().raw();
    }
    // TODO(johnmccutchan): Support native Code.
    return Object::null();
  }
  if (strncmp(kReusedPrefix, id, kReusedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kReusedPrefixLen], &pc, 16)) {
      return Object::sentinel().raw();
    }
    // TODO(turnidge): Return "expired" instead.
    return Object::null();
  }
  int64_t timestamp = 0;
  if (!GetCodeId(id, &timestamp, &pc) || (timestamp < 0)) {
    return Object::sentinel().raw();
  }
  Code& code = Code::Handle(Code::FindCode(pc, timestamp));
  if (!code.IsNull()) {
    return code.raw();
  }

  // Not found.
  return Object::sentinel().raw();
}


static RawObject* LookupHeapObjectMessage(Thread* thread,
                                          char** parts, int num_parts) {
  if (num_parts != 2) {
    return Object::sentinel().raw();
  }
  uword message_id = 0;
  if (!GetUnsignedIntegerId(parts[1], &message_id, 16)) {
    return Object::sentinel().raw();
  }
  MessageHandler::AcquiredQueues aq;
  thread->isolate()->message_handler()->AcquireQueues(&aq);
  Message* message = aq.queue()->FindMessageById(message_id);
  if (message == NULL) {
    // The user may try to load an expired message.
    return Object::sentinel().raw();
  }
  if (message->len() > 0) {
    MessageSnapshotReader reader(message->data(),
                                 message->len(),
                                 thread);
    return reader.ReadObject();
  } else {
    return message->raw_obj();
  }
}


static RawObject* LookupHeapObject(Thread* thread,
                                   const char* id_original,
                                   ObjectIdRing::LookupResult* result) {
  char* id = thread->zone()->MakeCopyOfString(id_original);

  // Parse the id by splitting at each '/'.
  const int MAX_PARTS = 8;
  char* parts[MAX_PARTS];
  int num_parts = 0;
  int i = 0;
  int start_pos = 0;
  while (id[i] != '\0') {
    if (id[i] == '/') {
      id[i++] = '\0';
      parts[num_parts++] = &id[start_pos];
      if (num_parts == MAX_PARTS) {
        break;
      }
      start_pos = i;
    } else {
      i++;
    }
  }
  if (num_parts < MAX_PARTS) {
    parts[num_parts++] = &id[start_pos];
  }

  if (result != NULL) {
    *result = ObjectIdRing::kValid;
  }

  Isolate* isolate = thread->isolate();
  if (strcmp(parts[0], "objects") == 0) {
    // Object ids look like "objects/1123"
    Object& obj = Object::Handle(thread->zone());
    ObjectIdRing::LookupResult lookup_result;
    obj = LookupObjectId(thread, parts[1], &lookup_result);
    if (lookup_result != ObjectIdRing::kValid) {
      if (result != NULL) {
        *result = lookup_result;
      }
      return Object::sentinel().raw();
    }
    return obj.raw();

  } else if (strcmp(parts[0], "libraries") == 0) {
    return LookupHeapObjectLibraries(isolate, parts, num_parts);
  } else if (strcmp(parts[0], "classes") == 0) {
    return LookupHeapObjectClasses(thread, parts, num_parts);
  } else if (strcmp(parts[0], "typearguments") == 0) {
    return LookupHeapObjectTypeArguments(thread, parts, num_parts);
  } else if (strcmp(parts[0], "code") == 0) {
    return LookupHeapObjectCode(isolate, parts, num_parts);
  } else if (strcmp(parts[0], "messages") == 0) {
    return LookupHeapObjectMessage(thread, parts, num_parts);
  }

  // Not found.
  return Object::sentinel().raw();
}


enum SentinelType {
  kCollectedSentinel,
  kExpiredSentinel,
  kFreeSentinel,
};


static void PrintSentinel(JSONStream* js, SentinelType sentinel_type) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Sentinel");
  switch (sentinel_type) {
    case kCollectedSentinel:
      jsobj.AddProperty("kind", "Collected");
      jsobj.AddProperty("valueAsString", "<collected>");
      break;
    case kExpiredSentinel:
      jsobj.AddProperty("kind", "Expired");
      jsobj.AddProperty("valueAsString", "<expired>");
      break;
    case kFreeSentinel:
      jsobj.AddProperty("kind", "Free");
      jsobj.AddProperty("valueAsString", "<free>");
      break;
    default:
      UNIMPLEMENTED();
      break;
  }
}


static Breakpoint* LookupBreakpoint(Isolate* isolate,
                                    const char* id,
                                    ObjectIdRing::LookupResult* result) {
  *result = ObjectIdRing::kInvalid;
  size_t end_pos = strcspn(id, "/");
  if (end_pos == strlen(id)) {
    return NULL;
  }
  const char* rest = id + end_pos + 1;  // +1 for '/'.
  if (strncmp("breakpoints", id, end_pos) == 0) {
    intptr_t bpt_id = 0;
    Breakpoint* bpt = NULL;
    if (GetIntegerId(rest, &bpt_id)) {
      bpt = isolate->debugger()->GetBreakpointById(bpt_id);
      if (bpt) {
        *result = ObjectIdRing::kValid;
        return bpt;
      }
      if (bpt_id < isolate->debugger()->limitBreakpointId()) {
        *result = ObjectIdRing::kCollected;
        return NULL;
      }
    }
  }
  return NULL;
}


static bool PrintInboundReferences(Thread* thread,
                                   Object* target,
                                   intptr_t limit,
                                   JSONStream* js) {
  ObjectGraph graph(thread);
  Array& path = Array::Handle(Array::New(limit * 2));
  intptr_t length = graph.InboundReferences(target, path);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "InboundReferences");
  {
    JSONArray elements(&jsobj, "references");
    Object& source = Object::Handle();
    Smi& slot_offset = Smi::Handle();
    Class& source_class = Class::Handle();
    Field& field = Field::Handle();
    Array& parent_field_map = Array::Handle();
    limit = Utils::Minimum(limit, length);
    for (intptr_t i = 0; i < limit; ++i) {
      JSONObject jselement(&elements);
      source = path.At(i * 2);
      slot_offset ^= path.At((i * 2) + 1);

      jselement.AddProperty("source", source);
      if (source.IsArray()) {
        intptr_t element_index = slot_offset.Value() -
            (Array::element_offset(0) >> kWordSizeLog2);
        jselement.AddProperty("parentListIndex", element_index);
      } else if (source.IsInstance()) {
        source_class ^= source.clazz();
        parent_field_map = source_class.OffsetToFieldMap();
        intptr_t offset = slot_offset.Value();
        if (offset > 0 && offset < parent_field_map.Length()) {
          field ^= parent_field_map.At(offset);
          jselement.AddProperty("parentField", field);
        }
      } else {
        intptr_t element_index = slot_offset.Value();
        jselement.AddProperty("_parentWordOffset", element_index);
      }

      // We nil out the array after generating the response to prevent
      // reporting suprious references when repeatedly looking for the
      // references to an object.
      path.SetAt(i * 2, Object::null_object());
    }
  }
  return true;
}


static const MethodParameter* get_inbound_references_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetInboundReferences(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (limit_cstr == NULL) {
    PrintMissingParamError(js, "limit");
    return true;
  }
  intptr_t limit;
  if (!GetIntegerId(limit_cstr, &limit)) {
    PrintInvalidParamError(js, "limit");
    return true;
  }

  Object& obj = Object::Handle(thread->zone());
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(thread);
    obj = LookupHeapObject(thread, target_id, &lookup_result);
  }
  if (obj.raw() == Object::sentinel().raw()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return true;
  }
  return PrintInboundReferences(thread, &obj, limit, js);
}


static bool PrintRetainingPath(Thread* thread,
                               Object* obj,
                               intptr_t limit,
                               JSONStream* js) {
  ObjectGraph graph(thread);
  Array& path = Array::Handle(Array::New(limit * 2));
  intptr_t length = graph.RetainingPath(obj, path);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "RetainingPath");
  jsobj.AddProperty("length", length);
  JSONArray elements(&jsobj, "elements");
  Object& element = Object::Handle();
  Smi& slot_offset = Smi::Handle();
  Class& element_class = Class::Handle();
  Array& element_field_map = Array::Handle();
  Field& field = Field::Handle();
  limit = Utils::Minimum(limit, length);
  for (intptr_t i = 0; i < limit; ++i) {
    JSONObject jselement(&elements);
    element = path.At(i * 2);
    jselement.AddProperty("index", i);
    jselement.AddProperty("value", element);
    // Interpret the word offset from parent as list index or instance field.
    // TODO(koda): User-friendly interpretation for map entries.
    if (i > 0) {
      slot_offset ^= path.At((i * 2) - 1);
      if (element.IsArray()) {
        intptr_t element_index = slot_offset.Value() -
            (Array::element_offset(0) >> kWordSizeLog2);
        jselement.AddProperty("parentListIndex", element_index);
      } else if (element.IsInstance()) {
        element_class ^= element.clazz();
        element_field_map = element_class.OffsetToFieldMap();
        intptr_t offset = slot_offset.Value();
        if (offset > 0 && offset < element_field_map.Length()) {
          field ^= element_field_map.At(offset);
          jselement.AddProperty("parentField", field);
        }
      } else {
        intptr_t element_index = slot_offset.Value();
        jselement.AddProperty("_parentWordOffset", element_index);
      }
    }
  }

  // We nil out the array after generating the response to prevent
  // reporting spurious references when looking for inbound references
  // after looking for a retaining path.
  for (intptr_t i = 0; i < limit; ++i) {
    path.SetAt(i * 2, Object::null_object());
  }

  return true;
}


static const MethodParameter* get_retaining_path_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetRetainingPath(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (limit_cstr == NULL) {
    PrintMissingParamError(js, "limit");
    return true;
  }
  intptr_t limit;
  if (!GetIntegerId(limit_cstr, &limit)) {
    PrintInvalidParamError(js, "limit");
    return true;
  }

  Object& obj = Object::Handle(thread->zone());
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(thread);
    obj = LookupHeapObject(thread, target_id, &lookup_result);
  }
  if (obj.raw() == Object::sentinel().raw()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return true;
  }
  return PrintRetainingPath(thread, &obj, limit, js);
}


static const MethodParameter* get_retained_size_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", true),
  NULL,
};


static bool GetRetainedSize(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  ASSERT(target_id != NULL);
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(thread, target_id,
                                                &lookup_result));
  if (obj.raw() == Object::sentinel().raw()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return true;
  }
  // TODO(rmacnak): There is no way to get the size retained by a class object.
  // SizeRetainedByClass should be a separate RPC.
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    ObjectGraph graph(thread);
    intptr_t retained_size = graph.SizeRetainedByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  }

  ObjectGraph graph(thread);
  intptr_t retained_size = graph.SizeRetainedByInstance(obj);
  const Object& result = Object::Handle(Integer::New(retained_size));
  result.PrintJSON(js, true);
  return true;
}


static const MethodParameter* get_reachable_size_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", true),
  NULL,
};


static bool GetReachableSize(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  ASSERT(target_id != NULL);
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(thread, target_id,
                                                &lookup_result));
  if (obj.raw() == Object::sentinel().raw()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return true;
  }
  // TODO(rmacnak): There is no way to get the size retained by a class object.
  // SizeRetainedByClass should be a separate RPC.
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    ObjectGraph graph(thread);
    intptr_t retained_size = graph.SizeReachableByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  }

  ObjectGraph graph(thread);
  intptr_t retained_size = graph.SizeReachableByInstance(obj);
  const Object& result = Object::Handle(Integer::New(retained_size));
  result.PrintJSON(js, true);
  return true;
}


static const MethodParameter* evaluate_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool Evaluate(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
                   "Cannot evaluate when running a precompiled program.");
    return true;
  }
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  const char* expr = js->LookupParam("expression");
  if (expr == NULL) {
    PrintMissingParamError(js, "expression");
    return true;
  }
  Zone* zone = thread->zone();
  const String& expr_str = String::Handle(zone, String::New(expr));
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(zone, LookupHeapObject(thread, target_id,
                                                      &lookup_result));
  if (obj.raw() == Object::sentinel().raw()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return true;
  }
  if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    const Object& result = Object::Handle(zone,
        lib.Evaluate(expr_str, Array::empty_array(), Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  }
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    const Object& result = Object::Handle(zone,
        cls.Evaluate(expr_str, Array::empty_array(), Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  }
  if ((obj.IsInstance() || obj.IsNull()) &&
      !ContainsNonInstance(obj)) {
    // We don't use Instance::Cast here because it doesn't allow null.
    Instance& instance = Instance::Handle(zone);
    instance ^= obj.raw();
    const Object& result =
        Object::Handle(zone, instance.Evaluate(expr_str,
                                               Array::empty_array(),
                                               Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  }
  js->PrintError(kInvalidParams,
                 "%s: invalid 'targetId' parameter: "
                 "id '%s' does not correspond to a "
                 "library, class, or instance", js->method(), target_id);
  return true;
}


static const MethodParameter* evaluate_in_frame_params[] = {
  ISOLATE_PARAMETER,
  new UIntParameter("frameIndex", true),
  new MethodParameter("expression", true),
  NULL,
};


static bool EvaluateInFrame(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  if (!isolate->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
                   "Cannot evaluate when running a precompiled program.");
    return true;
  }
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  intptr_t framePos = UIntParameter::Parse(js->LookupParam("frameIndex"));
  if (framePos > stack->Length()) {
    PrintInvalidParamError(js, "frameIndex");
    return true;
  }
  ActivationFrame* frame = stack->FrameAt(framePos);

  Zone* zone = thread->zone();
  const char* expr = js->LookupParam("expression");
  const String& expr_str = String::Handle(zone, String::New(expr));

  const Object& result = Object::Handle(zone, frame->Evaluate(expr_str));
  result.PrintJSON(js, true);
  return true;
}


class GetInstancesVisitor : public ObjectGraph::Visitor {
 public:
  GetInstancesVisitor(const Class& cls, const Array& storage)
      : cls_(cls), storage_(storage), count_(0) {}

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* raw_obj = it->Get();
    if (raw_obj->IsFreeListElement()) {
      return kProceed;
    }
    Thread* thread = Thread::Current();
    REUSABLE_OBJECT_HANDLESCOPE(thread);
    Object& obj = thread->ObjectHandle();
    obj = raw_obj;
    if (obj.GetClassId() == cls_.id()) {
      if (!storage_.IsNull() && count_ < storage_.Length()) {
        storage_.SetAt(count_, obj);
      }
      ++count_;
    }
    return kProceed;
  }

  intptr_t count() const { return count_; }

 private:
  const Class& cls_;
  const Array& storage_;
  intptr_t count_;
};


static const MethodParameter* get_instances_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetInstances(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("classId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "classId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (limit_cstr == NULL) {
    PrintMissingParamError(js, "limit");
    return true;
  }
  intptr_t limit;
  if (!GetIntegerId(limit_cstr, &limit)) {
    PrintInvalidParamError(js, "limit");
    return true;
  }
  const Object& obj =
      Object::Handle(LookupHeapObject(thread, target_id, NULL));
  if (obj.raw() == Object::sentinel().raw() ||
      !obj.IsClass()) {
    PrintInvalidParamError(js, "classId");
    return true;
  }
  const Class& cls = Class::Cast(obj);
  Array& storage = Array::Handle(Array::New(limit));
  GetInstancesVisitor visitor(cls, storage);
  ObjectGraph graph(thread);
  graph.IterateObjects(&visitor);
  intptr_t count = visitor.count();
  if (count < limit) {
    // Truncate the list using utility method for GrowableObjectArray.
    GrowableObjectArray& wrapper = GrowableObjectArray::Handle(
        GrowableObjectArray::New(storage));
    wrapper.SetLength(count);
    storage = Array::MakeArray(wrapper);
  }
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "InstanceSet");
  jsobj.AddProperty("totalCount", count);
  {
    JSONArray samples(&jsobj, "samples");
    for (int i = 0; i < storage.Length(); i++) {
      const Object& sample = Object::Handle(storage.At(i));
      samples.AddValue(sample);
    }
  }
  return true;
}


class LibraryCoverageFilter : public CoverageFilter {
 public:
  explicit LibraryCoverageFilter(const Library& lib) : lib_(lib) {}
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return lib.raw() == lib_.raw();
  }
 private:
  const Library& lib_;
};


class ScriptCoverageFilter : public CoverageFilter {
 public:
  explicit ScriptCoverageFilter(const Script& script)
      : script_(script) {}
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return script.raw() == script_.raw();
  }
 private:
  const Script& script_;
};


class ClassCoverageFilter : public CoverageFilter {
 public:
  explicit ClassCoverageFilter(const Class& cls) : cls_(cls) {}
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return cls.raw() == cls_.raw();
  }
 private:
  const Class& cls_;
};


class FunctionCoverageFilter : public CoverageFilter {
 public:
  explicit FunctionCoverageFilter(const Function& func) : func_(func) {}
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return func.raw() == func_.raw();
  }
 private:
  const Function& func_;
};


static bool GetHitsOrSites(Thread* thread, JSONStream* js, bool as_sites) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot get coverage data when running a precompiled program.");
    return true;
  }
  if (!js->HasParam("targetId")) {
    CodeCoverage::PrintJSON(thread, js, NULL, as_sites);
    return true;
  }
  const char* target_id = js->LookupParam("targetId");
  Object& obj = Object::Handle(LookupHeapObject(thread, target_id, NULL));
  if (obj.raw() == Object::sentinel().raw()) {
    PrintInvalidParamError(js, "targetId");
    return true;
  }
  if (obj.IsScript()) {
    ScriptCoverageFilter sf(Script::Cast(obj));
    CodeCoverage::PrintJSON(thread, js, &sf, as_sites);
    return true;
  }
  if (obj.IsLibrary()) {
    LibraryCoverageFilter lf(Library::Cast(obj));
    CodeCoverage::PrintJSON(thread, js, &lf, as_sites);
    return true;
  }
  if (obj.IsClass()) {
    ClassCoverageFilter cf(Class::Cast(obj));
    CodeCoverage::PrintJSON(thread, js, &cf, as_sites);
    return true;
  }
  if (obj.IsFunction()) {
    FunctionCoverageFilter ff(Function::Cast(obj));
    CodeCoverage::PrintJSON(thread, js, &ff, as_sites);
    return true;
  }
  js->PrintError(kInvalidParams,
                 "%s: invalid 'targetId' parameter: "
                 "id '%s' does not correspond to a "
                 "script, library, class, or function",
                 js->method(), target_id);
  return true;
}


static const MethodParameter* get_coverage_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", false),
  NULL,
};


static bool GetCoverage(Thread* thread, JSONStream* js) {
  // TODO(rmacnak): Remove this response; it is subsumed by GetCallSiteData.
  return GetHitsOrSites(thread, js, false);
}


static const MethodParameter* get_call_site_data_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", false),
  NULL,
};


static bool GetCallSiteData(Thread* thread, JSONStream* js) {
  return GetHitsOrSites(thread, js, true);
}


static bool AddBreakpointCommon(Thread* thread,
                                JSONStream* js,
                                const String& script_uri) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  const char* line_param = js->LookupParam("line");
  intptr_t line = UIntParameter::Parse(line_param);
  const char* col_param = js->LookupParam("column");
  intptr_t col = -1;
  if (col_param != NULL) {
    col = UIntParameter::Parse(col_param);
    if (col == 0) {
      // Column number is 1-based.
      PrintInvalidParamError(js, "column");
      return true;
    }
  }
  ASSERT(!script_uri.IsNull());
  Breakpoint* bpt = NULL;
  bpt = thread->isolate()->debugger()->
      SetBreakpointAtLineCol(script_uri, line, col);
  if (bpt == NULL) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at line '%s'",
                   js->method(), line_param);
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static const MethodParameter* add_breakpoint_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("scriptId", true),
  new UIntParameter("line", true),
  new UIntParameter("column", false),
  NULL,
};


static bool AddBreakpoint(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  const char* script_id_param = js->LookupParam("scriptId");
  Object& obj = Object::Handle(LookupHeapObject(thread, script_id_param, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsScript()) {
    PrintInvalidParamError(js, "scriptId");
    return true;
  }
  const Script& script = Script::Cast(obj);
  const String& script_uri = String::Handle(script.url());
  ASSERT(!script_uri.IsNull());
  return AddBreakpointCommon(thread, js, script_uri);
}


static const MethodParameter* add_breakpoint_with_script_uri_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("scriptUri", true),
  new UIntParameter("line", true),
  new UIntParameter("column", false),
  NULL,
};


static bool AddBreakpointWithScriptUri(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  const char* script_uri_param = js->LookupParam("scriptUri");
  const String& script_uri = String::Handle(String::New(script_uri_param));
  return AddBreakpointCommon(thread, js, script_uri);
}


static const MethodParameter* add_breakpoint_at_entry_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("functionId", true),
  NULL,
};


static bool AddBreakpointAtEntry(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  const char* function_id = js->LookupParam("functionId");
  Object& obj = Object::Handle(LookupHeapObject(thread, function_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsFunction()) {
    PrintInvalidParamError(js, "functionId");
    return true;
  }
  const Function& function = Function::Cast(obj);
  Breakpoint* bpt =
      thread->isolate()->debugger()->SetBreakpointAtEntry(function, false);
  if (bpt == NULL) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at function '%s'",
                   js->method(), function.ToCString());
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static const MethodParameter* add_breakpoint_at_activation_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("objectId", true),
  NULL,
};


static bool AddBreakpointAtActivation(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  const char* object_id = js->LookupParam("objectId");
  Object& obj = Object::Handle(LookupHeapObject(thread, object_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsInstance()) {
    PrintInvalidParamError(js, "objectId");
    return true;
  }
  const Instance& closure = Instance::Cast(obj);
  Breakpoint* bpt =
      thread->isolate()->debugger()->SetBreakpointAtActivation(closure);
  if (bpt == NULL) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at activation",
                   js->method());
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static const MethodParameter* remove_breakpoint_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool RemoveBreakpoint(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot use breakpoints when running a precompiled program.");
    return true;
  }
  if (!js->HasParam("breakpointId")) {
    PrintMissingParamError(js, "breakpointId");
    return true;
  }
  const char* bpt_id = js->LookupParam("breakpointId");
  ObjectIdRing::LookupResult lookup_result;
  Isolate* isolate = thread->isolate();
  Breakpoint* bpt = LookupBreakpoint(isolate, bpt_id, &lookup_result);
  // TODO(turnidge): Should we return a different error for bpts whic
  // have been already removed?
  if (bpt == NULL) {
    PrintInvalidParamError(js, "breakpointId");
    return true;
  }
  isolate->debugger()->RemoveBreakpoint(bpt->id());
  PrintSuccess(js);
  return true;
}


static RawClass* GetMetricsClass(Thread* thread) {
  Zone* zone = thread->zone();
  const Library& prof_lib =
      Library::Handle(zone, Library::DeveloperLibrary());
  ASSERT(!prof_lib.IsNull());
  const String& metrics_cls_name =
      String::Handle(zone, String::New("Metrics"));
  ASSERT(!metrics_cls_name.IsNull());
  const Class& metrics_cls =
      Class::Handle(zone, prof_lib.LookupClass(metrics_cls_name));
  ASSERT(!metrics_cls.IsNull());
  return metrics_cls.raw();
}



static bool HandleNativeMetricsList(Thread* thread, JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "MetricList");
  {
    JSONArray metrics(&obj, "metrics");
    Metric* current = thread->isolate()->metrics_list_head();
    while (current != NULL) {
      metrics.AddValue(current);
      current = current->next();
    }
  }
  return true;
}


static bool HandleNativeMetric(Thread* thread, JSONStream* js, const char* id) {
  Metric* current = thread->isolate()->metrics_list_head();
  while (current != NULL) {
    const char* name = current->name();
    ASSERT(name != NULL);
    if (strcmp(name, id) == 0) {
      current->PrintJSON(js);
      return true;
    }
    current = current->next();
  }
  PrintInvalidParamError(js, "metricId");
  return true;
}


static bool HandleDartMetricsList(Thread* thread, JSONStream* js) {
  Zone* zone = thread->zone();
  const Class& metrics_cls =
      Class::Handle(zone, GetMetricsClass(thread));
  const String& print_metrics_name =
      String::Handle(String::New("_printMetrics"));
  ASSERT(!print_metrics_name.IsNull());
  const Function& print_metrics = Function::Handle(
      zone,
      metrics_cls.LookupStaticFunctionAllowPrivate(print_metrics_name));
  ASSERT(!print_metrics.IsNull());
  const Array& args = Object::empty_array();
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(print_metrics, args));
  ASSERT(!result.IsNull());
  ASSERT(result.IsString());
  TextBuffer* buffer = js->buffer();
  buffer->AddString(String::Cast(result).ToCString());
  return true;
}


static bool HandleDartMetric(Thread* thread, JSONStream* js, const char* id) {
  Zone* zone = thread->zone();
  const Class& metrics_cls =
      Class::Handle(zone, GetMetricsClass(thread));
  const String& print_metric_name =
      String::Handle(String::New("_printMetric"));
  ASSERT(!print_metric_name.IsNull());
  const Function& print_metric = Function::Handle(
      zone,
      metrics_cls.LookupStaticFunctionAllowPrivate(print_metric_name));
  ASSERT(!print_metric.IsNull());
  const String& arg0 = String::Handle(String::New(id));
  ASSERT(!arg0.IsNull());
  const Array& args = Array::Handle(Array::New(1));
  ASSERT(!args.IsNull());
  args.SetAt(0, arg0);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(print_metric, args));
  if (!result.IsNull()) {
    ASSERT(result.IsString());
    TextBuffer* buffer = js->buffer();
    buffer->AddString(String::Cast(result).ToCString());
    return true;
  }
  PrintInvalidParamError(js, "metricId");
  return true;
}


static const MethodParameter* get_isolate_metric_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetIsolateMetricList(Thread* thread, JSONStream* js) {
  bool native_metrics = false;
  if (js->HasParam("type")) {
    if (js->ParamIs("type", "Native")) {
      native_metrics = true;
    } else if (js->ParamIs("type", "Dart")) {
      native_metrics = false;
    } else {
      PrintInvalidParamError(js, "type");
      return true;
    }
  } else {
    PrintMissingParamError(js, "type");
    return true;
  }
  if (native_metrics) {
    return HandleNativeMetricsList(thread, js);
  }
  return HandleDartMetricsList(thread, js);
}


static const MethodParameter* get_isolate_metric_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetIsolateMetric(Thread* thread, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == NULL) {
    PrintMissingParamError(js, "metricId");
    return true;
  }
  // Verify id begins with "metrics/".
  static const char* const kMetricIdPrefix = "metrics/";
  static intptr_t kMetricIdPrefixLen = strlen(kMetricIdPrefix);
  if (strncmp(metric_id, kMetricIdPrefix, kMetricIdPrefixLen) != 0) {
    PrintInvalidParamError(js, "metricId");
    return true;
  }
  // Check if id begins with "metrics/native/".
  static const char* const kNativeMetricIdPrefix = "metrics/native/";
  static intptr_t kNativeMetricIdPrefixLen = strlen(kNativeMetricIdPrefix);
  const bool native_metric =
      strncmp(metric_id, kNativeMetricIdPrefix, kNativeMetricIdPrefixLen) == 0;
  if (native_metric) {
    const char* id = metric_id + kNativeMetricIdPrefixLen;
    return HandleNativeMetric(thread, js, id);
  }
  const char* id = metric_id + kMetricIdPrefixLen;
  return HandleDartMetric(thread, js, id);
}


static const MethodParameter* get_vm_metric_list_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetVMMetricList(Thread* thread, JSONStream* js) {
  return false;
}


static const MethodParameter* get_vm_metric_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetVMMetric(Thread* thread, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == NULL) {
    PrintMissingParamError(js, "metricId");
  }
  return false;
}


static const MethodParameter* set_vm_timeline_flag_params[] = {
  NO_ISOLATE_PARAMETER,
  new MethodParameter("_record", true),
  NULL,
};


static bool SetVMTimelineFlag(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  StackZone zone(thread);

  bool recording = strcmp(js->LookupParam("_record"), "all") == 0;
  Timeline::SetStreamAPIEnabled(recording);
  Timeline::SetStreamCompilerEnabled(recording);
  Timeline::SetStreamDartEnabled(recording);
  Timeline::SetStreamDebuggerEnabled(recording);
  Timeline::SetStreamEmbedderEnabled(recording);
  Timeline::SetStreamGCEnabled(recording);
  Timeline::SetStreamIsolateEnabled(recording);

  PrintSuccess(js);

  return true;
}


static const MethodParameter* get_vm_timeline_flag_params[] = {
  NO_ISOLATE_PARAMETER,
  new MethodParameter("_record", false),
  NULL,
};


static bool GetVMTimelineFlag(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  StackZone zone(thread);

  js->PrintError(kFeatureDisabled, "TODO(johnmccutchan)");
  return true;
}


static const MethodParameter* clear_vm_timeline_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool ClearVMTimeline(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  StackZone zone(thread);

  Timeline::Clear();

  PrintSuccess(js);

  return true;
}


static const MethodParameter* get_vm_timeline_params[] = {
  NO_ISOLATE_PARAMETER,
  new Int64Parameter("timeOriginMicros", false),
  new Int64Parameter("timeExtentMicros", false),
  NULL,
};


static bool GetVMTimeline(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  StackZone zone(thread);
  Timeline::ReclaimCachedBlocksFromThreads();
  TimelineEventRecorder* timeline_recorder = Timeline::recorder();
  // TODO(johnmccutchan): Return an error.
  ASSERT(timeline_recorder != NULL);
  int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  TimelineEventFilter filter(time_origin_micros, time_extent_micros);
  timeline_recorder->PrintJSON(js, &filter);
  return true;
}


static const MethodParameter* resume_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool Resume(Thread* thread, JSONStream* js) {
  const char* step_param = js->LookupParam("step");
  Isolate* isolate = thread->isolate();
  if (isolate->message_handler()->paused_on_start()) {
    // If the user is issuing a 'Over' or an 'Out' step, that is the
    // same as a regular resume request.
    if ((step_param != NULL) && (strcmp(step_param, "Into") == 0)) {
      isolate->debugger()->EnterSingleStepMode();
    }
    isolate->message_handler()->set_pause_on_start(false);
    isolate->set_last_resume_timestamp();
    if (Service::debug_stream.enabled()) {
      ServiceEvent event(isolate, ServiceEvent::kResume);
      Service::HandleEvent(&event);
    }
    PrintSuccess(js);
    return true;
  }
  if (isolate->message_handler()->paused_on_exit()) {
    isolate->message_handler()->set_pause_on_exit(false);
    // We don't send a resume event because we will be exiting.
    PrintSuccess(js);
    return true;
  }
  if (isolate->debugger()->PauseEvent() != NULL) {
    if (step_param != NULL) {
      if (strcmp(step_param, "Into") == 0) {
        isolate->debugger()->SetSingleStep();
      } else if (strcmp(step_param, "Over") == 0) {
        isolate->debugger()->SetStepOver();
      } else if (strcmp(step_param, "Out") == 0) {
        isolate->debugger()->SetStepOut();
      } else {
        PrintInvalidParamError(js, "step");
        return true;
      }
    }
    isolate->Resume();
    PrintSuccess(js);
    return true;
  }

  js->PrintError(kVMMustBePaused, NULL);
  return true;
}


static const MethodParameter* pause_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool Pause(Thread* thread, JSONStream* js) {
  // TODO(turnidge): This interrupt message could have been sent from
  // the service isolate directly, but would require some special case
  // code.  That would prevent this isolate getting double-interrupted
  // with OOB messages.
  Isolate* isolate = thread->isolate();
  isolate->SendInternalLibMessage(Isolate::kInterruptMsg,
                                  isolate->pause_capability());
  PrintSuccess(js);
  return true;
}


static const MethodParameter* get_tag_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetTagProfile(Thread* thread, JSONStream* js) {
  JSONObject miniProfile(js);
  miniProfile.AddProperty("type", "TagProfile");
  thread->isolate()->vm_tag_counters()->PrintToJSONObject(&miniProfile);
  return true;
}


static const char* const tags_enum_names[] = {
  "None",
  "UserVM",
  "UserOnly",
  "VMUser",
  "VMOnly",
  NULL,
};


static const Profile::TagOrder tags_enum_values[] = {
  Profile::kNoTags,
  Profile::kUserVM,
  Profile::kUser,
  Profile::kVMUser,
  Profile::kVM,
  Profile::kNoTags,  // Default value.
};


static const MethodParameter* get_cpu_profile_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("tags", true, tags_enum_names),
  new BoolParameter("_codeTransitionTags", false),
  new Int64Parameter("timeOriginMicros", false),
  new Int64Parameter("timeExtentMicros", false),
  NULL,
};


// TODO(johnmccutchan): Rename this to GetCpuSamples.
static bool GetCpuProfile(Thread* thread, JSONStream* js) {
  Profile::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  intptr_t extra_tags = 0;
  if (BoolParameter::Parse(js->LookupParam("_codeTransitionTags"))) {
    extra_tags |= ProfilerService::kCodeTransitionTagsBit;
  }
  int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  ProfilerService::PrintJSON(js,
                             tag_order,
                             extra_tags,
                             time_origin_micros,
                             time_extent_micros);
  return true;
}


static const MethodParameter* get_cpu_profile_timeline_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("tags", true, tags_enum_names),
  new Int64Parameter("timeOriginMicros", false),
  new Int64Parameter("timeExtentMicros", false),
  NULL,
};


static bool GetCpuProfileTimeline(Thread* thread, JSONStream* js) {
  Profile::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  int64_t time_origin_micros =
      UIntParameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      UIntParameter::Parse(js->LookupParam("timeExtentMicros"));
  ProfilerService::PrintTimelineJSON(js,
                                     tag_order,
                                     time_origin_micros,
                                     time_extent_micros);
  return true;
}


static const MethodParameter* get_allocation_samples_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("tags", true, tags_enum_names),
  new IdParameter("classId", false),
  new Int64Parameter("timeOriginMicros", false),
  new Int64Parameter("timeExtentMicros", false),
  NULL,
};


static bool GetAllocationSamples(Thread* thread, JSONStream* js) {
  Profile::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  const char* class_id = js->LookupParam("classId");
  intptr_t cid = -1;
  GetPrefixedIntegerId(class_id, "classes/", &cid);
  Isolate* isolate = thread->isolate();
  if (IsValidClassId(isolate, cid)) {
    const Class& cls = Class::Handle(GetClassForId(isolate, cid));
    ProfilerService::PrintAllocationJSON(js,
                                         tag_order,
                                         cls,
                                         time_origin_micros,
                                         time_extent_micros);
  } else {
    PrintInvalidParamError(js, "classId");
  }
  return true;
}


static const MethodParameter* clear_cpu_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool ClearCpuProfile(Thread* thread, JSONStream* js) {
  ProfilerService::ClearSamples();
  PrintSuccess(js);
  return true;
}


static const MethodParameter* get_allocation_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetAllocationProfile(Thread* thread, JSONStream* js) {
  bool should_reset_accumulator = false;
  bool should_collect = false;
  if (js->HasParam("reset")) {
    if (js->ParamIs("reset", "true")) {
      should_reset_accumulator = true;
    } else {
      PrintInvalidParamError(js, "reset");
      return true;
    }
  }
  if (js->HasParam("gc")) {
    if (js->ParamIs("gc", "full")) {
      should_collect = true;
    } else {
      PrintInvalidParamError(js, "gc");
      return true;
    }
  }
  Isolate* isolate = thread->isolate();
  if (should_reset_accumulator) {
    isolate->UpdateLastAllocationProfileAccumulatorResetTimestamp();
    isolate->class_table()->ResetAllocationAccumulators();
  }
  if (should_collect) {
    isolate->UpdateLastAllocationProfileGCTimestamp();
    isolate->heap()->CollectAllGarbage();
  }
  isolate->class_table()->AllocationProfilePrintJSON(js);
  return true;
}


static const MethodParameter* get_heap_map_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetHeapMap(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  isolate->heap()->PrintHeapMapToJSONStream(isolate, js);
  return true;
}


static const MethodParameter* request_heap_snapshot_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool RequestHeapSnapshot(Thread* thread, JSONStream* js) {
  if (Service::graph_stream.enabled()) {
    Service::SendGraphEvent(thread);
  }
  // TODO(koda): Provide some id that ties this request to async response(s).
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "OK");
  return true;
}


void Service::SendGraphEvent(Thread* thread) {
  uint8_t* buffer = NULL;
  WriteStream stream(&buffer, &allocator, 1 * MB);
  ObjectGraph graph(thread);
  intptr_t node_count = graph.Serialize(&stream);

  // Chrome crashes receiving a single tens-of-megabytes blob, so send the
  // snapshot in megabyte-sized chunks instead.
  const intptr_t kChunkSize = 1 * MB;
  intptr_t num_chunks =
      (stream.bytes_written() + (kChunkSize - 1)) / kChunkSize;
  for (intptr_t i = 0; i < num_chunks; i++) {
    JSONStream js;
    {
      JSONObject jsobj(&js);
      jsobj.AddProperty("jsonrpc", "2.0");
      jsobj.AddProperty("method", "streamNotify");
      {
        JSONObject params(&jsobj, "params");
        params.AddProperty("streamId", graph_stream.id());
        {
          JSONObject event(&params, "event");
          event.AddProperty("type", "Event");
          event.AddProperty("kind", "_Graph");
          event.AddProperty("isolate", thread->isolate());
          event.AddPropertyTimeMillis("timestamp", OS::GetCurrentTimeMillis());

          event.AddProperty("chunkIndex", i);
          event.AddProperty("chunkCount", num_chunks);
          event.AddProperty("nodeCount", node_count);
        }
      }
    }

    const String& message = String::Handle(String::New(js.ToCString()));

    uint8_t* chunk_start = buffer + (i * kChunkSize);
    intptr_t chunk_size = (i + 1 == num_chunks)
        ? stream.bytes_written() - (i * kChunkSize)
        : kChunkSize;

    SendEventWithData(graph_stream.id(), "_Graph", message,
                      chunk_start, chunk_size);
  }
}


void Service::SendInspectEvent(Isolate* isolate, const Object& inspectee) {
  if (!Service::debug_stream.enabled()) {
    return;
  }
  ServiceEvent event(isolate, ServiceEvent::kInspect);
  event.set_inspectee(&inspectee);
  Service::HandleEvent(&event);
}


void Service::SendEmbedderEvent(Isolate* isolate,
                                const char* stream_id,
                                const char* event_kind,
                                const uint8_t* bytes,
                                intptr_t bytes_len) {
  if (!Service::debug_stream.enabled()) {
    return;
  }
  ServiceEvent event(isolate, ServiceEvent::kEmbedder);
  event.set_embedder_kind(event_kind);
  event.set_embedder_stream_id(stream_id);
  event.set_bytes(bytes, bytes_len);
  Service::HandleEvent(&event);
}


void Service::SendLogEvent(Isolate* isolate,
                           int64_t sequence_number,
                           int64_t timestamp,
                           intptr_t level,
                           const String& name,
                           const String& message,
                           const Instance& zone,
                           const Object& error,
                           const Instance& stack_trace) {
  if (!Service::logging_stream.enabled()) {
    return;
  }
  ServiceEvent::LogRecord log_record;
  log_record.sequence_number = sequence_number;
  log_record.timestamp = timestamp;
  log_record.level = level;
  log_record.name = &name;
  log_record.message = &message;
  log_record.zone = &zone;
  log_record.error = &error;
  log_record.stack_trace = &stack_trace;
  ServiceEvent event(isolate, ServiceEvent::kLogging);
  event.set_log_record(log_record);
  Service::HandleEvent(&event);
}


void Service::SendExtensionEvent(Isolate* isolate,
                                 const String& event_kind,
                                 const String& event_data) {
  if (!Service::extension_stream.enabled()) {
    return;
  }
  ServiceEvent::ExtensionEvent extension_event;
  extension_event.event_kind = &event_kind;
  extension_event.event_data = &event_data;
  ServiceEvent event(isolate, ServiceEvent::kExtension);
  event.set_extension_event(extension_event);
  Service::HandleEvent(&event);
}


class ContainsAddressVisitor : public FindObjectVisitor {
 public:
  ContainsAddressVisitor(Isolate* isolate, uword addr)
      : FindObjectVisitor(isolate), addr_(addr) { }
  virtual ~ContainsAddressVisitor() { }

  virtual uword filter_addr() const { return addr_; }

  virtual bool FindObject(RawObject* obj) const {
    // Free list elements are not real objects, so skip them.
    if (obj->IsFreeListElement()) {
      return false;
    }
    uword obj_begin = RawObject::ToAddr(obj);
    uword obj_end = obj_begin + obj->Size();
    return obj_begin <= addr_ && addr_ < obj_end;
  }
 private:
  uword addr_;
};


static const MethodParameter* get_object_by_address_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static RawObject* GetObjectHelper(Thread* thread, uword addr) {
  Object& object = Object::Handle(thread->zone());

  {
    NoSafepointScope no_safepoint;
    Isolate* isolate = thread->isolate();
    ContainsAddressVisitor visitor(isolate, addr);
    object = isolate->heap()->FindObject(&visitor);
  }

  if (!object.IsNull()) {
    return object.raw();
  }

  {
    NoSafepointScope no_safepoint;
    ContainsAddressVisitor visitor(Dart::vm_isolate(), addr);
    object = Dart::vm_isolate()->heap()->FindObject(&visitor);
  }

  return object.raw();
}


static bool GetObjectByAddress(Thread* thread, JSONStream* js) {
  const char* addr_str = js->LookupParam("address");
  if (addr_str == NULL) {
    PrintMissingParamError(js, "address");
    return true;
  }

  // Handle heap objects.
  uword addr = 0;
  if (!GetUnsignedIntegerId(addr_str, &addr, 16)) {
    PrintInvalidParamError(js, "address");
    return true;
  }
  bool ref = js->HasParam("ref") && js->ParamIs("ref", "true");
  const Object& obj = Object::Handle(thread->zone(),
      GetObjectHelper(thread, addr));
  if (obj.IsNull()) {
    PrintSentinel(js, kFreeSentinel);
  } else {
    obj.PrintJSON(js, ref);
  }
  return true;
}


static const MethodParameter* get_ports_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetPorts(Thread* thread, JSONStream* js) {
  MessageHandler* message_handler = thread->isolate()->message_handler();
  PortMap::PrintPortsForMessageHandler(message_handler, js);
  return true;
}


static bool RespondWithMalformedJson(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("a", "a");
  JSONObject jsobj1(js);
  jsobj1.AddProperty("a", "a");
  JSONObject jsobj2(js);
  jsobj2.AddProperty("a", "a");
  JSONObject jsobj3(js);
  jsobj3.AddProperty("a", "a");
  return true;
}


static bool RespondWithMalformedObject(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("bart", "simpson");
  return true;
}


static const MethodParameter* get_object_params[] = {
  ISOLATE_PARAMETER,
  new UIntParameter("offset", false),
  new UIntParameter("count", false),
  NULL,
};


static bool GetObject(Thread* thread, JSONStream* js) {
  const char* id = js->LookupParam("objectId");
  if (id == NULL) {
    PrintMissingParamError(js, "objectId");
    return true;
  }
  if (js->HasParam("offset")) {
    intptr_t value = UIntParameter::Parse(js->LookupParam("offset"));
    if (value < 0) {
      PrintInvalidParamError(js, "offset");
      return true;
    }
    js->set_offset(value);
  }
  if (js->HasParam("count")) {
    intptr_t value = UIntParameter::Parse(js->LookupParam("count"));
    if (value < 0) {
      PrintInvalidParamError(js, "count");
      return true;
    }
    js->set_count(value);
  }

  // Handle heap objects.
  ObjectIdRing::LookupResult lookup_result;
  const Object& obj =
      Object::Handle(LookupHeapObject(thread, id, &lookup_result));
  if (obj.raw() != Object::sentinel().raw()) {
    // We found a heap object for this id.  Return it.
    obj.PrintJSON(js, false);
    return true;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return true;
  } else if (lookup_result == ObjectIdRing::kExpired) {
    PrintSentinel(js, kExpiredSentinel);
    return true;
  }

  // Handle non-heap objects.
  Breakpoint* bpt = LookupBreakpoint(thread->isolate(), id, &lookup_result);
  if (bpt != NULL) {
    bpt->PrintJSON(js);
    return true;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return true;
  }

  PrintInvalidParamError(js, "objectId");
  return true;
}


static const MethodParameter* get_class_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetClassList(Thread* thread, JSONStream* js) {
  ClassTable* table = thread->isolate()->class_table();
  JSONObject jsobj(js);
  table->PrintToJSONObject(&jsobj);
  return true;
}


static const MethodParameter* get_type_arguments_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetTypeArgumentsList(Thread* thread, JSONStream* js) {
  bool only_with_instantiations = false;
  if (js->ParamIs("onlyWithInstantiations", "true")) {
    only_with_instantiations = true;
  }
  ObjectStore* object_store = thread->isolate()->object_store();
  const Array& table = Array::Handle(object_store->canonical_type_arguments());
  ASSERT(table.Length() > 0);
  TypeArguments& type_args = TypeArguments::Handle();
  const intptr_t table_size = table.Length() - 1;
  const intptr_t table_used = Smi::Value(Smi::RawCast(table.At(table_size)));
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "TypeArgumentsList");
  jsobj.AddProperty("canonicalTypeArgumentsTableSize", table_size);
  jsobj.AddProperty("canonicalTypeArgumentsTableUsed", table_used);
  JSONArray members(&jsobj, "typeArguments");
  for (intptr_t i = 0; i < table_size; i++) {
    type_args ^= table.At(i);
    if (!type_args.IsNull()) {
      if (!only_with_instantiations || type_args.HasInstantiations()) {
        members.AddValue(type_args);
      }
    }
  }
  return true;
}


static const MethodParameter* get_version_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetVersion(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Version");
  jsobj.AddProperty("major", static_cast<intptr_t>(3));
  jsobj.AddProperty("minor", static_cast<intptr_t>(0));
  jsobj.AddProperty("_privateMajor", static_cast<intptr_t>(0));
  jsobj.AddProperty("_privateMinor", static_cast<intptr_t>(0));
  return true;
}


class ServiceIsolateVisitor : public IsolateVisitor {
 public:
  explicit ServiceIsolateVisitor(JSONArray* jsarr)
      : jsarr_(jsarr) {
  }

  virtual ~ServiceIsolateVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    if ((isolate != Dart::vm_isolate()) &&
        !ServiceIsolate::IsServiceIsolateDescendant(isolate)) {
      jsarr_->AddValue(isolate);
    }
  }

 private:
  JSONArray* jsarr_;
};


static const MethodParameter* get_vm_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


void Service::PrintJSONForVM(JSONStream* js, bool ref) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", (ref ? "@VM" : "VM"));
  jsobj.AddProperty("name", GetVMName());
  if (ref) {
    return;
  }
  Isolate* vm_isolate = Dart::vm_isolate();
  jsobj.AddProperty("architectureBits", static_cast<intptr_t>(kBitsPerWord));
  jsobj.AddProperty("targetCPU", CPU::Id());
  jsobj.AddProperty("hostCPU", HostCPUFeatures::hardware());
  jsobj.AddProperty("version", Version::String());
  jsobj.AddProperty64("pid", OS::ProcessId());
  int64_t start_time_millis = (vm_isolate->start_time() /
                               kMicrosecondsPerMillisecond);
  jsobj.AddPropertyTimeMillis("startTime", start_time_millis);
  // Construct the isolate list.
  {
    JSONArray jsarr(&jsobj, "isolates");
    ServiceIsolateVisitor visitor(&jsarr);
    Isolate::VisitIsolates(&visitor);
  }
}


static bool GetVM(Thread* thread, JSONStream* js) {
  Service::PrintJSONForVM(js, false);
  return true;
}


static const MethodParameter* restart_vm_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool RestartVM(Thread* thread, JSONStream* js) {
  Isolate::KillAllIsolates(Isolate::kVMRestartMsg);
  PrintSuccess(js);
  return true;
}


static const char* exception_pause_mode_names[] = {
  "All",
  "None",
  "Unhandled",
  NULL,
};


static Dart_ExceptionPauseInfo exception_pause_mode_values[] = {
  kPauseOnAllExceptions,
  kNoPauseOnExceptions,
  kPauseOnUnhandledExceptions,
  kInvalidExceptionPauseInfo,
};


static const MethodParameter* set_exception_pause_mode_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("mode", true, exception_pause_mode_names),
  NULL,
};


static bool SetExceptionPauseMode(Thread* thread, JSONStream* js) {
  const char* mode = js->LookupParam("mode");
  if (mode == NULL) {
    PrintMissingParamError(js, "mode");
    return true;
  }
  Dart_ExceptionPauseInfo info =
      EnumMapper(mode, exception_pause_mode_names, exception_pause_mode_values);
  if (info == kInvalidExceptionPauseInfo) {
    PrintInvalidParamError(js, "mode");
    return true;
  }
  Isolate* isolate = thread->isolate();
  isolate->debugger()->SetExceptionPauseInfo(info);
  if (Service::debug_stream.enabled()) {
    ServiceEvent event(isolate, ServiceEvent::kDebuggerSettingsUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
  return true;
}


static const MethodParameter* get_flag_list_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetFlagList(Thread* thread, JSONStream* js) {
  Flags::PrintJSON(js);
  return true;
}


static const MethodParameter* set_flags_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool SetFlag(Thread* thread, JSONStream* js) {
  const char* flag_name = js->LookupParam("name");
  if (flag_name == NULL) {
    PrintMissingParamError(js, "name");
    return true;
  }
  const char* flag_value = js->LookupParam("value");
  if (flag_value == NULL) {
    PrintMissingParamError(js, "value");
    return true;
  }
  const char* error = NULL;
  if (Flags::SetFlag(flag_name, flag_value, &error)) {
    PrintSuccess(js);
    return true;
  } else {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("message", error);
    return true;
  }
}


static const MethodParameter* set_library_debuggable_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("libraryId", true),
  new BoolParameter("isDebuggable", true),
  NULL,
};


static bool SetLibraryDebuggable(Thread* thread, JSONStream* js) {
  const char* lib_id = js->LookupParam("libraryId");
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(thread, lib_id,
                                                &lookup_result));
  const bool is_debuggable =
      BoolParameter::Parse(js->LookupParam("isDebuggable"), false);
  if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    lib.set_debuggable(is_debuggable);
    PrintSuccess(js);
    return true;
  }
  PrintInvalidParamError(js, "libraryId");
  return true;
}


static const MethodParameter* set_name_params[] = {
  ISOLATE_PARAMETER,
  new MethodParameter("name", true),
  NULL,
};


static bool SetName(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  isolate->set_debugger_name(js->LookupParam("name"));
  if (Service::isolate_stream.enabled()) {
    ServiceEvent event(isolate, ServiceEvent::kIsolateUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
  return true;
}


static const MethodParameter* set_vm_name_params[] = {
  new MethodParameter("name", true),
  NULL,
};


static bool SetVMName(Thread* thread, JSONStream* js) {
  const char* name_param = js->LookupParam("name");
  free(vm_name);
  vm_name = strdup(name_param);
  if (Service::vm_stream.enabled()) {
    ServiceEvent event(NULL, ServiceEvent::kVMUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
  return true;
}


static const MethodParameter* set_trace_class_allocation_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("classId", true),
  new BoolParameter("enable", true),
  NULL,
};


static bool SetTraceClassAllocation(Thread* thread, JSONStream* js) {
  if (!thread->isolate()->compilation_allowed()) {
    js->PrintError(kFeatureDisabled,
        "Cannot trace allocation when running a precompiled program.");
    return true;
  }
  const char* class_id = js->LookupParam("classId");
  const bool enable = BoolParameter::Parse(js->LookupParam("enable"));
  intptr_t cid = -1;
  GetPrefixedIntegerId(class_id, "classes/", &cid);
  Isolate* isolate = thread->isolate();
  if (!IsValidClassId(isolate, cid)) {
    PrintInvalidParamError(js, "classId");
    return true;
  }
  const Class& cls = Class::Handle(GetClassForId(isolate, cid));
  ASSERT(!cls.IsNull());
  cls.SetTraceAllocation(enable);
  PrintSuccess(js);
  return true;
}


static const ServiceMethodDescriptor service_methods_[] = {
  { "_dumpIdZone", DumpIdZone, NULL },
  { "_echo", Echo,
    NULL },
  { "_respondWithMalformedJson", RespondWithMalformedJson,
    NULL },
  { "_respondWithMalformedObject", RespondWithMalformedObject,
    NULL },
  { "_triggerEchoEvent", TriggerEchoEvent,
    NULL },
  { "addBreakpoint", AddBreakpoint,
    add_breakpoint_params },
  { "addBreakpointWithScriptUri", AddBreakpointWithScriptUri,
    add_breakpoint_with_script_uri_params },
  { "addBreakpointAtEntry", AddBreakpointAtEntry,
    add_breakpoint_at_entry_params },
  { "_addBreakpointAtActivation", AddBreakpointAtActivation,
    add_breakpoint_at_activation_params },
  { "_clearCpuProfile", ClearCpuProfile,
    clear_cpu_profile_params },
  { "_clearVMTimeline", ClearVMTimeline,
    clear_vm_timeline_params, },
  { "evaluate", Evaluate,
    evaluate_params },
  { "evaluateInFrame", EvaluateInFrame,
    evaluate_in_frame_params },
  { "_getAllocationProfile", GetAllocationProfile,
    get_allocation_profile_params },
  { "_getAllocationSamples", GetAllocationSamples,
      get_allocation_samples_params },
  { "_getCallSiteData", GetCallSiteData,
    get_call_site_data_params },
  { "getClassList", GetClassList,
    get_class_list_params },
  { "_getCoverage", GetCoverage,
    get_coverage_params },
  { "_getCpuProfile", GetCpuProfile,
    get_cpu_profile_params },
  { "_getCpuProfileTimeline", GetCpuProfileTimeline,
    get_cpu_profile_timeline_params },
  { "getFlagList", GetFlagList,
    get_flag_list_params },
  { "_getHeapMap", GetHeapMap,
    get_heap_map_params },
  { "_getInboundReferences", GetInboundReferences,
    get_inbound_references_params },
  { "_getInstances", GetInstances,
    get_instances_params },
  { "getIsolate", GetIsolate,
    get_isolate_params },
  { "_getIsolateMetric", GetIsolateMetric,
    get_isolate_metric_params },
  { "_getIsolateMetricList", GetIsolateMetricList,
    get_isolate_metric_list_params },
  { "getObject", GetObject,
    get_object_params },
  { "_getObjectByAddress", GetObjectByAddress,
    get_object_by_address_params },
  { "_getPorts", GetPorts,
    get_ports_params },
  { "_getReachableSize", GetReachableSize,
    get_reachable_size_params },
  { "_getRetainedSize", GetRetainedSize,
    get_retained_size_params },
  { "_getRetainingPath", GetRetainingPath,
    get_retaining_path_params },
  { "getStack", GetStack,
    get_stack_params },
  { "_getTagProfile", GetTagProfile,
    get_tag_profile_params },
  { "_getTypeArgumentsList", GetTypeArgumentsList,
    get_type_arguments_list_params },
  { "getVersion", GetVersion,
    get_version_params },
  { "getVM", GetVM,
    get_vm_params },
  { "_getVMMetric", GetVMMetric,
    get_vm_metric_params },
  { "_getVMMetricList", GetVMMetricList,
    get_vm_metric_list_params },
  { "_getVMTimeline", GetVMTimeline,
    get_vm_timeline_params },
  { "_getVMTimelineFlag", GetVMTimelineFlag,
    get_vm_timeline_flag_params },
  { "pause", Pause,
    pause_params },
  { "removeBreakpoint", RemoveBreakpoint,
    remove_breakpoint_params },
  { "_restartVM", RestartVM,
    restart_vm_params },
  { "resume", Resume,
    resume_params },
  { "_requestHeapSnapshot", RequestHeapSnapshot,
    request_heap_snapshot_params },
  { "setExceptionPauseMode", SetExceptionPauseMode,
    set_exception_pause_mode_params },
  { "_setFlag", SetFlag,
    set_flags_params },
  { "setLibraryDebuggable", SetLibraryDebuggable,
    set_library_debuggable_params },
  { "setName", SetName,
    set_name_params },
  { "_setTraceClassAllocation", SetTraceClassAllocation,
    set_trace_class_allocation_params },
  { "setVMName", SetVMName,
    set_vm_name_params },
  { "_setVMTimelineFlag", SetVMTimelineFlag,
    set_vm_timeline_flag_params },
};


const ServiceMethodDescriptor* FindMethod(const char* method_name) {
  intptr_t num_methods = sizeof(service_methods_) /
                         sizeof(service_methods_[0]);
  for (intptr_t i = 0; i < num_methods; i++) {
    const ServiceMethodDescriptor& method = service_methods_[i];
    if (strcmp(method_name, method.name) == 0) {
      return &method;
    }
  }
  return NULL;
}


}  // namespace dart
