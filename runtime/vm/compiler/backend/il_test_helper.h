// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_

#include "include/dart_api.h"

#include "platform/allocation.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/compiler_state.h"

// The helpers in this file make it easier to write C++ unit tests which assert
// that Dart code gets turned into certain IR.
//
// Here is an example on how to use it:
//
//     ISOLATE_UNIT_TEST_CASE(MyIRTest) {
//       const char* script = R"(
//           void foo() { ... }
//           void main() { foo(); }
//       )";
//
//       // Load the script and exercise the code once.
//       const auto& lib = Library::Handle(LoadTestScript(script);
//
//       // Cause the code to be exercised once (to populate ICData).
//       Invoke(lib, "main");
//
//       // Look up the function.
//       const auto& function = Function::Handle(GetFunction(lib, "foo"));
//
//       // Run the JIT compilation pipeline with two passes.
//       TestPipeline pipeline(function);
//       FlowGraph* graph = pipeline.RunJITPasses("ComputeSSA,TypePropagation");
//
//       ...
//     }
//
namespace dart {

class FlowGraph;
class Function;
class Library;
class RawFunction;
class RawLibrary;

RawLibrary* LoadTestScript(const char* script,
                           Dart_NativeEntryResolver resolver = nullptr);

RawFunction* GetFunction(const Library& lib, const char* name);

void Invoke(const Library& lib, const char* name);

class TestPipeline {
 public:
  explicit TestPipeline(const Function& function)
      : function_(function),
        thread_(Thread::Current()),
        compiler_state_(thread_) {}

  FlowGraph* RunJITPasses(std::initializer_list<CompilerPass::Id> passes) {
    return Run(/*is_aot=*/false, passes);
  }
  FlowGraph* RunAOTPasses(std::initializer_list<CompilerPass::Id> passes) {
    return Run(/*is_aot=*/true, passes);
  }

 private:
  FlowGraph* Run(bool is_aot, std::initializer_list<CompilerPass::Id> passes);

  const Function& function_;
  Thread* thread_;
  CompilerState compiler_state_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
