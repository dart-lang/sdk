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

}  // namespace dart
