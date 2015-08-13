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

DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_pause_events);

ServiceIdZone::ServiceIdZone() {
}


ServiceIdZone::~ServiceIdZone() {
}


RingServiceIdZone::RingServiceIdZone(
    ObjectIdRing* ring, ObjectIdRing::IdPolicy policy)
        : ring_(ring),
          policy_(policy) {
  ASSERT(ring_ != NULL);
}


RingServiceIdZone::~RingServiceIdZone() {
}


char* RingServiceIdZone::GetServiceId(const Object& obj) {
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
ServiceMethodDescriptor* FindMethod(const char* method_name);


// Support for streams defined in embedders.
Dart_ServiceStreamListenCallback Service::stream_listen_callback_ = NULL;
Dart_ServiceStreamCancelCallback Service::stream_cancel_callback_ = NULL;


// These are the set of streams known to the core VM.
StreamInfo Service::isolate_stream("Isolate");
StreamInfo Service::debug_stream("Debug");
StreamInfo Service::gc_stream("GC");
StreamInfo Service::echo_stream("_Echo");
StreamInfo Service::graph_stream("_Graph");
StreamInfo Service::logging_stream("_Logging");

static StreamInfo* streams_[] = {
  &Service::isolate_stream,
  &Service::debug_stream,
  &Service::gc_stream,
  &Service::echo_stream,
  &Service::graph_stream,
  &Service::logging_stream,
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
  EnumParameter(const char* name, bool required, const char** enums)
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
  const char** enums_;
};


// If the key is not found, this function returns the last element in the
// values array. This can be used to encode the default value.
template<typename T>
T EnumMapper(const char* value, const char** enums, T* values) {
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


typedef bool (*ServiceMethodEntry)(Isolate* isolate, JSONStream* js);


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


void Service::InvokeMethod(Isolate* isolate, const Array& msg) {
  ASSERT(isolate != NULL);
  ASSERT(!msg.IsNull());
  ASSERT(msg.Length() == 6);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    Instance& reply_port = Instance::Handle(isolate);
    Instance& seq = String::Handle(isolate);
    String& method_name = String::Handle(isolate);
    Array& param_keys = Array::Handle(isolate);
    Array& param_values = Array::Handle(isolate);
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

    ServiceMethodDescriptor* method = FindMethod(c_method_name);
    if (method != NULL) {
      if (!ValidateParameters(method->parameters, &js)) {
        js.PostReply();
        return;
      }
      if (method->entry(isolate, &js)) {
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

    if (ScheduleExtensionHandler(method_name,
                                 param_keys,
                                 param_values,
                                 reply_port,
                                 seq)) {
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
  ASSERT(!ServiceIsolate::IsServiceIsolateDescendant(Isolate::Current()));
  if (!ServiceIsolate::IsRunning()) {
    return;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  HANDLESCOPE(isolate);

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
    OS::Print(
        "vm-service: Pushing event of type %s to stream %s, len %" Pd "\n",
        event_type, stream_id, len);
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
  if (ServiceIsolate::IsServiceIsolateDescendant(event->isolate())) {
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
    OS::Print(
        "vm-service: Pushing event of type %s to stream %s\n", kind, stream_id);
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


bool Service::ScheduleExtensionHandler(const String& method_name,
                                       const Array& parameter_keys,
                                       const Array& parameter_values,
                                       const Instance& reply_port,
                                       const Instance& id) {
  ASSERT(!method_name.IsNull());
  ASSERT(!parameter_keys.IsNull());
  ASSERT(!parameter_values.IsNull());
  ASSERT(!reply_port.IsNull());
  const Library& developer_lib = Library::Handle(Library::DeveloperLibrary());
  ASSERT(!developer_lib.IsNull());
  const Function& schedule_extension = Function::Handle(
      developer_lib.LookupLocalFunction(Symbols::_scheduleExtension()));
  ASSERT(!schedule_extension.IsNull());
  const Array& arguments = Array::Handle(Array::New(5));
  arguments.SetAt(0, method_name);
  arguments.SetAt(1, parameter_keys);
  arguments.SetAt(2, parameter_values);
  arguments.SetAt(3, reply_port);
  arguments.SetAt(4, id);
  return (DartEntry::InvokeFunction(schedule_extension, arguments) ==
          Object::bool_true().raw());
}


static const MethodParameter* get_isolate_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetIsolate(Isolate* isolate, JSONStream* js) {
  isolate->PrintJSON(js, false);
  return true;
}


static const MethodParameter* get_stack_params[] = {
  ISOLATE_PARAMETER,
  new BoolParameter("_full", false),
  NULL,
};


static bool GetStack(Isolate* isolate, JSONStream* js) {
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
      }
    }
  }
  const String& message = String::Handle(String::New(js.ToCString()));
  uint8_t data[] = {0, 128, 255};
  SendEventWithData(echo_stream.id(), "_Echo", message, data, sizeof(data));
}


static bool TriggerEchoEvent(Isolate* isolate, JSONStream* js) {
  if (Service::echo_stream.enabled()) {
    Service::SendEchoEvent(isolate, js->LookupParam("text"));
  }
  JSONObject jsobj(js);
  return HandleCommonEcho(&jsobj, js);
}


static bool DumpIdZone(Isolate* isolate, JSONStream* js) {
  // TODO(johnmccutchan): Respect _idZone parameter passed to RPC. For now,
  // always send the ObjectIdRing.
  //
  ObjectIdRing* ring = isolate->object_id_ring();
  ASSERT(ring != NULL);
  // When printing the ObjectIdRing, force object id reuse policy.
  RingServiceIdZone reuse_zone(ring, ObjectIdRing::kReuseId);
  js->set_id_zone(&reuse_zone);
  ring->PrintJSON(js);
  return true;
}


static bool Echo(Isolate* isolate, JSONStream* js) {
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


static RawObject* LookupObjectId(Isolate* isolate,
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
    const Integer& obj =
        Integer::Handle(isolate, Smi::New(static_cast<intptr_t>(value)));
    return obj.raw();
  } else if (strcmp(arg, "bool-true") == 0) {
    return Bool::True().raw();
  } else if (strcmp(arg, "bool-false") == 0) {
    return Bool::False().raw();
  } else if (strcmp(arg, "null") == 0) {
    return Object::null();
  }

  ObjectIdRing* ring = isolate->object_id_ring();
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

static RawObject* LookupHeapObjectClasses(Isolate* isolate,
                                          char** parts, int num_parts) {
  // Class ids look like: "classes/17"
  if (num_parts < 2) {
    return Object::sentinel().raw();
  }
  ClassTable* table = isolate->class_table();
  intptr_t id;
  if (!GetIntegerId(parts[1], &id) ||
      !table->IsValidIndex(id)) {
    return Object::sentinel().raw();
  }
  Class& cls = Class::Handle(table->At(id));
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
    Function& func = Function::Handle();
    func ^= cls.ClosureFunctionFromIndex(id);
    if (func.IsNull()) {
      return Object::sentinel().raw();
    }
    return func.raw();

  } else if (strcmp(parts[2], "fields") == 0) {
    // Field ids look like: "classes/17/fields/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().raw();
    }
    Field& field = Field::Handle(cls.FieldFromIndex(id));
    if (field.IsNull()) {
      return Object::sentinel().raw();
    }
    return field.raw();

  } else if (strcmp(parts[2], "functions") == 0) {
    // Function ids look like: "classes/17/functions/11"
    if (num_parts != 4) {
      return Object::sentinel().raw();
    }
    const char* encoded_id = parts[3];
    String& id = String::Handle(isolate, String::New(encoded_id));
    id = String::DecodeIRI(id);
    if (id.IsNull()) {
      return Object::sentinel().raw();
    }
    Function& func = Function::Handle(cls.LookupFunction(id));
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
    Function& func = Function::Handle();
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
    Function& func = Function::Handle();
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
    Type& type = Type::Handle();
    type ^= cls.CanonicalTypeFromIndex(id);
    if (type.IsNull()) {
      return Object::sentinel().raw();
    }
    return type.raw();
  }

  // Not found.
  return Object::sentinel().raw();
}


static RawObject* LookupHeapObjectTypeArguments(Isolate* isolate,
                                          char** parts, int num_parts) {
  // TypeArguments ids look like: "typearguments/17"
  if (num_parts < 2) {
    return Object::sentinel().raw();
  }
  intptr_t id;
  if (!GetIntegerId(parts[1], &id)) {
    return Object::sentinel().raw();
  }
  ObjectStore* object_store = isolate->object_store();
  const Array& table = Array::Handle(object_store->canonical_type_arguments());
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
  static const char* kCollectedPrefix = "collected-";
  static intptr_t kCollectedPrefixLen = strlen(kCollectedPrefix);
  static const char* kNativePrefix = "native-";
  static intptr_t kNativePrefixLen = strlen(kNativePrefix);
  static const char* kReusedPrefix = "reused-";
  static intptr_t kReusedPrefixLen = strlen(kReusedPrefix);
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


static RawObject* LookupHeapObject(Isolate* isolate,
                                   const char* id_original,
                                   ObjectIdRing::LookupResult* result) {
  char* id = Thread::Current()->zone()->MakeCopyOfString(id_original);

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

  if (strcmp(parts[0], "objects") == 0) {
    // Object ids look like "objects/1123"
    Object& obj = Object::Handle(isolate);
    ObjectIdRing::LookupResult lookup_result;
    obj = LookupObjectId(isolate, parts[1], &lookup_result);
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
    return LookupHeapObjectClasses(isolate, parts, num_parts);
  } else if (strcmp(parts[0], "typearguments") == 0) {
    return LookupHeapObjectTypeArguments(isolate, parts, num_parts);
  } else if (strcmp(parts[0], "code") == 0) {
    return LookupHeapObjectCode(isolate, parts, num_parts);
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


static Breakpoint* LookupBreakpoint(Isolate* isolate, const char* id) {
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
    }
    return bpt;
  }
  return NULL;
}


// Scans |isolate|'s message queue looking for a message with |id|.
// If found, the message is printed to |js| and true is returned.
// If not found, false is returned.
static bool PrintMessage(JSONStream* js, Isolate* isolate, const char* id) {
  size_t end_pos = strcspn(id, "/");
  if (end_pos == strlen(id)) {
    return false;
  }
  const char* rest = id + end_pos + 1;  // +1 for '/'.
  if (strncmp("messages", id, end_pos) == 0) {
    uword message_id = 0;
    if (GetUnsignedIntegerId(rest, &message_id, 16)) {
      MessageHandler::AcquiredQueues aq;
      isolate->message_handler()->AcquireQueues(&aq);
      Message* message = aq.queue()->FindMessageById(message_id);
      if (message == NULL) {
        // The user may try to load an expired message, so we treat
        // unrecognized ids as if they are expired.
        PrintSentinel(js, kExpiredSentinel);
        return true;
      }
      MessageSnapshotReader reader(message->data(),
                                   message->len(),
                                   isolate,
                                   Thread::Current()->zone());
      const Object& msg_obj = Object::Handle(reader.ReadObject());
      msg_obj.PrintJSON(js);
      return true;
    }
  }
  return false;
}


static bool PrintInboundReferences(Isolate* isolate,
                                   Object* target,
                                   intptr_t limit,
                                   JSONStream* js) {
  ObjectGraph graph(isolate);
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
      jselement.AddProperty("slot", "<unknown>");
      if (source.IsArray()) {
        intptr_t element_index = slot_offset.Value() -
            (Array::element_offset(0) >> kWordSizeLog2);
        jselement.AddProperty("slot", element_index);
      } else if (source.IsInstance()) {
        source_class ^= source.clazz();
        parent_field_map = source_class.OffsetToFieldMap();
        intptr_t offset = slot_offset.Value();
        if (offset > 0 && offset < parent_field_map.Length()) {
          field ^= parent_field_map.At(offset);
          jselement.AddProperty("slot", field);
        }
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


static bool GetInboundReferences(Isolate* isolate, JSONStream* js) {
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

  Object& obj = Object::Handle(isolate);
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(isolate);
    obj = LookupHeapObject(isolate, target_id, &lookup_result);
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
  return PrintInboundReferences(isolate, &obj, limit, js);
}


static bool PrintRetainingPath(Isolate* isolate,
                               Object* obj,
                               intptr_t limit,
                               JSONStream* js) {
  ObjectGraph graph(isolate);
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


static bool GetRetainingPath(Isolate* isolate, JSONStream* js) {
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

  Object& obj = Object::Handle(isolate);
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(isolate);
    obj = LookupHeapObject(isolate, target_id, &lookup_result);
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
  return PrintRetainingPath(isolate, &obj, limit, js);
}


static const MethodParameter* get_retained_size_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetRetainedSize(Isolate* isolate, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(isolate, target_id,
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
    ObjectGraph graph(isolate);
    intptr_t retained_size = graph.SizeRetainedByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  }

  ObjectGraph graph(isolate);
  intptr_t retained_size = graph.SizeRetainedByInstance(obj);
  const Object& result = Object::Handle(Integer::New(retained_size));
  result.PrintJSON(js, true);
  return true;
}


static const MethodParameter* evaluate_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool Evaluate(Isolate* isolate, JSONStream* js) {
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
  const String& expr_str = String::Handle(isolate, String::New(expr));
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(isolate, target_id,
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
    const Object& result = Object::Handle(lib.Evaluate(expr_str,
                                                       Array::empty_array(),
                                                       Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  }
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    const Object& result = Object::Handle(cls.Evaluate(expr_str,
                                                       Array::empty_array(),
                                                       Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  }
  if ((obj.IsInstance() || obj.IsNull()) &&
      !ContainsNonInstance(obj)) {
    // We don't use Instance::Cast here because it doesn't allow null.
    Instance& instance = Instance::Handle(isolate);
    instance ^= obj.raw();
    const Object& result =
        Object::Handle(instance.Evaluate(expr_str,
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


static bool EvaluateInFrame(Isolate* isolate, JSONStream* js) {
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  intptr_t framePos = UIntParameter::Parse(js->LookupParam("frameIndex"));
  if (framePos > stack->Length()) {
    PrintInvalidParamError(js, "frameIndex");
    return true;
  }
  ActivationFrame* frame = stack->FrameAt(framePos);

  const char* expr = js->LookupParam("expression");
  const String& expr_str = String::Handle(isolate, String::New(expr));

  const Object& result = Object::Handle(frame->Evaluate(expr_str));
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
    Isolate* isolate = Isolate::Current();
    REUSABLE_OBJECT_HANDLESCOPE(isolate);
    Object& obj = isolate->ObjectHandle();
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


static bool GetInstances(Isolate* isolate, JSONStream* js) {
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
      Object::Handle(LookupHeapObject(isolate, target_id, NULL));
  if (obj.raw() == Object::sentinel().raw() ||
      !obj.IsClass()) {
    PrintInvalidParamError(js, "classId");
    return true;
  }
  const Class& cls = Class::Cast(obj);
  Array& storage = Array::Handle(Array::New(limit));
  GetInstancesVisitor visitor(cls, storage);
  ObjectGraph graph(isolate);
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
      samples.AddValue(Instance::Cast(sample));
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


static bool GetHitsOrSites(Isolate* isolate, JSONStream* js, bool as_sites) {
  if (!js->HasParam("targetId")) {
    CodeCoverage::PrintJSON(isolate, js, NULL, as_sites);
    return true;
  }
  const char* target_id = js->LookupParam("targetId");
  Object& obj = Object::Handle(LookupHeapObject(isolate, target_id, NULL));
  if (obj.raw() == Object::sentinel().raw()) {
    PrintInvalidParamError(js, "targetId");
    return true;
  }
  if (obj.IsScript()) {
    ScriptCoverageFilter sf(Script::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &sf, as_sites);
    return true;
  }
  if (obj.IsLibrary()) {
    LibraryCoverageFilter lf(Library::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &lf, as_sites);
    return true;
  }
  if (obj.IsClass()) {
    ClassCoverageFilter cf(Class::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &cf, as_sites);
    return true;
  }
  if (obj.IsFunction()) {
    FunctionCoverageFilter ff(Function::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &ff, as_sites);
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


static bool GetCoverage(Isolate* isolate, JSONStream* js) {
  // TODO(rmacnak): Remove this response; it is subsumed by GetCallSiteData.
  return GetHitsOrSites(isolate, js, false);
}


static const MethodParameter* get_call_site_data_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", false),
  NULL,
};


static bool GetCallSiteData(Isolate* isolate, JSONStream* js) {
  return GetHitsOrSites(isolate, js, true);
}


static const MethodParameter* add_breakpoint_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("scriptId", true),
  new UIntParameter("line", true),
  NULL,
};


static bool AddBreakpoint(Isolate* isolate, JSONStream* js) {
  const char* line_param = js->LookupParam("line");
  intptr_t line = UIntParameter::Parse(line_param);
  const char* script_id = js->LookupParam("scriptId");
  Object& obj = Object::Handle(LookupHeapObject(isolate, script_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsScript()) {
    PrintInvalidParamError(js, "scriptId");
    return true;
  }
  const Script& script = Script::Cast(obj);
  const String& script_url = String::Handle(script.url());
  Breakpoint* bpt =
      isolate->debugger()->SetBreakpointAtLine(script_url, line);
  if (bpt == NULL) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at line '%s'",
                   js->method(), line_param);
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static const MethodParameter* add_breakpoint_at_entry_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("functionId", true),
  NULL,
};


static bool AddBreakpointAtEntry(Isolate* isolate, JSONStream* js) {
  const char* function_id = js->LookupParam("functionId");
  Object& obj = Object::Handle(LookupHeapObject(isolate, function_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsFunction()) {
    PrintInvalidParamError(js, "functionId");
    return true;
  }
  const Function& function = Function::Cast(obj);
  Breakpoint* bpt =
      isolate->debugger()->SetBreakpointAtEntry(function, false);
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


static bool AddBreakpointAtActivation(Isolate* isolate, JSONStream* js) {
  const char* object_id = js->LookupParam("objectId");
  Object& obj = Object::Handle(LookupHeapObject(isolate, object_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsInstance()) {
    PrintInvalidParamError(js, "objectId");
    return true;
  }
  const Instance& closure = Instance::Cast(obj);
  Breakpoint* bpt =
      isolate->debugger()->SetBreakpointAtActivation(closure);
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


static bool RemoveBreakpoint(Isolate* isolate, JSONStream* js) {
  if (!js->HasParam("breakpointId")) {
    PrintMissingParamError(js, "breakpointId");
    return true;
  }
  const char* bpt_id = js->LookupParam("breakpointId");
  Breakpoint* bpt = LookupBreakpoint(isolate, bpt_id);
  if (bpt == NULL) {
    PrintInvalidParamError(js, "breakpointId");
    return true;
  }
  isolate->debugger()->RemoveBreakpoint(bpt->id());
  PrintSuccess(js);
  return true;
}


static RawClass* GetMetricsClass(Isolate* isolate) {
  const Library& prof_lib =
      Library::Handle(isolate, Library::DeveloperLibrary());
  ASSERT(!prof_lib.IsNull());
  const String& metrics_cls_name =
      String::Handle(isolate, String::New("Metrics"));
  ASSERT(!metrics_cls_name.IsNull());
  const Class& metrics_cls =
      Class::Handle(isolate, prof_lib.LookupClass(metrics_cls_name));
  ASSERT(!metrics_cls.IsNull());
  return metrics_cls.raw();
}



static bool HandleNativeMetricsList(Isolate* isolate, JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "MetricList");
  {
    JSONArray metrics(&obj, "metrics");
    Metric* current = isolate->metrics_list_head();
    while (current != NULL) {
      metrics.AddValue(current);
      current = current->next();
    }
  }
  return true;
}


static bool HandleNativeMetric(Isolate* isolate,
                                JSONStream* js,
                                const char* id) {
  Metric* current = isolate->metrics_list_head();
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


static bool HandleDartMetricsList(Isolate* isolate, JSONStream* js) {
  const Class& metrics_cls = Class::Handle(isolate, GetMetricsClass(isolate));
  const String& print_metrics_name =
      String::Handle(String::New("_printMetrics"));
  ASSERT(!print_metrics_name.IsNull());
  const Function& print_metrics = Function::Handle(
      isolate,
      metrics_cls.LookupStaticFunctionAllowPrivate(print_metrics_name));
  ASSERT(!print_metrics.IsNull());
  const Array& args = Object::empty_array();
  const Object& result =
      Object::Handle(isolate, DartEntry::InvokeFunction(print_metrics, args));
  ASSERT(!result.IsNull());
  ASSERT(result.IsString());
  TextBuffer* buffer = js->buffer();
  buffer->AddString(String::Cast(result).ToCString());
  return true;
}


static bool HandleDartMetric(Isolate* isolate, JSONStream* js, const char* id) {
  const Class& metrics_cls = Class::Handle(isolate, GetMetricsClass(isolate));
  const String& print_metric_name =
      String::Handle(String::New("_printMetric"));
  ASSERT(!print_metric_name.IsNull());
  const Function& print_metric = Function::Handle(
      isolate,
      metrics_cls.LookupStaticFunctionAllowPrivate(print_metric_name));
  ASSERT(!print_metric.IsNull());
  const String& arg0 = String::Handle(String::New(id));
  ASSERT(!arg0.IsNull());
  const Array& args = Array::Handle(Array::New(1));
  ASSERT(!args.IsNull());
  args.SetAt(0, arg0);
  const Object& result =
      Object::Handle(isolate, DartEntry::InvokeFunction(print_metric, args));
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


static bool GetIsolateMetricList(Isolate* isolate, JSONStream* js) {
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
    return HandleNativeMetricsList(isolate, js);
  }
  return HandleDartMetricsList(isolate, js);
}


static const MethodParameter* get_isolate_metric_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetIsolateMetric(Isolate* isolate, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == NULL) {
    PrintMissingParamError(js, "metricId");
    return true;
  }
  // Verify id begins with "metrics/".
  static const char* kMetricIdPrefix = "metrics/";
  static intptr_t kMetricIdPrefixLen = strlen(kMetricIdPrefix);
  if (strncmp(metric_id, kMetricIdPrefix, kMetricIdPrefixLen) != 0) {
    PrintInvalidParamError(js, "metricId");
    return true;
  }
  // Check if id begins with "metrics/native/".
  static const char* kNativeMetricIdPrefix = "metrics/native/";
  static intptr_t kNativeMetricIdPrefixLen = strlen(kNativeMetricIdPrefix);
  const bool native_metric =
      strncmp(metric_id, kNativeMetricIdPrefix, kNativeMetricIdPrefixLen) == 0;
  if (native_metric) {
    const char* id = metric_id + kNativeMetricIdPrefixLen;
    return HandleNativeMetric(isolate, js, id);
  }
  const char* id = metric_id + kMetricIdPrefixLen;
  return HandleDartMetric(isolate, js, id);
}


static const MethodParameter* get_vm_metric_list_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetVMMetricList(Isolate* isolate, JSONStream* js) {
  return false;
}


static const MethodParameter* get_vm_metric_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool GetVMMetric(Isolate* isolate, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == NULL) {
    PrintMissingParamError(js, "metricId");
  }
  return false;
}


static const MethodParameter* resume_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool Resume(Isolate* isolate, JSONStream* js) {
  const char* step_param = js->LookupParam("step");
  if (isolate->message_handler()->paused_on_start()) {
    // If the user is issuing a 'Over' or an 'Out' step, that is the
    // same as a regular resume request.
    if ((step_param != NULL) && (strcmp(step_param, "Into") == 0)) {
      isolate->debugger()->EnterSingleStepMode();
    }
    isolate->message_handler()->set_pause_on_start(false);
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


static bool Pause(Isolate* isolate, JSONStream* js) {
  // TODO(turnidge): Don't double-interrupt the isolate here.
  isolate->ScheduleInterrupts(Isolate::kApiInterrupt);
  PrintSuccess(js);
  return true;
}


static const MethodParameter* get_tag_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetTagProfile(Isolate* isolate, JSONStream* js) {
  JSONObject miniProfile(js);
  miniProfile.AddProperty("type", "TagProfile");
  isolate->vm_tag_counters()->PrintToJSONObject(&miniProfile);
  return true;
}


static const char* tags_enum_names[] = {
  "None",
  "UserVM",
  "UserOnly",
  "VMUser",
  "VMOnly",
  NULL,
};


static Profile::TagOrder tags_enum_values[] = {
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
  NULL,
};


// TODO(johnmccutchan): Rename this to GetCpuSamples.
static bool GetCpuProfile(Isolate* isolate, JSONStream* js) {
  Profile::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  intptr_t extra_tags = 0;
  if (BoolParameter::Parse(js->LookupParam("_codeTransitionTags"))) {
    extra_tags |= ProfilerService::kCodeTransitionTagsBit;
  }
  ProfilerService::PrintJSON(js, tag_order, extra_tags);
  return true;
}


static const MethodParameter* get_allocation_samples_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("tags", true, tags_enum_names),
  new IdParameter("classId", false),
  NULL,
};


static bool GetAllocationSamples(Isolate* isolate, JSONStream* js) {
  Profile::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  const char* class_id = js->LookupParam("classId");
  intptr_t cid = -1;
  GetPrefixedIntegerId(class_id, "classes/", &cid);
  if (IsValidClassId(isolate, cid)) {
    const Class& cls = Class::Handle(GetClassForId(isolate, cid));
    ProfilerService::PrintAllocationJSON(js, tag_order, cls);
  } else {
    PrintInvalidParamError(js, "classId");
  }
  return true;
}


static const MethodParameter* clear_cpu_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool ClearCpuProfile(Isolate* isolate, JSONStream* js) {
  ProfilerService::ClearSamples();
  PrintSuccess(js);
  return true;
}


static const MethodParameter* get_allocation_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetAllocationProfile(Isolate* isolate, JSONStream* js) {
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


static bool GetHeapMap(Isolate* isolate, JSONStream* js) {
  isolate->heap()->PrintHeapMapToJSONStream(isolate, js);
  return true;
}


static const MethodParameter* request_heap_snapshot_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool RequestHeapSnapshot(Isolate* isolate, JSONStream* js) {
  if (Service::graph_stream.enabled()) {
    Service::SendGraphEvent(isolate);
  }
  // TODO(koda): Provide some id that ties this request to async response(s).
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "OK");
  return true;
}


void Service::SendGraphEvent(Isolate* isolate) {
  uint8_t* buffer = NULL;
  WriteStream stream(&buffer, &allocator, 1 * MB);
  ObjectGraph graph(isolate);
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
          event.AddProperty("isolate", isolate);

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


static RawObject* GetObjectHelper(Isolate* isolate, uword addr) {
  Object& object = Object::Handle(isolate);

  {
    NoSafepointScope no_safepoint;
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


static bool GetObjectByAddress(Isolate* isolate, JSONStream* js) {
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
  const Object& obj = Object::Handle(isolate, GetObjectHelper(isolate, addr));
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


static bool GetPorts(Isolate* isolate, JSONStream* js) {
  MessageHandler* message_handler = isolate->message_handler();
  PortMap::PrintPortsForMessageHandler(message_handler, js);
  return true;
}


static bool RespondWithMalformedJson(Isolate* isolate,
                                      JSONStream* js) {
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


static bool RespondWithMalformedObject(Isolate* isolate,
                                        JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("bart", "simpson");
  return true;
}


static const MethodParameter* get_object_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetObject(Isolate* isolate, JSONStream* js) {
  const char* id = js->LookupParam("objectId");
  if (id == NULL) {
    PrintMissingParamError(js, "objectId");
    return true;
  }

  // Handle heap objects.
  ObjectIdRing::LookupResult lookup_result;
  const Object& obj =
      Object::Handle(LookupHeapObject(isolate, id, &lookup_result));
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
  Breakpoint* bpt = LookupBreakpoint(isolate, id);
  if (bpt != NULL) {
    bpt->PrintJSON(js);
    return true;
  }

  if (PrintMessage(js, isolate, id)) {
    return true;
  }

  PrintInvalidParamError(js, "objectId");
  return true;
}


static const MethodParameter* get_class_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetClassList(Isolate* isolate, JSONStream* js) {
  ClassTable* table = isolate->class_table();
  JSONObject jsobj(js);
  table->PrintToJSONObject(&jsobj);
  return true;
}


static const MethodParameter* get_type_arguments_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool GetTypeArgumentsList(Isolate* isolate, JSONStream* js) {
  bool only_with_instantiations = false;
  if (js->ParamIs("onlyWithInstantiations", "true")) {
    only_with_instantiations = true;
  }
  ObjectStore* object_store = isolate->object_store();
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


static bool GetVersion(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Version");
  jsobj.AddProperty("major", static_cast<intptr_t>(2));
  jsobj.AddProperty("minor", static_cast<intptr_t>(1));
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


static bool GetVM(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "VM");
  jsobj.AddProperty("architectureBits", static_cast<intptr_t>(kBitsPerWord));
  jsobj.AddProperty("targetCPU", CPU::Id());
  jsobj.AddProperty("hostCPU", HostCPUFeatures::hardware());
  jsobj.AddProperty("version", Version::String());
  // Send pid as a string because it allows us to avoid any issues with
  // pids > 53-bits (when consumed by JavaScript).
  // TODO(johnmccutchan): Codify how integers are sent across the service.
  jsobj.AddPropertyF("pid", "%" Pd "", OS::ProcessId());
  jsobj.AddProperty("_assertsEnabled", isolate->flags().asserts());
  jsobj.AddProperty("_typeChecksEnabled", isolate->flags().type_checks());
  int64_t start_time_millis = (Dart::vm_isolate()->start_time() /
                               kMicrosecondsPerMillisecond);
  jsobj.AddProperty64("startTime", start_time_millis);
  // Construct the isolate list.
  {
    JSONArray jsarr(&jsobj, "isolates");
    ServiceIsolateVisitor visitor(&jsarr);
    Isolate::VisitIsolates(&visitor);
  }
  return true;
}


static const MethodParameter* set_exception_pause_info_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool SetExceptionPauseInfo(Isolate* isolate, JSONStream* js) {
  const char* exceptions = js->LookupParam("exceptions");
  if (exceptions == NULL) {
    PrintMissingParamError(js, "exceptions");
    return true;
  }

  Dart_ExceptionPauseInfo info = kNoPauseOnExceptions;
  if (strcmp(exceptions, "none") == 0) {
    info = kNoPauseOnExceptions;
  } else if (strcmp(exceptions, "all") == 0) {
    info = kPauseOnAllExceptions;
  } else if (strcmp(exceptions, "unhandled") == 0) {
    info = kPauseOnUnhandledExceptions;
  } else {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("message", "illegal value for parameter 'exceptions'");
    return true;
  }

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


static bool GetFlagList(Isolate* isolate, JSONStream* js) {
  Flags::PrintJSON(js);
  return true;
}


static const MethodParameter* set_flags_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool SetFlag(Isolate* isolate, JSONStream* js) {
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


static bool SetLibraryDebuggable(Isolate* isolate, JSONStream* js) {
  const char* lib_id = js->LookupParam("libraryId");
  ObjectIdRing::LookupResult lookup_result;
  Object& obj = Object::Handle(LookupHeapObject(isolate, lib_id,
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


static bool SetName(Isolate* isolate, JSONStream* js) {
  isolate->set_debugger_name(js->LookupParam("name"));
  if (Service::isolate_stream.enabled()) {
    ServiceEvent event(isolate, ServiceEvent::kIsolateUpdate);
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


static bool SetTraceClassAllocation(Isolate* isolate, JSONStream* js) {
  const char* class_id = js->LookupParam("classId");
  const bool enable = BoolParameter::Parse(js->LookupParam("enable"));
  intptr_t cid = -1;
  GetPrefixedIntegerId(class_id, "classes/", &cid);
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


static ServiceMethodDescriptor service_methods_[] = {
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
  { "addBreakpointAtEntry", AddBreakpointAtEntry,
    add_breakpoint_at_entry_params },
  { "_addBreakpointAtActivation", AddBreakpointAtActivation,
    add_breakpoint_at_activation_params },
  { "_clearCpuProfile", ClearCpuProfile,
    clear_cpu_profile_params },
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
  { "pause", Pause,
    pause_params },
  { "removeBreakpoint", RemoveBreakpoint,
    remove_breakpoint_params },
  { "resume", Resume,
    resume_params },
  { "_requestHeapSnapshot", RequestHeapSnapshot,
    request_heap_snapshot_params },
  { "_setExceptionPauseInfo", SetExceptionPauseInfo,
    set_exception_pause_info_params },
  { "_setFlag", SetFlag,
    set_flags_params },
  { "setLibraryDebuggable", SetLibraryDebuggable,
    set_library_debuggable_params },
  { "setName", SetName,
    set_name_params },
  { "_setTraceClassAllocation", SetTraceClassAllocation,
    set_trace_class_allocation_params },
};


ServiceMethodDescriptor* FindMethod(const char* method_name) {
  intptr_t num_methods = sizeof(service_methods_) /
                         sizeof(service_methods_[0]);
  for (intptr_t i = 0; i < num_methods; i++) {
    ServiceMethodDescriptor& method = service_methods_[i];
    if (strcmp(method_name, method.name) == 0) {
      return &method;
    }
  }
  return NULL;
}


}  // namespace dart
