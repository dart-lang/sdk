// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service_isolate.h"

#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/service.h"
#include "vm/symbols.h"
#include "vm/thread_pool.h"

namespace dart {

DEFINE_FLAG(bool, trace_service, false, "Trace VM service requests.");
DEFINE_FLAG(bool, trace_service_pause_events, false,
            "Trace VM service isolate pause events.");

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


static Dart_Port ExtractPort(Isolate* isolate, Dart_Handle receivePort) {
  const ReceivePort& rp = Api::UnwrapReceivePortHandle(isolate, receivePort);
  if (rp.IsNull()) {
    return ILLEGAL_PORT;
  }
  return rp.Id();
}


// These must be kept in sync with service/constants.dart
#define VM_SERVICE_ISOLATE_EXIT_MESSAGE_ID 0
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


static RawArray* MakeServiceExitMessage() {
  const Array& list = Array::Handle(Array::New(1));
  ASSERT(!list.IsNull());
  const intptr_t code = VM_SERVICE_ISOLATE_EXIT_MESSAGE_ID;
  const Integer& code_int = Integer::Handle(Integer::New(code));
  list.SetAt(0, code_int);
  return list.raw();
}


const char* ServiceIsolate::kName = "vm-service";
Isolate* ServiceIsolate::isolate_ = NULL;
Dart_Port ServiceIsolate::port_ = ILLEGAL_PORT;
Dart_Port ServiceIsolate::load_port_ = ILLEGAL_PORT;
Dart_Port ServiceIsolate::origin_ = ILLEGAL_PORT;
Dart_IsolateCreateCallback ServiceIsolate::create_callback_ = NULL;
uint8_t* ServiceIsolate::exit_message_ = NULL;
intptr_t ServiceIsolate::exit_message_length_ = 0;
Monitor* ServiceIsolate::monitor_ = NULL;
bool ServiceIsolate::initializing_ = true;
bool ServiceIsolate::shutting_down_ = false;


class RegisterRunningIsolatesVisitor : public IsolateVisitor {
 public:
  explicit RegisterRunningIsolatesVisitor(Isolate* service_isolate)
      : IsolateVisitor(),
        register_function_(Function::Handle(service_isolate)),
        service_isolate_(service_isolate) {
    ASSERT(ServiceIsolate::IsServiceIsolate(Isolate::Current()));
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
    ASSERT(ServiceIsolate::IsServiceIsolate(Isolate::Current()));
    if (ServiceIsolate::IsServiceIsolateDescendant(isolate) ||
        (isolate == Dart::vm_isolate())) {
      // We do not register the service (and descendants) or the vm-isolate.
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
    if (FLAG_trace_service) {
      OS::Print("vm-service: Isolate %s %" Pd64 " registered.\n",
                name.ToCString(),
                port_id);
    }
    ASSERT(!r.IsError());
  }

 private:
  Function& register_function_;
  Isolate* service_isolate_;
};



class ServiceIsolateNatives : public AllStatic {
 public:
  static void SendIsolateServiceMessage(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone stack_zone(isolate);
    Zone* zone = stack_zone.GetZone();  // Used by GET_NON_NULL_NATIVE_ARGUMENT.
    HANDLESCOPE(isolate);
    GET_NON_NULL_NATIVE_ARGUMENT(SendPort, sp, arguments->NativeArgAt(0));
    GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(1));

    // Set the type of the OOB message.
    message.SetAt(0, Smi::Handle(isolate, Smi::New(Message::kServiceOOBMsg)));

    // Serialize message.
    uint8_t* data = NULL;
    MessageWriter writer(&data, &allocator, false);
    writer.WriteMessage(message);

    // TODO(turnidge): Throw an exception when the return value is false?
    bool result = PortMap::PostMessage(
        new Message(sp.Id(), data, writer.BytesWritten(),
                    Message::kOOBPriority));
    arguments->SetReturn(Bool::Get(result));
  }

  static void SendRootServiceMessage(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone stack_zone(isolate);
    Zone* zone = stack_zone.GetZone();  // Used by GET_NON_NULL_NATIVE_ARGUMENT.
    HANDLESCOPE(isolate);
    GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
    Service::HandleRootMessage(message);
  }

  static void OnStart(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    {
      if (FLAG_trace_service) {
        OS::Print("vm-service: Booting dart:vmservice library.\n");
      }
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
      ServiceIsolate::SetServicePort(port);
      Dart_ExitScope();
    }

    {
      if (FLAG_trace_service) {
        OS::Print("vm-service: Registering running isolates.\n");
      }
      // Register running isolates with service.
      RegisterRunningIsolatesVisitor register_isolates(isolate);
      Isolate::VisitIsolates(&register_isolates);
    }
  }

  static void OnExit(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    {
      if (FLAG_trace_service) {
        OS::Print("vm-service: processed exit message.\n");
      }
    }
  }

  static void ListenStream(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone stack_zone(isolate);
    Zone* zone = stack_zone.GetZone();  // Used by GET_NON_NULL_NATIVE_ARGUMENT.
    HANDLESCOPE(isolate);
    GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
    bool result = Service::ListenStream(stream_id.ToCString());
    arguments->SetReturn(Bool::Get(result));
  }

  static void CancelStream(Dart_NativeArguments args) {
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
    Isolate* isolate = arguments->thread()->isolate();
    StackZone stack_zone(isolate);
    Zone* zone = stack_zone.GetZone();  // Used by GET_NON_NULL_NATIVE_ARGUMENT.
    HANDLESCOPE(isolate);
    GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
    Service::CancelStream(stream_id.ToCString());
  }
};


struct ServiceNativeEntry {
  const char* name;
  int num_arguments;
  Dart_NativeFunction function;
};


static ServiceNativeEntry _ServiceNativeEntries[] = {
  {"VMService_SendIsolateServiceMessage", 2,
    ServiceIsolateNatives::SendIsolateServiceMessage},
  {"VMService_SendRootServiceMessage", 1,
    ServiceIsolateNatives::SendRootServiceMessage},
  {"VMService_OnStart", 0,
    ServiceIsolateNatives::OnStart },
  {"VMService_OnExit", 0,
    ServiceIsolateNatives::OnExit },
  {"VMService_ListenStream", 1,
    ServiceIsolateNatives::ListenStream },
  {"VMService_CancelStream", 1,
    ServiceIsolateNatives::CancelStream },
};


static Dart_NativeFunction ServiceNativeResolver(Dart_Handle name,
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
  intptr_t n = sizeof(_ServiceNativeEntries) /
               sizeof(_ServiceNativeEntries[0]);
  for (intptr_t i = 0; i < n; i++) {
    ServiceNativeEntry entry = _ServiceNativeEntries[i];
    if ((strcmp(function_name, entry.name) == 0) &&
        (num_arguments == entry.num_arguments)) {
      return entry.function;
    }
  }
  return NULL;
}


bool ServiceIsolate::NameEquals(const char* name) {
  ASSERT(name != NULL);
  return strcmp(name, kName) == 0;
}


bool ServiceIsolate::Exists() {
  MonitorLocker ml(monitor_);
  return isolate_ != NULL;
}


bool ServiceIsolate::IsRunning() {
  MonitorLocker ml(monitor_);
  return (port_ != ILLEGAL_PORT) && (isolate_ != NULL);
}


bool ServiceIsolate::IsServiceIsolate(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  return isolate == isolate_;
}


bool ServiceIsolate::IsServiceIsolateDescendant(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  return isolate->origin_id() == origin_;
}


Dart_Port ServiceIsolate::Port() {
  MonitorLocker ml(monitor_);
  return port_;
}


Dart_Port ServiceIsolate::WaitForLoadPort() {
  MonitorLocker ml(monitor_);

  while (initializing_ && (load_port_ == ILLEGAL_PORT)) {
    ml.Wait();
  }

  return load_port_;
}


Dart_Port ServiceIsolate::LoadPort() {
  MonitorLocker ml(monitor_);
  return load_port_;
}


bool ServiceIsolate::SendIsolateStartupMessage() {
  if (!IsRunning()) {
    return false;
  }
  Isolate* isolate = Isolate::Current();
  if (IsServiceIsolateDescendant(isolate)) {
    return false;
  }
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
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("vm-service: Isolate %s %" Pd64 " registered.\n",
              name.ToCString(),
              Dart_GetMainPortId());
  }
  return PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
}


bool ServiceIsolate::SendIsolateShutdownMessage() {
  if (!IsRunning()) {
    return false;
  }
  Isolate* isolate = Isolate::Current();
  if (IsServiceIsolateDescendant(isolate)) {
    return false;
  }
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
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(list);
  intptr_t len = writer.BytesWritten();
  if (FLAG_trace_service) {
    OS::Print("vm-service: Isolate %s %" Pd64 " deregistered.\n",
              name.ToCString(),
              Dart_GetMainPortId());
  }
  return PortMap::PostMessage(
      new Message(port_, data, len, Message::kNormalPriority));
}


void ServiceIsolate::SendServiceExitMessage() {
  if (!IsRunning()) {
    return;
  }
  if ((exit_message_ == NULL) || (exit_message_length_ == 0)) {
    return;
  }
  if (FLAG_trace_service) {
    OS::Print("vm-service: sending service exit message.\n");
  }
  PortMap::PostMessage(new Message(port_,
                                   exit_message_,
                                   exit_message_length_,
                                   Message::kNormalPriority));
}


void ServiceIsolate::SetServicePort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  port_ = port;
}


void ServiceIsolate::SetServiceIsolate(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  isolate_ = isolate;
  if (isolate_ != NULL) {
    isolate_->is_service_isolate_ = true;
    origin_ = isolate_->origin_id();
  } else {
    origin_ = ILLEGAL_PORT;
  }
}

void ServiceIsolate::SetLoadPort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  load_port_ = port;
}


void ServiceIsolate::MaybeInjectVMServiceLibrary(Isolate* isolate) {
  ASSERT(isolate != NULL);
  ASSERT(isolate->name() != NULL);
  if (!ServiceIsolate::NameEquals(isolate->name())) {
    // Not service isolate.
    return;
  }
  if (Exists()) {
    // Service isolate already exists.
    return;
  }
  SetServiceIsolate(isolate);

  StackZone zone(isolate);
  HANDLESCOPE(isolate);

  // Register dart:vmservice library.
  const String& url_str = String::Handle(Symbols::DartVMService().raw());
  const Library& library = Library::Handle(Library::New(url_str));
  library.Register();
  library.set_native_entry_resolver(ServiceNativeResolver);

  // Temporarily install our library tag handler.
  isolate->set_library_tag_handler(LibraryTagHandler);

  // Get script source.
  const char* resource = NULL;
  const char* path = "/vmservice.dart";
  intptr_t r = Resources::ResourceLookup(path, &resource);
  ASSERT(r != Resources::kNoSuchInstance);
  ASSERT(resource != NULL);
  const String& source_str = String::Handle(
      String::FromUTF8(reinterpret_cast<const uint8_t*>(resource), r));
  ASSERT(!source_str.IsNull());
  const Script& script = Script::Handle(
    isolate, Script::New(url_str, source_str, RawScript::kLibraryTag));

  // Compile script.
  Dart_EnterScope();  // Need to enter scope for tag handler.
  library.SetLoadInProgress();
  const Error& error = Error::Handle(isolate,
                                     Compiler::Compile(library, script));
  if (!error.IsNull()) {
    OS::PrintErr("vm-service: Isolate creation error: %s\n",
          error.ToErrorCString());
  }
  ASSERT(error.IsNull());
  Dart_Handle result = Dart_FinalizeLoading(false);
  ASSERT(!Dart_IsError(result));
  Dart_ExitScope();

  // Uninstall our library tag handler.
  isolate->set_library_tag_handler(NULL);
}


void ServiceIsolate::ConstructExitMessageAndCache(Isolate* isolate) {
  // Construct and cache exit message here so we can send it without needing an
  // isolate.
  StartIsolateScope iso_scope(isolate);
  StackZone zone(isolate);
  HANDLESCOPE(isolate);
  ASSERT(exit_message_ == NULL);
  ASSERT(exit_message_length_ == 0);
  const Array& list = Array::Handle(MakeServiceExitMessage());
  ASSERT(!list.IsNull());
  MessageWriter writer(&exit_message_, &allocator, false);
  writer.WriteMessage(list);
  exit_message_length_ = writer.BytesWritten();
  ASSERT(exit_message_ != NULL);
  ASSERT(exit_message_length_ != 0);
}


void ServiceIsolate::FinishedExiting() {
  MonitorLocker ml(monitor_);
  shutting_down_ = false;
  ml.NotifyAll();
}


void ServiceIsolate::FinishedInitializing() {
  MonitorLocker ml(monitor_);
  initializing_ = false;
  ml.NotifyAll();
}


class RunServiceTask : public ThreadPool::Task {
 public:
  virtual void Run() {
    ASSERT(Isolate::Current() == NULL);
    TimelineDurationScope tds(Timeline::GetVMStream(),
                              "ServiceIsolateStartup");
    char* error = NULL;
    Isolate* isolate = NULL;

    Dart_IsolateCreateCallback create_callback =
        ServiceIsolate::create_callback();
    // TODO(johnmccutchan): Support starting up service isolate without embedder
    // provided isolate creation callback.
    if (create_callback == NULL) {
      ServiceIsolate::FinishedInitializing();
      return;
    }

    Isolate::Flags default_flags;
    Dart_IsolateFlags api_flags;
    default_flags.CopyTo(&api_flags);

    isolate =
        reinterpret_cast<Isolate*>(create_callback(ServiceIsolate::kName,
                                                   NULL,
                                                   NULL,
                                                   &api_flags,
                                                   NULL,
                                                   &error));
    if (isolate == NULL) {
      OS::PrintErr("vm-service: Isolate creation error: %s\n", error);
      ServiceIsolate::FinishedInitializing();
      return;
    }


    Thread::ExitIsolate();

    ServiceIsolate::ConstructExitMessageAndCache(isolate);

    RunMain(isolate);

    ServiceIsolate::FinishedInitializing();

    isolate->message_handler()->Run(Dart::thread_pool(),
                                    NULL,
                                    ShutdownIsolate,
                                    reinterpret_cast<uword>(isolate));
  }

 protected:
  static void ShutdownIsolate(uword parameter) {
    Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
    ASSERT(ServiceIsolate::IsServiceIsolate(isolate));
    {
      // Print the error if there is one.  This may execute dart code to
      // print the exception object, so we need to use a StartIsolateScope.
      StartIsolateScope start_scope(isolate);
      StackZone zone(isolate);
      HandleScope handle_scope(isolate);
      Error& error = Error::Handle();
      error = isolate->object_store()->sticky_error();
      if (!error.IsNull()) {
        OS::PrintErr("vm-service: Error: %s\n", error.ToErrorCString());
      }
      Dart::RunShutdownCallback();
    }
    {
      // Shut the isolate down.
      SwitchIsolateScope switch_scope(isolate);
      Dart::ShutdownIsolate();
    }
    ServiceIsolate::SetServiceIsolate(NULL);
    ServiceIsolate::SetServicePort(ILLEGAL_PORT);
    if (FLAG_trace_service) {
      OS::Print("vm-service: Shutdown.\n");
    }
    ServiceIsolate::FinishedExiting();
  }

  void RunMain(Isolate* isolate) {
    StartIsolateScope iso_scope(isolate);
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    // Invoke main which will return the loadScriptPort.
    const Library& root_library =
        Library::Handle(isolate, isolate->object_store()->root_library());
    if (root_library.IsNull()) {
      if (FLAG_trace_service) {
        OS::Print("vm-service: Embedder did not install a script.");
      }
      // Service isolate is not supported by embedder.
      return;
    }
    ASSERT(!root_library.IsNull());
    const String& entry_name = String::Handle(isolate, String::New("main"));
    ASSERT(!entry_name.IsNull());
    const Function& entry =
        Function::Handle(isolate,
                         root_library.LookupFunctionAllowPrivate(entry_name));
    if (entry.IsNull()) {
      // Service isolate is not supported by embedder.
      if (FLAG_trace_service) {
        OS::Print("vm-service: Embedder did not provide a main function.");
      }
      return;
    }
    ASSERT(!entry.IsNull());
    const Object& result =
        Object::Handle(isolate,
                       DartEntry::InvokeFunction(entry,
                                                 Object::empty_array()));
    ASSERT(!result.IsNull());
    if (result.IsError()) {
      // Service isolate did not initialize properly.
      if (FLAG_trace_service) {
        const Error& error = Error::Cast(result);
        OS::Print("vm-service: Calling main resulted in an error: %s",
                  error.ToErrorCString());
      }
      return;
    }
    ASSERT(result.IsReceivePort());
    const ReceivePort& rp = ReceivePort::Cast(result);
    ServiceIsolate::SetLoadPort(rp.Id());
  }
};


void ServiceIsolate::Run() {
  ASSERT(monitor_ == NULL);
  monitor_ = new Monitor();
  ASSERT(monitor_ != NULL);
  // Grab the isolate create callback here to avoid race conditions with tests
  // that change this after Dart_Initialize returns.
  create_callback_ = Isolate::CreateCallback();
  Dart::thread_pool()->Run(new RunServiceTask());
}


void ServiceIsolate::Shutdown() {
  if (!IsRunning()) {
    return;
  }
  {
    MonitorLocker ml(monitor_);
    shutting_down_ = true;
  }
  SendServiceExitMessage();
  {
    MonitorLocker ml(monitor_);
    while (shutting_down_ && (port_ != ILLEGAL_PORT)) {
      ml.Wait();
    }
  }
}


Dart_Handle ServiceIsolate::GetSource(const char* name) {
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
  FATAL1("vm-service: Could not find embedded source file: %s ", name);
  return Dart_Null();
}


Dart_Handle ServiceIsolate::LibraryTagHandler(Dart_LibraryTag tag,
                                              Dart_Handle library,
                                              Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    // url is already canonicalized.
    return url;
  }
  if (tag != Dart_kSourceTag) {
    FATAL("ServiceIsolate::LibraryTagHandler encountered an unexpected tag.");
  }
  ASSERT(tag == Dart_kSourceTag);
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  Dart_Handle source = GetSource(url_string);
  if (Dart_IsError(source)) {
    return source;
  }
  return Dart_LoadSource(library, url, source, 0, 0);
}

}  // namespace dart
