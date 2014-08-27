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

DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, trace_patching);

// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  ASSERT(!function.HasCode());
  const Error& error = Error::Handle(Compiler::CompileFunction(isolate,
                                                               function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}


RawError* Compiler::Compile(const Library& library, const Script& script) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      const String& script_url = String::Handle(script.url());
      // TODO(iposva): Extract script kind.
      OS::Print("Compiling %s '%s'\n", "", script_url.ToCString());
    }
    const String& library_key = String::Handle(library.private_key());
    script.Tokenize(library_key);
    Parser::ParseCompilationUnit(library, script);
    return Error::null();
  } else {
    Error& error = Error::Handle();
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


static void AddRelatedClassesToList(const Class& cls,
                                    const GrowableObjectArray& parse_list,
                                    const GrowableObjectArray& patch_list) {
  Isolate* isolate = Isolate::Current();
  Class& parse_class = Class::Handle(isolate);
  AbstractType& interface_type = Type::Handle(isolate);
  Array& interfaces = Array::Handle(isolate);

  // Add all the interfaces implemented by the class that have not been
  // already parsed to the parse list. Mark the interface as parsed so that
  // we don't recursively add it back into the list.
  interfaces ^= cls.interfaces();
  for (intptr_t i = 0; i < interfaces.Length(); i++) {
    interface_type ^= interfaces.At(i);
    parse_class ^= interface_type.type_class();
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      parse_list.Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
  }

  // Walk up the super_class chain and add these classes to the list if they
  // have not been already parsed to the parse list. Mark the class as parsed
  // so that we don't recursively add it back into the list.
  parse_class ^= cls.SuperClass();
  while (!parse_class.IsNull()) {
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      parse_list.Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
    parse_class ^= parse_class.SuperClass();
  }

  // Add patch classes if they exist to the parse list if they have not already
  // been parsed and patched. Mark the class as parsed so that we don't
  // recursively add it back into the list.
  parse_class ^= cls.patch_class();
  if (!parse_class.IsNull()) {
    if (!parse_class.is_finalized() && !parse_class.is_marked_for_parsing()) {
      patch_list.Add(parse_class);
      parse_class.set_is_marked_for_parsing();
    }
  }
}


RawError* Compiler::CompileClass(const Class& cls) {
  // If class is a top level class it is already parsed.
  if (cls.IsTopLevel()) {
    return Error::null();
  }
  // If the class is already marked for parsing return immediately.
  if (cls.is_marked_for_parsing()) {
    return Error::null();
  }

  Isolate* isolate = Isolate::Current();
  // We remember all the classes that are being compiled in these lists. This
  // also allows us to reset the marked_for_parsing state in case we see an
  // error.
  VMTagScope tagScope(isolate, VMTag::kCompileTopLevelTagId);
  Class& parse_class = Class::Handle(isolate);
  const GrowableObjectArray& parse_list =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New(4));
  const GrowableObjectArray& patch_list =
      GrowableObjectArray::Handle(isolate, GrowableObjectArray::New(4));

  // Parse the class and all the interfaces it implements and super classes.
  StackZone zone(isolate);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      OS::Print("Compiling Class %s '%s'\n", "", cls.ToCString());
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
    for (intptr_t i = 0; i < parse_list.Length(); i++) {
      parse_class ^= parse_list.At(i);
      AddRelatedClassesToList(parse_class, parse_list, patch_list);
    }

    // Parse all the classes that have been added above.
    for (intptr_t i = (parse_list.Length() - 1); i >=0 ; i--) {
      parse_class ^= parse_list.At(i);
      ASSERT(!parse_class.IsNull());
      Parser::ParseClass(parse_class);
    }

    // Parse all the patch classes that have been added above.
    for (intptr_t i = 0; i < patch_list.Length(); i++) {
      parse_class ^= patch_list.At(i);
      ASSERT(!parse_class.IsNull());
      Parser::ParseClass(parse_class);
    }

    // Finalize these classes.
    for (intptr_t i = (parse_list.Length() - 1); i >=0 ; i--) {
      parse_class ^= parse_list.At(i);
      ASSERT(!parse_class.IsNull());
      ClassFinalizer::FinalizeClass(parse_class);
      parse_class.reset_is_marked_for_parsing();
    }

    return Error::null();
  } else {
    // Reset the marked for parsing flags.
    for (intptr_t i = 0; i < parse_list.Length(); i++) {
      parse_class ^= parse_list.At(i);
      if (parse_class.is_marked_for_parsing()) {
        parse_class.reset_is_marked_for_parsing();
      }
    }
    for (intptr_t i = 0; i < patch_list.Length(); i++) {
      parse_class ^= patch_list.At(i);
      if (parse_class.is_marked_for_parsing()) {
        parse_class.reset_is_marked_for_parsing();
      }
    }

    Error& error = Error::Handle(isolate);
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


// Return false if bailed out.
static bool CompileParsedFunctionHelper(ParsedFunction* parsed_function,
                                        bool optimized,
                                        intptr_t osr_id) {
  const Function& function = parsed_function->function();
  if (optimized && !function.IsOptimizable()) {
    return false;
  }
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::codegen_timer);
  bool is_compiled = false;
  Isolate* isolate = Isolate::Current();
  HANDLESCOPE(isolate);

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
    const intptr_t prev_deopt_id = isolate->deopt_id();
    isolate->set_deopt_id(0);
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      FlowGraph* flow_graph = NULL;

      // Class hierarchy analysis is registered with the isolate in the
      // constructor and unregisters itself upon destruction.
      CHA cha(isolate);

      // TimerScope needs an isolate to be properly terminated in case of a
      // LongJump.
      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphbuilder_timer,
                         isolate);
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new(isolate) ZoneGrowableArray<const ICData*>();
        if (optimized) {
          ASSERT(function.HasCode());
          // Extract type feedback before the graph is built, as the graph
          // builder uses it to attach it to nodes.
          ASSERT(function.deoptimization_counter() <
                 FLAG_deoptimization_counter_threshold);
          function.RestoreICDataMap(ic_data_array);
          if (FLAG_print_ic_data_map) {
            for (intptr_t i = 0; i < ic_data_array->length(); i++) {
              if ((*ic_data_array)[i] != NULL) {
                OS::Print("%" Pd " ", i);
                FlowGraphPrinter::PrintICData(*(*ic_data_array)[i]);
              }
            }
          }
        }

        // Build the flow graph.
        FlowGraphBuilder builder(parsed_function,
                                 *ic_data_array,
                                 NULL,  // NULL = not inlining.
                                 osr_id,
                                 optimized);
        flow_graph = builder.BuildGraph();
      }

      if (FLAG_print_flow_graph ||
          (optimized && FLAG_print_flow_graph_optimized)) {
        if (osr_id == Isolate::kNoDeoptId) {
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
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::ssa_timer,
                         isolate);
        // Transform to SSA (virtual register 0 and no inlining arguments).
        flow_graph->ComputeSSA(0, NULL);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
        if (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized) {
          FlowGraphPrinter::PrintGraph("After SSA", flow_graph);
        }
      }

      // Collect all instance fields that are loaded in the graph and
      // have non-generic type feedback attached to them that can
      // potentially affect optimizations.
      if (optimized) {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphoptimizer_timer,
                         isolate);

        FlowGraphOptimizer optimizer(flow_graph);
        optimizer.ApplyICData();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Optimize (a << b) & c patterns, merge operations.
        // Run early in order to have more opportunity to optimize left shifts.
        optimizer.TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Inlining (mutates the flow graph)
        if (FLAG_use_inlining) {
          TimerScope timer(FLAG_compiler_stats,
                           &CompilerStats::graphinliner_timer);
          // Propagate types to create more inlining opportunities.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // Use propagated class-ids to create more inlining opportunities.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          FlowGraphInliner inliner(flow_graph);
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

        if (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized) {
          FlowGraphPrinter::PrintGraph("After Optimizations", flow_graph);
        }
      }

      Assembler assembler(use_far_branches);
      FlowGraphCompiler graph_compiler(&assembler, flow_graph, optimized);
      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphcompiler_timer,
                         isolate);
        graph_compiler.CompileGraph();
      }
      {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::codefinalizer_timer,
                         isolate);
        const Code& code = Code::Handle(
            Code::FinalizeCode(function, &assembler, optimized));
        code.set_is_optimized(optimized);
        graph_compiler.FinalizePcDescriptors(code);
        graph_compiler.FinalizeDeoptInfo(code);
        graph_compiler.FinalizeStackmaps(code);
        graph_compiler.FinalizeVarDescriptors(code);
        graph_compiler.FinalizeExceptionHandlers(code);
        graph_compiler.FinalizeStaticCallTargetsTable(code);

        if (optimized) {
          if (osr_id == Isolate::kNoDeoptId) {
            CodePatcher::PatchEntry(Code::Handle(function.CurrentCode()));
            if (FLAG_trace_compiler || FLAG_trace_patching) {
              if (FLAG_trace_compiler) {
                OS::Print("  ");
              }
              OS::Print("Patch unoptimized '%s' entry point %#" Px "\n",
                  function.ToFullyQualifiedCString(),
                  Code::Handle(function.unoptimized_code()).EntryPoint());
            }
          }
          function.AttachCode(code);

          // Register code with the classes it depends on because of CHA.
          for (intptr_t i = 0;
               i < isolate->cha()->leaf_classes().length();
               ++i) {
            isolate->cha()->leaf_classes()[i]->RegisterCHACode(code);
          }

          for (intptr_t i = 0;
               i < flow_graph->guarded_fields()->length();
               i++) {
            const Field* field = (*flow_graph->guarded_fields())[i];
            field->RegisterDependentCode(code);
          }
        } else {  // not optimized.
          if (function.ic_data_array() == Array::null()) {
            function.SaveICDataMap(graph_compiler.deopt_id_to_ic_data());
          }
          function.set_unoptimized_code(code);
          function.AttachCode(code);
          ASSERT(CodePatcher::CodeIsPatchable(code));
        }
        if (parsed_function->HasDeferredPrefixes()) {
          ZoneGrowableArray<const LibraryPrefix*>* prefixes =
              parsed_function->deferred_prefixes();
          for (intptr_t i = 0; i < prefixes->length(); i++) {
            (*prefixes)[i]->RegisterDependentCode(code);
          }
        }
      }
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
          OS::Print("%s\n", error.ToErrorCString());
        }
        done = true;
        ASSERT(optimized);
      }

      // Clear the error if it was not a real error, but just a bailout.
      if (error.IsLanguageError() &&
          (LanguageError::Cast(error).kind() == Report::kBailout)) {
        isolate->object_store()->clear_sticky_error();
      }
      is_compiled = false;
    }
    // Reset global isolate state.
    isolate->set_deopt_id(prev_deopt_id);
  }
  return is_compiled;
}


static void DisassembleCode(const Function& function, bool optimized) {
  const char* function_fullname = function.ToFullyQualifiedCString();
  OS::Print("Code for %sfunction '%s' {\n",
            optimized ? "optimized " : "",
            function_fullname);
  const Code& code = Code::Handle(function.CurrentCode());
  code.Disassemble();
  OS::Print("}\n");

  OS::Print("Pointer offsets for function: {\n");
  // Pointer offsets are stored in descending order.
  Object& obj = Object::Handle();
  for (intptr_t i = code.pointer_offsets_length() - 1; i >= 0; i--) {
    const uword addr = code.GetPointerOffsetAt(i) + code.EntryPoint();
    obj = *reinterpret_cast<RawObject**>(addr);
    OS::Print(" %d : %#" Px " '%s'\n",
              code.GetPointerOffsetAt(i), addr, obj.ToCString());
  }
  OS::Print("}\n");

  OS::Print("PC Descriptors for function '%s' {\n", function_fullname);
  PcDescriptors::PrintHeaderString();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  OS::Print("%s}\n", descriptors.ToCString());

  uword start = Instructions::Handle(code.instructions()).EntryPoint();
  const Array& deopt_table = Array::Handle(code.deopt_info_array());
  intptr_t deopt_table_length = DeoptTable::GetLength(deopt_table);
  if (deopt_table_length > 0) {
    OS::Print("DeoptInfo: {\n");
    Smi& offset = Smi::Handle();
    DeoptInfo& info = DeoptInfo::Handle();
    Smi& reason = Smi::Handle();
    for (intptr_t i = 0; i < deopt_table_length; ++i) {
      DeoptTable::GetEntry(deopt_table, i, &offset, &info, &reason);
      ASSERT((0 <= reason.Value()) &&
             (reason.Value() < ICData::kDeoptNumReasons));
      OS::Print("%4" Pd ": 0x%" Px "  %s  (%s)\n",
                i,
                start + offset.Value(),
                info.ToCString(),
                DeoptReasonToCString(
                    static_cast<ICData::DeoptReasonId>(reason.Value())));
    }
    OS::Print("}\n");
  }

  const Array& object_table = Array::Handle(code.object_table());
  if (object_table.Length() > 0) {
    OS::Print("Object Table: {\n");
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      OS::Print("  %" Pd ": %s\n", i,
          Object::Handle(object_table.At(i)).ToCString());
    }
    OS::Print("}\n");
  }

  OS::Print("Stackmaps for function '%s' {\n", function_fullname);
  if (code.stackmaps() != Array::null()) {
    const Array& stackmap_table = Array::Handle(code.stackmaps());
    Stackmap& map = Stackmap::Handle();
    for (intptr_t i = 0; i < stackmap_table.Length(); ++i) {
      map ^= stackmap_table.At(i);
      OS::Print("%s\n", map.ToCString());
    }
  }
  OS::Print("}\n");

  OS::Print("Variable Descriptors for function '%s' {\n",
            function_fullname);
  const LocalVarDescriptors& var_descriptors =
      LocalVarDescriptors::Handle(code.var_descriptors());
  intptr_t var_desc_length =
      var_descriptors.IsNull() ? 0 : var_descriptors.Length();
  String& var_name = String::Handle();
  for (intptr_t i = 0; i < var_desc_length; i++) {
    var_name = var_descriptors.GetName(i);
    RawLocalVarDescriptors::VarInfo var_info;
    var_descriptors.GetInfo(i, &var_info);
    if (var_info.kind == RawLocalVarDescriptors::kSavedEntryContext) {
      OS::Print("  saved caller's CTX reg offset %" Pd "\n", var_info.index);
    } else if (var_info.kind == RawLocalVarDescriptors::kSavedCurrentContext) {
      OS::Print("  saved current CTX reg offset %" Pd "\n", var_info.index);
    } else {
      if (var_info.kind == RawLocalVarDescriptors::kContextLevel) {
        OS::Print("  context level %" Pd " scope %d",
                  var_info.index, var_info.scope_id);
      } else if (var_info.kind == RawLocalVarDescriptors::kStackVar) {
        OS::Print("  stack var '%s' offset %" Pd "",
                  var_name.ToCString(), var_info.index);
      } else {
        ASSERT(var_info.kind == RawLocalVarDescriptors::kContextVar);
        OS::Print("  context var '%s' level %d offset %" Pd "",
                  var_name.ToCString(), var_info.scope_id, var_info.index);
      }
      OS::Print(" (valid %" Pd "-%" Pd ")\n",
                var_info.begin_pos, var_info.end_pos);
    }
  }
  OS::Print("}\n");

  OS::Print("Exception Handlers for function '%s' {\n", function_fullname);
  const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(code.exception_handlers());
  OS::Print("%s}\n", handlers.ToCString());

  {
    OS::Print("Static call target functions {\n");
    const Array& table = Array::Handle(code.static_calls_target_table());
    Smi& offset = Smi::Handle();
    Function& function = Function::Handle();
    Code& code = Code::Handle();
    for (intptr_t i = 0; i < table.Length();
        i += Code::kSCallTableEntryLength) {
      offset ^= table.At(i + Code::kSCallTableOffsetEntry);
      function ^= table.At(i + Code::kSCallTableFunctionEntry);
      code ^= table.At(i + Code::kSCallTableCodeEntry);
      OS::Print("  0x%" Px ": %s, %p\n",
          start + offset.Value(),
          function.ToFullyQualifiedCString(),
          code.raw());
    }
    OS::Print("}\n");
  }
}


static RawError* CompileFunctionHelper(const Function& function,
                                       bool optimized,
                                       intptr_t osr_id) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    TIMERSCOPE(isolate, time_compilation);
    Timer per_compile_timer(FLAG_trace_compiler, "Compilation time");
    per_compile_timer.Start();
    ParsedFunction* parsed_function = new(isolate) ParsedFunction(
        isolate, Function::ZoneHandle(isolate, function.raw()));
    if (FLAG_trace_compiler) {
      OS::Print("Compiling %s%sfunction: '%s' @ token %" Pd ", size %" Pd "\n",
                (osr_id == Isolate::kNoDeoptId ? "" : "osr "),
                (optimized ? "optimized " : ""),
                function.ToFullyQualifiedCString(),
                function.token_pos(),
                (function.end_token_pos() - function.token_pos()));
    }
    {
      HANDLESCOPE(isolate);
      Parser::ParseFunction(parsed_function);
      parsed_function->AllocateVariables();
    }

    const bool success =
        CompileParsedFunctionHelper(parsed_function, optimized, osr_id);
    if (!success) {
      if (optimized) {
        // Optimizer bailed out. Disable optimizations and to never try again.
        if (FLAG_trace_compiler) {
          OS::Print("--> disabling optimizations for '%s'\n",
                    function.ToFullyQualifiedCString());
        } else if (FLAG_trace_failed_optimization_attempts) {
          OS::Print("Cannot optimize: %s\n",
                    function.ToFullyQualifiedCString());
        }
        function.SetIsOptimizable(false);
        return Error::null();
      }
      UNREACHABLE();
    }

    per_compile_timer.Stop();

    if (FLAG_trace_compiler) {
      OS::Print("--> '%s' entry: %#" Px " size: %" Pd " time: %" Pd64 " us\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).EntryPoint(),
                Code::Handle(function.CurrentCode()).Size(),
                per_compile_timer.TotalElapsedTime());
    }

    isolate->debugger()->NotifyCompilation(function);

    if (FLAG_disassemble) {
      DisassembleCode(function, optimized);
    } else if (FLAG_disassemble_optimized && optimized) {
      // TODO(fschneider): Print unoptimized code along with the optimized code.
      OS::Print("*** BEGIN CODE\n");
      DisassembleCode(function, true);
      OS::Print("*** END CODE\n");
    }

    return Error::null();
  } else {
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileFunction(Isolate* isolate,
                                    const Function& function) {
  VMTagScope tagScope(isolate, VMTag::kCompileUnoptimizedTagId);
  return CompileFunctionHelper(function, false, Isolate::kNoDeoptId);
}


RawError* Compiler::CompileOptimizedFunction(Isolate* isolate,
                                             const Function& function,
                                             intptr_t osr_id) {
  VMTagScope tagScope(isolate, VMTag::kCompileOptimizedTagId);
  return CompileFunctionHelper(function, true, osr_id);
}


// This is only used from unit tests.
RawError* Compiler::CompileParsedFunction(
    ParsedFunction* parsed_function) {
  Isolate* isolate = Isolate::Current();
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Non-optimized code generator.
    CompileParsedFunctionHelper(parsed_function, false, Isolate::kNoDeoptId);
    if (FLAG_disassemble) {
      DisassembleCode(parsed_function->function(), false);
    }
    return Error::null();
  } else {
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileAllFunctions(const Class& cls) {
  Isolate* isolate = Isolate::Current();
  Error& error = Error::Handle(isolate);
  Array& functions = Array::Handle(isolate, cls.functions());
  Function& func = Function::Handle(isolate);
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
      error = CompileFunction(isolate, func);
      if (!error.IsNull()) {
        return error.raw();
      }
      func.ClearCode();
    }
  }
  // Inner functions get added to the closures array. As part of compilation
  // more closures can be added to the end of the array. Compile all the
  // closures until we have reached the end of the "worklist".
  GrowableObjectArray& closures =
      GrowableObjectArray::Handle(isolate, cls.closures());
  if (!closures.IsNull()) {
    for (int i = 0; i < closures.Length(); i++) {
      func ^= closures.At(i);
      if (!func.HasCode()) {
        error = CompileFunction(isolate, func);
        if (!error.IsNull()) {
          return error.raw();
        }
        func.ClearCode();
      }
    }
  }
  return error.raw();
}


RawObject* Compiler::EvaluateStaticInitializer(const Field& field) {
  ASSERT(field.is_static());
  // The VM sets the field's value to transiton_sentinel prior to
  // evaluating the initializer value.
  ASSERT(field.value() == Object::transition_sentinel().raw());
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    ParsedFunction* parsed_function =
        Parser::ParseStaticFieldInitializer(field);

    parsed_function->AllocateVariables();
    // Non-optimized code generator.
    CompileParsedFunctionHelper(parsed_function, false, Isolate::kNoDeoptId);

    // Invoke the function to evaluate the expression.
    const Function& initializer = parsed_function->function();
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(initializer, Object::empty_array()));
    return result.raw();
  } else {
    const Error& error =
        Error::Handle(isolate, isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}



RawObject* Compiler::ExecuteOnce(SequenceNode* fragment) {
  Isolate* isolate = Isolate::Current();
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      OS::Print("compiling expression: ");
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

    // We compile the function here, even though InvokeFunction() below
    // would compile func automatically. We are checking fewer invariants
    // here.
    ParsedFunction* parsed_function = new ParsedFunction(isolate, func);
    parsed_function->SetNodeSequence(fragment);
    parsed_function->set_default_parameter_values(Object::null_array());
    parsed_function->EnsureExpressionTemp();
    fragment->scope()->AddVariable(parsed_function->expression_temp_var());
    parsed_function->AllocateVariables();

    // Non-optimized code generator.
    CompileParsedFunctionHelper(parsed_function, false, Isolate::kNoDeoptId);

    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(func, Object::empty_array()));
    return result.raw();
  } else {
    const Object& result =
      Object::Handle(isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}

}  // namespace dart
