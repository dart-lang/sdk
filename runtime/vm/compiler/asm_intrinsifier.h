// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef RUNTIME_VM_COMPILER_ASM_INTRINSIFIER_H_
#define RUNTIME_VM_COMPILER_ASM_INTRINSIFIER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/recognized_methods_list.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class Function;
class TargetEntryInstr;
class ParsedFunction;
class FlowGraph;

namespace compiler {
class Assembler;
class Intrinsifier;
class Label;

class AsmIntrinsifier : public AllStatic {
 private:
  friend class Intrinsifier;

#define DECLARE_FUNCTION(library, class, function, enum_name, fp)              \
  static void enum_name(Assembler* assembler, Label* normal_ir_body);
  ASM_INTRINSICS_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION

  static void IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                           Label* normal_ir_body,
                                           bool sticky);

  static void StringEquality(Assembler* assembler,
                             Register obj1,
                             Register obj2,
                             Register temp1,
                             Register temp2,
                             Register result,
                             Label* normal_ir_body,
                             intptr_t string_cid);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASM_INTRINSIFIER_H_
