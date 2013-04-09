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

class IsolateStartData {
 public:
  IsolateStartData(char* library_url,
                   char* class_name,
                   intptr_t port_id)
      : library_url_(library_url),
        class_name_(class_name),
        port_id_(port_id) {}

  char* library_url_;
  char* class_name_;
  intptr_t port_id_;
};


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


// TODO(turnidge): Move to DartLibraryCalls.
static RawObject* ReceivePortCreate(intptr_t port_id) {
  Isolate* isolate = Isolate::Current();
  Function& func =
      Function::Handle(isolate,
                       isolate->object_store()->receive_port_create_function());
  const int kNumArguments = 1;
  if (func.IsNull()) {
    Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_ReceivePortImpl()));
    const String& function_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_get_or_create()));
    func = Resolver::ResolveStatic(isolate_lib,
                                   class_name,
                                   function_name,
                                   kNumArguments,
                                   Object::empty_array(),
                                   Resolver::kIsQualified);
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


DEFINE_NATIVE_ENTRY(ReceivePortImpl_factory, 1) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  intptr_t port_id =
      PortMap::CreatePort(arguments->isolate()->message_handler());
  const Object& port = Object::Handle(ReceivePortCreate(port_id));
  if (port.IsError()) {
    Exceptions::PropagateError(Error::Cast(port));
  }
  return port.raw();
}


DEFINE_NATIVE_ENTRY(ReceivePortImpl_closeInternal, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, id, arguments->NativeArgAt(0));
  PortMap::ClosePort(id.Value());
  return Object::null();
}


DEFINE_NATIVE_ENTRY(SendPortImpl_sendInternal_, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, send_id, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, reply_id, arguments->NativeArgAt(1));
  // TODO(iposva): Allow for arbitrary messages to be sent.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, obj, arguments->NativeArgAt(2));

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(obj);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(send_id.Value(), reply_id.Value(),
                                   data, writer.BytesWritten(),
                                   Message::kNormalPriority));
  return Object::null();
}


static void ThrowIllegalArgException(const String& message) {
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);
  Exceptions::ThrowByType(Exceptions::kArgument, args);
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
    Dart_Handle result = handler(kCanonicalizeUrl,
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
  state->isolate()->set_spawn_data(reinterpret_cast<uword>(state));
  if (state->isolate()->is_runnable()) {
    state->isolate()->Run();
  }

  return port.raw();
}


DEFINE_NATIVE_ENTRY(isolate_spawnFunction, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  bool throw_exception = false;
  Function& func = Function::Handle();
  if (closure.IsClosure()) {
    func = Closure::function(closure);
    const Class& cls = Class::Handle(func.Owner());
    if (!func.IsClosureFunction() || !func.is_static() || !cls.IsTopLevel()) {
      throw_exception = true;
    }
  } else {
    throw_exception = true;
  }
  if (throw_exception) {
    const String& msg = String::Handle(String::New(
        "spawnFunction expects to be passed a closure to a top-level static "
        "function"));
    ThrowIllegalArgException(msg);
  }

  GET_NATIVE_ARGUMENT(Instance, callback, arguments->NativeArgAt(1));
  Function& callback_func = Function::Handle();
  if (callback.IsClosure()) {
    callback_func = Closure::function(callback);
    const Class& cls = Class::Handle(callback_func.Owner());
    if (!callback_func.IsClosureFunction() || !callback_func.is_static() ||
        !cls.IsTopLevel()) {
      throw_exception = true;
    }
  } else if (!callback.IsNull()) {
    throw_exception = true;
  }
  if (throw_exception) {
    const String& msg = String::Handle(String::New(
        "spawnFunction expects to be passed either a unhandled exception "
        "callback to a top-level static function, or null"));
    ThrowIllegalArgException(msg);
  }

#if defined(DEBUG)
  Context& ctx = Context::Handle();
  ctx = Closure::context(closure);
  ASSERT(ctx.num_variables() == 0);
  if (!callback.IsNull()) {
    ctx = Closure::context(callback);
    ASSERT(ctx.num_variables() == 0);
  }
#endif

  return Spawn(arguments, new IsolateSpawnState(func, callback_func));
}


DEFINE_NATIVE_ENTRY(isolate_spawnUri, 1) {
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


DEFINE_NATIVE_ENTRY(isolate_getPortInternal, 0) {
  const Object& port = Object::Handle(ReceivePortCreate(isolate->main_port()));
  if (port.IsError()) {
    Exceptions::PropagateError(Error::Cast(port));
  }
  return port.raw();
}

}  // namespace dart
