// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_API_PRINT_FILTER_H_
#define RUNTIME_VM_COMPILER_API_PRINT_FILTER_H_
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

#include "platform/allocation.h"

namespace dart {

class Function;

namespace compiler {

class PrintFilter : public AllStatic {
 public:
  static bool ShouldPrint(const Function& function);
};

}  // namespace compiler

}  // namespace dart

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
#endif  // RUNTIME_VM_COMPILER_API_PRINT_FILTER_H_
