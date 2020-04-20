// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.
#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/asm_intrinsifier.h"

namespace dart {
namespace compiler {

void AsmIntrinsifier::String_identityHash(Assembler* assembler,
                                          Label* normal_ir_body) {
  String_getHashCode(assembler, normal_ir_body);
}

void AsmIntrinsifier::Double_identityHash(Assembler* assembler,
                                          Label* normal_ir_body) {
  Double_hashCode(assembler, normal_ir_body);
}

void AsmIntrinsifier::RegExp_ExecuteMatch(Assembler* assembler,
                                          Label* normal_ir_body) {
  AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body,
                                                /*sticky=*/false);
}

void AsmIntrinsifier::RegExp_ExecuteMatchSticky(Assembler* assembler,
                                                Label* normal_ir_body) {
  AsmIntrinsifier::IntrinsifyRegExpExecuteMatch(assembler, normal_ir_body,
                                                /*sticky=*/true);
}

}  // namespace compiler
}  // namespace dart
