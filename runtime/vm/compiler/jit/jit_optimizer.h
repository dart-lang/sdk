// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_JIT_JIT_OPTIMIZER_H_
#define RUNTIME_VM_COMPILER_JIT_JIT_OPTIMIZER_H_

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

class CSEInstructionMap;
template <typename T>
class GrowableArray;
class ParsedFunction;

class JitOptimizer : public FlowGraphVisitor {
 public:
  explicit JitOptimizer(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph) {}

  virtual ~JitOptimizer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  // Use ICData to optimize, replace or eliminate instructions.
  void ApplyICData();

  // Use propagated class ids to optimize, replace or eliminate instructions.
  void ApplyClassIds();

  virtual void VisitStaticCall(StaticCallInstr* instr);
  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitStoreInstanceField(StoreInstanceFieldInstr* instr);
  virtual void VisitAllocateContext(AllocateContextInstr* instr);
  virtual void VisitLoadCodeUnits(LoadCodeUnitsInstr* instr);

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    FlowGraph::UseKind use_kind) {
    flow_graph_->InsertBefore(next, instr, env, use_kind);
  }

 private:
  // Attempt to build ICData for call using propagated class-ids.
  bool TryCreateICData(InstanceCallInstr* call);

  void SpecializePolymorphicInstanceCall(PolymorphicInstanceCallInstr* call);

  bool TryReplaceWithIndexedOp(InstanceCallInstr* call);

  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryReplaceWithEqualityOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithRelationalOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call,
                               const ICData& unary_ic_data);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);
  void ReplaceWithInstanceOf(InstanceCallInstr* instr);
  bool TypeCheckAsClassEquality(const AbstractType& type);
  void ReplaceWithTypeCast(InstanceCallInstr* instr);

  bool TryReplaceInstanceCallWithInline(InstanceCallInstr* call);

  // Insert a check of 'to_check' determined by 'unary_checks'.  If the
  // check fails it will deoptimize to 'deopt_id' using the deoptimization
  // environment 'deopt_environment'.  The check is inserted immediately
  // before 'insert_before'.
  void AddCheckClass(Definition* to_check,
                     const Cids& cids,
                     intptr_t deopt_id,
                     Environment* deopt_environment,
                     Instruction* insert_before);

  // Insert a Smi check if needed.
  void AddCheckSmi(Definition* to_check,
                   intptr_t deopt_id,
                   Environment* deopt_environment,
                   Instruction* insert_before);

  // Add a class check for a call's nth argument immediately before the
  // call, using the call's IC data to determine the check, and the call's
  // deopt ID and deoptimization environment if the check fails.
  void AddChecksForArgNr(InstanceCallInstr* call,
                         Definition* instr,
                         int argument_number);

  // Add a class check for the call's first argument (receiver).
  void AddReceiverCheck(InstanceCallInstr* call) {
    AddChecksForArgNr(call, call->ArgumentAt(0), /* argument_number = */ 0);
  }

  void ReplaceCall(Definition* call, Definition* replacement);

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call,
                                   RawFunction::Kind kind) const;

  bool InlineFloat32x4BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool InlineInt32x4BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool InlineFloat64x2BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool InlineImplicitInstanceGetter(InstanceCallInstr* call);

  RawBool* InstanceOfAsBool(const ICData& ic_data,
                            const AbstractType& type,
                            ZoneGrowableArray<intptr_t>* results) const;

  void ReplaceWithMathCFunction(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);

  bool TryStringLengthOneEquality(InstanceCallInstr* call, Token::Kind op_kind);

  RawField* GetField(intptr_t class_id, const String& field_name);

  Thread* thread() const { return flow_graph_->thread(); }
  Isolate* isolate() const { return flow_graph_->isolate(); }
  Zone* zone() const { return flow_graph_->zone(); }

  const Function& function() const { return flow_graph_->function(); }

  FlowGraph* flow_graph_;

  DISALLOW_COPY_AND_ASSIGN(JitOptimizer);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_JIT_JIT_OPTIMIZER_H_
