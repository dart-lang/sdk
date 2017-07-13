// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr = new TargetEntryInstr(
      1, CatchClauseNode::kInvalidTryIndex, Thread::kNoDeoptId);
  EXPECT(target_instr->IsBlockEntry());
  EXPECT(!target_instr->IsDefinition());
  SpecialParameterInstr* context = new SpecialParameterInstr(
      SpecialParameterInstr::kContext, Thread::kNoDeoptId);
  EXPECT(context->IsDefinition());
  EXPECT(!context->IsBlockEntry());
}

TEST_CASE(OptimizationTests) {
  JoinEntryInstr* join = new JoinEntryInstr(
      1, CatchClauseNode::kInvalidTryIndex, Thread::kNoDeoptId);

  Definition* def1 = new PhiInstr(join, 0);
  Definition* def2 = new PhiInstr(join, 0);
  Value* use1a = new Value(def1);
  Value* use1b = new Value(def1);
  EXPECT(use1a->Equals(use1b));
  Value* use2 = new Value(def2);
  EXPECT(!use2->Equals(use1a));

  ConstantInstr* c1 = new ConstantInstr(Bool::True());
  ConstantInstr* c2 = new ConstantInstr(Bool::True());
  EXPECT(c1->Equals(c2));
  ConstantInstr* c3 = new ConstantInstr(Object::ZoneHandle());
  ConstantInstr* c4 = new ConstantInstr(Object::ZoneHandle());
  EXPECT(c3->Equals(c4));
  EXPECT(!c3->Equals(c1));
}

}  // namespace dart
