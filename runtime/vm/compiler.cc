// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler.h"

#include "vm/assembler.h"

#include "vm/ast_printer.h"
#include "vm/code_generator.h"
#include "vm/code_patcher.h"
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
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, disassemble, false, "Disassemble dart code.");
DEFINE_FLAG(bool, disassemble_optimized, false, "Disassemble optimized code.");
DEFINE_FLAG(bool, trace_bailout, false, "Print bailout from ssa compiler.");
DEFINE_FLAG(bool, trace_compiler, false, "Trace compiler operations.");
DEFINE_FLAG(bool, constant_propagation, true,
    "Do conditional constant propagation/unreachable code elimination.");
DEFINE_FLAG(bool, common_subexpression_elimination, true,
    "Do common subexpression elimination.");
DEFINE_FLAG(bool, loop_invariant_code_motion, true,
    "Do loop invariant code motion.");
DEFINE_FLAG(bool, propagate_types, true, "Do static type propagation.");
DEFINE_FLAG(int, deoptimization_counter_threshold, 16,
    "How many times we allow deoptimization before we disallow optimization.");
DEFINE_FLAG(bool, use_inlining, true, "Enable call-site inlining");
DEFINE_FLAG(bool, range_analysis, true, "Enable range analysis");
DEFINE_FLAG(bool, verify_compiler, false,
    "Enable compiler verification assertions");
DECLARE_FLAG(bool, print_flow_graph);
DECLARE_FLAG(bool, print_flow_graph_optimized);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);

// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  ASSERT(arguments.ArgCount() == kCompileFunctionRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  ASSERT(!function.HasCode());
  const Error& error = Error::Handle(Compiler::CompileFunction(function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}


RawError* Compiler::Compile(const Library& library, const Script& script) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      const String& script_url = String::Handle(script.url());
      // TODO(iposva): Extract script kind.
      OS::Print("Compiling %s '%s'\n", "", script_url.ToCString());
    }
    const String& library_key = String::Handle(library.private_key());
    script.Tokenize(library_key);
    Parser::ParseCompilationUnit(library, script);
    isolate->set_long_jump_base(base);
    return Error::null();
  } else {
    Error& error = Error::Handle();
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    isolate->set_long_jump_base(base);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


static void InstallUnoptimizedCode(const Function& function) {
  // Disable optimized code.
  ASSERT(function.HasOptimizedCode());
  if (FLAG_trace_compiler) {
    OS::Print("--> patching entry %#"Px"\n",
              Code::Handle(function.CurrentCode()).EntryPoint());
  }
  function.SwitchToUnoptimizedCode();
  if (FLAG_trace_compiler) {
    OS::Print("--> restoring entry at %#"Px"\n",
              Code::Handle(function.unoptimized_code()).EntryPoint());
  }
}


// Return false if bailed out.
static bool CompileParsedFunctionHelper(const ParsedFunction& parsed_function,
                                        bool optimized) {
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::codegen_timer);
  bool is_compiled = false;
  Isolate* isolate = Isolate::Current();
  HANDLESCOPE(isolate);
  ASSERT(isolate->ic_data_array() == Array::null());  // Must be reset to null.
  const intptr_t prev_deopt_id = isolate->deopt_id();
  isolate->set_deopt_id(0);
  LongJump* old_base = isolate->long_jump_base();
  LongJump bailout_jump;
  isolate->set_long_jump_base(&bailout_jump);
  if (setjmp(*bailout_jump.Set()) == 0) {
    FlowGraph* flow_graph = NULL;
    // TimerScope needs an isolate to be properly terminated in case of a
    // LongJump.
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphbuilder_timer,
                       isolate);
      if (optimized) {
        ASSERT(parsed_function.function().HasCode());
        // Extract type feedback before the graph is built, as the graph
        // builder uses it to attach it to nodes.
        // Do not use type feedback to optimize a function that was
        // deoptimized too often.
        if (parsed_function.function().deoptimization_counter() <
            FLAG_deoptimization_counter_threshold) {
          const Code& unoptimized_code =
              Code::Handle(parsed_function.function().unoptimized_code());
          isolate->set_ic_data_array(
              unoptimized_code.ExtractTypeFeedbackArray());
        }
      }

      // Build the flow graph.
      FlowGraphBuilder builder(parsed_function, NULL);  // NULL = not inlining.
      flow_graph = builder.BuildGraph();
    }

    if (optimized) {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::ssa_timer,
                       isolate);
      // Transform to SSA (virtual register 0 and no inlining arguments).
      flow_graph->ComputeSSA(0, NULL);
      DEBUG_ASSERT(flow_graph->VerifyUseLists());
    }

    if (FLAG_print_flow_graph ||
        (optimized && FLAG_print_flow_graph_optimized)) {
      FlowGraphPrinter::PrintGraph("Before Optimizations", flow_graph);
    }

    // Collect all instance fields that are loaded in the graph and
    // have non-generic type feedback attached to them that can
    // potentially affect optimizations.
    GrowableArray<Field*> guarded_fields(10);
    if (optimized) {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphoptimizer_timer,
                       isolate);

      FlowGraphOptimizer optimizer(flow_graph, &guarded_fields);
      optimizer.ApplyICData();
      DEBUG_ASSERT(flow_graph->VerifyUseLists());

      // Optimize (a << b) & c patterns. Must occur before
      // 'SelectRepresentations' which inserts conversion nodes.
      // TODO(srdjan): Moved before inlining until environment use list can
      // be used to detect when shift-left is outside the scope of bit-and.
      optimizer.TryOptimizeLeftShiftWithBitAndPattern();
      DEBUG_ASSERT(flow_graph->VerifyUseLists());

      // Inlining (mutates the flow graph)
      if (FLAG_use_inlining) {
        TimerScope timer(FLAG_compiler_stats,
                         &CompilerStats::graphinliner_timer);
        FlowGraphInliner inliner(flow_graph, &guarded_fields);
        inliner.Inline();
        // Use lists are maintained and validated by the inliner.
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      // Propagate types and eliminate more type tests.
      if (FLAG_propagate_types) {
        FlowGraphTypePropagator propagator(flow_graph);
        propagator.Propagate();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      // Use propagated class-ids to optimize further.
      optimizer.ApplyClassIds();
      DEBUG_ASSERT(flow_graph->VerifyUseLists());

      // Do optimizations that depend on the propagated type information.
      optimizer.Canonicalize();
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

      // Propagate types and eliminate even more type tests.
      if (FLAG_propagate_types) {
        // Recompute types after constant propagation to infer more precise
        // types for uses that were previously reached by now eliminated phis.
        FlowGraphTypePropagator propagator(flow_graph);
        propagator.Propagate();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      // Unbox doubles. Performed after constant propagation to minimize
      // interference from phis merging double values and tagged
      // values comming from dead paths.
      optimizer.SelectRepresentations();
      DEBUG_ASSERT(flow_graph->VerifyUseLists());

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
      if (FLAG_loop_invariant_code_motion &&
          (parsed_function.function().deoptimization_counter() <
           (FLAG_deoptimization_counter_threshold - 1))) {
        LICM licm(flow_graph);
        licm.Optimize();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      if (FLAG_range_analysis) {
        // We have to perform range analysis after LICM because it
        // optimistically moves CheckSmi through phis into loop preheaders
        // making some phis smi.
        optimizer.InferSmiRanges();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      if (FLAG_constant_propagation) {
        // Constant propagation can use information from range analysis to
        // find unreachable branch targets.
        ConstantPropagator::OptimizeBranches(flow_graph);
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }

      // The final canonicalization pass before the code generation.
      if (FLAG_propagate_types) {
        // Recompute types after code movement was done to ensure correct
        // reaching types for hoisted values.
        FlowGraphTypePropagator propagator(flow_graph);
        propagator.Propagate();
        DEBUG_ASSERT(flow_graph->VerifyUseLists());
      }
      optimizer.Canonicalize();
      DEBUG_ASSERT(flow_graph->VerifyUseLists());

      // Perform register allocation on the SSA graph.
      FlowGraphAllocator allocator(*flow_graph);
      allocator.AllocateRegisters();

      if (FLAG_print_flow_graph || FLAG_print_flow_graph_optimized) {
        FlowGraphPrinter::PrintGraph("After Optimizations", flow_graph);
      }
    }

    Assembler assembler;
    FlowGraphCompiler graph_compiler(&assembler,
                                     *flow_graph,
                                     optimized);
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
      const Function& function = parsed_function.function();
      const Code& code = Code::Handle(
          Code::FinalizeCode(function, &assembler, optimized));
      code.set_is_optimized(optimized);
      graph_compiler.FinalizePcDescriptors(code);
      graph_compiler.FinalizeDeoptInfo(code);
      graph_compiler.FinalizeStackmaps(code);
      graph_compiler.FinalizeVarDescriptors(code);
      graph_compiler.FinalizeExceptionHandlers(code);
      graph_compiler.FinalizeComments(code);
      graph_compiler.FinalizeStaticCallTargetsTable(code);

      if (optimized) {
        CodePatcher::PatchEntry(Code::Handle(function.CurrentCode()));
        function.SetCode(code);
        if (FLAG_trace_compiler) {
          OS::Print("--> patching entry %#"Px"\n",
                    Code::Handle(function.unoptimized_code()).EntryPoint());
        }

        for (intptr_t i = 0; i < guarded_fields.length(); i++) {
          const Field& field = *guarded_fields[i];
          field.RegisterDependentCode(code);
        }
      } else {
        function.set_unoptimized_code(code);
        function.SetCode(code);
        ASSERT(CodePatcher::CodeIsPatchable(code));
      }
    }
    is_compiled = true;
  } else {
    // We bailed out.
    Error& bailout_error = Error::Handle(
        isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    if (FLAG_trace_bailout) {
      OS::Print("%s\n", bailout_error.ToErrorCString());
    }
    // We only bail out from generating ssa code.
    ASSERT(optimized);
    is_compiled = false;
  }
  // Reset global isolate state.
  isolate->set_ic_data_array(Array::null());
  isolate->set_long_jump_base(old_base);
  isolate->set_deopt_id(prev_deopt_id);
  return is_compiled;
}


static void DisassembleCode(const Function& function, bool optimized) {
  const char* function_fullname = function.ToFullyQualifiedCString();
  OS::Print("Code for %sfunction '%s' {\n",
            optimized ? "optimized " : "",
            function_fullname);
  const Code& code = Code::Handle(function.CurrentCode());
  const Instructions& instructions =
      Instructions::Handle(code.instructions());
  uword start = instructions.EntryPoint();
  Disassembler::Disassemble(start,
                            start + instructions.size(),
                            code.comments());
  OS::Print("}\n");

  OS::Print("Pointer offsets for function: {\n");
  // Pointer offsets are stored in descending order.
  for (intptr_t i = code.pointer_offsets_length() - 1; i >= 0; i--) {
    const uword addr = code.GetPointerOffsetAt(i) + code.EntryPoint();
    Object& obj = Object::Handle();
    obj = *reinterpret_cast<RawObject**>(addr);
    OS::Print(" %d : %#"Px" '%s'\n",
              code.GetPointerOffsetAt(i), addr, obj.ToCString());
  }
  OS::Print("}\n");

  OS::Print("PC Descriptors for function '%s' {\n", function_fullname);
  PcDescriptors::PrintHeaderString();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  OS::Print("%s}\n", descriptors.ToCString());

  const Array& deopt_table = Array::Handle(code.deopt_info_array());
  intptr_t deopt_table_length = DeoptTable::GetLength(deopt_table);
  if (deopt_table_length > 0) {
    OS::Print("DeoptInfo: {\n");
    Smi& offset = Smi::Handle();
    DeoptInfo& info = DeoptInfo::Handle();
    Smi& reason = Smi::Handle();
    for (intptr_t i = 0; i < deopt_table_length; ++i) {
      DeoptTable::GetEntry(deopt_table, i, &offset, &info, &reason);
      OS::Print("%4"Pd": 0x%"Px"  %s  (%s)\n",
                i,
                start + offset.Value(),
                info.ToCString(),
                DeoptReasonToText(reason.Value()));
    }
    OS::Print("}\n");
  }

  const Array& object_table = Array::Handle(code.object_table());
  if (object_table.Length() > 0) {
    OS::Print("Object Table: {\n");
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      OS::Print("  %"Pd": %s\n", i,
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
    if (var_info.kind == RawLocalVarDescriptors::kContextChain) {
      OS::Print("  saved CTX reg offset %"Pd"\n", var_info.index);
    } else {
      if (var_info.kind == RawLocalVarDescriptors::kContextLevel) {
        OS::Print("  context level %"Pd" scope %d",
                  var_info.index, var_info.scope_id);
      } else if (var_info.kind == RawLocalVarDescriptors::kStackVar) {
        OS::Print("  stack var '%s' offset %"Pd"",
                  var_name.ToCString(), var_info.index);
      } else {
        ASSERT(var_info.kind == RawLocalVarDescriptors::kContextVar);
        OS::Print("  context var '%s' level %d offset %"Pd"",
                  var_name.ToCString(), var_info.scope_id, var_info.index);
      }
      OS::Print(" (valid %"Pd"-%"Pd")\n",
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
      OS::Print("  0x%"Px": %s, %p\n",
          start + offset.Value(),
          function.ToFullyQualifiedCString(),
          code.raw());
    }
    OS::Print("}\n");
  }
}


static RawError* CompileFunctionHelper(const Function& function,
                                       bool optimized) {
  Isolate* isolate = Isolate::Current();
  StackZone zone(isolate);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  // Skips parsing if we need to only install unoptimized code.
  if (!optimized && !Code::Handle(function.unoptimized_code()).IsNull()) {
    InstallUnoptimizedCode(function);
    isolate->set_long_jump_base(base);
    return Error::null();
  }
  if (setjmp(*jump.Set()) == 0) {
    TIMERSCOPE(time_compilation);
    Timer per_compile_timer(FLAG_trace_compiler, "Compilation time");
    per_compile_timer.Start();
    ParsedFunction* parsed_function = new ParsedFunction(
        Function::ZoneHandle(function.raw()));
    if (FLAG_trace_compiler) {
      OS::Print("Compiling %sfunction: '%s' @ token %"Pd", size %"Pd"\n",
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
        CompileParsedFunctionHelper(*parsed_function, optimized);
    if (optimized && !success) {
      // Optimizer bailed out. Disable optimizations and to never try again.
      if (FLAG_trace_compiler) {
        OS::Print("--> disabling optimizations for '%s'\n",
                  function.ToFullyQualifiedCString());
      } else if (FLAG_trace_failed_optimization_attempts) {
        OS::Print("Cannot optimize: %s\n", function.ToFullyQualifiedCString());
      }
      function.set_is_optimizable(false);
      isolate->set_long_jump_base(base);
      return Error::null();
    }

    ASSERT(success);
    per_compile_timer.Stop();

    if (FLAG_trace_compiler) {
      OS::Print("--> '%s' entry: %#"Px" size: %"Pd" time: %"Pd64" us\n",
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

    isolate->set_long_jump_base(base);
    return Error::null();
  } else {
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    isolate->set_long_jump_base(base);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileFunction(const Function& function) {
  return CompileFunctionHelper(function, false);  // Non-optimized.
}


RawError* Compiler::CompileOptimizedFunction(const Function& function) {
  return CompileFunctionHelper(function, true);  // Optimized.
}


RawError* Compiler::CompileParsedFunction(
    const ParsedFunction& parsed_function) {
  Isolate* isolate = Isolate::Current();
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    // Non-optimized code generator.
    CompileParsedFunctionHelper(parsed_function, false);
    if (FLAG_disassemble) {
      DisassembleCode(parsed_function.function(), false);
    }
    isolate->set_long_jump_base(base);
    return Error::null();
  } else {
    Error& error = Error::Handle();
    // We got an error during compilation.
    error = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    isolate->set_long_jump_base(base);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}


RawError* Compiler::CompileAllFunctions(const Class& cls) {
  Error& error = Error::Handle();
  Array& functions = Array::Handle(cls.functions());
  Function& func = Function::Handle();
  // Class dynamic lives in the vm isolate. Its array fields cannot be set to
  // an empty array.
  if (functions.IsNull()) {
    ASSERT(cls.IsDynamicClass());
    return error.raw();
  }
  for (int i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    if (!func.HasCode() &&
        !func.is_abstract() &&
        !func.IsRedirectingFactory()) {
      error = CompileFunction(func);
      if (!error.IsNull()) {
        return error.raw();
      }
    }
  }
  return error.raw();
}


RawObject* Compiler::ExecuteOnce(SequenceNode* fragment) {
  Isolate* isolate = Isolate::Current();
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
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
        RawFunction::kConstImplicitGetter,
        true,  // static function.
        false,  // not const function.
        false,  // not abstract
        false,  // not external.
        Class::Handle(Type::Handle(Type::Function()).type_class()),
        fragment->token_pos()));

    func.set_result_type(Type::Handle(Type::DynamicType()));
    func.set_num_fixed_parameters(0);
    func.SetNumOptionalParameters(0, true);
    // Manually generated AST, do not recompile.
    func.set_is_optimizable(false);

    // We compile the function here, even though InvokeStatic() below
    // would compile func automatically. We are checking fewer invariants
    // here.
    ParsedFunction* parsed_function = new ParsedFunction(func);
    parsed_function->SetNodeSequence(fragment);
    parsed_function->set_default_parameter_values(Array::ZoneHandle());
    parsed_function->set_expression_temp_var(
        ParsedFunction::CreateExpressionTempVar(0));
    fragment->scope()->AddVariable(parsed_function->expression_temp_var());
    parsed_function->set_array_literal_var(
        ParsedFunction::CreateArrayLiteralVar(0));
    fragment->scope()->AddVariable(parsed_function->array_literal_var());
    parsed_function->AllocateVariables();

    // Non-optimized code generator.
    CompileParsedFunctionHelper(*parsed_function, false);

    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(func, Object::empty_array()));
    isolate->set_long_jump_base(base);
    return result.raw();
  } else {
    const Object& result =
      Object::Handle(isolate->object_store()->sticky_error());
    isolate->object_store()->clear_sticky_error();
    isolate->set_long_jump_base(base);
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}

}  // namespace dart
