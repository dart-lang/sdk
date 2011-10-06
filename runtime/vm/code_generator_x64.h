// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_X64_H_
#define VM_CODE_GENERATOR_X64_H_

#ifndef VM_CODE_GENERATOR_H_
#error Do not include code_generator_x64.h directly; use assembler.h instead.
#endif

#include "vm/allocation.h"
#include "vm/ast.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Assembler;
class AstNode;
class ParsedFunction;

class CodeGenerator : public AstNodeVisitor {
 public:
  CodeGenerator(Assembler* assembler, const ParsedFunction& parsed_function) { }
  virtual ~CodeGenerator() { }

  bool GenerateCode() {
    return false;
  }

  // Add an exception handler table to code.
  void FinalizeExceptionHandlers(const Code& code) { UNIMPLEMENTED(); }

  // Add Pcdescriptors to code.
  void FinalizePcDescriptors(const Code& code) { UNIMPLEMENTED(); }

  // Allocate and return an arguments descriptor.
  // Let 'num_names' be the length of 'optional_arguments_names'.
  // Treat the first 'num_arguments - num_names' arguments as positional and
  // treat the following 'num_names' arguments as named optional arguments.
  static const Array& ArgumentsDescriptor(
      int num_arguments,
      const Array& optional_arguments_names);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(CodeGenerator);
};

}  // namespace dart

#endif  // VM_CODE_GENERATOR_X64_H_
