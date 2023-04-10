// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service_isolate.h"

#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/service.h"
#include "vm/symbols.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"

#if !defined(PRODUCT)

namespace dart {

#define Z (T->zone())

DEFINE_FLAG(bool, trace_service, false, "Trace VM service requests.");
DEFINE_FLAG(bool,
            trace_service_pause_events,
            false,
            "Trace VM service isolate pause events.");
DEFINE_FLAG(bool,
            trace_service_verbose,
            false,
            "Provide extra service tracing information.");

// These must be kept in sync with service/constants.dart
#define VM_SERVICE_ISOLATE_EXIT_MESSAGE_ID 0
#define VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID 1
#define VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID 2

#define VM_SERVICE_WEB_SERVER_CONTROL_MESSAGE_ID 3
#define VM_SERVICE_SERVER_INFO_MESSAGE_ID 4

#define VM_SERVICE_METHOD_CALL_FROM_NATIVE 5

bool ServiceIsolate::SendServiceControlMessage(Thread* thread,
                                               Dart_Port port_id,
                                               intptr_t code,
                                               const char* name) {
  Dart_CObject ccode;
  ccode.type = Dart_CObject_kInt32;
  ccode.value.as_int32 = code;

  Dart_CObject port_int;
  port_int.type = Dart_CObject_kInt64;
  port_int.value.as_int64 = port_id;

  Dart_CObject send_port;
  send_port.type = Dart_CObject_kSendPort;
  send_port.value.as_send_port.id = port_id;
  send_port.value.as_send_port.origin_id = port_id;

  Dart_CObject cname;
  cname.type = Dart_CObject_kString;
  cname.value.as_string = const_cast<char*>(name);

  Dart_CObject* values[4];
  values[0] = &ccode;
  values[1] = &port_int;
  values[2] = &send_port;
  values[3] = &cname;

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  message.value.as_array.length = 4;
  message.value.as_array.values = values;

  return PortMap::PostMessage(WriteApiMessage(thread->zone(), &message, port_,
                                              Message::kNormalPriority));
}

static ArrayPtr MakeServerControlMessage(const SendPort& sp,
                                         intptr_t code,
                                         bool enable,
                                         const Bool& silenceOutput) {
  const Array& list = Array::Handle(Array::New(4));
  ASSERT(!list.IsNull());
  list.SetAt(0, Integer::Handle(Integer::New(code)));
  list.SetAt(1, sp);
  list.SetAt(2, Bool::Get(enable));
  list.SetAt(3, silenceOutput);
  return list.ptr();
}

const char* ServiceIsolate::kName = DART_VM_SERVICE_ISOLATE_NAME;
Dart_IsolateGroupCreateCallback ServiceIsolate::create_group_callback_ =
    nullptr;
Monitor* ServiceIsolate::monitor_ = new Monitor();
ServiceIsolate::State ServiceIsolate::state_ = ServiceIsolate::kStopped;
Isolate* ServiceIsolate::isolate_ = nullptr;
Dart_Port ServiceIsolate::port_ = ILLEGAL_PORT;
Dart_Port ServiceIsolate::origin_ = ILLEGAL_PORT;
char* ServiceIsolate::server_address_ = nullptr;
char* ServiceIsolate::startup_failure_reason_ = nullptr;

void ServiceIsolate::RequestServerInfo(const SendPort& sp) {
  const Array& message = Array::Handle(MakeServerControlMessage(
      sp, VM_SERVICE_SERVER_INFO_MESSAGE_ID, false /* ignored */,
      Bool::Handle() /* ignored */));
  ASSERT(!message.IsNull());
  PortMap::PostMessage(WriteMessage(/* same_group */ false, message, port_,
                                    Message::kNormalPriority));
}

void ServiceIsolate::ControlWebServer(const SendPort& sp,
                                      bool enable,
                                      const Bool& silenceOutput) {
  const Array& message = Array::Handle(MakeServerControlMessage(
      sp, VM_SERVICE_WEB_SERVER_CONTROL_MESSAGE_ID, enable, silenceOutput));
  ASSERT(!message.IsNull());
  PortMap::PostMessage(WriteMessage(/* same_group */ false, message, port_,
                                    Message::kNormalPriority));
}

void ServiceIsolate::SetServerAddress(const char* address) {
  if (server_address_ != nullptr) {
    free(server_address_);
    server_address_ = nullptr;
  }
  if (address == nullptr) {
    return;
  }
  server_address_ = Utils::StrDup(address);
}

bool ServiceIsolate::NameEquals(const char* name) {
  ASSERT(name != nullptr);
  return strcmp(name, kName) == 0;
}

bool ServiceIsolate::Exists() {
  MonitorLocker ml(monitor_);
  return isolate_ != nullptr;
}

bool ServiceIsolate::IsRunning() {
  MonitorLocker ml(monitor_);
  return (port_ != ILLEGAL_PORT) && (isolate_ != nullptr);
}

bool ServiceIsolate::IsServiceIsolate(const Isolate* isolate) {
  MonitorLocker ml(monitor_);
  return isolate != nullptr && isolate == isolate_;
}

bool ServiceIsolate::IsServiceIsolateDescendant(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  return isolate->origin_id() == origin_;
}

Dart_Port ServiceIsolate::Port() {
  MonitorLocker ml(monitor_);
  return port_;
}

void ServiceIsolate::WaitForServiceIsolateStartup() {
  MonitorLocker ml(monitor_);
  while (state_ == kStarting) {
    ml.Wait();
  }
}

bool ServiceIsolate::SendServiceRpc(uint8_t* request_json,
                                    intptr_t request_json_length,
                                    Dart_Port reply_port,
                                    char** error) {
  // Keep in sync with "sdk/lib/vmservice/vmservice.dart:_handleNativeRpcCall".
  Dart_CObject opcode;
  opcode.type = Dart_CObject_kInt32;
  opcode.value.as_int32 = VM_SERVICE_METHOD_CALL_FROM_NATIVE;

  Dart_CObject message;
  message.type = Dart_CObject_kTypedData;
  message.value.as_typed_data.type = Dart_TypedData_kUint8;
  message.value.as_typed_data.length = request_json_length;
  message.value.as_typed_data.values = request_json;

  Dart_CObject send_port;
  send_port.type = Dart_CObject_kSendPort;
  send_port.value.as_send_port.id = reply_port;
  send_port.value.as_send_port.origin_id = ILLEGAL_PORT;

  Dart_CObject* request_array[] = {
      &opcode,
      &message,
      &send_port,
  };

  Dart_CObject request;
  request.type = Dart_CObject_kArray;
  request.value.as_array.values = request_array;
  request.value.as_array.length = ARRAY_SIZE(request_array);
  ServiceIsolate::WaitForServiceIsolateStartup();
  Dart_Port service_port = ServiceIsolate::Port();
  bool success = false;
  if (service_port != ILLEGAL_PORT) {
    success = Dart_PostCObject(service_port, &request);
    if (!success && error != nullptr) {
      *error = Utils::StrDup("Was unable to post message to service isolate.");
    }
  } else {
    if (error != nullptr) {
      if (startup_failure_reason_ != nullptr) {
        *error = OS::SCreate(/*zone=*/nullptr,
                             "Service isolate failed to start up: %s.",
                             startup_failure_reason_);
      } else {
        *error = Utils::StrDup("No service isolate port was found.");
      }
    }
  }
  return success;
}

bool ServiceIsolate::SendIsolateStartupMessage() {
  if (!IsRunning()) {
    return false;
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  if (Dart::VmIsolateNameEquals(isolate->name())) {
    return false;
  }

  Dart_Port main_port = Dart_GetMainPortId();
  if (FLAG_trace_service) {
    OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME ": Isolate %s %" Pd64
                                              " registered.\n",
                 isolate->name(), main_port);
  }
  bool result = SendServiceControlMessage(thread, main_port,
                                          VM_SERVICE_ISOLATE_STARTUP_MESSAGE_ID,
                                          isolate->name());
  isolate->set_is_service_registered(true);
  return result;
}

bool ServiceIsolate::SendIsolateShutdownMessage() {
  if (!IsRunning()) {
    return false;
  }
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  if (Dart::VmIsolateNameEquals(isolate->name())) {
    return false;
  }

  Dart_Port main_port = Dart_GetMainPortId();
  if (FLAG_trace_service) {
    OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME ": Isolate %s %" Pd64
                                              " deregistered.\n",
                 isolate->name(), main_port);
  }

  return SendServiceControlMessage(thread, main_port,
                                   VM_SERVICE_ISOLATE_SHUTDOWN_MESSAGE_ID,
                                   isolate->name());
}

void ServiceIsolate::SendServiceExitMessage() {
  if (!IsRunning()) {
    return;
  }
  if (FLAG_trace_service) {
    OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME
                 ": sending service exit message.\n");
  }

  Dart_CObject code;
  code.type = Dart_CObject_kInt32;
  code.value.as_int32 = VM_SERVICE_ISOLATE_EXIT_MESSAGE_ID;
  Dart_CObject* values[1] = {&code};

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  message.value.as_array.length = 1;
  message.value.as_array.values = values;

  AllocOnlyStackZone zone;
  PortMap::PostMessage(WriteApiMessage(zone.GetZone(), &message, port_,
                                       Message::kNormalPriority));
}

void ServiceIsolate::SetServicePort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  port_ = port;
}

void ServiceIsolate::SetServiceIsolate(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  isolate_ = isolate;
  if (isolate_ != nullptr) {
    isolate_->set_is_service_isolate(true);
    origin_ = isolate_->origin_id();
  }
}

void ServiceIsolate::MaybeMakeServiceIsolate(Isolate* I) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != nullptr);
  ASSERT(I->name() != nullptr);
  if (!ServiceIsolate::NameEquals(I->name())) {
    // Not service isolate.
    return;
  }
  if (Exists()) {
    // Service isolate already exists.
    return;
  }
  SetServiceIsolate(I);
}

void ServiceIsolate::FinishedExiting() {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarted || state_ == kStopping);
  state_ = kStopped;
  port_ = ILLEGAL_PORT;
  isolate_ = nullptr;
  ml.NotifyAll();
}

void ServiceIsolate::FinishedInitializing() {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarting);
  state_ = kStarted;
  ml.NotifyAll();
}

void ServiceIsolate::InitializingFailed(char* error) {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarting);
  state_ = kStopped;
  port_ = ILLEGAL_PORT;
  startup_failure_reason_ = error;
  ml.NotifyAll();
}

class RunServiceTask : public ThreadPool::Task {
 public:
  virtual void Run() {
    ASSERT(Isolate::Current() == nullptr);
#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(Timeline::GetVMStream(),
                               "ServiceIsolateStartup");
#endif  // SUPPORT_TIMELINE
    char* error = nullptr;
    Isolate* isolate = nullptr;

    const auto create_group_callback = ServiceIsolate::create_group_callback();
    ASSERT(create_group_callback != nullptr);

    Dart_IsolateFlags api_flags;
    Isolate::FlagsInitialize(&api_flags);
    api_flags.is_system_isolate = true;
    isolate = reinterpret_cast<Isolate*>(
        create_group_callback(ServiceIsolate::kName, ServiceIsolate::kName,
                              nullptr, nullptr, &api_flags, nullptr, &error));
    if (isolate == nullptr) {
      if (FLAG_trace_service) {
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME
                     ": Isolate creation error: %s\n",
                     error);
      }

      char* formatted_error = OS::SCreate(
          /*zone=*/nullptr, "Invoking the 'create_group' failed with: '%s'",
          error);

      free(error);
      error = nullptr;
      ServiceIsolate::InitializingFailed(formatted_error);
      return;
    }

    bool got_unwind;
    {
      ASSERT(Isolate::Current() == nullptr);
      StartIsolateScope start_scope(isolate);
      got_unwind = RunMain(isolate);
    }

    // FinishedInitializing should be called irrespective of whether
    // running main caused an error or not. Otherwise, other isolates
    // waiting for service isolate to come up will deadlock.
    ServiceIsolate::FinishedInitializing();

    if (got_unwind) {
      ShutdownIsolate(reinterpret_cast<uword>(isolate));
      return;
    }

    isolate->message_handler()->Run(isolate->group()->thread_pool(), nullptr,
                                    ShutdownIsolate,
                                    reinterpret_cast<uword>(isolate));
  }

 protected:
  static void ShutdownIsolate(uword parameter) {
    if (FLAG_trace_service) {
      OS::PrintErr("vm-service: ShutdownIsolate\n");
    }
    Dart_EnterIsolate(reinterpret_cast<Dart_Isolate>(parameter));
    {
      auto T = Thread::Current();
      TransitionNativeToVM transition(T);
      StackZone zone(T);
      HandleScope handle_scope(T);

      auto I = T->isolate();
      ASSERT(ServiceIsolate::IsServiceIsolate(I));

      // Print the error if there is one.  This may execute dart code to
      // print the exception object, so we need to use a StartIsolateScope.
      Error& error = Error::Handle(Z);
      error = T->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME ": Error: %s\n",
                     error.ToErrorCString());
      }
      error = I->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME ": Error: %s\n",
                     error.ToErrorCString());
      }
    }
    Dart_ShutdownIsolate();
    if (FLAG_trace_service) {
      OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME ": Shutdown.\n");
    }
    ServiceIsolate::FinishedExiting();
  }

  bool RunMain(Isolate* I) {
    Thread* T = Thread::Current();
    ASSERT(I == T->isolate());
    StackZone zone(T);
    // Invoke main which will set up the service port.
    const Library& root_library =
        Library::Handle(Z, I->group()->object_store()->root_library());
    if (root_library.IsNull()) {
      if (FLAG_trace_service) {
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME
                     ": Embedder did not install a script.");
      }
      // Service isolate is not supported by embedder.
      return false;
    }
    ASSERT(!root_library.IsNull());
    const String& entry_name = String::Handle(Z, String::New("main"));
    ASSERT(!entry_name.IsNull());
    const Function& entry = Function::Handle(
        Z, root_library.LookupFunctionAllowPrivate(entry_name));
    if (entry.IsNull()) {
      // Service isolate is not supported by embedder.
      if (FLAG_trace_service) {
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME
                     ": Embedder did not provide a main function.");
      }
      return false;
    }
    ASSERT(!entry.IsNull());
    const Object& result = Object::Handle(
        Z, DartEntry::InvokeFunction(entry, Object::empty_array()));
    if (result.IsError()) {
      // Service isolate did not initialize properly.
      if (FLAG_trace_service) {
        const Error& error = Error::Cast(result);
        OS::PrintErr(DART_VM_SERVICE_ISOLATE_NAME
                     ": Calling main resulted in an error: %s",
                     error.ToErrorCString());
      }
      if (result.IsUnwindError()) {
        return true;
      }
      return false;
    }
    return false;
  }
};

void ServiceIsolate::Run() {
  {
    MonitorLocker ml(monitor_);
    ASSERT(state_ == kStopped);
    state_ = kStarting;
    ml.NotifyAll();
  }
  // Grab the isolate create callback here to avoid race conditions with tests
  // that change this after Dart_Initialize returns.
  create_group_callback_ = Isolate::CreateGroupCallback();
  if (create_group_callback_ == nullptr) {
    ServiceIsolate::InitializingFailed(
        Utils::StrDup("The 'create_group' callback was not provided"));
    return;
  }
  bool task_started = Dart::thread_pool()->Run<RunServiceTask>();
  ASSERT(task_started);
}

void ServiceIsolate::KillServiceIsolate() {
  {
    MonitorLocker ml(monitor_);
    if (state_ == kStopped) {
      return;
    }
    ASSERT(state_ == kStarted);
    state_ = kStopping;
    ml.NotifyAll();
  }
  Isolate::KillIfExists(isolate_, Isolate::kInternalKillMsg);
  {
    MonitorLocker ml(monitor_);
    while (state_ == kStopping) {
      ml.Wait();
    }
    ASSERT(state_ == kStopped);
  }
}

void ServiceIsolate::Shutdown() {
  {
    MonitorLocker ml(monitor_);
    while (state_ == kStarting) {
      ml.Wait();
    }
  }

  if (IsRunning()) {
    {
      MonitorLocker ml(monitor_);
      ASSERT(state_ == kStarted);
      state_ = kStopping;
      ml.NotifyAll();
    }
    SendServiceExitMessage();
    {
      MonitorLocker ml(monitor_);
      while (state_ == kStopping) {
        ml.Wait();
      }
      ASSERT(state_ == kStopped);
    }
  } else {
    if (isolate_ != nullptr) {
      // TODO(johnmccutchan,turnidge) When it is possible to properly create
      // the VMService object and set up its shutdown handler in the service
      // isolate's main() function, this case will no longer be possible and
      // can be removed.
      KillServiceIsolate();
    }
  }
  if (server_address_ != nullptr) {
    free(server_address_);
    server_address_ = nullptr;
  }

  if (startup_failure_reason_ != nullptr) {
    free(startup_failure_reason_);
    startup_failure_reason_ = nullptr;
  }
}

void ServiceIsolate::BootVmServiceLibrary() {
  Thread* thread = Thread::Current();
  const Library& vmservice_library =
      Library::Handle(Library::LookupLibrary(thread, Symbols::DartVMService()));
  ASSERT(!vmservice_library.IsNull());
  const String& boot_function_name = String::Handle(String::New("boot"));
  const Function& boot_function = Function::Handle(
      vmservice_library.LookupFunctionAllowPrivate(boot_function_name));
  ASSERT(!boot_function.IsNull());
  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(boot_function, Object::empty_array()));
  ASSERT(!result.IsNull());
  if (result.IsUnwindError() || result.IsUnhandledException()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  Dart_Port port = ILLEGAL_PORT;
  if (result.IsReceivePort()) {
    port = ReceivePort::Cast(result).Id();
  }
  ASSERT(port != ILLEGAL_PORT);
  ServiceIsolate::SetServicePort(port);
}

void ServiceIsolate::RegisterRunningIsolates(
    const GrowableArray<Dart_Port>& isolate_ports,
    const GrowableArray<const String*>& isolate_names) {
  auto thread = Thread::Current();
  auto zone = thread->zone();

  ASSERT(ServiceIsolate::IsServiceIsolate(thread->isolate()));

  // Obtain "_registerIsolate" function to call.
  const String& library_url = Symbols::DartVMService();
  ASSERT(!library_url.IsNull());
  const Library& library =
      Library::Handle(zone, Library::LookupLibrary(thread, library_url));
  ASSERT(!library.IsNull());
  const String& function_name =
      String::Handle(zone, String::New("_registerIsolate"));
  ASSERT(!function_name.IsNull());
  const Function& register_function_ =
      Function::Handle(zone, library.LookupFunctionAllowPrivate(function_name));
  ASSERT(!register_function_.IsNull());

  Integer& port_int = Integer::Handle(zone);
  SendPort& send_port = SendPort::Handle(zone);
  Array& args = Array::Handle(zone, Array::New(3));
  Object& result = Object::Handle(zone);

  ASSERT(isolate_ports.length() == isolate_names.length());
  for (intptr_t i = 0; i < isolate_ports.length(); ++i) {
    const Dart_Port port_id = isolate_ports[i];
    const String& name = *isolate_names[i];

    port_int = Integer::New(port_id);
    send_port = SendPort::New(port_id);
    args.SetAt(0, port_int);
    args.SetAt(1, send_port);
    args.SetAt(2, name);
    result = DartEntry::InvokeFunction(register_function_, args);
    if (FLAG_trace_service) {
      OS::PrintErr("vm-service: Isolate %s %" Pd64 " registered.\n",
                   name.ToCString(), port_id);
    }
    ASSERT(!result.IsError());
  }
}

void ServiceIsolate::VisitObjectPointers(ObjectPointerVisitor* visitor) {}

}  // namespace dart

#endif  // !defined(PRODUCT)
