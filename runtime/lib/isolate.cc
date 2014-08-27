// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_native_api.h"
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
#include "vm/snapshot.h"
#include "vm/symbols.h"

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


DEFINE_NATIVE_ENTRY(RawReceivePortImpl_factory, 1) {
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
  Dart_Port port_id =
      PortMap::CreatePort(arguments->isolate()->message_handler());
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
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(obj);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(port.Id(),
                                   data, writer.BytesWritten(),
                                   Message::kNormalPriority));
  return Object::null();
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


class SpawnIsolateTask : public ThreadPool::Task {
 public:
  explicit SpawnIsolateTask(IsolateSpawnState* state)
      : state_(state) {
  }

  virtual void Run() {
    // Create a new isolate.
    char* error = NULL;
    Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
    if (callback == NULL) {
      ReportError(
          "Isolate spawn is not supported by this Dart implementation.\n");
      delete state_;
      return;
    }

    Isolate* isolate = reinterpret_cast<Isolate*>(
        (callback)(state_->script_url(),
                   state_->function_name(),
                   state_->init_data(),
                   &error));
    if (isolate == NULL) {
      // We were unable to create the child isolate.  Report the error
      // back to the parent isolate.
      ReportError(error);
      delete state_;
      return;
    }

    MutexLocker ml(isolate->mutex());
    state_->set_isolate(reinterpret_cast<Isolate*>(isolate));
    isolate->set_spawn_state(state_);
    if (isolate->is_runnable()) {
      // Start the new isolate if it has been marked as runnable.
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


DEFINE_NATIVE_ENTRY(Isolate_spawnFunction, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(2));
  if (closure.IsClosure()) {
    Function& func = Function::Handle();
    func = Closure::function(closure);
    if (func.IsImplicitClosureFunction() && func.is_static()) {
#if defined(DEBUG)
      Context& ctx = Context::Handle();
      ctx = Closure::context(closure);
      ASSERT(ctx.num_variables() == 0);
#endif
      Dart::thread_pool()->Run(new SpawnIsolateTask(
          new IsolateSpawnState(port.Id(),
                                isolate->init_callback_data(),
                                func, message)));
      return Object::null();
    }
  }
  const String& msg = String::Handle(String::New(
      "Isolate.spawn expects to be passed a static or top-level function"));
  Exceptions::ThrowArgumentError(msg);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Isolate_spawnUri, 4) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, uri, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, args, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, message, arguments->NativeArgAt(3));

  // Canonicalize the uri with respect to the current isolate.
  char* error = NULL;
  char* canonical_uri = NULL;
  const Library& root_lib =
      Library::Handle(arguments->isolate()->object_store()->root_library());
  if (!CanonicalizeUri(arguments->isolate(), root_lib, uri,
                       &canonical_uri, &error)) {
    const String& message = String::Handle(String::New(error));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, message);
    Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
  }

  Dart::thread_pool()->Run(new SpawnIsolateTask(
      new IsolateSpawnState(port.Id(),
                            isolate->init_callback_data(),
                            canonical_uri,
                            args, message)));
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Isolate_sendOOB, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, port, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, msg, arguments->NativeArgAt(1));

  // Make sure to route this request to the isolate library OOB mesage handler.
  msg.SetAt(0, Smi::Handle(Smi::New(Message::kIsolateLibOOBMsg)));

  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(msg);

  PortMap::PostMessage(new Message(port.Id(),
                                   data, writer.BytesWritten(),
                                   Message::kOOBPriority));
  return Object::null();
}

}  // namespace dart
