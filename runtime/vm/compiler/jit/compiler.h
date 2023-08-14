// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_JIT_COMPILER_H_
#define RUNTIME_VM_COMPILER_JIT_COMPILER_H_

#include "vm/allocation.h"
#include "vm/compiler/api/deopt_id.h"
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
class Script;
class SequenceNode;

class CompilationPipeline : public ZoneAllocated {
 public:
  static CompilationPipeline* New(Zone* zone, const Function& function);

  virtual void ParseFunction(ParsedFunction* parsed_function) = 0;
  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      ZoneGrowableArray<const ICData*>* ic_data_array,
      intptr_t osr_id,
      bool optimized) = 0;
  virtual ~CompilationPipeline() {}
};

class DartCompilationPipeline : public CompilationPipeline {
 public:
  void ParseFunction(ParsedFunction* parsed_function) override;

  FlowGraph* BuildFlowGraph(Zone* zone,
                            ParsedFunction* parsed_function,
                            ZoneGrowableArray<const ICData*>* ic_data_array,
                            intptr_t osr_id,
                            bool optimized) override;
};

class IrregexpCompilationPipeline : public CompilationPipeline {
 public:
  IrregexpCompilationPipeline() : backtrack_goto_(nullptr) {}

  void ParseFunction(ParsedFunction* parsed_function) override;

  FlowGraph* BuildFlowGraph(Zone* zone,
                            ParsedFunction* parsed_function,
                            ZoneGrowableArray<const ICData*>* ic_data_array,
                            intptr_t osr_id,
                            bool optimized) override;

 private:
  IndirectGotoInstr* backtrack_goto_;
};

class Compiler : public AllStatic {
 public:
  static constexpr intptr_t kNoOSRDeoptId = DeoptId::kNone;

  static bool IsBackgroundCompilation();
  // The result for a function may change if debugging gets turned on/off.
  static bool CanOptimizeFunction(Thread* thread, const Function& function);

  // Generates code for given function without optimization and sets its code
  // field.
  //
  // Returns the raw code object if compilation succeeds.  Otherwise returns an
  // ErrorPtr.  Also installs the generated code on the function.
  static ObjectPtr CompileFunction(Thread* thread, const Function& function);

  // Generates unoptimized code if not present, current code is unchanged.
  static ErrorPtr EnsureUnoptimizedCode(Thread* thread,
                                        const Function& function);

  // Generates optimized code for function.
  //
  // Returns the code object if compilation succeeds.  Returns an Error if
  // there is a compilation error.  If optimization fails, but there is no
  // error, returns null.  Any generated code is installed unless we are in
  // OSR mode.
  static ObjectPtr CompileOptimizedFunction(Thread* thread,
                                            const Function& function,
                                            intptr_t osr_id = kNoOSRDeoptId);

  // Generates local var descriptors and sets it in 'code'. Do not call if the
  // local var descriptor already exists.
  static void ComputeLocalVarDescriptors(const Code& code);

  // Eagerly compiles all functions in a class.
  //
  // Returns Error::null() if there is no compilation error.
  static ErrorPtr CompileAllFunctions(const Class& cls);

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
  explicit BackgroundCompiler(IsolateGroup* isolate_group);
  virtual ~BackgroundCompiler();

  static void Stop(IsolateGroup* isolate_group) {
    isolate_group->background_compiler()->Stop();
  }

  // Enqueues a function to be compiled in the background.
  //
  // Return `true` if successful.
  bool EnqueueCompilation(const Function& function);

  void VisitPointers(ObjectPointerVisitor* visitor);

  BackgroundCompilationQueue* function_queue() const { return function_queue_; }
  bool is_running() const { return running_; }

  void Run();

 private:
  friend class NoBackgroundCompilerScope;

  void Stop();
  void StopLocked(Thread* thread, SafepointMonitorLocker* done_locker);
  void Enable();
  void Disable();
  bool IsRunning() { return !done_; }

  IsolateGroup* isolate_group_;

  Monitor monitor_;  // Controls access to the queue and running state.
  BackgroundCompilationQueue* function_queue_;
  bool running_;            // While true, will try to read queue and compile.
  bool done_;               // True if the thread is done.
  int16_t disabled_depth_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BackgroundCompiler);
};

class NoBackgroundCompilerScope : public StackResource {
 public:
  explicit NoBackgroundCompilerScope(Thread* thread)
      : StackResource(thread), isolate_group_(thread->isolate_group()) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    isolate_group_->background_compiler()->Disable();
#endif
  }
  ~NoBackgroundCompilerScope() {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    isolate_group_->background_compiler()->Enable();
#endif
  }

 private:
  IsolateGroup* isolate_group_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_JIT_COMPILER_H_
