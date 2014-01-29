// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service.h"

#include "include/dart_api.h"

#include "vm/compiler.h"
#include "vm/coverage.h"
#include "vm/cpu.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/heap_histogram.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/symbols.h"


namespace dart {

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


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void SendIsolateServiceMessage(Dart_NativeArguments args) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(1));

  // Extract SendPort port id.
  const Object& sp_id_obj = Object::Handle(DartLibraryCalls::PortGetId(sp));
  if (sp_id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(sp_id_obj));
  }
  Integer& id = Integer::Handle(isolate);
  id ^= sp_id_obj.raw();
  Dart_Port sp_id = static_cast<Dart_Port>(id.AsInt64Value());
  ASSERT(sp_id != ILLEGAL_PORT);

  // Serialize message.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(message);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(sp_id, data, writer.BytesWritten(),
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


struct VmServiceNativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static VmServiceNativeEntry _VmServiceNativeEntries[] = {
  {"VMService_SendIsolateServiceMessage", 2, SendIsolateServiceMessage},
  {"VMService_SendRootServiceMessage", 1, SendRootServiceMessage}
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
    if (!strcmp(function_name, entry.name) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}


Isolate* Service::service_isolate_ = NULL;
Dart_LibraryTagHandler Service::default_handler_ = NULL;
Dart_Port Service::port_ = ILLEGAL_PORT;

static Dart_Port ExtractPort(Dart_Handle receivePort) {
  HANDLESCOPE(Isolate::Current());
  const Object& unwrapped_rp = Object::Handle(Api::UnwrapHandle(receivePort));
  const Instance& rp = Instance::Cast(unwrapped_rp);
  // Extract RawReceivePort port id.
  const Object& rp_id_obj = Object::Handle(DartLibraryCalls::PortGetId(rp));
  if (rp_id_obj.IsError()) {
    return ILLEGAL_PORT;
  }
  ASSERT(rp_id_obj.IsSmi() || rp_id_obj.IsMint());
  const Integer& id = Integer::Cast(rp_id_obj);
  return static_cast<Dart_Port>(id.AsInt64Value());
}


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
  Isolate* isolate = reinterpret_cast<Isolate*>(
      create_callback(callback_data, &error));
  if (isolate == NULL) {
    return NULL;
  }
  Isolate::SetCurrent(isolate);
  {
    // Install the dart:vmservice library.
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Library& library =
        Library::Handle(isolate, isolate->object_store()->root_library());
    // Isolate is empty.
    ASSERT(library.IsNull());
    // Grab embedder tag handler.
    default_handler_ = isolate->library_tag_handler();
    ASSERT(default_handler_ != NULL);
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
    Dart_ExitScope();
    library.SetLoaded();
    // Install embedder default library tag handler again.
    isolate->set_library_tag_handler(default_handler_);
    default_handler_ = NULL;
    library.set_native_entry_resolver(VmServiceNativeResolver);
  }
  {
    // Boot the dart:vmservice library.
    Dart_EnterScope();
    Dart_Handle result;
    Dart_Handle url_str =
        Dart_NewStringFromCString(Symbols::Name(Symbols::kDartVMServiceId));
    Dart_Handle library = Dart_LookupLibrary(url_str);
    ASSERT(Dart_IsLibrary(library));
    result = Dart_Invoke(library, Dart_NewStringFromCString("boot"), 0, NULL);
    ASSERT(!Dart_IsError(result));
    port_ = ExtractPort(result);
    ASSERT(port_ != ILLEGAL_PORT);
    Dart_ExitScope();
  }
  Isolate::SetCurrent(NULL);
  service_isolate_ = reinterpret_cast<Isolate*>(isolate);
  return service_isolate_;
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
  const Object& send_port = Object::Handle(
      DartLibraryCalls::NewSendPort(port_id));
  ASSERT(!send_port.IsNull());
  list.SetAt(0, code_int);
  list.SetAt(1, port_int);
  list.SetAt(2, send_port);
  list.SetAt(3, name);
  return list.raw();
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
  const Array& list = Array::Handle(
      MakeServiceControlMessage(Dart_GetMainPortId(),
                                VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID,
                                String::Handle(String::null())));
  ASSERT(!list.IsNull());
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  return PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
}


bool Service::IsRunning() {
  return port_ != ILLEGAL_PORT;
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
    ASSERT(default_handler_ != NULL);
    return default_handler_(tag, library, url);
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
  return Dart_LoadSource(library, url, source);
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


static void PostReply(JSONStream* js) {
  Dart_Port reply_port = js->reply_port();
  ASSERT(reply_port != ILLEGAL_PORT);
  js->set_reply_port(ILLEGAL_PORT);  // Prevent double replies.

  const String& reply = String::Handle(String::New(js->ToCString()));
  ASSERT(!reply.IsNull());

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(reply);
  PortMap::PostMessage(new Message(reply_port, data,
                                   writer.BytesWritten(),
                                   Message::kNormalPriority));
}


static void SetupJSONStream(JSONStream* js, Zone* zone,
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
  js->set_reply_port(port);

  // Setup JSONStream arguments and options. The arguments and options
  // are zone allocated and will be freed immediately after handling the
  // message.
  const char** arguments = zone->Alloc<const char*>(path.Length());
  String& string_iterator = String::Handle();
  for (intptr_t i = 0; i < path.Length(); i++) {
    string_iterator ^= path.At(i);
    arguments[i] = zone->MakeCopyOfString(string_iterator.ToCString());
  }
  js->SetArguments(arguments, path.Length());
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
    js->SetOptions(option_keys_native, option_values_native,
                  option_keys.Length());
  }
}


static void PrintArgumentsAndOptions(const JSONObject& obj, JSONStream* js) {
  JSONObject jsobj(&obj, "message");
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


static void PrintError(JSONStream* js, const char* format, ...) {
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
  jsobj.AddProperty("text", buffer);
  PrintArgumentsAndOptions(jsobj, js);
}


void Service::HandleIsolateMessage(Isolate* isolate, const Instance& msg) {
  ASSERT(isolate != NULL);
  ASSERT(!msg.IsNull());
  ASSERT(msg.IsGrowableObjectArray());

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    const GrowableObjectArray& message = GrowableObjectArray::Cast(msg);
    // Message is a list with four entries.
    ASSERT(message.Length() == 4);

    Instance& reply_port = Instance::Handle(isolate);
    GrowableObjectArray& path = GrowableObjectArray::Handle(isolate);
    GrowableObjectArray& option_keys = GrowableObjectArray::Handle(isolate);
    GrowableObjectArray& option_values = GrowableObjectArray::Handle(isolate);
    reply_port ^= message.At(0);
    path ^= message.At(1);
    option_keys ^= message.At(2);
    option_values ^= message.At(3);

    ASSERT(!path.IsNull());
    ASSERT(!option_keys.IsNull());
    ASSERT(!option_values.IsNull());
    // Path always has at least one entry in it.
    ASSERT(path.Length() > 0);
    // Same number of option keys as values.
    ASSERT(option_keys.Length() == option_values.Length());

    String& pathSegment = String::Handle();
    pathSegment ^= path.At(0);
    ASSERT(!pathSegment.IsNull());

    IsolateMessageHandler handler =
        FindIsolateMessageHandler(pathSegment.ToCString());
    {
      JSONStream js;
      SetupJSONStream(&js, zone.GetZone(),
                      reply_port, path, option_keys, option_values);
      if (handler == NULL) {
        PrintError(&js, "Unrecognized path");
        PostReply(&js);
      } else {
        if (handler(isolate, &js)) {
          // Handler returns true if the reply is ready to be posted.
          PostReply(&js);
        }
      }
    }
  }
}


static bool HandleName(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "IsolateName");
  jsobj.AddProperty("id", static_cast<intptr_t>(isolate->main_port()));
  jsobj.AddProperty("name", isolate->name());
  return true;
}


static bool HandleStackTrace(Isolate* isolate, JSONStream* js) {
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "StackTrace");
  JSONArray jsarr(&jsobj, "members");
  intptr_t n_frames = stack->Length();
  String& function = String::Handle();
  Script& script = Script::Handle();
  for (int i = 0; i < n_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    script ^= frame->SourceScript();
    function ^= frame->function().UserVisibleName();
    JSONObject jsobj(&jsarr);
    jsobj.AddProperty("name", function.ToCString());
    jsobj.AddProperty("script", script);
    jsobj.AddProperty("line", frame->LineNumber());
    jsobj.AddProperty("function", frame->function());
    jsobj.AddProperty("code", frame->code());
  }
  return true;
}


static bool HandleObjectHistogram(Isolate* isolate, JSONStream* js) {
  ObjectHistogram* histogram = Isolate::Current()->object_histogram();
  if (histogram == NULL) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("text", "Run with --print_object_histogram");
    return true;
  }
  histogram->PrintToJSONStream(js);
  return true;
}


static bool HandleIsolateEcho(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "message");
  PrintArgumentsAndOptions(jsobj, js);
  return true;
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
  func.PrintToJSONStream(js, false);
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
  func.PrintToJSONStream(js, false);
  return true;
}


static bool HandleClassesFunctions(Isolate* isolate, const Class& cls,
                                   JSONStream* js) {
  intptr_t id;
  if (js->num_arguments() > 4) {
    PrintError(js, "Command too long");
    return true;
  }
  if (!GetIntegerId(js->GetArgument(3), &id)) {
    PrintError(js, "Must specify collection object id: functions/id");
    return true;
  }
  Function& func = Function::Handle();
  func ^= cls.FunctionFromIndex(id);
  if (func.IsNull()) {
    PrintError(js, "Function %" Pd " not found", id);
    return true;
  }
  func.PrintToJSONStream(js, false);
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
  func.PrintToJSONStream(js, false);
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
  field.PrintToJSONStream(js, false);
  return true;
}


static bool HandleClasses(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    ClassTable* table = isolate->class_table();
    table->PrintToJSONStream(js);
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
    PrintError(js, "%" Pd " is not a valid class id.", id);;
    return true;
  }
  Class& cls = Class::Handle(table->At(id));
  if (js->num_arguments() == 2) {
    cls.PrintToJSONStream(js, false);
    return true;
  } else if (js->num_arguments() >= 3) {
    const char* second = js->GetArgument(2);
    if (!strcmp(second, "closures")) {
      return HandleClassesClosures(isolate, cls, js);
    } else if (!strcmp(second, "fields")) {
      return HandleClassesFields(isolate, cls, js);
    } else if (!strcmp(second, "functions")) {
      return HandleClassesFunctions(isolate, cls, js);
    } else if (!strcmp(second, "implicit_closures")) {
      return HandleClassesImplicitClosures(isolate, cls, js);
    } else if (!strcmp(second, "dispatchers")) {
      return HandleClassesDispatchers(isolate, cls, js);
    } else {
      PrintError(js, "Invalid sub collection %s", second);
      return true;
    }
  }
  UNREACHABLE();
  return true;
}


static bool HandleLibrary(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    const Library& lib =
        Library::Handle(isolate->object_store()->root_library());
    lib.PrintToJSONStream(js, false);
    return true;
  }
  PrintError(js, "Command too long");
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
  lib.PrintToJSONStream(js, false);
  return true;
}


static bool HandleObjects(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("objects");
  ASSERT(js->num_arguments() >= 2);
  ObjectIdRing* ring = isolate->object_id_ring();
  ASSERT(ring != NULL);
  intptr_t id = -1;
  if (!GetIntegerId(js->GetArgument(1), &id)) {
    Object::null_object().PrintToJSONStream(js, false);
    return true;
  }
  Object& obj = Object::Handle(ring->GetObjectForId(id));
  obj.PrintToJSONStream(js, false);
  return true;
}



static bool HandleScriptsEnumerate(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "ScriptList");
  JSONArray members(&jsobj, "members");
  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  int num_libs = libs.Length();
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


static bool HandleScriptsFetch(Isolate* isolate, JSONStream* js) {
  const GrowableObjectArray& libs =
    GrowableObjectArray::Handle(isolate->object_store()->libraries());
  int num_libs = libs.Length();
  Library &lib = Library::Handle();
  Script& script = Script::Handle();
  String& url = String::Handle();
  const String& id = String::Handle(String::New(js->GetArgument(1)));
  ASSERT(!id.IsNull());
  // The id is the url of the script % encoded, decode it.
  String& requested_url = String::Handle(String::DecodeURI(id));
  for (intptr_t i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    ASSERT(Smi::IsValid(lib.index()));
    const Array& loaded_scripts = Array::Handle(lib.LoadedScripts());
    ASSERT(!loaded_scripts.IsNull());
    intptr_t num_scripts = loaded_scripts.Length();
    for (intptr_t i = 0; i < num_scripts; i++) {
      script ^= loaded_scripts.At(i);
      ASSERT(!script.IsNull());
      url ^= script.url();
      if (url.Equals(requested_url)) {
        script.PrintToJSONStream(js, false);
        return true;
      }
    }
  }
  PrintError(js, "Cannot find script %s\n", requested_url.ToCString());
  return true;
}


static bool HandleScripts(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    // Enumerate all scripts.
    return HandleScriptsEnumerate(isolate, js);
  } else if (js->num_arguments() == 2) {
    // Fetch specific script.
    return HandleScriptsFetch(isolate, js);
  } else {
    PrintError(js, "Command too long");
    return true;
  }
}


static bool HandleDebug(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    PrintError(js, "Must specify a subcommand");
    return true;
  }
  const char* command = js->GetArgument(1);
  if (!strcmp(command, "breakpoints")) {
    if (js->num_arguments() == 2) {
      // Print breakpoint list.
      JSONObject jsobj(js);
      jsobj.AddProperty("type", "BreakpointList");
      JSONArray jsarr(&jsobj, "breakpoints");
      isolate->debugger()->PrintBreakpointsToJSONArray(&jsarr);
      return true;
    } else if (js->num_arguments() == 3) {
      // Print individual breakpoint.
      intptr_t id = 0;
      SourceBreakpoint* bpt = NULL;
      if (GetIntegerId(js->GetArgument(2), &id)) {
        bpt = isolate->debugger()->GetBreakpointById(id);
      }
      if (bpt != NULL) {
        bpt->PrintToJSONStream(js);
        return true;
      } else {
        PrintError(js, "Unrecognized breakpoint id %s", js->GetArgument(2));
        return true;
      }
    } else {
      PrintError(js, "Command too long");
      return true;
    }
  } else {
    PrintError(js, "Unrecognized subcommand '%s'", js->GetArgument(1));
    return true;
  }
}


static bool HandleCode(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("code");
  uintptr_t pc;
  if (!GetUnsignedIntegerId(js->GetArgument(1), &pc, 16)) {
    PrintError(js, "Must specify code address: code/c0deadd0.");
    return true;
  }
  Code& code = Code::Handle(Code::LookupCode(pc));
  if (code.IsNull()) {
    PrintError(js, "Could not find code at %" Px "", pc);
    return true;
  }
  code.PrintToJSONStream(js, false);
  return true;
}


static bool HandleProfile(Isolate* isolate, JSONStream* js) {
  Profiler::PrintToJSONStream(isolate, js, true);
  return true;
}

static bool HandleCoverage(Isolate* isolate, JSONStream* js) {
  CodeCoverage::PrintToJSONStream(isolate, js);
  return true;
}


static bool HandleAllocationProfile(Isolate* isolate, JSONStream* js) {
  isolate->class_table()->AllocationProfilePrintToJSONStream(js);
  return true;
}


static IsolateMessageHandlerEntry isolate_handlers[] = {
  { "_echo", HandleIsolateEcho },
  { "allocationprofile", HandleAllocationProfile },
  { "classes", HandleClasses },
  { "code", HandleCode },
  { "coverage", HandleCoverage },
  { "debug", HandleDebug },
  { "libraries", HandleLibraries },
  { "library", HandleLibrary },
  { "name", HandleName },
  { "objecthistogram", HandleObjectHistogram},
  { "objects", HandleObjects },
  { "profile", HandleProfile },
  { "scripts", HandleScripts },
  { "stacktrace", HandleStackTrace },
};


static IsolateMessageHandler FindIsolateMessageHandler(const char* command) {
  intptr_t num_message_handlers = sizeof(isolate_handlers) /
                                  sizeof(isolate_handlers[0]);
  for (intptr_t i = 0; i < num_message_handlers; i++) {
    const IsolateMessageHandlerEntry& entry = isolate_handlers[i];
    if (!strcmp(command, entry.command)) {
      return entry.handler;
    }
  }
  return NULL;
}


void Service::HandleRootMessage(const Instance& msg) {
  Isolate* isolate = Isolate::Current();
  ASSERT(!msg.IsNull());
  ASSERT(msg.IsGrowableObjectArray());

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);

    const GrowableObjectArray& message = GrowableObjectArray::Cast(msg);
    // Message is a list with four entries.
    ASSERT(message.Length() == 4);

    Instance& reply_port = Instance::Handle(isolate);
    GrowableObjectArray& path = GrowableObjectArray::Handle(isolate);
    GrowableObjectArray& option_keys = GrowableObjectArray::Handle(isolate);
    GrowableObjectArray& option_values = GrowableObjectArray::Handle(isolate);
    reply_port ^= message.At(0);
    path ^= message.At(1);
    option_keys ^= message.At(2);
    option_values ^= message.At(3);

    ASSERT(!path.IsNull());
    ASSERT(!option_keys.IsNull());
    ASSERT(!option_values.IsNull());
    // Path always has at least one entry in it.
    ASSERT(path.Length() > 0);
    // Same number of option keys as values.
    ASSERT(option_keys.Length() == option_values.Length());

    String& pathSegment = String::Handle();
    pathSegment ^= path.At(0);
    ASSERT(!pathSegment.IsNull());

    RootMessageHandler handler =
        FindRootMessageHandler(pathSegment.ToCString());
    {
      JSONStream js;
      SetupJSONStream(&js, zone.GetZone(),
                      reply_port, path, option_keys, option_values);
      if (handler == NULL) {
        PrintError(&js, "Unrecognized path");
        PostReply(&js);
      } else {
        if (handler(&js)) {
          // Handler returns true if the reply is ready to be posted.
          PostReply(&js);
        }
      }
    }
  }
}


static bool HandleRootEcho(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "message");
  PrintArgumentsAndOptions(jsobj, js);
  return true;
}


static bool HandleCpu(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "CPU");
  jsobj.AddProperty("architecture", CPU::Id());
  return true;
}


static RootMessageHandlerEntry root_handlers[] = {
  { "_echo", HandleRootEcho },
  { "cpu", HandleCpu },
};


static RootMessageHandler FindRootMessageHandler(const char* command) {
  intptr_t num_message_handlers = sizeof(root_handlers) /
                                  sizeof(root_handlers[0]);
  for (intptr_t i = 0; i < num_message_handlers; i++) {
    const RootMessageHandlerEntry& entry = root_handlers[i];
    if (!strcmp(command, entry.command)) {
      return entry.handler;
    }
  }
  return NULL;
}

}  // namespace dart
