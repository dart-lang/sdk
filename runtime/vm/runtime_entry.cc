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
      Class::Handle(Class::New(class_name, script, Scanner::kNoSourcePos));
  const String& function_name = String::ZoneHandle(Symbols::New(name));
  const Function& function = Function::ZoneHandle(
      Function::New(function_name, RawFunction::kRegularFunction,
                    true, false, false, false, false, owner_class, 0));
  const Array& functions = Array::Handle(Array::New(1));
  functions.SetAt(0, function);
  owner_class.SetFunctions(functions);
  Library& lib = Library::Handle(Library::CoreLibrary());
  lib.AddClass(owner_class);
  function.AttachCode(code);
  return function;
}

}  // namespace dart
