// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_IA32_H_
#define VM_CODE_GENERATOR_IA32_H_

#ifndef VM_CODE_GENERATOR_H_
#error Do not include code_generator_ia32.h directly; use code_generator.h.
#endif

#include "vm/assembler.h"
#include "vm/ast.h"
#include "vm/growable_array.h"
#include "vm/parser.h"

namespace dart {

// Forward Declarations.
class Assembler;
class AstNode;
class CodeGeneratorState;
class SourceLabel;

class CodeGenerator : public AstNodeVisitor {
 public:
  CodeGenerator(Assembler* assembler, const ParsedFunction& parsed_function);
  virtual ~CodeGenerator() { }

  // Accessors.
  Assembler* assembler() const { return assembler_; }

  const ParsedFunction& parsed_function() const { return parsed_function_; }

  void GenerateCode();
  virtual void GenerateDeferredCode();

#define DEFINE_VISITOR_FUNCTION(type, name)                                    \
  virtual void Visit##type(type* node);
NODE_LIST(DEFINE_VISITOR_FUNCTION)
#undef DEFINE_VISITOR_FUNCTION

  CodeGeneratorState* state() const { return state_; }
  void set_state(CodeGeneratorState* state) { state_ = state; }

  // Add exception handler table to code.
  void FinalizeExceptionHandlers(const Code& code);

  // Add pc descriptors to code.
  void FinalizePcDescriptors(const Code& code);

  // Allocate and return an arguments descriptor.
  // Let 'num_names' be the length of 'optional_arguments_names'.
  // Treat the first 'num_arguments - num_names' arguments as positional and
  // treat the following 'num_names' arguments as named optional arguments.
  static const Array& ArgumentsDescriptor(
      int num_arguments,
      const Array& optional_arguments_names);

  virtual bool IsOptimizing() const {
    return false;
  }

  virtual void CountBackwardLoop();

 private:
  // TODO(srdjan): Remove the friendship once the two compilers are properly
  // structured.
  friend class OptimizingCodeGenerator;

  // Forward Declarations.
  class DescriptorList;
  class HandlerList;

  // Return true if intrinsification was completed and no other code
  // needs to be generated.
  virtual bool TryIntrinsify() { return false; }
  virtual void GeneratePreEntryCode();
  void GenerateLegacyEntryCode();
  void GenerateEntryCode();
  void GenerateLoadVariable(Register dst, const LocalVariable& local);
  void GeneratePushVariable(const LocalVariable& variable, Register scratch);
  void GenerateStoreVariable(const LocalVariable& local,
                             Register src,
                             Register scratch);
  void GenerateLogicalNotOp(UnaryOpNode* node);
  void GenerateLogicalAndOrOp(BinaryOpNode* node);
  void GenerateInstanceGetterCall(intptr_t node_id,
                                  intptr_t token_index,
                                  const String& field_name);
  void GenerateInstanceSetterCall(intptr_t node_id,
                                  intptr_t token_index,
                                  const String& field_name);
  void GenerateBinaryOperatorCall(intptr_t node_id,
                                  intptr_t token_index,
                                  const char* operator_name);
  void GenerateStaticGetterCall(intptr_t token_index,
                                const Class& field_class,
                                const String& field_name);
  void GenerateStaticSetterCall(intptr_t token_index,
                                const Class& field_class,
                                const String& field_name);
  void GenerateLoadIndexed(intptr_t node_id, intptr_t token_index);
  void GenerateStoreIndexed(intptr_t node_id,
                            intptr_t token_index,
                            bool preserve_value);

  void GenerateInstanceCall(intptr_t node_id,
                            intptr_t token_index,
                            const String& function_name,
                            int num_arguments,
                            const Array& optional_arguments_names);

  void GenerateInstanceOf(intptr_t node_id,
                          intptr_t token_index,
                          const Type& type,
                          bool negate_result);
  void GenerateAssertAssignable(intptr_t node_id,
                                intptr_t token_index,
                                const Type& dst_type,
                                const String& dst_name);
  void GenerateArgumentTypeChecks();
  void GenerateConditionTypeCheck(intptr_t node_id, intptr_t token_index);

  void GenerateInstantiatorTypeArguments(intptr_t token_index);
  void GenerateTypeArguments(ConstructorCallNode* node,
                             bool is_cls_parameterized);

  intptr_t locals_space_size() const { return locals_space_size_; }
  void set_locals_space_size(intptr_t value) { locals_space_size_ = value; }

  bool IsResultNeeded(AstNode* node) const;

  void GenerateCall(intptr_t token_index, const ExternalLabel* ext_label);
  void GenerateCallRuntime(intptr_t node_id,
                           intptr_t token_index,
                           const RuntimeEntry& entry);

  void GenerateInlinedFinallyBlocks(SourceLabel* label);

  void ErrorMsg(intptr_t token_index, const char* format, ...);

  int generate_next_try_index() { return try_index_ += 1; }

  void MarkDeoptPoint(intptr_t node_id, intptr_t token_index);
  void AddCurrentDescriptor(PcDescriptors::Kind kind,
                            intptr_t node_id,
                            intptr_t token_index);

  Assembler* assembler_;
  const ParsedFunction& parsed_function_;
  intptr_t locals_space_size_;
  CodeGeneratorState* state_;
  DescriptorList* pc_descriptors_list_;
  HandlerList* exception_handlers_list_;
  int try_index_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(CodeGenerator);
};


}  // namespace dart

#endif  // VM_CODE_GENERATOR_IA32_H_
