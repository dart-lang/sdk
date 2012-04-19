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


static uint8_t* SerializeObject(const Instance& obj) {
  uint8_t* result = NULL;
  SnapshotWriter writer(Snapshot::kMessage, &result, &allocator);
  writer.WriteObject(obj.raw());
  writer.FinalizeBuffer();
  return result;
}


static void StoreError(Isolate* isolate, const Object& obj) {
  ASSERT(obj.IsError());
  Error& error = Error::Handle();
  error ^= obj.raw();
  isolate->object_store()->set_sticky_error(error);
}


static void ThrowErrorException(Exceptions::ExceptionType type,
                                const char* error_msg,
                                const char* library_url,
                                const char* class_name) {
  String& str = String::Handle();
  String& name = String::Handle();
  str ^= String::New(error_msg);
  name ^= String::NewSymbol(library_url);
  str ^= String::Concat(str, name);
  name ^= String::New(":");
  str ^= String::Concat(str, name);
  name ^= String::NewSymbol(class_name);
  str ^= String::Concat(str, name);
  GrowableArray<const Object*> arguments(1);
  arguments.Add(&str);
  Exceptions::ThrowByType(type, arguments);
}


// TODO(turnidge): Move to DartLibraryCalls.
RawObject* ReceivePortCreate(intptr_t port_id) {
  Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
  ASSERT(!isolate_lib.IsNull());
  const String& public_class_name =
      String::Handle(String::NewSymbol("_ReceivePortImpl"));
  const String& class_name =
      String::Handle(isolate_lib.PrivateName(public_class_name));
  const String& function_name =
      String::Handle(String::NewSymbol("_get_or_create"));
  const int kNumArguments = 1;
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveStatic(isolate_lib,
                              class_name,
                              function_name,
                              kNumArguments,
                              kNoArgumentNames,
                              Resolver::kIsQualified));
  GrowableArray<const Object*> arguments(kNumArguments);
  arguments.Add(&Integer::Handle(Integer::New(port_id)));
  const Object& result = Object::Handle(
      DartEntry::InvokeStatic(function, arguments, kNoArgumentNames));
  if (!result.IsError()) {
    PortMap::SetLive(port_id);
  }
  return result.raw();
}


static bool RunIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  IsolateStartData* data =
      reinterpret_cast<IsolateStartData*>(isolate->spawn_data());
  isolate->set_spawn_data(NULL);
  char* library_url = data->library_url_;
  char* class_name = data->class_name_;
  intptr_t port_id = data->port_id_;
  delete data;

  {
    StartIsolateScope start_scope(isolate);
    Zone zone(isolate);
    HandleScope handle_scope(isolate);
    ASSERT(ClassFinalizer::FinalizePendingClasses());
    // Lookup the target class by name, create an instance and call the run
    // method.
    const String& lib_name = String::Handle(String::NewSymbol(library_url));
    free(library_url);
    const Library& lib = Library::Handle(Library::LookupLibrary(lib_name));
    ASSERT(!lib.IsNull());
    const String& cls_name = String::Handle(String::NewSymbol(class_name));
    free(class_name);
    const Class& target_class = Class::Handle(lib.LookupClass(cls_name));
    // TODO(iposva): Deserialize or call the constructor after allocating.
    // For now, we only support a non-parameterized or raw target class.
    const Instance& target = Instance::Handle(Instance::New(target_class));
    Object& result = Object::Handle();

    // Invoke the default constructor.
    const String& period = String::Handle(String::New("."));
    String& constructor_name = String::Handle(String::Concat(cls_name, period));
    const Function& default_constructor =
        Function::Handle(target_class.LookupConstructor(constructor_name));
    if (!default_constructor.IsNull()) {
      GrowableArray<const Object*> arguments(1);
      arguments.Add(&target);
      arguments.Add(&Smi::Handle(Smi::New(Function::kCtorPhaseAll)));
      const Array& kNoArgumentNames = Array::Handle();
      result = DartEntry::InvokeStatic(default_constructor,
                                       arguments,
                                       kNoArgumentNames);
      if (result.IsError()) {
        StoreError(isolate, result);
        return false;
      }
      ASSERT(result.IsNull());
    }

    // Invoke the "_run" method.
    const Function& target_function = Function::Handle(Resolver::ResolveDynamic(
        target, String::Handle(String::NewSymbol("_run")), 2, 0));
    // TODO(iposva): Proper error checking here.
    ASSERT(!target_function.IsNull());
    // TODO(iposva): Allocate the proper port number here.
    const Object& local_port = Object::Handle(ReceivePortCreate(port_id));
    if (local_port.IsError()) {
      StoreError(isolate, local_port);
      return false;
    }
    GrowableArray<const Object*> arguments(1);
    arguments.Add(&local_port);
    const Array& kNoArgumentNames = Array::Handle();
    result = DartEntry::InvokeDynamic(target,
                                      target_function,
                                      arguments,
                                      kNoArgumentNames);
    if (result.IsError()) {
      StoreError(isolate, result);
      return false;
    }
    ASSERT(result.IsNull());
  }
  return true;
}


static void ShutdownIsolate(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  {
    // Print the error if there is one.  This may execute dart code to
    // print the exception object, so we need to use a StartIsolateScope.
    StartIsolateScope start_scope(isolate);
    Zone zone(isolate);
    HandleScope handle_scope(isolate);
    Error& error = Error::Handle();
    error = isolate->object_store()->sticky_error();
    if (!error.IsNull()) {
      OS::PrintErr("%s\n", error.ToErrorCString());
      exit(255);
    }
  }
  {
    // Shut the isolate down.
    SwitchIsolateScope switch_scope(isolate);
    Dart::ShutdownIsolate();
  }
}


static bool CheckArguments(const char* library_url, const char* class_name) {
  Isolate* isolate = Isolate::Current();
  Zone zone(isolate);
  HandleScope handle_scope(isolate);
  String& name = String::Handle();
  if (!ClassFinalizer::FinalizePendingClasses()) {
    return false;
  }
  // Lookup the target class by name, create an instance and call the run
  // method.
  name ^= String::NewSymbol(library_url);
  const Library& lib = Library::Handle(Library::LookupLibrary(name));
  if (lib.IsNull()) {
    const String& error_str = String::Handle(
        String::New("Error starting Isolate, library not loaded : "));
    const Error& error = Error::Handle(LanguageError::New(error_str));
    Isolate::Current()->object_store()->set_sticky_error(error);
    return false;
  }
  name ^= String::NewSymbol(class_name);
  const Class& target_class = Class::Handle(lib.LookupClass(name));
  if (target_class.IsNull()) {
    const String& error_str = String::Handle(
        String::New("Error starting Isolate, class not loaded : "));
    const Error& error = Error::Handle(LanguageError::New(error_str));
    Isolate::Current()->object_store()->set_sticky_error(error);
    return false;
  }
  return true;  // No errors.
}


static char* BuildIsolateName(const char* script_name,
                              const char* class_name,
                              const char* func_name) {
  // Skip past any slashes in the script name.
  const char* last_slash = strrchr(script_name, '/');
  if (last_slash != NULL) {
    script_name = last_slash + 1;
  }

  char* chars = NULL;
  if (class_name && class_name[0] != '\0') {
    const char* kFormat = "%s/%s.%s";
    intptr_t len = OS::SNPrint(NULL, 0, kFormat, script_name, class_name,
                               func_name) + 1;
    chars = reinterpret_cast<char*>(
        Isolate::Current()->current_zone()->Allocate(len));
    OS::SNPrint(chars, len, kFormat, script_name, class_name, func_name);
  } else {
    const char* kFormat = "%s/%s";
    intptr_t len = OS::SNPrint(NULL, 0, kFormat, script_name, func_name) + 1;
    chars = reinterpret_cast<char*>(
        Isolate::Current()->current_zone()->Allocate(len));
    OS::SNPrint(chars, len, kFormat, script_name, func_name);
  }
  return chars;
}


DEFINE_NATIVE_ENTRY(IsolateNatives_start, 2) {
  Isolate* preserved_isolate = Isolate::Current();
  GET_NATIVE_ARGUMENT(Instance, runnable, arguments->At(0));
  // arguments->At(1) unused.
  const Class& runnable_class = Class::Handle(runnable.clazz());
  const char* class_name = String::Handle(runnable_class.Name()).ToCString();
  const Library& library = Library::Handle(runnable_class.library());
  ASSERT(!library.IsNull());
  const char* library_url = String::Handle(library.url()).ToCString();
  intptr_t port_id = 0;
  LongJump jump;
  bool init_successful = true;
  Isolate* spawned_isolate = NULL;
  void* callback_data = preserved_isolate->init_callback_data();
  char* error = NULL;
  Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
  const char* isolate_name = BuildIsolateName(library_url, class_name, "main");
  if (callback == NULL) {
    error = strdup("Null callback specified for isolate creation\n");
  } else if (callback(isolate_name, callback_data, &error)) {
    spawned_isolate = Isolate::Current();
    ASSERT(spawned_isolate != NULL);
    // Check arguments to see if the specified library and classes are
    // loaded, this check will throw an exception if they are not loaded.
    if (init_successful && CheckArguments(library_url, class_name)) {
      port_id = spawned_isolate->main_port();
      spawned_isolate->set_spawn_data(
          reinterpret_cast<uword>(
              new IsolateStartData(strdup(library_url),
                                   strdup(class_name),
                                   port_id)));
      Isolate::SetCurrent(NULL);
      spawned_isolate->message_handler()->Run(
          Dart::thread_pool(), RunIsolate, ShutdownIsolate,
          reinterpret_cast<uword>(spawned_isolate));
    } else {
      // Error spawning the isolate, maybe due to initialization errors or
      // errors while loading the application into spawned isolate, shut
      // it down and report error.
      // Make sure to grab the error message out of the isolate before it has
      // been shutdown and to allocate it in the preserved isolates zone.
      {
        Zone zone(spawned_isolate);
        HandleScope scope(spawned_isolate);
        const Error& err_obj = Error::Handle(
            spawned_isolate->object_store()->sticky_error());
        error = strdup(err_obj.ToErrorCString());
      }
      Dart::ShutdownIsolate();
      spawned_isolate = NULL;
    }
  }

  // Switch back to the original isolate and return.
  Isolate::SetCurrent(preserved_isolate);
  if (spawned_isolate == NULL) {
    // Unable to spawn isolate correctly, throw exception.
    ThrowErrorException(Exceptions::kIllegalArgument,
                        error,
                        library_url,
                        class_name);
  }

  // TODO(turnidge): Move this code up before we launch the new
  // thread.  That way we won't have a thread hanging around that we
  // can't talk to.
  const Object& port = Object::Handle(DartLibraryCalls::NewSendPort(port_id));
  if (port.IsError()) {
    Exceptions::PropagateError(port);
  }
  arguments->SetReturn(port);
}


DEFINE_NATIVE_ENTRY(ReceivePortImpl_factory, 1) {
  ASSERT(AbstractTypeArguments::CheckedHandle(arguments->At(0)).IsNull());
  intptr_t port_id =
      PortMap::CreatePort(arguments->isolate()->message_handler());
  const Object& port = Object::Handle(ReceivePortCreate(port_id));
  if (port.IsError()) {
    Exceptions::PropagateError(port);
  }
  arguments->SetReturn(port);
}


DEFINE_NATIVE_ENTRY(ReceivePortImpl_closeInternal, 1) {
  GET_NATIVE_ARGUMENT(Smi, id, arguments->At(0));
  PortMap::ClosePort(id.Value());
}


DEFINE_NATIVE_ENTRY(SendPortImpl_sendInternal_, 3) {
  GET_NATIVE_ARGUMENT(Smi, send_id, arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, reply_id, arguments->At(1));
  // TODO(iposva): Allow for arbitrary messages to be sent.
  GET_NATIVE_ARGUMENT(Instance, obj, arguments->At(2));
  uint8_t* data = SerializeObject(obj);

  // TODO(turnidge): Throw an exception when the return value is false?
  PortMap::PostMessage(new Message(
      send_id.Value(), reply_id.Value(), data, Message::kNormalPriority));
}


static void ThrowIllegalArgException(const String& message) {
  GrowableArray<const Object*> args(1);
  args.Add(&message);
  Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
}


static void ThrowIsolateSpawnException(const String& message) {
  GrowableArray<const Object*> args(1);
  args.Add(&message);
  Exceptions::ThrowByType(Exceptions::kIsolateSpawn, args);
}


class SpawnState {
 public:
  explicit SpawnState(const Function& func)
      : isolate_(NULL),
        library_url_(NULL),
        function_name_(NULL) {
    const Class& cls = Class::Handle(func.owner());
    ASSERT(cls.IsTopLevel());
    const Library& lib = Library::Handle(cls.library());
    const String& lib_url = String::Handle(lib.url());
    library_url_ = strdup(lib_url.ToCString());

    const String& func_name = String::Handle(func.name());
    function_name_ = strdup(func_name.ToCString());
  }

  ~SpawnState() {
    free(library_url_);
    free(function_name_);
  }

  Isolate* isolate() const { return isolate_; }
  void set_isolate(Isolate* value) { isolate_ = value; }
  char* library_url() const { return library_url_; }
  char* function_name() const { return function_name_; }

  RawFunction* ResolveFunction() {
    const String& lib_url =
        String::Handle(String::NewSymbol(library_url()));
    const String& func_name =
        String::Handle(String::NewSymbol(function_name()));

    const Library& lib = Library::Handle(Library::LookupLibrary(lib_url));
    if (lib.IsNull() || lib.IsError()) {
      return Function::null();
    }
    return lib.LookupLocalFunction(func_name);
  }

  void Cleanup() {
    SwitchIsolateScope switch_scope(isolate());
    Dart::ShutdownIsolate();
  }

 private:
  Isolate* isolate_;
  char* library_url_;
  char* function_name_;
};


static bool CreateIsolate(SpawnState* state, char** error) {
  Isolate* parent_isolate = Isolate::Current();

  Dart_IsolateCreateCallback callback = Isolate::CreateCallback();
  ASSERT(callback);
  const char* isolate_name = BuildIsolateName(state->library_url(),
                                              "",
                                              state->function_name());
  void* init_data = parent_isolate->init_callback_data();
  bool retval = (callback)(isolate_name, init_data, error);
  if (retval) {
    Isolate* child_isolate = Isolate::Current();
    ASSERT(child_isolate);
    state->set_isolate(child_isolate);

    // Attempt to resolve the entry function now, so that we fail fast
    // in the case that the embedder's isolate create callback is
    // violating its contract.
    //
    // TODO(turnidge): Revisit this once we have an isolate death api.
    {
      Zone zone(child_isolate);
      HandleScope handle_scope(child_isolate);
      const Function& func = Function::Handle(state->ResolveFunction());
      if (func.IsNull()) {
        *error = strdup(zone.PrintToString(
            "Internal error while starting isolate '%s': "
            "unable to resolve entry function '%s'.",
            child_isolate->name(), state->function_name()));
        retval = false;
      }
    }
  }
  if (!retval) {
    Dart::ShutdownIsolate();
  }
  Isolate::SetCurrent(parent_isolate);
  return retval;
}


static bool RunIsolate2(uword parameter) {
  Isolate* isolate = reinterpret_cast<Isolate*>(parameter);
  SpawnState* state = reinterpret_cast<SpawnState*>(isolate->spawn_data());
  isolate->set_spawn_data(NULL);
  {
    StartIsolateScope start_scope(isolate);
    Zone zone(isolate);
    HandleScope handle_scope(isolate);
    ASSERT(ClassFinalizer::FinalizePendingClasses());
    Object& result = Object::Handle();

    const Function& func = Function::Handle(state->ResolveFunction());
    delete state;
    state = NULL;
    ASSERT(!func.IsNull());

    GrowableArray<const Object*> args(0);
    const Array& kNoArgNames = Array::Handle();
    result = DartEntry::InvokeStatic(func, args, kNoArgNames);
    if (result.IsError()) {
      StoreError(isolate, result);
      return false;
    }
  }
  return true;
}


DEFINE_NATIVE_ENTRY(isolate_spawnFunction, 1) {
  GET_NATIVE_ARGUMENT(Closure, closure, arguments->At(0));
  const Function& func = Function::Handle(closure.function());
  const Class& cls = Class::Handle(func.owner());
  if (!func.IsClosureFunction() || !func.is_static() || !cls.IsTopLevel()) {
    const String& msg = String::Handle(String::New(
        "spawnFunction expects to be passed a closure to a top-level static "
        "function"));
    ThrowIllegalArgException(msg);
  }

#if defined(DEBUG)
  const Context& ctx = Context::Handle(closure.context());
  ASSERT(ctx.num_variables() == 0);
#endif

  // Create a new isolate.
  char* error = NULL;
  SpawnState* state = new SpawnState(func);
  if (!CreateIsolate(state, &error)) {
    delete state;
    const String& msg = String::Handle(String::New(error));
    ThrowIsolateSpawnException(msg);
  }

  // Try to create a SendPort for the new isolate.
  const Object& port = Object::Handle(
      DartLibraryCalls::NewSendPort(state->isolate()->main_port()));
  if (port.IsError()) {
    state->Cleanup();
    delete state;
    Exceptions::PropagateError(port);
  }

  // Start the new isolate.
  state->isolate()->set_spawn_data(reinterpret_cast<uword>(state));
  state->isolate()->message_handler()->Run(
      Dart::thread_pool(), RunIsolate2, ShutdownIsolate,
      reinterpret_cast<uword>(state->isolate()));

  arguments->SetReturn(port);
}


DEFINE_NATIVE_ENTRY(isolate_getPortInternal, 0) {
  const Object& port = Object::Handle(ReceivePortCreate(isolate->main_port()));
  if (port.IsError()) {
    Exceptions::PropagateError(port);
  }
  arguments->SetReturn(port);
}

}  // namespace dart
