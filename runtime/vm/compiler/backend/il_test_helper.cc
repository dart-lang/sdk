// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_test_helper.h"

#include "vm/compiler/aot/aot_call_specializer.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/parser.h"
#include "vm/unit_test.h"

namespace dart {

LibraryPtr LoadTestScript(const char* script,
                          Dart_NativeEntryResolver resolver,
                          const char* lib_uri) {
  Dart_Handle api_lib;
  {
    TransitionVMToNative transition(Thread::Current());
    api_lib = TestCase::LoadTestScript(script, resolver, lib_uri);
    EXPECT_VALID(api_lib);
  }
  auto& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(api_lib);
  EXPECT(!lib.IsNull());
  return lib.ptr();
}

#if !defined(PRODUCT)
LibraryPtr ReloadTestScript(const char* script) {
  Dart_Handle api_lib;
  {
    TransitionVMToNative transition(Thread::Current());
    api_lib = TestCase::ReloadTestScript(script);
    EXPECT_VALID(api_lib);
  }
  auto& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(api_lib);
  EXPECT(!lib.IsNull());
  return lib.ptr();
}
#endif

FunctionPtr GetFunction(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  const auto& func = Function::Handle(lib.LookupFunctionAllowPrivate(
      String::Handle(Symbols::New(thread, name))));
  EXPECT(!func.IsNull());
  return func.ptr();
}

ClassPtr GetClass(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  const auto& cls = Class::Handle(
      lib.LookupClassAllowPrivate(String::Handle(Symbols::New(thread, name))));
  EXPECT(!cls.IsNull());
  return cls.ptr();
}

TypeParameterPtr GetClassTypeParameter(const Class& klass, intptr_t index) {
  const auto& param = TypeParameter::Handle(klass.TypeParameterAt(index));
  EXPECT(!param.IsNull());
  return param.ptr();
}

TypeParameterPtr GetFunctionTypeParameter(const Function& fun, intptr_t index) {
  const auto& param = TypeParameter::Handle(fun.TypeParameterAt(index));
  EXPECT(!param.IsNull());
  return param.ptr();
}

ObjectPtr Invoke(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  Dart_Handle api_lib = Api::NewHandle(thread, lib.ptr());
  Dart_Handle result;
  {
    TransitionVMToNative transition(thread);
    result = Dart_Invoke(api_lib, NewString(name), 0, nullptr);
    EXPECT_VALID(result);
  }
  return Api::UnwrapHandle(result);
}

InstructionsPtr BuildInstructions(
    std::function<void(compiler::Assembler* assembler)> fun) {
  auto thread = Thread::Current();
  compiler::Assembler assembler(nullptr);

  fun(&assembler);

  auto& code = Code::Handle();
  auto install_code_fun = [&] {
    code = Code::FinalizeCode(nullptr, &assembler,
                              Code::PoolAttachment::kNotAttachPool,
                              /*optimized=*/false, /*stats=*/nullptr);
  };
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  thread->isolate_group()->RunWithStoppedMutators(install_code_fun);
  return code.instructions();
}

FlowGraph* TestPipeline::RunPasses(
    std::initializer_list<CompilerPass::Id> passes) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const bool optimized = true;
  const intptr_t osr_id = Compiler::kNoOSRDeoptId;

  // We assume that prebuilt graph is already in SSA form so we should
  // avoid running ComputeSSA on it (it will just crash).
  const bool is_ssa = (flow_graph_ != nullptr);
  if (flow_graph_ == nullptr) {
    parsed_function_ = new (zone)
        ParsedFunction(thread, Function::ZoneHandle(zone, function_.ptr()));

    // Extract type feedback before the graph is built, as the graph
    // builder uses it to attach it to nodes.
    ic_data_array_ = new (zone) ZoneGrowableArray<const ICData*>();
    if (mode_ == CompilerPass::kJIT) {
      function_.RestoreICDataMap(ic_data_array_, /*clone_ic_data=*/false);
    }

    flow_graph_ = Compiler::BuildFlowGraph(zone, parsed_function_,
                                           ic_data_array_, osr_id, optimized);
  }

  if (mode_ == CompilerPass::kAOT) {
    flow_graph_->PopulateWithICData(function_);
  }

  if (mode_ == CompilerPass::kJIT && flow_graph_->should_reorder_blocks()) {
    BlockScheduler::AssignEdgeWeights(flow_graph_);
  }

  pass_state_ = new CompilerPassState(thread, flow_graph_);

  if (optimized) {
    JitCallSpecializer jit_call_specializer(flow_graph_);
    AotCallSpecializer aot_call_specializer(
        /*precompiler=*/nullptr, flow_graph_);
    if (mode_ == CompilerPass::kAOT) {
      pass_state_->call_specializer = &aot_call_specializer;
    } else {
      pass_state_->call_specializer = &jit_call_specializer;
    }

    if (passes.size() > 0) {
      flow_graph_ = CompilerPass::RunPipelineWithPasses(pass_state_, passes);
    } else {
      flow_graph_ = CompilerPass::RunPipeline(mode_, pass_state_,
                                              /*compute_ssa=*/!is_ssa);
    }
    pass_state_->call_specializer = nullptr;
  }

  return flow_graph_;
}

void TestPipeline::RunAdditionalPasses(
    std::initializer_list<CompilerPass::Id> passes) {
  JitCallSpecializer jit_call_specializer(flow_graph_);
  AotCallSpecializer aot_call_specializer(/*precompiler=*/nullptr, flow_graph_);
  if (mode_ == CompilerPass::kAOT) {
    pass_state_->call_specializer = &aot_call_specializer;
  } else {
    pass_state_->call_specializer = &jit_call_specializer;
  }

  flow_graph_ = CompilerPass::RunPipelineWithPasses(pass_state_, passes);
  pass_state_->call_specializer = nullptr;
}

void TestPipeline::RunForcedOptimizedAfterSSAPasses() {
  RunAdditionalPasses({
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      CompilerPass::kCanonicalize,
      CompilerPass::kBranchSimplify,
      CompilerPass::kIfConvert,
      CompilerPass::kConstantPropagation,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations_Final,
      CompilerPass::kTypePropagation,
      CompilerPass::kTryCatchOptimization,
      CompilerPass::kEliminateEnvironments,
      CompilerPass::kEliminateDeadPhis,
      CompilerPass::kDCE,
      CompilerPass::kCanonicalize,
      CompilerPass::kDelayAllocations,
      CompilerPass::kEliminateWriteBarriers,
      CompilerPass::kFinalizeGraph,
      CompilerPass::kAllocateRegisters,
      CompilerPass::kReorderBlocks,
  });
}

void TestPipeline::CompileGraphAndAttachFunction() {
  Zone* zone = thread_->zone();
  const bool optimized = true;

#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)
  const intptr_t far_branch_level = 0;
#else
  const intptr_t far_branch_level = 1;
#endif

  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler assembler(&object_pool_builder, far_branch_level);
  FlowGraphCompiler graph_compiler(&assembler, flow_graph_, *parsed_function_,
                                   optimized, ic_data_array_);

  graph_compiler.CompileGraph();

  const auto& deopt_info_array =
      Array::Handle(zone, graph_compiler.CreateDeoptInfo(&assembler));
  const auto pool_attachment = Code::PoolAttachment::kAttachPool;
  Code& code = Code::Handle();
  {
    SafepointWriteRwLocker ml(thread_,
                              thread_->isolate_group()->program_lock());
    code ^= Code::FinalizeCode(&graph_compiler, &assembler, pool_attachment,
                               optimized, nullptr);
  }
  code.set_is_optimized(optimized);
  code.set_owner(function_);

  graph_compiler.FinalizePcDescriptors(code);
  code.set_deopt_info_array(deopt_info_array);

  graph_compiler.FinalizeStackMaps(code);
  graph_compiler.FinalizeVarDescriptors(code);
  graph_compiler.FinalizeExceptionHandlers(code);
  graph_compiler.FinalizeCatchEntryMovesMap(code);
  graph_compiler.FinalizeStaticCallTargetsTable(code);
  graph_compiler.FinalizeCodeSourceMap(code);

  {
    SafepointWriteRwLocker ml(thread_,
                              thread_->isolate_group()->program_lock());
    if (optimized) {
      function_.InstallOptimizedCode(code);
    } else {
      function_.set_unoptimized_code(code);
      function_.AttachCode(code);
    }
  }

  // We expect there to be no deoptimizations.
  if (mode_ == CompilerPass::kAOT) {
    EXPECT(deopt_info_array.IsNull() || deopt_info_array.Length() == 0);
  }

#if !defined(PRODUCT)
  if (FLAG_disassemble_optimized) {
    Disassembler::DisassembleCode(function_, code, optimized);
  }
#endif
}

bool ILMatcher::TryMatch(std::initializer_list<MatchCode> match_codes,
                         MatchOpCode insert_before) {
  std::vector<MatchCode> qcodes = match_codes;

  if (insert_before != kInvalidMatchOpCode) {
    for (auto pos = qcodes.begin(); pos < qcodes.end(); pos++) {
      pos = qcodes.insert(pos, insert_before) + 1;
    }
  }

  if (trace_) {
    OS::PrintErr("ILMatcher: Matching the following graph\n");
    FlowGraphPrinter::PrintGraph("ILMatcher", flow_graph_);
    OS::PrintErr("ILMatcher: Starting match at %s:\n", cursor_->ToCString());
  }

  Instruction* cursor = cursor_;
  for (size_t i = 0; i < qcodes.size(); ++i) {
    Instruction** capture = qcodes[i].capture_;
    if (parallel_moves_handling_ == ParallelMovesHandling::kSkip) {
      while (cursor->IsParallelMove()) {
        cursor = cursor->next();
      }
    }
    if (trace_) {
      OS::PrintErr("  matching %30s @ %s\n",
                   MatchOpCodeToCString(qcodes[i].opcode()),
                   cursor->ToCString());
    }

    auto next = MatchInternal(qcodes, i, cursor);
    if (next == nullptr) {
      if (trace_) {
        OS::PrintErr("  -> Match failed\n");
      }
      cursor = next;
      break;
    }
    if (capture != nullptr) {
      *capture = cursor;
    }
    cursor = next;
  }
  if (cursor != nullptr) {
    cursor_ = cursor;
    return true;
  }
  return false;
}

Instruction* ILMatcher::MatchInternal(std::vector<MatchCode> match_codes,
                                      size_t i,
                                      Instruction* cursor) {
  const MatchOpCode opcode = match_codes[i].opcode();
  if (opcode == kMatchAndMoveBranchTrue) {
    auto branch = cursor->AsBranch();
    if (branch == nullptr) return nullptr;
    return branch->true_successor();
  }
  if (opcode == kMatchAndMoveBranchFalse) {
    auto branch = cursor->AsBranch();
    if (branch == nullptr) return nullptr;
    return branch->false_successor();
  }
  if (opcode == kNop) {
    return cursor;
  }
  if (opcode == kMoveAny) {
    return cursor->next();
  }
  if (opcode == kMoveParallelMoves) {
    while (cursor != nullptr && cursor->IsParallelMove()) {
      cursor = cursor->next();
    }
    return cursor;
  }

  if (opcode == kMoveGlob) {
    ASSERT((i + 1) < match_codes.size());
    while (true) {
      if (cursor == nullptr) return nullptr;
      if (MatchInternal(match_codes, i + 1, cursor) != nullptr) {
        return cursor;
      }
      if (auto as_goto = cursor->AsGoto()) {
        cursor = as_goto->successor();
      } else {
        cursor = cursor->next();
      }
    }
  }

  if (opcode == kMoveDebugStepChecks) {
    while (cursor != nullptr && cursor->IsDebugStepCheck()) {
      cursor = cursor->next();
    }
    return cursor;
  }

  if (opcode == kMatchAndMoveGoto) {
    if (auto goto_instr = cursor->AsGoto()) {
      return goto_instr->successor();
    }
  }

  switch (opcode) {
#define EMIT_CASE(Instruction, _)                                              \
  case kMatch##Instruction: {                                                  \
    if (cursor->Is##Instruction()) {                                           \
      return cursor;                                                           \
    }                                                                          \
    return nullptr;                                                            \
  }                                                                            \
  case kMatchAndMove##Instruction: {                                           \
    if (cursor->Is##Instruction()) {                                           \
      return cursor->next();                                                   \
    }                                                                          \
    return nullptr;                                                            \
  }                                                                            \
  case kMatchAndMoveOptional##Instruction: {                                   \
    if (cursor->Is##Instruction()) {                                           \
      return cursor->next();                                                   \
    }                                                                          \
    return cursor;                                                             \
  }
    FOR_EACH_CONCRETE_INSTRUCTION(EMIT_CASE)
    FOR_EACH_ABSTRACT_INSTRUCTION(EMIT_CASE)
#undef EMIT_CASE
    default:
      UNREACHABLE();
  }

  UNREACHABLE();
  return nullptr;
}

const char* ILMatcher::MatchOpCodeToCString(MatchOpCode opcode) {
  if (opcode == kMatchAndMoveBranchTrue) {
    return "kMatchAndMoveBranchTrue";
  }
  if (opcode == kMatchAndMoveBranchFalse) {
    return "kMatchAndMoveBranchFalse";
  }
  if (opcode == kNop) {
    return "kNop";
  }
  if (opcode == kMoveAny) {
    return "kMoveAny";
  }
  if (opcode == kMoveParallelMoves) {
    return "kMoveParallelMoves";
  }
  if (opcode == kMoveGlob) {
    return "kMoveGlob";
  }
  if (opcode == kMoveDebugStepChecks) {
    return "kMoveDebugStepChecks";
  }

  switch (opcode) {
#define EMIT_CASE(Instruction, _)                                              \
  case kMatch##Instruction:                                                    \
    return "kMatch" #Instruction;                                              \
  case kMatchAndMove##Instruction:                                             \
    return "kMatchAndMove" #Instruction;                                       \
  case kMatchAndMoveOptional##Instruction:                                     \
    return "kMatchAndMoveOptional" #Instruction;
    FOR_EACH_CONCRETE_INSTRUCTION(EMIT_CASE)
    FOR_EACH_ABSTRACT_INSTRUCTION(EMIT_CASE)
#undef EMIT_CASE
    default:
      UNREACHABLE();
  }

  UNREACHABLE();
  return nullptr;
}

}  // namespace dart
