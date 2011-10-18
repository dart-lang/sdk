// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

#include "vm/bigint_operations.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debuginfo.h"
#include "vm/exceptions.h"
#include "vm/growable_array.h"
#include "vm/longjump.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/snapshot.h"
#include "vm/stack_frame.h"
#include "vm/timer.h"
#include "vm/verifier.h"

namespace dart {

// TODO(iposva): This is a placeholder for the eventual external Dart API.
DART_EXPORT bool Dart_Initialize(int argc,
                                 char** argv,
                                 Dart_IsolateInitCallback callback) {
  return Dart::InitOnce(argc, argv, callback);
}


DART_EXPORT Dart_Isolate Dart_CreateIsolate(const Dart_Snapshot* snapshot,
                                            void* data) {
  ASSERT(Isolate::Current() == NULL);
  Isolate* isolate = Dart::CreateIsolate(snapshot, data);
  START_TIMER(time_total_runtime);
  return reinterpret_cast<Dart_Isolate>(isolate);
}


DART_EXPORT void Dart_ShutdownIsolate() {
  ASSERT(Isolate::Current() != NULL);
  STOP_TIMER(time_total_runtime);
  Dart::ShutdownIsolate();
}


DART_EXPORT Dart_Isolate Dart_CurrentIsolate() {
  return reinterpret_cast<Dart_Isolate>(Isolate::Current());
}


DART_EXPORT void Dart_EnterIsolate(Dart_Isolate dart_isolate) {
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  ASSERT(Isolate::Current() == NULL);
  Isolate::SetCurrent(isolate);
}


DART_EXPORT void Dart_ExitIsolate() {
  ASSERT(Isolate::Current() != NULL);
  Isolate::SetCurrent(NULL);
}


static void SetupErrorResult(Dart_Result* result) {
  // Make a copy of the error message as the original message string
  // may get deallocated when we return back from the Dart API call.
  const String& error = String::Handle(
      Isolate::Current()->object_store()->sticky_error());
  const char* errmsg = error.ToCString();
  intptr_t errlen = strlen(errmsg) + 1;
  char* msg = reinterpret_cast<char*>(Api::Allocate(errlen));
  OS::SNPrint(msg, errlen, "%s", errmsg);
  result->type_ = kRetError;
  result->retval_.errmsg = msg;
}


DART_EXPORT void Dart_SetMessageCallbacks(
    Dart_PostMessageCallback post_message_callback,
    Dart_ClosePortCallback close_port_callback) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(post_message_callback != NULL);
  ASSERT(close_port_callback != NULL);
  isolate->set_post_message_callback(post_message_callback);
  isolate->set_close_port_callback(close_port_callback);
}


static RawInstance* DeserializeMessage(void* data) {
  // Create a snapshot object using the buffer.
  const Snapshot* snapshot = Snapshot::SetupFromBuffer(data);
  ASSERT(snapshot->IsPartialSnapshot());

  // Read object back from the snapshot.
  Isolate* isolate = Isolate::Current();
  SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
  Instance& instance = Instance::Handle();
  instance ^= reader.ReadObject();
  return instance.raw();
}


static void ProcessUnhandledException(const UnhandledException& uhe) {
  const Instance& exception = Instance::Handle(uhe.exception());
  Instance& strtmp = Instance::Handle(DartLibraryCalls::ToString(exception));
  const char* str = strtmp.ToCString();
  fprintf(stderr, "%s\n", str);
  const Instance& stack = Instance::Handle(uhe.stacktrace());
  strtmp = DartLibraryCalls::ToString(stack);
  str = strtmp.ToCString();
  fprintf(stderr, "%s\n", str);
  exit(255);
}


DART_EXPORT void Dart_HandleMessage(Dart_Port dest_port,
                                    Dart_Port reply_port,
                                    Dart_Message dart_message) {
  const Instance& msg = Instance::Handle(DeserializeMessage(dart_message));
  const String& class_name =
      String::Handle(String::NewSymbol("ReceivePortImpl"));
  const String& function_name =
      String::Handle(String::NewSymbol("handleMessage_"));
  const int kNumArguments = 3;
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveStatic(Library::Handle(Library::CoreLibrary()),
                              class_name,
                              function_name,
                              kNumArguments,
                              kNoArgumentNames,
                              Resolver::kIsQualified));
  GrowableArray<const Object*> arguments(kNumArguments);
  arguments.Add(&Integer::Handle(Integer::New(dest_port)));
  arguments.Add(&Integer::Handle(Integer::New(reply_port)));
  arguments.Add(&msg);
  const Object& result = Object::Handle(
      DartEntry::InvokeStatic(function, arguments, kNoArgumentNames));
  if (result.IsUnhandledException()) {
    UnhandledException& uhe = UnhandledException::Handle();
    uhe ^= result.raw();
    // TODO(turnidge): Instead of exiting here, just return the
    // exception so that the embedder can choose how to handle this
    // case.
    ProcessUnhandledException(uhe);
  }
  ASSERT(result.IsNull());
}


DART_EXPORT Dart_Result Dart_RunLoop() {
  Isolate* isolate = Isolate::Current();
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  Dart_Result result;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    isolate->StandardRunLoop();
    result.type_ = kRetCBool;
    result.retval_.bool_value = true;
  } else {
    Zone zone;
    HandleScope handle_scope;
    SetupErrorResult(&result);
  }
  isolate->set_long_jump_base(base);
  return result;
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void CompileSource(const Library& lib,
                          const String& url,
                          const String& source,
                          RawScript::Kind kind,
                          Dart_Result* result) {
  const Script& script = Script::Handle(Script::New(url, source, kind));
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    Compiler::Compile(lib, script);
    result->type_ = kRetObject;
    result->retval_.obj_value = Api::NewLocalHandle(lib);
  } else {
    SetupErrorResult(result);
  }
  isolate->set_long_jump_base(base);
}


DART_EXPORT Dart_Result Dart_LoadScript(Dart_Handle url,
                                        Dart_Handle source,
                                        Dart_LibraryTagHandler handler) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  TIMERSCOPE(time_script_loading);
  const String& url_str = String::CheckedHandle(Api::UnwrapHandle(url));
  const String& source_str = String::CheckedHandle(Api::UnwrapHandle(source));
  Library& library = Library::Handle(isolate->object_store()->root_library());
  if (!library.IsNull()) {
    RETURN_FAILURE("Script already loaded");
  }
  isolate->set_library_tag_handler(handler);
  library = Library::New(url_str);
  library.Register();
  Dart_Result result;
  CompileSource(library, url_str, source_str, RawScript::kScript, &result);
  return result;
}


DEFINE_FLAG(bool, compile_all, false, "Eagerly compile all code.");

static void CompileAll(Dart_Result* result) {
  result->type_ = kRetCBool;
  result->retval_.bool_value = true;
  if (FLAG_compile_all) {
    Isolate* isolate = Isolate::Current();
    ASSERT(isolate != NULL);
    LongJump* base = isolate->long_jump_base();
    LongJump jump;
    isolate->set_long_jump_base(&jump);
    if (setjmp(*jump.Set()) == 0) {
      Library::CompileAll();
    } else {
      SetupErrorResult(result);
    }
    isolate->set_long_jump_base(base);
  }
}


// Return error if isolate is in an inconsistent state.
// Return NULL when no error condition exists.
static const char* CheckIsolateState() {
  if (!ClassFinalizer::FinalizePendingClasses()) {
    // Make a copy of the error message as the original message string
    // may get deallocated when we return back from the Dart API call.
    const String& err =
    String::Handle(Isolate::Current()->object_store()->sticky_error());
    const char* errmsg = err.ToCString();
    intptr_t errlen = strlen(errmsg) + 1;
    char* msg = reinterpret_cast<char*>(Api::Allocate(errlen));
    OS::SNPrint(msg, errlen, "%s", errmsg);
    return msg;
  }
  return NULL;
}


DART_EXPORT Dart_Result Dart_CompileAll() {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  Dart_Result result;
  const char* msg = CheckIsolateState();
  if (msg != NULL) {
    RETURN_FAILURE(msg);
  }
  CompileAll(&result);
  return result;
}


DART_EXPORT bool Dart_IsLibrary(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsLibrary();
}


DART_EXPORT Dart_Result Dart_LibraryUrl(Dart_Handle library) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Library& lib = Library::CheckedHandle(Api::UnwrapHandle(library));
  if (lib.IsNull()) {
    RETURN_FAILURE("Null library");
  }
  const String& url = String::Handle(lib.url());
  ASSERT(!url.IsNull());
  RETURN_OBJECT(url);
}


DART_EXPORT Dart_Result Dart_LibraryImportLibrary(Dart_Handle library_in,
                                                  Dart_Handle import_in) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Library& library =
      Library::CheckedHandle(Api::UnwrapHandle(library_in));
  if (library.IsNull()) {
    RETURN_FAILURE("Null library");
  }
  const Library& import =
      Library::CheckedHandle(Api::UnwrapHandle(import_in));
  library.AddImport(import);
  RETURN_CBOOLEAN(true);
}


DART_EXPORT Dart_Result Dart_LookupLibrary(Dart_Handle url) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& url_str = String::CheckedHandle(Api::UnwrapHandle(url));
  const Library& library = Library::Handle(Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    RETURN_FAILURE("Unknown library");
  } else {
    RETURN_OBJECT(library);
  }
}


DART_EXPORT Dart_Result Dart_LoadLibrary(Dart_Handle url, Dart_Handle source) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& url_str = String::CheckedHandle(Api::UnwrapHandle(url));
  const String& source_str = String::CheckedHandle(Api::UnwrapHandle(source));
  Library& library = Library::Handle(Library::LookupLibrary(url_str));
  if (library.IsNull()) {
    library = Library::New(url_str);
    library.Register();
  }
  Dart_Result result;
  CompileSource(library, url_str, source_str, RawScript::kLibrary, &result);
  return result;
}


DART_EXPORT Dart_Result Dart_LoadSource(Dart_Handle library_in,
                                        Dart_Handle url_in,
                                        Dart_Handle source_in) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& url = String::CheckedHandle(Api::UnwrapHandle(url_in));
  const String& source = String::CheckedHandle(Api::UnwrapHandle(source_in));
  const Library& library =
      Library::CheckedHandle(Api::UnwrapHandle(library_in));
  Dart_Result result;
  CompileSource(library, url, source, RawScript::kSource, &result);
  return result;
}


DART_EXPORT Dart_Result Dart_SetNativeResolver(
    Dart_Handle library,
    Dart_NativeEntryResolver resolver) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Library& lib = Library::CheckedHandle(Api::UnwrapHandle(library));
  if (lib.IsNull()) {
    RETURN_FAILURE("Invalid parameter, Unknown library specified");
  }
  lib.set_native_entry_resolver(resolver);
  RETURN_CBOOLEAN(true);
}


DART_EXPORT Dart_Result Dart_ObjectToString(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  Object& result = Object::Handle();
  if (obj.IsString()) {
    result = obj.raw();
  } else if (obj.IsInstance()) {
    Instance& receiver = Instance::Handle();
    receiver ^= obj.raw();
    result = DartLibraryCalls::ToString(receiver);
    if (result.IsUnhandledException()) {
      RETURN_FAILURE("An exception occurred when converting to string");
    }
  } else {
    // This is a VM internal object. Call the C++ method of printing.
    result = String::New(obj.ToCString());
  }
  RETURN_OBJECT(result);
}


DART_EXPORT bool Dart_IsNull(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsNull();
}


DART_EXPORT bool Dart_IsClosure(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsClosure();
}


DART_EXPORT Dart_Result Dart_ClosureSmrck(Dart_Handle object) {
  Zone zone;
  HandleScope scope;
  const Closure& obj = Closure::CheckedHandle(Api::UnwrapHandle(object));
  const Integer& smrck = Integer::Handle(obj.smrck());
  RETURN_CINT64(smrck.IsNull() ? 0 : smrck.AsInt64Value());
}


DART_EXPORT void Dart_ClosureSetSmrck(Dart_Handle object, int64_t value) {
  Zone zone;
  HandleScope scope;
  const Closure& obj = Closure::CheckedHandle(Api::UnwrapHandle(object));
  const Integer& smrck = Integer::Handle(Integer::New(value));
  obj.set_smrck(smrck);
}


DART_EXPORT Dart_Result Dart_Objects_Equal(Dart_Handle obj1, Dart_Handle obj2) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Instance& expected = Instance::CheckedHandle(Api::UnwrapHandle(obj1));
  const Instance& actual = Instance::CheckedHandle(Api::UnwrapHandle(obj2));
  const Instance& result =
      Instance::Handle(DartLibraryCalls::Equals(expected, actual));
  if (result.IsBool()) {
    Bool& b = Bool::Handle();
    b ^= result.raw();
    RETURN_CBOOLEAN(b.value());
  } else {
    RETURN_FAILURE("An exception occured when calling '=='");
  }
}


DART_EXPORT Dart_Result Dart_GetClass(Dart_Handle library, Dart_Handle name) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString()) {
    RETURN_FAILURE("Invalid class name specified");
  }
  const Library& lib = Library::CheckedHandle(Api::UnwrapHandle(library));
  if (lib.IsNull()) {
    RETURN_FAILURE("Invalid parameter, Unknown library specified");
  }
  String& cls_name = String::Handle();
  cls_name ^= param.raw();
  const Class& cls = Class::Handle(lib.LookupClass(cls_name));
  if (cls.IsNull()) {
    RETURN_FAILURE("Specified class does not exist");
  }
  RETURN_OBJECT(cls);
}


// TODO(iposva): This call actually implements IsInstanceOfClass.
// Do we also need a real Dart_IsInstanceOf, which should take an instance
// rather than an object and a type rather than a class?
DART_EXPORT Dart_Result Dart_IsInstanceOf(Dart_Handle object,
                                          Dart_Handle clazz) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Class& cls = Class::CheckedHandle(Api::UnwrapHandle(clazz));
  if (cls.IsNull()) {
    RETURN_FAILURE("instanceof check against null class");
  }
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  Instance& instance = Instance::Handle();
  instance ^= obj.raw();
  // Finalize all classes.
  const char* msg = CheckIsolateState();
  if (msg != NULL) {
    RETURN_FAILURE(msg);
  }
  const Type& type = Type::Handle(Type::NewNonParameterizedType(cls));
  RETURN_CBOOLEAN(instance.Is(type));
}


// TODO(iposva): The argument should be an instance.
DART_EXPORT bool Dart_IsNumber(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsNumber();
}


DART_EXPORT bool Dart_IsInteger(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsInteger();
}


DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Integer& obj = Integer::Handle(Integer::New(value));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* str) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& str_obj = String::Handle(String::New(str));
  const Integer& obj = Integer::Handle(Integer::New(str_obj));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Result Dart_IntegerValue(Dart_Handle integer) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(integer));
  if (obj.IsSmi() || obj.IsMint()) {
    Integer& integer = Integer::Handle();
    integer ^= obj.raw();
    RETURN_CINT64(integer.AsInt64Value());
  }
  if (obj.IsBigint()) {
    Bigint& bigint = Bigint::Handle();
    bigint ^= obj.raw();
    if (BigintOperations::FitsIntoInt64(bigint)) {
      RETURN_CINT64(BigintOperations::ToInt64(bigint));
    } else {
      RETURN_CSTRING(BigintOperations::ToHexCString(bigint, &Api::Allocate));
    }
  }
  RETURN_FAILURE("Object is not a Integer");
}


DART_EXPORT Dart_Result Dart_IntegerFitsIntoInt64(Dart_Handle integer) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(integer));
  if (obj.IsSmi() || obj.IsMint()) {
    RETURN_CBOOLEAN(true);
  } else if (obj.IsBigint()) {
#if defined(DEBUG)
    Bigint& bigint = Bigint::Handle();
    bigint ^= obj.raw();
    ASSERT(!BigintOperations::FitsIntoInt64(bigint));
#endif
    RETURN_CBOOLEAN(false);
  }
  RETURN_FAILURE("Object is not a Integer");
}


DART_EXPORT bool Dart_IsBoolean(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsBool();
}


DART_EXPORT Dart_Handle Dart_NewBoolean(bool value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Bool& obj = Bool::Handle(Bool::Get(value));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Result Dart_BooleanValue(Dart_Handle bool_object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(bool_object));
  if (obj.IsBool()) {
    Bool& bool_obj = Bool::Handle();
    bool_obj ^= obj.raw();
    RETURN_CBOOLEAN(bool_obj.value());
  }
  RETURN_FAILURE("Object is not a Boolean");
}


DART_EXPORT bool Dart_IsDouble(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsDouble();
}


DART_EXPORT Dart_Handle Dart_NewDouble(double value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Double& obj = Double::Handle(Double::New(value));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Result Dart_DoubleValue(Dart_Handle integer) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(integer));
  if (obj.IsDouble()) {
    Double& double_obj = Double::Handle();
    double_obj ^= obj.raw();
    RETURN_CDOUBLE(double_obj.value());
  }
  RETURN_FAILURE("Object is not a Double");
}


DART_EXPORT bool Dart_IsString(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsString();
}


DART_EXPORT Dart_Result Dart_StringLength(Dart_Handle str) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle();
    string_obj ^= obj.raw();
    RETURN_CINT(string_obj.Length());
  }
  RETURN_FAILURE("Object is not a String");
}


DART_EXPORT Dart_Handle Dart_NewString(const char* str) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& obj = String::Handle(String::New(str));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Handle Dart_NewString8(const uint8_t* codepoints,
                                        intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& obj = String::Handle(String::New(codepoints, length));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Handle Dart_NewString16(const uint16_t* codepoints,
                                         intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const String& obj = String::Handle(String::New(codepoints, length));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Handle Dart_NewString32(const uint32_t* codepoints,
                                         intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  UNIMPLEMENTED();
  const String& obj = String::Handle(String::New(codepoints, length));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT bool Dart_IsString8(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsOneByteString();
}


DART_EXPORT bool Dart_IsString16(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsOneByteString() || obj.IsTwoByteString();
}


DART_EXPORT Dart_Result Dart_StringGet8(Dart_Handle str,
                                        uint8_t* codepoints,
                                        intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(str));
  if (obj.IsOneByteString()) {
    OneByteString& string_obj = OneByteString::Handle();
    string_obj ^= obj.raw();
    intptr_t str_len = string_obj.Length();
    intptr_t copy_len = (str_len > length) ? length : str_len;
    for (intptr_t i = 0; i < copy_len; i++) {
      codepoints[i] = static_cast<uint8_t>(string_obj.CharAt(i));
    }
    RETURN_CINT(copy_len);
  }
  RETURN_FAILURE(obj.IsString() ? "Object is not a String8" :
                                  "Object is not a String");
}


DART_EXPORT Dart_Result Dart_StringGet16(Dart_Handle str,
                                         uint16_t* codepoints,
                                         intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(str));
  if (obj.IsOneByteString() || obj.IsTwoByteString()) {
    String& string_obj = String::Handle();
    string_obj ^= obj.raw();
    intptr_t str_len = string_obj.Length();
    intptr_t copy_len = (str_len > length) ? length : str_len;
    for (intptr_t i = 0; i < copy_len; i++) {
      codepoints[i] = static_cast<uint16_t>(string_obj.CharAt(i));
    }
    RETURN_CINT(copy_len);
  }
  RETURN_FAILURE(obj.IsString() ? "Object is not a String16" :
                                  "Object is not a String");
}


DART_EXPORT Dart_Result Dart_StringGet32(Dart_Handle str,
                                         uint32_t* codepoints,
                                         intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(str));
  if (obj.IsString()) {
    String& string_obj = String::Handle();
    string_obj ^= obj.raw();
    intptr_t str_len = string_obj.Length();
    intptr_t copy_len = (str_len > length) ? length : str_len;
    for (intptr_t i = 0; i < copy_len; i++) {
      codepoints[i] = static_cast<uint32_t>(string_obj.CharAt(i));
    }
    RETURN_CINT(copy_len);
  }
  RETURN_FAILURE("Object is not a String");
}


DART_EXPORT Dart_Result Dart_StringToCString(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  if (obj.IsString()) {
    const char* string_value = obj.ToCString();
    intptr_t string_length = strlen(string_value);
    char* result = reinterpret_cast<char*>(Api::Allocate(string_length + 1));
    if (result == NULL) {
      RETURN_FAILURE("Unable to allocate memory");
    }
    strncpy(result, string_value, string_length + 1);
    ASSERT(result[string_length] == '\0');
    RETURN_CSTRING(result);
  }
  RETURN_FAILURE("Object is not a String");
}


DART_EXPORT bool Dart_IsArray(Dart_Handle object) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  return obj.IsArray();
}


DART_EXPORT Dart_Handle Dart_NewArray(intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Array& obj = Array::Handle(Array::New(length));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT Dart_Result Dart_GetLength(Dart_Handle array) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(array));
  if (obj.IsArray()) {
    Array& array_obj = Array::Handle();
    array_obj ^= obj.raw();
    RETURN_CINT(array_obj.Length());
  }
  RETURN_FAILURE("Object is not an Array");
}


DART_EXPORT Dart_Result Dart_ArrayGet(Dart_Handle array,
                                      intptr_t offset,
                                      uint8_t* native_array,
                                      intptr_t length) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(array));
  if (obj.IsArray()) {
    Array& array_obj = Array::Handle();
    array_obj ^= obj.raw();
    if ((offset + length) <= array_obj.Length()) {
      Object& element = Object::Handle();
      Integer& integer  = Integer::Handle();
      for (int i = 0; i < length; i++) {
        element = array_obj.At(offset + i);
        integer ^= element.raw();
        native_array[i] = static_cast<uint8_t>(integer.AsInt64Value() & 0xff);
        ASSERT(integer.AsInt64Value() <= 0xff);
        // TODO(hpayer): value should always be smaller then 0xff. Add error
        // handling.
       }
      RETURN_CINT(0);
    }
    RETURN_FAILURE("Invalid length passed in to access array elements");
  }
  RETURN_FAILURE("Object is not an Array");
}


DART_EXPORT Dart_Result Dart_ArrayGetAt(Dart_Handle array, intptr_t index) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(array));
  if (obj.IsArray()) {
    Array& array_obj = Array::Handle();
    array_obj ^= obj.raw();
    if ((index >= 0) && (index < array_obj.Length())) {
      const Object& element = Object::Handle(array_obj.At(index));
      RETURN_OBJECT(element);
    }
    RETURN_FAILURE("Invalid index passed in to access array element");
  }
  RETURN_FAILURE("Object is not an Array");
}


DART_EXPORT Dart_Result Dart_ArraySet(Dart_Handle array,
                                      intptr_t offset,
                                      uint8_t* native_array,
                                      intptr_t length) {
  Zone zone;
  HandleScope scope;
  const Object& obj = Object::Handle(Api::UnwrapHandle(array));
  if (obj.IsArray()) {
    Array& array_obj = Array::Handle();
    array_obj ^= obj.raw();
    Integer& integer = Integer::Handle();
    if ((offset + length) <= array_obj.Length()) {
      for (int i = 0; i < length; i++) {
        integer ^= Integer::New(native_array[i]);
        array_obj.SetAt(offset + i, integer);
      }
      RETURN_CINT(0);
    }
    RETURN_FAILURE("Invalid length passed in to set array elements");
  }
  RETURN_FAILURE("Object is not an Array");
}

DART_EXPORT Dart_Result Dart_ArraySetAt(Dart_Handle array,
                                        intptr_t index,
                                        Dart_Handle value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(array));
  if (obj.IsArray()) {
    Array& array_obj = Array::Handle();
    array_obj ^= obj.raw();
    const Object& value_obj = Object::Handle(Api::UnwrapHandle(value));
    if ((index >= 0) && (index < array_obj.Length())) {
      array_obj.SetAt(index, value_obj);
      RETURN_CINT(0);
    }
    RETURN_FAILURE("Invalid index passed in to set array element");
  }
  RETURN_FAILURE("Object is not an Array");
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void InvokeStatic(const Function& function,
                         GrowableArray<const Object*>& args,
                         Dart_Result* result) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    const Array& kNoArgumentNames = Array::Handle();
    const Instance& retval = Instance::Handle(
        DartEntry::InvokeStatic(function, args, kNoArgumentNames));
    result->type_ = kRetObject;
    result->retval_.obj_value = Api::NewLocalHandle(retval);
  } else {
    SetupErrorResult(result);
  }
  isolate->set_long_jump_base(base);
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void InvokeDynamic(const Instance& receiver,
                          const Function& function,
                          GrowableArray<const Object*>& args,
                          Dart_Result* result) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    const Array& kNoArgumentNames = Array::Handle();
    const Instance& retval = Instance::Handle(
        DartEntry::InvokeDynamic(receiver, function, args, kNoArgumentNames));
    result->type_ = kRetObject;
    result->retval_.obj_value = Api::NewLocalHandle(retval);
  } else {
    SetupErrorResult(result);
  }
  isolate->set_long_jump_base(base);
}


// NOTE: Need to pass 'result' as a parameter here in order to avoid
// warning: variable 'result' might be clobbered by 'longjmp' or 'vfork'
// which shows up because of the use of setjmp.
static void InvokeClosure(const Closure& closure,
                          GrowableArray<const Object*>& args,
                          Dart_Result* result) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    const Array& kNoArgumentNames = Array::Handle();
    const Instance& retval = Instance::Handle(
        DartEntry::InvokeClosure(closure, args, kNoArgumentNames));
    result->type_ = kRetObject;
    result->retval_.obj_value = Api::NewLocalHandle(retval);
  } else {
    SetupErrorResult(result);
  }
  isolate->set_long_jump_base(base);
}


DART_EXPORT Dart_Result Dart_InvokeStatic(Dart_Handle library_in,
                                          Dart_Handle class_name_in,
                                          Dart_Handle function_name_in,
                                          int number_of_arguments,
                                          Dart_Handle* arguments) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  // Finalize all classes.
  const char* msg = CheckIsolateState();
  if (msg != NULL) {
    RETURN_FAILURE(msg);
  }

  // Now try to resolve and invoke the static function.
  const Library& library =
      Library::CheckedHandle(Api::UnwrapHandle(library_in));
  if (library.IsNull()) {
    RETURN_FAILURE("No library specified");
  }
  const String& class_name =
      String::CheckedHandle(Api::UnwrapHandle(class_name_in));
  const String& function_name =
      String::CheckedHandle(Api::UnwrapHandle(function_name_in));
  const Function& function = Function::Handle(
      Resolver::ResolveStatic(library,
                              class_name,
                              function_name,
                              number_of_arguments,
                              Array::Handle(),  // Named arguments are not yet
                                                // supported in the API.
                              Resolver::kIsQualified));
  if (function.IsNull()) {
    char* msg;
    if (class_name.IsNull()) {
      const char* format = "Unable to find entrypoint: %s()";
      intptr_t length = OS::SNPrint(NULL, 0, format, function_name.ToCString());
      msg = reinterpret_cast<char*>(Api::Allocate(length + 1));
      OS::SNPrint(msg, (length + 1), format, function_name.ToCString());
    } else {
      const char* format = "Unable to find entrypoint: static %s.%s()";
      intptr_t length = OS::SNPrint(NULL, 0, format,
                                    class_name.ToCString(),
                                    function_name.ToCString());
      msg = reinterpret_cast<char*>(Api::Allocate(length + 1));
      OS::SNPrint(msg, (length + 1), format,
                  class_name.ToCString(), function_name.ToCString());
    }
    RETURN_FAILURE(msg);
  }
  Dart_Result retval;
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg = Object::Handle(Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  InvokeStatic(function, dart_arguments, &retval);
  return retval;
}


DART_EXPORT Dart_Result Dart_InvokeDynamic(Dart_Handle object,
                                           Dart_Handle function_name,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(object));
  // Let the resolver figure out the correct target for null receiver.
  // E.g., (null).toString() should execute correctly.
  if (!obj.IsNull() && !obj.IsInstance()) {
    RETURN_FAILURE("Invalid receiver (not instance) passed to invoke dynamic");
  }
  if (function_name == NULL) {
    RETURN_FAILURE("Invalid function name specified");
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Now try to resolve and invoke the dynamic function on this object.
  Instance& receiver = Instance::Handle();
  receiver ^= obj.raw();
  const String& name = String::CheckedHandle(Api::UnwrapHandle(function_name));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               name,
                               (number_of_arguments + 1),
                               0));  // Named args not yet supported in API.
  if (function.IsNull()) {
    // TODO(5415268): Invoke noSuchMethod instead of failing.
    OS::PrintErr("Unable to find instance function: %s\n", name.ToCString());
    RETURN_FAILURE("Unable to find instance function");
  }
  Dart_Result retval;
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg = Object::Handle(Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  InvokeDynamic(receiver, function, dart_arguments, &retval);
  return retval;
}


DART_EXPORT Dart_Result Dart_InvokeClosure(Dart_Handle closure,
                                           int number_of_arguments,
                                           Dart_Handle* arguments) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& obj = Object::Handle(Api::UnwrapHandle(closure));
  if (obj.IsNull()) {
    RETURN_FAILURE("Null object passed in to invoke closure");
  }
  if (!obj.IsClosure()) {
    RETURN_FAILURE("Invalid closure passed to invoke closure");
  }
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Now try to invoke the closure.
  Closure& closure_obj = Closure::Handle();
  closure_obj ^= obj.raw();
  Dart_Result retval;
  GrowableArray<const Object*> dart_arguments(number_of_arguments);
  for (int i = 0; i < number_of_arguments; i++) {
    const Object& arg = Object::Handle(Api::UnwrapHandle(arguments[i]));
    dart_arguments.Add(&arg);
  }
  InvokeClosure(closure_obj, dart_arguments, &retval);
  return retval;
}


DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  const Object& obj = Object::Handle(arguments->At(index));
  return Api::NewLocalHandle(obj);
}


DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  arguments->SetReturn(Object::Handle(Api::UnwrapHandle(retval)));
}


DART_EXPORT bool Dart_ExceptionOccurred(Dart_Handle result) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& retval  = Object::Handle(Api::UnwrapHandle(result));
  return retval.IsUnhandledException();
}


DART_EXPORT Dart_Result Dart_GetException(Dart_Handle result) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& retval = Object::Handle(Api::UnwrapHandle(result));
  if (retval.IsUnhandledException()) {
    const UnhandledException& unhandled = UnhandledException::Handle(
        reinterpret_cast<RawUnhandledException*>(retval.raw()));
    const Object& exception = Object::Handle(unhandled.exception());
    RETURN_OBJECT(exception);
  }
  RETURN_FAILURE("Object is not an unhandled exception object");
}


DART_EXPORT Dart_Result Dart_GetStacktrace(Dart_Handle unhandled_excp) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& retval = Object::Handle(Api::UnwrapHandle(unhandled_excp));
  if (retval.IsUnhandledException()) {
    const UnhandledException& unhandled = UnhandledException::Handle(
        reinterpret_cast<RawUnhandledException*>(retval.raw()));
    const Object& stacktrace = Object::Handle(unhandled.stacktrace());
    RETURN_OBJECT(stacktrace);
  }
  RETURN_FAILURE("Object is not an unhandled exception object");
}


DART_EXPORT Dart_Result Dart_ThrowException(Dart_Handle exception) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    RETURN_FAILURE("No Dart frames on stack, cannot throw exception");
  }
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Instance& excp = Instance::CheckedHandle(Api::UnwrapHandle(exception));
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->UnwindScopes(isolate->top_exit_frame_info());
  Exceptions::Throw(excp);
  RETURN_FAILURE("Exception was not thrown, internal error");
}


DART_EXPORT Dart_Result Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  if (isolate->top_exit_frame_info() == 0) {
    // There are no dart frames on the stack so it would be illegal to
    // throw an exception here.
    RETURN_FAILURE("No Dart frames on stack, cannot throw exception");
  }
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Instance& excp = Instance::CheckedHandle(Api::UnwrapHandle(exception));
  const Instance& stk = Instance::CheckedHandle(Api::UnwrapHandle(stacktrace));
  // Unwind all the API scopes till the exit frame before throwing an
  // exception.
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  state->UnwindScopes(isolate->top_exit_frame_info());
  Exceptions::ReThrow(excp, stk);
  RETURN_FAILURE("Exception was not re thrown, internal error");
}


DART_EXPORT void Dart_EnterScope() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* new_scope = new ApiLocalScope(state->top_scope(),
                                               reinterpret_cast<uword>(&state));
  ASSERT(new_scope != NULL);
  state->set_top_scope(new_scope);  // New scope is now the top scope.
}


DART_EXPORT void Dart_ExitScope() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  state->set_top_scope(scope->previous());  // Reset top scope to previous.
  delete scope;  // Free up the old scope which we have just exited.
}


DART_EXPORT Dart_Handle Dart_NewPersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  LocalHandle* local_ref = Api::UnwrapAsLocalHandle(*state, object);
  PersistentHandle* ref = state->persistent_handles().AllocateHandle();
  ref->set_raw(*local_ref);
  return reinterpret_cast<Dart_Handle>(ref);
}


DART_EXPORT Dart_Handle Dart_MakeWeakPersistentHandle(Dart_Handle object) {
  UNIMPLEMENTED();
  return NULL;
}


DART_EXPORT Dart_Handle Dart_MakePersistentHandle(Dart_Handle object) {
  UNIMPLEMENTED();
  return NULL;
}


DART_EXPORT void Dart_DeletePersistentHandle(Dart_Handle object) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  PersistentHandle* ref = Api::UnwrapAsPersistentHandle(*state, object);
  ref->FreeHandle(state->persistent_handles().free_list());
  state->persistent_handles().set_free_list(ref);
}


static const bool kGetter = true;
static const bool kSetter = false;


static bool UseGetterForStaticField(const Field& fld) {
  if (fld.IsNull()) {
    return true;
  }

  // Return getter method for uninitialized fields, rather than the
  // field object, since the value in the field object will not be
  // initialized until the first time the getter is invoked.
  const Instance& value = Instance::Handle(fld.value());
  ASSERT(value.raw() != Object::transition_sentinel());
  return value.raw() == Object::sentinel();
}


static Dart_Result LookupStaticField(Dart_Handle clazz,
                                     Dart_Handle field_name,
                                     bool is_getter) {
  const Object& param1 = Object::Handle(Api::UnwrapHandle(clazz));
  const Object& param2 = Object::Handle(Api::UnwrapHandle(field_name));
  if (param1.IsNull() || !param1.IsClass()) {
    RETURN_FAILURE("Invalid class specified");
  }
  if (param2.IsNull() || !param2.IsString()) {
    RETURN_FAILURE("Invalid field name specified");
  }
  Class& cls = Class::Handle();
  cls ^= param1.raw();
  String& fld_name = String::Handle();
  fld_name ^= param2.raw();
  const Field& fld = Field::Handle(cls.LookupStaticField(fld_name));
  if (is_getter && UseGetterForStaticField(fld)) {
    const String& func_name = String::Handle(Field::GetterName(fld_name));
    const Function& function =
        Function::Handle(cls.LookupStaticFunction(func_name));
    if (!function.IsNull()) {
      RETURN_OBJECT(function);
    }
    RETURN_FAILURE("Specified field is not found in the class");
  }
  if (fld.IsNull()) {
    RETURN_FAILURE("Specified field is not found in the class");
  }
  RETURN_OBJECT(fld);
}


static Dart_Result LookupInstanceField(const Object& object,
                                       Dart_Handle name,
                                       bool is_getter) {
  const Object& param = Object::Handle(Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString()) {
    RETURN_FAILURE("Invalid field name specified");
  }
  String& field_name = String::Handle();
  field_name ^= param.raw();
  String& func_name = String::Handle();
  Field& fld = Field::Handle();
  Class& cls = Class::Handle(object.clazz());
  while (!cls.IsNull()) {
    fld = cls.LookupInstanceField(field_name);
    if (!fld.IsNull()) {
      if (!is_getter && fld.is_final()) {
        RETURN_FAILURE("Cannot set value of final fields");
      }
      func_name = is_getter ? Field::GetterName(field_name) :
                              Field::SetterName(field_name);
      const Function& function = Function::Handle(
          cls.LookupDynamicFunction(func_name));
      if (function.IsNull()) {
        RETURN_FAILURE("Unable to find accessor function in the class");
      }
      RETURN_OBJECT(function);
    }
    cls = cls.SuperClass();
  }
  RETURN_FAILURE("Unable to find field in the class");
}


DART_EXPORT Dart_Result Dart_GetStaticField(Dart_Handle cls,
                                            Dart_Handle name) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  Dart_Result result = LookupStaticField(cls, name, kGetter);
  if (!Dart_IsValidResult(result)) {
    RETURN_FAILURE(Dart_GetErrorCString(result));
  }
  Object& retval = Object::Handle();
  const Object& obj = Object::Handle(Api::UnwrapHandle(Dart_GetResult(result)));
  if (obj.IsField()) {
    Field& fld = Field::Handle();
    fld ^= obj.raw();
    retval = fld.value();
    RETURN_OBJECT(retval);
  } else {
    Function& func = Function::Handle();
    func ^= obj.raw();
    GrowableArray<const Object*> args;
    InvokeStatic(func, args, &result);
    if (Dart_IsValidResult(result)) {
      Dart_Handle result_obj = Dart_GetResult(result);
      if (Dart_ExceptionOccurred(result_obj)) {
        RETURN_FAILURE("An exception occurred when getting the static field");
      }
    }
    return result;
  }
}


// TODO(iposva): The value parameter should be documented as being an instance.
DART_EXPORT Dart_Result Dart_SetStaticField(Dart_Handle cls,
                                            Dart_Handle name,
                                            Dart_Handle value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  Dart_Result result = LookupStaticField(cls, name, kSetter);
  if (!Dart_IsValidResult(result)) {
    RETURN_FAILURE(Dart_GetErrorCString(result));
  }
  Field& fld = Field::Handle();
  fld ^= Api::UnwrapHandle(Dart_GetResult(result));
  if (fld.is_final()) {
    RETURN_FAILURE("Specified field is a static final field in the class");
  }
  const Object& val = Object::Handle(Api::UnwrapHandle(value));
  Instance& instance = Instance::Handle();
  instance ^= val.raw();
  fld.set_value(instance);
  RETURN_OBJECT(val);
}


DART_EXPORT Dart_Result Dart_GetInstanceField(Dart_Handle obj,
                                              Dart_Handle name) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    RETURN_FAILURE("Invalid object passed in to access instance field");
  }
  Instance& object = Instance::Handle();
  object ^= param.raw();
  Dart_Result result = LookupInstanceField(object, name, kGetter);
  if (!Dart_IsValidResult(result)) {
    RETURN_FAILURE(Dart_GetErrorCString(result));
  }
  Function& func = Function::Handle();
  func ^= Api::UnwrapHandle(Dart_GetResult(result));
  GrowableArray<const Object*> arguments;
  InvokeDynamic(object, func, arguments, &result);
  if (Dart_IsValidResult(result)) {
    Dart_Handle result_obj = Dart_GetResult(result);
    if (Dart_ExceptionOccurred(result_obj)) {
      RETURN_FAILURE("An exception occurred when accessing the instance field");
    }
  }
  return result;
}


DART_EXPORT Dart_Result Dart_SetInstanceField(Dart_Handle obj,
                                              Dart_Handle name,
                                              Dart_Handle value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    RETURN_FAILURE("Invalid object passed in to access instance field");
  }
  Instance& object = Instance::Handle();
  object ^= param.raw();
  Dart_Result result = LookupInstanceField(object, name, kSetter);
  if (!Dart_IsValidResult(result)) {
    RETURN_FAILURE(Dart_GetErrorCString(result));
  }
  Function& func = Function::Handle();
  func ^= Api::UnwrapHandle(Dart_GetResult(result));
  GrowableArray<const Object*> arguments(1);
  const Object& arg = Object::Handle(Api::UnwrapHandle(value));
  arguments.Add(&arg);
  InvokeDynamic(object, func, arguments, &result);
  if (Dart_IsValidResult(result)) {
    Dart_Handle result_obj = Dart_GetResult(result);
    if (Dart_ExceptionOccurred(result_obj)) {
      RETURN_FAILURE("An exception occurred when setting the instance field");
    }
  }
  return result;
}


DART_EXPORT Dart_Result Dart_CreateNativeWrapperClass(Dart_Handle library,
                                                      Dart_Handle name,
                                                      int field_count) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(name));
  if (param.IsNull() || !param.IsString() || field_count <= 0) {
    RETURN_FAILURE("Invalid arguments passed to Dart_CreateNativeWrapperClass");
  }
  String& cls_name = String::Handle();
  cls_name ^= param.raw();
  cls_name = String::NewSymbol(cls_name);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(library);
  if (lib.IsNull()) {
    RETURN_FAILURE("Invalid arguments passed to Dart_CreateNativeWrapperClass");
  }
  const Class& cls = Class::Handle(Class::NewNativeWrapper(&lib,
                                                           cls_name,
                                                           field_count));
  if (cls.IsNull()) {
    RETURN_FAILURE("Unable to create native wrapper class : already exists");
  }
  RETURN_OBJECT(cls);
}


DART_EXPORT Dart_Result Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    RETURN_FAILURE("Invalid object passed in to access native instance field");
  }
  Instance& object = Instance::Handle();
  object ^= param.raw();
  if (!object.IsValidNativeIndex(index)) {
    RETURN_FAILURE("Invalid index passed in to access native instance field");
  }
  RETURN_CINT(object.GetNativeField(index));
}


DART_EXPORT Dart_Result Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& param = Object::Handle(Api::UnwrapHandle(obj));
  if (param.IsNull() || !param.IsInstance()) {
    RETURN_FAILURE("Invalid object passed in to set native instance field");
  }
  Instance& object = Instance::Handle();
  object ^= param.raw();
  if (!object.IsValidNativeIndex(index)) {
    RETURN_FAILURE("Invalid index passed in to set native instance field");
  }
  object.SetNativeField(index, value);
  RETURN_CINT(value);
}


static uint8_t* ApiAllocator(uint8_t* ptr,
                             intptr_t old_size,
                             intptr_t new_size) {
  uword new_ptr = Api::Reallocate(reinterpret_cast<uword>(ptr),
                                  old_size,
                                  new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DART_EXPORT Dart_Result Dart_CreateSnapshot(uint8_t** snapshot_buffer,
                                            intptr_t* snapshot_size) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  if (snapshot_buffer == NULL || snapshot_size == NULL) {
    RETURN_FAILURE("Invalid input parameters to Dart_CreateSnapshot");
  }
  const char* msg = CheckIsolateState();
  if (msg != NULL) {
    RETURN_FAILURE(msg);
  }
  SnapshotWriter writer(true, snapshot_buffer, ApiAllocator);
  writer.WriteFullSnapshot();
  *snapshot_size = writer.Size();
  RETURN_CBOOLEAN(true);
}


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DART_EXPORT Dart_Result Dart_PostIntArray(Dart_Port port,
                                          int field_count,
                                          intptr_t* data) {
  uint8_t* buffer = NULL;
  MessageWriter writer(&buffer, &allocator);

  writer.WriteMessage(field_count, data);

  // Post the message at the given port.
  bool result = PortMap::PostMessage(port, kNoReplyPort, buffer);
  RETURN_CBOOLEAN(result);
}


DART_EXPORT Dart_Result Dart_Post(Dart_Port port, Dart_Handle handle) {
  Zone zone;  // Setup a VM zone as we are creating some handles.
  HandleScope scope;  // Setup a VM handle scope.
  const Object& object = Object::Handle(Api::UnwrapHandle(handle));
  uint8_t* data = NULL;
  SnapshotWriter writer(false, &data, &allocator);
  writer.WriteObject(object.raw());
  writer.FinalizeBuffer();
  bool result = PortMap::PostMessage(port, kNoReplyPort, data);
  RETURN_CBOOLEAN(result);
}


DART_EXPORT void Dart_InitPprofSupport() {
  DebugInfo* pprof_symbol_generator = DebugInfo::NewGenerator();
  ASSERT(pprof_symbol_generator != NULL);
  Dart::set_pprof_symbol_generator(pprof_symbol_generator);
}


DART_EXPORT void Dart_GetPprofSymbolInfo(void** buffer, int* buffer_size) {
  DebugInfo* pprof_symbol_generator = Dart::pprof_symbol_generator();
  if (pprof_symbol_generator != NULL) {
    ByteArray* debug_region = new ByteArray();
    ASSERT(debug_region != NULL);
    pprof_symbol_generator->WriteToMemory(debug_region);
    *buffer_size = debug_region->size();
    if (*buffer_size != 0) {
      *buffer = reinterpret_cast<void*>(Api::Allocate(*buffer_size));
      memmove(*buffer, debug_region->data(), *buffer_size);
    } else {
      *buffer = NULL;
    }
    delete debug_region;
  } else {
    *buffer = NULL;
    *buffer_size = 0;
  }
}


DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name) {
  if (Flags::Lookup(flag_name) != NULL) {
    return true;
  }
  return false;
}


Dart_Handle Api::NewLocalHandle(const Object& object) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  LocalHandles* local_handles = scope->local_handles();
  ASSERT(local_handles != NULL);
  LocalHandle* ref = local_handles->AllocateHandle();
  ref->set_raw(object);
  return reinterpret_cast<Dart_Handle>(ref);
}


RawObject* Api::UnwrapHandle(Dart_Handle object) {
#ifdef DEBUG
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ASSERT(state->IsValidPersistentHandle(object) ||
         state->IsValidLocalHandle(object));
  ASSERT(PersistentHandle::raw_offset() == 0 &&
         LocalHandle::raw_offset() == 0);
#endif
  return *(reinterpret_cast<RawObject**>(object));
}


LocalHandle* Api::UnwrapAsLocalHandle(const ApiState& state,
                                      Dart_Handle object) {
  ASSERT(state.IsValidLocalHandle(object));
  return reinterpret_cast<LocalHandle*>(object);
}


PersistentHandle* Api::UnwrapAsPersistentHandle(const ApiState& state,
                                                Dart_Handle object) {
  ASSERT(state.IsValidPersistentHandle(object));
  return reinterpret_cast<PersistentHandle*>(object);
}


uword Api::Allocate(intptr_t size) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope->zone().Allocate(size);
}


uword Api::Reallocate(uword ptr, intptr_t old_size, intptr_t new_size) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* scope = state->top_scope();
  ASSERT(scope != NULL);
  return scope->zone().Reallocate(ptr, old_size, new_size);
}


}  // namespace dart
