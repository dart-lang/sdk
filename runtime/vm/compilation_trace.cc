// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compilation_trace.h"

#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

CompilationTraceSaver::CompilationTraceSaver(Zone* zone)
    : buf_(zone, 4 * KB),
      func_name_(String::Handle(zone)),
      cls_(Class::Handle(zone)),
      cls_name_(String::Handle(zone)),
      lib_(Library::Handle(zone)),
      uri_(String::Handle(zone)) {}

void CompilationTraceSaver::Visit(const Function& function) {
  if (!function.HasCode()) {
    return;  // Not compiled.
  }
  if (function.parent_function() != Function::null()) {
    // Lookup works poorly for local functions. We compile all local functions
    // in a compiled function instead.
    return;
  }

  func_name_ = function.name();
  func_name_ = String::RemovePrivateKey(func_name_);
  cls_ = function.Owner();
  cls_name_ = cls_.Name();
  cls_name_ = String::RemovePrivateKey(cls_name_);
  lib_ = cls_.library();
  uri_ = lib_.url();
  buf_.Printf("%s,%s,%s\n", uri_.ToCString(), cls_name_.ToCString(),
              func_name_.ToCString());
}

CompilationTraceLoader::CompilationTraceLoader(Thread* thread)
    : thread_(thread),
      zone_(thread->zone()),
      uri_(String::Handle(zone_)),
      class_name_(String::Handle(zone_)),
      function_name_(String::Handle(zone_)),
      function_name2_(String::Handle(zone_)),
      lib_(Library::Handle(zone_)),
      cls_(Class::Handle(zone_)),
      function_(Function::Handle(zone_)),
      function2_(Function::Handle(zone_)),
      field_(Field::Handle(zone_)),
      error_(Object::Handle(zone_)) {}

static char* FindCharacter(char* str, char goal, char* limit) {
  while (str < limit) {
    if (*str == goal) {
      return str;
    }
    str++;
  }
  return NULL;
}

RawObject* CompilationTraceLoader::CompileTrace(uint8_t* buffer,
                                                intptr_t size) {
  // First compile functions named in the trace.
  char* cursor = reinterpret_cast<char*>(buffer);
  char* limit = cursor + size;
  while (cursor < limit) {
    char* uri = cursor;
    char* comma1 = FindCharacter(uri, ',', limit);
    if (comma1 == NULL) {
      break;
    }
    *comma1 = 0;
    char* cls_name = comma1 + 1;
    char* comma2 = FindCharacter(cls_name, ',', limit);
    if (comma2 == NULL) {
      break;
    }
    *comma2 = 0;
    char* func_name = comma2 + 1;
    char* newline = FindCharacter(func_name, '\n', limit);
    if (newline == NULL) {
      break;
    }
    *newline = 0;
    error_ = CompileTriple(uri, cls_name, func_name);
    if (error_.IsError()) {
      return error_.raw();
    }
    cursor = newline + 1;
  }

  // Next, compile common dispatchers. These aren't found with the normal
  // lookup above because they have irregular lookup that depends on the
  // arguments descriptor (e.g. call() versus call(x)).
  const Class& closure_class =
      Class::Handle(zone_, thread_->isolate()->object_store()->closure_class());
  Array& arguments_descriptor = Array::Handle(zone_);
  Function& dispatcher = Function::Handle(zone_);
  for (intptr_t argc = 1; argc <= 4; argc++) {
    const intptr_t kTypeArgsLen = 0;
    arguments_descriptor = ArgumentsDescriptor::New(kTypeArgsLen, argc);
    dispatcher = closure_class.GetInvocationDispatcher(
        Symbols::Call(), arguments_descriptor,
        RawFunction::kInvokeFieldDispatcher, true /* create_if_absent */);
    error_ = CompileFunction(dispatcher);
    if (error_.IsError()) {
      return error_.raw();
    }
  }

  // Finally, compile closures in all compiled functions. Don't cache the
  // length since compiling may append to this list.
  const GrowableObjectArray& closure_functions = GrowableObjectArray::Handle(
      zone_, thread_->isolate()->object_store()->closure_functions());
  for (intptr_t i = 0; i < closure_functions.Length(); i++) {
    function_ ^= closure_functions.At(i);
    function2_ = function_.parent_function();
    if (function2_.HasCode()) {
      error_ = CompileFunction(function_);
      if (error_.IsError()) {
        return error_.raw();
      }
    }
  }

  return Object::null();
}

// Use a fuzzy match to find the right function to compile. This allows a
// compilation trace to remain mostly valid in the face of program changes, and
// deals with implicit/dispatcher functions that don't have proper names.
//  - Ignore private name mangling
//  - If looking for a getter and we only have the corresponding regular method,
//    compile the regular method, create its implicit closure and compile that.
//  - If looking for a regular method and we only have the corresponding getter,
//    compile the getter, create its method extractor and compile that.
//  - If looking for a getter and we only have a const field, evaluate the const
//    field.
RawObject* CompilationTraceLoader::CompileTriple(const char* uri_cstr,
                                                 const char* cls_cstr,
                                                 const char* func_cstr) {
  uri_ = Symbols::New(thread_, uri_cstr);
  class_name_ = Symbols::New(thread_, cls_cstr);
  function_name_ = Symbols::New(thread_, func_cstr);

  if (function_name_.Equals("_getMainClosure")) {
    // The scheme for invoking main relies on compiling _getMainClosure after
    // synthetically importing the root library.
    return Object::null();
  }

  lib_ = Library::LookupLibrary(thread_, uri_);
  if (lib_.IsNull()) {
    // Missing library.
    return Object::null();
  }

  bool is_getter = Field::IsGetterName(function_name_);
  bool add_closure = false;

  if (class_name_.Equals(Symbols::TopLevel())) {
    function_ = lib_.LookupFunctionAllowPrivate(function_name_);
    field_ = lib_.LookupFieldAllowPrivate(function_name_);
    if (function_.IsNull() && is_getter) {
      // Maybe this was a tear off.
      add_closure = true;
      function_name2_ = Field::NameFromGetter(function_name_);
      function_ = lib_.LookupFunctionAllowPrivate(function_name2_);
      field_ = lib_.LookupFieldAllowPrivate(function_name2_);
    }
  } else {
    cls_ = lib_.SlowLookupClassAllowMultiPartPrivate(class_name_);
    if (cls_.IsNull()) {
      // Missing class.
      return Object::null();
    }

    error_ = cls_.EnsureIsFinalized(thread_);
    if (error_.IsError()) {
      return error_.raw();
    }

    function_ = cls_.LookupFunctionAllowPrivate(function_name_);
    field_ = cls_.LookupFieldAllowPrivate(function_name_);
    if (function_.IsNull() && is_getter) {
      // Maybe this was a tear off.
      add_closure = true;
      function_name2_ = Field::NameFromGetter(function_name_);
      function_ = cls_.LookupFunctionAllowPrivate(function_name2_);
      field_ = cls_.LookupFieldAllowPrivate(function_name2_);
      if (!function_.IsNull() && !function_.is_static()) {
        // Maybe this was a method extractor.
        function2_ =
            Resolver::ResolveDynamicAnyArgs(zone_, cls_, function_name_);
        if (!function2_.IsNull()) {
          error_ = CompileFunction(function2_);
          if (error_.IsError()) {
            return error_.raw();
          }
        }
      }
    }
  }

  if (!field_.IsNull() && field_.is_const() && field_.is_static() &&
      (field_.StaticValue() == Object::sentinel().raw())) {
    error_ = EvaluateInitializer(field_);
    if (error_.IsError()) {
      return error_.raw();
    }
  }

  if (!function_.IsNull()) {
    error_ = CompileFunction(function_);
    if (error_.IsError()) {
      return error_.raw();
    }
    if (add_closure) {
      function_ = function_.ImplicitClosureFunction();
      error_ = CompileFunction(function_);
      if (error_.IsError()) {
        return error_.raw();
      }
    }
  }

  return Object::null();
}

RawObject* CompilationTraceLoader::CompileFunction(const Function& function) {
  if (function.is_abstract()) {
    return Object::null();
  }
  return Compiler::CompileFunction(thread_, function);
}

RawObject* CompilationTraceLoader::EvaluateInitializer(const Field& field) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    field_.EvaluateInitializer();
  } else {
    Thread* thread = Thread::Current();
    const Error& error = Error::Handle(thread->sticky_error());
    thread->clear_sticky_error();
    return error.raw();
  }
  return Object::null();
}

}  // namespace dart
