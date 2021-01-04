// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_

#include <utility>
#include <vector>

#include "include/dart_api.h"

#include "platform/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/compiler_state.h"
#include "vm/compiler/jit/compiler.h"
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

LibraryPtr LoadTestScript(const char* script,
                          Dart_NativeEntryResolver resolver = nullptr,
                          const char* lib_uri = RESOLVED_USER_TEST_URI);

FunctionPtr GetFunction(const Library& lib, const char* name);
ClassPtr GetClass(const Library& lib, const char* name);
TypeParameterPtr GetClassTypeParameter(const Class& klass, const char* name);
TypeParameterPtr GetFunctionTypeParameter(const Function& fun,
                                          const char* name);

ObjectPtr Invoke(const Library& lib, const char* name);

class TestPipeline : public ValueObject {
 public:
  explicit TestPipeline(const Function& function,
                        CompilerPass::PipelineMode mode,
                        bool is_optimizing = true)
      : function_(function),
        thread_(Thread::Current()),
        compiler_state_(thread_,
                        mode == CompilerPass::PipelineMode::kAOT,
                        is_optimizing,
                        CompilerState::ShouldTrace(function)),
        mode_(mode) {}
  ~TestPipeline() { delete pass_state_; }

  // As a side-effect this will populate
  //   - [ic_data_array_]
  //   - [parsed_function_]
  //   - [pass_state_]
  //   - [flow_graph_]
  FlowGraph* RunPasses(std::initializer_list<CompilerPass::Id> passes);

  void CompileGraphAndAttachFunction();

 private:
  const Function& function_;
  Thread* thread_;
  CompilerState compiler_state_;
  CompilerPass::PipelineMode mode_;
  ZoneGrowableArray<const ICData*>* ic_data_array_ = nullptr;
  ParsedFunction* parsed_function_ = nullptr;
  CompilerPassState* pass_state_ = nullptr;
  FlowGraph* flow_graph_ = nullptr;
};

// Match opcodes used for [ILMatcher], see below.
enum MatchOpCode {
// Emit a match and match-and-move code for every instruction.
#define DEFINE_MATCH_OPCODES(Instruction, _)                                   \
  kMatch##Instruction, kMatchAndMove##Instruction,                             \
      kMatchAndMoveOptional##Instruction,
  FOR_EACH_INSTRUCTION(DEFINE_MATCH_OPCODES)
#undef DEFINE_MATCH_OPCODES

  // Matches a branch and moves left.
  kMatchAndMoveBranchTrue,

  // Matches a branch and moves right.
  kMatchAndMoveBranchFalse,

  // Is ignored.
  kNop,

  // Moves forward across any instruction.
  kMoveAny,

  // Moves over all parallel moves.
  kMoveParallelMoves,

  // Moves forward until the next match code matches.
  kMoveGlob,

  // Moves over any DebugStepChecks.
  kMoveDebugStepChecks,

  // Invalid match opcode used as default [insert_before] argument to TryMatch
  // to signal that no insertions should occur.
  kInvalidMatchOpCode,
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

enum class ParallelMovesHandling {
  // Matcher doesn't do anything special with ParallelMove instructions.
  kDefault,
  // All ParallelMove instructions are skipped.
  // This mode is useful when matching a flow graph after the whole
  // compiler pipeline, as it may have ParallelMove instructions
  // at arbitrary architecture-dependent places.
  kSkip,
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
  ILMatcher(FlowGraph* flow_graph,
            Instruction* cursor,
            bool trace = true,
            ParallelMovesHandling parallel_moves_handling =
                ParallelMovesHandling::kDefault)
      : flow_graph_(flow_graph),
        cursor_(cursor),
        parallel_moves_handling_(parallel_moves_handling),
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
  //
  // If [insert_before] is a valid match opcode, then it will be inserted
  // before each MatchCode in [match_codes] prior to matching.
  bool TryMatch(std::initializer_list<MatchCode> match_codes,
                MatchOpCode insert_before = kInvalidMatchOpCode);

 private:
  Instruction* MatchInternal(std::vector<MatchCode> match_codes,
                             size_t i,
                             Instruction* cursor);

  const char* MatchOpCodeToCString(MatchOpCode code);

  FlowGraph* flow_graph_;
  Instruction* cursor_;
  ParallelMovesHandling parallel_moves_handling_;
  bool trace_;
};

#if !defined(PRODUCT)
#define ENTITY_TOCSTRING(v) ((v)->ToCString())
#else
#define ENTITY_TOCSTRING(v) "<?>"
#endif

// Helper to check various IL and object properties and informative error
// messages if check fails. [entity] should be a pointer to a value.
// [property] should be an expression which can refer to [entity] using
// variable named [it].
// [entity] is expected to have a ToCString() method in non-PRODUCT builds.
#define EXPECT_PROPERTY(entity, property)                                      \
  do {                                                                         \
    auto& it = *entity;                                                        \
    if (!(property)) {                                                         \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("expected " #property " for " #entity " which is %s.\n",       \
                ENTITY_TOCSTRING(entity));                                     \
    }                                                                          \
  } while (0)

class FlowGraphBuilderHelper {
 public:
  FlowGraphBuilderHelper()
      : state_(CompilerState::Current()),
        flow_graph_(MakeDummyGraph(Thread::Current())) {
    flow_graph_.CreateCommonConstants();
  }

  TargetEntryInstr* TargetEntry(intptr_t try_index = kInvalidTryIndex) const {
    return new TargetEntryInstr(flow_graph_.allocate_block_id(), try_index,
                                state_.GetNextDeoptId());
  }

  JoinEntryInstr* JoinEntry(intptr_t try_index = kInvalidTryIndex) const {
    return new JoinEntryInstr(flow_graph_.allocate_block_id(), try_index,
                              state_.GetNextDeoptId());
  }

  ConstantInstr* IntConstant(int64_t value) const {
    return flow_graph_.GetConstant(
        Integer::Handle(Integer::NewCanonical(value)));
  }

  ConstantInstr* DoubleConstant(double value) {
    return flow_graph_.GetConstant(Double::Handle(Double::NewCanonical(value)));
  }

  static Definition* const kPhiSelfReference;

  PhiInstr* Phi(JoinEntryInstr* join,
                std::initializer_list<std::pair<BlockEntryInstr*, Definition*>>
                    incoming) {
    auto phi = new PhiInstr(join, incoming.size());
    for (size_t i = 0; i < incoming.size(); i++) {
      auto input = new Value(flow_graph_.constant_dead());
      phi->SetInputAt(i, input);
      input->definition()->AddInputUse(input);
    }
    for (auto pair : incoming) {
      pending_phis_.Add({phi, pair.first,
                         pair.second == kPhiSelfReference ? phi : pair.second});
    }
    return phi;
  }

  void FinishGraph() {
    flow_graph_.DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph_.ComputeDominators(&dominance_frontier);

    for (auto& pending : pending_phis_) {
      auto join = pending.phi->block();
      EXPECT(pending.phi->InputCount() == join->PredecessorCount());
      auto pred_index = join->IndexOfPredecessor(pending.pred);
      EXPECT(pred_index != -1);
      pending.phi->InputAt(pred_index)->BindTo(pending.defn);
    }
  }

  FlowGraph* flow_graph() { return &flow_graph_; }

 private:
  static FlowGraph& MakeDummyGraph(Thread* thread) {
    const Function& func = Function::ZoneHandle(Function::New(
        String::Handle(Symbols::New(thread, "dummy")),
        FunctionLayout::kRegularFunction,
        /*is_static=*/true,
        /*is_const=*/false,
        /*is_abstract=*/false,
        /*is_external=*/false,
        /*is_native=*/true,
        Class::Handle(thread->isolate()->object_store()->object_class()),
        TokenPosition::kNoSource));

    Zone* zone = thread->zone();
    ParsedFunction* parsed_function = new (zone) ParsedFunction(thread, func);

    parsed_function->set_scope(new LocalScope(nullptr, 0, 0));

    auto graph_entry =
        new GraphEntryInstr(*parsed_function, Compiler::kNoOSRDeoptId);

    const intptr_t block_id = 1;  // 0 is GraphEntry.
    graph_entry->set_normal_entry(
        new FunctionEntryInstr(graph_entry, block_id, kInvalidTryIndex,
                               CompilerState::Current().GetNextDeoptId()));
    return *new FlowGraph(*parsed_function, graph_entry, block_id,
                          PrologueInfo{-1, -1});
  }

  CompilerState& state_;
  FlowGraph& flow_graph_;

  struct PendingPhiInput {
    PhiInstr* phi;
    BlockEntryInstr* pred;
    Definition* defn;
  };
  GrowableArray<PendingPhiInput> pending_phis_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_TEST_HELPER_H_
