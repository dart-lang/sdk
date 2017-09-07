// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_
#define RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"

namespace dart {

// Call specialization pass is responsible for replacing instance calls by
// faster alternatives based on type feedback (JIT), type speculations (AOT),
// locally propagated type information or global type information.
//
// This pass for example can
//
//    * Replace a call to a binary arithmetic operator with corresponding IL
//      instructions and necessary checks;
//    * Replace a dynamic call with a static call, if reciever is known
//      to have a certain class id;
//    * Replace type check with a range check
//
// CallSpecializer is a base class that contains logic shared between
// JIT and AOT compilation pipelines, see JitCallSpecializer for JIT specific
// optimizations and AotCallSpecializer for AOT specific optimizations.
class CallSpecializer : public FlowGraphVisitor {
 public:
  CallSpecializer(FlowGraph* flow_graph, bool should_clone_fields)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph),
        should_clone_fields_(should_clone_fields) {}

  virtual ~CallSpecializer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  // Use ICData to optimize, replace or eliminate instructions.
  void ApplyICData();

  // Use propagated class ids to optimize, replace or eliminate instructions.
  void ApplyClassIds();

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    FlowGraph::UseKind use_kind) {
    flow_graph_->InsertBefore(next, instr, env, use_kind);
  }

  virtual void VisitStaticCall(StaticCallInstr* instr);

  // TODO(dartbug.com/30633) these methods have nothing to do with
  // specialization of calls. They are here for historical reasons.
  // Find a better place for them.
  virtual void VisitLoadCodeUnits(LoadCodeUnitsInstr* instr);

 protected:
  Thread* thread() const { return flow_graph_->thread(); }
  Isolate* isolate() const { return flow_graph_->isolate(); }
  Zone* zone() const { return flow_graph_->zone(); }
  const Function& function() const { return flow_graph_->function(); }

  bool TryReplaceWithIndexedOp(InstanceCallInstr* call,
                               const ICData* unary_checks);

  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryReplaceWithEqualityOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithRelationalOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call,
                               const ICData& unary_ic_data);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);
  void ReplaceWithInstanceOf(InstanceCallInstr* instr);
  void ReplaceWithTypeCast(InstanceCallInstr* instr);

  void ReplaceCall(Definition* call, Definition* replacement);

  // Add a class check for the call's first argument (receiver).
  void AddReceiverCheck(InstanceCallInstr* call) {
    AddChecksForArgNr(call, call->ArgumentAt(0), /* argument_number = */ 0);
  }

  // Attempt to build ICData for call using propagated class-ids.
  virtual bool TryCreateICData(InstanceCallInstr* call);

  static bool HasOnlyTwoOf(const ICData& ic_data, intptr_t cid);

  virtual bool TryReplaceInstanceOfWithRangeCheck(InstanceCallInstr* call,
                                                  const AbstractType& type);

  virtual bool TryReplaceTypeCastWithRangeCheck(InstanceCallInstr* call,
                                                const AbstractType& type);

  virtual bool IsAllowedForInlining(intptr_t deopt_id) const = 0;

 private:
  bool TypeCheckAsClassEquality(const AbstractType& type);

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

  bool InlineFloat32x4BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool InlineInt32x4BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool InlineFloat64x2BinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryInlineImplicitInstanceGetter(InstanceCallInstr* call);

  RawBool* InstanceOfAsBool(const ICData& ic_data,
                            const AbstractType& type,
                            ZoneGrowableArray<intptr_t>* results) const;

  void ReplaceWithMathCFunction(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);

  bool TryStringLengthOneEquality(InstanceCallInstr* call, Token::Kind op_kind);

  RawField* GetField(intptr_t class_id, const String& field_name);

  void SpecializePolymorphicInstanceCall(PolymorphicInstanceCallInstr* call);

  // Tries to add cid tests to 'results' so that no deoptimization is
  // necessary for common number-related type tests.  Unconditionally adds an
  // entry for the Smi type to the start of the array.
  static bool SpecializeTestCidsForNumericTypes(
      ZoneGrowableArray<intptr_t>* results,
      const AbstractType& type);

  FlowGraph* flow_graph_;
  const bool should_clone_fields_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_CALL_SPECIALIZER_H_
