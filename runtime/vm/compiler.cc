// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler.h"

#include "vm/assembler.h"

#include "vm/ast_printer.h"
#include "vm/block_scheduler.h"
#include "vm/cha.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/constant_propagator.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_inliner.h"
#include "vm/flow_graph_optimizer.h"
#include "vm/flow_graph_type_propagator.h"
#include "vm/il_printer.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/regexp_parser.h"
#include "vm/regexp_assembler.h"
#include "vm/scanner.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, allocation_sinking, true,
    "Attempt to sink temporary allocations to side exits");
DEFINE_FLAG(bool, common_subexpression_elimination, true,
    "Do common subexpression elimination.");
DEFINE_FLAG(bool, constant_propagation, true,
    "Do conditional constant propagation/unreachable code elimination.");
DEFINE_FLAG(int, deoptimization_counter_threshold, 16,
    "How many times we allow deoptimization before we disallow optimization.");
DEFINE_FLAG(bool, disassemble, false, "Disassemble dart code.");
DEFINE_FLAG(bool, disassemble_optimized, false, "Disassemble optimized code.");
DEFINE_FLAG(bool, loop_invariant_code_motion, true,
    "Do loop invariant code motion.");
DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DEFINE_FLAG(bool, print_flow_graph_optimized, false,
    "Print the IR flow graph when optimizing.");
DEFINE_FLAG(bool, print_ic_data_map, false,
    "Print the deopt-id to ICData map in optimizing compiler.");
DEFINE_FLAG(bool, range_analysis, true, "Enable range analysis");
DEFINE_FLAG(bool, reorder_basic_blocks, true, "Enable basic-block reordering.");
DEFINE_FLAG(bool, trace_compiler, false, "Trace compiler operations.");
DEFINE_FLAG(bool, trace_bailout, false, "Print bailout from ssa compiler.");
DEFINE_FLAG(bool, use_inlining, true, "Enable call-site inlining");
DEFINE_FLAG(bool, verify_compiler, false,
    "Enable compiler verification assertions");

DECLARE_FLAG(bool, background_compilation);
DECLARE_FLAG(bool, load_deferred_eagerly);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, trace_inlining_intervals);
DECLARE_FLAG(bool, trace_irregexp);


bool Compiler::always_optimize_ = false;
bool Compiler::allow_recompilation_ = true;


// TODO(zerny): Factor out unoptimizing/optimizing pipelines and remove
// separate helpers functions & `optimizing` args.
class CompilationPipeline : public ZoneAllocated {
 public:
  static CompilationPipeline* New(Zone* zone, const Function& function);

  virtual void ParseFunction(ParsedFunction* parsed_function) = 0;
  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id) = 0;
  virtual void FinalizeCompilation() = 0;
  virtual ~CompilationPipeline() { }
};


class DartCompilationPipeline : public CompilationPipeline {
 public:
  virtual void ParseFunction(ParsedFunction* parsed_function) {
    Parser::ParseFunction(parsed_function);
    parsed_function->AllocateVariables();
  }

  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id) {
    // Build the flow graph.
    FlowGraphBuilder builder(*parsed_function,
                             ic_data_array,
                             NULL,  // NULL = not inlining.
                             osr_id);

    return builder.BuildGraph();
  }

  virtual void FinalizeCompilation() { }
};


class IrregexpCompilationPipeline : public CompilationPipeline {
 public:
  IrregexpCompilationPipeline() : backtrack_goto_(NULL) { }

  virtual void ParseFunction(ParsedFunction* parsed_function) {
    RegExpParser::ParseFunction(parsed_function);
    // Variables are allocated after compilation.
  }

  virtual FlowGraph* BuildFlowGraph(
      Zone* zone,
      ParsedFunction* parsed_function,
      const ZoneGrowableArray<const ICData*>& ic_data_array,
      intptr_t osr_id) {
    // Compile to the dart IR.
    RegExpEngine::CompilationResult result =
        RegExpEngine::CompileIR(parsed_function->regexp_compile_data(),
                                parsed_function,
                                ic_data_array);
    backtrack_goto_ = result.backtrack_goto;

    // Allocate variables now that we know the number of locals.
    parsed_function->AllocateIrregexpVariables(result.num_stack_locals);

    // Build the flow graph.
    FlowGraphBuilder builder(*parsed_function,
                             ic_data_array,
                             NULL,  // NULL = not inlining.
                             osr_id);

    return new(zone) FlowGraph(*parsed_function,
                               result.graph_entry,
                               result.num_blocks);
  }

  virtual void FinalizeCompilation() {
    backtrack_goto_->ComputeOffsetTable();
  }

 private:
  IndirectGotoInstr* backtrack_goto_;
};


CompilationPipeline* CompilationPipeline::New(Zone* zone,
                                              const Function& function) {
  if (function.IsIrregexpFunction()) {
    return new(zone) IrregexpCompilationPipeline();
  } else {
    return new(zone) DartCompilationPipeline();
  }
}


// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  ASSERT(!function.HasCode());
  const Error& error =
      Error::Handle(Compiler::CompileFunction(thread, function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}


bool Compiler::IsBackgroundCompilation() {
  // For now: compilation in non mutator thread is the background compoilation.
  return !Thread::Current()->IsMutatorThread();
}


RawError* Compiler::Compile(const Library& library, const Script& script) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    StackZone zone(thread);
    if (FLAG_trace_compiler) {
      const String& script_url = String::Handle(script.url());
      // TODO(iposva): Extract script kind.
      THR_Print("Compiling %s '%s'\n", "", script_url.ToCString());
    }
    const String& library_key = String::Handle(library.private_key());
    script.Tokenize(library_key);
    Parser::ParseCompilationUnit(library, script);
    return Error::null();
  } else {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone zone(thread);
    Error& error = Error::Handle();
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


static void AddRelatedClassesToList(
    const Class& cls,
    GrowableHandlePtrArray<const Class>* parse_list,
    GrowableHandlePtrArray<const Class>* patch_list) {
  Zone* zone = Thread::Current()->zone();
  Class& parse_class = Class::Handle(zone);
  AbstractType& interface_type = Type::Handle(zone);
  Array& interfaces = Array::Handle(zone);

  // Add all the interfaces implemented by the class that have not been
  // already parsed to the parse list. Mark the interface as parsed so that
  // we don't recursively add it back into the list.
  interfaces ^= cls.interfaces();
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    interface_type ^= interfaces.At(i);
    parse_class ^= interface_type.type_class();
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      parse_list->Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
  }

  // Walk up the super_class chain and add these classes to the list if they
  // have not been already parsed to the parse list. Mark the class as parsed
  // so that we don't recursively add it back into the list.
  parse_class ^= cls.SuperClass();
  while (!parse_class.IsNull()) {
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      parse_list->Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
    parse_class ^= parse_class.SuperClass();
  }

  // Add patch classes if they exist to the parse list if they have not already
  // been parsed and patched. Mark the class as parsed so that we don't
  // recursively add it back into the list.
  parse_class ^= cls.GetPatchClass();
  if (!parse_class.IsNull()) {
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      patch_list->Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
  }
}


RawError* Compiler::CompileClass(const Class& cls) {
  ASSERT(Thread::Current()->IsMutatorThread());
  // If class is a top level class it is already parsed.
  if (cls.IsTopLevel()) {
    return Error::null();
  }
  // If the class is already marked for parsing return immediately.
  if (cls.is_marked_for_parsing()) {
    return Error::null();
  }
  // If the class is a signature class there is no need to try and
  // compile it. Just finalize it directly.
  if (cls.IsSignatureClass()) {
#if defined(DEBUG)
    const Type& type = Type::Handle(
        Isolate::Current()->object_store()->function_impl_type());
    const Class& type_cls = Class::Handle(type.type_class());
    ASSERT(type_cls.is_finalized());
#endif
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      ClassFinalizer::FinalizeClass(cls);
      return Error::null();
    } else {
      Thread* thread = Thread::Current();
      Isolate* isolate = thread->isolate();
      Error& error = Error::Handle(thread->zone());
      error = isolate->object_store()->sticky_error();
      isolate->object_store()->clear_sticky_error();
      return error.raw();
    }
  }

  Thread* const thread = Thread::Current();
  Isolate* const isolate = thread->isolate();
  StackZone zone(thread);
  // We remember all the classes that are being compiled in these lists. This
  // also allows us to reset the marked_for_parsing state in case we see an
  // error.
  VMTagScope tagScope(thread, VMTag::kCompileClassTagId);
  GrowableHandlePtrArray<const Class> parse_list(thread->zone(), 4);
  GrowableHandlePtrArray<const Class> patch_list(thread->zone(), 4);

  // Parse the class and all the interfaces it implements and super classes.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      THR_Print("Compiling Class %s '%s'\n", "", cls.ToCString());
    }

    // Add the primary class which needs to be parsed to the parse list.
    // Mark the class as parsed so that we don't recursively add the same
    // class back into the list.
    parse_list.Add(cls);
    cls.set_is_marked_for_parsing();

    // Add all super classes, interface classes and patch class if one
    // exists to the corresponding lists.
    // NOTE: The parse_list array keeps growing as more classes are added
    // to it by AddRelatedClassesToList. It is not OK to hoist
    // parse_list.Length() into a local variable and iterate using the local
    // variable.
    for (intptr_t i = 0; i < parse_list.length(); i++) {
      AddRelatedClassesToList(parse_list.At(i), &parse_list, &patch_list);
    }

    // Parse all the classes that have been added above.
    for (intptr_t i = (parse_list.length() - 1); i >=0 ; i--) {
      const Class& parse_class = parse_list.At(i);
      ASSERT(!parse_class.IsNull());
      Parser::ParseClass(parse_class);
    }

    // Parse all the patch classes that have been added above.
    for (intptr_t i = 0; i < patch_list.length(); i++) {
      const Class& parse_class = patch_list.At(i);
      ASSERT(!parse_class.IsNull());
      Parser::ParseClass(parse_class);
    }

    // Finalize these classes.
    for (intptr_t i = (parse_list.length() - 1); i >=0 ; i--) {
      const Class& parse_class = parse_list.At(i);
      ASSERT(!parse_class.IsNull());
      ClassFinalizer::FinalizeClass(parse_class);
      parse_class.reset_is_marked_for_parsing();
    }
    for (intptr_t i = (patch_list.length() - 1); i >=0 ; i--) {
      const Class& parse_class = patch_list.At(i);
      ASSERT(!parse_class.IsNull());
      ClassFinalizer::FinalizeClass(parse_class);
      parse_class.reset_is_marked_for_parsing();
    }

    return Error::null();
  } else {
    // Reset the marked for parsing flags.
    for (intptr_t i = 0; i < parse_list.length(); i++) {
      const Class& parse_class = parse_list.At(i);
      if (parse_class.is_marked_for_parsing()) {
        parse_class.reset_is_marked_for_parsing();
      }
    }
    for (intptr_t i = 0; i < patch_list.length(); i++) {
      const Class& parse_class = patch_list.At(i);
      if (parse_class.is_marked_for_parsing()) {
        parse_class.reset_is_marked_for_parsing();
      }
    }
    Error& error = Error::Handle(zone.GetZone());
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


// Return false if bailed out.
// If optimized_result_code is not NULL then it is caller's responsibility
// to install code.
static bool CompileParsedFunctionHelper(CompilationPipeline* pipeline,
                                        ParsedFunction* parsed_function,
                                        bool optimized,
                                        intptr_t osr_id,
                                        BackgroundCompilationResult* result) {
  const Function& function = parsed_function->function();
  if (optimized && !function.IsOptimizable()) {
    return false;
  }
  bool is_compiled = false;
  Thread* const thread = Thread::Current();
  Zone* const zone = thread->zone();
  Isolate* const isolate = thread->isolate();
  CSTAT_TIMER_SCOPE(thread, codegen_timer);
  HANDLESCOPE(thread);

  // We may reattempt compilation if the function needs to be assembled using
  // far branches on ARM and MIPS. In the else branch of the setjmp call,
  // done is set to false, and use_far_branches is set to true if there is a
  // longjmp from the ARM or MIPS assemblers. In all other paths through this
  // while loop, done is set to true. use_far_branches is always false on ia32
  // and x64.
  bool done = false;
  // volatile because the variable may be clobbered by a longjmp.
  volatile bool use_far_branches = false;
  while (!done) {
    const intptr_t prev_deopt_id = thread->deopt_id();
    thread->set_deopt_id(0);
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      FlowGraph* flow_graph = NULL;

      // Class hierarchy analysis is registered with the isolate in the
      // constructor and unregisters itself upon destruction.
      CHA cha(thread);

      // TimerScope needs an isolate to be properly terminated in case of a
      // LongJump.
      {
        CSTAT_TIMER_SCOPE(thread, graphbuilder_timer);
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new(zone) ZoneGrowableArray<const ICData*>();
        if (optimized) {
          // Extract type feedback before the graph is built, as the graph
          // builder uses it to attach it to nodes.
          ASSERT(function.deoptimization_counter() <
                 FLAG_deoptimization_counter_threshold);

          // 'Freeze' ICData in background compilation so that it does not
          // change while compiling.
          const bool clone_descriptors = Compiler::IsBackgroundCompilation();
          function.RestoreICDataMap(ic_data_array, clone_descriptors);

          if (FLAG_print_ic_data_map) {
            for (intptr_t i = 0; i < ic_data_array->length(); i++) {
              if ((*ic_data_array)[i] != NULL) {
                THR_Print("%" Pd " ", i);
                FlowGraphPrinter::PrintICData(*(*ic_data_array)[i]);
              }
            }
          }
        }

        flow_graph = pipeline->BuildFlowGraph(zone,
                                              parsed_function,
                                              *ic_data_array,
                                              osr_id);
      }

      const bool print_flow_graph =
          (FLAG_print_flow_graph ||
          (optimized && FLAG_print_flow_graph_optimized)) &&
          FlowGraphPrinter::ShouldPrint(function);

      if (print_flow_graph) {
        if (osr_id == Compiler::kNoOSRDeoptId) {
          FlowGraphPrinter::PrintGraph("Before Optimizations", flow_graph);
        } else {
          FlowGraphPrinter::PrintGraph("For OSR", flow_graph);
        }
      }

      BlockScheduler block_scheduler(flow_graph);
      const bool reorder_blocks =
          FlowGraph::ShouldReorderBlocks(function, optimized);
      if (reorder_blocks) {
        block_scheduler.AssignEdgeWeights();
      }

      if (optimized) {
        CSTAT_TIMER_SCOPE(thread, ssa_timer);
        // Transform to SSA (virtual register 0 and no inlining arguments).
        flow_graph->ComputeSSA(0, NULL);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
        if (print_flow_graph) {
          FlowGraphPrinter::PrintGraph("After SSA", flow_graph);
        }
      }

      // Maps inline_id_to_function[inline_id] -> function. Top scope
      // function has inline_id 0. The map is populated by the inliner.
      GrowableArray<const Function*> inline_id_to_function;
      // For a given inlining-id(index) specifies the caller's inlining-id.
      GrowableArray<intptr_t> caller_inline_id;
      // Collect all instance fields that are loaded in the graph and
      // have non-generic type feedback attached to them that can
      // potentially affect optimizations.
      if (optimized) {
        inline_id_to_function.Add(&function);
        // Top scope function has no caller (-1).
        caller_inline_id.Add(-1);
        CSTAT_TIMER_SCOPE(thread, graphoptimizer_timer);

        FlowGraphOptimizer optimizer(flow_graph);
        if (Compiler::always_optimize()) {
          optimizer.PopulateWithICData();
        }
        optimizer.ApplyICData();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Optimize (a << b) & c patterns, merge operations.
        // Run early in order to have more opportunity to optimize left shifts.
        optimizer.TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphInliner::SetInliningId(flow_graph, 0);

        // Inlining (mutates the flow graph)
        if (FLAG_use_inlining) {
          CSTAT_TIMER_SCOPE(thread, graphinliner_timer);
          // Propagate types to create more inlining opportunities.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // Use propagated class-ids to create more inlining opportunities.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          FlowGraphInliner inliner(flow_graph,
                                   &inline_id_to_function,
                                   &caller_inline_id);
          inliner.Inline();
          // Use lists are maintained and validated by the inliner.
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types and eliminate more type tests.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Use propagated class-ids to optimize further.
        optimizer.ApplyClassIds();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Propagate types for potentially newly added instructions by
        // ApplyClassIds(). Must occur before canonicalization.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Do optimizations that depend on the propagated type information.
        if (optimizer.Canonicalize()) {
          // Invoke Canonicalize twice in order to fully canonicalize patterns
          // like "if (a & const == 0) { }".
          optimizer.Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        BranchSimplifier::Simplify(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        IfConverter::Simplify(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (FLAG_constant_propagation) {
          ConstantPropagator::Optimize(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
          // A canonicalization pass to remove e.g. smi checks on smi constants.
          optimizer.Canonicalize();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
          // Canonicalization introduced more opportunities for constant
          // propagation.
          ConstantPropagator::Optimize(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Optimistically convert loop phis that have a single non-smi input
        // coming from the loop pre-header into smi-phis.
        if (FLAG_loop_invariant_code_motion) {
          LICM licm(flow_graph);
          licm.OptimisticallySpecializeSmiPhis();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types and eliminate even more type tests.
        // Recompute types after constant propagation to infer more precise
        // types for uses that were previously reached by now eliminated phis.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Where beneficial convert Smi operations into Int32 operations.
        // Only meanigful for 32bit platforms right now.
        optimizer.WidenSmiToInt32();

        // Unbox doubles. Performed after constant propagation to minimize
        // interference from phis merging double values and tagged
        // values coming from dead paths.
        optimizer.SelectRepresentations();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (FLAG_common_subexpression_elimination ||
            FLAG_loop_invariant_code_motion) {
          flow_graph->ComputeBlockEffects();
        }

        if (FLAG_common_subexpression_elimination) {
          if (DominatorBasedCSE::Optimize(flow_graph)) {
            DEBUG_ASSERT(flow_graph->VerifyUseLists());
            // Do another round of CSE to take secondary effects into account:
            // e.g. when eliminating dependent loads (a.x[0] + a.x[0])
            // TODO(fschneider): Change to a one-pass optimization pass.
            DominatorBasedCSE::Optimize(flow_graph);
            DEBUG_ASSERT(flow_graph->VerifyUseLists());
          }
        }

        // Run loop-invariant code motion right after load elimination since it
        // depends on the numbering of loads from the previous load-elimination.
        if (FLAG_loop_invariant_code_motion) {
          LICM licm(flow_graph);
          licm.Optimize();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }
        flow_graph->RemoveRedefinitions();

        // Optimize (a << b) & c patterns, merge operations.
        // Run after CSE in order to have more opportunity to merge
        // instructions that have same inputs.
        optimizer.TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        DeadStoreElimination::Optimize(flow_graph);

        if (FLAG_range_analysis) {
          // Propagate types after store-load-forwarding. Some phis may have
          // become smi phis that can be processed by range analysis.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // We have to perform range analysis after LICM because it
          // optimistically moves CheckSmi through phis into loop preheaders
          // making some phis smi.
          optimizer.InferIntRanges();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (FLAG_constant_propagation) {
          // Constant propagation can use information from range analysis to
          // find unreachable branch targets and eliminate branches that have
          // the same true- and false-target.
          ConstantPropagator::OptimizeBranches(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Recompute types after code movement was done to ensure correct
        // reaching types for hoisted values.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Optimize try-blocks.
        TryCatchAnalyzer::Optimize(flow_graph);

        // Detach environments from the instructions that can't deoptimize.
        // Do it before we attempt to perform allocation sinking to minimize
        // amount of materializations it has to perform.
        optimizer.EliminateEnvironments();

        DeadCodeElimination::EliminateDeadPhis(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (optimizer.Canonicalize()) {
          optimizer.Canonicalize();
        }

        // Attempt to sink allocations of temporary non-escaping objects to
        // the deoptimization path.
        AllocationSinking* sinking = NULL;
        if (FLAG_allocation_sinking &&
            (flow_graph->graph_entry()->SuccessorCount()  == 1)) {
          // TODO(fschneider): Support allocation sinking with try-catch.
          sinking = new AllocationSinking(flow_graph);
          sinking->Optimize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        DeadCodeElimination::EliminateDeadPhis(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Ensure that all phis inserted by optimization passes have consistent
        // representations.
        optimizer.SelectRepresentations();

        if (optimizer.Canonicalize()) {
          // To fully remove redundant boxing (e.g. BoxDouble used only in
          // environments and UnboxDouble instructions) instruction we
          // first need to replace all their uses and then fold them away.
          // For now we just repeat Canonicalize twice to do that.
          // TODO(vegorov): implement a separate representation folding pass.
          optimizer.Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (sinking != NULL) {
          // Remove all MaterializeObject instructions inserted by allocation
          // sinking from the flow graph and let them float on the side
          // referenced only from environments. Register allocator will consider
          // them as part of a deoptimization environment.
          sinking->DetachMaterializations();
        }

        // Compute and store graph informations (call & instruction counts)
        // to be later used by the inliner.
        FlowGraphInliner::CollectGraphInfo(flow_graph, true);

        // Perform register allocation on the SSA graph.
        FlowGraphAllocator allocator(*flow_graph);
        allocator.AllocateRegisters();
        if (reorder_blocks) block_scheduler.ReorderBlocks();

        if (print_flow_graph) {
          FlowGraphPrinter::PrintGraph("After Optimizations", flow_graph);
        }
      }

      ASSERT(inline_id_to_function.length() == caller_inline_id.length());
      Assembler assembler(use_far_branches);
      FlowGraphCompiler graph_compiler(&assembler, flow_graph,
                                       *parsed_function, optimized,
                                       inline_id_to_function,
                                       caller_inline_id);
      {
        CSTAT_TIMER_SCOPE(thread, graphcompiler_timer);
        graph_compiler.CompileGraph();
        pipeline->FinalizeCompilation();
      }
      {
        CSTAT_TIMER_SCOPE(thread, codefinalizer_timer);
        // CreateDeoptInfo uses the object pool and needs to be done before
        // FinalizeCode.
        const Array& deopt_info_array =
            Array::Handle(zone, graph_compiler.CreateDeoptInfo(&assembler));
        INC_STAT(thread, total_code_size,
                 deopt_info_array.Length() * sizeof(uword));
        const Code& code = Code::Handle(
            Code::FinalizeCode(function, &assembler, optimized));
        code.set_is_optimized(optimized);
        code.set_owner(function);

        const Array& intervals = graph_compiler.inlined_code_intervals();
        INC_STAT(thread, total_code_size,
                 intervals.Length() * sizeof(uword));
        code.SetInlinedIntervals(intervals);

        const Array& inlined_id_array =
            Array::Handle(zone, graph_compiler.InliningIdToFunction());
        INC_STAT(thread, total_code_size,
                 inlined_id_array.Length() * sizeof(uword));
        code.SetInlinedIdToFunction(inlined_id_array);

        const Array& caller_inlining_id_map_array =
            Array::Handle(zone, graph_compiler.CallerInliningIdMap());
        INC_STAT(thread, total_code_size,
                 caller_inlining_id_map_array.Length() * sizeof(uword));
        code.SetInlinedCallerIdMap(caller_inlining_id_map_array);

        graph_compiler.FinalizePcDescriptors(code);
        code.set_deopt_info_array(deopt_info_array);

        graph_compiler.FinalizeStackmaps(code);
        graph_compiler.FinalizeVarDescriptors(code);
        graph_compiler.FinalizeExceptionHandlers(code);
        graph_compiler.FinalizeStaticCallTargetsTable(code);

        if (optimized) {
          if (result != NULL) {
            ASSERT(!Thread::Current()->IsMutatorThread());
            // Do not install code, but return it instead.
            // Since code dependencies (CHA, fields) are defined eagerly,
            // the code may be disabled before installing it.
            code.set_owner(function);
            result->set_result_code(code);
            // Disable invalidation counters that are not relevant.
            if (thread->cha()->leaf_classes().is_empty()) {
              result->ClearCHAInvalidationGen();
            }
            if (flow_graph->guarded_fields()->is_empty()) {
              result->ClearFieldInnvalidationGen();
            }
            if (!parsed_function->HasDeferredPrefixes()) {
              result->ClearPrefixInnvalidationGen();
            }
          } else {
            const bool is_osr = osr_id != Compiler::kNoOSRDeoptId;
            function.InstallOptimizedCode(code, is_osr);
          }

          // TODO(srdjan): In background compilation, verify that CHA and field
          // guards have not been invalidated in the meantime.
          // Register code with the classes it depends on because of CHA and
          // fields it depends on because of store guards, unless we cannot
          // deopt.
          if (Compiler::allow_recompilation()) {
            for (intptr_t i = 0;
                 i < thread->cha()->leaf_classes().length();
                 ++i) {
              thread->cha()->leaf_classes()[i]->RegisterCHACode(code);
            }
            for (intptr_t i = 0;
                 i < flow_graph->guarded_fields()->length();
                 i++) {
              const Field* field = (*flow_graph->guarded_fields())[i];
              field->RegisterDependentCode(code);
            }
          }
        } else {  // not optimized.
          if (!Compiler::always_optimize() &&
              (function.ic_data_array() == Array::null())) {
            function.SaveICDataMap(
                graph_compiler.deopt_id_to_ic_data(),
                Array::Handle(zone, graph_compiler.edge_counters_array()));
          }
          function.set_unoptimized_code(code);
          function.AttachCode(code);
        }
        if (parsed_function->HasDeferredPrefixes()) {
          ASSERT(!FLAG_load_deferred_eagerly);
          ZoneGrowableArray<const LibraryPrefix*>* prefixes =
              parsed_function->deferred_prefixes();
          for (intptr_t i = 0; i < prefixes->length(); i++) {
            (*prefixes)[i]->RegisterDependentCode(code);
          }
        }
      }
      // Mark that this isolate now has compiled code.
      isolate->set_has_compiled_code(true);
      // Exit the loop and the function with the correct result value.
      is_compiled = true;
      done = true;
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(
          isolate->object_store()->sticky_error());

      if (error.raw() == Object::branch_offset_error().raw()) {
        // Compilation failed due to an out of range branch offset in the
        // assembler. We try again (done = false) with far branches enabled.
        done = false;
        ASSERT(!use_far_branches);
        use_far_branches = true;
      } else {
        // If the error isn't due to an out of range branch offset, we don't
        // try again (done = true), and indicate that we did not finish
        // compiling (is_compiled = false).
        if (FLAG_trace_bailout) {
          THR_Print("%s\n", error.ToErrorCString());
        }
        done = true;
      }

      // Clear the error if it was not a real error, but just a bailout.
      if (error.IsLanguageError() &&
          (LanguageError::Cast(error).kind() == Report::kBailout)) {
        isolate->object_store()->clear_sticky_error();
      }
      is_compiled = false;
    }
    // Reset global isolate state.
    thread->set_deopt_id(prev_deopt_id);
  }
  return is_compiled;
}


static void DisassembleCode(const Function& function, bool optimized) {
  const char* function_fullname = function.ToFullyQualifiedCString();
  THR_Print("Code for %sfunction '%s' {\n",
            optimized ? "optimized " : "",
            function_fullname);
  const Code& code = Code::Handle(function.CurrentCode());
  code.Disassemble();
  THR_Print("}\n");

  THR_Print("Pointer offsets for function: {\n");
  // Pointer offsets are stored in descending order.
  Object& obj = Object::Handle();
  for (intptr_t i = code.pointer_offsets_length() - 1; i >= 0; i--) {
    const uword addr = code.GetPointerOffsetAt(i) + code.EntryPoint();
    obj = *reinterpret_cast<RawObject**>(addr);
    THR_Print(" %d : %#" Px " '%s'\n",
              code.GetPointerOffsetAt(i), addr, obj.ToCString());
  }
  THR_Print("}\n");

  THR_Print("PC Descriptors for function '%s' {\n", function_fullname);
  PcDescriptors::PrintHeaderString();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  THR_Print("%s}\n", descriptors.ToCString());

  uword start = Instructions::Handle(code.instructions()).EntryPoint();
  const Array& deopt_table = Array::Handle(code.deopt_info_array());
  intptr_t deopt_table_length = DeoptTable::GetLength(deopt_table);
  if (deopt_table_length > 0) {
    THR_Print("DeoptInfo: {\n");
    Smi& offset = Smi::Handle();
    TypedData& info = TypedData::Handle();
    Smi& reason_and_flags = Smi::Handle();
    for (intptr_t i = 0; i < deopt_table_length; ++i) {
      DeoptTable::GetEntry(deopt_table, i, &offset, &info, &reason_and_flags);
      const intptr_t reason =
          DeoptTable::ReasonField::decode(reason_and_flags.Value());
      ASSERT((0 <= reason) && (reason < ICData::kDeoptNumReasons));
      THR_Print("%4" Pd ": 0x%" Px "  %s  (%s)\n",
                i,
                start + offset.Value(),
                DeoptInfo::ToCString(deopt_table, info),
                DeoptReasonToCString(
                    static_cast<ICData::DeoptReasonId>(reason)));
    }
    THR_Print("}\n");
  }

  const ObjectPool& object_pool = ObjectPool::Handle(code.GetObjectPool());
  object_pool.DebugPrint();

  THR_Print("Stackmaps for function '%s' {\n", function_fullname);
  if (code.stackmaps() != Array::null()) {
    const Array& stackmap_table = Array::Handle(code.stackmaps());
    Stackmap& map = Stackmap::Handle();
    for (intptr_t i = 0; i < stackmap_table.Length(); ++i) {
      map ^= stackmap_table.At(i);
      THR_Print("%s\n", map.ToCString());
    }
  }
  THR_Print("}\n");

  THR_Print("Variable Descriptors for function '%s' {\n",
            function_fullname);
  const LocalVarDescriptors& var_descriptors =
      LocalVarDescriptors::Handle(code.GetLocalVarDescriptors());
  intptr_t var_desc_length =
      var_descriptors.IsNull() ? 0 : var_descriptors.Length();
  String& var_name = String::Handle();
  for (intptr_t i = 0; i < var_desc_length; i++) {
    var_name = var_descriptors.GetName(i);
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors.GetInfo(i, &var_info);
    const int8_t kind = var_info.kind();
    if (kind == RawLocalVarDescriptors::kSavedCurrentContext) {
      THR_Print("  saved current CTX reg offset %d\n", var_info.index());
    } else {
      if (kind == RawLocalVarDescriptors::kContextLevel) {
        THR_Print("  context level %d scope %d", var_info.index(),
            var_info.scope_id);
      } else if (kind == RawLocalVarDescriptors::kStackVar) {
        THR_Print("  stack var '%s' offset %d",
          var_name.ToCString(), var_info.index());
      } else {
        ASSERT(kind == RawLocalVarDescriptors::kContextVar);
        THR_Print("  context var '%s' level %d offset %d",
            var_name.ToCString(), var_info.scope_id, var_info.index());
      }
      THR_Print(" (valid %d-%d)\n", var_info.begin_pos, var_info.end_pos);
    }
  }
  THR_Print("}\n");

  THR_Print("Exception Handlers for function '%s' {\n", function_fullname);
  const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(code.exception_handlers());
  THR_Print("%s}\n", handlers.ToCString());

  {
    THR_Print("Static call target functions {\n");
    const Array& table = Array::Handle(code.static_calls_target_table());
    Smi& offset = Smi::Handle();
    Function& function = Function::Handle();
    Code& code = Code::Handle();
    for (intptr_t i = 0; i < table.Length();
        i += Code::kSCallTableEntryLength) {
      offset ^= table.At(i + Code::kSCallTableOffsetEntry);
      function ^= table.At(i + Code::kSCallTableFunctionEntry);
      code ^= table.At(i + Code::kSCallTableCodeEntry);
      if (function.IsNull()) {
        Class& cls = Class::Handle();
        cls ^= code.owner();
        if (cls.IsNull()) {
          const String& code_name = String::Handle(code.Name());
          THR_Print("  0x%" Px ": %s, %p\n",
              start + offset.Value(),
              code_name.ToCString(),
              code.raw());
        } else {
          THR_Print("  0x%" Px ": allocation stub for %s, %p\n",
              start + offset.Value(),
              cls.ToCString(),
              code.raw());
        }
      } else {
        THR_Print("  0x%" Px ": %s, %p\n",
            start + offset.Value(),
            function.ToFullyQualifiedCString(),
            code.raw());
      }
    }
    THR_Print("}\n");
  }
  if (optimized && FLAG_trace_inlining_intervals) {
    code.DumpInlinedIntervals();
  }
}


#if defined(DEBUG)
// Verifies that the inliner is always in the list of inlined functions.
// If this fails run with --trace-inlining-intervals to get more information.
static void CheckInliningIntervals(const Function& function) {
  const Code& code = Code::Handle(function.CurrentCode());
  const Array& intervals = Array::Handle(code.GetInlinedIntervals());
  if (intervals.IsNull() || (intervals.Length() == 0)) return;
  Smi& start = Smi::Handle();
  GrowableArray<Function*> inlined_functions;
  for (intptr_t i = 0; i < intervals.Length(); i += Code::kInlIntNumEntries) {
    start ^= intervals.At(i + Code::kInlIntStart);
    ASSERT(!start.IsNull());
    if (start.IsNull()) continue;
    code.GetInlinedFunctionsAt(start.Value(), &inlined_functions);
    ASSERT(inlined_functions[inlined_functions.length() - 1]->raw() ==
           function.raw());
  }
}
#endif


static RawError* CompileFunctionHelper(CompilationPipeline* pipeline,
                                       const Function& function,
                                       bool optimized,
                                       intptr_t osr_id,
                                       BackgroundCompilationResult* result) {
  // Check that we optimize if 'Compiler::always_optimize()' is set to true,
  // except if the function is marked as not optimizable.
  ASSERT(!function.IsOptimizable() ||
         !Compiler::always_optimize() || optimized);
  ASSERT(Compiler::allow_recompilation() || !function.HasCode());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    Timer per_compile_timer(FLAG_trace_compiler, "Compilation time");
    per_compile_timer.Start();

    ParsedFunction* parsed_function = new(zone) ParsedFunction(
        thread, Function::ZoneHandle(zone, function.raw()));
    if (FLAG_trace_compiler) {
      THR_Print("Compiling %s%sfunction: '%s' @ token %" Pd ", size %" Pd "\n",
                (osr_id == Compiler::kNoOSRDeoptId ? "" : "osr "),
                (optimized ? "optimized " : ""),
                function.ToFullyQualifiedCString(),
                function.token_pos(),
                (function.end_token_pos() - function.token_pos()));
    }
    INC_STAT(thread, num_functions_compiled, 1);
    if (optimized) {
      INC_STAT(thread, num_functions_optimized, 1);
    }
    {
      HANDLESCOPE(thread);
      const int64_t num_tokens_before = STAT_VALUE(thread, num_tokens_consumed);
      pipeline->ParseFunction(parsed_function);
      const int64_t num_tokens_after = STAT_VALUE(thread, num_tokens_consumed);
      INC_STAT(thread,
               num_func_tokens_compiled,
               num_tokens_after - num_tokens_before);
    }

    const bool success = CompileParsedFunctionHelper(pipeline,
                                                     parsed_function,
                                                     optimized,
                                                     osr_id,
                                                     result);
    if (!success) {
      if (optimized) {
        ASSERT(!Compiler::always_optimize());  // Optimized is the only code.
        // Optimizer bailed out. Disable optimizations and never try again.
        if (FLAG_trace_compiler) {
          THR_Print("--> disabling optimizations for '%s'\n",
                    function.ToFullyQualifiedCString());
        } else if (FLAG_trace_failed_optimization_attempts) {
          THR_Print("Cannot optimize: %s\n",
                    function.ToFullyQualifiedCString());
        }
        function.SetIsOptimizable(false);
        return Error::null();
      } else {
        // Encountered error.
        Error& error = Error::Handle();
        // We got an error during compilation.
        error = isolate->object_store()->sticky_error();
        isolate->object_store()->clear_sticky_error();
        return error.raw();
      }
    }

    per_compile_timer.Stop();

    if (FLAG_trace_compiler) {
      THR_Print("--> '%s' entry: %#" Px " size: %" Pd " time: %" Pd64 " us\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).EntryPoint(),
                Code::Handle(function.CurrentCode()).Size(),
                per_compile_timer.TotalElapsedTime());
    }

    isolate->debugger()->NotifyCompilation(function);

    if (FLAG_disassemble && FlowGraphPrinter::ShouldPrint(function)) {
      DisassembleCode(function, optimized);
    } else if (FLAG_disassemble_optimized &&
               optimized &&
               FlowGraphPrinter::ShouldPrint(function)) {
      // TODO(fschneider): Print unoptimized code along with the optimized code.
      THR_Print("*** BEGIN CODE\n");
      DisassembleCode(function, true);
      THR_Print("*** END CODE\n");
    }
#if defined(DEBUG)
    CheckInliningIntervals(function);
#endif
    return Error::null();
  } else {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone stack_zone(thread);
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileFunction(Thread* thread,
                                    const Function& function) {
  Isolate* isolate = thread->isolate();
  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "Function", function);

  if (!isolate->compilation_allowed()) {
    FATAL3("Precompilation missed function %s (%" Pd ", %s)\n",
           function.ToLibNamePrefixedQualifiedCString(),
           function.token_pos(),
           Function::KindToCString(function.kind()));
  }

  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);

  const bool optimized =
      Compiler::always_optimize() && function.IsOptimizable();

  return CompileFunctionHelper(pipeline,
                               function,
                               optimized,
                               kNoOSRDeoptId,  /* not OSR */
                               NULL /* no result code */);
}


RawError* Compiler::EnsureUnoptimizedCode(Thread* thread,
                                          const Function& function) {
  if (function.unoptimized_code() != Object::null()) {
    return Error::null();
  }
  Code& original_code = Code::ZoneHandle(thread->zone());
  if (function.HasCode()) {
    original_code = function.CurrentCode();
  }
  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);
  const Error& error = Error::Handle(
      CompileFunctionHelper(pipeline,
                            function,
                            false,  /* not optimized */
                            kNoOSRDeoptId,  /* not OSR */
                            NULL  /* no result code */));
  if (!error.IsNull()) {
    return error.raw();
  }
  // Since CompileFunctionHelper replaces the current code, re-attach the
  // the original code if the function was already compiled.
  if (!original_code.IsNull() &&
      (original_code.raw() != function.CurrentCode())) {
    function.AttachCode(original_code);
  }
  ASSERT(function.unoptimized_code() != Object::null());
  if (FLAG_trace_compiler) {
    THR_Print("Ensure unoptimized code for %s\n", function.ToCString());
  }
  return Error::null();
}


RawError* Compiler::CompileOptimizedFunction(Thread* thread,
                                             const Function& function,
                                             intptr_t osr_id,
                                             BackgroundCompilationResult* res) {
  VMTagScope tagScope(thread, VMTag::kCompileOptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread,
                                         "OptimizedFunction", function);

  // Optimization must happen in non-mutator/Dart thread if background
  // compilation is on. OSR compilation still occurs in the main thread.
  ASSERT((osr_id != kNoOSRDeoptId) || !FLAG_background_compilation ||
         !thread->IsMutatorThread());
  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);
  return CompileFunctionHelper(pipeline,
                               function,
                               true,  /* optimized */
                               osr_id,
                               res);
}


// This is only used from unit tests.
RawError* Compiler::CompileParsedFunction(
    ParsedFunction* parsed_function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper(&pipeline,
                                parsed_function,
                                false,
                                kNoOSRDeoptId,
                                NULL /* no result code */);
    if (FLAG_disassemble) {
      DisassembleCode(parsed_function->function(), false);
    }
    return Error::null();
  } else {
    Isolate* const isolate = Isolate::Current();
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


void Compiler::ComputeLocalVarDescriptors(const Code& code) {
  ASSERT(!code.is_optimized());
  const Function& function = Function::Handle(code.function());
  ParsedFunction* parsed_function = new ParsedFunction(
      Thread::Current(), Function::ZoneHandle(function.raw()));
  LocalVarDescriptors& var_descs =
      LocalVarDescriptors::Handle(code.var_descriptors());
  ASSERT(var_descs.IsNull());
  // IsIrregexpFunction have eager var descriptors generation.
  ASSERT(!function.IsIrregexpFunction());
  // Parser should not produce any errors, therefore no LongJumpScope needed.
  Parser::ParseFunction(parsed_function);
  parsed_function->AllocateVariables();
  var_descs = parsed_function->node_sequence()->scope()->
      GetVarDescriptors(function);
  ASSERT(!var_descs.IsNull());
  code.set_var_descriptors(var_descs);
}


RawError* Compiler::CompileAllFunctions(const Class& cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Error& error = Error::Handle(zone);
  Array& functions = Array::Handle(zone, cls.functions());
  Function& func = Function::Handle(zone);
  // Class dynamic lives in the vm isolate. Its array fields cannot be set to
  // an empty array.
  if (functions.IsNull()) {
    ASSERT(cls.IsDynamicClass());
    return error.raw();
  }
  // Compile all the regular functions.
  for (int i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    if (!func.HasCode() &&
        !func.is_abstract() &&
        !func.IsRedirectingFactory()) {
      error = CompileFunction(thread, func);
      if (!error.IsNull()) {
        return error.raw();
      }
      func.ClearICDataArray();
      func.ClearCode();
    }
  }
  // Inner functions get added to the closures array. As part of compilation
  // more closures can be added to the end of the array. Compile all the
  // closures until we have reached the end of the "worklist".
  GrowableObjectArray& closures =
      GrowableObjectArray::Handle(zone, cls.closures());
  if (!closures.IsNull()) {
    for (int i = 0; i < closures.Length(); i++) {
      func ^= closures.At(i);
      if (!func.HasCode()) {
        error = CompileFunction(thread, func);
        if (!error.IsNull()) {
          return error.raw();
        }
        func.ClearICDataArray();
        func.ClearCode();
      }
    }
  }
  return error.raw();
}


void Compiler::CompileStaticInitializer(const Field& field) {
  ASSERT(field.is_static());
  if (field.HasPrecompiledInitializer()) {
    // TODO(rmacnak): Investigate why this happens for _enum_names.
    OS::Print("Warning: Ignoring repeated request for initializer for %s\n",
              field.ToCString());
    return;
  }
  Thread* thread = Thread::Current();
  StackZone zone(thread);

  ParsedFunction* parsed_function = Parser::ParseStaticFieldInitializer(field);

  parsed_function->AllocateVariables();
  // Non-optimized code generator.
  DartCompilationPipeline pipeline;
  CompileParsedFunctionHelper(&pipeline,
                              parsed_function,
                              false,  // optimized
                              kNoOSRDeoptId,
                              NULL /* no result code */);

  const Function& initializer = parsed_function->function();
  field.SetPrecompiledInitializer(initializer);
}


RawObject* Compiler::EvaluateStaticInitializer(const Field& field) {
  ASSERT(field.is_static());
  // The VM sets the field's value to transiton_sentinel prior to
  // evaluating the initializer value.
  ASSERT(field.StaticValue() == Object::transition_sentinel().raw());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Under precompilation, the initializer may have already been compiled, in
    // which case use it. Under lazy compilation or early in precompilation, the
    // initializer has not yet been created, so create it now, but don't bother
    // remembering it because it won't be used again.
    Function& initializer = Function::Handle();
    if (!field.HasPrecompiledInitializer()) {
      Thread* const thread = Thread::Current();
      StackZone zone(thread);
      ParsedFunction* parsed_function =
          Parser::ParseStaticFieldInitializer(field);

      parsed_function->AllocateVariables();
      // Non-optimized code generator.
      DartCompilationPipeline pipeline;
      CompileParsedFunctionHelper(&pipeline,
                                  parsed_function,
                                  false,  // optimized
                                  kNoOSRDeoptId,
                                  NULL /* no result code */);
      initializer = parsed_function->function().raw();
      Code::Handle(initializer.unoptimized_code()).set_var_descriptors(
          Object::empty_var_descriptors());
    } else {
      initializer ^= field.PrecompiledInitializer();
    }
    // Invoke the function to evaluate the expression.
    return DartEntry::InvokeFunction(initializer, Object::empty_array());
  } else {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone zone(thread);
    const Error& error =
        Error::Handle(thread->zone(), isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}



RawObject* Compiler::ExecuteOnce(SequenceNode* fragment) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    if (FLAG_trace_compiler) {
      THR_Print("compiling expression: ");
      AstPrinter::PrintNode(fragment);
    }

    // Create a dummy function object for the code generator.
    // The function needs to be associated with a named Class: the interface
    // Function fits the bill.
    const char* kEvalConst = "eval_const";
    const Function& func = Function::ZoneHandle(Function::New(
        String::Handle(Symbols::New(kEvalConst)),
        RawFunction::kRegularFunction,
        true,  // static function
        false,  // not const function
        false,  // not abstract
        false,  // not external
        false,  // not native
        Class::Handle(Type::Handle(Type::Function()).type_class()),
        fragment->token_pos()));

    func.set_result_type(Type::Handle(Type::DynamicType()));
    func.set_num_fixed_parameters(0);
    func.SetNumOptionalParameters(0, true);
    // Manually generated AST, do not recompile.
    func.SetIsOptimizable(false);
    func.set_is_debuggable(false);

    // We compile the function here, even though InvokeFunction() below
    // would compile func automatically. We are checking fewer invariants
    // here.
    ParsedFunction* parsed_function = new ParsedFunction(thread, func);
    parsed_function->SetNodeSequence(fragment);
    fragment->scope()->AddVariable(parsed_function->EnsureExpressionTemp());
    fragment->scope()->AddVariable(
        parsed_function->current_context_var());
    parsed_function->AllocateVariables();

    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper(&pipeline,
                                parsed_function,
                                false,
                                kNoOSRDeoptId,
                                NULL /* no result code */);
    Code::Handle(func.unoptimized_code()).set_var_descriptors(
        Object::empty_var_descriptors());

    const Object& result = PassiveObject::Handle(
        DartEntry::InvokeFunction(func, Object::empty_array()));
    return result.raw();
  } else {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    const Object& result =
      PassiveObject::Handle(isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}


// C-heap allocated background compilation queue element.
class QueueElement {
 public:
  explicit QueueElement(const Function& function)
      : next_(NULL),
        obj_(function.raw()),
        cha_invalidation_gen_(Isolate::kInvalidGen),
        field_invalidation_gen_(Isolate::kInvalidGen),
        prefix_invalidation_gen_(Isolate::kInvalidGen) {
    ASSERT(Thread::Current()->IsMutatorThread());
  }

  ~QueueElement() {
    ASSERT(Thread::Current()->IsMutatorThread());
    obj_ = Object::null();
  }

  void Clear() {
    next_ = NULL;
    obj_ = Object::null();
    cha_invalidation_gen_ = Isolate::kInvalidGen;
    field_invalidation_gen_ = Isolate::kInvalidGen;
    prefix_invalidation_gen_ = Isolate::kInvalidGen;
  }

  RawFunction* Function() const { return Function::RawCast(obj_); }
  RawCode* Code() const {
    return (obj_ == Object::null()) ? Code::null() : Code::RawCast(obj_);
  }

  uint32_t cha_invalidation_gen() const { return cha_invalidation_gen_; }
  uint32_t field_invalidation_gen() const { return field_invalidation_gen_; }
  uint32_t prefix_invalidation_gen() const { return prefix_invalidation_gen_; }

  void set_next(QueueElement* elem) { next_ = elem; }
  QueueElement* next() const { return next_; }

  RawObject** obj_ptr() { return &obj_; }
  RawObject* obj() const { return obj_; }

  void SetFromResult(const BackgroundCompilationResult& value) {
    ASSERT(!value.result_code().IsNull());
    obj_ = value.result_code().raw();
    cha_invalidation_gen_ = value.cha_invalidation_gen();
    field_invalidation_gen_ = value.field_invalidation_gen();
    prefix_invalidation_gen_ = value.prefix_invalidation_gen();
  }

 private:
  QueueElement* next_;

  RawObject* obj_;  // Code or Function.
  uint32_t cha_invalidation_gen_;
  uint32_t field_invalidation_gen_;
  uint32_t prefix_invalidation_gen_;

  DISALLOW_COPY_AND_ASSIGN(QueueElement);
};


// Allocated in C-heap. Handles both input and output of background compilation.
// It implements a FIFO queue, using Peek, Add, Remove operations.
class BackgroundCompilationQueue {
 public:
  BackgroundCompilationQueue() : first_(NULL), last_(NULL) {}
  ~BackgroundCompilationQueue() {
    while (!IsEmpty()) {
      QueueElement* e = Remove();
      delete e;
    }
    ASSERT((first_ == NULL) && (last_ == NULL));
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    ASSERT(visitor != NULL);
    QueueElement* p = first_;
    while (p != NULL) {
      visitor->VisitPointer(p->obj_ptr());
      p = p->next();
    }
  }

  bool IsEmpty() const { return first_ == NULL; }

  void Add(QueueElement* value) {
    ASSERT(value != NULL);
    if (first_ == NULL) {
      first_ = value;
    } else {
      last_->set_next(value);
    }
    value->set_next(NULL);
    last_ = value;
  }

  QueueElement* Peek() const {
    return first_;
  }

  RawFunction* PeekFunction() const {
    QueueElement* e = Peek();
    if (e == NULL) {
      return Function::null();
    } else {
      return e->Function();
    }
  }

  QueueElement* Remove() {
    ASSERT(first_ != NULL);
    QueueElement* result = first_;
    first_ = first_->next();
    if (first_ == NULL) {
      last_ = NULL;
    }
    return result;
  }

  bool ContainsObj(const Object& obj) const {
    QueueElement* p = first_;
    while (p != NULL) {
      if (p->obj() == obj.raw()) {
        return true;
      }
      p = p->next();
    }
    return false;
  }

 private:
  QueueElement* first_;
  QueueElement* last_;

  DISALLOW_COPY_AND_ASSIGN(BackgroundCompilationQueue);
};


BackgroundCompilationResult::BackgroundCompilationResult()
    : result_code_(Code::Handle()),
      cha_invalidation_gen_(Isolate::kInvalidGen),
      field_invalidation_gen_(Isolate::kInvalidGen),
      prefix_invalidation_gen_(Isolate::kInvalidGen) {
}


void BackgroundCompilationResult::Init() {
  Isolate* i = Isolate::Current();
  result_code_ = Code::null();
  cha_invalidation_gen_ = i->cha_invalidation_gen();
  field_invalidation_gen_ = i->field_invalidation_gen();
  prefix_invalidation_gen_ = i->prefix_invalidation_gen();
}


void BackgroundCompilationResult::SetFromQElement(QueueElement* value) {
  ASSERT(value != NULL);
  result_code_ = value->Code();
  cha_invalidation_gen_ = value->cha_invalidation_gen();
  field_invalidation_gen_ = value->field_invalidation_gen();
  prefix_invalidation_gen_ = value->prefix_invalidation_gen();
}


bool BackgroundCompilationResult::IsValid() const {
  if (result_code().IsNull() || result_code().IsDisabled()) {
    return false;
  }
  Isolate* i = Isolate::Current();
  if ((cha_invalidation_gen_ != Isolate::kInvalidGen) &&
      (cha_invalidation_gen_ != i->cha_invalidation_gen())) {
    return false;
  }
  if ((field_invalidation_gen_ != Isolate::kInvalidGen) &&
      (field_invalidation_gen_ != i->field_invalidation_gen())) {
    return false;
  }
  if ((prefix_invalidation_gen_ != Isolate::kInvalidGen) &&
      (prefix_invalidation_gen_ != i->prefix_invalidation_gen())) {
    return false;
  }
  return true;
}


void BackgroundCompilationResult::PrintValidity() const {
  Object& o = Object::Handle(result_code().owner());
  THR_Print("BackgroundCompilationResult: %s\n",
      Function::Cast(o).ToQualifiedCString());
  if (result_code().IsNull()) {
    THR_Print(" result_code is NULL\n");
    return;
  }
  if (result_code().IsDisabled()) {
    THR_Print(" result_code is disabled\n");
    return;
  }
  Isolate* i = Isolate::Current();
  THR_Print("  cha_invalidation_gen: %u (current: %u)\n",
      cha_invalidation_gen_, i->cha_invalidation_gen());
  THR_Print("  field_invalidation_gen: %u (current: %u)\n",
      field_invalidation_gen_, i->field_invalidation_gen());
  THR_Print("  prefix_invalidation_gen: %u (current: %u)\n",
      prefix_invalidation_gen_, i->prefix_invalidation_gen());
}


BackgroundCompiler::BackgroundCompiler(Isolate* isolate)
    : isolate_(isolate), running_(true), done_(new bool()),
      queue_monitor_(new Monitor()), done_monitor_(new Monitor()),
      function_queue_(new BackgroundCompilationQueue()),
      result_queue_(new BackgroundCompilationQueue()) {
  *done_ = false;
}


void BackgroundCompiler::Run() {
  while (running_) {
    // Maybe something is already in the queue, check first before waiting
    // to be notified.
    Thread::EnterIsolateAsHelper(isolate_);
    {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      HANDLESCOPE(thread);
      Function& function = Function::Handle(zone);
      function = function_queue()->PeekFunction();
      BackgroundCompilationResult result;
      while (running_ && !function.IsNull()) {
        result.Init();
        const Error& error = Error::Handle(zone,
            Compiler::CompileOptimizedFunction(thread,
                                               function,
                                               Compiler::kNoOSRDeoptId,
                                               &result));
        // TODO(srdjan): We do not expect errors while compiling optimized
        // code, any errors should have been caught when compiling
        // unoptimized code.
        // If it still happens mark function as not optimizable.
        ASSERT(error.IsNull());
        // Reuse the input QueueElement to return the result.
        QueueElement* qelem = function_queue()->Remove();
        qelem->Clear();
        result_queue()->Add(qelem);
        // Add 'qelem' to the queue first so that it gets visited by GC.
        qelem->SetFromResult(result);
        function = function_queue()->PeekFunction();
      }
    }
    Thread::ExitIsolateAsHelper();
    {
      // Wait to be notified when the work queue is not empty.
      MonitorLocker ml(queue_monitor_);
      while (function_queue()->IsEmpty() && running_) {
        ml.Wait();
      }
    }
  }  // while running

  {
    // Notify that the thread is done.
    MonitorLocker ml_done(done_monitor_);
    *done_ = true;
    ml_done.Notify();
  }
}


void BackgroundCompiler::CompileOptimized(const Function& function) {
  ASSERT(Thread::Current()->IsMutatorThread());
  MonitorLocker ml(queue_monitor_);
  if (function_queue()->ContainsObj(function)) {
    return;
  }
  QueueElement* elem = new QueueElement(function);
  function_queue()->Add(elem);
  ml.Notify();
}


void BackgroundCompiler::InstallGeneratedCode() {
  ASSERT(Thread::Current()->IsMutatorThread());
  MonitorLocker ml(queue_monitor_);
  Object& owner = Object::Handle();
  while (result_queue()->Peek() != NULL) {
    BackgroundCompilationResult result;
    QueueElement* elem = result_queue()->Remove();
    ASSERT(elem != NULL);
    result.SetFromQElement(elem);
    delete elem;

    owner = result.result_code().owner();
    const Function& function = Function::Cast(owner);
    if (result.IsValid()) {
      function.InstallOptimizedCode(result.result_code(), false /* not OSR */);
    } else if (FLAG_trace_compiler) {
      THR_Print("Drop code generated in the background compiler:\n");
      result.PrintValidity();
    }
    if (function.usage_counter() < 0) {
      // Reset to 0 so that it can be recompiled if needed.
      function.set_usage_counter(0);
    }
  }
}


void BackgroundCompiler::VisitPointers(ObjectPointerVisitor* visitor) {
  function_queue_->VisitObjectPointers(visitor);
  result_queue_->VisitObjectPointers(visitor);
}


void BackgroundCompiler::Stop(BackgroundCompiler* task) {
  ASSERT(Isolate::Current()->background_compiler() == task);
  if (task == NULL) {
    return;
  }
  BackgroundCompilationQueue* function_queue = task->function_queue();
  BackgroundCompilationQueue* result_queue = task->result_queue();

  Monitor* queue_monitor = task->queue_monitor_;
  Monitor* done_monitor = task->done_monitor_;
  bool* task_done = task->done_;
  // Wake up compiler task and stop it.
  {
    MonitorLocker ml(task->queue_monitor_);
    task->running_ = false;
    // 'task' will be deleted by thread pool.
    task = NULL;
    ml.Notify();   // Stop waiting for the queue.
  }

  {
    MonitorLocker ml_done(done_monitor);
    while (!(*task_done)) {
      ml_done.Wait();
    }
  }
  delete task_done;
  delete done_monitor;
  delete queue_monitor;
  delete function_queue;
  delete result_queue;
  Isolate::Current()->set_background_compiler(NULL);
}


void BackgroundCompiler::EnsureInit(Thread* thread) {
  bool start_task = false;
  Isolate* isolate = thread->isolate();
  {
    MutexLocker ml(isolate->mutex());
    if (isolate->background_compiler() == NULL) {
      BackgroundCompiler* task = new BackgroundCompiler(isolate);
      isolate->set_background_compiler(task);
      start_task = true;
    }
  }
  if (start_task) {
    Dart::thread_pool()->Run(isolate->background_compiler());
  }
}

}  // namespace dart
