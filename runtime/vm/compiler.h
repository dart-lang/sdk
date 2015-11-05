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
class BackgroundCompilationQueue;
class Class;
class Code;
class CompilationWorkQueue;
class Function;
class Library;
class ParsedFunction;
class QueueElement;
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

  uint32_t cha_invalidation_gen() const { return cha_invalidation_gen_; }
  uint32_t field_invalidation_gen() const { return field_invalidation_gen_; }
  uint32_t prefix_invalidation_gen() const { return prefix_invalidation_gen_; }

  void SetFromQElement(QueueElement* value);

  // Returns true if all relevant gen-counts are current and code is valid.
  bool IsValid() const;

  // Remove gen-counts from validation check.
  void ClearCHAInvalidationGen() {
    cha_invalidation_gen_ = Isolate::kInvalidGen;
  }
  void ClearFieldInnvalidationGen() {
    field_invalidation_gen_ = Isolate::kInvalidGen;
  }
  void ClearPrefixInnvalidationGen() {
    prefix_invalidation_gen_ = Isolate::kInvalidGen;
  }

  void PrintValidity() const;

 private:
  Code& result_code_;
  uint32_t cha_invalidation_gen_;
  uint32_t field_invalidation_gen_;
  uint32_t prefix_invalidation_gen_;
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


  void VisitPointers(ObjectPointerVisitor* visitor);

  BackgroundCompilationQueue* function_queue() const { return function_queue_; }
  BackgroundCompilationQueue* result_queue() const { return result_queue_; }

 private:
  explicit BackgroundCompiler(Isolate* isolate);

  virtual void Run();

  void AddResult(const BackgroundCompilationResult& value);

  Isolate* isolate_;
  bool running_;       // While true, will try to read queue and compile.
  bool* done_;         // True if the thread is done.
  Monitor* queue_monitor_;  // Controls access to the queue.
  Monitor* done_monitor_;   // Notify/wait that the thread is done.

  BackgroundCompilationQueue* function_queue_;
  BackgroundCompilationQueue* result_queue_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BackgroundCompiler);
};

}  // namespace dart

#endif  // VM_COMPILER_H_
