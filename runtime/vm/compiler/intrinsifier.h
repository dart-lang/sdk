// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef RUNTIME_VM_COMPILER_INTRINSIFIER_H_
#define RUNTIME_VM_COMPILER_INTRINSIFIER_H_

#include "vm/allocation.h"
#include "vm/compiler/method_recognizer.h"

namespace dart {

// Forward declarations.
namespace compiler {
class Assembler;
class Label;
}  // namespace compiler
class FlowGraphCompiler;
class Function;
class TargetEntryInstr;
class ParsedFunction;
class FlowGraph;

using compiler::Assembler;
using compiler::Label;

class Intrinsifier : public AllStatic {
 public:
  static bool Intrinsify(const ParsedFunction& parsed_function,
                         FlowGraphCompiler* compiler);
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void InitializeState();
#endif

  static bool GraphIntrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler);

  static intptr_t ParameterSlotFromSp();

  static void IntrinsicCallPrologue(Assembler* assembler);
  static void IntrinsicCallEpilogue(Assembler* assembler);

 private:
  // The "_A" value used in the intrinsification of
  // `runtime/lib/math_patch.dart:_Random._nextState()`
  static const int64_t kRandomAValue = 0xffffda61;

  static bool CanIntrinsify(const Function& function);

#define DECLARE_FUNCTION(class_name, function_name, enum_name, fp)             \
  static void enum_name(Assembler* assembler, Label* normal_ir_body);

  ALL_INTRINSICS_LIST(DECLARE_FUNCTION)
#if defined(TARGET_ARCH_DBC)
  // On DBC graph intrinsics are handled in the same way as non-graph ones.
  GRAPH_INTRINSICS_LIST(DECLARE_FUNCTION)
#endif

#undef DECLARE_FUNCTION

#if !defined(TARGET_ARCH_DBC)
#define DECLARE_FUNCTION(class_name, function_name, enum_name, fp)             \
  static bool Build_##enum_name(FlowGraph* flow_graph);

  GRAPH_INTRINSICS_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION

  static void IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                           Label* normal_ir_body,
                                           bool sticky);
#endif
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_INTRINSIFIER_H_
