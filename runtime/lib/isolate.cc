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
#include "vm/message.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/snapshot.h"
#include "vm/thread.h"

namespace dart {

class IsolateStartData {
 public:
  IsolateStartData(Isolate* isolate,
                   char* library_url,
                   char* class_name,
                   intptr_t port_id)
      : isolate_(isolate),
        library_url_(library_url),
        class_name_(class_name),
        port_id_(port_id) {}

  Isolate* isolate_;
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


static void ProcessError(const Object& obj) {
  ASSERT(obj.IsError());
  Error& error = Error::Handle();
  error ^= obj.raw();
  OS::PrintErr("%s\n", error.ToErrorCString());
  exit(255);
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


static void RunIsolate(uword parameter) {
  IsolateStartData* data = reinterpret_cast<IsolateStartData*>(parameter);
  Isolate* isolate = data->isolate_;
  char* library_url = data->library_url_;
  char* class_name = data->class_name_;
  intptr_t port_id = data->port_id_;
  delete data;

  Isolate::SetCurrent(isolate);
  // Intialize stack limit in case we are running isolate in a
  // different thread than in which it was initialized.
  isolate->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(&isolate));
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    Zone zone(isolate);
    HandleScope handle_scope(isolate);
    ASSERT(ClassFinalizer::FinalizePendingClasses());
    // Lookup the target class by name, create an instance and call the run
    // method.
    const String& lib_name = String::Handle(String::NewSymbol(library_url));
    const Library& lib = Library::Handle(Library::LookupLibrary(lib_name));
    ASSERT(!lib.IsNull());
    const String& cls_name = String::Handle(String::NewSymbol(class_name));
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
        ProcessError(result);
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
      ProcessError(local_port);
    }
    GrowableArray<const Object*> arguments(1);
    arguments.Add(&local_port);
    const Array& kNoArgumentNames = Array::Handle();
    result = DartEntry::InvokeDynamic(target,
                                      target_function,
                                      arguments,
                                      kNoArgumentNames);
    if (result.IsError()) {
      ProcessError(result);
    }
    ASSERT(result.IsNull());
    free(class_name);
    free(library_url);
    result = isolate->StandardRunLoop();
    if (result.IsError()) {
      ProcessError(result);
    }
    ASSERT(result.IsNull());

  } else {
    Zone zone(isolate);
    HandleScope handle_scope(isolate);
    const Error& error = Error::Handle(
        Isolate::Current()->object_store()->sticky_error());
    const char* errmsg = error.ToErrorCString();
    OS::PrintErr("%s\n", errmsg);
    exit(255);
  }
  isolate->set_long_jump_base(base);
  Dart::ShutdownIsolate();
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

  const char* kFormat = "%s/%s.%s";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, script_name, class_name,
                             func_name) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, script_name, class_name, func_name);
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
      uword data = reinterpret_cast<uword>(
          new IsolateStartData(spawned_isolate,
                               strdup(library_url),
                               strdup(class_name),
                               port_id));
      int result = Thread::Start(RunIsolate, data);
      if (result != 0) {
        FATAL1("Failed to start isolate thread %d", result);
      }
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

}  // namespace dart
