// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef RUNTIME_VM_COMPILER_INTRINSIFIER_H_
#define RUNTIME_VM_COMPILER_INTRINSIFIER_H_

#include "vm/allocation.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/graph_intrinsifier.h"
#include "vm/compiler/method_recognizer.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class Function;
class ParsedFunction;

namespace compiler {
class Assembler;
class Label;

class Intrinsifier : public AllStatic {
 public:
  static bool Intrinsify(const ParsedFunction& parsed_function,
                         FlowGraphCompiler* compiler);
#if !defined(DART_PRECOMPILED_RUNTIME)
  static void InitializeState();
#endif

 private:
  static bool CanIntrinsify(const Function& function);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_INTRINSIFIER_H_
