// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/range_analysis.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(RangeTests) {
  Range* zero =
      new Range(RangeBoundary::FromConstant(0), RangeBoundary::FromConstant(0));
  Range* positive = new Range(RangeBoundary::FromConstant(0),
                              RangeBoundary::FromConstant(100));
  Range* negative = new Range(RangeBoundary::FromConstant(-1),
                              RangeBoundary::FromConstant(-100));
  Range* range_x = new Range(RangeBoundary::FromConstant(-15),
                             RangeBoundary::FromConstant(100));
  EXPECT(positive->IsPositive());
  EXPECT(zero->Overlaps(0, 0));
  EXPECT(positive->Overlaps(0, 0));
  EXPECT(!negative->Overlaps(0, 0));
  EXPECT(range_x->Overlaps(0, 0));
  EXPECT(range_x->IsWithin(-15, 100));
  EXPECT(!range_x->IsWithin(-15, 99));
  EXPECT(!range_x->IsWithin(-14, 100));

#define TEST_RANGE_OP_(Op, l_min, l_max, r_min, r_max, Clamp, res_min,         \
                       res_max)                                                \
  {                                                                            \
    RangeBoundary min, max;                                                    \
    Range* left_range = new Range(RangeBoundary::FromConstant(l_min),          \
                                  RangeBoundary::FromConstant(l_max));         \
    Range* shift_range = new Range(RangeBoundary::FromConstant(r_min),         \
                                   RangeBoundary::FromConstant(r_max));        \
    Op(left_range, shift_range, &min, &max);                                   \
    min = Clamp(min);                                                          \
    max = Clamp(max);                                                          \
    EXPECT(min.Equals(res_min));                                               \
    if (FLAG_support_il_printer && !min.Equals(res_min)) {                     \
      OS::PrintErr("%s\n", min.ToCString());                                   \
    }                                                                          \
    EXPECT(max.Equals(res_max));                                               \
    if (FLAG_support_il_printer && !max.Equals(res_max)) {                     \
      OS::PrintErr("%s\n", max.ToCString());                                   \
    }                                                                          \
  }

#define NO_CLAMP(b) (b)
#define TEST_RANGE_OP(Op, l_min, l_max, r_min, r_max, result_min, result_max)  \
  TEST_RANGE_OP_(Op, l_min, l_max, r_min, r_max, NO_CLAMP, result_min,         \
                 result_max)

#define CLAMP_TO_SMI(b) (b.Clamp(RangeBoundary::kRangeBoundarySmi))
#define TEST_RANGE_OP_SMI(Op, l_min, l_max, r_min, r_max, res_min, res_max)    \
  TEST_RANGE_OP_(Op, l_min, l_max, r_min, r_max, CLAMP_TO_SMI, res_min, res_max)

  TEST_RANGE_OP(Range::Shl, -15, 100, 0, 2, RangeBoundary(-60),
                RangeBoundary(400));
  TEST_RANGE_OP(Range::Shl, -15, 100, -2, 2, RangeBoundary(-60),
                RangeBoundary(400));
  TEST_RANGE_OP(Range::Shl, -15, -10, 1, 2, RangeBoundary(-60),
                RangeBoundary(-20));
  TEST_RANGE_OP(Range::Shl, 5, 10, -2, 2, RangeBoundary(5), RangeBoundary(40));
  TEST_RANGE_OP(Range::Shl, -15, 100, 0, 64, RangeBoundary::NegativeInfinity(),
                RangeBoundary::PositiveInfinity());
  TEST_RANGE_OP(Range::Shl, -1, 1, 63, 63, RangeBoundary(kMinInt64),
                RangeBoundary::PositiveInfinity());
  if (kBitsPerWord == 64) {
    TEST_RANGE_OP_SMI(Range::Shl, -1, 1, 62, 62,
                      RangeBoundary(compiler::target::kSmiMin),
                      RangeBoundary(compiler::target::kSmiMax));
    TEST_RANGE_OP_SMI(Range::Shl, -1, 1, 30, 30, RangeBoundary(-(1 << 30)),
                      RangeBoundary(1 << 30));
  } else {
    TEST_RANGE_OP_SMI(Range::Shl, -1, 1, 30, 30,
                      RangeBoundary(compiler::target::kSmiMin),
                      RangeBoundary(compiler::target::kSmiMax));
    TEST_RANGE_OP_SMI(Range::Shl, -1, 1, 62, 62,
                      RangeBoundary(compiler::target::kSmiMin),
                      RangeBoundary(compiler::target::kSmiMax));
  }
  TEST_RANGE_OP(Range::Shl, 0, 100, 0, 64, RangeBoundary(0),
                RangeBoundary::PositiveInfinity());
  TEST_RANGE_OP(Range::Shl, -100, 0, 0, 64, RangeBoundary::NegativeInfinity(),
                RangeBoundary(0));

  TEST_RANGE_OP(Range::Shr, -8, 8, 1, 2, RangeBoundary(-4), RangeBoundary(4));
  TEST_RANGE_OP(Range::Shr, 1, 8, 1, 2, RangeBoundary(0), RangeBoundary(4));
  TEST_RANGE_OP(Range::Shr, -16, -8, 1, 2, RangeBoundary(-8),
                RangeBoundary(-2));
  TEST_RANGE_OP(Range::Shr, 2, 4, -1, 1, RangeBoundary(1), RangeBoundary(4));
  TEST_RANGE_OP(Range::Shr, kMaxInt64, kMaxInt64, 0, 1,
                RangeBoundary(kMaxInt64 >> 1), RangeBoundary(kMaxInt64));
  TEST_RANGE_OP(Range::Shr, kMinInt64, kMinInt64, 0, 1,
                RangeBoundary(kMinInt64), RangeBoundary(kMinInt64 >> 1));
#undef TEST_RANGE_OP
}

TEST_CASE(RangeTestsInfinity) {
  // +/- inf overflowed.
  EXPECT(RangeBoundary::NegativeInfinity().OverflowedSmi());
  EXPECT(RangeBoundary::PositiveInfinity().OverflowedSmi());

  EXPECT(RangeBoundary::NegativeInfinity().OverflowedMint());
  EXPECT(RangeBoundary::PositiveInfinity().OverflowedMint());

  const Range fullInt64Range = Range::Full(RangeBoundary::kRangeBoundaryInt64);

  Range* all = new Range(RangeBoundary::NegativeInfinity(),
                         RangeBoundary::PositiveInfinity());
  EXPECT(all->Equals(&fullInt64Range));
  EXPECT(all->Overlaps(0, 0));
  EXPECT(all->Overlaps(-1, 1));
  EXPECT(!all->IsWithin(0, 100));

  Range* positive = new Range(RangeBoundary::FromConstant(0),
                              RangeBoundary::PositiveInfinity());
  EXPECT(positive->Equals(&fullInt64Range));
  EXPECT(positive->Overlaps(0, 1));
  EXPECT(positive->Overlaps(1, 100));
  EXPECT(positive->Overlaps(-1, 0));

  Range* negative = new Range(RangeBoundary::NegativeInfinity(),
                              RangeBoundary::FromConstant(-1));
  EXPECT(positive->Equals(&fullInt64Range));
  EXPECT(negative->Overlaps(-1, 0));
  EXPECT(negative->Overlaps(-2, -1));

  Range* negpos = new Range(RangeBoundary::NegativeInfinity(),
                            RangeBoundary::FromConstant(0));
  EXPECT(negpos->Equals(&fullInt64Range));
  EXPECT(!negpos->IsPositive());

  Range* a = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(1));

  Range* b = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(31));

  Range* c = new Range(RangeBoundary::NegativeInfinity(),
                       RangeBoundary::FromConstant(32));

  EXPECT(a->Equals(&fullInt64Range));
  EXPECT(b->Equals(&fullInt64Range));
  EXPECT(c->Equals(&fullInt64Range));
  EXPECT(!c->OnlyLessThanOrEqualTo(31));

  Range* unsatisfiable = new Range(RangeBoundary::PositiveInfinity(),
                                   RangeBoundary::NegativeInfinity());
  EXPECT(unsatisfiable->Equals(&fullInt64Range));

  Range* unsatisfiable_right = new Range(RangeBoundary::PositiveInfinity(),
                                         RangeBoundary::FromConstant(0));
  EXPECT(unsatisfiable_right->Equals(&fullInt64Range));

  Range* unsatisfiable_left = new Range(RangeBoundary::FromConstant(0),
                                        RangeBoundary::NegativeInfinity());
  EXPECT(unsatisfiable_left->Equals(&fullInt64Range));
}

TEST_CASE(RangeUtils) {
  // Use kMin/kMax instead of +/-inf as any range with a +/-inf bound is
  // converted to the full int64 range due to wrap-around.
  const RangeBoundary negativeInfinity =
      RangeBoundary::FromConstant(RangeBoundary::kMin);
  const RangeBoundary positiveInfinity =
      RangeBoundary::FromConstant(RangeBoundary::kMax);

  // [-inf, +inf].
  const Range& range_0 = *(new Range(negativeInfinity, positiveInfinity));
  // [-inf, -1].
  const Range& range_a =
      *(new Range(negativeInfinity, RangeBoundary::FromConstant(-1)));
  // [-inf, 0].
  const Range& range_b =
      *(new Range(negativeInfinity, RangeBoundary::FromConstant(0)));
  // [-inf, 1].
  const Range& range_c =
      *(new Range(negativeInfinity, RangeBoundary::FromConstant(1)));
  // [-1, +inf]
  const Range& range_d =
      *(new Range(RangeBoundary::FromConstant(-1), positiveInfinity));
  // [0, +inf]
  const Range& range_e =
      *(new Range(RangeBoundary::FromConstant(0), positiveInfinity));
  // [1, +inf].
  const Range& range_f =
      *(new Range(RangeBoundary::FromConstant(1), positiveInfinity));
  // [1, 2].
  const Range& range_g = *(new Range(RangeBoundary::FromConstant(1),
                                     RangeBoundary::FromConstant(2)));
  // [-1, -2].
  const Range& range_h = *(new Range(RangeBoundary::FromConstant(-1),
                                     RangeBoundary::FromConstant(-2)));
  // [-1, 1].
  const Range& range_i = *(new Range(RangeBoundary::FromConstant(-1),
                                     RangeBoundary::FromConstant(1)));

  // OnlyPositiveOrZero.
  EXPECT(!Range::OnlyPositiveOrZero(range_a, range_b));
  EXPECT(!Range::OnlyPositiveOrZero(range_b, range_c));
  EXPECT(!Range::OnlyPositiveOrZero(range_c, range_d));
  EXPECT(!Range::OnlyPositiveOrZero(range_d, range_e));
  EXPECT(Range::OnlyPositiveOrZero(range_e, range_f));
  EXPECT(!Range::OnlyPositiveOrZero(range_d, range_d));
  EXPECT(Range::OnlyPositiveOrZero(range_e, range_e));
  EXPECT(Range::OnlyPositiveOrZero(range_f, range_g));
  EXPECT(!Range::OnlyPositiveOrZero(range_g, range_h));
  EXPECT(!Range::OnlyPositiveOrZero(range_i, range_i));

  // OnlyNegativeOrZero.
  EXPECT(Range::OnlyNegativeOrZero(range_a, range_b));
  EXPECT(!Range::OnlyNegativeOrZero(range_b, range_c));
  EXPECT(Range::OnlyNegativeOrZero(range_b, range_b));
  EXPECT(!Range::OnlyNegativeOrZero(range_c, range_c));
  EXPECT(!Range::OnlyNegativeOrZero(range_c, range_d));
  EXPECT(!Range::OnlyNegativeOrZero(range_d, range_e));
  EXPECT(!Range::OnlyNegativeOrZero(range_e, range_f));
  EXPECT(!Range::OnlyNegativeOrZero(range_f, range_g));
  EXPECT(!Range::OnlyNegativeOrZero(range_g, range_h));
  EXPECT(Range::OnlyNegativeOrZero(range_h, range_h));
  EXPECT(!Range::OnlyNegativeOrZero(range_i, range_i));

  // [-inf, +inf].
  EXPECT(!Range::OnlyNegativeOrZero(range_0, range_0));
  EXPECT(!Range::OnlyPositiveOrZero(range_0, range_0));

  EXPECT(Range::ConstantAbsMax(&range_0) == RangeBoundary::kMax);
  EXPECT(Range::ConstantAbsMax(&range_h) == 2);
  EXPECT(Range::ConstantAbsMax(&range_i) == 1);

  // RangeBOundary.Equals.
  EXPECT(RangeBoundary::FromConstant(1).Equals(RangeBoundary::FromConstant(1)));
  EXPECT(
      !RangeBoundary::FromConstant(2).Equals(RangeBoundary::FromConstant(1)));
  EXPECT(RangeBoundary::PositiveInfinity().Equals(
      RangeBoundary::PositiveInfinity()));
  EXPECT(!RangeBoundary::PositiveInfinity().Equals(
      RangeBoundary::NegativeInfinity()));
  EXPECT(RangeBoundary::NegativeInfinity().Equals(
      RangeBoundary::NegativeInfinity()));
  EXPECT(!RangeBoundary::NegativeInfinity().Equals(
      RangeBoundary::PositiveInfinity()));
  EXPECT(!RangeBoundary::FromConstant(1).Equals(
      RangeBoundary::NegativeInfinity()));
  EXPECT(!RangeBoundary::FromConstant(1).Equals(
      RangeBoundary::NegativeInfinity()));
  EXPECT(!RangeBoundary::FromConstant(2).Equals(
      RangeBoundary::PositiveInfinity()));
}

TEST_CASE(RangeBinaryOp) {
  Range* range_a = new Range(RangeBoundary::FromConstant(-1),
                             RangeBoundary::FromConstant(RangeBoundary::kMax));
  range_a->Clamp(RangeBoundary::kRangeBoundaryInt32);
  EXPECT(range_a->min().ConstantValue() == -1);
  EXPECT(range_a->max().ConstantValue() == kMaxInt32);
  range_a->set_max(RangeBoundary::FromConstant(RangeBoundary::kMax));

  Range* range_b = new Range(RangeBoundary::FromConstant(RangeBoundary::kMin),
                             RangeBoundary::FromConstant(1));
  range_b->Clamp(RangeBoundary::kRangeBoundaryInt32);
  EXPECT(range_b->min().ConstantValue() == kMinInt32);
  EXPECT(range_b->max().ConstantValue() == 1);
  range_b->set_min(RangeBoundary::FromConstant(RangeBoundary::kMin));

  {
    Range result;
    Range::BinaryOp(Token::kADD, range_a, range_b, NULL, &result);
    ASSERT(!Range::IsUnknown(&result));
    EXPECT(!result.min().IsNegativeInfinity());
    EXPECT(!result.max().IsPositiveInfinity());
    EXPECT(result.min().Equals(
        RangeBoundary::MinConstant(RangeBoundary::kRangeBoundaryInt64)));
    EXPECT(result.max().Equals(
        RangeBoundary::MaxConstant(RangeBoundary::kRangeBoundaryInt64)));
  }

  // Test that [5, 10] + [0, 5] = [5, 15].
  Range* range_c = new Range(RangeBoundary::FromConstant(5),
                             RangeBoundary::FromConstant(10));
  Range* range_d =
      new Range(RangeBoundary::FromConstant(0), RangeBoundary::FromConstant(5));

  {
    Range result;
    Range::BinaryOp(Token::kADD, range_c, range_d, NULL, &result);
    ASSERT(!Range::IsUnknown(&result));
    EXPECT(result.min().ConstantValue() == 5);
    EXPECT(result.max().ConstantValue() == 15);
  }

  // Test that [0xff, 0xfff] & [0xf, 0xf] = [0x0, 0xf].
  Range* range_e = new Range(RangeBoundary::FromConstant(0xff),
                             RangeBoundary::FromConstant(0xfff));
  Range* range_f = new Range(RangeBoundary::FromConstant(0xf),
                             RangeBoundary::FromConstant(0xf));
  {
    Range result;
    Range::BinaryOp(Token::kBIT_AND, range_e, range_f, NULL, &result);
    ASSERT(!Range::IsUnknown(&result));
    EXPECT(result.min().ConstantValue() == 0x0);
    EXPECT(result.max().ConstantValue() == 0xf);
  }
}

TEST_CASE(RangeAdd) {
#define TEST_RANGE_ADD(l_min, l_max, r_min, r_max, result_min, result_max)     \
  {                                                                            \
    RangeBoundary min, max;                                                    \
    Range* left_range = new Range(RangeBoundary::FromConstant(l_min),          \
                                  RangeBoundary::FromConstant(l_max));         \
    Range* right_range = new Range(RangeBoundary::FromConstant(r_min),         \
                                   RangeBoundary::FromConstant(r_max));        \
    EXPECT(left_range->min().ConstantValue() == l_min);                        \
    EXPECT(left_range->max().ConstantValue() == l_max);                        \
    EXPECT(right_range->min().ConstantValue() == r_min);                       \
    EXPECT(right_range->max().ConstantValue() == r_max);                       \
    Range::Add(left_range, right_range, &min, &max, NULL);                     \
    EXPECT(min.Equals(result_min));                                            \
    if (FLAG_support_il_printer && !min.Equals(result_min)) {                  \
      OS::PrintErr("%s != %s\n", min.ToCString(), result_min.ToCString());     \
    }                                                                          \
    EXPECT(max.Equals(result_max));                                            \
    if (FLAG_support_il_printer && !max.Equals(result_max)) {                  \
      OS::PrintErr("%s != %s\n", max.ToCString(), result_max.ToCString());     \
    }                                                                          \
  }

  // [kMaxInt32, kMaxInt32 + 15] + [10, 20] = [kMaxInt32 + 10, kMaxInt32 + 35].
  TEST_RANGE_ADD(static_cast<int64_t>(kMaxInt32),
                 static_cast<int64_t>(kMaxInt32) + 15, static_cast<int64_t>(10),
                 static_cast<int64_t>(20),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 10),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 35));

  // [kMaxInt32 - 15, kMaxInt32 + 15] + [15, -15] = [kMaxInt32, kMaxInt32].
  TEST_RANGE_ADD(static_cast<int64_t>(kMaxInt32) - 15,
                 static_cast<int64_t>(kMaxInt32) + 15, static_cast<int64_t>(15),
                 static_cast<int64_t>(-15),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32)),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32)));

  // [kMaxInt32, kMaxInt32 + 15] + [10, kMaxInt64] = [kMaxInt32 + 10, +inf].
  TEST_RANGE_ADD(static_cast<int64_t>(kMaxInt32),
                 static_cast<int64_t>(kMaxInt32) + 15, static_cast<int64_t>(10),
                 static_cast<int64_t>(kMaxInt64),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 10),
                 RangeBoundary::PositiveInfinity());

  // [kMinInt64, kMaxInt32 + 15] + [10, 20] = [kMinInt64 + 10, kMaxInt32 + 35].
  TEST_RANGE_ADD(static_cast<int64_t>(kMinInt64),
                 static_cast<int64_t>(kMaxInt32) + 15, static_cast<int64_t>(10),
                 static_cast<int64_t>(20),
                 RangeBoundary(static_cast<int64_t>(kMinInt64) + 10),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 35));

  // [0, 0] + [kMinInt64, kMaxInt64] = [kMinInt64, kMaxInt64].
  TEST_RANGE_ADD(static_cast<int64_t>(0), static_cast<int64_t>(0),
                 static_cast<int64_t>(kMinInt64),
                 static_cast<int64_t>(kMaxInt64), RangeBoundary(kMinInt64),
                 RangeBoundary(kMaxInt64));

  // Overflows.

  // [-1, 1] + [kMinInt64, kMaxInt64] = [-inf, +inf].
  TEST_RANGE_ADD(
      static_cast<int64_t>(-1), static_cast<int64_t>(1),
      static_cast<int64_t>(kMinInt64), static_cast<int64_t>(kMaxInt64),
      RangeBoundary::NegativeInfinity(), RangeBoundary::PositiveInfinity());

  // [kMaxInt64, kMaxInt64] + [kMaxInt64, kMaxInt64] = [-inf, +inf].
  TEST_RANGE_ADD(
      static_cast<int64_t>(kMaxInt64), static_cast<int64_t>(kMaxInt64),
      static_cast<int64_t>(kMaxInt64), static_cast<int64_t>(kMaxInt64),
      RangeBoundary::NegativeInfinity(), RangeBoundary::PositiveInfinity());

  // [kMaxInt64, kMaxInt64] + [1, 1] = [-inf, +inf].
  TEST_RANGE_ADD(static_cast<int64_t>(kMaxInt64),
                 static_cast<int64_t>(kMaxInt64), static_cast<int64_t>(1),
                 static_cast<int64_t>(1), RangeBoundary::NegativeInfinity(),
                 RangeBoundary::PositiveInfinity());

#undef TEST_RANGE_ADD
}

TEST_CASE(RangeSub) {
#define TEST_RANGE_SUB(l_min, l_max, r_min, r_max, result_min, result_max)     \
  {                                                                            \
    RangeBoundary min, max;                                                    \
    Range* left_range = new Range(RangeBoundary::FromConstant(l_min),          \
                                  RangeBoundary::FromConstant(l_max));         \
    Range* right_range = new Range(RangeBoundary::FromConstant(r_min),         \
                                   RangeBoundary::FromConstant(r_max));        \
    EXPECT(left_range->min().ConstantValue() == l_min);                        \
    EXPECT(left_range->max().ConstantValue() == l_max);                        \
    EXPECT(right_range->min().ConstantValue() == r_min);                       \
    EXPECT(right_range->max().ConstantValue() == r_max);                       \
    Range::Sub(left_range, right_range, &min, &max, NULL);                     \
    EXPECT(min.Equals(result_min));                                            \
    if (FLAG_support_il_printer && !min.Equals(result_min)) {                  \
      OS::PrintErr("%s != %s\n", min.ToCString(), result_min.ToCString());     \
    }                                                                          \
    EXPECT(max.Equals(result_max));                                            \
    if (FLAG_support_il_printer && !max.Equals(result_max)) {                  \
      OS::PrintErr("%s != %s\n", max.ToCString(), result_max.ToCString());     \
    }                                                                          \
  }

  // [kMaxInt32, kMaxInt32 + 15] - [10, 20] = [kMaxInt32 - 20, kMaxInt32 + 5].
  TEST_RANGE_SUB(static_cast<int64_t>(kMaxInt32),
                 static_cast<int64_t>(kMaxInt32) + 15, static_cast<int64_t>(10),
                 static_cast<int64_t>(20),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) - 20),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 5));

  // [kMintInt64, kMintInt64] - [1, 1] = [-inf, +inf].
  TEST_RANGE_SUB(static_cast<int64_t>(kMinInt64),
                 static_cast<int64_t>(kMinInt64), static_cast<int64_t>(1),
                 static_cast<int64_t>(1), RangeBoundary::NegativeInfinity(),
                 RangeBoundary::PositiveInfinity());

  // [1, 1] - [kMintInt64, kMintInt64] = [-inf, +inf].
  TEST_RANGE_SUB(
      static_cast<int64_t>(1), static_cast<int64_t>(1),
      static_cast<int64_t>(kMinInt64), static_cast<int64_t>(kMinInt64),
      RangeBoundary::NegativeInfinity(), RangeBoundary::PositiveInfinity());

  // [kMaxInt32 + 10, kMaxInt32 + 20] - [-20, -20] =
  //     [kMaxInt32 + 30, kMaxInt32 + 40].
  TEST_RANGE_SUB(static_cast<int64_t>(kMaxInt32) + 10,
                 static_cast<int64_t>(kMaxInt32) + 20,
                 static_cast<int64_t>(-20), static_cast<int64_t>(-20),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 30),
                 RangeBoundary(static_cast<int64_t>(kMaxInt32) + 40));

#undef TEST_RANGE_SUB
}

TEST_CASE(RangeAnd) {
#define TEST_RANGE_AND(l_min, l_max, r_min, r_max, result_min, result_max)     \
  {                                                                            \
    RangeBoundary min, max;                                                    \
    Range* left_range = new Range(RangeBoundary::FromConstant(l_min),          \
                                  RangeBoundary::FromConstant(l_max));         \
    Range* right_range = new Range(RangeBoundary::FromConstant(r_min),         \
                                   RangeBoundary::FromConstant(r_max));        \
    EXPECT(left_range->min().ConstantValue() == l_min);                        \
    EXPECT(left_range->max().ConstantValue() == l_max);                        \
    EXPECT(right_range->min().ConstantValue() == r_min);                       \
    EXPECT(right_range->max().ConstantValue() == r_max);                       \
    Range::And(left_range, right_range, &min, &max);                           \
    EXPECT(min.Equals(result_min));                                            \
    if (FLAG_support_il_printer && !min.Equals(result_min)) {                  \
      OS::PrintErr("%s != %s\n", min.ToCString(), result_min.ToCString());     \
    }                                                                          \
    EXPECT(max.Equals(result_max));                                            \
    if (FLAG_support_il_printer && !max.Equals(result_max)) {                  \
      OS::PrintErr("%s != %s\n", max.ToCString(), result_max.ToCString());     \
    }                                                                          \
  }

  // [0xff, 0xfff] & [0xf, 0xf] = [0x0, 0xf].
  TEST_RANGE_AND(static_cast<int64_t>(0xff), static_cast<int64_t>(0xfff),
                 static_cast<int64_t>(0xf), static_cast<int64_t>(0xf),
                 RangeBoundary(0), RangeBoundary(0xf));

  // [0xffffffff, 0xffffffff] & [0xfffffffff, 0xfffffffff] = [0x0, 0xfffffffff].
  TEST_RANGE_AND(
      static_cast<int64_t>(0xffffffff), static_cast<int64_t>(0xffffffff),
      static_cast<int64_t>(0xfffffffff), static_cast<int64_t>(0xfffffffff),
      RangeBoundary(0), RangeBoundary(static_cast<int64_t>(0xfffffffff)));

  // [0xffffffff, 0xffffffff] & [-20, 20] = [0x0, 0xffffffff].
  TEST_RANGE_AND(static_cast<int64_t>(0xffffffff),
                 static_cast<int64_t>(0xffffffff), static_cast<int64_t>(-20),
                 static_cast<int64_t>(20), RangeBoundary(0),
                 RangeBoundary(static_cast<int64_t>(0xffffffff)));

  // [-20, 20] & [0xffffffff, 0xffffffff] = [0x0, 0xffffffff].
  TEST_RANGE_AND(static_cast<int64_t>(-20), static_cast<int64_t>(20),
                 static_cast<int64_t>(0xffffffff),
                 static_cast<int64_t>(0xffffffff), RangeBoundary(0),
                 RangeBoundary(static_cast<int64_t>(0xffffffff)));

  // Test that [-20, 20] & [-20, 20] = [-32, 31].
  TEST_RANGE_AND(static_cast<int64_t>(-20), static_cast<int64_t>(20),
                 static_cast<int64_t>(-20), static_cast<int64_t>(20),
                 RangeBoundary(-32), RangeBoundary(31));

#undef TEST_RANGE_AND
}

TEST_CASE(RangeIntersectionMinMax) {
  // Test IntersectionMin and IntersectionMax methods which for constants are
  // simply defined as Max/Min respectively.

  // Constants.
  // MIN(0, 1) == 0
  EXPECT(RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(0),
                                        RangeBoundary::FromConstant(1))
             .ConstantValue() == 0);
  // MIN(0, -1) == -1
  EXPECT(RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(0),
                                        RangeBoundary::FromConstant(-1))
             .ConstantValue() == -1);

  // MIN(1, 0) == 0
  EXPECT(RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(1),
                                        RangeBoundary::FromConstant(0))
             .ConstantValue() == 0);
  // MIN(-1, 0) == -1
  EXPECT(RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(-1),
                                        RangeBoundary::FromConstant(0))
             .ConstantValue() == -1);

  // MAX(0, 1) == 1
  EXPECT(RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(0),
                                        RangeBoundary::FromConstant(1))
             .ConstantValue() == 1);

  // MAX(0, -1) == 0
  EXPECT(RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(0),
                                        RangeBoundary::FromConstant(-1))
             .ConstantValue() == 0);

  // MAX(1, 0) == 1
  EXPECT(RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(1),
                                        RangeBoundary::FromConstant(0))
             .ConstantValue() == 1);
  // MAX(-1, 0) == 0
  EXPECT(RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(-1),
                                        RangeBoundary::FromConstant(0))
             .ConstantValue() == 0);

  RangeBoundary n_infinity = RangeBoundary::NegativeInfinity();
  RangeBoundary p_infinity = RangeBoundary::PositiveInfinity();

  // Constants vs. infinity.
  EXPECT(RangeBoundary::IntersectionMin(n_infinity,
                                        RangeBoundary::FromConstant(-1))
             .ConstantValue() == -1);

  EXPECT(RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(-1),
                                        n_infinity)
             .ConstantValue() == -1);

  EXPECT(
      RangeBoundary::IntersectionMin(RangeBoundary::FromConstant(1), n_infinity)
          .ConstantValue() == 1);

  EXPECT(
      RangeBoundary::IntersectionMin(n_infinity, RangeBoundary::FromConstant(1))
          .ConstantValue() == 1);

  EXPECT(RangeBoundary::IntersectionMax(p_infinity,
                                        RangeBoundary::FromConstant(-1))
             .ConstantValue() == -1);

  EXPECT(RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(-1),
                                        p_infinity)
             .ConstantValue() == -1);

  EXPECT(
      RangeBoundary::IntersectionMax(RangeBoundary::FromConstant(1), p_infinity)
          .ConstantValue() == 1);

  EXPECT(
      RangeBoundary::IntersectionMax(p_infinity, RangeBoundary::FromConstant(1))
          .ConstantValue() == 1);
}

TEST_CASE(RangeJoinMinMax) {
  // Test IntersectionMin and IntersectionMax methods which for constants are
  // simply defined as Min/Max respectively.
  const RangeBoundary::RangeSize size = RangeBoundary::kRangeBoundarySmi;

  // Constants.
  EXPECT(RangeBoundary::JoinMax(RangeBoundary::FromConstant(0),
                                RangeBoundary::FromConstant(1), size)
             .ConstantValue() == 1);
  EXPECT(RangeBoundary::JoinMax(RangeBoundary::FromConstant(0),
                                RangeBoundary::FromConstant(-1), size)
             .ConstantValue() == 0);
  EXPECT(RangeBoundary::JoinMax(RangeBoundary::FromConstant(1),
                                RangeBoundary::FromConstant(0), size)
             .ConstantValue() == 1);
  EXPECT(RangeBoundary::JoinMax(RangeBoundary::FromConstant(-1),
                                RangeBoundary::FromConstant(0), size)
             .ConstantValue() == 0);
  EXPECT(RangeBoundary::JoinMin(RangeBoundary::FromConstant(0),
                                RangeBoundary::FromConstant(1), size)
             .ConstantValue() == 0);
  EXPECT(RangeBoundary::JoinMin(RangeBoundary::FromConstant(0),
                                RangeBoundary::FromConstant(-1), size)
             .ConstantValue() == -1);
  EXPECT(RangeBoundary::JoinMin(RangeBoundary::FromConstant(1),
                                RangeBoundary::FromConstant(0), size)
             .ConstantValue() == 0);
  EXPECT(RangeBoundary::JoinMin(RangeBoundary::FromConstant(-1),
                                RangeBoundary::FromConstant(0), size)
             .ConstantValue() == -1);

  RangeBoundary n_infinity = RangeBoundary::NegativeInfinity();
  RangeBoundary p_infinity = RangeBoundary::PositiveInfinity();

  // Constants vs. infinity.
  EXPECT(
      RangeBoundary::JoinMin(n_infinity, RangeBoundary::FromConstant(-1), size)
          .IsMinimumOrBelow(size));

  EXPECT(
      RangeBoundary::JoinMin(RangeBoundary::FromConstant(-1), n_infinity, size)
          .IsMinimumOrBelow(size));

  EXPECT(
      RangeBoundary::JoinMin(RangeBoundary::FromConstant(1), n_infinity, size)
          .IsMinimumOrBelow(size));

  EXPECT(
      RangeBoundary::JoinMin(n_infinity, RangeBoundary::FromConstant(1), size)
          .IsMinimumOrBelow(size));

  EXPECT(
      RangeBoundary::JoinMax(p_infinity, RangeBoundary::FromConstant(-1), size)
          .IsMaximumOrAbove(size));

  EXPECT(
      RangeBoundary::JoinMax(RangeBoundary::FromConstant(-1), p_infinity, size)
          .IsMaximumOrAbove(size));

  EXPECT(
      RangeBoundary::JoinMax(RangeBoundary::FromConstant(1), p_infinity, size)
          .IsMaximumOrAbove(size));

  EXPECT(
      RangeBoundary::JoinMax(p_infinity, RangeBoundary::FromConstant(1), size)
          .IsMaximumOrAbove(size));
}

}  // namespace dart
