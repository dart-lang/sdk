// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/jit/compiler.h"

#include "vm/compiler/assembler/assembler.h"

#include "vm/ast_printer.h"
#include "vm/code_patcher.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/block_scheduler.h"
#include "vm/compiler/backend/branch_optimizer.h"
#include "vm/compiler/backend/constant_propagator.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/cha.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/kernel.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/regexp_assembler.h"
#include "vm/regexp_parser.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(
    int,
    max_deoptimization_counter_threshold,
    16,
    "How many times we allow deoptimization before we disallow optimization.");
DEFINE_FLAG(charp, optimization_filter, NULL, "Optimize only named function");
DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DEFINE_FLAG(bool,
            print_flow_graph_optimized,
            false,
            "Print the IR flow graph when optimizing.");
DEFINE_FLAG(bool,
            print_ic_data_map,
            false,
            "Print the deopt-id to ICData map in optimizing compiler.");
DEFINE_FLAG(bool, print_code_source_map, false, "Print code source map.");
DEFINE_FLAG(bool,
            stress_test_background_compilation,
            false,
            "Keep background compiler running all the time");
DEFINE_FLAG(bool,
            stop_on_excessive_deoptimization,
            false,
            "Debugging: stops program if deoptimizing same function too often");
DEFINE_FLAG(bool, trace_compiler, false, "Trace compiler operations.");
DEFINE_FLAG(bool,
            trace_failed_optimization_attempts,
            false,
            "Traces all failed optimization attempts");
DEFINE_FLAG(bool,
            trace_optimizing_compiler,
            false,
            "Trace only optimizing compiler operations.");
DEFINE_FLAG(bool, trace_bailout, false, "Print bailout from ssa compiler.");
DEFINE_FLAG(bool,
            verify_compiler,
            false,
            "Enable compiler verification assertions");

DECLARE_FLAG(bool, huge_method_cutoff_in_code_size);
DECLARE_FLAG(bool, trace_failed_optimization_attempts);
DECLARE_FLAG(bool, unbox_numeric_fields);

static void PrecompilationModeHandler(bool value) {
  if (value) {
#if defined(TARGET_ARCH_IA32)
    FATAL("Precompilation not supported on IA32");
#endif

    FLAG_background_compilation = false;
    FLAG_collect_code = false;
    FLAG_enable_mirrors = false;
    FLAG_fields_may_be_reset = true;
    FLAG_interpret_irregexp = true;
    FLAG_lazy_dispatchers = false;
    FLAG_link_natives_lazily = true;
    FLAG_optimization_counter_threshold = -1;
    FLAG_polymorphic_with_deopt = false;
    FLAG_precompiled_mode = true;
    FLAG_reorder_basic_blocks = false;
    FLAG_use_field_guards = false;
    FLAG_use_cha_deopt = false;

#if !defined(DART_PRECOMPILED_RUNTIME)
    // Not present with DART_PRECOMPILED_RUNTIME
    FLAG_unbox_numeric_fields = false;
#endif

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    // Set flags affecting runtime accordingly for dart_bootstrap.
    // These flags are constants with PRODUCT and DART_PRECOMPILED_RUNTIME.
    FLAG_deoptimize_alot = false;  // Used in some tests.
    FLAG_deoptimize_every = 0;     // Used in some tests.
    FLAG_load_deferred_eagerly = true;
    FLAG_print_stop_message = false;
    FLAG_use_osr = false;
#endif
  }
}

DEFINE_FLAG_HANDLER(PrecompilationModeHandler,
                    precompilation,
                    "Precompilation mode");

#ifndef DART_PRECOMPILED_RUNTIME

bool UseKernelFrontEndFor(ParsedFunction* parsed_function) {
  const Function& function = parsed_function->function();
  return (function.kernel_offset() > 0) ||
         (function.kind() == RawFunction::kNoSuchMethodDispatcher) ||
         (function.kind() == RawFunction::kInvokeFieldDispatcher);
}

void DartCompilationPipeline::ParseFunction(ParsedFunction* parsed_function) {
  if (!UseKernelFrontEndFor(parsed_function)) {
    Parser::ParseFunction(parsed_function);
    parsed_function->AllocateVariables();
  }
}

FlowGraph* DartCompilationPipeline::BuildFlowGraph(
    Zone* zone,
    ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    intptr_t osr_id,
    bool optimized) {
  if (UseKernelFrontEndFor(parsed_function)) {
    kernel::FlowGraphBuilder builder(
        parsed_function->function().kernel_offset(), parsed_function,
        ic_data_array,
        /* not building var desc */ NULL,
        /* not inlining */ NULL, optimized, osr_id);
    FlowGraph* graph = builder.BuildGraph();
#if defined(DART_USE_INTERPRETER)
    ASSERT((graph != NULL) || parsed_function->function().HasBytecode());
#else
    ASSERT(graph != NULL);
#endif
    return graph;
  }
  FlowGraphBuilder builder(*parsed_function, ic_data_array,
                           /* not building var desc */ NULL,
                           /* not inlining */ NULL, osr_id);

  return builder.BuildGraph();
}

void DartCompilationPipeline::FinalizeCompilation(FlowGraph* flow_graph) {}

void IrregexpCompilationPipeline::ParseFunction(
    ParsedFunction* parsed_function) {
  VMTagScope tagScope(parsed_function->thread(),
                      VMTag::kCompileParseRegExpTagId);
  Zone* zone = parsed_function->zone();
  RegExp& regexp = RegExp::Handle(parsed_function->function().regexp());

  const String& pattern = String::Handle(regexp.pattern());
  const bool multiline = regexp.is_multi_line();

  RegExpCompileData* compile_data = new (zone) RegExpCompileData();
  if (!RegExpParser::ParseRegExp(pattern, multiline, compile_data)) {
    // Parsing failures are handled in the RegExp factory constructor.
    UNREACHABLE();
  }

  regexp.set_num_bracket_expressions(compile_data->capture_count);
  if (compile_data->simple) {
    regexp.set_is_simple();
  } else {
    regexp.set_is_complex();
  }

  parsed_function->SetRegExpCompileData(compile_data);

  // Variables are allocated after compilation.
}

FlowGraph* IrregexpCompilationPipeline::BuildFlowGraph(
    Zone* zone,
    ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    intptr_t osr_id,
    bool optimized) {
  // Compile to the dart IR.
  RegExpEngine::CompilationResult result =
      RegExpEngine::CompileIR(parsed_function->regexp_compile_data(),
                              parsed_function, ic_data_array, osr_id);
  backtrack_goto_ = result.backtrack_goto;

  // Allocate variables now that we know the number of locals.
  parsed_function->AllocateIrregexpVariables(result.num_stack_locals);

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (osr_id != Compiler::kNoOSRDeoptId) {
    result.graph_entry->RelinkToOsrEntry(zone, result.num_blocks);
  }
  PrologueInfo prologue_info(-1, -1);
  return new (zone) FlowGraph(*parsed_function, result.graph_entry,
                              result.num_blocks, prologue_info);
}

void IrregexpCompilationPipeline::FinalizeCompilation(FlowGraph* flow_graph) {
  backtrack_goto_->ComputeOffsetTable();
}

CompilationPipeline* CompilationPipeline::New(Zone* zone,
                                              const Function& function) {
  if (function.IsIrregexpFunction()) {
    return new (zone) IrregexpCompilationPipeline();
  } else {
    return new (zone) DartCompilationPipeline();
  }
}

// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  const Function& function = Function::CheckedHandle(arguments.ArgAt(0));
  ASSERT(!function.HasCode());
  const Object& result =
      Object::Handle(Compiler::CompileFunction(thread, function));
  if (result.IsError()) {
    if (result.IsLanguageError()) {
      Exceptions::ThrowCompileTimeError(LanguageError::Cast(result));
      UNREACHABLE();
    }
    Exceptions::PropagateError(Error::Cast(result));
  }
#if defined(DART_USE_INTERPRETER)
  // TODO(regis): Revisit.
  if (!function.HasCode() && function.HasBytecode()) {
    // Function was not actually compiled, but its bytecode was loaded.
    // Verify that InterpretCall stub code was installed.
    ASSERT(function.CurrentCode() == StubCode::InterpretCall_entry()->code());
  }
#endif
}

bool Compiler::CanOptimizeFunction(Thread* thread, const Function& function) {
#if !defined(PRODUCT)
  Isolate* isolate = thread->isolate();
  if (isolate->debugger()->IsStepping() ||
      isolate->debugger()->HasBreakpoint(function, thread->zone())) {
    // We cannot set breakpoints and single step in optimized code,
    // so do not optimize the function. Bump usage counter down to avoid
    // repeatedly entering the runtime for an optimization attempt.
    function.SetUsageCounter(0);
    return false;
  }
#endif
  if (function.deoptimization_counter() >=
      FLAG_max_deoptimization_counter_threshold) {
    if (FLAG_trace_failed_optimization_attempts ||
        FLAG_stop_on_excessive_deoptimization) {
      THR_Print("Too many deoptimizations: %s\n",
                function.ToFullyQualifiedCString());
      if (FLAG_stop_on_excessive_deoptimization) {
        FATAL("Stop on excessive deoptimization");
      }
    }
    // The function will not be optimized any longer. This situation can occur
    // mostly with small optimization counter thresholds.
    function.SetIsOptimizable(false);
    function.SetUsageCounter(INT_MIN);
    return false;
  }
  if (FLAG_optimization_filter != NULL) {
    // FLAG_optimization_filter is a comma-separated list of strings that are
    // matched against the fully-qualified function name.
    char* save_ptr;  // Needed for strtok_r.
    const char* function_name = function.ToFullyQualifiedCString();
    intptr_t len = strlen(FLAG_optimization_filter) + 1;  // Length with \0.
    char* filter = new char[len];
    strncpy(filter, FLAG_optimization_filter, len);  // strtok modifies arg 1.
    char* token = strtok_r(filter, ",", &save_ptr);
    bool found = false;
    while (token != NULL) {
      if (strstr(function_name, token) != NULL) {
        found = true;
        break;
      }
      token = strtok_r(NULL, ",", &save_ptr);
    }
    delete[] filter;
    if (!found) {
      function.SetUsageCounter(INT_MIN);
      return false;
    }
  }
  if (!function.IsOptimizable()) {
    // Huge methods (code size above --huge_method_cutoff_in_code_size) become
    // non-optimizable only after the code has been generated.
    if (FLAG_trace_failed_optimization_attempts) {
      THR_Print("Not optimizable: %s\n", function.ToFullyQualifiedCString());
    }
    function.SetUsageCounter(INT_MIN);
    return false;
  }
  return true;
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
    const Class& closure_cls =
        Class::Handle(Isolate::Current()->object_store()->closure_class());
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
#if !defined(PRODUCT)
  VMTagScope tagScope(thread, VMTag::kCompileClassTagId);
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                            "CompileClass");
  if (tds.enabled()) {
    tds.SetNumArguments(1);
    tds.CopyArgument(0, "class", cls.ToCString());
  }
#endif  // !defined(PRODUCT)

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

    // Classes loaded from a kernel should not be parsed.
    if (cls.kernel_offset() <= 0) {
      // Parse all the classes that have been added above.
      for (intptr_t i = (parse_list.length() - 1); i >= 0; i--) {
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
    }

    // Finalize these classes.
    for (intptr_t i = (parse_list.length() - 1); i >= 0; i--) {
      const Class& parse_class = parse_list.At(i);
      ASSERT(!parse_class.IsNull());
      ClassFinalizer::FinalizeClass(parse_class);
      parse_class.reset_is_marked_for_parsing();
    }
    for (intptr_t i = (patch_list.length() - 1); i >= 0; i--) {
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
    Thread* thread = Thread::Current();
    Error& error = Error::Handle(thread->zone());
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
        loading_invalidation_gen_at_start_(
            isolate()->loading_invalidation_gen()) {}

  RawCode* Compile(CompilationPipeline* pipeline);

 private:
  ParsedFunction* parsed_function() const { return parsed_function_; }
  bool optimized() const { return optimized_; }
  intptr_t osr_id() const { return osr_id_; }
  Thread* thread() const { return thread_; }
  Isolate* isolate() const { return thread_->isolate(); }
  intptr_t loading_invalidation_gen_at_start() const {
    return loading_invalidation_gen_at_start_;
  }
  RawCode* FinalizeCompilation(Assembler* assembler,
                               FlowGraphCompiler* graph_compiler,
                               FlowGraph* flow_graph);
  void CheckIfBackgroundCompilerIsBeingStopped();

  ParsedFunction* parsed_function_;
  const bool optimized_;
  const intptr_t osr_id_;
  Thread* const thread_;
  const intptr_t loading_invalidation_gen_at_start_;

  DISALLOW_COPY_AND_ASSIGN(CompileParsedFunctionHelper);
};

RawCode* CompileParsedFunctionHelper::FinalizeCompilation(
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
  Code& code =
      Code::Handle(Code::FinalizeCode(function, assembler, optimized()));
  code.set_is_optimized(optimized());
  code.set_owner(function);
#if !defined(PRODUCT)
  ZoneGrowableArray<TokenPosition>* await_token_positions =
      flow_graph->await_token_positions();
  if (await_token_positions != NULL) {
    Smi& token_pos_value = Smi::Handle(zone);
    if (await_token_positions->length() > 0) {
      const Array& await_to_token_map = Array::Handle(
          zone, Array::New(await_token_positions->length(), Heap::kOld));
      ASSERT(!await_to_token_map.IsNull());
      for (intptr_t i = 0; i < await_token_positions->length(); i++) {
        TokenPosition token_pos = await_token_positions->At(i).FromSynthetic();
        if (!token_pos.IsReal()) {
          // Some async machinary uses sentinel values. Map them to
          // no source position.
          token_pos_value = Smi::New(TokenPosition::kNoSourcePos);
        } else {
          token_pos_value = Smi::New(token_pos.value());
        }
        await_to_token_map.SetAt(i, token_pos_value);
      }
      code.set_await_token_positions(await_to_token_map);
    }
  }
#endif  // !defined(PRODUCT)

  if (!function.IsOptimizable()) {
    // A function with huge unoptimized code can become non-optimizable
    // after generating unoptimized code.
    function.SetUsageCounter(INT_MIN);
  }

  graph_compiler->FinalizePcDescriptors(code);
  code.set_deopt_info_array(deopt_info_array);

  graph_compiler->FinalizeStackMaps(code);
  graph_compiler->FinalizeVarDescriptors(code);
  graph_compiler->FinalizeExceptionHandlers(code);
  graph_compiler->FinalizeCatchEntryStateMap(code);
  graph_compiler->FinalizeStaticCallTargetsTable(code);
  graph_compiler->FinalizeCodeSourceMap(code);

  if (optimized()) {
    // Installs code while at safepoint.
    if (thread()->IsMutatorThread()) {
      const bool is_osr = osr_id() != Compiler::kNoOSRDeoptId;
      if (!is_osr) {
        function.InstallOptimizedCode(code);
      }
      ASSERT(code.owner() == function.raw());
    } else {
      // Background compilation.
      // Before installing code check generation counts if the code may
      // have become invalid.
      const bool trace_compiler =
          FLAG_trace_compiler || FLAG_trace_optimizing_compiler;
      bool code_is_valid = true;
      if (!flow_graph->parsed_function().guarded_fields()->is_empty()) {
        const ZoneGrowableArray<const Field*>& guarded_fields =
            *flow_graph->parsed_function().guarded_fields();
        Field& original = Field::Handle();
        for (intptr_t i = 0; i < guarded_fields.length(); i++) {
          const Field& field = *guarded_fields[i];
          ASSERT(!field.IsOriginal());
          original = field.Original();
          if (!field.IsConsistentWith(original)) {
            code_is_valid = false;
            if (trace_compiler) {
              THR_Print("--> FAIL: Field %s guarded state changed.",
                        field.ToCString());
            }
            break;
          }
        }
      }
      if (loading_invalidation_gen_at_start() !=
          isolate()->loading_invalidation_gen()) {
        code_is_valid = false;
        if (trace_compiler) {
          THR_Print("--> FAIL: Loading invalidation.");
        }
      }
      if (!thread()->cha()->IsConsistentWithCurrentHierarchy()) {
        code_is_valid = false;
        if (trace_compiler) {
          THR_Print("--> FAIL: Class hierarchy has new subclasses.");
        }
      }

      // Setting breakpoints at runtime could make a function non-optimizable.
      if (code_is_valid && Compiler::CanOptimizeFunction(thread(), function)) {
        const bool is_osr = osr_id() != Compiler::kNoOSRDeoptId;
        ASSERT(!is_osr);  // OSR is not compiled in background.
        function.InstallOptimizedCode(code);
      } else {
        code = Code::null();
      }
      if (function.usage_counter() < 0) {
        // Reset to 0 so that it can be recompiled if needed.
        if (code_is_valid) {
          function.SetUsageCounter(0);
        } else {
          // Trigger another optimization pass soon.
          function.SetUsageCounter(FLAG_optimization_counter_threshold - 100);
        }
      }
    }

    if (!code.IsNull()) {
      // The generated code was compiled under certain assumptions about
      // class hierarchy and field types. Register these dependencies
      // to ensure that the code will be deoptimized if they are violated.
      thread()->cha()->RegisterDependencies(code);

      const ZoneGrowableArray<const Field*>& guarded_fields =
          *flow_graph->parsed_function().guarded_fields();
      Field& field = Field::Handle();
      for (intptr_t i = 0; i < guarded_fields.length(); i++) {
        field = guarded_fields[i]->Original();
        field.RegisterDependentCode(code);
      }
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
  return code.raw();
}

void CompileParsedFunctionHelper::CheckIfBackgroundCompilerIsBeingStopped() {
  ASSERT(Compiler::IsBackgroundCompilation());
  if (!isolate()->background_compiler()->is_running()) {
    // The background compiler is being stopped.
    Compiler::AbortBackgroundCompilation(
        Thread::kNoDeoptId, "Background compilation is being stopped");
  }
}

// Return null if bailed out.
// If optimized_result_code is not NULL then it is caller's responsibility
// to install code.
RawCode* CompileParsedFunctionHelper::Compile(CompilationPipeline* pipeline) {
  ASSERT(!FLAG_precompiled_mode);
  const Function& function = parsed_function()->function();
  if (optimized() && !function.IsOptimizable()) {
    return Code::null();
  }
  Zone* const zone = thread()->zone();
  NOT_IN_PRODUCT(TimelineStream* compiler_timeline =
                     Timeline::GetCompilerStream());
  CSTAT_TIMER_SCOPE(thread(), codegen_timer);
  HANDLESCOPE(thread());

  // We may reattempt compilation if the function needs to be assembled using
  // far branches on ARM. In the else branch of the setjmp call, done is set to
  // false, and use_far_branches is set to true if there is a longjmp from the
  // ARM assembler. In all other paths through this while loop, done is set to
  // true. use_far_branches is always false on ia32 and x64.
  volatile bool done = false;
  // volatile because the variable may be clobbered by a longjmp.
  volatile bool use_far_branches = false;

  // In the JIT case we allow speculative inlining and have no need for a
  // blacklist, since we don't restart optimization.
  SpeculativeInliningPolicy speculative_policy(/* enable_blacklist= */ false);

  Code* volatile result = &Code::ZoneHandle(zone);
  while (!done) {
    *result = Code::null();
    const intptr_t prev_deopt_id = thread()->deopt_id();
    thread()->set_deopt_id(0);
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      FlowGraph* flow_graph = NULL;

      // Class hierarchy analysis is registered with the thread in the
      // constructor and unregisters itself upon destruction.
      CHA cha(thread());

      // TimerScope needs an isolate to be properly terminated in case of a
      // LongJump.
      {
        CSTAT_TIMER_SCOPE(thread(), graphbuilder_timer);
        ZoneGrowableArray<const ICData*>* ic_data_array =
            new (zone) ZoneGrowableArray<const ICData*>();
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
            Compiler::AbortBackgroundCompilation(
                Thread::kNoDeoptId, "RestoreICDataMap: ICData array cleared.");
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

        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(), compiler_timeline,
                                                 "BuildFlowGraph"));
        flow_graph = pipeline->BuildFlowGraph(
            zone, parsed_function(), *ic_data_array, osr_id(), optimized());
      }

#if defined(DART_USE_INTERPRETER)
      // TODO(regis): Revisit.
      if (flow_graph == NULL && function.HasBytecode()) {
        return Code::null();
      }
#endif

      const bool print_flow_graph =
          (FLAG_print_flow_graph ||
           (optimized() && FLAG_print_flow_graph_optimized)) &&
          FlowGraphPrinter::ShouldPrint(function);

      if (print_flow_graph && !optimized()) {
        FlowGraphPrinter::PrintGraph("Unoptimized Compilation", flow_graph);
      }

      BlockScheduler block_scheduler(flow_graph);
      const bool reorder_blocks =
          FlowGraph::ShouldReorderBlocks(function, optimized());
      if (reorder_blocks) {
        NOT_IN_PRODUCT(TimelineDurationScope tds(
            thread(), compiler_timeline, "BlockScheduler::AssignEdgeWeights"));
        block_scheduler.AssignEdgeWeights();
      }

      CompilerPassState pass_state(thread(), flow_graph, &speculative_policy);
      NOT_IN_PRODUCT(pass_state.compiler_timeline = compiler_timeline);
      pass_state.block_scheduler = &block_scheduler;
      pass_state.reorder_blocks = reorder_blocks;

      if (optimized()) {
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(), compiler_timeline,
                                                 "OptimizationPasses"));
        CSTAT_TIMER_SCOPE(thread(), graphoptimizer_timer);

        pass_state.inline_id_to_function.Add(&function);
        // We do not add the token position now because we don't know the
        // position of the inlined call until later. A side effect of this
        // is that the length of |inline_id_to_function| is always larger
        // than the length of |inline_id_to_token_pos| by one.
        // Top scope function has no caller (-1). We do this because we expect
        // all token positions to be at an inlined call.
        pass_state.caller_inline_id.Add(-1);

        JitCallSpecializer call_specializer(flow_graph, &speculative_policy);
        pass_state.call_specializer = &call_specializer;

        CompilerPass::RunPipeline(CompilerPass::kJIT, &pass_state);
      }

      ASSERT(pass_state.inline_id_to_function.length() ==
             pass_state.caller_inline_id.length());
      Assembler assembler(use_far_branches);
      FlowGraphCompiler graph_compiler(
          &assembler, flow_graph, *parsed_function(), optimized(),
          &speculative_policy, pass_state.inline_id_to_function,
          pass_state.inline_id_to_token_pos, pass_state.caller_inline_id);
      {
        CSTAT_TIMER_SCOPE(thread(), graphcompiler_timer);
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(), compiler_timeline,
                                                 "CompileGraph"));
        graph_compiler.CompileGraph();
        pipeline->FinalizeCompilation(flow_graph);
      }
      {
        NOT_IN_PRODUCT(TimelineDurationScope tds(thread(), compiler_timeline,
                                                 "FinalizeCompilation"));
        if (thread()->IsMutatorThread()) {
          *result =
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
            CheckIfBackgroundCompilerIsBeingStopped();
            SafepointOperationScope safepoint_scope(thread());
            // Do not Garbage collect during this stage and instead allow the
            // heap to grow.
            NoHeapGrowthControlScope no_growth_control;
            CheckIfBackgroundCompilerIsBeingStopped();
            *result =
                FinalizeCompilation(&assembler, &graph_compiler, flow_graph);
          }
        }
      }
      // Exit the loop and the function with the correct result value.
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
        // try again (done = true).
        if (FLAG_trace_bailout) {
          THR_Print("%s\n", error.ToErrorCString());
        }
        done = true;
      }

      // If is is not a background compilation, clear the error if it was not a
      // real error, but just a bailout. If we're it a background compilation
      // this will be dealt with in the caller.
      if (!Compiler::IsBackgroundCompilation() && error.IsLanguageError() &&
          (LanguageError::Cast(error).kind() == Report::kBailout)) {
        thread()->clear_sticky_error();
      }
    }
    // Reset global isolate state.
    thread()->set_deopt_id(prev_deopt_id);
  }
  return result->raw();
}

static RawObject* CompileFunctionHelper(CompilationPipeline* pipeline,
                                        const Function& function,
                                        bool optimized,
                                        intptr_t osr_id) {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(!optimized || function.WasCompiled());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    Isolate* const isolate = thread->isolate();
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    const bool trace_compiler =
        FLAG_trace_compiler || (FLAG_trace_optimizing_compiler && optimized);
    Timer per_compile_timer(trace_compiler, "Compilation time");
    per_compile_timer.Start();

    ParsedFunction* parsed_function = new (zone)
        ParsedFunction(thread, Function::ZoneHandle(zone, function.raw()));
    if (trace_compiler) {
      const intptr_t token_size =
          function.end_token_pos().Pos() - function.token_pos().Pos();
      THR_Print("Compiling %s%sfunction %s: '%s' @ token %s, size %" Pd "\n",
                (osr_id == Compiler::kNoOSRDeoptId ? "" : "osr "),
                (optimized ? "optimized " : ""),
                (Compiler::IsBackgroundCompilation() ? "(background)" : ""),
                function.ToFullyQualifiedCString(),
                function.token_pos().ToCString(), token_size);
    }
    INC_STAT(thread, num_functions_compiled, 1);
    if (optimized) {
      INC_STAT(thread, num_functions_optimized, 1);
    }
    // Makes sure no classes are loaded during parsing in background.
    const intptr_t loading_invalidation_gen_at_start =
        isolate->loading_invalidation_gen();
    {
      HANDLESCOPE(thread);
      const int64_t num_tokens_before = STAT_VALUE(thread, num_tokens_consumed);
      pipeline->ParseFunction(parsed_function);
      const int64_t num_tokens_after = STAT_VALUE(thread, num_tokens_consumed);
      INC_STAT(thread, num_func_tokens_compiled,
               num_tokens_after - num_tokens_before);
    }

    CompileParsedFunctionHelper helper(parsed_function, optimized, osr_id);

    if (Compiler::IsBackgroundCompilation()) {
      if (isolate->IsTopLevelParsing() ||
          (loading_invalidation_gen_at_start !=
           isolate->loading_invalidation_gen())) {
        // Loading occured while parsing. We need to abort here because state
        // changed while compiling.
        Compiler::AbortBackgroundCompilation(
            Thread::kNoDeoptId,
            "Invalidated state during parsing because of script loading");
      }
    }

    const Code& result = Code::Handle(helper.Compile(pipeline));

#if defined(DART_USE_INTERPRETER)
    // TODO(regis): Revisit.
    if (result.IsNull() && function.HasBytecode()) {
      return Object::null();
    }
#endif

    if (!result.IsNull()) {
      if (!optimized) {
        function.SetWasCompiled(true);
      }
    } else {
      if (optimized) {
        if (Compiler::IsBackgroundCompilation()) {
          // Try again later, background compilation may abort because of
          // state change during compilation.
          if (FLAG_trace_compiler) {
            THR_Print("Aborted background compilation: %s\n",
                      function.ToFullyQualifiedCString());
          }
          {
            // If it was a bailout, then disable optimization.
            Error& error = Error::Handle();
            // We got an error during compilation.
            error = thread->sticky_error();
            thread->clear_sticky_error();

            if (error.raw() == Object::background_compilation_error().raw()) {
              if (FLAG_trace_compiler) {
                THR_Print(
                    "--> disabling background optimizations for '%s' (will "
                    "try to re-compile on isolate thread again)\n",
                    function.ToFullyQualifiedCString());
              }

              // Ensure we don't attempt to re-compile the function on the
              // background compiler.
              function.set_is_background_optimizable(false);

              // Trigger another optimization soon on the main thread.
              function.SetUsageCounter(FLAG_optimization_counter_threshold);
            } else if ((error.IsLanguageError() &&
                        LanguageError::Cast(error).kind() ==
                            Report::kBailout) ||
                       error.IsUnhandledException()) {
              if (FLAG_trace_compiler) {
                THR_Print("--> disabling optimizations for '%s'\n",
                          function.ToFullyQualifiedCString());
              }
              function.SetIsOptimizable(false);
            }
          }
          return Error::null();
        }
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
        ASSERT(!optimized);
        // Encountered error.
        Error& error = Error::Handle();
        // We got an error during compilation.
        error = thread->sticky_error();
        thread->clear_sticky_error();
        // The non-optimizing compiler can get an unhandled exception
        // due to OOM or Stack overflow errors, it should not however
        // bail out.
        ASSERT(error.IsUnhandledException() ||
               (error.IsLanguageError() &&
                LanguageError::Cast(error).kind() != Report::kBailout));
        return error.raw();
      }
      UNREACHABLE();
    }

    per_compile_timer.Stop();

    if (trace_compiler) {
      THR_Print("--> '%s' entry: %#" Px " size: %" Pd " time: %" Pd64 " us\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).PayloadStart(),
                Code::Handle(function.CurrentCode()).Size(),
                per_compile_timer.TotalElapsedTime());
    }

#if !defined(PRODUCT)
    isolate->debugger()->NotifyCompilation(function);
#endif

    if (FLAG_disassemble && FlowGraphPrinter::ShouldPrint(function)) {
      Disassembler::DisassembleCode(function, result, optimized);
    } else if (FLAG_disassemble_optimized && optimized &&
               FlowGraphPrinter::ShouldPrint(function)) {
      Disassembler::DisassembleCode(function, result, true);
    }

    return result.raw();
  } else {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    Error& error = Error::Handle();
    // We got an error during compilation or it is a bailout from background
    // compilation (e.g., during parsing with EnsureIsFinalized).
    error = thread->sticky_error();
    thread->clear_sticky_error();
    if (error.raw() == Object::background_compilation_error().raw()) {
      // Exit compilation, retry it later.
      if (FLAG_trace_bailout) {
        THR_Print("Aborted background compilation: %s\n",
                  function.ToFullyQualifiedCString());
      }
      return Object::null();
    }
    // Do not attempt to optimize functions that can cause errors.
    function.set_is_optimizable(false);
    return error.raw();
  }
  UNREACHABLE();
  return Object::null();
}

static RawError* ParseFunctionHelper(CompilationPipeline* pipeline,
                                     const Function& function,
                                     bool optimized,
                                     intptr_t osr_id) {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(!optimized || function.WasCompiled());
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* const zone = stack_zone.GetZone();
    const bool trace_compiler =
        FLAG_trace_compiler || (FLAG_trace_optimizing_compiler && optimized);

    if (trace_compiler) {
      const intptr_t token_size =
          function.end_token_pos().Pos() - function.token_pos().Pos();
      THR_Print("Parsing %s%sfunction %s: '%s' @ token %s, size %" Pd "\n",
                (osr_id == Compiler::kNoOSRDeoptId ? "" : "osr "),
                (optimized ? "optimized " : ""),
                (Compiler::IsBackgroundCompilation() ? "(background)" : ""),
                function.ToFullyQualifiedCString(),
                function.token_pos().ToCString(), token_size);
    }
    ParsedFunction* parsed_function = new (zone)
        ParsedFunction(thread, Function::ZoneHandle(zone, function.raw()));
    pipeline->ParseFunction(parsed_function);
// For now we just walk thru the AST nodes and in DEBUG mode we print
// them otherwise just skip through them, this will be need to be
// wired to generate the IR format.
#if !defined(PRODUCT)
#if defined(DEBUG)
    AstPrinter ast_printer(true);
#else
    AstPrinter ast_printer(false);
#endif  // defined(DEBUG).
    ast_printer.PrintFunctionNodes(*parsed_function);
#endif  // !defined(PRODUCT).
    return Error::null();
  } else {
    Thread* const thread = Thread::Current();
    StackZone stack_zone(thread);
    Error& error = Error::Handle();
    // We got an error during compilation or it is a bailout from background
    // compilation (e.g., during parsing with EnsureIsFinalized).
    error = thread->sticky_error();
    thread->clear_sticky_error();
    // Unoptimized compilation or precompilation may encounter compile-time
    // errors, but regular optimized compilation should not.
    ASSERT(!optimized);
    return error.raw();
  }
  UNREACHABLE();
  return Error::null();
}

RawObject* Compiler::CompileFunction(Thread* thread, const Function& function) {
#ifdef DART_PRECOMPILER
  if (FLAG_precompiled_mode) {
    return Precompiler::CompileFunction(
        /* precompiler = */ NULL, thread, thread->zone(), function);
  }
#endif

  Isolate* isolate = thread->isolate();

#if !defined(PRODUCT)
  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "CompileFunction", function);
#endif  // !defined(PRODUCT)

  if (!isolate->compilation_allowed()) {
    FATAL3("Precompilation missed function %s (%s, %s)\n",
           function.ToLibNamePrefixedQualifiedCString(),
           function.token_pos().ToCString(),
           Function::KindToCString(function.kind()));
  }

  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);

  return CompileFunctionHelper(pipeline, function,
                               /* optimized = */ false, kNoOSRDeoptId);
}

RawError* Compiler::ParseFunction(Thread* thread, const Function& function) {
  Isolate* isolate = thread->isolate();
#if !defined(PRODUCT)
  VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, "ParseFunction", function);
#endif  // !defined(PRODUCT)

  if (!isolate->compilation_allowed()) {
    FATAL3("Precompilation missed function %s (%s, %s)\n",
           function.ToLibNamePrefixedQualifiedCString(),
           function.token_pos().ToCString(),
           Function::KindToCString(function.kind()));
  }

  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);

  return ParseFunctionHelper(pipeline, function,
                             /* optimized = */ false, kNoOSRDeoptId);
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
  const Object& result = Object::Handle(
      CompileFunctionHelper(pipeline, function, false, /* not optimized */
                            kNoOSRDeoptId));
  if (result.IsError()) {
    return Error::Cast(result).raw();
  }
  // Since CompileFunctionHelper replaces the current code, re-attach the
  // the original code if the function was already compiled.
  if (!original_code.IsNull() && result.raw() == function.CurrentCode() &&
      !original_code.IsDisabled()) {
    function.AttachCode(original_code);
  }
  ASSERT(function.unoptimized_code() != Object::null());
  ASSERT(function.unoptimized_code() == result.raw());
  if (FLAG_trace_compiler) {
    THR_Print("Ensure unoptimized code for %s\n", function.ToCString());
  }
  return Error::null();
}

RawObject* Compiler::CompileOptimizedFunction(Thread* thread,
                                              const Function& function,
                                              intptr_t osr_id) {
#if !defined(PRODUCT)
  VMTagScope tagScope(thread, VMTag::kCompileOptimizedTagId);
  const char* event_name;
  if (osr_id != kNoOSRDeoptId) {
    event_name = "CompileFunctionOptimizedOSR";
  } else if (IsBackgroundCompilation()) {
    event_name = "CompileFunctionOptimizedBackground";
  } else {
    event_name = "CompileFunctionOptimized";
  }
  TIMELINE_FUNCTION_COMPILATION_DURATION(thread, event_name, function);
#endif  // !defined(PRODUCT)

  // If we are in the optimizing in the mutator/Dart thread, then
  // this is either an OSR compilation or background compilation is
  // not currently allowed.
  ASSERT(!thread->IsMutatorThread() || (osr_id != kNoOSRDeoptId) ||
         !FLAG_background_compilation ||
         BackgroundCompiler::IsDisabled(Isolate::Current()) ||
         !function.is_background_optimizable());
  CompilationPipeline* pipeline =
      CompilationPipeline::New(thread->zone(), function);
  return CompileFunctionHelper(pipeline, function, true, /* optimized */
                               osr_id);
}

// This is only used from unit tests.
RawError* Compiler::CompileParsedFunction(ParsedFunction* parsed_function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
    helper.Compile(&pipeline);
    if (FLAG_disassemble) {
      Code& code = Code::Handle(parsed_function->function().CurrentCode());
      Disassembler::DisassembleCode(parsed_function->function(), code, false);
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
  ASSERT(code.var_descriptors() == Object::null());
  // IsIrregexpFunction have eager var descriptors generation.
  ASSERT(!function.IsIrregexpFunction());
  // In background compilation, parser can produce 'errors": bailouts
  // if state changed while compiling in background.
  const intptr_t prev_deopt_id = Thread::Current()->deopt_id();
  Thread::Current()->set_deopt_id(0);
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    ZoneGrowableArray<const ICData*>* ic_data_array =
        new ZoneGrowableArray<const ICData*>();
    ZoneGrowableArray<intptr_t>* context_level_array =
        new ZoneGrowableArray<intptr_t>();

    if (!UseKernelFrontEndFor(parsed_function)) {
      Parser::ParseFunction(parsed_function);
      parsed_function->AllocateVariables();
      FlowGraphBuilder builder(
          *parsed_function, *ic_data_array, context_level_array,
          /* not inlining */ NULL, Compiler::kNoOSRDeoptId);
      builder.BuildGraph();
    } else {
      parsed_function->EnsureKernelScopes();
      kernel::FlowGraphBuilder builder(
          parsed_function->function().kernel_offset(), parsed_function,
          *ic_data_array, context_level_array,
          /* not inlining */ NULL, false, Compiler::kNoOSRDeoptId);
      builder.BuildGraph();
    }

    const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
        parsed_function->node_sequence()->scope()->GetVarDescriptors(
            function, context_level_array));
    ASSERT(!var_descs.IsNull());
    code.set_var_descriptors(var_descs);
  } else {
    // Only possible with background compilation.
    ASSERT(Compiler::IsBackgroundCompilation());
  }
  Thread::Current()->set_deopt_id(prev_deopt_id);
}

RawError* Compiler::CompileAllFunctions(const Class& cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Object& result = Object::Handle(zone);
  Array& functions = Array::Handle(zone, cls.functions());
  Function& func = Function::Handle(zone);
  // Class dynamic lives in the vm isolate. Its array fields cannot be set to
  // an empty array.
  if (functions.IsNull()) {
    ASSERT(cls.IsDynamicClass());
    return Error::null();
  }
  // Compile all the regular functions.
  for (int i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    if (!func.HasCode() && !func.is_abstract() &&
        !func.IsRedirectingFactory()) {
      if ((cls.is_mixin_app_alias() || cls.IsMixinApplication()) &&
          func.HasOptionalParameters()) {
        // Skipping optional parameters in mixin application.
        continue;
      }
      result = CompileFunction(thread, func);
      if (result.IsError()) {
        return Error::Cast(result).raw();
      }
      ASSERT(!result.IsNull());
    }
  }
  return Error::null();
}

RawError* Compiler::ParseAllFunctions(const Class& cls) {
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
    if (!func.is_abstract() && !func.IsRedirectingFactory()) {
      if ((cls.is_mixin_app_alias() || cls.IsMixinApplication()) &&
          func.HasOptionalParameters()) {
        // Skipping optional parameters in mixin application.
        continue;
      }
      error = ParseFunction(thread, func);
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
    Thread* const thread = Thread::Current();
    NoOOBMessageScope no_msg_scope(thread);
    NoReloadScope no_reload_scope(thread->isolate(), thread);
    // Under lazy compilation initializer has not yet been created, so create
    // it now, but don't bother remembering it because it won't be used again.
    ASSERT(!field.HasPrecompiledInitializer());
    {
#if !defined(PRODUCT)
      VMTagScope tagScope(thread, VMTag::kCompileUnoptimizedTagId);
      TimelineDurationScope tds(thread, Timeline::GetCompilerStream(),
                                "CompileStaticInitializer");
      if (tds.enabled()) {
        tds.SetNumArguments(1);
        tds.CopyArgument(0, "field", field.ToCString());
      }
#endif  // !defined(PRODUCT)

      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      ParsedFunction* parsed_function;

      // Create a one-time-use function to evaluate the initializer and invoke
      // it immediately.
      if (field.kernel_offset() > 0) {
        parsed_function = kernel::ParseStaticFieldInitializer(zone, field);
      } else {
        parsed_function = Parser::ParseStaticFieldInitializer(field);
        parsed_function->AllocateVariables();
      }

      // Non-optimized code generator.
      DartCompilationPipeline pipeline;
      CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
      const Code& code = Code::Handle(helper.Compile(&pipeline));
      if (!code.IsNull()) {
        const Function& initializer = parsed_function->function();
        code.set_var_descriptors(Object::empty_var_descriptors());
        // Invoke the function to evaluate the expression.
        return DartEntry::InvokeFunction(initializer, Object::empty_array());
      }
    }
  }

  Thread* const thread = Thread::Current();
  StackZone zone(thread);
  const Error& error = Error::Handle(thread->zone(), thread->sticky_error());
  thread->clear_sticky_error();
  return error.raw();
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

    // Don't allow reload requests to come in.
    NoReloadScope no_reload_scope(thread->isolate(), thread);

    if (FLAG_trace_compiler) {
      THR_Print("compiling expression: ");
      if (FLAG_support_ast_printer) {
        AstPrinter ast_printer;
        ast_printer.PrintNode(fragment);
      }
    }

    // Create a dummy function object for the code generator.
    // The function needs to be associated with a named Class: the interface
    // Function fits the bill.
    const char* kEvalConst = "eval_const";
    const Function& func = Function::ZoneHandle(Function::New(
        String::Handle(Symbols::New(thread, kEvalConst)),
        RawFunction::kRegularFunction,
        true,   // static function
        false,  // not const function
        false,  // not abstract
        false,  // not external
        false,  // not native
        Class::Handle(Type::Handle(Type::DartFunctionType()).type_class()),
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
    fragment->scope()->AddVariable(parsed_function->current_context_var());
    parsed_function->AllocateVariables();

    // Non-optimized code generator.
    DartCompilationPipeline pipeline;
    CompileParsedFunctionHelper helper(parsed_function, false, kNoOSRDeoptId);
    const Code& code = Code::Handle(helper.Compile(&pipeline));
    if (!code.IsNull()) {
      code.set_var_descriptors(Object::empty_var_descriptors());
      const Object& result = PassiveObject::Handle(
          DartEntry::InvokeFunction(func, Object::empty_array()));
      return result.raw();
    }
  }

  Thread* const thread = Thread::Current();
  const Object& result = PassiveObject::Handle(thread->sticky_error());
  thread->clear_sticky_error();
  return result.raw();
}

void Compiler::AbortBackgroundCompilation(intptr_t deopt_id, const char* msg) {
  if (FLAG_trace_compiler) {
    THR_Print("ABORT background compilation: %s\n", msg);
  }
#if !defined(PRODUCT)
  TimelineStream* stream = Timeline::GetCompilerStream();
  ASSERT(stream != NULL);
  TimelineEvent* event = stream->StartEvent();
  if (event != NULL) {
    event->Instant("AbortBackgroundCompilation");
    event->SetNumArguments(1);
    event->CopyArgument(0, "reason", msg);
    event->Complete();
  }
#endif  // !defined(PRODUCT)
  ASSERT(Compiler::IsBackgroundCompilation());
  Thread::Current()->long_jump_base()->Jump(
      deopt_id, Object::background_compilation_error());
}

// C-heap allocated background compilation queue element.
class QueueElement {
 public:
  explicit QueueElement(const Function& function)
      : next_(NULL), function_(function.raw()) {}

  virtual ~QueueElement() {
    next_ = NULL;
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
  virtual ~BackgroundCompilationQueue() { Clear(); }

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
    ASSERT(value->next() == NULL);
    if (first_ == NULL) {
      first_ = value;
      ASSERT(last_ == NULL);
    } else {
      ASSERT(last_ != NULL);
      last_->set_next(value);
    }
    last_ = value;
    ASSERT(first_ != NULL && last_ != NULL);
  }

  QueueElement* Peek() const { return first_; }

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

  void Clear() {
    while (!IsEmpty()) {
      QueueElement* e = Remove();
      delete e;
    }
    ASSERT((first_ == NULL) && (last_ == NULL));
  }

 private:
  QueueElement* first_;
  QueueElement* last_;

  DISALLOW_COPY_AND_ASSIGN(BackgroundCompilationQueue);
};

BackgroundCompiler::BackgroundCompiler(Isolate* isolate)
    : isolate_(isolate),
      queue_monitor_(new Monitor()),
      function_queue_(new BackgroundCompilationQueue()),
      done_monitor_(new Monitor()),
      running_(false),
      done_(true),
      disabled_depth_(0) {}

// Fields all deleted in ::Stop; here clear them.
BackgroundCompiler::~BackgroundCompiler() {
  delete queue_monitor_;
  delete function_queue_;
  delete done_monitor_;
}

void BackgroundCompiler::Run() {
  while (running_) {
    // Maybe something is already in the queue, check first before waiting
    // to be notified.
    bool result = Thread::EnterIsolateAsHelper(isolate_, Thread::kCompilerTask);
    ASSERT(result);
    {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      HANDLESCOPE(thread);
      Function& function = Function::Handle(zone);
      {
        MonitorLocker ml(queue_monitor_);
        function = function_queue()->PeekFunction();
      }
      while (running_ && !function.IsNull() && !isolate_->IsTopLevelParsing()) {
        // Check that we have aggregated and cleared the stats.
        ASSERT(thread->compiler_stats()->IsCleared());
        Compiler::CompileOptimizedFunction(thread, function,
                                           Compiler::kNoOSRDeoptId);
#ifndef PRODUCT
        Isolate* isolate = thread->isolate();
        isolate->aggregate_compiler_stats()->Add(*thread->compiler_stats());
        thread->compiler_stats()->Clear();
#endif  // PRODUCT

        QueueElement* qelem = NULL;
        {
          MonitorLocker ml(queue_monitor_);
          if (function_queue()->IsEmpty()) {
            // We are shutting down, queue was cleared.
            function = Function::null();
          } else {
            qelem = function_queue()->Remove();
            const Function& old = Function::Handle(qelem->Function());
            if ((!old.HasOptimizedCode() && old.IsOptimizable()) ||
                FLAG_stress_test_background_compilation) {
              if (Compiler::CanOptimizeFunction(thread, old)) {
                QueueElement* repeat_qelem = new QueueElement(old);
                function_queue()->Add(repeat_qelem);
              }
            }
            function = function_queue()->PeekFunction();
          }
        }
        if (qelem != NULL) {
          delete qelem;
        }
      }
    }
    Thread::ExitIsolateAsHelper();
    {
      // Wait to be notified when the work queue is not empty.
      MonitorLocker ml(queue_monitor_);
      while ((function_queue()->IsEmpty() || isolate_->IsTopLevelParsing()) &&
             running_) {
        ml.Wait();
      }
    }
  }  // while running

  {
    // Notify that the thread is done.
    MonitorLocker ml_done(done_monitor_);
    done_ = true;
    ml_done.Notify();
  }
}

void BackgroundCompiler::CompileOptimized(const Function& function) {
  ASSERT(Thread::Current()->IsMutatorThread());
  // TODO(srdjan): Checking different strategy for collecting garbage
  // accumulated by background compiler.
  if (isolate_->heap()->NeedsGarbageCollection()) {
    isolate_->heap()->CollectAllGarbage();
  }
  {
    MonitorLocker ml(queue_monitor_);
    ASSERT(running_);
    if (function_queue()->ContainsObj(function)) {
      return;
    }
    QueueElement* elem = new QueueElement(function);
    function_queue()->Add(elem);
    ml.Notify();
  }
}

void BackgroundCompiler::VisitPointers(ObjectPointerVisitor* visitor) {
  function_queue_->VisitObjectPointers(visitor);
}

class BackgroundCompilerTask : public ThreadPool::Task {
 public:
  explicit BackgroundCompilerTask(BackgroundCompiler* background_compiler)
      : background_compiler_(background_compiler) {}
  virtual ~BackgroundCompilerTask() {}

 private:
  virtual void Run() { background_compiler_->Run(); }

  BackgroundCompiler* background_compiler_;

  DISALLOW_COPY_AND_ASSIGN(BackgroundCompilerTask);
};

void BackgroundCompiler::Start() {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(!thread->IsAtSafepoint());

  // Finalize NoSuchMethodError, _Mint; occasionally needed in optimized
  // compilation.
  Class& cls = Class::Handle(
      thread->zone(), Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  ASSERT(!cls.IsNull());
  Error& error = Error::Handle(thread->zone(), cls.EnsureIsFinalized(thread));
  ASSERT(error.IsNull());
  cls = Library::LookupCoreClass(Symbols::_Mint());
  ASSERT(!cls.IsNull());
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());

  MonitorLocker ml(done_monitor_);
  if (running_ || !done_) return;
  running_ = true;
  done_ = false;
  bool task_started =
      Dart::thread_pool()->Run(new BackgroundCompilerTask(this));
  if (!task_started) {
    running_ = false;
    done_ = true;
  }
}

void BackgroundCompiler::Stop() {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsMutatorThread());
  ASSERT(!thread->IsAtSafepoint());

  {
    MonitorLocker ml(queue_monitor_);
    running_ = false;
    function_queue_->Clear();
    ml.Notify();  // Stop waiting for the queue.
  }

  {
    MonitorLocker ml_done(done_monitor_);
    while (!done_) {
      ml_done.WaitWithSafepointCheck(thread);
    }
  }
}

void BackgroundCompiler::Enable() {
  disabled_depth_--;
  if (disabled_depth_ < 0) {
    FATAL("Mismatched number of calls to BackgroundCompiler::Enable/Disable.");
  }
}

void BackgroundCompiler::Disable() {
  Stop();
  disabled_depth_++;
}

bool BackgroundCompiler::IsDisabled() {
  return disabled_depth_ > 0;
}

#else  // DART_PRECOMPILED_RUNTIME

bool UseKernelFrontEndFor(ParsedFunction* parsed_function) {
  UNREACHABLE();
  return false;
}

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
  return false;
}

bool Compiler::CanOptimizeFunction(Thread* thread, const Function& function) {
  UNREACHABLE();
  return false;
}

RawError* Compiler::Compile(const Library& library, const Script& script) {
  FATAL1("Attempt to compile script %s", script.ToCString());
  return Error::null();
}

RawError* Compiler::CompileClass(const Class& cls) {
  FATAL1("Attempt to compile class %s", cls.ToCString());
  return Error::null();
}

RawObject* Compiler::CompileFunction(Thread* thread, const Function& function) {
  FATAL1("Attempt to compile function %s", function.ToCString());
  return Error::null();
}

RawError* Compiler::ParseFunction(Thread* thread, const Function& function) {
  FATAL1("Attempt to parse function %s", function.ToCString());
  return Error::null();
}

RawError* Compiler::EnsureUnoptimizedCode(Thread* thread,
                                          const Function& function) {
  FATAL1("Attempt to compile function %s", function.ToCString());
  return Error::null();
}

RawObject* Compiler::CompileOptimizedFunction(Thread* thread,
                                              const Function& function,
                                              intptr_t osr_id) {
  FATAL1("Attempt to compile function %s", function.ToCString());
  return Error::null();
}

RawError* Compiler::CompileParsedFunction(ParsedFunction* parsed_function) {
  FATAL1("Attempt to compile function %s",
         parsed_function->function().ToCString());
  return Error::null();
}

void Compiler::ComputeLocalVarDescriptors(const Code& code) {
  UNREACHABLE();
}

RawError* Compiler::CompileAllFunctions(const Class& cls) {
  FATAL1("Attempt to compile class %s", cls.ToCString());
  return Error::null();
}

RawError* Compiler::ParseAllFunctions(const Class& cls) {
  FATAL1("Attempt to parse class %s", cls.ToCString());
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

void Compiler::AbortBackgroundCompilation(intptr_t deopt_id, const char* msg) {
  UNREACHABLE();
}

void BackgroundCompiler::CompileOptimized(const Function& function) {
  UNREACHABLE();
}

void BackgroundCompiler::VisitPointers(ObjectPointerVisitor* visitor) {
  UNREACHABLE();
}

void BackgroundCompiler::Start() {
  UNREACHABLE();
}

void BackgroundCompiler::Stop() {
  UNREACHABLE();
}

void BackgroundCompiler::Enable() {
  UNREACHABLE();
}

void BackgroundCompiler::Disable() {
  UNREACHABLE();
}

bool BackgroundCompiler::IsDisabled() {
  UNREACHABLE();
  return true;
}

#endif  // DART_PRECOMPILED_RUNTIME

}  // namespace dart
