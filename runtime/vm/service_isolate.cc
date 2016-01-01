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

DECLARE_FLAG(bool, shutdown);

#define Z (T->zone())


DEFINE_FLAG(bool, trace_service, false, "Trace VM service requests.");
DEFINE_FLAG(bool, trace_service_pause_events, false,
            "Trace VM service isolate pause events.");

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
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
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  if (IsServiceIsolateDescendant(isolate)) {
    return false;
  }
  ASSERT(isolate != NULL);
  HANDLESCOPE(thread);
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
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  if (IsServiceIsolateDescendant(isolate)) {
    return false;
  }
  ASSERT(isolate != NULL);
  HANDLESCOPE(thread);
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
  }
}

void ServiceIsolate::SetLoadPort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  load_port_ = port;
}


void ServiceIsolate::MaybeMakeServiceIsolate(Isolate* I) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != NULL);
  ASSERT(I->name() != NULL);
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


void ServiceIsolate::ConstructExitMessageAndCache(Isolate* I) {
  // Construct and cache exit message here so we can send it without needing an
  // isolate.
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != NULL);
  StackZone zone(T);
  HANDLESCOPE(T);
  ASSERT(exit_message_ == NULL);
  ASSERT(exit_message_length_ == 0);
  const Array& list = Array::Handle(Z, MakeServiceExitMessage());
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
                                                   NULL,
                                                   &api_flags,
                                                   NULL,
                                                   &error));
    if (isolate == NULL) {
      OS::PrintErr("vm-service: Isolate creation error: %s\n", error);
      ServiceIsolate::SetServiceIsolate(NULL);
      ServiceIsolate::FinishedInitializing();
      return;
    }

    {
      ASSERT(Isolate::Current() == NULL);
      StartIsolateScope start_scope(isolate);
      ServiceIsolate::ConstructExitMessageAndCache(isolate);
      RunMain(isolate);
    }

    ServiceIsolate::FinishedInitializing();

    isolate->message_handler()->Run(Dart::thread_pool(),
                                    NULL,
                                    ShutdownIsolate,
                                    reinterpret_cast<uword>(isolate));
  }

 protected:
  static void ShutdownIsolate(uword parameter) {
    Isolate* I = reinterpret_cast<Isolate*>(parameter);
    ASSERT(ServiceIsolate::IsServiceIsolate(I));
    ServiceIsolate::SetServiceIsolate(NULL);
    ServiceIsolate::SetServicePort(ILLEGAL_PORT);
    {
      // Print the error if there is one.  This may execute dart code to
      // print the exception object, so we need to use a StartIsolateScope.
      ASSERT(Isolate::Current() == NULL);
      StartIsolateScope start_scope(I);
      Thread* T = Thread::Current();
      ASSERT(I == T->isolate());
      StackZone zone(T);
      HandleScope handle_scope(T);
      Error& error = Error::Handle(Z);
      error = I->object_store()->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr("vm-service: Error: %s\n", error.ToErrorCString());
      }
      Dart::RunShutdownCallback();
    }
    // Shut the isolate down.
    Dart::ShutdownIsolate(I);
    if (FLAG_trace_service) {
      OS::Print("vm-service: Shutdown.\n");
    }
    ServiceIsolate::FinishedExiting();
  }

  void RunMain(Isolate* I) {
    Thread* T = Thread::Current();
    ASSERT(I == T->isolate());
    StackZone zone(T);
    HANDLESCOPE(T);
    // Invoke main which will return the loadScriptPort.
    const Library& root_library = Library::Handle(Z,
        I->object_store()->root_library());
    if (root_library.IsNull()) {
      if (FLAG_trace_service) {
        OS::Print("vm-service: Embedder did not install a script.");
      }
      // Service isolate is not supported by embedder.
      return;
    }
    ASSERT(!root_library.IsNull());
    const String& entry_name = String::Handle(Z, String::New("main"));
    ASSERT(!entry_name.IsNull());
    const Function& entry = Function::Handle(Z,
        root_library.LookupFunctionAllowPrivate(entry_name));
    if (entry.IsNull()) {
      // Service isolate is not supported by embedder.
      if (FLAG_trace_service) {
        OS::Print("vm-service: Embedder did not provide a main function.");
      }
      return;
    }
    ASSERT(!entry.IsNull());
    const Object& result = Object::Handle(Z,
        DartEntry::InvokeFunction(entry, Object::empty_array()));
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


void ServiceIsolate::KillServiceIsolate() {
  if (!FLAG_shutdown) {
    return;
  }
  {
    MonitorLocker ml(monitor_);
    shutting_down_ = true;
  }
  Isolate::KillIfExists(isolate_, Isolate::kInternalKillMsg);
  {
    MonitorLocker ml(monitor_);
    while (shutting_down_) {
      ml.Wait();
    }
  }
}


void ServiceIsolate::Shutdown() {
  if (!IsRunning()) {
    if (isolate_ != NULL) {
      // TODO(johnmccutchan,turnidge) When it is possible to properly create
      // the VMService object and set up its shutdown handler in the service
      // isolate's main() function, this case will no longer be possible and
      // can be removed.
      KillServiceIsolate();
    }
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


void ServiceIsolate::BootVmServiceLibrary() {
  const Library& vmservice_library =
      Library::Handle(Library::LookupLibrary(Symbols::DartVMService()));
  ASSERT(!vmservice_library.IsNull());
  const String& boot_function_name = String::Handle(String::New("boot"));
  const Function& boot_function =
      Function::Handle(
          vmservice_library.LookupFunctionAllowPrivate(boot_function_name));
  ASSERT(!boot_function.IsNull());
  const Object& result =
      Object::Handle(
          DartEntry::InvokeFunction(boot_function, Object::empty_array()));
  ASSERT(!result.IsNull());
  Dart_Port port = ILLEGAL_PORT;
  if (result.IsReceivePort()) {
    port = ReceivePort::Cast(result).Id();
  }
  ASSERT(port != ILLEGAL_PORT);
  ServiceIsolate::SetServicePort(port);
}

}  // namespace dart
