// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_

#include <vector>

#include "include/dart_api.h"

#include "platform/allocation.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/compiler_state.h"
#include "vm/unit_test.h"

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
                           Dart_NativeEntryResolver resolver = nullptr,
                           const char* lib_uri = USER_TEST_URI);

RawFunction* GetFunction(const Library& lib, const char* name);

void Invoke(const Library& lib, const char* name);

class TestPipeline : public ValueObject {
 public:
  explicit TestPipeline(const Function& function)
      : function_(function),
        thread_(Thread::Current()),
        compiler_state_(thread_) {}
  ~TestPipeline() { delete pass_state_; }

  FlowGraph* RunJITPasses(std::initializer_list<CompilerPass::Id> passes) {
    return Run(/*is_aot=*/false, passes);
  }
  FlowGraph* RunAOTPasses(std::initializer_list<CompilerPass::Id> passes) {
    return Run(/*is_aot=*/true, passes);
  }

  void CompileGraphAndAttachFunction();

 private:
  // As a side-effect this will populate
  //   - [ic_data_array_]
  //   - [parsed_function_]
  //   - [pass_state_]
  //   - [flow_graph_]
  FlowGraph* Run(bool is_aot, std::initializer_list<CompilerPass::Id> passes);

  const Function& function_;
  Thread* thread_;
  CompilerState compiler_state_;
  ZoneGrowableArray<const ICData*>* ic_data_array_ = nullptr;
  ParsedFunction* parsed_function_ = nullptr;
  CompilerPassState* pass_state_ = nullptr;
  FlowGraph* flow_graph_ = nullptr;
};

// Match opcodes used for [ILMatcher], see below.
enum MatchOpCode {
// Emit a match and match-and-move code for every instruction.
#define DEFINE_MATCH_OPCODES(Instruction, _)                                   \
  kMatch##Instruction, kMatchAndMove##Instruction,
  FOR_EACH_INSTRUCTION(DEFINE_MATCH_OPCODES)
#undef DEFINE_MATCH_OPCODES

  // Matches a branch and moves left.
  kMatchAndMoveBranchTrue,

  // Matches a branch and moves right.
  kMatchAndMoveBranchFalse,

  // Moves forward across any instruction.
  kMoveAny,

  // Moves over all parallel moves.
  kMoveParallelMoves,

  // Moves forward until the next match code matches.
  kMoveGlob,
};

// Match codes used for [ILMatcher], see below.
class MatchCode {
 public:
  MatchCode(MatchOpCode opcode)  // NOLINT
      : opcode_(opcode), capture_(nullptr) {}

  MatchCode(MatchOpCode opcode, Instruction** capture)
      : opcode_(opcode), capture_(capture) {}

#define DEFINE_TYPED_CONSTRUCTOR(Type, ignored)                                \
  MatchCode(MatchOpCode opcode, Type##Instr** capture)                         \
      : opcode_(opcode), capture_(reinterpret_cast<Instruction**>(capture)) {  \
    RELEASE_ASSERT(opcode == kMatch##Type || opcode == kMatchAndMove##Type);   \
  }
  FOR_EACH_INSTRUCTION(DEFINE_TYPED_CONSTRUCTOR)
#undef DEFINE_TYPED_CONSTRUCTOR

  MatchOpCode opcode() { return opcode_; }

 private:
  friend class ILMatcher;

  MatchOpCode opcode_;
  Instruction** capture_;
};

// Used for matching a sequence of IL instructions including capturing support.
//
// Example:
//
//     TargetEntryInstr* entry = ....;
//     BranchInstr* branch = nullptr;
//
//     ILMatcher matcher(flow_graph, entry);
//     if (matcher.TryMatch({ kMoveGlob, {kMatchBranch, &branch}, })) {
//       EXPECT(branch->operation_cid() == kMintCid);
//       ...
//     }
//
// This match will start at [entry], follow any number instructions (including
// [GotoInstr]s until a [BranchInstr] is found).
//
// If the match was successful, this returns `true` and updates the current
// value for the cursor.
class ILMatcher : public ValueObject {
 public:
  ILMatcher(FlowGraph* flow_graph, Instruction* cursor, bool trace = true)
      : flow_graph_(flow_graph),
        cursor_(cursor),
  // clang-format off
#if !defined(PRODUCT)
        trace_(trace) {}
#else
        trace_(false) {}
#endif
  // clang-format on

  Instruction* value() { return cursor_; }

  // From the current [value] according to match_codes.
  //
  // Returns `true` if the match was successful and cursor has been updated,
  // otherwise returns `false`.
  bool TryMatch(std::initializer_list<MatchCode> match_codes);

 private:
  Instruction* MatchInternal(std::vector<MatchCode> match_codes,
                             size_t i,
                             Instruction* cursor);

  const char* MatchOpCodeToCString(MatchOpCode code);

  FlowGraph* flow_graph_;
  Instruction* cursor_;
  bool trace_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
