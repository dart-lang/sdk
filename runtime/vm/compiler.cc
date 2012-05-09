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
#include "vm/disassembler.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/opt_code_generator.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/scanner.h"
#include "vm/timer.h"

namespace dart {

DEFINE_FLAG(bool, disassemble, false, "Disassemble dart code.");
DEFINE_FLAG(bool, trace_compiler, false, "Trace compiler operations.");
DEFINE_FLAG(int, deoptimization_counter_threshold, 5,
    "How many times we allow deoptimization before we disallow"
    " certain optimizations");
#if defined(TARGET_ARCH_X64)
DEFINE_FLAG(bool, use_new_compiler, true,
    "Try to use the new compiler backend.");
#else
DEFINE_FLAG(bool, use_new_compiler, false,
    "Try to use the new compiler backend.");
#endif
DEFINE_FLAG(bool, trace_bailout, false, "Print bailout from new compiler.");


// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  ASSERT(arguments.Count() == kCompileFunctionRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(!function.HasCode());
  const Error& error = Error::Handle(Compiler::CompileFunction(function));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }
}


// Extracts IC data associated with a node id.
// TODO(srdjan): Check performance impact of node id search loop.
static void ExtractTypeFeedback(const Code& code,
                                SequenceNode* sequence_node) {
  ASSERT(!code.IsNull() && !code.is_optimized());
  GrowableArray<AstNode*> all_nodes;
  sequence_node->CollectAllNodes(&all_nodes);
  GrowableArray<intptr_t> node_ids;
  const GrowableObjectArray& ic_data_objs =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  code.ExtractIcDataArraysAtCalls(&node_ids, ic_data_objs);
  ICData& ic_data_obj = ICData::Handle();
  for (intptr_t i = 0; i < node_ids.length(); i++) {
    intptr_t node_id = node_ids[i];
    bool found_node = false;
    for (intptr_t n = 0; n < all_nodes.length(); n++) {
      if (all_nodes[n]->HasId(node_id)) {
        found_node = true;
        // Make sure we assign ic data array only once.
        ASSERT(all_nodes[n]->ICDataAtId(node_id).IsNull());
        ic_data_obj ^= ic_data_objs.At(i);
        all_nodes[n]->SetIcDataAtId(node_id, ic_data_obj);
      }
    }
    ASSERT(found_node);
  }
}


RawError* Compiler::Compile(const Library& library, const Script& script) {
  Isolate* isolate = Isolate::Current();
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    if (FLAG_trace_compiler) {
      HANDLESCOPE(isolate);
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
  // Patch entry of optimized code.
  CodePatcher::PatchEntry(Code::Handle(function.CurrentCode()));
  if (FLAG_trace_compiler) {
    OS::Print("--> patching entry 0x%x\n",
              Code::Handle(function.CurrentCode()).EntryPoint());
  }
  // Use previously compiled code.
  function.SetCode(Code::Handle(function.unoptimized_code()));
  CodePatcher::RestoreEntry(Code::Handle(function.unoptimized_code()));
  if (FLAG_trace_compiler) {
    OS::Print("--> restoring entry at 0x%x\n",
              Code::Handle(function.unoptimized_code()).EntryPoint());
  }
}


// Return false if bailed out.
static bool CompileWithNewCompiler(
    const ParsedFunction& parsed_function, bool optimized) {
  bool is_compiled = false;
  Isolate* isolate = Isolate::Current();
  LongJump* old_base = isolate->long_jump_base();
  LongJump bailout_jump;
  isolate->set_long_jump_base(&bailout_jump);
  if (setjmp(*bailout_jump.Set()) == 0) {
    GrowableArray<BlockEntryInstr*> block_order;
    // TimerScope needs an isolate to be properly terminated in case of a
    // LongJump.
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphbuilder_timer,
                       isolate);
      CompilerStats::graphbuilder_timer.Start();
      FlowGraphBuilder graph_builder(parsed_function);
      graph_builder.BuildGraph(optimized);

      // The non-optimizing compiler compiles blocks in reverse postorder,
      // because it is a 'natural' order for the human reader of the
      // generated code.
      intptr_t length = graph_builder.postorder_block_entries().length();
      for (intptr_t i = length - 1; i >= 0; --i) {
        block_order.Add(graph_builder.postorder_block_entries()[i]);
      }

      if (optimized) {
        // Transition to optimized code only from unoptimized code ...
        // for now.
        ASSERT(parsed_function.function().HasCode());
        ASSERT(!parsed_function.function().HasOptimizedCode());
        // Do not use type feedback to optimize a function that was
        // deoptimized too often.
        if (parsed_function.function().deoptimization_counter() <
            FLAG_deoptimization_counter_threshold) {
          // Extract type feedback etc.
        }
      }
    }

    Assembler assembler;
    FlowGraphCompiler graph_compiler(&assembler, parsed_function,
                                     block_order, optimized);
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
      const Code& code = Code::Handle(Code::FinalizeCode(function, &assembler));
      code.set_is_optimized(optimized);
      graph_compiler.FinalizePcDescriptors(code);
      graph_compiler.FinalizeStackmaps(code);
      graph_compiler.FinalizeVarDescriptors(code);
      graph_compiler.FinalizeExceptionHandlers(code);
      if (optimized) {
        function.SetCode(code);
        CodePatcher::PatchEntry(Code::Handle(function.unoptimized_code()));
        if (FLAG_trace_compiler) {
          OS::Print("--> patching entry 0x%x\n",
                    Code::Handle(function.unoptimized_code()).EntryPoint());
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
    is_compiled = false;
  }
  isolate->set_long_jump_base(old_base);
  return is_compiled;
}


static void CompileWithOldCompiler(
    const ParsedFunction& parsed_function, bool optimized) {
  const Function& function = parsed_function.function();
  Assembler assembler;
  if (optimized) {
    // Transition to optimized code only from unoptimized code ...
    // for now.
    ASSERT(function.HasCode());
    ASSERT(!function.HasOptimizedCode());
    // Do not use type feedback to optimize a function that was
    // deoptimized too often.
    if (parsed_function.function().deoptimization_counter() <
        FLAG_deoptimization_counter_threshold) {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphbuilder_timer);
      ExtractTypeFeedback(
          Code::Handle(parsed_function.function().unoptimized_code()),
          parsed_function.node_sequence());
    }
    OptimizingCodeGenerator code_gen(&assembler, parsed_function);
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphcompiler_timer);
      code_gen.GenerateCode();
    }
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::codefinalizer_timer);
      Code& code = Code::Handle(Code::FinalizeCode(function, &assembler));
      code.set_is_optimized(true);
      code_gen.FinalizePcDescriptors(code);
      code_gen.FinalizeStackmaps(code);
      code_gen.FinalizeExceptionHandlers(code);
      function.SetCode(code);
      CodePatcher::PatchEntry(Code::Handle(function.unoptimized_code()));
    }
    if (FLAG_trace_compiler) {
      OS::Print("--> patching entry 0x%x\n",
                Code::Handle(function.unoptimized_code()).EntryPoint());
    }
  } else {
    // Compile unoptimized code.
    ASSERT(!function.HasCode());
    // Compiling first time.
    CodeGenerator code_gen(&assembler, parsed_function);
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::graphcompiler_timer);
      code_gen.GenerateCode();
    }
    {
      TimerScope timer(FLAG_compiler_stats,
                       &CompilerStats::codefinalizer_timer);
      const Code& code = Code::Handle(Code::FinalizeCode(function, &assembler));
      code.set_is_optimized(false);
      code_gen.FinalizePcDescriptors(code);
      code_gen.FinalizeStackmaps(code);
      code_gen.FinalizeVarDescriptors(code);
      code_gen.FinalizeExceptionHandlers(code);
      function.set_unoptimized_code(code);
      function.SetCode(code);
      ASSERT(CodePatcher::CodeIsPatchable(code));
    }
  }
}

static void CompileParsedFunctionHelper(
    const ParsedFunction& parsed_function, bool optimized) {
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::codegen_timer);
  bool is_compiled = false;
  // TODO(srdjan): Remove once the old compiler has been ripped out.
#if defined(TARGET_ARCH_X64)
  const bool use_new_compiler = true;
#else
  const bool use_new_compiler = FLAG_use_new_compiler;
#endif
  if (use_new_compiler) {
    is_compiled = CompileWithNewCompiler(parsed_function, optimized);
  }

  if (!is_compiled) {
    CompileWithOldCompiler(parsed_function, optimized);
  }
}


static RawError* CompileFunctionHelper(const Function& function,
                                       bool optimized) {
  Isolate* isolate = Isolate::Current();
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
    ParsedFunction parsed_function(function);
    if (FLAG_trace_compiler) {
      OS::Print("Compiling %sfunction: '%s' @ token %d\n",
                (optimized ? "optimized " : ""),
                function.ToFullyQualifiedCString(),
                function.token_index());
    }
    Parser::ParseFunction(&parsed_function);
    parsed_function.AllocateVariables();

    CompileParsedFunctionHelper(parsed_function, optimized);

    if (FLAG_trace_compiler) {
      OS::Print("--> '%s' entry: 0x%x\n",
                function.ToFullyQualifiedCString(),
                Code::Handle(function.CurrentCode()).EntryPoint());
    }
    if (Isolate::Current()->debugger()->IsActive()) {
      Isolate::Current()->debugger()->NotifyCompilation(function);
    }
    if (FLAG_disassemble) {
      const char* function_fullname = function.ToFullyQualifiedCString();
      OS::Print("Code for %sfunction '%s' {\n",
                optimized ? "optimized " : "",
                function_fullname);
      const Code& code = Code::Handle(function.CurrentCode());
      const Instructions& instructions =
          Instructions::Handle(code.instructions());
      uword start = instructions.EntryPoint();
      Disassembler::Disassemble(start, start + instructions.size());
      OS::Print("}\n");
      OS::Print("Pointer offsets for function: {\n");
      for (intptr_t i = 0; i < code.pointer_offsets_length(); i++) {
        const uword addr = code.GetPointerOffsetAt(i) + code.EntryPoint();
        Object& obj = Object::Handle();
        obj = *reinterpret_cast<RawObject**>(addr);
        OS::Print(" %d : 0x%x '%s'\n",
                  code.GetPointerOffsetAt(i), addr, obj.ToCString());
      }
      OS::Print("}\n");
      OS::Print("PC Descriptors for function '%s' {\n", function_fullname);
      OS::Print("(pc\t\tkind\tid\ttry-ix\ttoken-index)\n");
      const PcDescriptors& descriptors =
          PcDescriptors::Handle(code.pc_descriptors());
      OS::Print("%s", descriptors.ToCString());
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
        intptr_t scope_id, begin_pos, end_pos;
        var_descriptors.GetScopeInfo(i, &scope_id, &begin_pos, &end_pos);
        intptr_t slot = var_descriptors.GetSlotIndex(i);
        OS::Print("  var %s scope %ld (valid %d-%d) offset %ld\n",
                  var_name.ToCString(), scope_id, begin_pos, end_pos, slot);
      }
      OS::Print("}\n");
      OS::Print("Exception Handlers for function '%s' {\n", function_fullname);
      const ExceptionHandlers& handlers =
          ExceptionHandlers::Handle(code.exception_handlers());
      OS::Print("%s", handlers.ToCString());
      OS::Print("}\n");
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
    CompileParsedFunctionHelper(parsed_function, false);  // Non-optimized.
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
  for (int i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    if (!func.HasCode() && !func.IsAbstract()) {
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
    const char* kEvalConst = "eval_const";
    const Function& func = Function::Handle(Function::New(
        String::Handle(String::NewSymbol(kEvalConst)),
        RawFunction::kConstImplicitGetter,
        true,  // static function.
        false,  // not const function.
        fragment->token_index()));

    func.set_result_type(Type::Handle(Type::DynamicType()));
    func.set_num_fixed_parameters(0);
    func.set_num_optional_parameters(0);

    // The function needs to be associated with a named Class: the interface
    // Function fits the bill.
    func.set_owner(Class::Handle(
        Type::Handle(Type::FunctionInterface()).type_class()));

    // We compile the function here, even though InvokeStatic() below
    // would compile func automatically. We are checking fewer invariants
    // here.
    ParsedFunction parsed_function(func);
    parsed_function.SetNodeSequence(fragment);
    parsed_function.set_default_parameter_values(Array::Handle());

    CompileParsedFunctionHelper(parsed_function, false);  // Non-optimized.

    GrowableArray<const Object*> arguments;  // no arguments.
    const Array& kNoArgumentNames = Array::Handle();
    Object& result = Object::Handle();
    result = DartEntry::InvokeStatic(func,
                                     arguments,
                                     kNoArgumentNames);
    isolate->set_long_jump_base(base);
    return result.raw();
  } else {
    Object& result = Object::Handle();
    result = isolate->object_store()->sticky_error();
    isolate->object_store()->clear_sticky_error();
    isolate->set_long_jump_base(base);
    return result.raw();
  }
  UNREACHABLE();
  return Object::null();
}


}  // namespace dart
