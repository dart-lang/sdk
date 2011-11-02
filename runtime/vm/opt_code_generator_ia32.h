// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OPT_CODE_GENERATOR_IA32_H_
#define VM_OPT_CODE_GENERATOR_IA32_H_

#ifndef VM_OPT_CODE_GENERATOR_H_
#error Do not include opt_code_generator_ia32.h; use opt_code_generator.h.
#endif

#include "vm/code_generator.h"

namespace dart {

// Forward declarations.
class DeoptimizationBlob;

// Temporary hierarchy, until optimized code generator implemented.
// The optimizing compiler does not run if type checks are enabled.
class OptimizingCodeGenerator : public CodeGenerator {
 public:
  OptimizingCodeGenerator(Assembler* assembler,
                          const ParsedFunction& parsed_function);

  virtual void VisitBinaryOpNode(BinaryOpNode* node);
  virtual void VisitIncrOpLocalNode(IncrOpLocalNode* node);
  virtual void VisitIncrOpInstanceFieldNode(IncrOpInstanceFieldNode* node);
  virtual void VisitInstanceGetterNode(InstanceGetterNode* node);
  virtual void VisitInstanceSetterNode(InstanceSetterNode* node);
  virtual void VisitComparisonNode(ComparisonNode* node);
  virtual void VisitLoadIndexedNode(LoadIndexedNode* node);
  virtual void VisitStoreIndexedNode(StoreIndexedNode* node);
  virtual void VisitLiteralNode(LiteralNode* node);
  virtual void VisitLoadLocalNode(LoadLocalNode* node);
  virtual void VisitStoreLocalNode(StoreLocalNode* node);
  virtual void VisitForNode(ForNode* node);
  virtual void VisitDoWhileNode(DoWhileNode* node);
  virtual void VisitWhileNode(WhileNode* node);
  virtual void VisitIfNode(IfNode* node);
  virtual void VisitInstanceCallNode(InstanceCallNode* node);
  virtual void VisitStaticCallNode(StaticCallNode* node);

  // Return true if intrinsification succeeded and no more code is needed.
  // Returns false if either no intrinsification occured or if intrinsified
  // code needs the rest for slow case execution.
  virtual bool TryIntrinsify();
  virtual void GeneratePreEntryCode();
  virtual bool IsOptimizing() const { return true; }

  virtual void CountBackwardLoop() {}
  virtual void GenerateDeferredCode();

 private:
  friend class DeoptimizationBlob;

  DeoptimizationBlob* AddDeoptimizationBlob(AstNode* node);
  DeoptimizationBlob* AddDeoptimizationBlob(AstNode* node,
                                            Register reg1);
  DeoptimizationBlob* AddDeoptimizationBlob(AstNode* node,
                                            Register reg1,
                                            Register reg2);
  DeoptimizationBlob* AddDeoptimizationBlob(AstNode* node,
                                            Register reg1,
                                            Register reg2,
                                            Register reg3);

  void IntrinsifyGetter();
  void IntrinsifySetter();

  bool ICDataToSameInlineableInstanceGetter(const ICData& ic_data);
  void InlineInstanceGettersWithSameTarget(AstNode* node,
                                           AstNode* receiver,
                                           const String& field_name,
                                           Register recv_reg);

  // Helper method to load a value quickly into register instead of pushing
  // and popping it.
  void VisitLoadOne(AstNode* node, Register reg);
  void VisitLoadTwo(AstNode* left,
                    AstNode* right,
                    Register left_reg,
                    Register right_reg);

  bool IsInlineableInstanceGetter(const Function& function);
  void InlineInstanceGetter(AstNode* node,
                            intptr_t id,
                            AstNode* receiver,
                            const String& field_name,
                            Register recv_reg);

  void CallDeoptimize(intptr_t node_id, intptr_t token_index);

  void GenerateSmiBinaryOp(BinaryOpNode* node);
  void GenerateSmiShiftBinaryOp(BinaryOpNode* node);

  void GenerateDoubleBinaryOp(BinaryOpNode* node);
  void GenerateMintBinaryOp(BinaryOpNode* node, bool allow_smi);
  void CheckIfDoubleOrSmi(Register reg,
                          Register temp,
                          Label* is_smi,
                          Label* not_double_or_smi);
  void GenerateDirectCall(intptr_t node_id,
                          intptr_t token_index,
                          Function& target,
                          intptr_t arg_count,
                          const Array& optional_argument_names);
  void GenerateCheckedInstanceCalls(AstNode* node,
                                    AstNode* receiver,
                                    intptr_t node_id,
                                    intptr_t token_index,
                                    intptr_t num_args,
                                    const Array& optional_argument_names);
  bool GenerateSmiComparison(ComparisonNode* node);
  void GenerateSmiEquality(ComparisonNode* node);
  bool GenerateDoubleComparison(ComparisonNode* node);
  bool GenerateEqualityComparison(ComparisonNode* node);
  void GenerateLogicalBinaryOp(BinaryOpNode* node);
  void GenerateConditionalJumps(const CodeGenInfo& nInfo, Condition condition);
  bool TryInlineInstanceCall(InstanceCallNode* node);
  bool TryInlineStaticCall(StaticCallNode* node);

  bool IsResultInEaxRequested(AstNode* node) const;
  bool NodeMayBeSmi(AstNode* node) const;

  void PrintCollectedClasses(AstNode* node);
  void TraceOpt(AstNode* node, const char* message);
  void TraceNotOpt(AstNode* node, const char* message);

  GrowableArray<DeoptimizationBlob*> deoptimization_blobs_;
  const Class& smi_class_;
  const Class& double_class_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(OptimizingCodeGenerator);
};

}  // namespace dart


#endif  // VM_OPT_CODE_GENERATOR_IA32_H_
