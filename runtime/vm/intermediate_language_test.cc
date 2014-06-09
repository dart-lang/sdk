// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intermediate_language.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr =
      new TargetEntryInstr(1, CatchClauseNode::kInvalidTryIndex);
  EXPECT(target_instr->IsBlockEntry());
  EXPECT(!target_instr->IsDefinition());
  CurrentContextInstr* context = new CurrentContextInstr();
  EXPECT(context->IsDefinition());
  EXPECT(!context->IsBlockEntry());
}


TEST_CASE(OptimizationTests) {
  JoinEntryInstr* join =
      new JoinEntryInstr(1, CatchClauseNode::kInvalidTryIndex);

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


TEST_CASE(RangeTests) {
  Range* zero = new Range(
      RangeBoundary::FromConstant(0),
      RangeBoundary::FromConstant(0));
  Range* positive = new Range(
      RangeBoundary::FromConstant(0),
      RangeBoundary::FromConstant(100));
  Range* negative = new Range(
      RangeBoundary::FromConstant(-1),
      RangeBoundary::FromConstant(-100));
  Range* range_x = new Range(
      RangeBoundary::FromConstant(-15),
      RangeBoundary::FromConstant(100));
  EXPECT(negative->IsNegative());
  EXPECT(positive->IsPositive());
  EXPECT(zero->Overlaps(0, 0));
  EXPECT(positive->Overlaps(0, 0));
  EXPECT(!negative->Overlaps(0, 0));
  EXPECT(range_x->Overlaps(0, 0));
  EXPECT(range_x->IsWithin(-15, 100));
  EXPECT(!range_x->IsWithin(-15, 99));
  EXPECT(!range_x->IsWithin(-14, 100));
}


TEST_CASE(RangeTestsInfinity) {
  // +/- inf overflowed.
  EXPECT(RangeBoundary::NegativeInfinity().Overflowed());
  EXPECT(RangeBoundary::PositiveInfinity().Overflowed());

  Range* all = new Range(RangeBoundary::NegativeInfinity(),
                         RangeBoundary::PositiveInfinity());
  EXPECT(all->Overlaps(0, 0));
  EXPECT(all->Overlaps(-1, 1));
  EXPECT(!all->IsWithin(0, 100));
  Range* positive = new Range(RangeBoundary::FromConstant(0),
                              RangeBoundary::PositiveInfinity());
  EXPECT(positive->IsPositive());
  EXPECT(!positive->IsNegative());
  EXPECT(positive->Overlaps(0, 1));
  EXPECT(positive->Overlaps(1, 100));
  EXPECT(positive->Overlaps(-1, 0));
  EXPECT(!positive->Overlaps(-2, -1));
  Range* negative = new Range(RangeBoundary::NegativeInfinity(),
                              RangeBoundary::FromConstant(-1));
  EXPECT(negative->IsNegative());
  EXPECT(!negative->IsPositive());
  EXPECT(!negative->Overlaps(0, 1));
  EXPECT(!negative->Overlaps(1, 100));
  EXPECT(negative->Overlaps(-1, 0));
  EXPECT(negative->Overlaps(-2, -1));
  Range* negpos = new Range(RangeBoundary::NegativeInfinity(),
                            RangeBoundary::FromConstant(0));
  EXPECT(!negpos->IsNegative());
  EXPECT(!negpos->IsPositive());

  Range* a = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(1));

  Range* b = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(31));

  Range* c = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(32));

  EXPECT(a->OnlyLessThanOrEqualTo(31));
  EXPECT(b->OnlyLessThanOrEqualTo(31));
  EXPECT(!c->OnlyLessThanOrEqualTo(31));

  Range* unsatisfiable = new Range(RangeBoundary::PositiveInfinity(),
                                   RangeBoundary::NegativeInfinity());
  EXPECT(unsatisfiable->IsUnsatisfiable());

  Range* unsatisfiable_right = new Range(RangeBoundary::PositiveInfinity(),
                                         RangeBoundary::FromConstant(0));
  EXPECT(unsatisfiable_right->IsUnsatisfiable());

  Range* unsatisfiable_left = new Range(RangeBoundary::FromConstant(0),
                                        RangeBoundary::NegativeInfinity());
  EXPECT(unsatisfiable_left->IsUnsatisfiable());
}

}  // namespace dart
