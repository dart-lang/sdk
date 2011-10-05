// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OPT_CODE_GENERATOR_X64_H_
#define VM_OPT_CODE_GENERATOR_X64_H_

#ifndef VM_OPT_CODE_GENERATOR_H_
#error Do not include opt_code_generator_x64.h; use opt_code_generator.h.
#endif

#include "vm/code_generator.h"

namespace dart {

// Temporary hierarchy, until optimized code generator implemented.
class OptimizingCodeGenerator : public CodeGenerator {
 public:
  OptimizingCodeGenerator(Assembler* assembler,
                          const ParsedFunction& parsed_function)
      : CodeGenerator(assembler, parsed_function) {}

  virtual bool IsOptimizing() const {
    return true;
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(OptimizingCodeGenerator);
};

}  // namespace dart


#endif  // VM_OPT_CODE_GENERATOR_X64_H_
