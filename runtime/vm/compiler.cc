// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler.h"

#include "vm/assembler.h"

#include "vm/ast_printer.h"
#include "vm/block_scheduler.h"
#include "vm/branch_optimizer.h"
#include "vm/cha.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
#include "vm/constant_propagator.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/disassembler.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_allocator.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_inliner.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/flow_graph_type_propagator.h"
#include "vm/il_printer.h"
#include "vm/jit_optimizer.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/precompiler.h"
#include "vm/redundancy_elimination.h"
#include "vm/regexp_parser.h"
#include "vm/regexp_assembler.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, allocation_sinking, true,
    "Attempt to sink temporary allocations to side exits");
DEFINE_FLAG(bool, common_subexpression_elimination, true,
    "Do common subexpression elimination.");
DEFINE_FLAG(bool, constant_propagation, true,
    "Do conditional constant propagation/unreachable code elimination.");
DEFINE_FLAG(int, max_deoptimization_counter_threshold, 16,
    "How many times we allow deoptimization before we disallow optimization.");
DEFINE_FLAG(bool, loop_invariant_code_motion, true,
    "Do loop invariant code motion.");
DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DEFINE_FLAG(bool, print_flow_graph_optimized, false,
    "Print the IR flow graph when optimizing.");
DEFINE_FLAG(bool, print_ic_data_map, false,
    "Print the deopt-id to ICData map in optimizing compiler.");
DEFINE_FLAG(bool, print_code_source_map, false, "Print code source map.");
DEFINE_FLAG(bool, range_analysis, true, "Enable range analysis");
DEFINE_FLAG(bool, trace_compiler, false, "Trace compiler operations.");
DEFINE_FLAG(bool, trace_optimizing_compiler, false,
    "Trace only optimizing compiler operations.");
DEFINE_FLAG(bool, trace_bailout, false, "Print bailout from ssa compiler.");
DEFINE_FLAG(bool, use_inlining, true, "Enable call-site inlining");
DEFINE_FLAG(bool, verify_compiler, false,
    "Enable compiler verification assertions");

DECLARE_FLAG(bool, huge_method_cutoff_in_code_size);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, trace_irregexp);


#ifndef DART_PRECOMPILED_RUNTIME

void DartCompilationPipeline::ParseFunction(ParsedFunction* parsed_function) {
  Parser::ParseFunction(parsed_function);
  parsed_function->AllocateVariables();
}


FlowGraph* DartCompilationPipeline::BuildFlowGraph(
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


void DartCompilationPipeline::FinalizeCompilation() { }


void IrregexpCompilationPipeline::ParseFunction(
    ParsedFunction* parsed_function) {
  RegExpParser::ParseFunction(parsed_function);
  // Variables are allocated after compilation.
}


FlowGraph* IrregexpCompilationPipeline::BuildFlowGraph(
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


void IrregexpCompilationPipeline::FinalizeCompilation() {
  backtrack_goto_->ComputeOffsetTable();
}


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
    StackZone zone(thread);
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
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
  // If the class is a typedef class there is no need to try and
  // compile it. Just finalize it directly.
  if (cls.IsTypedefClass()) {
#if defined(DEBUG)
    const Class& closure_cls = Class::Handle(
        Isolate::Current()->object_store()->closure_class());
    ASSERT(closure_cls.is_finalized());
#endif
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      ClassFinalizer::FinalizeClass(cls);
      return Error::null();
    } else {
      Thread* thread = Thread::Current();
      Error& error = Error::Handle(thread->zone());
      error = thread->sticky_error();
      thread->clear_sticky_error();
      return error.raw();
    }
  }

  Thread* const thread = Thread::Current();
  StackZone zone(thread);
NOT_IN_PRODUCT(
  VMTagScope tagScope(thread, VMTag::kCompileClassTagId);
  TimelineDurationScope tds(thread,
                            thread->isolate()->GetCompilerStream(),
                            "CompileClass");
  if (tds.enabled()) {
    tds.SetNumArguments(1);
    tds.CopyArgument(0, "class", cls.ToCString());
  }
)  // !PRODUCT

  // We remember all the classes that are being compiled in these lists. This
  // also allows us to reset the marked_for_parsing state in case we see an
  // error.
  GrowableHandlePtrArray<const Class> parse_list(thread->zone(), 4);
  GrowableHandlePtrArray<const Class> patch_list(thread->zone(), 4);

  // Parse the class and all the interfaces it implements and super classes.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      THR_Print("Compiling Class '%s'\n", cls.ToCString());
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
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


class CompileParsedFunctionHelper : public ValueObject {
 public:
  CompileParsedFunctionHelper(ParsedFunction* parsed_function,
                              bool optimized,
                              intptr_t osr_id)
      : parsed_function_(parsed_function),
        optimized_(optimized),
        osr_id_(osr_id),
        thread_(Thread::Current()),
        cha_invalidation_gen_at_start_(isolate()->cha_invalidation_gen()),
        field_invalidation_gen_at_start_(isolate()->field_invalidation_gen()),
        prefix_invalidation_gen_at_start_(
            isolate()->prefix_invalidation_gen()) {
  }

  bool Compile(CompilationPipeline* pipeline);

 private:
  ParsedFunction* parsed_function() const { return parsed_function_; }
  bool optimized() const { return optimized_; }
  intptr_t osr_id() const { return osr_id_; }
  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return thread_->isolate(); }
  uint32_t cha_invalidation_gen_at_start() const {
    return cha_invalidation_gen_at_start_;
  }
  uint32_t field_invalidation_gen_at_start() const {
    return field_invalidation_gen_at_start_;
  }
  uint32_t prefix_invalidation_gen_at_start() const {
    return prefix_invalidation_gen_at_start_;
  }
  void FinalizeCompilation(Assembler* assembler,
                           FlowGraphCompiler* graph_compiler,
                           FlowGraph* flow_graph);

  ParsedFunction* parsed_function_;
  const bool optimized_;
  const intptr_t osr_id_;
  Thread* const thread_;
  const uint32_t cha_invalidation_gen_at_start_;
  const uint32_t field_invalidation_gen_at_start_;
  const uint32_t prefix_invalidation_gen_at_start_;

  DISALLOW_COPY_AND_ASSIGN(CompileParsedFunctionHelper);
};


void CompileParsedFunctionHelper::FinalizeCompilation(
    Assembler* assembler,
    FlowGraphCompiler* graph_compiler,
    FlowGraph* flow_graph) {
  ASSERT(!FLAG_precompiled_mode);
  const Function& function = parsed_function()->function();
  Zone* const zone = thread()->zone();

  CSTAT_TIMER_SCOPE(thread(), codefinalizer_timer);
  // CreateDeoptInfo uses the object pool and needs to be done before
  // FinalizeCode.
  const Array& deopt_info_array =
      Array::Handle(zone, graph_compiler->CreateDeoptInfo(assembler));
  INC_STAT(thread(), total_code_size,
           deopt_info_array.Length() * sizeof(uword));
  // Allocates instruction object. Since this occurs only at safepoint,
  // there can be no concurrent access to the instruction page.
  const Code& code = Code::Handle(
      Code::FinalizeCode(function, assembler, optimized()));
  code.set_is_optimized(optimized());
  code.set_owner(function);
  if (!function.IsOptimizable()) {
    // A function with huge unoptimized code can become non-optimizable
    // after generating unoptimized code.
    function.set_usage_counter(INT_MIN);
  }

  const Array& intervals = graph_compiler->inlined_code_intervals();
  INC_STAT(thread(), total_code_size,
           intervals.Length() * sizeof(uword));
  code.SetInlinedIntervals(intervals);

  const Array& inlined_id_array =
      Array::Handle(zone, graph_compiler->InliningIdToFunction());
  INC_STAT(thread(), total_code_size,
           inlined_id_array.Length() * sizeof(uword));
  code.SetInlinedIdToFunction(inlined_id_array);

  const Array& caller_inlining_id_map_array =
      Array::Handle(zone, graph_compiler->CallerInliningIdMap());
  INC_STAT(thread(), total_code_size,
           caller_inlining_id_map_array.Length() * sizeof(uword));
  code.SetInlinedCallerIdMap(caller_inlining_id_map_array);

  const Array& inlined_id_to_token_pos =
      Array::Handle(zone, graph_compiler->InliningIdToTokenPos());
  INC_STAT(thread(), total_code_size,
           inlined_id_to_token_pos.Length() * sizeof(uword));
  code.SetInlinedIdToTokenPos(inlined_id_to_token_pos);

  graph_compiler->FinalizePcDescriptors(code);
  code.set_deopt_info_array(deopt_info_array);

  graph_compiler->FinalizeStackmaps(code);
  graph_compiler->FinalizeVarDescriptors(code);
  graph_compiler->FinalizeExceptionHandlers(code);
  graph_compiler->FinalizeStaticCallTargetsTable(code);

NOT_IN_PRODUCT(
  // Set the code source map after setting the inlined information because
  // we use the inlined information when printing.
  const CodeSourceMap& code_source_map =
      CodeSourceMap::Handle(
          zone,
          graph_compiler->code_source_map_builder()->Finalize());
  code.set_code_source_map(code_source_map);
  if (FLAG_print_code_source_map) {
    CodeSourceMap::Dump(code_source_map, code, function);
  }
);
  if (optimized()) {
    // Installs code while at safepoint.
    if (thread()->IsMutatorThread()) {
      const bool is_osr = osr_id() != Compiler::kNoOSRDeoptId;
      function.InstallOptimizedCode(code, is_osr);
    } else {
      // Background compilation.
      // Before installing code check generation counts if the code may
      // have become invalid.
      const bool trace_compiler =
          FLAG_trace_compiler || FLAG_trace_optimizing_compiler;
      bool code_is_valid = true;
      if (!thread()->cha()->leaf_classes().is_empty()) {
        if (cha_invalidation_gen_at_start() !=
            isolate()->cha_invalidation_gen()) {
          code_is_valid = false;
          if (trace_compiler) {
            THR_Print("--> FAIL: CHA invalidation.");
          }
        }
      }
      if (!flow_graph->parsed_function().guarded_fields()->is_empty()) {
        if (field_invalidation_gen_at_start() !=
            isolate()->field_invalidation_gen()) {
          code_is_valid = false;
          if (trace_compiler) {
            THR_Print("--> FAIL: Field invalidation.");
          }
        }
      }
      if (parsed_function()->HasDeferredPrefixes()) {
        if (prefix_invalidation_gen_at_start() !=
            isolate()->prefix_invalidation_gen()) {
          code_is_valid = false;
          if (trace_compiler) {
            THR_Print("--> FAIL: Prefix invalidation.");
          }
        }
      }
      if (code_is_valid) {
        const bool is_osr = osr_id() != Compiler::kNoOSRDeoptId;
        ASSERT(!is_osr);  // OSR is compiled in background.
        function.InstallOptimizedCode(code, is_osr);
      }
      if (function.usage_counter() < 0) {
        // Reset to 0 so that it can be recompiled if needed.
        function.set_usage_counter(0);
      }
    }

    // Register code with the classes it depends on because of CHA and
    // fields it depends on because of store guards, unless we cannot
    // deopt.
    for (intptr_t i = 0;
         i < thread()->cha()->leaf_classes().length();
         ++i) {
      thread()->cha()->leaf_classes()[i]->RegisterCHACode(code);
    }
    const ZoneGrowableArray<const Field*>& guarded_fields =
        *flow_graph->parsed_function().guarded_fields();
    for (intptr_t i = 0; i < guarded_fields.length(); i++) {
      const Field* field = guarded_fields[i];
      field->RegisterDependentCode(code);
    }
  } else {  // not optimized.
    if (function.ic_data_array() == Array::null()) {
      function.SaveICDataMap(
          graph_compiler->deopt_id_to_ic_data(),
          Array::Handle(zone, graph_compiler->edge_counters_array()));
    }
    function.set_unoptimized_code(code);
    function.AttachCode(code);
  }
  if (parsed_function()->HasDeferredPrefixes()) {
    ASSERT(!FLAG_load_deferred_eagerly);
    ZoneGrowableArray<const LibraryPrefix*>* prefixes =
        parsed_function()->deferred_prefixes();
    for (intptr_t i = 0; i < prefixes->length(); i++) {
      (*prefixes)[i]->RegisterDependentCode(code);
    }
  }
}


// Return false if bailed out.
// If optimized_result_code is not NULL then it is caller's responsibility
// to install code.
bool CompileParsedFunctionHelper::Compile(CompilationPipeline* pipeline) {
  ASSERT(!FLAG_precompiled_mode);
  const Function& function = parsed_function()->function();
  if (optimized() && !function.IsOptimizable()) {
    return false;
  }
  bool is_compiled = false;
  Zone* const zone = thread()->zone();
  NOT_IN_PRODUCT(
      TimelineStream* compiler_timeline = isolate()->GetCompilerStream());
  CSTAT_TIMER_SCOPE(thread(), codegen_timer);
  HANDLESCOPE(thread());

  // We may reattempt compilation if the function needs to be assembled using
  // far branches on ARM and MIPS. In the else branch of the setjmp call,
  // done is set to false, and use_far_branches is set to true if there is a
  // longjmp from the ARM or MIPS assemblers. In all other paths through this
  // while loop, done is set to true. use_far_branches is always false on ia32
  // and x64.
  volatile bool done = false;
  // volatile because the variable may be clobbered by a longjmp.
  volatile bool use_far_branches = false;
  const bool use_speculative_inlining = false;

  while (!done) {
    const intptr_t prev_deopt_id = thread()->deopt_id();
    thread()->set_deopt_id(0);
    LongJumpScope jump;
    const intptr_t val = setjmp(*jump.Set());
    if (val == 0) {
      FlowGraph* flow_graph = NULL;

      // Class hierarchy analysis is registered with the isolate in the
      // constructor and unregisters itself upon destruction.
      CHA cha(thread());

      // TimerScope needs an isolate to be properly terminated in case of a
      // LongJump.
      {
        CSTAT_TIMER_SCOPE(thread(), graphbuilder_timer);
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new(zone) ZoneGrowableArray<const ICData*>();
        if (optimized()) {
          // Extract type feedback before the graph is built, as the graph
          // builder uses it to attach it to nodes.

          // In background compilation the deoptimization counter may have
          // already reached the limit.
          ASSERT(Compiler::IsBackgroundCompilation() ||
                 (function.deoptimization_counter() <
                     FLAG_max_deoptimization_counter_threshold));

          // 'Freeze' ICData in background compilation so that it does not
          // change while compiling.
          const bool clone_ic_data = Compiler::IsBackgroundCompilation();
          function.RestoreICDataMap(ic_data_array, clone_ic_data);

          if (Compiler::IsBackgroundCompilation() &&
              (function.ic_data_array() == Array::null())) {
            Compiler::AbortBackgroundCompilation(Thread::kNoDeoptId);
          }
          if (FLAG_print_ic_data_map) {
            for (intptr_t i = 0; i < ic_data_array->length(); i++) {
              if ((*ic_data_array)[i] != NULL) {
                THR_Print("%" Pd " ", i);
                FlowGraphPrinter::PrintICData(*(*ic_data_array)[i]);
              }
            }
          }
        }

        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(),
                                                 compiler_timeline,
                                                 "BuildFlowGraph");)
        flow_graph = pipeline->BuildFlowGraph(zone,
                                              parsed_function(),
                                              *ic_data_array,
                                              osr_id());
      }

      const bool print_flow_graph =
          (FLAG_print_flow_graph ||
           (optimized() && FLAG_print_flow_graph_optimized)) &&
          FlowGraphPrinter::ShouldPrint(function);

      if (print_flow_graph) {
        if (osr_id() == Compiler::kNoOSRDeoptId) {
          FlowGraphPrinter::PrintGraph("Before Optimizations", flow_graph);
        } else {
          FlowGraphPrinter::PrintGraph("For OSR", flow_graph);
        }
      }

      BlockScheduler block_scheduler(flow_graph);
      const bool reorder_blocks =
          FlowGraph::ShouldReorderBlocks(function, optimized());
      if (reorder_blocks) {
        NOT_IN_PRODUCT(TimelineDurationScope tds(
            thread(), compiler_timeline, "BlockScheduler::AssignEdgeWeights"));
        block_scheduler.AssignEdgeWeights();
      }

      if (optimized()) {
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(),
                                                 compiler_timeline,
                                                 "ComputeSSA"));
        CSTAT_TIMER_SCOPE(thread(), ssa_timer);
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
      // Token position where inlining occured.
      GrowableArray<TokenPosition> inline_id_to_token_pos;
      // For a given inlining-id(index) specifies the caller's inlining-id.
      GrowableArray<intptr_t> caller_inline_id;
      // Collect all instance fields that are loaded in the graph and
      // have non-generic type feedback attached to them that can
      // potentially affect optimizations.
      if (optimized()) {
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(),
                                                 compiler_timeline,
                                                 "OptimizationPasses"));
        inline_id_to_function.Add(&function);
        // We do not add the token position now because we don't know the
        // position of the inlined call until later. A side effect of this
        // is that the length of |inline_id_to_function| is always larger
        // than the length of |inline_id_to_token_pos| by one.
        // Top scope function has no caller (-1). We do this because we expect
        // all token positions to be at an inlined call.
        caller_inline_id.Add(-1);
        CSTAT_TIMER_SCOPE(thread(), graphoptimizer_timer);

        JitOptimizer optimizer(flow_graph);

        optimizer.ApplyICData();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Optimize (a << b) & c patterns, merge operations.
        // Run early in order to have more opportunity to optimize left shifts.
        optimizer.TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphInliner::SetInliningId(flow_graph, 0);

        // Inlining (mutates the flow graph)
        if (FLAG_use_inlining) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "Inlining"));
          CSTAT_TIMER_SCOPE(thread(), graphinliner_timer);
          // Propagate types to create more inlining opportunities.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // Use propagated class-ids to create more inlining opportunities.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          FlowGraphInliner inliner(flow_graph,
                                   &inline_id_to_function,
                                   &inline_id_to_token_pos,
                                   &caller_inline_id,
                                   use_speculative_inlining,
                                   NULL);
          inliner.Inline();
          // Use lists are maintained and validated by the inliner.
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types and eliminate more type tests.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "ApplyClassIds"));
          // Use propagated class-ids to optimize further.
          optimizer.ApplyClassIds();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        // Propagate types for potentially newly added instructions by
        // ApplyClassIds(). Must occur before canonicalization.
        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        // Do optimizations that depend on the propagated type information.
        if (flow_graph->Canonicalize()) {
          // Invoke Canonicalize twice in order to fully canonicalize patterns
          // like "if (a & const == 0) { }".
          flow_graph->Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "BranchSimplifier"));
          BranchSimplifier::Simplify(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          IfConverter::Simplify(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (FLAG_constant_propagation) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "ConstantPropagation");
          ConstantPropagator::Optimize(flow_graph));
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
          // A canonicalization pass to remove e.g. smi checks on smi constants.
          flow_graph->Canonicalize();
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

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "SelectRepresentations"));
          // Where beneficial convert Smi operations into Int32 operations.
          // Only meanigful for 32bit platforms right now.
          flow_graph->WidenSmiToInt32();

          // Unbox doubles. Performed after constant propagation to minimize
          // interference from phis merging double values and tagged
          // values coming from dead paths.
          flow_graph->SelectRepresentations();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(
              thread(), compiler_timeline, "CommonSubexpressionElinination"));
          if (FLAG_common_subexpression_elimination ||
              FLAG_loop_invariant_code_motion) {
            flow_graph->ComputeBlockEffects();
          }

          if (FLAG_common_subexpression_elimination) {
            if (DominatorBasedCSE::Optimize(flow_graph)) {
              DEBUG_ASSERT(flow_graph->VerifyUseLists());
              flow_graph->Canonicalize();
              // Do another round of CSE to take secondary effects into account:
              // e.g. when eliminating dependent loads (a.x[0] + a.x[0])
              // TODO(fschneider): Change to a one-pass optimization pass.
              if (DominatorBasedCSE::Optimize(flow_graph)) {
                flow_graph->Canonicalize();
              }
              DEBUG_ASSERT(flow_graph->VerifyUseLists());
            }
          }

          // Run loop-invariant code motion right after load elimination since
          // it depends on the numbering of loads from the previous
          // load-elimination.
          if (FLAG_loop_invariant_code_motion) {
            LICM licm(flow_graph);
            licm.Optimize();
            DEBUG_ASSERT(flow_graph->VerifyUseLists());
          }
          flow_graph->RemoveRedefinitions();
        }

        // Optimize (a << b) & c patterns, merge operations.
        // Run after CSE in order to have more opportunity to merge
        // instructions that have same inputs.
        optimizer.TryOptimizePatterns();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "DeadStoreElimination"));
          DeadStoreElimination::Optimize(flow_graph);
        }

        if (FLAG_range_analysis) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "RangeAnalysis"));
          // Propagate types after store-load-forwarding. Some phis may have
          // become smi phis that can be processed by range analysis.
          FlowGraphTypePropagator::Propagate(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());

          // We have to perform range analysis after LICM because it
          // optimistically moves CheckSmi through phis into loop preheaders
          // making some phis smi.
          RangeAnalysis range_analysis(flow_graph);
          range_analysis.Analyze();
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (FLAG_constant_propagation) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(
              thread(), compiler_timeline,
              "ConstantPropagator::OptimizeBranches"));
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

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(
              thread(), compiler_timeline, "TryCatchAnalyzer::Optimize"));
          // Optimize try-blocks.
          TryCatchAnalyzer::Optimize(flow_graph);
        }

        // Detach environments from the instructions that can't deoptimize.
        // Do it before we attempt to perform allocation sinking to minimize
        // amount of materializations it has to perform.
        flow_graph->EliminateEnvironments();

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "EliminateDeadPhis"));
          DeadCodeElimination::EliminateDeadPhis(flow_graph);
          DEBUG_ASSERT(flow_graph->VerifyUseLists());
        }

        if (flow_graph->Canonicalize()) {
          flow_graph->Canonicalize();
        }

        // Attempt to sink allocations of temporary non-escaping objects to
        // the deoptimization path.
        AllocationSinking* sinking = NULL;
        if (FLAG_allocation_sinking &&
            (flow_graph->graph_entry()->SuccessorCount()  == 1)) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(
              thread(), compiler_timeline, "AllocationSinking::Optimize"));
          // TODO(fschneider): Support allocation sinking with try-catch.
          sinking = new AllocationSinking(flow_graph);
          sinking->Optimize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        DeadCodeElimination::EliminateDeadPhis(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        FlowGraphTypePropagator::Propagate(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "SelectRepresentations"));
          // Ensure that all phis inserted by optimization passes have
          // consistent representations.
          flow_graph->SelectRepresentations();
        }

        if (flow_graph->Canonicalize()) {
          // To fully remove redundant boxing (e.g. BoxDouble used only in
          // environments and UnboxDouble instructions) instruction we
          // first need to replace all their uses and then fold them away.
          // For now we just repeat Canonicalize twice to do that.
          // TODO(vegorov): implement a separate representation folding pass.
          flow_graph->Canonicalize();
        }
        DEBUG_ASSERT(flow_graph->VerifyUseLists());

        if (sinking != NULL) {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(
              thread(), compiler_timeline,
              "AllocationSinking::DetachMaterializations"));
          // Remove all MaterializeObject instructions inserted by allocation
          // sinking from the flow graph and let them float on the side
          // referenced only from environments. Register allocator will consider
          // them as part of a deoptimization environment.
          sinking->DetachMaterializations();
        }

        // Compute and store graph informations (call & instruction counts)
        // to be later used by the inliner.
        FlowGraphInliner::CollectGraphInfo(flow_graph, true);

        {
          NOT_IN_PRODUCT(TimelineDurationScope tds2(thread(),
                                                    compiler_timeline,
                                                    "AllocateRegisters"));
          // Perform register allocation on the SSA graph.
          FlowGraphAllocator allocator(*flow_graph);
          allocator.AllocateRegisters();
        }

        if (reorder_blocks) {
          NOT_IN_PRODUCT(TimelineDurationScope tds(
              thread(), compiler_timeline, "BlockScheduler::ReorderBlocks"));
          block_scheduler.ReorderBlocks();
        }

        if (print_flow_graph) {
          FlowGraphPrinter::PrintGraph("After Optimizations", flow_graph);
        }
      }

      ASSERT(inline_id_to_function.length() == caller_inline_id.length());
      Assembler assembler(use_far_branches);
      FlowGraphCompiler graph_compiler(&assembler, flow_graph,
                                       *parsed_function(), optimized(),
                                       inline_id_to_function,
                                       inline_id_to_token_pos,
                                       caller_inline_id);
      {
        CSTAT_TIMER_SCOPE(thread(), graphcompiler_timer);
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(),
                                                 compiler_timeline,
                                                 "CompileGraph"));
        graph_compiler.CompileGraph();
        pipeline->FinalizeCompilation();
      }
      {
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(),
                                                 compiler_timeline,
                                                 "FinalizeCompilation"));
        if (thread()->IsMutatorThread()) {
          FinalizeCompilation(&assembler, &graph_compiler, flow_graph);
        } else {
          // This part of compilation must be at a safepoint.
          // Stop mutator thread before creating the instruction object and
          // installing code.
          // Mutator thread may not run code while we are creating the
          // instruction object, since the creation of instruction object
          // changes code page access permissions (makes them temporary not
          // executable).
          {
            SafepointOperationScope safepoint_scope(thread());
            // Do not Garbage collect during this stage and instead allow the
            // heap to grow.
            NoHeapGrowthControlScope no_growth_control;
            FinalizeCompilation(&assembler, &graph_compiler, flow_graph);
          }
          if (isolate()->heap()->NeedsGarbageCollection()) {
            isolate()->heap()->CollectAllGarbage();
          }
        }
      }
      // Mark that this isolate now has compiled code.
      isolate()->set_has_compiled_code(true);
      // Exit the loop and the function with the correct result value.
      is_compiled = true;
      done = true;
    } else {
      // We bailed out or we encountered an error.
      const Error& error = Error::Handle(thread()->sticky_error());

      if (error.raw() == Object::branch_offset_error().raw()) {
        // Compilation failed due to an out of range branch offset in the
        // assembler. We try again (done = false) with far branches enabled.
        done = false;
        ASSERT(!use_far_branches);
        use_far_branches = true;
      } else if (error.raw() == Object::speculative_inlining_error().raw()) {
        // Can only happen with precompilation.
        UNREACHABLE();
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
        thread()->clear_sticky_error();
      }
      is_compiled = false;
    }
    // Reset global isolate state.
    thread()->set_deopt_id(prev_deopt_id);
  }
  return is_compiled;
}


DEBUG_ONLY(
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
)

static RawError* CompileFunctionHelper(CompilationPipeline* pipeline,
                                       const Function& function,
                                       bool optimized,
                                       intptr_t osr_id) {
  ASSERT(!FLAG_precompiled_mode);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    const bool trace_compiler =
        FLAG_trace_compiler ||
        (FLAG_trace_optimizing_compiler && optimized);
    Timer per_compile_timer(trace_compiler, "Compilation time");
    per_compile_timer.Start();

    ParsedFunction* parsed_function = new(zone) ParsedFunction(
        thread, Function::ZoneHandle(zone, function.raw()));
    if (trace_compiler) {
      const intptr_t token_size = function.end_token_pos().Pos() -
                                  function.token_pos().Pos();
      THR_Print("Compiling %s%sfunction %s: '%s' @ token %s, size %" Pd "\n",
                (osr_id == Compiler::kNoOSRDeoptId ? "" : "osr "),
                (optimized ? "optimized " : ""),
                (Compiler::IsBackgroundCompilation() ? "(background)" : ""),
                function.ToFullyQualifiedCString(),
                function.token_pos().ToCString(),
                token_size);
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

    CompileParsedFunctionHelper helper(parsed_function, optimized, osr_id);
    const bool success = helper.Compile(pipeline);
    if (!success) {
      if (optimized) {
        // Optimizer bailed out. Disable optimizations and never try again.
        if (trace_compiler) {
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
        error = thread->sticky_error();
        thread->clear_sticky_error();
        ASSERT(error.IsLanguageError() &&
               LanguageError::Cast(error).kind() != Report::kBailout);
        return error.raw();
      }
    }

    per_compile_timer.Stop();

    if (trace_compiler && success) {
      THR_Print("--> '%s' entry: %#" Px " size: %" Pd " time: %" Pd64 " us\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).EntryPoint(),
                Code::Handle(function.CurrentCode()).Size(),
                per_compile_timer.TotalElapsedTime());
    }

    if (FLAG_support_debugger) {
      isolate->debugger()->NotifyCompilation(function);
    }

    if (FLAG_disassemble && FlowGraphPrinter::ShouldPrint(function)) {
      Disassembler::DisassembleCode(function, optimized);
    } else if (FLAG_disassemble_optimized &&
               optimized &&
               FlowGraphPrinter::ShouldPrint(function)) {
      // TODO(fschneider): Print unoptimized code along with the optimized code.
      THR_Print("*** BEGIN CODE\n");
      Disassembler::DisassembleCode(function, true);
      THR_Print("*** END CODE\n");
    }
    DEBUG_ONLY(CheckInliningIntervals(function));
    return Error::null();
  } else {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = thread->sticky_error();
    thread->clear_sticky_error();
    // Unoptimized compilation or precompilation may encounter compile-time
    // errors, but regular optimized compilation should not.
    ASSERT(!optimized);
    // Do not attempt to optimize functions that can cause errors.
    function.set_is_optimizable(false);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileFunction(Thread* thread,
                                    const Function& function) {
#ifdef DART_PRECOMPILER
  if (FLAG_precompiled_mode) {
    return Precompiler::CompileFunction(thread, function);
  }
#endif
  Isolate* isolate = thread->isolate();
  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "Function", function);

  if (!isolate->compilation_allowed()) {
    FATAL3("Precompilation missed function %s (%s, %s)\n",
           function.ToLibNamePrefixedQualifiedCString(),
           function.token_pos().ToCString(),
           Function::KindToCString(function.kind()));
  }

  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);

  return CompileFunctionHelper(pipeline,
                               function,
                               /* optimized = */ false,
                               kNoOSRDeoptId);
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
                            kNoOSRDeoptId));
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
                                             intptr_t osr_id) {
  VMTagScope tagScope(thread, VMTag::kCompileOptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread,
                                         "OptimizedFunction", function);

  // Optimization must happen in non-mutator/Dart thread if background
  // compilation is on. OSR compilation still occurs in the main thread.
  // TODO(Srdjan): Remove assert allowance for regular expression functions
  // once they can be compiled in background.
  ASSERT((osr_id != kNoOSRDeoptId) || !FLAG_background_compilation ||
         !thread->IsMutatorThread() ||
         function.IsIrregexpFunction());
  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);
  return CompileFunctionHelper(pipeline,
                               function,
                               true,  /* optimized */
                               osr_id);
}


// This is only used from unit tests.
RawError* Compiler::CompileParsedFunction(
    ParsedFunction* parsed_function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
    helper.Compile(&pipeline);
    if (FLAG_disassemble) {
      Disassembler::DisassembleCode(parsed_function->function(), false);
    }
    return Error::null();
  } else {
    Error& error = Error::Handle();
    Thread* thread = Thread::Current();
    // We got an error during compilation.
    error = thread->sticky_error();
    thread->clear_sticky_error();
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
  return error.raw();
}


RawObject* Compiler::EvaluateStaticInitializer(const Field& field) {
#ifdef DART_PRECOMPILER
  if (FLAG_precompiled_mode) {
    return Precompiler::EvaluateStaticInitializer(field);
  }
#endif
  ASSERT(field.is_static());
  // The VM sets the field's value to transiton_sentinel prior to
  // evaluating the initializer value.
  ASSERT(field.StaticValue() == Object::transition_sentinel().raw());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Under lazy compilation initializer has not yet been created, so create
    // it now, but don't bother remembering it because it won't be used again.
    ASSERT(!field.HasPrecompiledInitializer());
    Thread* const thread = Thread::Current();
    StackZone zone(thread);
    ParsedFunction* parsed_function =
        Parser::ParseStaticFieldInitializer(field);

    parsed_function->AllocateVariables();
    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
    helper.Compile(&pipeline);
    const Function& initializer =
        Function::Handle(parsed_function->function().raw());
    Code::Handle(initializer.unoptimized_code()).set_var_descriptors(
        Object::empty_var_descriptors());
    // Invoke the function to evaluate the expression.
    return DartEntry::InvokeFunction(initializer, Object::empty_array());
  } else {
    Thread* const thread = Thread::Current();
    StackZone zone(thread);
    const Error& error = Error::Handle(thread->zone(), thread->sticky_error());
    thread->clear_sticky_error();
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}



RawObject* Compiler::ExecuteOnce(SequenceNode* fragment) {
#ifdef DART_PRECOMPILER
  if (FLAG_precompiled_mode) {
    return Precompiler::ExecuteOnce(fragment);
  }
#endif
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();

    // Don't allow message interrupts while executing constant
    // expressions.  They can cause bogus recursive compilation.
    NoOOBMessageScope no_msg_scope(thread);
    if (FLAG_trace_compiler) {
      THR_Print("compiling expression: ");
      if (FLAG_support_ast_printer) {
        AstPrinter::PrintNode(fragment);
      }
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

    func.set_result_type(Object::dynamic_type());
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
    CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
    helper.Compile(&pipeline);
    Code::Handle(func.unoptimized_code()).set_var_descriptors(
        Object::empty_var_descriptors());

    const Object& result = PassiveObject::Handle(
        DartEntry::InvokeFunction(func, Object::empty_array()));
    return result.raw();
  } else {
    Thread* const thread = Thread::Current();
    const Object& result = PassiveObject::Handle(thread->sticky_error());
    thread->clear_sticky_error();
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}


void Compiler::AbortBackgroundCompilation(intptr_t deopt_id) {
  if (FLAG_trace_compiler) {
    THR_Print("ABORT background compilation.");
  }
  ASSERT(Compiler::IsBackgroundCompilation());
  Thread::Current()->long_jump_base()->Jump(
      deopt_id, Object::background_compilation_error());
}


// C-heap allocated background compilation queue element.
class QueueElement {
 public:
  explicit QueueElement(const Function& function)
      : next_(NULL),
        function_(function.raw()) {
    ASSERT(Thread::Current()->IsMutatorThread());
  }

  ~QueueElement() {
    function_ = Function::null();
  }

  RawFunction* Function() const { return function_; }


  void set_next(QueueElement* elem) { next_ = elem; }
  QueueElement* next() const { return next_; }

  RawObject* function() const { return function_; }
  RawObject** function_ptr() {
    return reinterpret_cast<RawObject**>(&function_);
  }

 private:
  QueueElement* next_;
  RawFunction* function_;

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
      visitor->VisitPointer(p->function_ptr());
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
      if (p->function() == obj.raw()) {
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


BackgroundCompiler::BackgroundCompiler(Isolate* isolate)
    : isolate_(isolate), running_(true), done_(new bool()),
      queue_monitor_(new Monitor()), done_monitor_(new Monitor()),
      function_queue_(new BackgroundCompilationQueue()) {
  *done_ = false;
}


void BackgroundCompiler::Run() {
  while (running_) {
    // Maybe something is already in the queue, check first before waiting
    // to be notified.
    bool result = Thread::EnterIsolateAsHelper(isolate_);
    ASSERT(result);
    {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      HANDLESCOPE(thread);
      Function& function = Function::Handle(zone);
      function = function_queue()->PeekFunction();
      while (running_ && !function.IsNull()) {
        const Error& error = Error::Handle(zone,
            Compiler::CompileOptimizedFunction(thread,
                                               function,
                                               Compiler::kNoOSRDeoptId));
        // TODO(srdjan): We do not expect errors while compiling optimized
        // code, any errors should have been caught when compiling
        // unoptimized code. Any issues while optimizing are flagged by
        // making the result invalid.
        ASSERT(error.IsNull());
        QueueElement* qelem = function_queue()->Remove();
        delete qelem;
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


void BackgroundCompiler::VisitPointers(ObjectPointerVisitor* visitor) {
  function_queue_->VisitObjectPointers(visitor);
}


void BackgroundCompiler::Stop(BackgroundCompiler* task) {
  ASSERT(Isolate::Current()->background_compiler() == task);
  ASSERT(task != NULL);
  BackgroundCompilationQueue* function_queue = task->function_queue();

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
      ml_done.WaitWithSafepointCheck(Thread::Current());
    }
  }
  delete task_done;
  delete done_monitor;
  delete queue_monitor;
  delete function_queue;
  Isolate::Current()->set_background_compiler(NULL);
}


void BackgroundCompiler::EnsureInit(Thread* thread) {
  ASSERT(thread->IsMutatorThread());
  // Finalize NoSuchMethodError, _Mint; occasionally needed in optimized
  // compilation.
  Class& cls = Class::Handle(thread->zone(),
      Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  Error& error = Error::Handle(thread->zone(),
      cls.EnsureIsFinalized(thread));
  ASSERT(error.IsNull());
  cls = Library::LookupCoreClass(Symbols::_Mint());
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());

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


#else  // DART_PRECOMPILED_RUNTIME


CompilationPipeline* CompilationPipeline::New(Zone* zone,
                                              const Function& function) {
  UNREACHABLE();
  return NULL;
}


DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  FATAL3("Precompilation missed function %s (%" Pd ", %s)\n",
         function.ToLibNamePrefixedQualifiedCString(),
         function.token_pos().value(),
         Function::KindToCString(function.kind()));
}


bool Compiler::IsBackgroundCompilation() {
  UNREACHABLE();
  return false;
}


RawError* Compiler::Compile(const Library& library, const Script& script) {
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileClass(const Class& cls) {
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileFunction(Thread* thread,
                                    const Function& function) {
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::EnsureUnoptimizedCode(Thread* thread,
                                          const Function& function) {
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileOptimizedFunction(Thread* thread,
                                             const Function& function,
                                             intptr_t osr_id) {
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileParsedFunction(
    ParsedFunction* parsed_function) {
  UNREACHABLE();
  return Error::null();
}


void Compiler::ComputeLocalVarDescriptors(const Code& code) {
  UNREACHABLE();
}


RawError* Compiler::CompileAllFunctions(const Class& cls) {
  UNREACHABLE();
  return Error::null();
}


RawObject* Compiler::EvaluateStaticInitializer(const Field& field) {
  ASSERT(field.HasPrecompiledInitializer());
  const Function& initializer =
      Function::Handle(field.PrecompiledInitializer());
  return DartEntry::InvokeFunction(initializer, Object::empty_array());
}


RawObject* Compiler::ExecuteOnce(SequenceNode* fragment) {
  UNREACHABLE();
  return Object::null();
}


void Compiler::AbortBackgroundCompilation(intptr_t deopt_id) {
  UNREACHABLE();
}


void BackgroundCompiler::CompileOptimized(const Function& function) {
  UNREACHABLE();
}


void BackgroundCompiler::VisitPointers(ObjectPointerVisitor* visitor) {
  UNREACHABLE();
}


void BackgroundCompiler::Stop(BackgroundCompiler* task) {
  UNREACHABLE();
}


void BackgroundCompiler::EnsureInit(Thread* thread) {
  UNREACHABLE();
}

#endif  // DART_PRECOMPILED_RUNTIME

}  // namespace dart
