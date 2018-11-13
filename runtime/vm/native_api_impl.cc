// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_native_api.h"

#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/native_message_handler.h"
#include "vm/port.h"
#include "vm/service_isolate.h"

namespace dart {

// --- Message sending/receiving from native code ---

class IsolateSaver {
 public:
  explicit IsolateSaver(Isolate* current_isolate)
      : saved_isolate_(current_isolate) {
    if (current_isolate != NULL) {
      ASSERT(current_isolate == Isolate::Current());
      Dart_ExitIsolate();
    }
  }
  ~IsolateSaver() {
    if (saved_isolate_ != NULL) {
      Dart_Isolate I = reinterpret_cast<Dart_Isolate>(saved_isolate_);
      Dart_EnterIsolate(I);
    }
  }

 private:
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(IsolateSaver);
};

static bool PostCObjectHelper(Dart_Port port_id, Dart_CObject* message) {
  ApiMessageWriter writer;
  Message* msg =
      writer.WriteCMessage(message, port_id, Message::kNormalPriority);

  if (msg == NULL) {
    return false;
  }

  // Post the message at the given port.
  return PortMap::PostMessage(msg);
}

DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  return PostCObjectHelper(port_id, message);
}

DART_EXPORT bool Dart_PostInteger(Dart_Port port_id, int64_t message) {
  if (Smi::IsValid(message)) {
    return PortMap::PostMessage(
        new Message(port_id, Smi::New(message), Message::kNormalPriority));
  }
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = message;
  return PostCObjectHelper(port_id, &cobj);
}

DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently) {
  if (name == NULL) {
    name = "<UnnamedNativePort>";
  }
  if (handler == NULL) {
    OS::PrintErr("%s expects argument 'handler' to be non-null.\n",
                 CURRENT_FUNC);
    return ILLEGAL_PORT;
  }
  // Start the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());

  NativeMessageHandler* nmh = new NativeMessageHandler(name, handler);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  PortMap::SetPortState(port_id, PortMap::kLivePort);
  nmh->Run(Dart::thread_pool(), NULL, NULL, 0);
  return port_id;
}

DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id) {
  // Close the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());

  // TODO(turnidge): Check that the port is native before trying to close.
  return PortMap::ClosePort(native_port_id);
}

static Monitor* vm_service_calls_monitor = new Monitor();

DART_EXPORT bool Dart_InvokeVMServiceMethod(uint8_t* request_json,
                                            intptr_t request_json_length,
                                            uint8_t** response_json,
                                            intptr_t* response_json_length,
                                            char** error) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate == nullptr || !isolate->is_service_isolate());
  IsolateSaver saver(isolate);

  // We only allow one isolate reload at a time.  If this turns out to be on the
  // critical path, we can change it to have a global datastructure which is
  // mapping the reply ports to receive buffers.
  MonitorLocker _(vm_service_calls_monitor);

  static Monitor* vm_service_call_monitor = new Monitor();
  static uint8_t* result_bytes = nullptr;
  static intptr_t result_length = 0;

  ASSERT(result_bytes == nullptr);
  ASSERT(result_length == 0);

  struct Utils {
    static void HandleResponse(Dart_Port dest_port_id, Dart_CObject* message) {
      MonitorLocker monitor(vm_service_call_monitor);

      RELEASE_ASSERT(message->type == Dart_CObject_kTypedData);
      RELEASE_ASSERT(message->value.as_typed_data.type ==
                     Dart_TypedData_kUint8);
      result_length = message->value.as_typed_data.length;
      result_bytes = reinterpret_cast<uint8_t*>(malloc(result_length));
      memmove(result_bytes, message->value.as_typed_data.values, result_length);

      monitor.Notify();
    }
  };

  auto port =
      ::Dart_NewNativePort("service-rpc", &Utils::HandleResponse, false);
  if (port == ILLEGAL_PORT) {
    return Api::NewError("Was unable to create native port.");
  }

  // Before sending the message we'll lock the monitor, which the receiver
  // will later on notify once the answer has been received.
  MonitorLocker monitor(vm_service_call_monitor);

  if (ServiceIsolate::SendServiceRpc(request_json, request_json_length, port)) {
    // We posted successfully and expect the vm-service to send the reply, so
    // we will wait for it now.
    auto wait_result = monitor.Wait();
    ASSERT(wait_result == Monitor::kNotified);

    // The caller takes ownership of the data.
    *response_json = result_bytes;
    *response_json_length = result_length;

    // Reset global data, which can be used by the next call (after the mutex
    // has been released).
    result_bytes = nullptr;
    result_length = 0;

    // After the data has been received, we will not get any more messages on
    // this port and can safely close it now.
    Dart_CloseNativePort(port);

    return true;
  } else {
    // We couldn't post the message and will not receive any reply. Therefore we
    // clean up the port and return an error.
    Dart_CloseNativePort(port);

    if (error != nullptr) {
      *error = strdup("Was unable to post message to isolate.");
    }
    return false;
  }
}

// --- Verification tools ---

DART_EXPORT Dart_Handle Dart_CompileAll() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  const Error& error = Error::Handle(T->zone(), Library::CompileAll());
  if (!error.IsNull()) {
    return Api::NewHandle(T, error.raw());
  }
  return Api::Success();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

DART_EXPORT Dart_Handle Dart_ReadAllBytecode() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot read bytecode on an AOT runtime.",
                       CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  const Error& error = Error::Handle(T->zone(), Library::ReadAllBytecode());
  if (!error.IsNull()) {
    return Api::NewHandle(T, error.raw());
  }
  return Api::Success();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
