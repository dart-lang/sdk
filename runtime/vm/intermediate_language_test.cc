// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr = new TargetEntryInstr();
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
  UseVal* use1a = new UseVal(def1);
  UseVal* use1b = new UseVal(def1);
  EXPECT(use1a->Equals(use1b));
  UseVal* use2 = new UseVal(def2);
  EXPECT(!use2->Equals(use1a));

  ConstantVal* c1 = new ConstantVal(Bool::ZoneHandle(Bool::True()));
  ConstantVal* c2 = new ConstantVal(Bool::ZoneHandle(Bool::True()));
  EXPECT(c1->Equals(c2));
  ConstantVal* c3 = new ConstantVal(Object::ZoneHandle());
  ConstantVal* c4 = new ConstantVal(Object::ZoneHandle());
  EXPECT(c3->Equals(c4));
  EXPECT(!c3->Equals(c1));
}

}  // namespace dart
