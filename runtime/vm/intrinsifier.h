// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef VM_INTRINSIFIER_H_
#define VM_INTRINSIFIER_H_

#include "vm/allocation.h"
#include "vm/method_recognizer.h"

namespace dart {

// Forward declarations.
class Assembler;
class FlowGraphCompiler;
class Function;
class TargetEntryInstr;
class ParsedFunction;
class FlowGraph;

class Intrinsifier : public AllStatic {
 public:
  static void Intrinsify(const ParsedFunction& parsed_function,
                         FlowGraphCompiler* compiler);
#if defined(DART_NO_SNAPSHOT)
  static void InitializeState();
#endif

  static bool GraphIntrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler);

  static intptr_t ParameterSlotFromSp();

  static void IntrinsicCallPrologue(Assembler* assembler);
  static void IntrinsicCallEpilogue(Assembler* assembler);

 private:
  static bool CanIntrinsify(const Function& function);

#define DECLARE_FUNCTION(class_name, function_name, enum_name, type, fp) \
  static void enum_name(Assembler* assembler);

  ALL_INTRINSICS_LIST(DECLARE_FUNCTION)
#if defined(TARGET_ARCH_DBC)
  // On DBC graph intrinsics are handled in the same way as non-graph ones.
  GRAPH_INTRINSICS_LIST(DECLARE_FUNCTION)
#endif

#undef DECLARE_FUNCTION

#if !defined(TARGET_ARCH_DBC)
#define DECLARE_FUNCTION(class_name, function_name, enum_name, type, fp) \
  static bool Build_##enum_name(FlowGraph* flow_graph);

  GRAPH_INTRINSICS_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION
#endif
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
