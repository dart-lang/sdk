// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COMPILER_H_
#define VM_COMPILER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/runtime_entry.h"
#include "vm/thread_pool.h"

namespace dart {

// Forward declarations.
class Class;
class Code;
class CompilationWorkQueue;
class Function;
class Library;
class ParsedFunction;
class RawInstance;
class Script;
class SequenceNode;

// Carries result from background compilation: code and generation counters
// that help check if the code may have become invalid during background
// compilation.
class BackgroundCompilationResult : public ValueObject {
 public:
  BackgroundCompilationResult();

  // Initializes with current isolate-stored generations
  void Init();

  void set_result_code(const Code& value) { result_code_ = value.raw(); }
  const Code& result_code() const { return result_code_; }

  // Returns true if all relevant gen-counts are current and code is valid.
  bool IsValid() const;

  // Remove gen-counts from validation check.
  void ClearCHAInvalidationGen() {
    cha_invalidation_gen_ = Integer::null();
  }
  void ClearFieldInnvalidationGen() {
    field_invalidation_gen_ = Integer::null();
  }
  void ClearPrefixInnvalidationGen() {
    prefix_invalidation_gen_ = Integer::null();
  }

  void PushOnQueue(CompilationWorkQueue* queue) const;
  void PopFromQueue(CompilationWorkQueue* queue);

  void PrintValidity() const;

 private:
  Code& result_code_;
  Integer& cha_invalidation_gen_;
  Integer& field_invalidation_gen_;
  Integer& prefix_invalidation_gen_;
};


class Compiler : public AllStatic {
 public:
  static const intptr_t kNoOSRDeoptId = Thread::kNoDeoptId;

  static bool IsBackgroundCompilation();

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
  // If 'result_code' is not NULL, then the generated code is returned but
  // not installed.
  static RawError* CompileOptimizedFunction(
      Thread* thread,
      const Function& function,
      intptr_t osr_id = kNoOSRDeoptId,
      BackgroundCompilationResult* res = NULL);

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


// Class to run optimizing compilation in a background thread.
// Current implementation: one task per isolate, it dies with the owning
// isolate.
// No OSR compilation in the background compiler.
class BackgroundCompiler : public ThreadPool::Task {
 public:
  static void EnsureInit(Thread* thread);

  static void Stop(BackgroundCompiler* task);

  // Call to optimize a function in the background, enters the function in the
  // compilation queue.
  void CompileOptimized(const Function& function);

  // Call to activate/install optimized code (must occur in the mutator thread).
  void InstallGeneratedCode();

  // Access to queue length is guarded with queue_monitor_;
  intptr_t function_queue_length() const { return function_queue_length_; }
  void set_function_queue_length(intptr_t value) {
    function_queue_length_ = value;
  }

  void VisitPointers(ObjectPointerVisitor* visitor);

 private:
  explicit BackgroundCompiler(Isolate* isolate);

  void set_compilation_function_queue(const GrowableObjectArray& value);
  void set_compilation_result_queue(const GrowableObjectArray& value);

  GrowableObjectArray* FunctionsQueue() const;
  GrowableObjectArray* ResultQueue() const;

  virtual void Run();

  void AddFunction(const Function& f);
  RawFunction* RemoveFunctionOrNull();
  RawFunction* LastFunctionOrNull() const;

  void AddResult(const BackgroundCompilationResult& value);

  Isolate* isolate_;
  bool running_;       // While true, will try to read queue and compile.
  bool* done_;         // True if the thread is done.
  Monitor* queue_monitor_;  // Controls access to the queue.
  Monitor* done_monitor_;   // Notify/wait that the thread is done.

  // Lightweight access to length of compiler queue.
  intptr_t function_queue_length_;

  RawGrowableObjectArray* compilation_function_queue_;
  RawGrowableObjectArray* compilation_result_queue_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BackgroundCompiler);
};

}  // namespace dart

#endif  // VM_COMPILER_H_
