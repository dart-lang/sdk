// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_
#define RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_

#include "vm/compiler/call_specializer.h"

namespace dart {

class Precompiler;
class SpeculativeInliningPolicy;

class AotCallSpecializer : public CallSpecializer {
 public:
  AotCallSpecializer(Precompiler* precompiler,
                     FlowGraph* flow_graph,
                     SpeculativeInliningPolicy* speculative_policy);

  virtual ~AotCallSpecializer() {}

  // TODO(dartbug.com/30633) these method has nothing to do with
  // specialization of calls. They are here for historical reasons.
  // Find a better place for them.
  static void ReplaceArrayBoundChecks(FlowGraph* flow_graph);

  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitStaticCall(StaticCallInstr* instr);
  virtual void VisitPolymorphicInstanceCall(
      PolymorphicInstanceCallInstr* instr);

  virtual bool TryReplaceInstanceOfWithRangeCheck(InstanceCallInstr* call,
                                                  const AbstractType& type);
  virtual bool TryReplaceTypeCastWithRangeCheck(InstanceCallInstr* call,
                                                const AbstractType& type);

 private:
  // Attempt to build ICData for call using propagated class-ids.
  virtual bool TryCreateICData(InstanceCallInstr* call);

  bool TryCreateICDataForUniqueTarget(InstanceCallInstr* call);

  bool RecognizeRuntimeTypeGetter(InstanceCallInstr* call);
  bool TryReplaceWithHaveSameRuntimeType(TemplateDartCall<0>* call);

  bool TryInlineFieldAccess(InstanceCallInstr* call);
  bool TryInlineFieldAccess(StaticCallInstr* call);

  bool IsSupportedIntOperandForStaticDoubleOp(CompileType* operand_type);
  Value* PrepareStaticOpInput(Value* input, intptr_t cid, Instruction* call);

  Value* PrepareReceiverOfDevirtualizedCall(Value* input, intptr_t cid);

  bool TryOptimizeInstanceCallUsingStaticTypes(InstanceCallInstr* instr);

  virtual bool TryOptimizeStaticCallUsingStaticTypes(StaticCallInstr* call);

  // Check if o.m(...) [call] is actually an invocation through a getter
  // o.get:m().call(...) given that the receiver of the call is a subclass
  // of the [receiver_class]. If it is - then expand it into
  // o.get:m.call(...) to avoid hitting dispatch through noSuchMethod.
  bool TryExpandCallThroughGetter(const Class& receiver_class,
                                  InstanceCallInstr* call);

  Precompiler* precompiler_;

  bool has_unique_no_such_method_;

  DISALLOW_COPY_AND_ASSIGN(AotCallSpecializer);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_
