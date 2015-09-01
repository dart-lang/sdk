// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

class Compiler : public AllStatic {
 public:
  // Extracts top level entities from the script and populates
  // the class dictionary of the library.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* Compile(const Library& library, const Script& script);

  // Extracts function and field symbols from the class and populates
  // the class.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileClass(const Class& cls);

  // Generates code for given function and sets its code field.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileFunction(Thread* thread, const Function& function);

  // Generates unoptimized code if not present, current code is unchanged.
  static RawError* EnsureUnoptimizedCode(Thread* thread,
                                         const Function& function);

  // Generates optimized code for function.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileOptimizedFunction(
      Thread* thread,
      const Function& function,
      intptr_t osr_id = Isolate::kNoDeoptId);

  // Generates code for given parsed function (without parsing it again) and
  // sets its code field.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileParsedFunction(ParsedFunction* parsed_function);

  // Generates and executes code for a given code fragment, e.g. a
  // compile time constant expression. Returns the result returned
  // by the fragment.
  //
  // The return value is either a RawInstance on success or a RawError
  // on compilation failure.
  static RawObject* ExecuteOnce(SequenceNode* fragment);

  // Evaluates the initializer expression of the given static field.
  //
  // The return value is either a RawInstance on success or a RawError
  // on compilation failure.
  static RawObject* EvaluateStaticInitializer(const Field& field);
  static void CompileStaticInitializer(const Field& field);

  // Generates local var descriptors and sets it in 'code'. Do not call if the
  // local var descriptor already exists.
  static void ComputeLocalVarDescriptors(const Code& code);

  // Eagerly compiles all functions in a class.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileAllFunctions(const Class& cls);

  // The following global flags are changed by --noopt handler;
  // the flags are changed when generating best unoptimized code (no runtime
  // feedback, no deoptimization).

  // Default: false.
  static bool always_optimize() { return always_optimize_; }
  static void set_always_optimize(bool value) { always_optimize_ = value; }

  static bool allow_recompilation() { return allow_recompilation_; }
  static void set_allow_recompilation(bool value) {
    allow_recompilation_ = value;
  }

 private:
  static bool always_optimize_;
  static bool allow_recompilation_;
};

}  // namespace dart

#endif  // VM_COMPILER_H_
