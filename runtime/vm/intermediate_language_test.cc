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

TEST_CASE(DefUseTests) {
  Definition* def1 = new PhiInstr(0);
  Definition* def2 = new PhiInstr(0);
  EXPECT(def1->use_list() == NULL);
  EXPECT(def2->use_list() == NULL);
  UseVal* use1 = new UseVal(def1);
  EXPECT(def1->use_list() == use1);
  EXPECT(def1->use_list()->next_use() == NULL);
  UseVal* use2 = new UseVal(def1);
  EXPECT(def1->use_list()->next_use()->next_use() == NULL);
  UseVal* use3 = new UseVal(def1);
  EXPECT(def1->use_list()->next_use()->next_use()->next_use() == NULL);
  use1->RemoveFromUseList();
  EXPECT(def1->use_list()->next_use()->next_use() == NULL);
  use3->SetDefinition(def2);
  EXPECT(def1->use_list() == use2);
  EXPECT(def1->use_list()->next_use() == NULL);
  EXPECT(def2->use_list() == use3);
  EXPECT(def2->use_list()->next_use() == NULL);
  BindInstr* bind = new BindInstr(BindInstr::kUsed, use2);
  bind->RemoveInputUses();
  EXPECT(def1->use_list() == NULL);
  // Test replacing with a definition without uses.
  UseVal* use4 = new UseVal(def2);
  def2->ReplaceUsesWith(def1);
  EXPECT(def1->use_list() == use4);
  EXPECT(def2->use_list() == NULL);
  EXPECT(use4->definition() == def1);
}

}  // namespace dart
