// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/unit_test.h"

namespace dart {

static uword ZoneAllocator(intptr_t size) {
  Zone* zone = Isolate::Current()->current_zone();
  return zone->AllocUnsafe(size);
}


TEST_CASE(BigintSmi) {
  {
    const Smi& smi = Smi::Handle(Smi::New(5));
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(smi.Value()));
    EXPECT_EQ(5, bigint.AsInt64Value());
    EXPECT(bigint.FitsIntoSmi());
    Smi& smi_back = Smi::Handle();
    smi_back ^= bigint.AsValidInteger();
    EXPECT_EQ(5, smi_back.Value());
  }

  {
    const Smi& smi = Smi::Handle(Smi::New(Smi::kMaxValue));
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(smi.Value()));
    EXPECT(Smi::kMaxValue == bigint.AsInt64Value());
    EXPECT(bigint.FitsIntoSmi());
    Smi& smi_back = Smi::Handle();
    smi_back ^= bigint.AsValidInteger();
    EXPECT(Smi::kMaxValue == smi_back.Value());
  }

  {
    const Smi& smi = Smi::Handle(Smi::New(Smi::kMinValue));
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(smi.Value()));
    EXPECT(bigint.IsNegative());
    EXPECT(Smi::kMinValue == bigint.AsInt64Value());
    EXPECT(bigint.FitsIntoSmi());
    Smi& smi_back = Smi::Handle();
    smi_back ^= bigint.AsValidInteger();
    EXPECT(Smi::kMinValue == smi_back.Value());
  }

  {
    ASSERT(0xFFFFFFF < Smi::kMaxValue);
    const Smi& smi = Smi::Handle(Smi::New(0xFFFFFFF));
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(smi.Value()));
    EXPECT_EQ(0xFFFFFFF, bigint.AsInt64Value());
    EXPECT(bigint.FitsIntoSmi());
    Smi& smi_back = Smi::Handle();
    smi_back ^= bigint.AsValidInteger();
    EXPECT_EQ(0xFFFFFFF, smi_back.Value());
  }

  {
    ASSERT(0x10000000 < Smi::kMaxValue);
    const Smi& smi = Smi::Handle(Smi::New(0x10000000));
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(smi.Value()));
    EXPECT_EQ(0x10000000, bigint.AsInt64Value());
    EXPECT(bigint.FitsIntoSmi());
    Smi& smi_back = Smi::Handle();
    smi_back ^= bigint.AsValidInteger();
    EXPECT(0x10000000 == smi_back.Value());
  }
}


TEST_CASE(BigintInt64) {
  const int64_t kValue = 100000000;
  const int64_t kValue64 = kValue * kValue;
  Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(kValue));
  EXPECT_EQ(kValue, bigint.AsInt64Value());
  bigint = Bigint::NewFromInt64(kValue64);
  EXPECT_EQ(kValue64, bigint.AsInt64Value());
  bigint = Bigint::NewFromInt64(-kValue64);
  EXPECT_EQ(-kValue64, bigint.AsInt64Value());
  bigint = Bigint::NewFromInt64(kMinInt64);
  EXPECT(bigint.FitsIntoInt64());
  EXPECT_EQ(kMinInt64, bigint.AsInt64Value());
}


TEST_CASE(BigintUint64) {
  const Bigint& one = Bigint::Handle(Bigint::NewFromUint64(1));
  EXPECT(one.FitsIntoInt64());
  EXPECT(one.FitsIntoUint64());

  const Bigint& big = Bigint::Handle(Bigint::NewFromUint64(kMaxUint64));
  EXPECT(!big.FitsIntoInt64());
  EXPECT(big.FitsIntoUint64());

  uint64_t back = big.AsUint64Value();
  EXPECT_EQ(kMaxUint64, back);
}


TEST_CASE(BigintDouble) {
  Bigint& bigint = Bigint::Handle(Bigint::NewFromInt64(5));
  EXPECT_EQ(5.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromInt64(0);
  EXPECT_EQ(0.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromInt64(-12345678);
  EXPECT_EQ(-1.2345678e+7, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("1");
  EXPECT_EQ(1.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("123456");
  EXPECT_EQ(123456.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("123456789");
  EXPECT_EQ(123456789.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("12345678901234567");
  EXPECT_EQ(12345678901234568.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("98765432109876");
  EXPECT_EQ(9.8765432109876e+13, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x17777777777778");
  EXPECT_EQ(6605279453476728.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x37777777777778");
  EXPECT_EQ(15612478708217720.0, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x177777777777781234567");
  EXPECT_EQ(1.7730912021014563e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x177777777777788000000");
  EXPECT_EQ(1.7730912021014563e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x177777777777788000001");
  EXPECT_EQ(1.7730912021014565e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x177777777777798000000");
  EXPECT_EQ(1.7730912021014568e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x177777777777798000001");
  EXPECT_EQ(1.7730912021014568e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x377777777777790000000");
  EXPECT_EQ(4.1909428413307146e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x377777777777790000001");
  EXPECT_EQ(4.190942841330715e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x377777777777730000000");
  EXPECT_EQ(4.1909428413307135e+24, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("0x377777777777730000001");
  EXPECT_EQ(4.1909428413307135e+24, bigint.AsDoubleValue());

  // Reduced precision.
  bigint = Bigint::NewFromCString(
      "9876543210987654321098765432109876543210");
  EXPECT_EQ(9.8765432109876546e+39, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890"
      "12345678901234567890123456789012345678901234567890");
  double zero = 0.0;
  EXPECT_EQ(1.0/zero, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "17976931348623157081452742373170435679807056752584"
      "49965989174768031572607800285387605895586327668781"
      "71540458953514382464234321326889464182768467546703"
      "53751698604991057655128207624549009038932894407586"
      "85084551339423045832369032229481658085593321233482"
      "74797826204144723168738177180919299881250404026184"
      "124858368");
  EXPECT_EQ(1.7976931348623157e308, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "17976931348623159077293051907890247336179769789423"
      "06572734300811577326758055009631327084773224075360"
      "21120113879871393357658789768814416622492847430639"
      "47412437776789342486548527630221960124609411945308"
      "29520850057688381506823424628814739131105408272371"
      "63350510684586298239947245938479716304835356329624"
      "224137216");
  EXPECT_EQ(1.0/zero, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "17976931348623158079372897140530341507993413271003"
      "78269361737789804449682927647509466490179775872070"
      "96330286416692887910946555547851940402630657488671"
      "50582068190890200070838367627385484581771153176447"
      "57302700698555713669596228429148198608349364752927"
      "19074168444365510704342711559699508093042880177904"
      "174497792");
  EXPECT_EQ(1.0/zero, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "17976931348623158079372897140530341507993413271003"
      "78269361737789804449682927647509466490179775872070"
      "96330286416692887910946555547851940402630657488671"
      "50582068190890200070838367627385484581771153176447"
      "57302700698555713669596228429148198608349364752927"
      "19074168444365510704342711559699508093042880177904"
      "174497791");
  EXPECT_EQ(1.7976931348623157e308, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("100000000000000000000000");
  EXPECT_EQ(1e+23, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString("100000000000000000000001");
  EXPECT_EQ(1.0000000000000001e+23, bigint.AsDoubleValue());

  // Same but shifted 64 bits to the left.
  bigint = Bigint::NewFromCString(
      "1844674407370955161600000000000000000000000");
  EXPECT_EQ(1.844674407370955e+42, bigint.AsDoubleValue());

  bigint = Bigint::NewFromCString(
      "1844674407370955161600000000000000000000001");
  EXPECT_EQ(1.8446744073709553e+42, bigint.AsDoubleValue());
}


TEST_CASE(BigintHexStrings) {
  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x0"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x1"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(1, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0x123, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x123"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0xaBcEf"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0xABCEF", str);
  }

  {
    const char* in = "0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0xFFFFFFF";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0x10000000";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0x123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(-0x123, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0x123"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0xaBcEf"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0xABCEF", str);
  }

  {
    const char* in = "-0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x00000123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0x123, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("0x000000123"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("0x0000aBcEf"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0xABCEF", str);
  }

  {
    const char* in = "0x00000000000000000000000000000000000000000000123456789";
    const char* out =                                            "0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const char* in = "0x00000123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* out =     "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("-0x00000123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(-0x123, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("-0x00000123"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("-0x000aBcEf"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0xABCEF", str);
  }

  {
    const char* in = "-0x00000000000000000000000000000000000000000000123456789";
    const char* out =                                            "-0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const char* in = "-0x0000123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* out =    "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
  {
    const char* test = "12345678901234567890";
    const char* out = "0xAB54A98CEB1F0AD2";
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString(test));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
  {
    const char* test = "-12345678901234567890";
    const char* out = "-0xAB54A98CEB1F0AD2";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(test));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
}


TEST_CASE(BigintDecStrings) {
  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x0"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("0", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x123"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0xaBcEf"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("703727", str);
  }

  {
    const char* in = "0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("4886718345", str);
  }

  {
    const char* in = "0xFFFFFFF";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("268435455", str);
  }

  {
    const char* in = "0x10000000";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("268435456", str);
  }

  {
    const char* in = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("7141946863373290020600059860922167424469804758405880798960",
        str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0x123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(-291, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0x123"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("-291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0xaBcEf"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("-703727", str);
  }

  {
    const char* in = "-0x123456789";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("-4886718345", str);
  }

  {
    const char* in = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString(in));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("-7141946863373290020600059860922167424469804758405880798960",
        str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0x00000123"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0x123, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("0x000000123"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("100000000000000000000000000000000"));
    const char* str = bigint.ToDecCString(&ZoneAllocator);
    EXPECT_STREQ("100000000000000000000000000000000", str);
  }
}


static void TestBigintCompare(const char* a, const char* b, int compare) {
  const Bigint& bigint_a = Bigint::Handle(Bigint::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(Bigint::NewFromCString(b));
  const Integer& int_a = Integer::Handle(bigint_a.AsValidInteger());
  const Integer& int_b = Integer::Handle(bigint_b.AsValidInteger());
  int computed_compare = int_a.CompareWith(int_b);
  int inverted_compare = int_b.CompareWith(int_a);
  if (compare == 0) {
    EXPECT(computed_compare == 0);
    EXPECT(inverted_compare == 0);
  } else if (compare < 0) {
    ASSERT(computed_compare < 0);
    EXPECT(computed_compare < 0);
    EXPECT(inverted_compare > 0);
  } else {
    ASSERT(compare > 0);
    EXPECT(computed_compare > 0);
    EXPECT(inverted_compare < 0);
  }
}


TEST_CASE(BigintCompare) {
  TestBigintCompare("0x0", "0x0", 0);
  TestBigintCompare("0x1", "0x1", 0);
  TestBigintCompare("-0x1", "-0x1", 0);
  TestBigintCompare("0x1234567", "0x1234567", 0);
  TestBigintCompare("-0x1234567", "-0x1234567", 0);
  TestBigintCompare("0x12345678", "0x12345678", 0);
  TestBigintCompare("-0x12345678", "-0x12345678", 0);
  TestBigintCompare("0x123456789ABCDEF0", "0x123456789ABCDEF0", 0);
  TestBigintCompare("-0x123456789ABCDEF0", "-0x123456789ABCDEF0", 0);
  TestBigintCompare("0x123456789ABCDEF01", "0x123456789ABCDEF01", 0);
  TestBigintCompare("-0x123456789ABCDEF01", "-0x123456789ABCDEF01", 0);
  TestBigintCompare("0x1", "0x0", 1);
  TestBigintCompare("-0x1", "-0x2", 1);
  TestBigintCompare("0x1234567", "0x1234566", 1);
  TestBigintCompare("-0x1234567", "-0x1234568", 1);
  TestBigintCompare("0x12345678", "0x12345677", 1);
  TestBigintCompare("-0x12345678", "-0x12345679", 1);
  TestBigintCompare("0x123456789ABCDEF1", "0x123456789ABCDEF0", 1);
  TestBigintCompare("-0x123456789ABCDEF0", "-0x123456789ABCDEF1", 1);
  TestBigintCompare("0x123456789ABCDEF02", "0x123456789ABCDEF01", 1);
  TestBigintCompare("-0x123456789ABCDEF00", "-0x123456789ABCDEF01", 1);
  TestBigintCompare("0x10000000", "0xFFFFFFF", 1);
  TestBigintCompare("-0x10000000", "-0xFFFFFFF", -1);
  TestBigintCompare("0x100000000", "0xFFFFFFFF", 1);
  TestBigintCompare("-0x100000000", "-0xFFFFFFFF", -1);
  TestBigintCompare("0x10000000000000000", "0xFFFFFFFFFFFFFFFF", 1);
  TestBigintCompare("-0x10000000000000000", "-0xFFFFFFFFFFFFFFFF", -1);
  TestBigintCompare("0x10000000000000000", "0x0", 1);
  TestBigintCompare("-0x10000000000000000", "0x0", -1);
  TestBigintCompare("-0x1234567", "0x1234566", -1);
  TestBigintCompare("-0x1234567", "0x1234568", -1);
  TestBigintCompare("-0x12345678", "0x12345677", -1);
  TestBigintCompare("-0x12345678", "0x12345670", -1);
  TestBigintCompare("-0x123456789ABCDEF1", "0x123456789ABCDEF0", -1);
  TestBigintCompare("-0x123456789ABCDEF0", "0x123456789ABCDEF1", -1);
  TestBigintCompare("-0x123456789ABCDEF02", "0x123456789ABCDEF01", -1);
  TestBigintCompare("-0x123456789ABCDEF00", "0x123456789ABCDEF01", -1);
  TestBigintCompare("-0x10000000", "0xFFFFFFF", -1);
  TestBigintCompare("-0x10000000", "0xFFFFFFF", -1);
  TestBigintCompare("-0x100000000", "0xFFFFFFFF", -1);
  TestBigintCompare("-0x100000000", "0xFFFFFFFF", -1);
  TestBigintCompare("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", -1);
  TestBigintCompare("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", -1);
  TestBigintCompare("-0x10000000000000000", "0x0", -1);
  TestBigintCompare("-0x10000000000000000", "0x0", -1);
}


TEST_CASE(BigintDecimalStrings) {
  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("0"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("1"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(1, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("703710"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0xABCDE", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("11259375"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0xABCDEF", str);
  }

  {
    const Bigint& bigint =
        Bigint::Handle(Bigint::NewFromCString("1311768467463790320"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("0x123456789ABCDEF0", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-0"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(0, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-1"));
    EXPECT(bigint.FitsIntoSmi());
    EXPECT_EQ(-1, bigint.AsInt64Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-703710"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0xABCDE", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(Bigint::NewFromCString("-11259375"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0xABCDEF", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        Bigint::NewFromCString("-1311768467463790320"));
    const char* str = bigint.ToHexCString(&ZoneAllocator);
    EXPECT_STREQ("-0x123456789ABCDEF0", str);
  }
}

}  // namespace dart
