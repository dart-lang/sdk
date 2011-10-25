// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler.h"

#include "vm/assembler.h"
#include "vm/ast_printer.h"
#include "vm/code_generator.h"
#include "vm/code_index_table.h"
#include "vm/code_patcher.h"
#include "vm/dart_entry.h"
#include "vm/disassembler.h"
#include "vm/flags.h"
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
DEFINE_FLAG(int, deoptimization_counter_threshold, 2,
    "How many times we allow deoptimization before we disallow"
    " certain optimizations");


// Compile a function. Should call only if the function has not been compiled.
//   Arg0: function object.
DEFINE_RUNTIME_ENTRY(CompileFunction, 1) {
  ASSERT(arguments.Count() == kCompileFunctionRuntimeEntry.argument_count());
  const Function& function = Function::CheckedHandle(arguments.At(0));
  ASSERT(!function.HasCode());
  Compiler::CompileFunction(function);
}


// Extracts all encountered classes of instance calls in the unoptimized code
// by analyzing the inline caches.
// Each instance call contains a token index which is matched with an AST
// node. The collected classes are assigned to the corresponding node.
static void ExtractTypeFeedback(const Code& code,
                                SequenceNode* sequence_node) {
  ASSERT(!code.IsNull() && !code.is_optimized());
  GrowableArray<intptr_t> node_ids;
  GrowableArray<ZoneGrowableArray<const Class*>*> type_arrays;
  code.ExtractTypesAtIcCalls(&node_ids, &type_arrays);
  GrowableArray<AstNode*> all_nodes;
  sequence_node->CollectAllNodes(&all_nodes);
  for (intptr_t i = 0; i < node_ids.length(); i++) {
    ZoneGrowableArray<const Class*>* types = type_arrays[i];
    bool found_node = false;
    for (intptr_t n = 0; n < all_nodes.length(); n++) {
      if (all_nodes[n]->HasId(node_ids[i])) {
        ASSERT(all_nodes[n]->CollectedClassesAtId(node_ids[i]) == NULL);
        all_nodes[n]->SetCollectedClassesAtId(node_ids[i], types);
        found_node = true;
        break;
      }
    }
    // There must be a node with the given token index.
    ASSERT(found_node);
  }
}


void Compiler::Compile(const Library& library, const Script& script) {
  if (FLAG_trace_compiler) {
    HANDLESCOPE();
    const String& script_url = String::Handle(script.url());
    // TODO(iposva): Extract script kind.
    OS::Print("Compiling %s '%s'\n", "", script_url.ToCString());
  }
  const String& library_key = String::Handle(library.private_key());
  script.Tokenize(library_key);
  Parser::ParseCompilationUnit(library, script);
}


static void CompileFunctionHelper(const Function& function, bool optimized) {
  TIMERSCOPE(time_compilation);
  ParsedFunction parsed_function(function);
  const char* function_fullname = function.ToFullyQualifiedCString();
  if (FLAG_trace_compiler) {
    OS::Print("Compiling %sfunction: '%s' @ token %d\n",
        (optimized ? "optimized " : ""),
        function_fullname,
        function.token_index());
  }
  Parser::ParseFunction(&parsed_function);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  Assembler assembler;
  if (optimized) {
    // Transition to optimized code only from unoptimized code ... for now.
    ASSERT(function.HasCode());
    ASSERT(!Code::Handle(function.code()).is_optimized());
    // Do not use type feedback to optimize a function that was deoptimized.
    if (parsed_function.function().deoptimization_counter() <
        FLAG_deoptimization_counter_threshold) {
      ExtractTypeFeedback(Code::Handle(parsed_function.function().code()),
                          parsed_function.node_sequence());
    }
    OptimizingCodeGenerator code_gen(&assembler, parsed_function);
    code_gen.GenerateCode();
    Code& code = Code::Handle(
        Code::FinalizeCode(function_fullname, &assembler));
    code.set_is_optimized(true);
    code_gen.FinalizePcDescriptors(code);
    code_gen.FinalizeExceptionHandlers(code);
    function.SetCode(code);
    code_index_table->AddFunction(function);
    CodePatcher::PatchEntry(Code::Handle(function.unoptimized_code()));
    if (FLAG_trace_compiler) {
      OS::Print("--> patching entry 0x%x\n",
          Code::Handle(function.unoptimized_code()).EntryPoint());
    }
  } else {
    // Unoptimized code.
    if (Code::Handle(function.unoptimized_code()).IsNull()) {
      ASSERT(Code::Handle(function.code()).IsNull());
      // Compiling first time.
      CodeGenerator code_gen(&assembler, parsed_function);
      code_gen.GenerateCode();
      const Code& code =
          Code::Handle(Code::FinalizeCode(function_fullname, &assembler));
      code.set_is_optimized(false);
      code_gen.FinalizePcDescriptors(code);
      code_gen.FinalizeExceptionHandlers(code);
      function.set_unoptimized_code(code);
      function.SetCode(code);
      ASSERT(CodePatcher::CodeIsPatchable(code));
      code_index_table->AddFunction(function);
    } else {
      // Disable optimized code.
      const Code& optimized_code = Code::Handle(function.code());
      ASSERT(optimized_code.is_optimized());
      CodePatcher::PatchEntry(Code::Handle(function.code()));
      if (FLAG_trace_compiler) {
        OS::Print("--> patching entry 0x%x\n",
            Code::Handle(function.unoptimized_code()).EntryPoint());
      }
      // Use previously compiled code.
      function.SetCode(Code::Handle(function.unoptimized_code()));
      CodePatcher::RestoreEntry(Code::Handle(function.unoptimized_code()));
      if (FLAG_trace_compiler) {
        OS::Print("--> restoring entry at 0x%x\n",
            Code::Handle(function.unoptimized_code()).EntryPoint());
      }
    }
  }
  if (FLAG_trace_compiler) {
    OS::Print("--> '%s' entry: 0x%x\n",
        function_fullname, Code::Handle(function.code()).EntryPoint());
  }
  if (FLAG_disassemble) {
    OS::Print("Code for %sfunction '%s' {\n",
        optimized ? "optimized " : "", function_fullname);
    const Code& code = Code::Handle(function.code());
    const Instructions& instructions =
        Instructions::Handle(code.instructions());
    uword start = instructions.EntryPoint();
    Disassembler::Disassemble(start, start + assembler.CodeSize());
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
    OS::Print("(pc, kind, id, try-index, token-index)\n");
    const PcDescriptors& descriptors =
        PcDescriptors::Handle(code.pc_descriptors());
    OS::Print("%s", descriptors.ToCString());
    OS::Print("}\n");
    OS::Print("Exception Handlers for function '%s' {\n", function_fullname);
    const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(code.exception_handlers());
    OS::Print("%s", handlers.ToCString());
    OS::Print("}\n");
  }
}


void Compiler::CompileFunction(const Function& function) {
  CompileFunctionHelper(function, false);
}


void Compiler::CompileOptimizedFunction(const Function& function) {
  CompileFunctionHelper(function, true);
}


void Compiler::CompileAllFunctions(const Class& cls) {
  Array& functions = Array::Handle(cls.functions());
  Function& func = Function::Handle();
  for (int i = 0; i < functions.Length(); i++) {
    func ^= functions.At(i);
    ASSERT(!func.IsNull());
    if (!func.HasCode() && !func.IsAbstract()) {
      CompileFunction(func);
    }
  }
}


RawInstance* Compiler::ExecuteOnce(SequenceNode* fragment) {
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

  func.set_result_type(Type::Handle(Type::VarType()));
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
  parsed_function.set_node_sequence(fragment);
  parsed_function.set_default_parameter_values(Array::Handle());

  Assembler assembler;
  CodeGenerator code_gen(&assembler, parsed_function);
  code_gen.GenerateCode();
  const Code& code = Code::Handle(Code::FinalizeCode(kEvalConst, &assembler));

  func.SetCode(code);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  code_index_table->AddFunction(func);
  // TODO(hausner): We need a way to remove these one-time execution
  // functions from the global code description (PC mapping) tables so
  // we don't pollute the system unnecessarily with stale data.
  code_gen.FinalizePcDescriptors(code);
  code_gen.FinalizeExceptionHandlers(code);

  GrowableArray<const Object*> arguments;  // no arguments.
  const Array& kNoArgumentNames = Array::Handle();
  Instance& result = Instance::Handle(
      DartEntry::InvokeStatic(func,
                              arguments,
                              kNoArgumentNames));
  if (result.IsUnhandledException()) {
    // TODO(srdjan): implement proper exit from compiler.
    UNIMPLEMENTED();
  }
  return result.raw();
}


}  // namespace dart
