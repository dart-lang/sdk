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
#include "vm/longjump.h"
#include "vm/message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
#include "vm/thread.h"

namespace dart {

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


// TODO(turnidge): Move to DartLibraryCalls.
static RawObject* ReceivePortCreate(Dart_Port port_id) {
  Isolate* isolate = Isolate::Current();
  Function& func =
      Function::Handle(isolate,
                       isolate->object_store()->receive_port_create_function());
  const int kNumArguments = 1;
  if (func.IsNull()) {
    Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_get_or_create()));
    func = Resolver::ResolveStatic(isolate_lib,
                                   class_name,
                                   function_name,
                                   kNumArguments,
                                   Object::empty_array());
    ASSERT(!func.IsNull());
    isolate->object_store()->set_receive_port_create_function(func);
  }
  const Array& args = Array::Handle(isolate, Array::New(kNumArguments));
  args.SetAt(0, Integer::Handle(isolate, Integer::New(port_id)));
  const Object& result =
      Object::Handle(isolate, DartEntry::InvokeFunction(func, args));
  if (!result.IsError()) {
    PortMap::SetLive(port_id);
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_factory, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  Dart_Port port_id =
      PortMap::CreatePort(arguments->isolate()->message_handler());
  const Object& port = Object::Handle(ReceivePortCreate(port_id));
  if (port.IsError()) {
    Exceptions::PropagateError(Error::Cast(port));
  }
  return port.raw();
}


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_closeInternal, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, id, arguments->NativeArgAt(0));
  PortMap::ClosePort(id.Value());
  return Object::null();
}


DEFINE_NATIVE_ENTRY(SendPortImpl_sendInternal_, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, send_id, arguments->NativeArgAt(0));
  // TODO(iposva): Allow for arbitrary messages to be sent.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(1));

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(obj);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(send_id.Value(),
                                   data, writer.BytesWritten(),
                                   Message::kNormalPriority));
  return Object::null();
}


static void ThrowIsolateSpawnException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}


static bool CanonicalizeUri(Isolate* isolate,
                            const Library& library,
                            const String& uri,
                            char** canonical_uri,
                            char** error) {
  Zone* zone = isolate->current_zone();
  bool retval = false;
  Dart_LibraryTagHandler handler = isolate->library_tag_handler();
  if (handler != NULL) {
    Dart_EnterScope();
    Dart_Handle result = handler(Dart_kCanonicalizeUrl,
                                 Api::NewHandle(isolate, library.raw()),
                                 Api::NewHandle(isolate, uri.raw()));
    const Object& obj = Object::Handle(Api::UnwrapHandle(result));
    if (obj.IsString()) {
      *canonical_uri = zone->MakeCopyOfString(String::Cast(obj).ToCString());
      retval = true;
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
  return retval;
}


static bool CreateIsolate(IsolateSpawnState* state, char** error) {
  Isolate* parent_isolate = Isolate::Current();

  Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
  if (callback == NULL) {
    *error = strdup("Null callback specified for isolate creation\n");
    Isolate::SetCurrent(parent_isolate);
    return false;
  }

  void* init_data = parent_isolate->init_callback_data();
  Isolate* child_isolate = reinterpret_cast<Isolate*>(
      (callback)(state->script_url(),
                 state->function_name(),
                 init_data,
                 error));
  if (child_isolate == NULL) {
    Isolate::SetCurrent(parent_isolate);
    return false;
  }
  state->set_isolate(reinterpret_cast<Isolate*>(child_isolate));

  Isolate::SetCurrent(parent_isolate);
  return true;
}


static RawObject* Spawn(NativeArguments* arguments, IsolateSpawnState* state) {
  // Create a new isolate.
  char* error = NULL;
  if (!CreateIsolate(state, &error)) {
    delete state;
    const String& msg = String::Handle(String::New(error));
    free(error);
    ThrowIsolateSpawnException(msg);
  }

  // Try to create a SendPort for the new isolate.
  const Object& port = Object::Handle(
      DartLibraryCalls::NewSendPort(state->isolate()->main_port()));
  if (port.IsError()) {
    state->Cleanup();
    delete state;
    Exceptions::PropagateError(Error::Cast(port));
  }

  // Start the new isolate if it is already marked as runnable.
  MutexLocker ml(state->isolate()->mutex());
  state->isolate()->set_spawn_state(state);
  if (state->isolate()->is_runnable()) {
    state->isolate()->Run();
  }

  return port.raw();
}


DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  if (closure.IsClosure()) {
    Function& func = Function::Handle();
    func = Closure::function(closure);
    if (func.IsImplicitClosureFunction() && func.is_static()) {
#if defined(DEBUG)
      Context& ctx = Context::Handle();
      ctx = Closure::context(closure);
      ASSERT(ctx.num_variables() == 0);
#endif
      return Spawn(arguments, new IsolateSpawnState(func));
    }
  }
  const String& msg = String::Handle(String::New(
      "Isolate.spawn expects to be passed a static or top-level function"));
  Exceptions::ThrowArgumentError(msg);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Isolate_spawnUri, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, uri, arguments->NativeArgAt(0));

  // Canonicalize the uri with respect to the current isolate.
  char* error = NULL;
  char* canonical_uri = NULL;
  const Library& root_lib =
      Library::Handle(arguments->isolate()->object_store()->root_library());
  if (!CanonicalizeUri(arguments->isolate(), root_lib, uri,
                       &canonical_uri, &error)) {
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  return Spawn(arguments, new IsolateSpawnState(canonical_uri));
}


DEFINE_NATIVE_ENTRY(Isolate_mainPort, 0) {
  const Object& port = Object::Handle(ReceivePortCreate(isolate->main_port()));
  if (port.IsError()) {
    Exceptions::PropagateError(Error::Cast(port));
  }

  // The control port is being accessed as a regular port from Dart code. This
  // is most likely due to the _startIsolate code in dart:isolate. Account for
  // this by increasing the number of open control ports.
  isolate->message_handler()->increment_control_ports();

  return port.raw();
}

}  // namespace dart
