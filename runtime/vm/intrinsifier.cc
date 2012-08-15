// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#include "vm/intrinsifier.h"
#include "vm/flags.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(bool, intrinsify, true, "Instrinsify when possible");


static bool CompareNames(const char* test_name, const char* name) {
  if (strcmp(test_name, name) == 0) {
    return true;
  }
  if ((name[0] == '_') && (test_name[0] == '_')) {
    // Check if the private class is member of corelib and matches the
    // test_class_name.
    const Library& core_lib = Library::Handle(Library::CoreLibrary());
    const Library& core_impl_lib = Library::Handle(Library::CoreImplLibrary());
    String& test_str = String::Handle(String::New(test_name));
    String& test_str_with_key = String::Handle();
    test_str_with_key =
        String::Concat(test_str, String::Handle(core_lib.private_key()));
    if (strcmp(test_str_with_key.ToCString(), name) == 0) {
      return true;
    }
    test_str_with_key =
        String::Concat(test_str, String::Handle(core_impl_lib.private_key()));
    if (strcmp(test_str_with_key.ToCString(), name) == 0) {
      return true;
    }
  }
  return false;
}


// Returns true if the function matches function_name and class_name, with
// special recognition of corelib private classes.
static bool TestFunction(const Function& function,
                         const char* function_class_name,
                         const char* function_name,
                         const char* test_class_name,
                         const char* test_function_name) {
  return CompareNames(test_class_name, function_class_name) &&
         CompareNames(test_function_name, function_name);
}


bool Intrinsifier::Intrinsify(const Function& function, Assembler* assembler) {
  if (!FLAG_intrinsify) return false;
  const char* function_name = String::Handle(function.name()).ToCString();
  const Class& function_class = Class::Handle(function.Owner());
  const char* class_name = String::Handle(function_class.Name()).ToCString();
  // Only core library methods can be intrinsified.
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Library& core_impl_lib = Library::Handle(Library::CoreImplLibrary());
  if ((function_class.library() != core_lib.raw()) &&
      (function_class.library() != core_impl_lib.raw())) {
    return false;
  }
#define FIND_INTRINSICS(test_class_name, test_function_name, destination)      \
  if (TestFunction(function,                                                   \
                   class_name, function_name,                                  \
                   #test_class_name, #test_function_name)) {                   \
    return destination(assembler);                                             \
  }                                                                            \

INTRINSIC_LIST(FIND_INTRINSICS);
#undef FIND_INTRINSICS
  return false;
}

}  // namespace dart
