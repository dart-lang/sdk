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
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/unicode.h"
#include "vm/version.h"

namespace dart {

DEFINE_FLAG(bool, trace_service, false, "Trace VM service requests.");
DEFINE_FLAG(bool, trace_service_pause_events, false,
            "Trace VM service isolate pause events.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, enable_asserts);

struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

extern ResourcesEntry __service_resources_[];

class Resources {
 public:
  static const int kNoSuchInstance = -1;
  static int ResourceLookup(const char* path, const char** resource) {
    ResourcesEntry* table = ResourceTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      const ResourcesEntry& entry = table[i];
      if (strcmp(path, entry.path_) == 0) {
        *resource = entry.resource_;
        ASSERT(entry.length_ > 0);
        return entry.length_;
      }
    }
    return kNoSuchInstance;
  }

  static const char* Path(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* entry = At(idx);
    if (entry == NULL) {
      return NULL;
    }
    ASSERT(entry->path_ != NULL);
    return entry->path_;
  }

  static int Length(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* entry = At(idx);
    if (entry == NULL) {
      return kNoSuchInstance;
    }
    ASSERT(entry->path_ != NULL);
    return entry->length_;
  }

  static const uint8_t* Resource(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* entry = At(idx);
    if (entry == NULL) {
      return NULL;
    }
    return reinterpret_cast<const uint8_t*>(entry->resource_);
  }

 private:
  static ResourcesEntry* At(int idx) {
    ASSERT(idx >= 0);
    ResourcesEntry* table = ResourceTable();
    for (int i = 0; table[i].path_ != NULL; i++) {
      if (idx == i) {
        return &table[i];
      }
    }
    return NULL;
  }

  static ResourcesEntry* ResourceTable() {
    return &__service_resources_[0];
  }

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Resources);
};


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


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void SendIsolateServiceMessage(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(1));

  // Set the type of the OOB message.
  message.SetAt(0, Smi::Handle(isolate, Smi::New(Message::kServiceOOBMsg)));

  // Serialize message.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(message);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(sp.Id(), data, writer.BytesWritten(),
                                   Message::kOOBPriority));
}


static void SendRootServiceMessage(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(0));
  Service::HandleRootMessage(message);
}


void Service::SetEventMask(uint32_t mask) {
  event_mask_ = mask;
}


void SetEventMask(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, mask, arguments->NativeArgAt(0));
  Service::SetEventMask(mask.AsTruncatedUint32Value());
}


// These must be kept in sync with service/constants.dart
#define VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID 1
#define VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID 2


static RawArray* MakeServiceControlMessage(Dart_Port port_id, intptr_t code,
                                           const String& name) {
  const Array& list = Array::Handle(Array::New(4));
  ASSERT(!list.IsNull());
  const Integer& code_int = Integer::Handle(Integer::New(code));
  const Integer& port_int = Integer::Handle(Integer::New(port_id));
  const SendPort& send_port = SendPort::Handle(SendPort::New(port_id));
  list.SetAt(0, code_int);
  list.SetAt(1, port_int);
  list.SetAt(2, send_port);
  list.SetAt(3, name);
  return list.raw();
}


class RegisterRunningIsolatesVisitor : public IsolateVisitor {
 public:
  explicit RegisterRunningIsolatesVisitor(Isolate* service_isolate)
      : IsolateVisitor(),
        register_function_(Function::Handle(service_isolate)),
        service_isolate_(service_isolate) {
    ASSERT(Isolate::Current() == service_isolate_);
    // Get library.
    const String& library_url = Symbols::DartVMService();
    ASSERT(!library_url.IsNull());
    const Library& library =
        Library::Handle(Library::LookupLibrary(library_url));
    ASSERT(!library.IsNull());
    // Get function.
    const String& function_name =
        String::Handle(String::New("_registerIsolate"));
    ASSERT(!function_name.IsNull());
    register_function_ = library.LookupFunctionAllowPrivate(function_name);
    ASSERT(!register_function_.IsNull());
  }

  virtual void VisitIsolate(Isolate* isolate) {
    ASSERT(Isolate::Current() == service_isolate_);
    if ((isolate == service_isolate_) ||
        (isolate == Dart::vm_isolate())) {
      // We do not register the service or vm isolate.
      return;
    }
    // Setup arguments for call.
    Dart_Port port_id = isolate->main_port();
    const Integer& port_int = Integer::Handle(Integer::New(port_id));
    ASSERT(!port_int.IsNull());
    const SendPort& send_port = SendPort::Handle(SendPort::New(port_id));
    const String& name = String::Handle(String::New(isolate->name()));
    ASSERT(!name.IsNull());
    const Array& args = Array::Handle(Array::New(3));
    ASSERT(!args.IsNull());
    args.SetAt(0, port_int);
    args.SetAt(1, send_port);
    args.SetAt(2, name);
    Object& r = Object::Handle(service_isolate_);
    r = DartEntry::InvokeFunction(register_function_, args);
    ASSERT(!r.IsError());
  }

 private:
  Function& register_function_;
  Isolate* service_isolate_;
};


static Dart_Port ExtractPort(Isolate* isolate, Dart_Handle receivePort) {
  const ReceivePort& rp = Api::UnwrapReceivePortHandle(isolate, receivePort);
  if (rp.IsNull()) {
    return ILLEGAL_PORT;
  }
  return rp.Id();
}


static void OnStart(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  {
    // Boot the dart:vmservice library.
    Dart_EnterScope();
    Dart_Handle url_str =
        Dart_NewStringFromCString(Symbols::Name(Symbols::kDartVMServiceId));
    Dart_Handle library = Dart_LookupLibrary(url_str);
    ASSERT(Dart_IsLibrary(library));
    Dart_Handle result =
        Dart_Invoke(library, Dart_NewStringFromCString("boot"), 0, NULL);
    ASSERT(!Dart_IsError(result));
    Dart_Port port = ExtractPort(isolate, result);
    ASSERT(port != ILLEGAL_PORT);
    Service::set_port(port);
    Dart_ExitScope();
  }
  {
    // Register running isolates with service.
    RegisterRunningIsolatesVisitor register_isolates(isolate);
    Isolate::VisitIsolates(&register_isolates);
  }
}


struct VmServiceNativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static VmServiceNativeEntry _VmServiceNativeEntries[] = {
  {"VMService_SendIsolateServiceMessage", 2, SendIsolateServiceMessage},
  {"VMService_SendRootServiceMessage", 1, SendRootServiceMessage},
  {"VMService_SetEventMask", 1, SetEventMask},
  {"VMService_OnStart", 0, OnStart },
};


static Dart_NativeFunction VmServiceNativeResolver(Dart_Handle name,
                                                   int num_arguments,
                                                   bool* auto_setup_scope) {
  const Object& obj = Object::Handle(Api::UnwrapHandle(name));
  if (!obj.IsString()) {
    return NULL;
  }
  const char* function_name = obj.ToCString();
  ASSERT(function_name != NULL);
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  intptr_t n =
      sizeof(_VmServiceNativeEntries) / sizeof(_VmServiceNativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    VmServiceNativeEntry entry = _VmServiceNativeEntries[i];
    if ((strcmp(function_name, entry.name) == 0) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}


EmbedderServiceHandler* Service::isolate_service_handler_head_ = NULL;
EmbedderServiceHandler* Service::root_service_handler_head_ = NULL;
Isolate* Service::service_isolate_ = NULL;
Dart_LibraryTagHandler Service::embedder_provided_handler_ = NULL;
Dart_Port Service::port_ = ILLEGAL_PORT;
uint32_t Service::event_mask_ = 0;

Isolate* Service::GetServiceIsolate(void* callback_data) {
  if (service_isolate_ != NULL) {
    // Already initialized, return service isolate.
    return service_isolate_;
  }
  Dart_ServiceIsolateCreateCalback create_callback =
    Isolate::ServiceCreateCallback();
  if (create_callback == NULL) {
    return NULL;
  }
  Isolate::SetCurrent(NULL);
  char* error = NULL;
  Isolate* isolate =
      reinterpret_cast<Isolate*>(create_callback(callback_data, &error));
  if (isolate == NULL) {
    return NULL;
  }
  StartIsolateScope isolate_scope(isolate);
  {
    // Install the dart:vmservice library.
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Library& library =
        Library::Handle(isolate, isolate->object_store()->root_library());
    // Isolate is empty.
    ASSERT(library.IsNull());
    // Grab embedder tag handler.
    embedder_provided_handler_ = isolate->library_tag_handler();
    // Temporarily install our own.
    isolate->set_library_tag_handler(LibraryTagHandler);
    // Get script resource.
    const char* resource = NULL;
    const char* path = "/vmservice.dart";
    intptr_t r = Resources::ResourceLookup(path, &resource);
    ASSERT(r != Resources::kNoSuchInstance);
    ASSERT(resource != NULL);
    const String& source_str = String::Handle(
        String::FromUTF8(reinterpret_cast<const uint8_t*>(resource), r));
    ASSERT(!source_str.IsNull());
    const String& url_str = String::Handle(Symbols::DartVMService().raw());
    library ^= Library::LookupLibrary(url_str);
    ASSERT(library.IsNull());
    // Setup library.
    library = Library::New(url_str);
    library.Register();
    const Script& script = Script::Handle(
      isolate, Script::New(url_str, source_str, RawScript::kLibraryTag));
    library.SetLoadInProgress();
    Dart_EnterScope();  // Need to enter scope for tag handler.
    const Error& error = Error::Handle(isolate,
                                       Compiler::Compile(library, script));
    ASSERT(error.IsNull());
    Dart_Handle result = Dart_FinalizeLoading(false);
    ASSERT(!Dart_IsError(result));
    Dart_ExitScope();

    // Install embedder default library tag handler again.
    isolate->set_library_tag_handler(embedder_provided_handler_);
    embedder_provided_handler_ = NULL;
    library.set_native_entry_resolver(VmServiceNativeResolver);
  }
  service_isolate_ = reinterpret_cast<Isolate*>(isolate);
  return service_isolate_;
}


bool Service::SendIsolateStartupMessage() {
  if (!IsRunning()) {
    return false;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  HANDLESCOPE(isolate);
  const String& name = String::Handle(String::New(isolate->name()));
  ASSERT(!name.IsNull());
  const Array& list = Array::Handle(
      MakeServiceControlMessage(Dart_GetMainPortId(),
                                VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID,
                                name));
  ASSERT(!list.IsNull());
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("Isolate %s %" Pd64 " registered with service \n",
              name.ToCString(),
              Dart_GetMainPortId());
  }
  return PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
}


bool Service::SendIsolateShutdownMessage() {
  if (!IsRunning()) {
    return false;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  HANDLESCOPE(isolate);
  const String& name = String::Handle(String::New(isolate->name()));
  ASSERT(!name.IsNull());
  const Array& list = Array::Handle(
      MakeServiceControlMessage(Dart_GetMainPortId(),
                                VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID,
                                name));
  ASSERT(!list.IsNull());
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("Isolate %s %" Pd64 " deregistered with service \n",
              name.ToCString(),
              Dart_GetMainPortId());
  }
  return PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
}


Dart_Handle Service::GetSource(const char* name) {
  ASSERT(name != NULL);
  int i = 0;
  while (true) {
    const char* path = Resources::Path(i);
    if (path == NULL) {
      break;
    }
    ASSERT(*path != '\0');
    // Skip the '/'.
    path++;
    if (strcmp(name, path) == 0) {
      const uint8_t* str = Resources::Resource(i);
      intptr_t length = Resources::Length(i);
      return Dart_NewStringFromUTF8(str, length);
    }
    i++;
  }
  return Dart_Null();
}


Dart_Handle Service::LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url) {
  if (!Dart_IsLibrary(library)) {
    return Dart_NewApiError("not a library");
  }
  if (!Dart_IsString(url)) {
    return Dart_NewApiError("url is not a string");
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kImportTag) {
    // Embedder handles all requests for external libraries.
    if (embedder_provided_handler_ == NULL) {
      return Dart_NewApiError("Unable to import module as no library tag "
                              "handler has been provided by embedder");
    }
    return embedder_provided_handler_(tag, library, url);
  }
  ASSERT((tag == Dart_kSourceTag) || (tag == Dart_kCanonicalizeUrl));
  if (tag == Dart_kCanonicalizeUrl) {
    // url is already canonicalized.
    return url;
  }
  Dart_Handle source = GetSource(url_string);
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadSource(library, url, source, 0, 0);
}


// A handler for a per-isolate request.
//
// If a handler returns true, the reply is complete and ready to be
// posted.  If a handler returns false, then it is responsible for
// posting the reply (this can be used for asynchronous delegation of
// the response handling).
typedef bool (*IsolateMessageHandler)(Isolate* isolate, JSONStream* stream);

struct IsolateMessageHandlerEntry {
  const char* command;
  IsolateMessageHandler handler;
};

static IsolateMessageHandler FindIsolateMessageHandler(const char* command);


// A handler for a root (vm-global) request.
//
// If a handler returns true, the reply is complete and ready to be
// posted.  If a handler returns false, then it is responsible for
// posting the reply (this can be used for asynchronous delegation of
// the response handling).
typedef bool (*RootMessageHandler)(JSONStream* stream);

struct RootMessageHandlerEntry {
  const char* command;
  RootMessageHandler handler;
};

static RootMessageHandler FindRootMessageHandler(const char* command);


static void PrintArgumentsAndOptions(const JSONObject& obj, JSONStream* js) {
  JSONObject jsobj(&obj, "request");
  {
    JSONArray jsarr(&jsobj, "arguments");
    for (intptr_t i = 0; i < js->num_arguments(); i++) {
      jsarr.AddValue(js->GetArgument(i));
    }
  }
  {
    JSONArray jsarr(&jsobj, "option_keys");
    for (intptr_t i = 0; i < js->num_options(); i++) {
      jsarr.AddValue(js->GetOptionKey(i));
    }
  }
  {
    JSONArray jsarr(&jsobj, "option_values");
    for (intptr_t i = 0; i < js->num_options(); i++) {
      jsarr.AddValue(js->GetOptionValue(i));
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
  jsobj.AddProperty("id", "");
  jsobj.AddProperty("message", buffer);
  PrintArgumentsAndOptions(jsobj, js);
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
  PrintArgumentsAndOptions(jsobj, js);
}


void Service::HandleIsolateMessage(Isolate* isolate, const Array& msg) {
  ASSERT(isolate != NULL);
  ASSERT(!msg.IsNull());

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    // Message is a list with five entries.
    ASSERT(msg.Length() == 5);

    Instance& reply_port = Instance::Handle(isolate);
    GrowableObjectArray& path = GrowableObjectArray::Handle(isolate);
    Array& option_keys = Array::Handle(isolate);
    Array& option_values = Array::Handle(isolate);
    reply_port ^= msg.At(1);
    path ^= msg.At(2);
    option_keys ^= msg.At(3);
    option_values ^= msg.At(4);

    ASSERT(!path.IsNull());
    ASSERT(!option_keys.IsNull());
    ASSERT(!option_values.IsNull());
    // Same number of option keys as values.
    ASSERT(option_keys.Length() == option_values.Length());

    if (!reply_port.IsSendPort()) {
      FATAL("SendPort expected.");
    }

    String& path_segment = String::Handle();
    if (path.Length() > 0) {
      path_segment ^= path.At(0);
    } else {
      path_segment ^= Symbols::Empty().raw();
    }
    ASSERT(!path_segment.IsNull());
    const char* path_segment_c = path_segment.ToCString();

    IsolateMessageHandler handler =
        FindIsolateMessageHandler(path_segment_c);
    {
      JSONStream js;
      js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(),
               path, option_keys, option_values);
      if (handler == NULL) {
        // Check for an embedder handler.
        EmbedderServiceHandler* e_handler =
            FindIsolateEmbedderHandler(path_segment_c);
        if (e_handler != NULL) {
          EmbedderHandleMessage(e_handler, &js);
        } else {
          PrintError(&js, "Unrecognized path");
        }
        js.PostReply();
      } else {
        if (handler(isolate, &js)) {
          // Handler returns true if the reply is ready to be posted.
          // TODO(johnmccutchan): Support asynchronous replies.
          js.PostReply();
        }
      }
    }
  }
}


static bool HandleIsolate(Isolate* isolate, JSONStream* js) {
  isolate->PrintJSON(js, false);
  return true;
}


static bool HandleStackTrace(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() > 1) {
    PrintError(js, "Command too long");
    return true;
  }
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "StackTrace");
  jsobj.AddProperty("id", "stacktrace");
  JSONArray jsarr(&jsobj, "members");
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
  jsobj->AddProperty("type", "message");
  PrintArgumentsAndOptions(*jsobj, js);
  return true;
}


void Service::SendEchoEvent(Isolate* isolate) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("type", "ServiceEvent");
    jsobj.AddPropertyF("id", "_echoEvent");
    jsobj.AddProperty("eventType", "_Echo");
    jsobj.AddProperty("isolate", isolate);
  }
  const String& message = String::Handle(String::New(js.ToCString()));
  uint8_t data[] = {0, 128, 255};
  // TODO(koda): Add 'testing' event family.
  SendEvent(kEventFamilyDebug, message, data, sizeof(data));
}


bool HandleIsolateEcho(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("id", "_echo");
  if (js->num_arguments() == 2 && strcmp(js->GetArgument(1), "event") == 0) {
    Service::SendEchoEvent(isolate);
  }
  return HandleCommonEcho(&jsobj, js);
}


// Print an error message if there is no ID argument.
#define REQUIRE_COLLECTION_ID(collection)                                      \
  if (js->num_arguments() == 1) {                                              \
    PrintError(js, "Must specify collection object id: /%s/id", collection);   \
    return true;                                                               \
  }


#define CHECK_COLLECTION_ID_BOUNDS(collection, length, arg, id, js)            \
  if (!GetIntegerId(arg, &id)) {                                               \
    PrintError(js, "Must specify collection object id: %s/id", collection);    \
    return true;                                                               \
  }                                                                            \
  if ((id < 0) || (id >= length)) {                                            \
    PrintError(js, "%s id (%" Pd ") must be in [0, %" Pd ").", collection, id, \
                                                               length);        \
    return true;                                                               \
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
const char* ScanUntilDash(const char* s) {
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


static bool HandleInboundReferences(Isolate* isolate,
                                    Object* target,
                                    intptr_t limit,
                                    JSONStream* js) {
  ObjectGraph graph(isolate);
  Array& path = Array::Handle(Array::New(limit * 2));
  intptr_t length = graph.InboundReferences(target, path);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "InboundReferences");
  jsobj.AddProperty("id", "inbound_references");
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


static bool HandleRetainingPath(Isolate* isolate,
                                Object* obj,
                                intptr_t limit,
                                JSONStream* js) {
  ObjectGraph graph(isolate);
  Array& path = Array::Handle(Array::New(limit * 2));
  intptr_t length = graph.RetainingPath(obj, path);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "RetainingPath");
  jsobj.AddProperty("id", "retaining_path");
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
  // reporting suprious references when looking for inbound references
  // after looking for a retaining path.
  for (intptr_t i = 0; i < limit; ++i) {
    path.SetAt(i * 2, Object::null_object());
  }

  return true;
}


// Takes an Object* only because RetainingPath temporarily clears it.
static bool HandleInstanceCommands(Isolate* isolate,
                                   Object* obj,
                                   ObjectIdRing::LookupResult kind,
                                   JSONStream* js,
                                   intptr_t arg_pos) {
  ASSERT(js->num_arguments() > arg_pos);
  ASSERT(kind != ObjectIdRing::kInvalid);
  const char* action = js->GetArgument(arg_pos);
  if (strcmp(action, "eval") == 0) {
    if (js->num_arguments() > (arg_pos + 1)) {
      PrintError(js, "expected at most %" Pd " arguments but found %" Pd "\n",
                 arg_pos + 1,
                 js->num_arguments());
      return true;
    }
    if (kind == ObjectIdRing::kCollected) {
      PrintErrorWithKind(js, "EvalCollected",
                         "attempt to evaluate against collected object\n",
                         js->num_arguments());
      return true;
    }
    if (kind == ObjectIdRing::kExpired) {
      PrintErrorWithKind(js, "EvalExpired",
                         "attempt to evaluate against expired object\n",
                         js->num_arguments());
      return true;
    }
    if (ContainsNonInstance(*obj)) {
      PrintError(js, "attempt to evaluate against internal VM object\n");
      return true;
    }
    const char* expr = js->LookupOption("expr");
    if (expr == NULL) {
      PrintError(js, "eval expects an 'expr' option\n",
                 js->num_arguments());
      return true;
    }
    const String& expr_str = String::Handle(isolate, String::New(expr));
    ASSERT(obj->IsInstance() || obj->IsNull());
    Instance& instance = Instance::Handle();
    instance ^= obj->raw();
    const Object& result =
        Object::Handle(instance.Evaluate(expr_str,
                                         Array::empty_array(),
                                         Array::empty_array()));
    result.PrintJSON(js, true);
    return true;
  } else if (strcmp(action, "retained") == 0) {
    if (kind == ObjectIdRing::kCollected) {
      PrintErrorWithKind(
          js, "RetainedCollected",
          "attempt to calculate size retained by a collected object\n",
          js->num_arguments());
      return true;
    }
    if (kind == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "RetainedExpired",
          "attempt to calculate size retained by an expired object\n",
          js->num_arguments());
      return true;
    }
    ObjectGraph graph(isolate);
    intptr_t retained_size = graph.SizeRetainedByInstance(*obj);
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return true;
  } else if (strcmp(action, "retaining_path") == 0) {
    if (kind == ObjectIdRing::kCollected) {
      PrintErrorWithKind(
          js, "RetainingPathCollected",
          "attempt to find a retaining path for a collected object\n",
          js->num_arguments());
      return true;
    }
    if (kind == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "RetainingPathExpired",
          "attempt to find a retaining path for an expired object\n",
          js->num_arguments());
      return true;
    }
    intptr_t limit;
    if (!GetIntegerId(js->LookupOption("limit"), &limit)) {
      PrintError(js, "retaining_path expects a 'limit' option\n",
                 js->num_arguments());
      return true;
    }
    return HandleRetainingPath(isolate, obj, limit, js);
  } else if (strcmp(action, "inbound_references") == 0) {
    if (kind == ObjectIdRing::kCollected) {
      PrintErrorWithKind(
          js, "InboundReferencesCollected",
          "attempt to find inbound references for a collected object\n",
          js->num_arguments());
      return true;
    }
    if (kind == ObjectIdRing::kExpired) {
      PrintErrorWithKind(
          js, "InboundReferencesExpired",
          "attempt to find inbound references for an expired object\n",
          js->num_arguments());
      return true;
    }
    intptr_t limit;
    if (!GetIntegerId(js->LookupOption("limit"), &limit)) {
      PrintError(js, "inbound_references expects a 'limit' option\n",
                 js->num_arguments());
      return true;
    }
    return HandleInboundReferences(isolate, obj, limit, js);
  }

  PrintError(js, "unrecognized action '%s'\n", action);
  return true;
}


static bool HandleClassesClosures(Isolate* isolate, const Class& cls,
                                  JSONStream* js) {
  intptr_t id;
  if (js->num_arguments() > 4) {
    PrintError(js, "Command too long");
    return true;
  }
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: closures/id");
    return true;
  }
  Function& func = Function::Handle();
  func ^= cls.ClosureFunctionFromIndex(id);
  if (func.IsNull()) {
    PrintError(js, "Closure function %" Pd " not found", id);
    return true;
  }
  func.PrintJSON(js, false);
  return true;
}


static bool HandleClassesEval(Isolate* isolate, const Class& cls,
                              JSONStream* js) {
  if (js->num_arguments() > 3) {
    PrintError(js, "Command too long");
    return true;
  }
  const char* expr = js->LookupOption("expr");
  if (expr == NULL) {
    PrintError(js, "eval expects an 'expr' option\n",
               js->num_arguments());
    return true;
  }
  const String& expr_str = String::Handle(isolate, String::New(expr));
  const Object& result = Object::Handle(cls.Evaluate(expr_str,
                                                     Array::empty_array(),
                                                     Array::empty_array()));
  result.PrintJSON(js, true);
  return true;
}


static bool HandleClassesDispatchers(Isolate* isolate, const Class& cls,
                                     JSONStream* js) {
  intptr_t id;
  if (js->num_arguments() > 4) {
    PrintError(js, "Command too long");
    return true;
  }
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: dispatchers/id");
    return true;
  }
  Function& func = Function::Handle();
  func ^= cls.InvocationDispatcherFunctionFromIndex(id);
  if (func.IsNull()) {
    PrintError(js, "Dispatcher %" Pd " not found", id);
    return true;
  }
  func.PrintJSON(js, false);
  return true;
}


static bool HandleClassesFunctionsCoverage(
    Isolate* isolate, const Function& func, JSONStream* js) {
  FunctionCoverageFilter filter(func);
  CodeCoverage::PrintJSON(isolate, js, &filter);
  return true;
}


static bool HandleClassesFunctions(Isolate* isolate, const Class& cls,
                                   JSONStream* js) {
  if (js->num_arguments() != 4 && js->num_arguments() != 5) {
    PrintError(js, "Command should have 4 or 5 arguments");
    return true;
  }
  const char* encoded_id = js->GetArgument(3);
  String& id = String::Handle(isolate, String::New(encoded_id));
  id = String::DecodeIRI(id);
  if (id.IsNull()) {
    PrintError(js, "Function id %s is malformed", encoded_id);
    return true;
  }
  Function& func = Function::Handle(cls.LookupFunction(id));
  if (func.IsNull()) {
    PrintError(js, "Function %s not found", encoded_id);
    return true;
  }
  if (js->num_arguments() == 4) {
    func.PrintJSON(js, false);
    return true;
  } else {
    const char* subcollection = js->GetArgument(4);
    if (strcmp(subcollection, "coverage") == 0) {
      return HandleClassesFunctionsCoverage(isolate, func, js);
    } else {
      PrintError(js, "Invalid sub collection %s", subcollection);
      return true;
    }
  }
  UNREACHABLE();
  return true;
}


static bool HandleClassesImplicitClosures(Isolate* isolate, const Class& cls,
                                          JSONStream* js) {
  intptr_t id;
  if (js->num_arguments() > 4) {
    PrintError(js, "Command too long");
    return true;
  }
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: implicit_closures/id");
    return true;
  }
  Function& func = Function::Handle();
  func ^= cls.ImplicitClosureFunctionFromIndex(id);
  if (func.IsNull()) {
    PrintError(js, "Implicit closure function %" Pd " not found", id);
    return true;
  }
  func.PrintJSON(js, false);
  return true;
}


static bool HandleClassesFields(Isolate* isolate, const Class& cls,
                                JSONStream* js) {
  intptr_t id;
  if (js->num_arguments() > 4) {
    PrintError(js, "Command too long");
    return true;
  }
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: fields/id");
    return true;
  }
  Field& field = Field::Handle(cls.FieldFromIndex(id));
  if (field.IsNull()) {
    PrintError(js, "Field %" Pd " not found", id);
    return true;
  }
  field.PrintJSON(js, false);
  return true;
}


static bool HandleClassesTypes(Isolate* isolate, const Class& cls,
                               JSONStream* js) {
  if (js->num_arguments() == 3) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "TypeList");
    JSONArray members(&jsobj, "members");
    const intptr_t num_types = cls.NumCanonicalTypes();
    Type& type = Type::Handle();
    for (intptr_t i = 0; i < num_types; i++) {
      type = cls.CanonicalTypeFromIndex(i);
      members.AddValue(type);
    }
    return true;
  }
  ASSERT(js->num_arguments() >= 4);
  intptr_t id;
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: types/id");
    return true;
  }
  Type& type = Type::Handle();
  type ^= cls.CanonicalTypeFromIndex(id);
  if (type.IsNull()) {
    PrintError(js, "Canonical type %" Pd " not found", id);
    return true;
  }
  if (js->num_arguments() == 4) {
    type.PrintJSON(js, false);
    return true;
  }
  return HandleInstanceCommands(isolate, &type, ObjectIdRing::kValid, js, 4);
}


static bool HandleClassesRetained(Isolate* isolate, const Class& cls,
                                  JSONStream* js) {
  if (js->num_arguments() != 3) {
    PrintError(js, "Command too long");
    return true;
  }
  ObjectGraph graph(isolate);
  intptr_t retained_size = graph.SizeRetainedByClass(cls.id());
  const Object& result = Object::Handle(Integer::New(retained_size));
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


static bool HandleClassesInstances(Isolate* isolate, const Class& cls,
                                   JSONStream* js) {
  if (js->num_arguments() != 3) {
    PrintError(js, "Command too long");
    return true;
  }
  intptr_t limit;
  if (!GetIntegerId(js->LookupOption("limit"), &limit)) {
    PrintError(js, "instances expects a 'limit' option\n",
               js->num_arguments());
    return true;
  }
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


static bool HandleClassesCoverage(Isolate* isolate,
                                  const Class& cls,
                                  JSONStream* stream) {
  ClassCoverageFilter cf(cls);
  CodeCoverage::PrintJSON(isolate, stream, &cf);
  return true;
}


static bool HandleClasses(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    ClassTable* table = isolate->class_table();
    JSONObject jsobj(js);
    table->PrintToJSONObject(&jsobj);
    return true;
  }
  ASSERT(js->num_arguments() >= 2);
  intptr_t id;
  if (!GetIntegerId(js->GetArgument(1), &id)) {
    PrintError(js, "Must specify collection object id: /classes/id");
    return true;
  }
  ClassTable* table = isolate->class_table();
  if (!table->IsValidIndex(id)) {
    PrintError(js, "%" Pd " is not a valid class id.", id);
    return true;
  }
  Class& cls = Class::Handle(table->At(id));
  if (js->num_arguments() == 2) {
    cls.PrintJSON(js, false);
    return true;
  } else if (js->num_arguments() >= 3) {
    const char* second = js->GetArgument(2);
    if (strcmp(second, "eval") == 0) {
      return HandleClassesEval(isolate, cls, js);
    } else if (strcmp(second, "closures") == 0) {
      return HandleClassesClosures(isolate, cls, js);
    } else if (strcmp(second, "fields") == 0) {
      return HandleClassesFields(isolate, cls, js);
    } else if (strcmp(second, "functions") == 0) {
      return HandleClassesFunctions(isolate, cls, js);
    } else if (strcmp(second, "implicit_closures") == 0) {
      return HandleClassesImplicitClosures(isolate, cls, js);
    } else if (strcmp(second, "dispatchers") == 0) {
      return HandleClassesDispatchers(isolate, cls, js);
    } else if (strcmp(second, "types") == 0) {
      return HandleClassesTypes(isolate, cls, js);
    } else if (strcmp(second, "retained") == 0) {
      return HandleClassesRetained(isolate, cls, js);
    } else if (strcmp(second, "instances") == 0) {
      return HandleClassesInstances(isolate, cls, js);
    } else if (strcmp(second, "coverage") == 0) {
      return HandleClassesCoverage(isolate, cls, js);
    } else {
      PrintError(js, "Invalid sub collection %s", second);
      return true;
    }
  }
  UNREACHABLE();
  return true;
}


static bool HandleLibrariesEval(Isolate* isolate, const Library& lib,
                                JSONStream* js) {
  if (js->num_arguments() > 3) {
    PrintError(js, "Command too long");
    return true;
  }
  const char* expr = js->LookupOption("expr");
  if (expr == NULL) {
    PrintError(js, "eval expects an 'expr' option\n",
               js->num_arguments());
    return true;
  }
  const String& expr_str = String::Handle(isolate, String::New(expr));
  const Object& result = Object::Handle(lib.Evaluate(expr_str,
                                                     Array::empty_array(),
                                                     Array::empty_array()));
  result.PrintJSON(js, true);
  return true;
}


static bool HandleLibrariesScriptsCoverage(
    Isolate* isolate, const Script& script, JSONStream* js) {
  ScriptCoverageFilter sf(script);
  CodeCoverage::PrintJSON(isolate, js, &sf);
  return true;
}


static bool HandleLibrariesScriptsSetBreakpoint(
    Isolate* isolate, const Script& script, JSONStream* js) {
  if (!js->HasOption("line")) {
    PrintError(js, "Missing 'line' option");
    return true;
  }
  const char* line_option = js->LookupOption("line");
  intptr_t line = -1;
  if (!GetIntegerId(line_option, &line)) {
    PrintError(js, "Invalid 'line' value: %s", line_option);
    return true;
  }
  const String& script_url = String::Handle(script.url());
  SourceBreakpoint* bpt =
      isolate->debugger()->SetBreakpointAtLine(script_url, line);
  if (bpt == NULL) {
    PrintError(js, "Unable to set breakpoint at line %s", line_option);
    return true;
  }
  bpt->PrintJSON(js);
  return true;
}


static bool HandleLibrariesScripts(Isolate* isolate,
                                   const Library& lib,
                                   JSONStream* js) {
  if (js->num_arguments() > 5) {
    PrintError(js, "Command too long");
    return true;
  } else if (js->num_arguments() < 4) {
    PrintError(js, "Must specify collection object id: scripts/id");
    return true;
  }
  const String& id = String::Handle(String::New(js->GetArgument(3)));
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
      break;
    }
  }
  if (i == loaded_scripts.Length()) {
    PrintError(js, "Script %s not found", requested_url.ToCString());
    return true;
  }
  if (js->num_arguments() == 4) {
    script.PrintJSON(js, false);
    return true;
  } else {
    const char* subcollection = js->GetArgument(4);
    if (strcmp(subcollection, "coverage") == 0) {
      return HandleLibrariesScriptsCoverage(isolate, script, js);
    } else if (strcmp(subcollection, "setBreakpoint") == 0) {
      return HandleLibrariesScriptsSetBreakpoint(isolate, script, js);
    } else {
      PrintError(js, "Invalid sub collection %s", subcollection);
      return true;
    }
  }
  UNREACHABLE();
  return true;
}


static bool HandleLibrariesCoverage(Isolate* isolate,
                                    const Library& lib,
                                    JSONStream* js) {
  LibraryCoverageFilter lf(lib);
  CodeCoverage::PrintJSON(isolate, js, &lf);
  return true;
}


static bool HandleLibraries(Isolate* isolate, JSONStream* js) {
  // TODO(johnmccutchan): Support fields and functions on libraries.
  REQUIRE_COLLECTION_ID("libraries");
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  ASSERT(!libs.IsNull());
  intptr_t id = 0;
  CHECK_COLLECTION_ID_BOUNDS("libraries", libs.Length(), js->GetArgument(1),
                             id, js);
  Library& lib = Library::Handle();
  lib ^= libs.At(id);
  ASSERT(!lib.IsNull());
  if (js->num_arguments() == 2) {
    lib.PrintJSON(js, false);
    return true;
  } else if (js->num_arguments() >= 3) {
    const char* second = js->GetArgument(2);
    if (strcmp(second, "eval") == 0) {
      return HandleLibrariesEval(isolate, lib, js);
    } else if (strcmp(second, "scripts") == 0) {
      return HandleLibrariesScripts(isolate, lib, js);
    } else if (strcmp(second, "coverage") == 0) {
      return HandleLibrariesCoverage(isolate, lib, js);
    } else {
      PrintError(js, "Invalid sub collection %s", second);
      return true;
    }
  }
  UNREACHABLE();
  return true;
}


static void PrintSentinel(JSONStream* js,
                          const char* id,
                          const char* preview) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Sentinel");
  jsobj.AddProperty("id", id);
  jsobj.AddProperty("valueAsString", preview);
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


static bool HandleIsolateMetricsList(Isolate* isolate, JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "MetricList");
  obj.AddProperty("id", "metrics/vm");
  {
    JSONArray members(&obj, "members");
    Metric* current = isolate->metrics_list_head();
    while (current != NULL) {
      members.AddValue(current);
      current = current->next();
    }
  }
  return true;
}


static bool HandleIsolateMetric(Isolate* isolate,
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
  PrintError(js, "Metric %s not found\n", id);
  return true;
}


static bool HandleMetricsList(Isolate* isolate, JSONStream* js) {
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


static bool HandleMetric(Isolate* isolate, JSONStream* js, const char* id) {
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
  PrintError(js, "Metric %s not found\n", id);
  return true;
}


static bool HandleMetrics(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    return HandleMetricsList(isolate, js);
  }
  ASSERT(js->num_arguments() > 1);
  const char* arg = js->GetArgument(1);
  if (strcmp(arg, "vm") == 0) {
    if (js->num_arguments() == 2) {
      return HandleIsolateMetricsList(isolate, js);
    } else {
      if (js->num_arguments() > 3) {
        PrintError(js, "Command too long");
        return true;
      }
      return HandleIsolateMetric(isolate, js, js->GetArgument(2));
    }
  }
  if (js->num_arguments() > 2) {
    PrintError(js, "Command too long");
    return true;
  }
  return HandleMetric(isolate, js, arg);
}


static bool HandleObjects(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("objects");
  if (js->num_arguments() < 2) {
    PrintError(js, "expected at least 2 arguments but found %" Pd "\n",
               js->num_arguments());
    return true;
  }
  const char* arg = js->GetArgument(1);

  // Handle special non-objects first.
  if (strcmp(arg, "optimized-out") == 0) {
    if (js->num_arguments() > 2) {
      PrintError(js, "expected at most 2 arguments but found %" Pd "\n",
                 js->num_arguments());
    } else {
      Symbols::OptimizedOut().PrintJSON(js, false);
    }
    return true;

  } else if (strcmp(arg, "collected") == 0) {
    if (js->num_arguments() > 2) {
      PrintError(js, "expected at most 2 arguments but found %" Pd "\n",
                 js->num_arguments());
    } else {
      PrintSentinel(js, "objects/collected", "<collected>");
    }
    return true;

  } else if (strcmp(arg, "expired") == 0) {
    if (js->num_arguments() > 2) {
      PrintError(js, "expected at most 2 arguments but found %" Pd "\n",
                 js->num_arguments());
    } else {
      PrintSentinel(js, "objects/expired", "<expired>");
    }
    return true;
  }

  // Lookup the object.
  Object& obj = Object::Handle(isolate);
  ObjectIdRing::LookupResult kind = ObjectIdRing::kInvalid;
  obj = LookupObjectId(isolate, arg, &kind);
  if (kind == ObjectIdRing::kInvalid) {
    PrintError(js, "unrecognized object id '%s'", arg);
    return true;
  }
  if (js->num_arguments() == 2) {
    // Print.
    if (kind == ObjectIdRing::kCollected) {
      // The object has been collected by the gc.
      PrintSentinel(js, "objects/collected", "<collected>");
      return true;
    } else if (kind == ObjectIdRing::kExpired) {
      // The object id has expired.
      PrintSentinel(js, "objects/expired", "<expired>");
      return true;
    }
    obj.PrintJSON(js, false);
    return true;
  }
  return HandleInstanceCommands(isolate, &obj, kind, js, 2);
}


static bool HandleScriptsEnumerate(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "ScriptList");
  jsobj.AddProperty("id", "scripts");
  JSONArray members(&jsobj, "members");
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  intptr_t num_libs = libs.Length();
  Library &lib = Library::Handle();
  Script& script = Script::Handle();
  for (intptr_t i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    ASSERT(Smi::IsValid(lib.index()));
    const Array& loaded_scripts = Array::Handle(lib.LoadedScripts());
    ASSERT(!loaded_scripts.IsNull());
    intptr_t num_scripts = loaded_scripts.Length();
    for (intptr_t i = 0; i < num_scripts; i++) {
      script ^= loaded_scripts.At(i);
      members.AddValue(script);
    }
  }
  return true;
}


static bool HandleScripts(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    // Enumerate all scripts.
    return HandleScriptsEnumerate(isolate, js);
  }
  PrintError(js, "Command too long");
  return true;
}


static bool HandleDebugResume(Isolate* isolate,
                              const char* step_option,
                              JSONStream* js) {
  if (isolate->message_handler()->paused_on_start()) {
    isolate->message_handler()->set_pause_on_start(false);
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    return true;
  }
  if (isolate->message_handler()->paused_on_exit()) {
    isolate->message_handler()->set_pause_on_exit(false);
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Success");
    jsobj.AddProperty("id", "");
    return true;
  }
  if (isolate->debugger()->PauseEvent() != NULL) {
    if (step_option != NULL) {
      if (strcmp(step_option, "into") == 0) {
        isolate->debugger()->SetSingleStep();
      } else if (strcmp(step_option, "over") == 0) {
        isolate->debugger()->SetStepOver();
      } else if (strcmp(step_option, "out") == 0) {
        isolate->debugger()->SetStepOut();
      } else {
        PrintError(js, "Invalid 'step' option: %s", step_option);
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


static bool HandleDebug(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    PrintError(js, "Must specify a subcommand");
    return true;
  }
  const char* command = js->GetArgument(1);
  if (strcmp(command, "breakpoints") == 0) {
    if (js->num_arguments() == 2) {
      // Print breakpoint list.
      JSONObject jsobj(js);
      jsobj.AddProperty("type", "BreakpointList");
      jsobj.AddProperty("id", "debug/breakpoints");
      JSONArray jsarr(&jsobj, "breakpoints");
      isolate->debugger()->PrintBreakpointsToJSONArray(&jsarr);
      return true;
    } else {
      intptr_t id = 0;
      SourceBreakpoint* bpt = NULL;
      if (GetIntegerId(js->GetArgument(2), &id)) {
        bpt = isolate->debugger()->GetBreakpointById(id);
      }
      if (bpt == NULL) {
        PrintError(js, "Unrecognized breakpoint id: %s", js->GetArgument(2));
        return true;
      }
      if (js->num_arguments() == 3) {
        // Print individual breakpoint.
        bpt->PrintJSON(js);
        return true;
      } else if (js->num_arguments() == 4) {
        const char* sub_command = js->GetArgument(3);
        if (strcmp(sub_command, "clear") == 0) {
          // Clear this breakpoint.
          isolate->debugger()->RemoveBreakpoint(id);

          JSONObject jsobj(js);
          jsobj.AddProperty("type", "Success");
          jsobj.AddProperty("id", "");
          return true;
        } else {
          PrintError(js, "Unrecognized subcommand: %s", sub_command);
          return true;
        }
      } else {
        PrintError(js, "Command too long");
        return true;
      }
    }
  } else if (strcmp(command, "pause") == 0) {
    if (js->num_arguments() == 2) {
      // TODO(turnidge): Don't double-interrupt the isolate here.
      isolate->ScheduleInterrupts(Isolate::kApiInterrupt);
      JSONObject jsobj(js);
      jsobj.AddProperty("type", "Success");
      jsobj.AddProperty("id", "");
      return true;
    } else {
      PrintError(js, "Command too long");
      return true;
    }
  } else if (strcmp(command, "resume") == 0) {
    if (js->num_arguments() == 2) {
      const char* step_option = js->LookupOption("step");
      return HandleDebugResume(isolate, step_option, js);
    } else {
      PrintError(js, "Command too long");
      return true;
    }
  } else {
    PrintError(js, "Unrecognized subcommand '%s'", js->GetArgument(1));
    return true;
  }
}


static bool HandleNullCode(uintptr_t pc, JSONStream* js) {
  // TODO(turnidge): Consider adding/using Object::null_code() for
  // consistent "type".
  Object::null_object().PrintJSON(js, false);
  return true;
}


static bool HandleCode(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("code");
  uword pc;
  if (js->num_arguments() > 2) {
    PrintError(js, "Command too long");
    return true;
  }
  ASSERT(js->num_arguments() == 2);
  static const char* kCollectedPrefix = "collected-";
  static intptr_t kCollectedPrefixLen = strlen(kCollectedPrefix);
  static const char* kNativePrefix = "native-";
  static intptr_t kNativePrefixLen = strlen(kNativePrefix);
  static const char* kReusedPrefix = "reused-";
  static intptr_t kReusedPrefixLen = strlen(kReusedPrefix);
  const char* command = js->GetArgument(1);
  if (strncmp(kCollectedPrefix, command, kCollectedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&command[kCollectedPrefixLen], &pc, 16)) {
      PrintError(js, "Must specify code address: code/%sc0deadd0.",
                 kCollectedPrefix);
      return true;
    }
    return HandleNullCode(pc, js);
  }
  if (strncmp(kNativePrefix, command, kNativePrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&command[kNativePrefixLen], &pc, 16)) {
      PrintError(js, "Must specify code address: code/%sc0deadd0.",
                 kNativePrefix);
      return true;
    }
    // TODO(johnmccutchan): Support native Code.
    return HandleNullCode(pc, js);
  }
  if (strncmp(kReusedPrefix, command, kReusedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&command[kReusedPrefixLen], &pc, 16)) {
      PrintError(js, "Must specify code address: code/%sc0deadd0.",
                 kReusedPrefix);
      return true;
    }
    return HandleNullCode(pc, js);
  }
  int64_t timestamp = 0;
  if (!GetCodeId(command, &timestamp, &pc) || (timestamp < 0)) {
    PrintError(js, "Malformed code id: %s", command);
    return true;
  }
  Code& code = Code::Handle(Code::FindCode(pc, timestamp));
  if (!code.IsNull()) {
    code.PrintJSON(js, false);
    return true;
  }
  PrintError(js, "Could not find code with id: %s", command);
  return true;
}


static bool HandleProfile(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 2) {
    const char* sub_command = js->GetArgument(1);
    if (!strcmp(sub_command, "tag")) {
      {
        JSONObject miniProfile(js);
        miniProfile.AddProperty("type", "TagProfile");
        miniProfile.AddProperty("id", "profile/tag");
        isolate->vm_tag_counters()->PrintToJSONObject(&miniProfile);
      }
      return true;
    } else {
      PrintError(js, "Unrecognized subcommand '%s'", sub_command);
      return true;
    }
  }
  // A full profile includes disassembly of all Dart code objects.
  // TODO(johnmccutchan): Add sub command to trigger full code dump.
  bool full_profile = false;
  const char* tags_option = js->LookupOption("tags");
  Profiler::TagOrder tag_order = Profiler::kUserVM;
  if (js->HasOption("tags")) {
    if (js->OptionIs("tags", "hide")) {
      tag_order = Profiler::kNoTags;
    } else if (js->OptionIs("tags", "uv")) {
      tag_order = Profiler::kUserVM;
    } else if (js->OptionIs("tags", "u")) {
      tag_order = Profiler::kUser;
    } else if (js->OptionIs("tags", "vu")) {
      tag_order = Profiler::kVMUser;
    } else if (js->OptionIs("tags", "v")) {
      tag_order = Profiler::kVM;
    } else {
      PrintError(js, "Invalid tags option value: %s\n", tags_option);
      return true;
    }
  }
  Profiler::PrintJSON(isolate, js, full_profile, tag_order);
  return true;
}

static bool HandleCoverage(Isolate* isolate, JSONStream* js) {
  CodeCoverage::PrintJSON(isolate, js, NULL);
  return true;
}


static bool HandleAllocationProfile(Isolate* isolate, JSONStream* js) {
  bool should_reset_accumulator = false;
  bool should_collect = false;
  if (js->num_arguments() != 1) {
    PrintError(js, "Command too long");
    return true;
  }
  if (js->HasOption("reset")) {
    if (js->OptionIs("reset", "true")) {
      should_reset_accumulator = true;
    } else {
      PrintError(js, "Unrecognized reset option '%s'",
                 js->LookupOption("reset"));
      return true;
    }
  }
  if (js->HasOption("gc")) {
    if (js->OptionIs("gc", "full")) {
      should_collect = true;
    } else {
      PrintError(js, "Unrecognized gc option '%s'", js->LookupOption("gc"));
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


static bool HandleTypeArguments(Isolate* isolate, JSONStream* js) {
  ObjectStore* object_store = isolate->object_store();
  const Array& table = Array::Handle(object_store->canonical_type_arguments());
  ASSERT(table.Length() > 0);
  TypeArguments& type_args = TypeArguments::Handle();
  const intptr_t table_size = table.Length() - 1;
  const intptr_t table_used = Smi::Value(Smi::RawCast(table.At(table_size)));
  bool only_with_instantiations = false;
  if (js->num_arguments() >= 2) {
    const char* second = js->GetArgument(1);
    if (strcmp(second, "withinstantiations") == 0) {
      only_with_instantiations = true;
      if (js->num_arguments() > 2) {
        PrintError(js, "Command too long");
        return true;
      }
    }
  }
  if ((js->num_arguments() == 1) || only_with_instantiations) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "TypeArgumentsList");
    jsobj.AddProperty("table_size", table_size);
    jsobj.AddProperty("table_used", table_used);
    JSONArray members(&jsobj, "members");
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
  ASSERT((js->num_arguments() >= 2) && !only_with_instantiations);
  intptr_t id;
  if (!GetIntegerId(js->GetArgument(1), &id)) {
    // Note that the table index of the canonical type arguments will change
    // when the table grows. Should we not support this access at all?
    PrintError(js, "Must specify collection object id: /typearguments/id");
    return true;
  }
  if ((id < 0) || (id >= table_size) || (table.At(id) == Object::null())) {
    PrintError(js, "%" Pd " is not a valid typearguments id.", id);
    return true;
  }
  type_args ^= table.At(id);
  type_args.PrintJSON(js, false);
  return true;
}


static bool HandleHeapMap(Isolate* isolate, JSONStream* js) {
  isolate->heap()->PrintHeapMapToJSONStream(isolate, js);
  return true;
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


static bool HandleAddress(Isolate* isolate, JSONStream* js) {
  uword addr = 0;
  if (js->num_arguments() != 2 ||
      !GetUnsignedIntegerId(js->GetArgument(1), &addr, 16)) {
    static const uword kExampleAddr = static_cast<uword>(kIntptrMax / 7);
    PrintError(js, "Must specify address: address/" Px ".", kExampleAddr);
    return true;
  }
  Object& object = Object::Handle(isolate);
  {
    NoGCScope no_gc;
    ContainsAddressVisitor visitor(isolate, addr);
    object = isolate->heap()->FindObject(&visitor);
  }
  object.PrintJSON(js, true);
  return true;
}


static bool HandleMalformedJson(Isolate* isolate, JSONStream* js) {
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


static bool HandleMalformedObject(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("bart", "simpson");
  return true;
}


static IsolateMessageHandlerEntry isolate_handlers[] = {
  { "_malformedjson", HandleMalformedJson },
  { "_malformedobject", HandleMalformedObject },
  { "_echo", HandleIsolateEcho },
  { "", HandleIsolate },
  { "address", HandleAddress },
  { "allocationprofile", HandleAllocationProfile },
  { "classes", HandleClasses },
  { "code", HandleCode },
  { "coverage", HandleCoverage },
  { "debug", HandleDebug },
  { "heapmap", HandleHeapMap },
  { "libraries", HandleLibraries },
  { "metrics", HandleMetrics },
  { "objects", HandleObjects },
  { "profile", HandleProfile },
  { "scripts", HandleScripts },
  { "stacktrace", HandleStackTrace },
  { "typearguments", HandleTypeArguments },
};


static IsolateMessageHandler FindIsolateMessageHandler(const char* command) {
  intptr_t num_message_handlers = sizeof(isolate_handlers) /
                                  sizeof(isolate_handlers[0]);
  for (intptr_t i = 0; i < num_message_handlers; i++) {
    const IsolateMessageHandlerEntry& entry = isolate_handlers[i];
    if (strcmp(command, entry.command) == 0) {
      return entry.handler;
    }
  }
  if (FLAG_trace_service) {
    OS::Print("Service has no isolate message handler for <%s>\n", command);
  }
  return NULL;
}


void Service::HandleRootMessage(const Instance& msg) {
  Isolate* isolate = Isolate::Current();
  ASSERT(!msg.IsNull());
  ASSERT(msg.IsArray());

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    const Array& message = Array::Cast(msg);
    // Message is a list with five entries.
    ASSERT(message.Length() == 5);

    Instance& reply_port = Instance::Handle(isolate);
    GrowableObjectArray& path = GrowableObjectArray::Handle(isolate);
    Array& option_keys = Array::Handle(isolate);
    Array& option_values = Array::Handle(isolate);

    reply_port ^= message.At(1);
    path ^= message.At(2);
    option_keys ^= message.At(3);
    option_values ^= message.At(4);

    ASSERT(!path.IsNull());
    ASSERT(!option_keys.IsNull());
    ASSERT(!option_values.IsNull());
    // Path always has at least one entry in it.
    ASSERT(path.Length() > 0);
    // Same number of option keys as values.
    ASSERT(option_keys.Length() == option_values.Length());

    if (!reply_port.IsSendPort()) {
      FATAL("SendPort expected.");
    }

    String& path_segment = String::Handle();
    if (path.Length() > 0) {
      path_segment ^= path.At(0);
    } else {
      path_segment ^= Symbols::Empty().raw();
    }
    ASSERT(!path_segment.IsNull());
    const char* path_segment_c = path_segment.ToCString();

    RootMessageHandler handler =
        FindRootMessageHandler(path_segment_c);
    {
      JSONStream js;
      js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(),
               path, option_keys, option_values);
      if (handler == NULL) {
        // Check for an embedder handler.
        EmbedderServiceHandler* e_handler =
            FindRootEmbedderHandler(path_segment_c);
        if (e_handler != NULL) {
          EmbedderHandleMessage(e_handler, &js);
        } else {
          PrintError(&js, "Unrecognized path");
        }
        js.PostReply();
      } else {
        if (handler(&js)) {
          // Handler returns true if the reply is ready to be posted.
          // TODO(johnmccutchan): Support asynchronous replies.
          js.PostReply();
        }
      }
    }
  }
}


static bool HandleRootEcho(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("id", "_echo");
  return HandleCommonEcho(&jsobj, js);
}


class ServiceIsolateVisitor : public IsolateVisitor {
 public:
  explicit ServiceIsolateVisitor(JSONArray* jsarr)
      : jsarr_(jsarr) {
  }

  virtual ~ServiceIsolateVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    if (isolate != Dart::vm_isolate() && !Service::IsServiceIsolate(isolate)) {
      jsarr_->AddValue(isolate);
    }
  }

 private:
  JSONArray* jsarr_;
};


static bool HandleVM(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "VM");
  jsobj.AddProperty("id", "vm");
  jsobj.AddProperty("targetCPU", CPU::Id());
  jsobj.AddProperty("hostCPU", HostCPUFeatures::hardware());
  jsobj.AddPropertyF("date", "%" Pd64 "", OS::GetCurrentTimeMillis());
  jsobj.AddProperty("version", Version::String());
  // Send pid as a string because it allows us to avoid any issues with
  // pids > 53-bits (when consumed by JavaScript).
  // TODO(johnmccutchan): Codify how integers are sent across the service.
  jsobj.AddPropertyF("pid", "%" Pd "", OS::ProcessId());
  jsobj.AddProperty("assertsEnabled", FLAG_enable_asserts);
  jsobj.AddProperty("typeChecksEnabled", FLAG_enable_type_checks);
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


static bool HandleFlags(JSONStream* js) {
  if (js->num_arguments() == 1) {
    Flags::PrintJSON(js);
    return true;
  } else if (js->num_arguments() == 2) {
    const char* arg = js->GetArgument(1);
    if (strcmp(arg, "set") == 0) {
      if (js->num_arguments() > 2) {
        PrintError(js, "expected at most 2 arguments but found %" Pd "\n",
                   js->num_arguments());
      } else {
        if (js->HasOption("name") && js->HasOption("value")) {
          JSONObject jsobj(js);
          const char* flag_name = js->LookupOption("name");
          const char* flag_value = js->LookupOption("value");
          const char* error = NULL;
          if (Flags::SetFlag(flag_name, flag_value, &error)) {
            jsobj.AddProperty("type", "Success");
            jsobj.AddProperty("id", "");
          } else {
            jsobj.AddProperty("type", "Failure");
            jsobj.AddProperty("id", "");
            jsobj.AddProperty("message", error);
          }
        } else {
          PrintError(js, "expected to find 'name' and 'value' options");
        }
      }
    }
    return true;
  } else {
    PrintError(js, "Command too long");
    return true;
  }
}


static RootMessageHandlerEntry root_handlers[] = {
  { "_echo", HandleRootEcho },
  { "vm", HandleVM },
  { "flags", HandleFlags },
};


static RootMessageHandler FindRootMessageHandler(const char* command) {
  intptr_t num_message_handlers = sizeof(root_handlers) /
                                  sizeof(root_handlers[0]);
  for (intptr_t i = 0; i < num_message_handlers; i++) {
    const RootMessageHandlerEntry& entry = root_handlers[i];
    if (strcmp(command, entry.command) == 0) {
      return entry.handler;
    }
  }
  if (FLAG_trace_service) {
    OS::Print("Service has no root message handler for <%s>\n", command);
  }
  return NULL;
}


void Service::SendEvent(intptr_t eventId, const Object& eventMessage) {
  if (!IsRunning()) {
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
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("Pushing event of type %" Pd ", len %" Pd "\n", eventId, len);
  }
  // TODO(turnidge): For now we ignore failure to send an event.  Revisit?
  PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
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


void Service::EmbedderHandleMessage(EmbedderServiceHandler* handler,
                                    JSONStream* js) {
  ASSERT(handler != NULL);
  Dart_ServiceRequestCallback callback = handler->callback();
  ASSERT(callback != NULL);
  const char* r = NULL;
  const char* name = js->command();
  const char** arguments = js->arguments();
  const char** keys = js->option_keys();
  const char** values = js->option_values();
  r = callback(name, arguments, js->num_arguments(), keys, values,
               js->num_options(), handler->user_data());
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

}  // namespace dart
