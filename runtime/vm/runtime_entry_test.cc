// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/runtime_entry.h"

#include "vm/object.h"
#include "vm/symbols.h"
#include "vm/verifier.h"

namespace dart {

// Add function to a class and that class to the class dictionary so that
// frame walking can be used.
const Function& RegisterFakeFunction(const char* name, const Code& code) {
  const String& class_name = String::Handle(Symbols::New("ownerClass"));
  const Script& script = Script::Handle();
  const Class& owner_class =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  const String& function_name = String::ZoneHandle(Symbols::New(name));
  const Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, owner_class, 0));
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  owner_class.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(owner_class);
  function.SetCode(code);
  return function;
}


// A runtime call for test purposes.
// Arg0: a smi.
// Arg1: a smi.
// Result: a smi representing arg0 - arg1.
DEFINE_RUNTIME_ENTRY(TestSmiSub, 2) {
  ASSERT(arguments.ArgCount() == kTestSmiSubRuntimeEntry.argument_count());
  const Smi& left = Smi::CheckedHandle(arguments.ArgAt(0));
  const Smi& right = Smi::CheckedHandle(arguments.ArgAt(1));
  // Ignoring overflow in the calculation below.
  intptr_t result = left.Value() - right.Value();
  arguments.SetReturn(Smi::Handle(Smi::New(result)));
}


// A leaf runtime call for test purposes.
// arg0: a smi.
// arg1: a smi.
// returns a smi representing arg0 + arg1.
DEFINE_LEAF_RUNTIME_ENTRY(RawObject*, TestLeafSmiAdd,
                          RawObject* arg0, RawObject* arg1) {
  // Ignoring overflow in the calculation below and using the internal
  // representation of Smi directly without using any handlized code.
  intptr_t result = reinterpret_cast<intptr_t>(arg0) +
      reinterpret_cast<intptr_t>(arg1);
  return reinterpret_cast<RawObject*>(result);
}
END_LEAF_RUNTIME_ENTRY

}  // namespace dart
