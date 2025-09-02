// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "include/dart_native_api.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/message_snapshot.h"
#include "vm/native_message_handler.h"
#include "vm/port.h"
#include "vm/service_isolate.h"

namespace dart {

// --- Message sending/receiving from native code ---

class IsolateLeaveScope {
 public:
  explicit IsolateLeaveScope(Isolate* current_isolate)
      : saved_isolate_(current_isolate) {
    if (current_isolate != nullptr) {
      ASSERT(current_isolate == Isolate::Current());
      Dart_ExitIsolate();
    }
  }
  ~IsolateLeaveScope() {
    if (saved_isolate_ != nullptr) {
      Dart_Isolate I = reinterpret_cast<Dart_Isolate>(saved_isolate_);
      Dart_EnterIsolate(I);
    }
  }

 private:
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(IsolateLeaveScope);
};

class DartApiCallScope : public ValueObject {
 public:
  DartApiCallScope() : active_(Dart::SetActiveApiCall()) {}
  ~DartApiCallScope() {
    if (active_) {
      Dart::ResetActiveApiCall();
    }
  }
  bool active() const { return active_; }

 private:
  const bool active_;
};

#define ENTER_API_CALL_OR_RETURN(failure_value)                                \
  DartApiCallScope api_call_scope;                                             \
  if (!api_call_scope.active()) {                                              \
    return failure_value;                                                      \
  }

static bool PostCObjectHelper(Dart_Port port_id, Dart_CObject* message) {
  AllocOnlyStackZone zone;
  std::unique_ptr<Message> msg = WriteApiMessage(
      zone.GetZone(), message, port_id, Message::kNormalPriority);

  if (msg == nullptr) {
    return false;
  }

  // Post the message at the given port.
  return PortMap::PostMessage(std::move(msg));
}

DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  return PostCObjectHelper(port_id, message);
}

DART_EXPORT bool Dart_PostInteger(Dart_Port port_id, int64_t message) {
  if (Smi::IsValid(message)) {
    return PortMap::PostMessage(
        Message::New(port_id, Smi::New(message), Message::kNormalPriority));
  }
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = message;
  return PostCObjectHelper(port_id, &cobj);
}

DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently) {
  return Dart_NewConcurrentNativePort(name, handler, /*max_concurrency=*/1);
}

DART_EXPORT Dart_Port
Dart_NewConcurrentNativePort(const char* name,
                             Dart_NativeMessageHandler handler,
                             intptr_t max_concurrency) {
  if (name == nullptr) {
    name = "<UnnamedNativePort>";
  }
  if (handler == nullptr) {
    OS::PrintErr("%s expects argument 'handler' to be non-null.\n",
                 CURRENT_FUNC);
    return ILLEGAL_PORT;
  }
  ENTER_API_CALL_OR_RETURN(ILLEGAL_PORT);
  // Start the native port without a current isolate.
  IsolateLeaveScope saver(Isolate::Current());

  NativeMessageHandler* nmh =
      new NativeMessageHandler(name, handler, max_concurrency);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  return port_id;
}

DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id) {
  ENTER_API_CALL_OR_RETURN(false)

  // Close the native port without a current isolate.
  IsolateLeaveScope saver(Isolate::Current());

  PortHandler* handler = nullptr;
  const bool was_closed = PortMap::ClosePort(native_port_id, &handler);
  if (was_closed) {
    NativeMessageHandler::RequestDeletion(
        static_cast<NativeMessageHandler*>(handler));
  }
  return was_closed;
}

DART_EXPORT bool Dart_InvokeVMServiceMethod(uint8_t* request_json,
                                            intptr_t request_json_length,
                                            uint8_t** response_json,
                                            intptr_t* response_json_length,
                                            char** error) {
#if !defined(PRODUCT)
  DartApiCallScope api_call;
  if (!api_call.active()) {
    *error = ::dart::Utils::StrDup("VM Service is not active.");
    return false;
  }

  Isolate* isolate = Isolate::Current();
  ASSERT(isolate == nullptr || !isolate->is_service_isolate());
  IsolateLeaveScope saver(isolate);

  // We only allow one isolate reload at a time.  If this turns out to be on the
  // critical path, we can change it to have a global datastructure which is
  // mapping the reply ports to receive buffers.
  static Monitor* vm_service_calls_monitor = new Monitor();
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
    if (error != nullptr) {
      *error = ::dart::Utils::StrDup("Was unable to create native port.");
    }
    return false;
  }

  // Before sending the message we'll lock the monitor, which the receiver
  // will later on notify once the answer has been received.
  MonitorLocker monitor(vm_service_call_monitor);

  if (ServiceIsolate::SendServiceRpc(request_json, request_json_length, port,
                                     error)) {
    // We posted successfully and expect the vm-service to send the reply, so
    // we will wait for it now. Since the service isolate could have shutdown
    // after we sent the message we make sure to wake up periodically and
    // check to see if the service isolate has shutdown.
    do {
      auto wait_result = monitor.Wait(1000); /* milliseconds */
      if (wait_result == Monitor::kNotified) {
        break;
      }
      if (!ServiceIsolate::IsRunning()) {
        // Service Isolate has shutdown while we were waiting for a reply,
        // We will not get a reply anymore, cleanup and return an error.
        Dart_CloseNativePort(port);
        return false;
      }
    } while (true);

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
    return false;
  }
#else   // !defined(PRODUCT)
  if (error != nullptr) {
    *error = Utils::StrDup("VM Service is not supported in PRODUCT mode.");
  }
  return false;
#endif  // !defined(PRODUCT)
}

// --- Verification tools ---

DART_EXPORT Dart_Handle Dart_CompileAll() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: Cannot compile on an AOT runtime.", CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  const Error& error = Error::Handle(T->zone(), Library::CompileAll());
  if (!error.IsNull()) {
    return Api::NewHandle(T, error.ptr());
  }
  return Api::Success();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

DART_EXPORT Dart_Handle Dart_FinalizeAllClasses() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return Api::NewError("%s: All classes are already finalized in AOT runtime.",
                       CURRENT_FUNC);
#else
  DARTSCOPE(Thread::Current());
  API_TIMELINE_DURATION(T);
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (Api::IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  const Error& error = Error::Handle(T->zone(), Library::FinalizeAllClasses());
  if (!error.IsNull()) {
    return Api::NewHandle(T, error.ptr());
  }
  return Api::Success();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

struct RunInSafepointAndRWCodeArgs {
  Isolate* isolate;
  std::function<void()>* callback;
};

struct UnsafeSetSharedToArgs {
  void* library_name_handle;
  void* field_name_handle;
  void* value_handle;
};

DART_EXPORT void* Dart_ExecuteInternalCommand(const char* command, void* arg) {
  if (strcmp(command, "gc-on-nth-allocation") == 0) {
    Thread* const thread = Thread::Current();
    Isolate* isolate = (thread == nullptr) ? nullptr : thread->isolate();
    CHECK_ISOLATE(isolate);
    TransitionNativeToVM _(thread);
    intptr_t argument = reinterpret_cast<intptr_t>(arg);
    ASSERT(argument > 0);
    IsolateGroup::Current()->heap()->CollectOnNthAllocation(argument);
    return nullptr;

  } else if (strcmp(command, "gc-now") == 0) {
    ASSERT(arg == nullptr);  // Don't pass an argument to this command.
    Thread* const thread = Thread::Current();
    Isolate* isolate = (thread == nullptr) ? nullptr : thread->isolate();
    CHECK_ISOLATE(isolate);
    TransitionNativeToVM _(thread);
    IsolateGroup::Current()->heap()->CollectAllGarbage(GCReason::kDebugging);
    return nullptr;

  } else if (strcmp(command, "is-thread-in-generated") == 0) {
    if (Thread::Current()->execution_state() == Thread::kThreadInGenerated) {
      return reinterpret_cast<void*>(1);
    }
    return nullptr;

  } else if (strcmp(command, "is-mutator-blocked-at-safepoint") == 0) {
    Isolate* const isolate = reinterpret_cast<Isolate*>(arg);
    CHECK_ISOLATE(isolate);
    if (isolate->mutator_thread()
            ->IsBlockedForSafepointCrossThreadForTesting()) {
      return arg;
    } else {
      return nullptr;
    }

  } else if (strcmp(command, "run-in-safepoint-and-rw-code") == 0) {
    const RunInSafepointAndRWCodeArgs* const args =
        reinterpret_cast<RunInSafepointAndRWCodeArgs*>(arg);
    Isolate* const isolate = args->isolate;
    CHECK_ISOLATE(isolate);
    auto isolate_group = isolate->group();
    const bool kBypassSafepoint = false;
    Thread::EnterIsolateGroupAsHelper(isolate_group, Thread::kUnknownTask,
                                      kBypassSafepoint);
    Thread* const thread = Thread::Current();
    {
      NoReloadScope no_reload(thread);  // Reload can flip code protection.
      GcSafepointOperationScope scope(thread);
      isolate_group->heap()->WriteProtectCode(/*read_only=*/false);
      (*args->callback)();
      isolate_group->heap()->WriteProtectCode(/*read_only=*/true);
    }
    Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    return nullptr;

  } else if (strcmp(command, "unsafe-set-shared-to") == 0) {
    const UnsafeSetSharedToArgs* const args =
        reinterpret_cast<UnsafeSetSharedToArgs*>(arg);
    DARTSCOPE(Thread::Current());
    const String& library_name = Api::UnwrapStringHandle(
        T->zone(), reinterpret_cast<Dart_Handle>(args->library_name_handle));
    const String& field_name = Api::UnwrapStringHandle(
        T->zone(), reinterpret_cast<Dart_Handle>(args->field_name_handle));
    const Instance& value = Api::UnwrapInstanceHandle(
        T->zone(), reinterpret_cast<Dart_Handle>(args->value_handle));
    const Library& library =
        Library::Handle(T->zone(), Library::LookupLibrary(T, library_name));
    ASSERT(!library.IsNull());
    Field& field =
        Field::Handle(T->zone(), library.LookupFieldAllowPrivate(field_name));
    ASSERT(!field.IsNull());
    if (field.is_shared()) {
      SafepointReadRwLocker ml(T, T->isolate_group()->program_lock());
      T->isolate_group()->shared_field_table()->SetAt(field.field_id(),
                                                      value.ptr());
    } else {
      field.SetStaticValue(value);
    }
    return nullptr;
  } else {
    UNREACHABLE();
  }
}

}  // namespace dart
