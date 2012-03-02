// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "vm/code_index_table.h"
#include "vm/object.h"
#include "vm/verifier.h"

namespace dart {

// Add function to a class and that class to the class dictionary so that
// frame walking can be used.
const Function& RegisterFakeFunction(const char* name, const Code& code) {
  const String& function_name = String::ZoneHandle(String::NewSymbol(name));
  const Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kFunction, true, false, 0));
  Class& cls = Class::ZoneHandle();
  const Script& script = Script::Handle();
  cls = Class::New(function_name, script, Scanner::kDummyTokenIndex);
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  cls.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(cls);
  function.SetCode(code);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  code_index_table->AddCode(code);
  return function;
}


// A runtime call for test purposes.
// Arg0: a smi.
// Arg1: a smi.
// Result: a smi representing arg0 - arg1.
DEFINE_RUNTIME_ENTRY(TestSmiSub, 2) {
  ASSERT(arguments.Count() == kTestSmiSubRuntimeEntry.argument_count());
  const Smi& left = Smi::CheckedHandle(arguments.At(0));
  const Smi& right = Smi::CheckedHandle(arguments.At(1));
  // Ignoring overflow in the calculation below.
  intptr_t result = left.Value() - right.Value();
  arguments.SetReturn(Smi::Handle(Smi::New(result)));
}

}  // namespace dart
