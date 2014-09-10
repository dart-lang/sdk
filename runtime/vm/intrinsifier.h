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
  static void Intrinsify(ParsedFunction* parsed_function,
                         FlowGraphCompiler* compiler);
  static void InitializeState();

  static bool GraphIntrinsify(ParsedFunction* parsed_function,
                              FlowGraphCompiler* compiler);

  static intptr_t ParameterSlotFromSp();

 private:
  static bool CanIntrinsify(const Function& function);

#define DECLARE_FUNCTION(test_class_name, test_function_name, enum_name, fp)   \
  static void enum_name(Assembler* assembler);

  ALL_INTRINSICS_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION

#define DECLARE_FUNCTION(test_class_name, test_function_name, enum_name, fp)   \
  static bool Build_##enum_name(FlowGraph* flow_graph);

  GRAPH_INTRINSICS_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
