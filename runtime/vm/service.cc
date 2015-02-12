// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service.h"

#include "include/dart_api.h"
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
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/unicode.h"
#include "vm/version.h"

namespace dart {

DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_pause_events);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, enable_asserts);

// TODO(johnmccutchan): Unify embedder service handler lists and their APIs.
EmbedderServiceHandler* Service::isolate_service_handler_head_ = NULL;
EmbedderServiceHandler* Service::root_service_handler_head_ = NULL;
uint32_t Service::event_mask_ = 0;
struct ServiceMethodDescriptor;
ServiceMethodDescriptor* FindMethod(const char* method_name);

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}

static void PrintRequest(const JSONObject& obj, JSONStream* js) {
  JSONObject jsobj(&obj, "request");
  jsobj.AddProperty("method", js->method());
  {
    JSONArray jsarr(&jsobj, "param_keys");
    for (intptr_t i = 0; i < js->num_params(); i++) {
      jsarr.AddValue(js->GetParamKey(i));
    }
  }
  {
    JSONArray jsarr(&jsobj, "param_values");
    for (intptr_t i = 0; i < js->num_params(); i++) {
      jsarr.AddValue(js->GetParamValue(i));
    }
  }
}


static void PrintError(JSONStream* js,
                       const char* format, ...) {
  Isolate* isolate = Isolate::Current();

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = isolate->current_zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Error");
  jsobj.AddProperty("message", buffer);
  PrintRequest(jsobj, js);
}


static void PrintMissingParamError(JSONStream* js,
                                   const char* param) {
  PrintError(js, "%s expects the '%s' parameter",
             js->method(), param);
}


static void PrintInvalidParamError(JSONStream* js,
                                   const char* param) {
  PrintError(js, "%s: invalid '%s' parameter: %s",
             js->method(), param, js->LookupParam(param));
}


static void PrintUnrecognizedMethodError(JSONStream* js) {
  PrintError(js, "unrecognized method: %s", js->method());
}


static void PrintErrorWithKind(JSONStream* js,
                               const char* kind,
                               const char* format, ...) {
  Isolate* isolate = Isolate::Current();

  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  char* buffer = isolate->current_zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Error");
  jsobj.AddProperty("id", "");
  jsobj.AddProperty("kind", kind);
  jsobj.AddProperty("message", buffer);
  PrintRequest(jsobj, js);
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

  static bool Interpret(const char* value) {
    return strcmp("true", value) == 0;
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
    if (!parameter->Validate(value)) {
      PrintInvalidParamError(js, name);
      return false;
    }
  }
  return true;
}


void Service::InvokeMethod(Isolate* isolate, const Array& msg) {
  ASSERT(isolate != NULL);
  ASSERT(!msg.IsNull());
  ASSERT(msg.Length() == 5);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    Instance& reply_port = Instance::Handle(isolate);
    String& method_name = String::Handle(isolate);
    Array& param_keys = Array::Handle(isolate);
    Array& param_values = Array::Handle(isolate);
    reply_port ^= msg.At(1);
    method_name ^= msg.At(2);
    param_keys ^= msg.At(3);
    param_values ^= msg.At(4);

    ASSERT(!method_name.IsNull());
    ASSERT(!param_keys.IsNull());
    ASSERT(!param_values.IsNull());
    ASSERT(param_keys.Length() == param_values.Length());

    if (!reply_port.IsSendPort()) {
      FATAL("SendPort expected.");
    }

    JSONStream js;
    js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(),
             method_name, param_keys, param_values);

    const char* c_method_name = method_name.ToCString();

    ServiceMethodDescriptor* method = FindMethod(c_method_name);
    if (method != NULL) {
      if (!ValidateParameters(method->parameters, &js)) {
        js.PostReply();
        return;
      }
      if (method->entry(isolate, &js)) {
        js.PostReply();
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


bool Service::EventMaskHas(uint32_t mask) {
  return (event_mask_ & mask) != 0;
}


bool Service::NeedsDebuggerEvents() {
  return ServiceIsolate::IsRunning() && EventMaskHas(kEventFamilyDebugMask);
}


bool Service::NeedsGCEvents() {
  return ServiceIsolate::IsRunning() && EventMaskHas(kEventFamilyGCMask);
}


void Service::SetEventMask(uint32_t mask) {
  event_mask_ = mask;
}


void Service::SendEvent(intptr_t eventId, const Object& eventMessage) {
  if (!ServiceIsolate::IsRunning()) {
    return;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  HANDLESCOPE(isolate);

  // Construct a list of the form [eventId, eventMessage].
  const Array& list = Array::Handle(Array::New(2));
  ASSERT(!list.IsNull());
  list.SetAt(0, Integer::Handle(Integer::New(eventId)));
  list.SetAt(1, eventMessage);

  // Push the event to port_.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("vm-service: Pushing event of type %" Pd ", len %" Pd "\n",
              eventId, len);
  }
  // TODO(turnidge): For now we ignore failure to send an event.  Revisit?
  PortMap::PostMessage(
      new Message(ServiceIsolate::Port(), data, len, Message::kNormalPriority));
}


void Service::SendEvent(intptr_t eventId,
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
    NoGCScope no_gc;
    meta.ToUTF8(static_cast<uint8_t*>(message.DataAddr(offset)), meta_bytes);
    offset += meta_bytes;
  }
  // TODO(koda): It would be nice to avoid this copy (requires changes to
  // MessageWriter code).
  {
    NoGCScope no_gc;
    memmove(message.DataAddr(offset), data, size);
    offset += size;
  }
  ASSERT(offset == total_bytes);
  SendEvent(eventId, message);
}


void Service::HandleGCEvent(GCEvent* event) {
  JSONStream js;
  event->PrintJSON(&js);
  const String& message = String::Handle(String::New(js.ToCString()));
  SendEvent(kEventFamilyGC, message);
}


void Service::HandleDebuggerEvent(DebuggerEvent* event) {
  JSONStream js;
  event->PrintJSON(&js);
  const String& message = String::Handle(String::New(js.ToCString()));
  SendEvent(kEventFamilyDebug, message);
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
  const char* name = js->method();
  const char** keys = js->param_keys();
  const char** values = js->param_values();
  r = callback(name, keys, values, js->num_params(), handler->user_data());
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


static const MethodParameter* get_isolate_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolate(Isolate* isolate, JSONStream* js) {
  isolate->PrintJSON(js, false);
  return true;
}


static const MethodParameter* get_stack_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetStack(Isolate* isolate, JSONStream* js) {
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Stack");
  JSONArray jsarr(&jsobj, "frames");
  intptr_t num_frames = stack->Length();
  for (intptr_t i = 0; i < num_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    JSONObject jsobj(&jsarr);
    frame->PrintToJSONObject(&jsobj);
    // TODO(turnidge): Implement depth differently -- differentiate
    // inlined frames.
    jsobj.AddProperty("depth", i);
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
    jsobj.AddProperty("type", "ServiceEvent");
    jsobj.AddProperty("eventType", "_Echo");
    jsobj.AddProperty("isolate", isolate);
    if (text != NULL) {
      jsobj.AddProperty("text", text);
    }
  }
  const String& message = String::Handle(String::New(js.ToCString()));
  uint8_t data[] = {0, 128, 255};
  // TODO(koda): Add 'testing' event family.
  SendEvent(kEventFamilyDebug, message, data, sizeof(data));
}


static bool HandleIsolateTriggerEchoEvent(Isolate* isolate, JSONStream* js) {
  Service::SendEchoEvent(isolate, js->LookupParam("text"));
  JSONObject jsobj(js);
  return HandleCommonEcho(&jsobj, js);
}


static bool HandleIsolateEcho(Isolate* isolate, JSONStream* js) {
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
  } else if (strcmp(arg, "not-initialized") == 0) {
    return Object::sentinel().raw();
  } else if (strcmp(arg, "being-initialized") == 0) {
    return Object::transition_sentinel().raw();
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
  char* id = isolate->current_zone()->MakeCopyOfString(id_original);

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


static void PrintSentinel(JSONStream* js,
                          const char* id,
                          const char* preview) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Sentinel");
  jsobj.AddProperty("id", id);
  jsobj.AddProperty("valueAsString", preview);
}


static SourceBreakpoint* LookupBreakpoint(Isolate* isolate, const char* id) {
  size_t end_pos = strcspn(id, "/");
  const char* rest = NULL;
  if (end_pos < strlen(id)) {
    rest = id + end_pos + 1;  // +1 for '/'.
  }
  if (strncmp("breakpoints", id, end_pos) == 0) {
    if (rest == NULL) {
      return NULL;
    }
    intptr_t bpt_id = 0;
    SourceBreakpoint* bpt = NULL;
    if (GetIntegerId(rest, &bpt_id)) {
      bpt = isolate->debugger()->GetBreakpointById(bpt_id);
    }
    return bpt;
  }
  return NULL;
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


static bool HandleIsolateGetInboundReferences(Isolate* isolate,
                                              JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (target_id == NULL) {
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
      PrintErrorWithKind(
          js, "InboundReferencesCollected",
          "attempt to find a retaining path for a collected object\n");
      return true;
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "InboundReferencesExpired",
          "attempt to find a retaining path for an expired object\n");
      return true;
    }
    PrintInvalidParamError(js, "targetId");
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
  Object& parent = Object::Handle();
  Smi& offset_from_parent = Smi::Handle();
  Class& parent_class = Class::Handle();
  Array& parent_field_map = Array::Handle();
  Field& field = Field::Handle();
  limit = Utils::Minimum(limit, length);
  for (intptr_t i = 0; i < limit; ++i) {
    JSONObject jselement(&elements);
    element = path.At(i * 2);
    jselement.AddProperty("index", i);
    jselement.AddProperty("value", element);
    // Interpret the word offset from parent as list index or instance field.
    // TODO(koda): User-friendly interpretation for map entries.
    offset_from_parent ^= path.At((i * 2) + 1);
    int parent_i = i + 1;
    if (parent_i < limit) {
      parent = path.At(parent_i * 2);
      if (parent.IsArray()) {
        intptr_t element_index = offset_from_parent.Value() -
            (Array::element_offset(0) >> kWordSizeLog2);
        jselement.AddProperty("parentListIndex", element_index);
      } else if (parent.IsInstance()) {
        parent_class ^= parent.clazz();
        parent_field_map = parent_class.OffsetToFieldMap();
        intptr_t offset = offset_from_parent.Value();
        if (offset > 0 && offset < parent_field_map.Length()) {
          field ^= parent_field_map.At(offset);
          jselement.AddProperty("parentField", field);
        }
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


static bool HandleIsolateGetRetainingPath(Isolate* isolate,
                                          JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "targetId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (target_id == NULL) {
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
      PrintErrorWithKind(
          js, "RetainingPathCollected",
          "attempt to find a retaining path for a collected object\n");
      return true;
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "RetainingPathExpired",
          "attempt to find a retaining path for an expired object\n");
      return true;
    }
    PrintInvalidParamError(js, "targetId");
    return true;
  }
  return PrintRetainingPath(isolate, &obj, limit, js);
}


static const MethodParameter* get_retained_size_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetRetainedSize(Isolate* isolate, JSONStream* js) {
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
      PrintErrorWithKind(
          js, "RetainedCollected",
          "attempt to calculate size retained by a collected object\n");
      return true;
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "RetainedExpired",
          "attempt to calculate size retained by an expired object\n");
      return true;
    }
    PrintInvalidParamError(js, "targetId");
    return true;
  }
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    ObjectGraph graph(isolate);
    intptr_t retained_size = graph.SizeRetainedByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  }
  if (obj.IsInstance() || obj.IsNull()) {
    // We don't use Instance::Cast here because it doesn't allow null.
    ObjectGraph graph(isolate);
    intptr_t retained_size = graph.SizeRetainedByInstance(obj);
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  }
  PrintError(js, "%s: Invalid 'targetId' parameter value: "
             "id '%s' does not correspond to a "
             "library, class, or instance", js->method(), target_id);
  return true;
}


static const MethodParameter* eval_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateEval(Isolate* isolate, JSONStream* js) {
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
      PrintSentinel(js, "objects/collected", "<collected>");
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, "objects/expired", "<expired>");
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
  PrintError(js, "%s: Invalid 'targetId' parameter value: "
             "id '%s' does not correspond to a "
             "library, class, or instance", js->method(), target_id);
  return true;
}


static const MethodParameter* get_call_site_data_params[] = {
  ISOLATE_PARAMETER,
  new IdParameter("targetId", true),
  NULL,
};


static bool HandleIsolateGetCallSiteData(Isolate* isolate, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  Object& obj = Object::Handle(LookupHeapObject(isolate, target_id, NULL));
  if (obj.raw() == Object::sentinel().raw()) {
    PrintInvalidParamError(js, "targetId");
    return true;
  }
  if (obj.IsFunction()) {
    const Function& func = Function::Cast(obj);
    const GrowableObjectArray& ics =
        GrowableObjectArray::Handle(func.CollectICsWithSourcePositions());
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "_CallSiteData");
    jsobj.AddProperty("function", func);
    JSONArray elements(&jsobj, "callSites");
    Smi& line = Smi::Handle();
    Smi& column = Smi::Handle();
    ICData& ic_data = ICData::Handle();
    for (intptr_t i = 0; i < ics.Length();) {
      ic_data ^= ics.At(i++);
      line ^= ics.At(i++);
      column ^= ics.At(i++);
      ic_data.PrintToJSONArray(&elements, line.Value(), column.Value());
    }
    return true;
  }
  return false;
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


static bool HandleIsolateGetInstances(Isolate* isolate, JSONStream* js) {
  const char* target_id = js->LookupParam("classId");
  if (target_id == NULL) {
    PrintMissingParamError(js, "classId");
    return true;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (target_id == NULL) {
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
  jsobj.AddProperty("id", "instance_set");
  jsobj.AddProperty("totalCount", count);
  jsobj.AddProperty("sampleCount", storage.Length());
  jsobj.AddProperty("sample", storage);
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


static const MethodParameter* get_coverage_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetCoverage(Isolate* isolate, JSONStream* js) {
  if (!js->HasParam("targetId")) {
    CodeCoverage::PrintJSON(isolate, js, NULL);
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
    CodeCoverage::PrintJSON(isolate, js, &sf);
    return true;
  }
  if (obj.IsLibrary()) {
    LibraryCoverageFilter lf(Library::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &lf);
    return true;
  }
  if (obj.IsClass()) {
    ClassCoverageFilter cf(Class::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &cf);
    return true;
  }
  if (obj.IsFunction()) {
    FunctionCoverageFilter ff(Function::Cast(obj));
    CodeCoverage::PrintJSON(isolate, js, &ff);
    return true;
  }
  PrintError(js, "%s: Invalid 'targetId' parameter value: "
             "id '%s' does not correspond to a "
             "script, library, class, or function", js->method(), target_id);
  return true;
}


static const MethodParameter* add_breakpoint_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateAddBreakpoint(Isolate* isolate, JSONStream* js) {
  if (!js->HasParam("line")) {
    PrintMissingParamError(js, "line");
    return true;
  }
  const char* line_param = js->LookupParam("line");
  intptr_t line = -1;
  if (!GetIntegerId(line_param, &line)) {
    PrintInvalidParamError(js, "line");
    return true;
  }
  const char* script_id = js->LookupParam("script");
  Object& obj = Object::Handle(LookupHeapObject(isolate, script_id, NULL));
  if (obj.raw() == Object::sentinel().raw() || !obj.IsScript()) {
    PrintInvalidParamError(js, "script");
    return true;
  }
  const Script& script = Script::Cast(obj);
  const String& script_url = String::Handle(script.url());
  SourceBreakpoint* bpt =
      isolate->debugger()->SetBreakpointAtLine(script_url, line);
  if (bpt == NULL) {
    PrintError(js, "Unable to set breakpoint at line %s", line_param);
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static const MethodParameter* remove_breakpoint_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateRemoveBreakpoint(Isolate* isolate, JSONStream* js) {
  if (!js->HasParam("breakpointId")) {
    PrintMissingParamError(js, "breakpointId");
    return true;
  }
  const char* bpt_id = js->LookupParam("breakpointId");
  SourceBreakpoint* bpt = LookupBreakpoint(isolate, bpt_id);
  if (bpt == NULL) {
    fprintf(stderr, "ERROR1");
    PrintInvalidParamError(js, "breakpointId");
    return true;
  }
  isolate->debugger()->RemoveBreakpoint(bpt->id());

  // TODO(turnidge): Consider whether the 'Success' type is proper.
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
  jsobj.AddProperty("id", "");
  return true;
}


static RawClass* GetMetricsClass(Isolate* isolate) {
  const Library& prof_lib =
      Library::Handle(isolate, Library::ProfilerLibrary());
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
  PrintError(js, "Native Metric %s not found\n", id);
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
  PrintError(js, "Dart Metric %s not found\n", id);
  return true;
}


static const MethodParameter* get_metric_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetMetricList(Isolate* isolate, JSONStream* js) {
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


static const MethodParameter* get_metric_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetMetric(Isolate* isolate, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == NULL) {
    PrintMissingParamError(js, "metricId");
    return true;
  }
  // Verify id begins with "metrics/".
  static const char* kMetricIdPrefix = "metrics/";
  static intptr_t kMetricIdPrefixLen = strlen(kMetricIdPrefix);
  if (strncmp(metric_id, kMetricIdPrefix, kMetricIdPrefixLen) != 0) {
    PrintError(js, "Metric %s not found\n", metric_id);
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


static bool HandleVMGetMetricList(Isolate* isolate, JSONStream* js) {
  return false;
}


static const MethodParameter* get_vm_metric_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool HandleVMGetMetric(Isolate* isolate, JSONStream* js) {
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


static bool HandleIsolateResume(Isolate* isolate, JSONStream* js) {
  const char* step_param = js->LookupParam("step");
  if (isolate->message_handler()->paused_on_start()) {
    isolate->message_handler()->set_pause_on_start(false);
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    {
      DebuggerEvent resumeEvent(isolate, DebuggerEvent::kIsolateResumed);
      Service::HandleDebuggerEvent(&resumeEvent);
    }
    return true;
  }
  if (isolate->message_handler()->paused_on_exit()) {
    isolate->message_handler()->set_pause_on_exit(false);
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    // We don't send a resume event because we will be exiting.
    return true;
  }
  if (isolate->debugger()->PauseEvent() != NULL) {
    if (step_param != NULL) {
      if (strcmp(step_param, "into") == 0) {
        isolate->debugger()->SetSingleStep();
      } else if (strcmp(step_param, "over") == 0) {
        isolate->debugger()->SetStepOver();
      } else if (strcmp(step_param, "out") == 0) {
        isolate->debugger()->SetStepOut();
      } else {
        PrintInvalidParamError(js, "step");
        return true;
      }
    }
    isolate->Resume();
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    return true;
  }

  PrintError(js, "VM was not paused");
  return true;
}


static const MethodParameter* get_breakpoints_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetBreakpoints(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "BreakpointList");
  JSONArray jsarr(&jsobj, "breakpoints");
  isolate->debugger()->PrintBreakpointsToJSONArray(&jsarr);
  return true;
}


static const MethodParameter* pause_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolatePause(Isolate* isolate, JSONStream* js) {
  // TODO(turnidge): Don't double-interrupt the isolate here.
  isolate->ScheduleInterrupts(Isolate::kApiInterrupt);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
  jsobj.AddProperty("id", "");
  return true;
}


static const MethodParameter* get_tag_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetTagProfile(Isolate* isolate, JSONStream* js) {
  JSONObject miniProfile(js);
  miniProfile.AddProperty("type", "TagProfile");
  miniProfile.AddProperty("id", "profile/tag");
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


static ProfilerService::TagOrder tags_enum_values[] = {
  ProfilerService::kNoTags,
  ProfilerService::kUserVM,
  ProfilerService::kUser,
  ProfilerService::kVMUser,
  ProfilerService::kVM,
  ProfilerService::kNoTags,  // Default value.
};


static const MethodParameter* get_cpu_profile_params[] = {
  ISOLATE_PARAMETER,
  new EnumParameter("tags", true, tags_enum_names),
  NULL,
};


static bool HandleIsolateGetCpuProfile(Isolate* isolate, JSONStream* js) {
  ProfilerService::TagOrder tag_order =
      EnumMapper(js->LookupParam("tags"), tags_enum_names, tags_enum_values);
  ProfilerService::PrintJSON(js, tag_order);
  return true;
}


static const MethodParameter* get_allocation_profile_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetAllocationProfile(Isolate* isolate,
                                              JSONStream* js) {
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


static bool HandleIsolateGetHeapMap(Isolate* isolate, JSONStream* js) {
  isolate->heap()->PrintHeapMapToJSONStream(isolate, js);
  return true;
}


static const MethodParameter* request_heap_snapshot_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateRequestHeapSnapshot(Isolate* isolate, JSONStream* js) {
  Service::SendGraphEvent(isolate);
  // TODO(koda): Provide some id that ties this request to async response(s).
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "OK");
  jsobj.AddProperty("id", "ok");
  return true;
}


void Service::SendGraphEvent(Isolate* isolate) {
  uint8_t* buffer = NULL;
  WriteStream stream(&buffer, &allocator, 1 * MB);
  ObjectGraph graph(isolate);
  graph.Serialize(&stream);
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("type", "ServiceEvent");
    jsobj.AddPropertyF("id", "_graphEvent");
    jsobj.AddProperty("eventType", "_Graph");
    jsobj.AddProperty("isolate", isolate);
  }
  const String& message = String::Handle(String::New(js.ToCString()));
  SendEvent(kEventFamilyDebug, message, buffer, stream.bytes_written());
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


static bool HandleIsolateGetObjectByAddress(Isolate* isolate, JSONStream* js) {
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
  Object& object = Object::Handle(isolate);
  {
    NoGCScope no_gc;
    ContainsAddressVisitor visitor(isolate, addr);
    object = isolate->heap()->FindObject(&visitor);
  }
  object.PrintJSON(js, ref);
  return true;
}


static bool HandleIsolateRespondWithMalformedJson(Isolate* isolate,
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


static bool HandleIsolateRespondWithMalformedObject(Isolate* isolate,
                                                    JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("bart", "simpson");
  return true;
}


static const MethodParameter* get_object_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetObject(Isolate* isolate, JSONStream* js) {
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
    PrintSentinel(js, "objects/collected", "<collected>");
    return true;
  } else if (lookup_result == ObjectIdRing::kExpired) {
    PrintSentinel(js, "objects/expired", "<expired>");
    return true;
  }

  // Handle non-heap objects.
  SourceBreakpoint* bpt = LookupBreakpoint(isolate, id);
  if (bpt != NULL) {
    bpt->PrintJSON(js);
    return true;
  }

  PrintError(js, "Unrecognized object id: %s\n", id);
  return true;
}


static const MethodParameter* get_class_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetClassList(Isolate* isolate, JSONStream* js) {
  ClassTable* table = isolate->class_table();
  JSONObject jsobj(js);
  table->PrintToJSONObject(&jsobj);
  return true;
}


static const MethodParameter* get_type_arguments_list_params[] = {
  ISOLATE_PARAMETER,
  NULL,
};


static bool HandleIsolateGetTypeArgumentsList(Isolate* isolate,
                                              JSONStream* js) {
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


class ServiceIsolateVisitor : public IsolateVisitor {
 public:
  explicit ServiceIsolateVisitor(JSONArray* jsarr)
      : jsarr_(jsarr) {
  }

  virtual ~ServiceIsolateVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    if ((isolate != Dart::vm_isolate()) &&
        !ServiceIsolate::IsServiceIsolate(isolate)) {
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


static bool HandleVM(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "VM");
  jsobj.AddProperty("id", "vm");
  jsobj.AddProperty("architectureBits", static_cast<intptr_t>(kBitsPerWord));
  jsobj.AddProperty("targetCPU", CPU::Id());
  jsobj.AddProperty("hostCPU", HostCPUFeatures::hardware());
  jsobj.AddPropertyF("date", "%" Pd64 "", OS::GetCurrentTimeMillis());
  jsobj.AddProperty("version", Version::String());
  // Send pid as a string because it allows us to avoid any issues with
  // pids > 53-bits (when consumed by JavaScript).
  // TODO(johnmccutchan): Codify how integers are sent across the service.
  jsobj.AddPropertyF("pid", "%" Pd "", OS::ProcessId());
  jsobj.AddProperty("assertsEnabled", isolate->AssertsEnabled());
  jsobj.AddProperty("typeChecksEnabled", isolate->TypeChecksEnabled());
  int64_t start_time_micros = Dart::vm_isolate()->start_time();
  int64_t uptime_micros = (OS::GetCurrentTimeMicros() - start_time_micros);
  double seconds = (static_cast<double>(uptime_micros) /
                    static_cast<double>(kMicrosecondsPerSecond));
  jsobj.AddProperty("uptime", seconds);

  // Construct the isolate list.
  {
    JSONArray jsarr(&jsobj, "isolates");
    ServiceIsolateVisitor visitor(&jsarr);
    Isolate::VisitIsolates(&visitor);
  }
  return true;
}


static const MethodParameter* get_flag_list_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool HandleVMFlagList(Isolate* isolate, JSONStream* js) {
  Flags::PrintJSON(js);
  return true;
}


static const MethodParameter* set_flags_params[] = {
  NO_ISOLATE_PARAMETER,
  NULL,
};


static bool HandleVMSetFlag(Isolate* isolate, JSONStream* js) {
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
  JSONObject jsobj(js);
  const char* error = NULL;
  if (Flags::SetFlag(flag_name, flag_value, &error)) {
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    return true;
  } else {
    jsobj.AddProperty("type", "Failure");
    jsobj.AddProperty("id", "");
    jsobj.AddProperty("message", error);
    return true;
  }
}


static ServiceMethodDescriptor service_methods_[] = {
  { "_echo", HandleIsolateEcho,
    NULL },
  { "_respondWithMalformedJson", HandleIsolateRespondWithMalformedJson,
    NULL },
  { "_respondWithMalformedObject", HandleIsolateRespondWithMalformedObject,
    NULL },
  { "_triggerEchoEvent", HandleIsolateTriggerEchoEvent,
    NULL },
  { "addBreakpoint", HandleIsolateAddBreakpoint,
    add_breakpoint_params },
  { "eval", HandleIsolateEval,
    eval_params },
  { "getAllocationProfile", HandleIsolateGetAllocationProfile,
    get_allocation_profile_params },
  { "getBreakpoints", HandleIsolateGetBreakpoints,
    get_breakpoints_params },
  { "getCallSiteData", HandleIsolateGetCallSiteData,
    get_call_site_data_params },
  { "getClassList", HandleIsolateGetClassList,
    get_class_list_params },
  { "getCoverage", HandleIsolateGetCoverage,
    get_coverage_params },
  { "getCpuProfile", HandleIsolateGetCpuProfile,
    get_cpu_profile_params },
  { "getFlagList", HandleVMFlagList ,
    get_flag_list_params },
  { "getHeapMap", HandleIsolateGetHeapMap,
    get_heap_map_params },
  { "getInboundReferences", HandleIsolateGetInboundReferences,
    get_inbound_references_params },
  { "getInstances", HandleIsolateGetInstances,
    get_instances_params },
  { "getIsolate", HandleIsolate,
    get_isolate_params },
  { "getIsolateMetric", HandleIsolateGetMetric,
    get_metric_params },
  { "getIsolateMetricList", HandleIsolateGetMetricList,
    get_metric_list_params },
  { "getObject", HandleIsolateGetObject,
    get_object_params },
  { "getObjectByAddress", HandleIsolateGetObjectByAddress,
    get_object_by_address_params },
  { "getRetainedSize", HandleIsolateGetRetainedSize,
    get_retained_size_params },
  { "getRetainingPath", HandleIsolateGetRetainingPath,
    get_retaining_path_params },
  { "getStack", HandleIsolateGetStack,
    get_stack_params },
  { "getTagProfile", HandleIsolateGetTagProfile,
    get_tag_profile_params },
  { "getTypeArgumentsList", HandleIsolateGetTypeArgumentsList,
    get_type_arguments_list_params },
  { "getVM", HandleVM ,
    get_vm_params },
  { "getVMMetric", HandleVMGetMetric,
    get_vm_metric_params },
  { "getVMMetricList", HandleVMGetMetricList,
    get_vm_metric_list_params },
  { "pause", HandleIsolatePause,
    pause_params },
  { "removeBreakpoint", HandleIsolateRemoveBreakpoint,
    remove_breakpoint_params },
  { "resume", HandleIsolateResume,
    resume_params },
  { "requestHeapSnapshot", HandleIsolateRequestHeapSnapshot,
    request_heap_snapshot_params },
  { "setFlag", HandleVMSetFlag ,
    set_flags_params },
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
