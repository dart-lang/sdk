// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_ARM_H_
#define VM_CODE_GENERATOR_ARM_H_

#ifndef VM_CODE_GENERATOR_H_
#error Do not include code_generator_arm.h directly; use assembler.h instead.
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
  CodeGenerator(Assembler* assembler, const ParsedFunction& parsed_function)
      : pc_descriptors_list_(NULL) { }
  virtual ~CodeGenerator() { }

  bool GenerateCode() {
    return false;
  }

  // Add exception handler table to code.
  void FinalizeExceptionHandlers(const Code& code) { UNIMPLEMENTED(); }

  // Add pc descriptors to code.
  void FinalizePcDescriptors(const Code& code) { UNIMPLEMENTED(); }

  // Add stack maps to code.
  void FinalizeStackmaps(const Code& code) { UNIMPLEMENTED(); }

  // Add local variable descriptors to code.
  void FinalizeVarDescriptors(const Code& code) { UNIMPLEMENTED(); }

  // Allocate and return an arguments descriptor.
  // Let 'num_names' be the length of 'optional_arguments_names'.
  // Treat the first 'num_arguments - num_names' arguments as positional and
  // treat the following 'num_names' arguments as named optional arguments.
  static const Array& ArgumentsDescriptor(
      int num_arguments,
      const Array& optional_arguments_names);

  // Return true if the VM may optimize functions.
  static bool CanOptimize();

 private:
  // Forward declarations.
  class DescriptorList;

  DescriptorList* pc_descriptors_list_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(CodeGenerator);
};

}  // namespace dart

#endif  // VM_CODE_GENERATOR_ARM_H_
