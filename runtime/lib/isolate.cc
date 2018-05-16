// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/lockers.h"
#include "vm/longjump.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/service.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
#include "vm/unicode.h"

namespace dart {

DEFINE_NATIVE_ENTRY(CapabilityImpl_factory, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  uint64_t id = isolate->random()->NextUInt64();
  return Capability::New(id);
}

DEFINE_NATIVE_ENTRY(CapabilityImpl_equals, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, recv, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, other, arguments->NativeArgAt(1));
  return (recv.Id() == other.Id()) ? Bool::True().raw() : Bool::False().raw();
}

DEFINE_NATIVE_ENTRY(CapabilityImpl_get_hashcode, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Capability, cap, arguments->NativeArgAt(0));
  int64_t id = cap.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_factory, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  Dart_Port port_id = PortMap::CreatePort(isolate->message_handler());
  return ReceivePort::New(port_id, false /* not control port */);
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_id, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_sendport, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return port.send_port();
}

DEFINE_NATIVE_ENTRY(RawReceivePortImpl_closeInternal, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  Dart_Port id = port.Id();
  PortMap::ClosePort(id);
  return Integer::New(id);
}

DEFINE_NATIVE_ENTRY(SendPortImpl_get_id, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  return Integer::New(port.Id());
}

DEFINE_NATIVE_ENTRY(SendPortImpl_get_hashcode, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  int64_t id = port.Id();
  int32_t hi = static_cast<int32_t>(id >> 32);
  int32_t lo = static_cast<int32_t>(id);
  int32_t hash = (hi ^ lo) & kSmiMax;
  return Smi::New(hash);
}

DEFINE_NATIVE_ENTRY(SendPortImpl_sendInternal_, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  // TODO(iposva): Allow for arbitrary messages to be sent.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

  const Dart_Port destination_port_id = port.Id();
  const bool can_send_any_object = isolate->origin_id() == port.origin_id();

  if (ApiObjectConverter::CanConvert(obj.raw())) {
    PortMap::PostMessage(
        new Message(destination_port_id, obj.raw(), Message::kNormalPriority));
  } else {
    MessageWriter writer(can_send_any_object);
    // TODO(turnidge): Throw an exception when the return value is false?
    PortMap::PostMessage(writer.WriteMessage(obj, destination_port_id,
                                             Message::kNormalPriority));
  }
  return Object::null();
}

static void ThrowIsolateSpawnException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}

class SpawnIsolateTask : public ThreadPool::Task {
 public:
  explicit SpawnIsolateTask(IsolateSpawnState* state) : state_(state) {}

  virtual void Run() {
    // Create a new isolate.
    char* error = NULL;
    Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
    if (callback == NULL) {
      state_->DecrementSpawnCount();
      ReportError(
          "Isolate spawn is not supported by this Dart implementation\n");
      delete state_;
      state_ = NULL;
      return;
    }

    // Make a copy of the state's isolate flags and hand it to the callback.
    Dart_IsolateFlags api_flags = *(state_->isolate_flags());

    Isolate* isolate = reinterpret_cast<Isolate*>((callback)(
        state_->script_url(), state_->function_name(), state_->package_root(),
        state_->package_config(), &api_flags, state_->init_data(), &error));
    state_->DecrementSpawnCount();
    if (isolate == NULL) {
      ReportError(error);
      delete state_;
      state_ = NULL;
      free(error);
      return;
    }

    if (state_->origin_id() != ILLEGAL_PORT) {
      // For isolates spawned using spawnFunction we set the origin_id
      // to the origin_id of the parent isolate.
      isolate->set_origin_id(state_->origin_id());
    }
    MutexLocker ml(isolate->mutex());
    state_->set_isolate(reinterpret_cast<Isolate*>(isolate));
    isolate->set_spawn_state(state_);
    state_ = NULL;
    if (isolate->is_runnable()) {
      isolate->Run();
    }
  }

 private:
  void ReportError(const char* error) {
    Dart_CObject error_cobj;
    error_cobj.type = Dart_CObject_kString;
    error_cobj.value.as_string = const_cast<char*>(error);
    if (!Dart_PostCObject(state_->parent_port(), &error_cobj)) {
      // Perhaps the parent isolate died or closed the port before we
      // could report the error.  Ignore.
    }
  }

  IsolateSpawnState* state_;

  DISALLOW_COPY_AND_ASSIGN(SpawnIsolateTask);
};

static const char* String2UTF8(const String& str) {
  intptr_t len = Utf8::Length(str);
  char* result = new char[len + 1];
  str.ToUTF8(reinterpret_cast<uint8_t*>(result), len);
  result[len] = 0;

  return result;
}

DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 10) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, script_uri, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(6));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(7));
  GET_NATIVE_ARGUMENT(String, packageRoot, arguments->NativeArgAt(8));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(9));

  if (closure.IsClosure()) {
    Function& func = Function::Handle();
    func = Closure::Cast(closure).function();
    if (func.IsImplicitClosureFunction() && func.is_static()) {
#if defined(DEBUG)
      Context& ctx = Context::Handle();
      ctx = Closure::Cast(closure).context();
      ASSERT(ctx.IsNull());
#endif
      // Get the parent function so that we get the right function name.
      func = func.parent_function();

      bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
      Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
      Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

      // We first try to serialize the message.  In case the message is not
      // serializable this will throw an exception.
      SerializedObjectBuffer message_buffer;
      {
        MessageWriter writer(/* can_send_any_object = */ true);
        message_buffer.set_message(writer.WriteMessage(
            message, ILLEGAL_PORT, Message::kNormalPriority));
      }

      const char* utf8_package_root =
          packageRoot.IsNull() ? NULL : String2UTF8(packageRoot);
      const char* utf8_package_config =
          packageConfig.IsNull() ? NULL : String2UTF8(packageConfig);

      IsolateSpawnState* state = new IsolateSpawnState(
          port.Id(), isolate->origin_id(), isolate->init_callback_data(),
          String2UTF8(script_uri), func, &message_buffer,
          isolate->spawn_count_monitor(), isolate->spawn_count(),
          utf8_package_root, utf8_package_config, paused.value(), fatal_errors,
          on_exit_port, on_error_port);
      ThreadPool::Task* spawn_task = new SpawnIsolateTask(state);

      isolate->IncrementSpawnCount();
      if (!Dart::thread_pool()->Run(spawn_task)) {
        // Running on the thread pool failed. Clean up everything.
        state->DecrementSpawnCount();
        delete state;
        state = NULL;
        delete spawn_task;
        spawn_task = NULL;
      }
      return Object::null();
    }
  }
  const String& msg = String::Handle(String::New(
      "Isolate.spawn expects to be passed a static or top-level function"));
  Exceptions::ThrowArgumentError(msg);
  return Object::null();
}

static const char* CanonicalizeUri(Thread* thread,
                                   const Library& library,
                                   const String& uri,
                                   char** error) {
  const char* result = NULL;
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Dart_LibraryTagHandler handler = isolate->library_tag_handler();
  if (handler != NULL) {
    TransitionVMToNative transition(thread);
    Dart_EnterScope();
    Dart_Handle handle =
        handler(Dart_kCanonicalizeUrl, Api::NewHandle(thread, library.raw()),
                Api::NewHandle(thread, uri.raw()));
    const Object& obj = Object::Handle(Api::UnwrapHandle(handle));
    if (obj.IsString()) {
      result = String2UTF8(String::Cast(obj));
    } else if (obj.IsError()) {
      Error& error_obj = Error::Handle();
      error_obj ^= obj.raw();
      *error = zone->PrintToString("Unable to canonicalize uri '%s': %s",
                                   uri.ToCString(), error_obj.ToErrorCString());
    } else {
      *error = zone->PrintToString(
          "Unable to canonicalize uri '%s': "
          "library tag handler returned wrong type",
          uri.ToCString());
    }
    Dart_ExitScope();
  } else {
    *error = zone->PrintToString(
        "Unable to canonicalize uri '%s': no library tag handler found.",
        uri.ToCString());
  }
  return result;
}

DEFINE_NATIVE_ENTRY(Isolate_spawnUri, 12) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, uri, arguments->NativeArgAt(1));

  GET_NON_NULL_NATIVE_ARGUMENT(Instance, args, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));

  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(6));

  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(7));
  GET_NATIVE_ARGUMENT(Bool, checked, arguments->NativeArgAt(8));

  GET_NATIVE_ARGUMENT(Array, environment, arguments->NativeArgAt(9));

  GET_NATIVE_ARGUMENT(String, packageRoot, arguments->NativeArgAt(10));
  GET_NATIVE_ARGUMENT(String, packageConfig, arguments->NativeArgAt(11));

  if (Dart::vm_snapshot_kind() == Snapshot::kFullAOT) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(
        0,
        String::Handle(String::New(
            "Isolate.spawnUri is not supported when using AOT compilation")));
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
    UNREACHABLE();
  }

  bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
  Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
  Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

  // We first try to serialize the arguments and the message.  In case the
  // arguments or the message are not serializable this will throw an exception.
  SerializedObjectBuffer arguments_buffer;
  SerializedObjectBuffer message_buffer;
  {
    MessageWriter writer(/* can_send_any_object = */ false);
    arguments_buffer.set_message(
        writer.WriteMessage(args, ILLEGAL_PORT, Message::kNormalPriority));
  }
  {
    MessageWriter writer(/* can_send_any_object = */ false);
    message_buffer.set_message(
        writer.WriteMessage(message, ILLEGAL_PORT, Message::kNormalPriority));
  }

  // Canonicalize the uri with respect to the current isolate.
  const Library& root_lib =
      Library::Handle(isolate->object_store()->root_library());
  char* error = NULL;
  const char* canonical_uri = CanonicalizeUri(thread, root_lib, uri, &error);
  if (canonical_uri == NULL) {
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  const char* utf8_package_root =
      packageRoot.IsNull() ? NULL : String2UTF8(packageRoot);
  const char* utf8_package_config =
      packageConfig.IsNull() ? NULL : String2UTF8(packageConfig);

  IsolateSpawnState* state = new IsolateSpawnState(
      port.Id(), isolate->init_callback_data(), canonical_uri,
      utf8_package_root, utf8_package_config, &arguments_buffer,
      &message_buffer, isolate->spawn_count_monitor(), isolate->spawn_count(),
      paused.value(), fatal_errors, on_exit_port, on_error_port);

  // If we were passed a value then override the default flags state for
  // checked mode.
  if (!checked.IsNull()) {
    bool is_checked = checked.value();
    Dart_IsolateFlags* flags = state->isolate_flags();
    flags->enable_asserts = is_checked;
    // Do not enable type checks in strong mode.
    flags->enable_type_checks = is_checked && !flags->strong;
  }

  ThreadPool::Task* spawn_task = new SpawnIsolateTask(state);

  isolate->IncrementSpawnCount();
  if (!Dart::thread_pool()->Run(spawn_task)) {
    // Running on the thread pool failed. Clean up everything.
    state->DecrementSpawnCount();
    delete state;
    state = NULL;
    delete spawn_task;
    spawn_task = NULL;
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(Isolate_getPortAndCapabilitiesOfCurrentIsolate, 0) {
  const Array& result = Array::Handle(Array::New(3));
  result.SetAt(0, SendPort::Handle(SendPort::New(isolate->main_port())));
  result.SetAt(
      1, Capability::Handle(Capability::New(isolate->pause_capability())));
  result.SetAt(
      2, Capability::Handle(Capability::New(isolate->terminate_capability())));
  return result.raw();
}

DEFINE_NATIVE_ENTRY(Isolate_getCurrentRootUriStr, 0) {
  const Library& root_lib =
      Library::Handle(zone, isolate->object_store()->root_library());
  return root_lib.url();
}

DEFINE_NATIVE_ENTRY(Isolate_sendOOB, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, msg, arguments->NativeArgAt(1));

  // Make sure to route this request to the isolate library OOB mesage handler.
  msg.SetAt(0, Smi::Handle(Smi::New(Message::kIsolateLibOOBMsg)));

  MessageWriter writer(false);
  PortMap::PostMessage(
      writer.WriteMessage(msg, port.Id(), Message::kOOBPriority));

  // Drain interrupts before running so any IMMEDIATE operations on the current
  // isolate happen synchronously.
  const Error& error = Error::Handle(thread->HandleInterrupts());
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  return Object::null();
}

}  // namespace dart
