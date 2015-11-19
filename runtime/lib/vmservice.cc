// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, trace_service);

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


class RegisterRunningIsolatesVisitor : public IsolateVisitor {
 public:
  explicit RegisterRunningIsolatesVisitor(Thread* thread)
      : IsolateVisitor(),
        register_function_(Function::Handle(thread->zone())),
        service_isolate_(thread->isolate()) {
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
    const Object& r = Object::Handle(
        DartEntry::InvokeFunction(register_function_, args));
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


DEFINE_NATIVE_ENTRY(VMService_SendIsolateServiceMessage, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(1));

  // Set the type of the OOB message.
  message.SetAt(0, Smi::Handle(thread->zone(),
                               Smi::New(Message::kServiceOOBMsg)));

  // Serialize message.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(message);

  // TODO(turnidge): Throw an exception when the return value is false?
  bool result = PortMap::PostMessage(
      new Message(sp.Id(), data, writer.BytesWritten(),
                  Message::kOOBPriority));
  return Bool::Get(result).raw();
}


DEFINE_NATIVE_ENTRY(VMService_SendRootServiceMessage, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
  Service::HandleRootMessage(message);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(VMService_OnStart, 0) {
  if (FLAG_trace_service) {
    OS::Print("vm-service: Booting dart:vmservice library.\n");
  }
  // Boot the dart:vmservice library.
  ServiceIsolate::BootVmServiceLibrary();

  // Register running isolates with service.
  RegisterRunningIsolatesVisitor register_isolates(thread);
  if (FLAG_trace_service) {
    OS::Print("vm-service: Registering running isolates.\n");
  }
  Isolate::VisitIsolates(&register_isolates);

  return Object::null();
}


DEFINE_NATIVE_ENTRY(VMService_OnExit, 0) {
  if (FLAG_trace_service) {
    OS::Print("vm-service: processed exit message.\n");
  }
  return Object::null();
}


DEFINE_NATIVE_ENTRY(VMService_ListenStream, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  bool result = Service::ListenStream(stream_id.ToCString());
  return Bool::Get(result).raw();
}


DEFINE_NATIVE_ENTRY(VMService_CancelStream, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  Service::CancelStream(stream_id.ToCString());
  return Object::null();
}


DEFINE_NATIVE_ENTRY(VMService_RequestAssets, 0) {
  return Service::RequestAssets();
}

}  // namespace dart
