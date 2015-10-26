// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
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

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


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
  Dart_Port port_id =
      PortMap::CreatePort(isolate->message_handler());
  return ReceivePort::New(port_id, false /* not control port */);
}


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_id, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return Integer::NewFromUint64(port.Id());
}


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_get_sendport, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  return port.send_port();
}


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_closeInternal, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(ReceivePort, port, arguments->NativeArgAt(0));
  Dart_Port id = port.Id();
  PortMap::ClosePort(id);
  return Integer::NewFromUint64(id);
}


DEFINE_NATIVE_ENTRY(SendPortImpl_get_id, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  return Integer::NewFromUint64(port.Id());
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

  uint8_t* data = NULL;

  const Dart_Port destination_port_id = port.Id();
  const bool can_send_any_object = isolate->origin_id() == port.origin_id();

  MessageWriter writer(&data, &allocator, can_send_any_object);
  writer.WriteMessage(obj);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(destination_port_id,
                                   data, writer.BytesWritten(),
                                   Message::kNormalPriority));
  return Object::null();
}


static void ThrowIsolateSpawnException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}


static bool CreateIsolate(Isolate* parent_isolate,
                          IsolateSpawnState* state,
                          char** error) {
  Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
  if (callback == NULL) {
    *error = strdup("Null callback specified for isolate creation\n");
    return false;
  }

  Dart_IsolateFlags api_flags;
  state->isolate_flags()->CopyTo(&api_flags);

  void* init_data = parent_isolate->init_callback_data();
  Isolate* child_isolate = reinterpret_cast<Isolate*>(
      (callback)(state->script_url(),
                 state->function_name(),
                 state->package_root(),
                 state->package_map(),
                 &api_flags,
                 init_data,
                 error));
  if (child_isolate == NULL) {
    return false;
  }
  if (!state->is_spawn_uri()) {
    // For isolates spawned using the spawn semantics we set
    // the origin_id to the origin_id of the parent isolate.
    child_isolate->set_origin_id(parent_isolate->origin_id());
  }
  state->set_isolate(reinterpret_cast<Isolate*>(child_isolate));
  return true;
}


static void Spawn(Isolate* parent_isolate, IsolateSpawnState* state) {
  Thread::ExitIsolate();
  // Create a new isolate.
  char* error = NULL;
  if (!CreateIsolate(parent_isolate, state, &error)) {
    Thread::EnterIsolate(parent_isolate);
    delete state;
    const String& msg = String::Handle(String::New(error));
    free(error);
    ThrowIsolateSpawnException(msg);
  }
  Thread::EnterIsolate(parent_isolate);
  // Start the new isolate if it is already marked as runnable.
  Isolate* spawned_isolate = state->isolate();
  MutexLocker ml(spawned_isolate->mutex());
  spawned_isolate->set_spawn_state(state);
  if (spawned_isolate->is_runnable()) {
    spawned_isolate->Run();
  }
}


DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 7) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, paused, arguments->NativeArgAt(3));
  GET_NATIVE_ARGUMENT(Bool, fatalErrors, arguments->NativeArgAt(4));
  GET_NATIVE_ARGUMENT(SendPort, onExit, arguments->NativeArgAt(5));
  GET_NATIVE_ARGUMENT(SendPort, onError, arguments->NativeArgAt(6));

  if (closure.IsClosure()) {
    Function& func = Function::Handle();
    func = Closure::function(closure);
    if (func.IsImplicitClosureFunction() && func.is_static()) {
#if defined(DEBUG)
      Context& ctx = Context::Handle();
      ctx = Closure::context(closure);
      ASSERT(ctx.num_variables() == 0);
#endif
      // Get the parent function so that we get the right function name.
      func = func.parent_function();

      bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
      Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
      Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

      Spawn(isolate, new IsolateSpawnState(port.Id(),
                                           func,
                                           message,
                                           paused.value(),
                                           fatal_errors,
                                           on_exit_port,
                                           on_error_port));
      return Object::null();
    }
  }
  const String& msg = String::Handle(String::New(
      "Isolate.spawn expects to be passed a static or top-level function"));
  Exceptions::ThrowArgumentError(msg);
  return Object::null();
}


static char* String2UTF8(const String& str) {
  intptr_t len = Utf8::Length(str);
  char* result = new char[len + 1];
  str.ToUTF8(reinterpret_cast<uint8_t*>(result), len);
  result[len] = 0;

  return result;
}


static char* CanonicalizeUri(Thread* thread,
                             const Library& library,
                             const String& uri,
                             char** error) {
  char* result = NULL;
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Dart_LibraryTagHandler handler = isolate->library_tag_handler();
  if (handler != NULL) {
    Dart_EnterScope();
    Dart_Handle handle = handler(Dart_kCanonicalizeUrl,
                                 Api::NewHandle(isolate, library.raw()),
                                 Api::NewHandle(isolate, uri.raw()));
    const Object& obj = Object::Handle(Api::UnwrapHandle(handle));
    if (obj.IsString()) {
      result = String2UTF8(String::Cast(obj));
    } else if (obj.IsError()) {
      Error& error_obj = Error::Handle();
      error_obj ^= obj.raw();
      *error = zone->PrintToString("Unable to canonicalize uri '%s': %s",
                                   uri.ToCString(), error_obj.ToErrorCString());
    } else {
      *error = zone->PrintToString("Unable to canonicalize uri '%s': "
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

  GET_NATIVE_ARGUMENT(String, package_root, arguments->NativeArgAt(10));
  GET_NATIVE_ARGUMENT(Array, packages, arguments->NativeArgAt(11));


  // Canonicalize the uri with respect to the current isolate.
  const Library& root_lib =
      Library::Handle(isolate->object_store()->root_library());
  char* error = NULL;
  char* canonical_uri = CanonicalizeUri(thread, root_lib, uri, &error);
  if (canonical_uri == NULL) {
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  char* utf8_package_root =
      package_root.IsNull() ? NULL : String2UTF8(package_root);

  char** utf8_package_map = NULL;
  if (!packages.IsNull()) {
    intptr_t len = packages.Length();
    utf8_package_map = new char*[len + 1];

    Object& entry = Object::Handle();
    for (intptr_t i = 0; i < len; i++) {
      entry = packages.At(i);
      if (!entry.IsString()) {
        const String& msg = String::Handle(String::NewFormatted(
            "Bad value in package map: %s", entry.ToCString()));
        ThrowIsolateSpawnException(msg);
      }
      utf8_package_map[i] = String2UTF8(String::Cast(entry));
    }
    // NULL terminated array.
    utf8_package_map[len] = NULL;
  }

  bool fatal_errors = fatalErrors.IsNull() ? true : fatalErrors.value();
  Dart_Port on_exit_port = onExit.IsNull() ? ILLEGAL_PORT : onExit.Id();
  Dart_Port on_error_port = onError.IsNull() ? ILLEGAL_PORT : onError.Id();

  IsolateSpawnState* state = new IsolateSpawnState(
      port.Id(),
      canonical_uri,
      utf8_package_root,
      const_cast<const char**>(utf8_package_map),
      args,
      message,
      paused.value(),
      fatal_errors,
      on_exit_port,
      on_error_port);
  // If we were passed a value then override the default flags state for
  // checked mode.
  if (!checked.IsNull()) {
    state->isolate_flags()->set_checked(checked.value());
  }

  Spawn(isolate, state);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Isolate_getPortAndCapabilitiesOfCurrentIsolate, 0) {
  const Array& result = Array::Handle(Array::New(3));
  result.SetAt(0, SendPort::Handle(SendPort::New(isolate->main_port())));
  result.SetAt(1, Capability::Handle(
                      Capability::New(isolate->pause_capability())));
  result.SetAt(2, Capability::Handle(
                      Capability::New(isolate->terminate_capability())));
  return result.raw();
}


DEFINE_NATIVE_ENTRY(Isolate_sendOOB, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, msg, arguments->NativeArgAt(1));

  // Make sure to route this request to the isolate library OOB mesage handler.
  msg.SetAt(0, Smi::Handle(Smi::New(Message::kIsolateLibOOBMsg)));

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator, false);
  writer.WriteMessage(msg);

  PortMap::PostMessage(new Message(port.Id(),
                                   data, writer.BytesWritten(),
                                   Message::kOOBPriority));
  return Object::null();
}

}  // namespace dart
