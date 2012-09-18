// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COMPILER_H_
#define VM_COMPILER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/runtime_entry.h"

namespace dart {

// Forward declarations.
class Class;
class Function;
class Library;
class ParsedFunction;
class RawInstance;
class Script;
class SequenceNode;

DECLARE_RUNTIME_ENTRY(CompileFunction);

class Compiler : public AllStatic {
 public:
  // Extracts class, interface, function symbols from the script and populates
  // the symbol tables and the class dictionary of the library.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* Compile(const Library& library, const Script& script);

  // Generates code for given function and sets its code field.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileFunction(const Function& function);

  // Generates optimized code for function.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileOptimizedFunction(const Function& function);

  // Generates code for given parsed function (without parsing it again) and
  // sets its code field.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileParsedFunction(const ParsedFunction& parsed_function);

  // Generates and executes code for a given code fragment, e.g. a
  // compile time constant expression. Returns the result returned
  // by the fragment.
  //
  // The return value is either a RawInstance on success or a RawError
  // on compilation failure.
  static RawObject* ExecuteOnce(SequenceNode* fragment);

  // Eagerly compiles all functions in a class.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileAllFunctions(const Class& cls);
};

}  // namespace dart

#endif  // VM_COMPILER_H_
