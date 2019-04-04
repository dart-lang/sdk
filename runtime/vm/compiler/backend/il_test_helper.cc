// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_test_helper.h"

#include "vm/compiler/aot/aot_call_specializer.h"
#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/call_specializer.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/dart_api_impl.h"
#include "vm/parser.h"
#include "vm/unit_test.h"

namespace dart {

RawLibrary* LoadTestScript(const char* script,
                           Dart_NativeEntryResolver resolver) {
  Dart_Handle api_lib;
  {
    TransitionVMToNative transition(Thread::Current());
    api_lib = TestCase::LoadTestScript(script, resolver);
  }
  auto& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(api_lib);
  EXPECT(!lib.IsNull());
  return lib.raw();
}

RawFunction* GetFunction(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  const auto& func = Function::Handle(lib.LookupFunctionAllowPrivate(
      String::Handle(Symbols::New(thread, name))));
  EXPECT(!func.IsNull());
  return func.raw();
}

void Invoke(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  Dart_Handle api_lib = Api::NewHandle(thread, lib.raw());
  TransitionVMToNative transition(thread);
  Dart_Handle result =
      Dart_Invoke(api_lib, NewString(name), /*argc=*/0, /*argv=*/nullptr);
  EXPECT_VALID(result);
}

FlowGraph* TestPipeline::Run(bool is_aot,
                             std::initializer_list<CompilerPass::Id> passes) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const bool optimized = true;
  const intptr_t osr_id = Compiler::kNoOSRDeoptId;

  auto pipeline = CompilationPipeline::New(zone, function_);

  auto parsed_function = new (zone)
      ParsedFunction(thread, Function::ZoneHandle(zone, function_.raw()));
  pipeline->ParseFunction(parsed_function);

  // Extract type feedback before the graph is built, as the graph
  // builder uses it to attach it to nodes.
  auto ic_data_array = new (zone) ZoneGrowableArray<const ICData*>();
  if (!is_aot) {
    function_.RestoreICDataMap(ic_data_array, /*clone_ic_data=*/false);
  }

  FlowGraph* flow_graph = pipeline->BuildFlowGraph(
      zone, parsed_function, ic_data_array, osr_id, optimized);

  if (is_aot) {
    flow_graph->PopulateWithICData(function_);
  }

  BlockScheduler block_scheduler(flow_graph);
  const bool reorder_blocks =
      FlowGraph::ShouldReorderBlocks(function_, optimized);
  if (reorder_blocks) {
    block_scheduler.AssignEdgeWeights();
  }

  SpeculativeInliningPolicy speculative_policy(/*enable_blacklist=*/false);
  CompilerPassState pass_state(thread, flow_graph, &speculative_policy);
  pass_state.block_scheduler = &block_scheduler;
  pass_state.reorder_blocks = reorder_blocks;

  if (optimized) {
    pass_state.inline_id_to_function.Add(&function_);
    // We do not add the token position now because we don't know the
    // position of the inlined call until later. A side effect of this
    // is that the length of |inline_id_to_function| is always larger
    // than the length of |inline_id_to_token_pos| by one.
    // Top scope function has no caller (-1). We do this because we expect
    // all token positions to be at an inlined call.
    pass_state.caller_inline_id.Add(-1);

    JitCallSpecializer jit_call_specializer(flow_graph, &speculative_policy);
    AotCallSpecializer aot_call_specializer(/*precompiler=*/nullptr, flow_graph,
                                            &speculative_policy);
    if (is_aot) {
      pass_state.call_specializer = &aot_call_specializer;
    } else {
      pass_state.call_specializer = &jit_call_specializer;
    }

    const auto mode = is_aot ? CompilerPass::kJIT : CompilerPass::kAOT;
    if (passes.size() > 0) {
      CompilerPass::RunPipelineWithPasses(&pass_state, passes);
    } else {
      CompilerPass::RunPipeline(mode, &pass_state);
    }
  }

  return flow_graph;
}

}  // namespace dart
