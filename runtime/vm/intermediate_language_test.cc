// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr =
      new TargetEntryInstr(CatchClauseNode::kInvalidTryIndex);
  EXPECT(target_instr->IsBlockEntry());
  EXPECT(!target_instr->IsBind());
  BindInstr* bind_instr =
      new BindInstr(BindInstr::kUnused, new CurrentContextComp());
  EXPECT(bind_instr->IsBind());
  EXPECT(!bind_instr->IsBlockEntry());
}


TEST_CASE(OptimizationTests) {
  Definition* def1 = new PhiInstr(0);
  Definition* def2 = new PhiInstr(0);
  Value* use1a = new Value(def1);
  Value* use1b = new Value(def1);
  EXPECT(use1a->Equals(use1b));
  Value* use2 = new Value(def2);
  EXPECT(!use2->Equals(use1a));

  ConstantComp* c1 = new ConstantComp(Bool::ZoneHandle(Bool::True()));
  ConstantComp* c2 = new ConstantComp(Bool::ZoneHandle(Bool::True()));
  EXPECT(c1->Equals(c2));
  ConstantComp* c3 = new ConstantComp(Object::ZoneHandle());
  ConstantComp* c4 = new ConstantComp(Object::ZoneHandle());
  EXPECT(c3->Equals(c4));
  EXPECT(!c3->Equals(c1));
}

}  // namespace dart
