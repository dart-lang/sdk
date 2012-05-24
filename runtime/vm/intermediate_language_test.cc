// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr = new TargetEntryInstr();
  EXPECT(target_instr->IsBlockEntry());
  EXPECT(!target_instr->IsDo());
  EXPECT(!target_instr->IsBind());
  DoInstr* do_instr = new DoInstr(new CurrentContextComp());
  EXPECT(do_instr->IsDo());
  EXPECT(!do_instr->IsBlockEntry());
  EXPECT(!do_instr->IsBind());
}

}  // namespace dart
