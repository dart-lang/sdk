// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/precompiler.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/compiler.h"
#include "vm/longjump.h"

namespace dart {


DEFINE_FLAG(bool, trace_precompiler, false, "Trace precompiler.");


static RawError* CompileFunction(const Function& func) {
  Thread* thread = Thread::Current();
  Error& error = Error::Handle();
  if (func.is_abstract() || func.IsRedirectingFactory()) {
    return error.raw();
  }

  if (!func.HasCode()) {
    if (FLAG_trace_precompiler) {
      OS::Print("    Precompiling %s (%" Pd ")\n",
                func.ToQualifiedCString(),
                func.token_pos());
    }
    error = Compiler::CompileFunction(thread, func);
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  if ((func.kind() == RawFunction::kRegularFunction) && !func.is_static()) {
    const String& name = String::Handle(func.name());
    if (!Field::IsGetterName(name) && !Field::IsSetterName(name)) {
      const Function& closure_func =
          Function::Handle(func.ImplicitClosureFunction());
      ASSERT(!closure_func.IsNull());
      error = CompileFunction(closure_func);
    }
  }

  return error.raw();
}


static RawError* CompileClass(const Class& cls) {
  if (FLAG_trace_precompiler) {
    OS::Print("  Precompiling %s\n", cls.ToCString());
  }

  Error& error = Error::Handle();
  error = cls.EnsureIsFinalized(Isolate::Current());
  if (!error.IsNull()) {
    return error.raw();
  }

  const Array& fields = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < fields.Length(); i++) {
    field ^= fields.At(i);
    ASSERT(!field.IsNull());
    if (field.is_static() && field.has_initializer()) {
      if (FLAG_trace_precompiler) {
        OS::Print("    Precompiling initializer for %s\n", field.ToCString());
      }
      Compiler::CompileStaticInitializer(field);
    }
  }

  const Array& functions = Array::Handle(cls.functions());
  Function& func = Function::Handle();
  for (intptr_t i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    error = CompileFunction(func);
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  return error.raw();
}


static RawError* CompileLibrary(const Library& lib) {
  if (FLAG_trace_precompiler) {
    OS::Print("Precompiling %s\n", lib.ToCString());
  }
  ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
  Class& cls = Class::Handle();
  Error& error = Error::Handle();
  while (it.HasNext()) {
    cls = it.GetNextClass();
    error = CompileClass(cls);
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  return error.raw();
}


static RawError* InnerCompileAll() {
  Error& error = Error::Handle();
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->libraries());
  Library& lib = Library::Handle();
  for (int i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    error = CompileLibrary(lib);
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  if (FLAG_trace_precompiler) {
    OS::Print("** Precompiling collected closures **\n");
  }

  const GrowableObjectArray& closures =
    GrowableObjectArray::Handle(Isolate::Current()->collected_closures());
  Function& func = Function::Handle();
  if (!closures.IsNull()) {
    for (int i = 0; i < closures.Length(); i++) {
      func ^= closures.At(i);
      error = CompileFunction(func);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }
  Isolate::Current()->set_collected_closures(GrowableObjectArray::Handle());

  if (FLAG_trace_precompiler) {
    OS::Print("*** Done precompiling ***\n");
  }
  Isolate::Current()->set_compilation_allowed(false);
  return error.raw();
}


RawError* Precompiler::CompileAll() {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    return InnerCompileAll();
  } else {
    Isolate* isolate = Isolate::Current();
    const Error& error = Error::Handle(isolate,
                                       isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
}

}  // namespace dart
