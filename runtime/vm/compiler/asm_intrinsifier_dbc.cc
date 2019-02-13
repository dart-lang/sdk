// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/asm_intrinsifier.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/intrinsifier.h"

namespace dart {
namespace compiler {

DECLARE_FLAG(bool, interpret_irregexp);

#define DEFINE_FUNCTION(class_name, test_function_name, enum_name, fp)         \
  void AsmIntrinsifier::enum_name(Assembler* assembler,                        \
                                  Label* normal_ir_body) {                     \
    if (Simulator::IsSupportedIntrinsic(Simulator::k##enum_name##Intrinsic)) { \
      assembler->Intrinsic(Simulator::k##enum_name##Intrinsic);                \
    }                                                                          \
    assembler->Bind(normal_ir_body);                                           \
  }

ALL_INTRINSICS_LIST(DEFINE_FUNCTION)
GRAPH_INTRINSICS_LIST(DEFINE_FUNCTION)
#undef DEFINE_FUNCTION

}  // namespace compiler
}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
