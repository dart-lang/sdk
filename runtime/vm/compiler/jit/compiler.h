// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_JIT_COMPILER_H_
#define RUNTIME_VM_COMPILER_JIT_COMPILER_H_

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
class FlowGraph;
class Function;
class IndirectGotoInstr;
class Library;
class ParsedFunction;
class QueueElement;
class RawInstance;
class Script;
class SequenceNode;

bool UseKernelFrontEndFor(ParsedFunction* parsed_function);

class CompilationPipeline : public ZoneAllocated {
 public:
  static CompilationPipeline* New(Zone* zone, const Function& function);

  virtual void ParseFunction(ParsedFunction* parsed_function) = 0;
  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id,
      bool optimized) = 0;
  virtual void FinalizeCompilation(FlowGraph* flow_graph) = 0;
  virtual ~CompilationPipeline() {}
};

class DartCompilationPipeline : public CompilationPipeline {
 public:
  virtual void ParseFunction(ParsedFunction* parsed_function);

  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id,
      bool optimized);

  virtual void FinalizeCompilation(FlowGraph* flow_graph);
};

class IrregexpCompilationPipeline : public CompilationPipeline {
 public:
  IrregexpCompilationPipeline() : backtrack_goto_(NULL) {}

  virtual void ParseFunction(ParsedFunction* parsed_function);

  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id,
      bool optimized);

  virtual void FinalizeCompilation(FlowGraph* flow_graph);

 private:
  IndirectGotoInstr* backtrack_goto_;
};

class Compiler : public AllStatic {
 public:
  static const intptr_t kNoOSRDeoptId = Thread::kNoDeoptId;

  static bool IsBackgroundCompilation();
  // The result for a function may change if debugging gets turned on/off.
  static bool CanOptimizeFunction(Thread* thread, const Function& function);

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

  // Generates code for given function without optimization and sets its code
  // field.
  //
  // Returns the raw code object if compilation succeeds.  Otherwise returns a
  // RawError.  Also installs the generated code on the function.
  static RawObject* CompileFunction(Thread* thread, const Function& function);
  // Returns Error::null() if there is no compilation error.
  static RawError* ParseFunction(Thread* thread, const Function& function);

  // Generates unoptimized code if not present, current code is unchanged.
  static RawError* EnsureUnoptimizedCode(Thread* thread,
                                         const Function& function);

  // Generates optimized code for function.
  //
  // Returns the code object if compilation succeeds.  Returns an Error if
  // there is a compilation error.  If optimization fails, but there is no
  // error, returns null.  Any generated code is installed unless we are in
  // OSR mode.
  static RawObject* CompileOptimizedFunction(Thread* thread,
                                             const Function& function,
                                             intptr_t osr_id = kNoOSRDeoptId);

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

  // Generates local var descriptors and sets it in 'code'. Do not call if the
  // local var descriptor already exists.
  static void ComputeLocalVarDescriptors(const Code& code);

  // Eagerly compiles all functions in a class.
  //
  // Returns Error::null() if there is no compilation error.
  static RawError* CompileAllFunctions(const Class& cls);
  static RawError* ParseAllFunctions(const Class& cls);

  // Notify the compiler that background (optimized) compilation has failed
  // because the mutator thread changed the state (e.g., deoptimization,
  // deferred loading). The background compilation may retry to compile
  // the same function later.
  static void AbortBackgroundCompilation(intptr_t deopt_id, const char* msg);
};

// Class to run optimizing compilation in a background thread.
// Current implementation: one task per isolate, it dies with the owning
// isolate.
// No OSR compilation in the background compiler.
class BackgroundCompiler {
 public:
  explicit BackgroundCompiler(Isolate* isolate);
  virtual ~BackgroundCompiler();

  static void Start(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      isolate->background_compiler()->Start();
    }
  }
  static void Stop(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      isolate->background_compiler()->Stop();
    }
  }
  static void Enable(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      isolate->background_compiler()->Enable();
    }
  }
  static void Disable(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      isolate->background_compiler()->Disable();
    }
  }
  static bool IsDisabled(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      return isolate->background_compiler()->IsDisabled();
    }
    return false;
  }
  static bool IsRunning(Isolate* isolate) {
    ASSERT(Thread::Current()->IsMutatorThread());
    if (isolate->background_compiler() != NULL) {
      return isolate->background_compiler()->IsRunning();
    }
    return false;
  }

  // Call to optimize a function in the background, enters the function in the
  // compilation queue.
  void CompileOptimized(const Function& function);

  void VisitPointers(ObjectPointerVisitor* visitor);

  BackgroundCompilationQueue* function_queue() const { return function_queue_; }
  bool is_running() const { return running_; }

  void Run();

 private:
  void Start();
  void Stop();
  void Enable();
  void Disable();
  bool IsDisabled();
  bool IsRunning() { return !done_; }

  Isolate* isolate_;

  Monitor* queue_monitor_;  // Controls access to the queue.
  BackgroundCompilationQueue* function_queue_;

  Monitor* done_monitor_;   // Notify/wait that the thread is done.
  bool running_;            // While true, will try to read queue and compile.
  bool done_;               // True if the thread is done.

  int16_t disabled_depth_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BackgroundCompiler);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_JIT_COMPILER_H_
