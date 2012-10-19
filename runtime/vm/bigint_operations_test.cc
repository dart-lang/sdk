// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bigint_operations.h"
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
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi_back = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(5, smi_back.Value());
  }

  {
    const Smi& smi = Smi::Handle(Smi::New(Smi::kMaxValue));
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi_back = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT(Smi::kMaxValue == smi_back.Value());
  }

  {
    const Smi& smi = Smi::Handle(Smi::New(Smi::kMinValue));
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi_back = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT(bigint.IsNegative());
    EXPECT(Smi::kMinValue == smi_back.Value());
  }

  {
    ASSERT(0xFFFFFFF < Smi::kMaxValue);
    const Smi& smi = Smi::Handle(Smi::New(0xFFFFFFF));
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi_back = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT(0xFFFFFFF == smi_back.Value());
  }

  {
    ASSERT(0x10000000 < Smi::kMaxValue);
    const Smi& smi = Smi::Handle(Smi::New(0x10000000));
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi_back = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT(0x10000000 == smi_back.Value());
  }
}


TEST_CASE(BigintInt64) {
  const int64_t kValue = 100000000;
  const int64_t kValue64 = kValue * kValue;
  Bigint& big = Bigint::Handle(BigintOperations::NewFromInt64(kValue));
  const Smi& smi = Smi::Handle(Smi::New(kValue));
  Bigint& big_test = Bigint::Handle(BigintOperations::NewFromSmi(smi));
  EXPECT_EQ(0, BigintOperations::Compare(big, big_test));
  big = BigintOperations::NewFromInt64(kValue64);
  big_test = BigintOperations::Multiply(big_test, big_test);
  EXPECT_EQ(0, BigintOperations::Compare(big, big_test));
  big = BigintOperations::NewFromInt64(-kValue64);
  big_test = BigintOperations::Subtract(
      Bigint::Handle(BigintOperations::NewFromInt64(0)), big_test);
  EXPECT_EQ(0, BigintOperations::Compare(big, big_test));

  const Bigint& one = Bigint::Handle(BigintOperations::NewFromInt64(1));
  big = BigintOperations::NewFromInt64(kMinInt64);
  EXPECT(BigintOperations::FitsIntoMint(big));
  int64_t back = BigintOperations::ToMint(big);
  EXPECT_EQ(kMinInt64, back);

  big = BigintOperations::Subtract(big, one);
  EXPECT(!BigintOperations::FitsIntoMint(big));

  big = BigintOperations::NewFromInt64(kMaxInt64);
  EXPECT(BigintOperations::FitsIntoMint(big));
  back = BigintOperations::ToMint(big);
  EXPECT_EQ(kMaxInt64, back);

  big = BigintOperations::Add(big, one);
  EXPECT(!BigintOperations::FitsIntoMint(big));
}


TEST_CASE(BigintUint64) {
  const Bigint& one = Bigint::Handle(BigintOperations::NewFromUint64(1));
  EXPECT(BigintOperations::FitsIntoMint(one));
  EXPECT(BigintOperations::FitsIntoUint64(one));

  Bigint& big = Bigint::Handle(BigintOperations::NewFromUint64(kMaxUint64));
  EXPECT(!BigintOperations::FitsIntoMint(big));
  EXPECT(BigintOperations::FitsIntoUint64(big));

  uint64_t back = BigintOperations::ToUint64(big);
  EXPECT_EQ(kMaxUint64, back);

  big = BigintOperations::Add(big, one);
  EXPECT(!BigintOperations::FitsIntoMint(big));
  EXPECT(!BigintOperations::FitsIntoUint64(big));

  big = BigintOperations::Subtract(big, one);
  EXPECT(!BigintOperations::FitsIntoMint(big));
  EXPECT(BigintOperations::FitsIntoUint64(big));

  big = BigintOperations::ShiftRight(big, 1);
  EXPECT(BigintOperations::FitsIntoMint(big));
  EXPECT(BigintOperations::FitsIntoUint64(big));
}


TEST_CASE(BigintDouble) {
  Smi& smi = Smi::Handle(Smi::New(5));
  Bigint& bigint = Bigint::Handle(BigintOperations::NewFromSmi(smi));
  Double& dbl = Double::Handle(BigintOperations::ToDouble(bigint));
  EXPECT_EQ(5.0, dbl.value());

  smi = Smi::New(0);
  bigint = BigintOperations::NewFromSmi(smi);
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(0.0, dbl.value());
  double zero = dbl.value();

  smi = Smi::New(-12345678);
  bigint = BigintOperations::NewFromSmi(smi);
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(-1.2345678e+7, dbl.value());

  bigint = BigintOperations::NewFromCString("1");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.0, dbl.value());

  bigint = BigintOperations::NewFromCString("123456");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(123456.0, dbl.value());

  bigint = BigintOperations::NewFromCString("123456789");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(123456789.0, dbl.value());

  bigint = BigintOperations::NewFromCString("12345678901234567");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(12345678901234568.0, dbl.value());

  bigint = BigintOperations::NewFromCString("98765432109876");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(9.8765432109876e+13, dbl.value());

  bigint = BigintOperations::NewFromCString("0x17777777777778");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(6605279453476728.0, dbl.value());

  bigint = BigintOperations::NewFromCString("0x37777777777778");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(15612478708217720.0, dbl.value());

  bigint = BigintOperations::NewFromCString("0x177777777777781234567");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7730912021014563e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x177777777777788000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7730912021014563e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x177777777777788000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7730912021014565e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x177777777777798000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7730912021014568e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x177777777777798000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7730912021014568e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x377777777777790000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(4.1909428413307146e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x377777777777790000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(4.190942841330715e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x377777777777730000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(4.1909428413307135e+24, dbl.value());

  bigint = BigintOperations::NewFromCString("0x377777777777730000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(4.1909428413307135e+24, dbl.value());

  // Reduced precision.
  bigint = BigintOperations::NewFromCString(
      "9876543210987654321098765432109876543210");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(9.8765432109876546e+39, dbl.value());

  bigint = BigintOperations::NewFromCString(
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
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.0/zero, dbl.value());

  bigint = BigintOperations::NewFromCString(
      "17976931348623157081452742373170435679807056752584"
      "49965989174768031572607800285387605895586327668781"
      "71540458953514382464234321326889464182768467546703"
      "53751698604991057655128207624549009038932894407586"
      "85084551339423045832369032229481658085593321233482"
      "74797826204144723168738177180919299881250404026184"
      "124858368");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7976931348623157e308, dbl.value());

  bigint = BigintOperations::NewFromCString(
      "17976931348623159077293051907890247336179769789423"
      "06572734300811577326758055009631327084773224075360"
      "21120113879871393357658789768814416622492847430639"
      "47412437776789342486548527630221960124609411945308"
      "29520850057688381506823424628814739131105408272371"
      "63350510684586298239947245938479716304835356329624"
      "224137216");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.0/zero, dbl.value());

  bigint = BigintOperations::NewFromCString(
      "17976931348623158079372897140530341507993413271003"
      "78269361737789804449682927647509466490179775872070"
      "96330286416692887910946555547851940402630657488671"
      "50582068190890200070838367627385484581771153176447"
      "57302700698555713669596228429148198608349364752927"
      "19074168444365510704342711559699508093042880177904"
      "174497792");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.0/zero, dbl.value());

  bigint = BigintOperations::NewFromCString(
      "17976931348623158079372897140530341507993413271003"
      "78269361737789804449682927647509466490179775872070"
      "96330286416692887910946555547851940402630657488671"
      "50582068190890200070838367627385484581771153176447"
      "57302700698555713669596228429148198608349364752927"
      "19074168444365510704342711559699508093042880177904"
      "174497791");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.7976931348623157e308, dbl.value());

  bigint = BigintOperations::NewFromCString("100000000000000000000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1e+23, dbl.value());

  bigint = BigintOperations::NewFromCString("100000000000000000000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.0000000000000001e+23, dbl.value());

  // Same but shifted 64 bits to the left.
  bigint = BigintOperations::NewFromCString(
      "1844674407370955161600000000000000000000000");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.844674407370955e+42, dbl.value());

  bigint = BigintOperations::NewFromCString(
      "1844674407370955161600000000000000000000001");
  dbl = BigintOperations::ToDouble(bigint);
  EXPECT_EQ(1.8446744073709553e+42, dbl.value());
}


TEST_CASE(BigintHexStrings) {
  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x0"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x1"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(1, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0x123, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x123"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0xaBcEf"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0xABCEF", str);
  }

  {
    const char* in = "0x123456789";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0xFFFFFFF";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0x10000000";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(-0x123, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x123"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0xaBcEf"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0xABCEF", str);
  }

  {
    const char* in = "-0x123456789";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const char* in = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(in, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x00000123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0x123, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x000000123"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x0000aBcEf"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0xABCEF", str);
  }

  {
    const char* in = "0x00000000000000000000000000000000000000000000123456789";
    const char* out =                                            "0x123456789";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const char* in = "0x00000123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* out =     "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x00000123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(-0x123, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x00000123"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0x123", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x000aBcEf"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0xABCEF", str);
  }

  {
    const char* in = "-0x00000000000000000000000000000000000000000000123456789";
    const char* out =                                            "-0x123456789";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }

  {
    const char* in = "-0x0000123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* out =    "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
  {
    const char* test = "12345678901234567890";
    const char* out = "0xAB54A98CEB1F0AD2";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(test));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
  {
    const char* test = "-12345678901234567890";
    const char* out = "-0xAB54A98CEB1F0AD2";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(test));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ(out, str);
  }
}


TEST_CASE(BigintDecStrings) {
  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x123"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0xaBcEf"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("703727", str);
  }

  {
    const char* in = "0x123456789";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("4886718345", str);
  }

  {
    const char* in = "0xFFFFFFF";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("268435455", str);
  }

  {
    const char* in = "0x10000000";
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("268435456", str);
  }

  {
    const char* in = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("7141946863373290020600059860922167424469804758405880798960",
        str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(-291, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0x123"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0xaBcEf"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-703727", str);
  }

  {
    const char* in = "-0x123456789";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-4886718345", str);
  }

  {
    const char* in = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const Bigint& bigint = Bigint::Handle(BigintOperations::NewFromCString(in));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-7141946863373290020600059860922167424469804758405880798960",
        str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x00000123"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0x123, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0x000000123"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("291", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("100000000000000000000000000000000"));
    const char* str =
        BigintOperations::ToDecimalCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("100000000000000000000000000000000", str);
  }
}


static void TestBigintCompare(const char* a, const char* b, int compare) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  int computed_compare = BigintOperations::Compare(bigint_a, bigint_b);
  int inverted_compare = BigintOperations::Compare(bigint_b, bigint_a);
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
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("0"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("1"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(1, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("703710"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0xABCDE", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("11259375"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0xABCDEF", str);
  }

  {
    const Bigint& bigint =
        Bigint::Handle(BigintOperations::NewFromCString("1311768467463790320"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("0x123456789ABCDEF0", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-0"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(0, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-1"));
    EXPECT(BigintOperations::FitsIntoSmi(bigint));
    const Smi& smi = Smi::Handle(BigintOperations::ToSmi(bigint));
    EXPECT_EQ(-1, smi.Value());
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-703710"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0xABCDE", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-11259375"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0xABCDEF", str);
  }

  {
    const Bigint& bigint = Bigint::Handle(
        BigintOperations::NewFromCString("-1311768467463790320"));
    const char* str = BigintOperations::ToHexCString(bigint, &ZoneAllocator);
    EXPECT_STREQ("-0x123456789ABCDEF0", str);
  }
}


static void TestBigintAddSubtract(const char* a,
                                  const char* b,
                                  const char* sum) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& bigint_sum =
      Bigint::Handle(BigintOperations::NewFromCString(sum));
  const Bigint& computed_sum =
      Bigint::Handle(BigintOperations::Add(bigint_a, bigint_b));
  const Bigint& computed_difference1 =
      Bigint::Handle(BigintOperations::Subtract(bigint_sum, bigint_a));
  const Bigint& computed_difference2 =
      Bigint::Handle(BigintOperations::Subtract(bigint_sum, bigint_b));
  const char* str_sum = BigintOperations::ToHexCString(computed_sum,
                                                       &ZoneAllocator);
  EXPECT_STREQ(sum, str_sum);
  const char* str_difference1 =
      BigintOperations::ToHexCString(computed_difference1, &ZoneAllocator);
  EXPECT_STREQ(b, str_difference1);
  const char* str_difference2 =
      BigintOperations::ToHexCString(computed_difference2, &ZoneAllocator);
  EXPECT_STREQ(a, str_difference2);
}


TEST_CASE(BigintAddSubtract) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintAddSubtract(zero, zero, zero);
  TestBigintAddSubtract(zero, one, one);
  TestBigintAddSubtract(one, zero, one);
  TestBigintAddSubtract(one, one, "0x2");
  TestBigintAddSubtract(minus_one, minus_one, "-0x2");
  TestBigintAddSubtract("0x123", zero, "0x123");
  TestBigintAddSubtract(zero, "0x123", "0x123");
  TestBigintAddSubtract("0x123", one, "0x124");
  TestBigintAddSubtract(one, "0x123", "0x124");
  TestBigintAddSubtract("0xFFFFFFF", one,  // 28 bit overflow.
                        "0x10000000");
  TestBigintAddSubtract("0xFFFFFFFF", one,  // 32 bit overflow.
                        "0x100000000");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFF", one,  // 56 bit overflow.
                        "0x100000000000000");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFFFF", one,  // 64 bit overflow.
                        "0x10000000000000000");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  // 128 bit.
                        one,
                        "0x100000000000000000000000000000000");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
                        one,
                        "0x10000000000000000000000000000000000000000000");
  TestBigintAddSubtract("0x8000000",  // 28 bit overflow.
                        "0x8000000",
                        "0x10000000");
  TestBigintAddSubtract("0x80000000",  // 32 bit overflow.
                        "0x80000000",
                        "0x100000000");
  TestBigintAddSubtract("0x80000000000000",  // 56 bit overflow.
                        "0x80000000000000",
                        "0x100000000000000");
  TestBigintAddSubtract("0x8000000000000000",  // 64 bit overflow.
                        "0x8000000000000000",
                        "0x10000000000000000");
  TestBigintAddSubtract("0x80000000000000000000000000000000",  // 128 bit.
                        "0x80000000000000000000000000000000",
                        "0x100000000000000000000000000000000");
  TestBigintAddSubtract("0x8000000000000000000000000000000000000000000",
                        "0x8000000000000000000000000000000000000000000",
                        "0x10000000000000000000000000000000000000000000");

  {
    const char* a = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* sum1 = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF1";
    const char* times2 = "0x2468ACF13579BDE02468ACF121579BDE02468ACF13579BDE0";
    TestBigintAddSubtract(a, zero, a);
    TestBigintAddSubtract(a, one, sum1);
    TestBigintAddSubtract(a, a, times2);
  }

  TestBigintAddSubtract("-0x123", minus_one, "-0x124");
  TestBigintAddSubtract(minus_one, "-0x123", "-0x124");
  TestBigintAddSubtract("-0xFFFFFFF", minus_one,  // 28 bit overflow.
                        "-0x10000000");
  TestBigintAddSubtract("-0xFFFFFFFF", minus_one,  // 32 bit overflow.
                        "-0x100000000");
  TestBigintAddSubtract("-0xFFFFFFFFFFFFFF", minus_one,  // 56 bit overflow.
                        "-0x100000000000000");
  TestBigintAddSubtract("-0xFFFFFFFFFFFFFFFF", minus_one,  // 64 bit overflow.
                        "-0x10000000000000000");
  TestBigintAddSubtract("-0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  // 128 bit.
                        minus_one,
                        "-0x100000000000000000000000000000000");
  TestBigintAddSubtract("-0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
                        minus_one,
                        "-0x10000000000000000000000000000000000000000000");
  TestBigintAddSubtract("-0x8000000",  // 28 bit overflow.
                        "-0x8000000",
                        "-0x10000000");
  TestBigintAddSubtract("-0x80000000",  // 32 bit overflow.
                        "-0x80000000",
                        "-0x100000000");
  TestBigintAddSubtract("-0x80000000000000",  // 56 bit overflow.
                        "-0x80000000000000",
                        "-0x100000000000000");
  TestBigintAddSubtract("-0x8000000000000000",  // 64 bit overflow.
                        "-0x8000000000000000",
                        "-0x10000000000000000");
  TestBigintAddSubtract("-0x80000000000000000000000000000000",  // 128 bit.
                        "-0x80000000000000000000000000000000",
                        "-0x100000000000000000000000000000000");
  TestBigintAddSubtract("-0x8000000000000000000000000000000000000000000",
                        "-0x8000000000000000000000000000000000000000000",
                        "-0x10000000000000000000000000000000000000000000");

  {
    const char* a = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    const char* sum1 = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF1";
    const char* times2 = "-0x2468ACF13579BDE02468ACF121579BDE02468ACF13579BDE0";
    TestBigintAddSubtract(a, zero, a);
    TestBigintAddSubtract(a, minus_one, sum1);
    TestBigintAddSubtract(a, a, times2);
  }

  TestBigintAddSubtract("0x10000000000000000000000000000000000000000000",
                        "0xFFFF",
                        "0x1000000000000000000000000000000000000000FFFF");
  TestBigintAddSubtract("0x10000000000000000000000000000000000000000000",
                        "0xFFFF00000000",
                        "0x10000000000000000000000000000000FFFF00000000");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
                        "0x100000000",
                        "0x1000000000000000000000000000000000000FFFFFFFF");
  TestBigintAddSubtract("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
                        "0x10000000000000000000",
                        "0x10000000000000000000000000FFFFFFFFFFFFFFFFFFF");

  TestBigintAddSubtract("0xB", "-0x7", "0x4");
  TestBigintAddSubtract("-0xB", "-0x7", "-0x12");
  TestBigintAddSubtract("0xB", "0x7", "0x12");
  TestBigintAddSubtract("-0xB", "0x7", "-0x4");
  TestBigintAddSubtract("-0x7", "0xB", "0x4");
  TestBigintAddSubtract("-0x7", "-0xB", "-0x12");
  TestBigintAddSubtract("0x7", "0xB", "0x12");
  TestBigintAddSubtract("0x7", "-0xB", "-0x4");
}


static void TestBigintShift(const char* a, int amount, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& shifted =
      Bigint::Handle(BigintOperations::ShiftLeft(bigint_a, amount));
  const char* str_shifted = BigintOperations::ToHexCString(shifted,
                                                           &ZoneAllocator);
  EXPECT_STREQ(result, str_shifted);
  const Bigint& back_shifted =
      Bigint::Handle(BigintOperations::ShiftRight(shifted, amount));
  const char* str_back_shifted = BigintOperations::ToHexCString(back_shifted,
                                                                &ZoneAllocator);
  EXPECT_STREQ(a, str_back_shifted);
}


TEST_CASE(BigintLeftShift) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintShift(zero, 0, zero);
  TestBigintShift(one, 0, one);
  TestBigintShift("0x1234", 0, "0x1234");
  TestBigintShift(zero, 100000, zero);
  TestBigintShift(one, 1, "0x2");
  TestBigintShift(one, 28, "0x10000000");
  TestBigintShift(one, 32, "0x100000000");
  TestBigintShift(one, 64, "0x10000000000000000");
  TestBigintShift("0x5", 28, "0x50000000");
  TestBigintShift("0x5", 32, "0x500000000");
  TestBigintShift("0x5", 56, "0x500000000000000");
  TestBigintShift("0x5", 64, "0x50000000000000000");
  TestBigintShift("0x5", 128, "0x500000000000000000000000000000000");
  TestBigintShift("0x5", 27, "0x28000000");
  TestBigintShift("0x5", 31, "0x280000000");
  TestBigintShift("0x5", 55, "0x280000000000000");
  TestBigintShift("0x5", 63, "0x28000000000000000");
  TestBigintShift("0x5", 127, "0x280000000000000000000000000000000");
  TestBigintShift("0x8000001", 1, "0x10000002");
  TestBigintShift("0x80000001", 1, "0x100000002");
  TestBigintShift("0x8000000000000001", 1, "0x10000000000000002");
  TestBigintShift("0x8000001", 29, "0x100000020000000");
  TestBigintShift("0x80000001", 33, "0x10000000200000000");
  TestBigintShift("0x8000000000000001", 65,
                  "0x100000000000000020000000000000000");
  TestBigintShift(minus_one, 0, minus_one);
  TestBigintShift("-0x1234", 0, "-0x1234");
  TestBigintShift(minus_one, 1, "-0x2");
  TestBigintShift(minus_one, 28, "-0x10000000");
  TestBigintShift(minus_one, 32, "-0x100000000");
  TestBigintShift(minus_one, 64, "-0x10000000000000000");
  TestBigintShift("-0x5", 28, "-0x50000000");
  TestBigintShift("-0x5", 32, "-0x500000000");
  TestBigintShift("-0x5", 64, "-0x50000000000000000");
  TestBigintShift("-0x5", 27, "-0x28000000");
  TestBigintShift("-0x5", 31, "-0x280000000");
  TestBigintShift("-0x5", 63, "-0x28000000000000000");
  TestBigintShift("-0x8000001", 1, "-0x10000002");
  TestBigintShift("-0x80000001", 1, "-0x100000002");
  TestBigintShift("-0x8000000000000001", 1, "-0x10000000000000002");
  TestBigintShift("-0x8000001", 29, "-0x100000020000000");
  TestBigintShift("-0x80000001", 33, "-0x10000000200000000");
  TestBigintShift("-0x8000000000000001", 65,
                  "-0x100000000000000020000000000000000");
}


static void TestBigintRightShift(
    const char* a, int amount, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& shifted =
      Bigint::Handle(BigintOperations::ShiftRight(bigint_a, amount));
  const char* str_shifted = BigintOperations::ToHexCString(shifted,
                                                           &ZoneAllocator);
  if (strcmp(result, str_shifted)) {
    WARN2("%s >> %d", a, amount);
  }
  EXPECT_STREQ(result, str_shifted);
}


TEST_CASE(BigintRightShift) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintRightShift(one, 1, zero);
  TestBigintRightShift(minus_one, 1, minus_one);
  TestBigintRightShift("-0x2", 1, minus_one);
  TestBigintRightShift("0x12345678", 29, zero);
  TestBigintRightShift("-0x12345678", 29, minus_one);
  TestBigintRightShift("-0x12345678", 100, minus_one);
  TestBigintRightShift("0x5", 1, "0x2");
  TestBigintRightShift("0x5", 2, "0x1");
  TestBigintRightShift("-0x5", 1, "-0x3");
  TestBigintRightShift("-0x5", 2, "-0x2");
  TestBigintRightShift("0x10000001", 28, one);
  TestBigintRightShift("0x100000001", 32, one);
  TestBigintRightShift("0x10000000000000001", 64, one);
  TestBigintRightShift("-0x10000001", 28, "-0x2");
  TestBigintRightShift("-0x100000001", 32, "-0x2");
  TestBigintRightShift("-0x10000000000000001", 64, "-0x2");
  TestBigintRightShift("0x30000000", 29, one);
  TestBigintRightShift("0x300000000", 33, one);
  TestBigintRightShift("0x30000000000000000", 65, one);
  TestBigintRightShift("-0x30000000", 29, "-0x2");
  TestBigintRightShift("-0x300000000", 33, "-0x2");
  TestBigintRightShift("-0x30000000000000000", 65, "-0x2");
}


static void TestBigintBitAnd(const char* a, const char* b, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& anded =
      Bigint::Handle(BigintOperations::BitAnd(bigint_a, bigint_b));
  const char* str_anded = BigintOperations::ToHexCString(anded, &ZoneAllocator);
  EXPECT_STREQ(result, str_anded);
  const Bigint& anded2 =
      Bigint::Handle(BigintOperations::BitAnd(bigint_b, bigint_a));
  const char* str_anded2 = BigintOperations::ToHexCString(anded2,
                                                          &ZoneAllocator);
  EXPECT_STREQ(result, str_anded2);
}


TEST_CASE(BigintBitAnd) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintBitAnd(one, zero, zero);
  TestBigintBitAnd(one, one, one);
  TestBigintBitAnd(minus_one, zero, zero);
  TestBigintBitAnd(minus_one, one, one);
  TestBigintBitAnd(minus_one, minus_one, minus_one);
  TestBigintBitAnd("0x5", "0x3", one);
  TestBigintBitAnd("0x5", minus_one, "0x5");
  TestBigintBitAnd("0x50000000", one, zero);
  TestBigintBitAnd("0x50000000", minus_one, "0x50000000");
  TestBigintBitAnd("0x500000000", one, zero);
  TestBigintBitAnd("0x500000000", minus_one, "0x500000000");
  TestBigintBitAnd("0x50000000000000000", one, zero);
  TestBigintBitAnd("0x50000000000000000", minus_one, "0x50000000000000000");
  TestBigintBitAnd("-0x50000000", "-0x50000000", "-0x50000000");
  TestBigintBitAnd("-0x500000000", "-0x500000000", "-0x500000000");
  TestBigintBitAnd("-0x50000000000000000",
                   "-0x50000000000000000",
                   "-0x50000000000000000");
  TestBigintBitAnd("0x1234567890ABCDEF012345678",
                   "0x876543210FEDCBA0987654321",
                   "0x224422000A9C9A0002244220");
  TestBigintBitAnd("-0x1234567890ABCDEF012345678",
                   "-0x876543210FEDCBA0987654321",
                   "-0x977557799FEFCFEF997755778");
  TestBigintBitAnd("0x1234567890ABCDEF012345678",
                   "-0x876543210FEDCBA0987654321",
                   "0x101014589002044F010101458");
  TestBigintBitAnd("0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
                   "-0x876543210FEDCBA0987654321",
                   "0x1234567890ABCDEF012345678789ABCDEF012345F6789ABCDF");
  TestBigintBitAnd("0x12345678", "0xFFFFFFF", "0x2345678");
  TestBigintBitAnd("0x123456789", "0xFFFFFFFF", "0x23456789");
  TestBigintBitAnd("-0x10000000", "0xFFFFFFF", "0x0");
  TestBigintBitAnd("-0x100000000", "0xFFFFFFFF", "0x0");
  TestBigintBitAnd("-0x10000001", "0xFFFFFFF", "0xFFFFFFF");
  TestBigintBitAnd("-0x100000001", "0xFFFFFFFF", "0xFFFFFFFF");
  TestBigintBitAnd("-0x10000001", "0x3FFFFFFF", "0x2FFFFFFF");
  TestBigintBitAnd("-0x100000001", "0x3FFFFFFFF", "0x2FFFFFFFF");
  TestBigintBitAnd("-0x10000000000000001",
                   "0x3FFFFFFFFFFFFFFFF",
                   "0x2FFFFFFFFFFFFFFFF");
  TestBigintBitAnd("-0x100000000000000", "0xFFFFFFFFFFFFFF", "0x0");
  TestBigintBitAnd("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "0x0");
  TestBigintBitAnd("-0x300000000000000",
                   "0xFFFFFFFFFFFFFFF",
                   "0xD00000000000000");
  TestBigintBitAnd("-0x30000000000000000",
                   "0xFFFFFFFFFFFFFFFFF",
                   "0xD0000000000000000");
  TestBigintBitAnd("-0x10000000", "-0x10000000", "-0x10000000");
  TestBigintBitAnd("-0x100000000", "-0x100000000", "-0x100000000");
  TestBigintBitAnd("-0x100000000000000",
                   "-0x100000000000000",
                   "-0x100000000000000");
  TestBigintBitAnd("-0x10000000000000000",
                   "-0x10000000000000000",
                   "-0x10000000000000000");
  TestBigintBitAnd("-0x3", "-0x2", "-0x4");
  TestBigintBitAnd("-0x10000000", "-0x10000001", "-0x20000000");
  TestBigintBitAnd("-0x100000000", "-0x100000001", "-0x200000000");
  TestBigintBitAnd("-0x100000000000000",
                   "-0x100000000000001",
                   "-0x200000000000000");
  TestBigintBitAnd("-0x10000000000000000",
                   "-0x10000000000000001",
                   "-0x20000000000000000");
  TestBigintBitAnd("0x123456789ABCDEF01234567890",
                   "0x3FFFFFFF",  // Max Smi for 32 bits.
                   "0x34567890");
  TestBigintBitAnd("0x123456789ABCDEF01274567890",
                   "0x3FFFFFFF",  // Max Smi for 32 bits.
                   "0x34567890");
  TestBigintBitAnd("0x123456789ABCDEF01234567890",
                   "0x40000000",  // Max Smi for 32 bits + 1.
                   "0x0");
  TestBigintBitAnd("0x123456789ABCDEF01274567890",
                   "0x40000000",  // Max Smi for 32 bits + 1.
                   "0x40000000");
  TestBigintBitAnd("0x123456789ABCDEF01234567890",
                   "0x3FFFFFFFFFFFFFFF",  // Max Smi for 64 bits.
                   "0x3CDEF01234567890");
  TestBigintBitAnd("0x123456789ACCDEF01234567890",
                   "0x4000000000000000",  // Max Smi for 64 bits + 1.
                   "0x4000000000000000");
  TestBigintBitAnd("0x123456789ABCDEF01234567890",
                   "0x4000000000000000",  // Max Smi for 64 bits + 1.
                   "0x0");
}


static void TestBigintBitOr(const char* a, const char* b, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& ored =
      Bigint::Handle(BigintOperations::BitOr(bigint_a, bigint_b));
  const char* str_ored = BigintOperations::ToHexCString(ored, &ZoneAllocator);
  EXPECT_STREQ(result, str_ored);
  const Bigint& ored2 =
      Bigint::Handle(BigintOperations::BitOr(bigint_b, bigint_a));
  const char* str_ored2 = BigintOperations::ToHexCString(ored2, &ZoneAllocator);
  EXPECT_STREQ(result, str_ored2);
}


TEST_CASE(BigintBitOr) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintBitOr(one, zero, one);
  TestBigintBitOr(one, one, one);
  TestBigintBitOr(minus_one, zero, minus_one);
  TestBigintBitOr(minus_one, one, minus_one);
  TestBigintBitOr(minus_one, minus_one, minus_one);
  TestBigintBitOr("-0x3", one, "-0x3");
  TestBigintBitOr("0x5", "0x3", "0x7");
  TestBigintBitOr("0x5", minus_one, minus_one);
  TestBigintBitOr("0x5", zero, "0x5");
  TestBigintBitOr("0x50000000", one, "0x50000001");
  TestBigintBitOr("0x50000000", minus_one, minus_one);
  TestBigintBitOr("0x500000000", one, "0x500000001");
  TestBigintBitOr("0x500000000", minus_one, minus_one);
  TestBigintBitOr("0x50000000000000000", one, "0x50000000000000001");
  TestBigintBitOr("0x50000000000000000", minus_one, minus_one);
  TestBigintBitOr("-0x50000000", "-0x50000000", "-0x50000000");
  TestBigintBitOr("-0x500000000", "-0x500000000", "-0x500000000");
  TestBigintBitOr("-0x50000000000000000",
                  "-0x50000000000000000",
                  "-0x50000000000000000");
  TestBigintBitOr("0x1234567890ABCDEF012345678",
                  "0x876543210FEDCBA0987654321",
                  "0x977557799FEFCFEF997755779");
  TestBigintBitOr("-0x1234567890ABCDEF012345678",
                  "-0x876543210FEDCBA0987654321",
                  "-0x224422000A9C9A0002244221");
  TestBigintBitOr("0x1234567890ABCDEF012345678",
                  "-0x876543210FEDCBA0987654321",
                  "-0x854101010F440200985410101");
  TestBigintBitOr("0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
                  "-0x876543210FEDCBA0987654321",
                  "-0x1");
  TestBigintBitOr("0x12345678", "0xFFFFFFF", "0x1FFFFFFF");
  TestBigintBitOr("0x123456789", "0xFFFFFFFF", "0x1FFFFFFFF");
  TestBigintBitOr("-0x10000000", "0xFFFFFFF", "-0x1");
  TestBigintBitOr("-0x100000000", "0xFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x10000001", "0xFFFFFFF", "-0x10000001");
  TestBigintBitOr("-0x100000001", "0xFFFFFFFF", "-0x100000001");
  TestBigintBitOr("-0x10000001", "0x3FFFFFFF", "-0x1");
  TestBigintBitOr("-0x100000001", "0x3FFFFFFFF", "-0x1");
  TestBigintBitOr("-0x10000000000000001", "0x3FFFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x100000000000000", "0xFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x300000000000000", "0xFFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x30000000000000000", "0xFFFFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitOr("-0x10000000", "-0x10000000", "-0x10000000");
  TestBigintBitOr("-0x100000000", "-0x100000000", "-0x100000000");
  TestBigintBitOr("-0x100000000000000",
                   "-0x100000000000000",
                   "-0x100000000000000");
  TestBigintBitOr("-0x10000000000000000",
                   "-0x10000000000000000",
                   "-0x10000000000000000");
  TestBigintBitOr("-0x10000000", "-0x10000001", "-0x1");
  TestBigintBitOr("-0x100000000", "-0x100000001", "-0x1");
  TestBigintBitOr("-0x100000000000000", "-0x100000000000001", "-0x1");
  TestBigintBitOr("-0x10000000000000000", "-0x10000000000000001", "-0x1");
  TestBigintBitOr("-0x10000000000000000", "-0x1", "-0x1");
}


static void TestBigintBitXor(const char* a, const char* b, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& xored =
      Bigint::Handle(BigintOperations::BitXor(bigint_a, bigint_b));
  const char* str_xored = BigintOperations::ToHexCString(xored, &ZoneAllocator);
  EXPECT_STREQ(result, str_xored);
  const Bigint& xored2 =
      Bigint::Handle(BigintOperations::BitXor(bigint_b, bigint_a));
  const char* str_xored2 = BigintOperations::ToHexCString(xored2,
                                                          &ZoneAllocator);
  EXPECT_STREQ(result, str_xored2);
  const Bigint& xored3 =
      Bigint::Handle(BigintOperations::BitXor(bigint_a, xored2));
  const char* str_xored3 = BigintOperations::ToHexCString(xored3,
                                                          &ZoneAllocator);
  EXPECT_STREQ(b, str_xored3);
  const Bigint& xored4 =
      Bigint::Handle(BigintOperations::BitXor(xored2, bigint_a));
  const char* str_xored4 = BigintOperations::ToHexCString(xored4,
                                                          &ZoneAllocator);
  EXPECT_STREQ(b, str_xored4);
  const Bigint& xored5 =
      Bigint::Handle(BigintOperations::BitXor(bigint_b, xored2));
  const char* str_xored5 = BigintOperations::ToHexCString(xored5,
                                                          &ZoneAllocator);
  EXPECT_STREQ(a, str_xored5);
  const Bigint& xored6 =
      Bigint::Handle(BigintOperations::BitXor(xored2, bigint_b));
  const char* str_xored6 = BigintOperations::ToHexCString(xored6,
                                                          &ZoneAllocator);
  EXPECT_STREQ(a, str_xored6);
}


TEST_CASE(BigintBitXor) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintBitXor(one, zero, one);
  TestBigintBitXor(one, one, zero);
  TestBigintBitXor(minus_one, zero, minus_one);
  TestBigintBitXor(minus_one, one, "-0x2");
  TestBigintBitXor(minus_one, minus_one, zero);
  TestBigintBitXor("0x5", "0x3", "0x6");
  TestBigintBitXor("0x5", minus_one, "-0x6");
  TestBigintBitXor("0x5", zero, "0x5");
  TestBigintBitXor(minus_one, "-0x8", "0x7");
  TestBigintBitXor("0x50000000", one, "0x50000001");
  TestBigintBitXor("0x50000000", minus_one, "-0x50000001");
  TestBigintBitXor("0x500000000", one, "0x500000001");
  TestBigintBitXor("0x500000000", minus_one, "-0x500000001");
  TestBigintBitXor("0x50000000000000000", one, "0x50000000000000001");
  TestBigintBitXor("0x50000000000000000", minus_one, "-0x50000000000000001");
  TestBigintBitXor("-0x50000000", "-0x50000000", zero);
  TestBigintBitXor("-0x500000000", "-0x500000000", zero);
  TestBigintBitXor("-0x50000000000000000", "-0x50000000000000000", zero);
  TestBigintBitXor("0x1234567890ABCDEF012345678",
                  "0x876543210FEDCBA0987654321",
                  "0x955115599F46064F995511559");
  TestBigintBitXor("-0x1234567890ABCDEF012345678",
                  "-0x876543210FEDCBA0987654321",
                  "0x955115599F46064F995511557");
  TestBigintBitXor("0x1234567890ABCDEF012345678",
                  "-0x876543210FEDCBA0987654321",
                  "-0x955115599F46064F995511559");
  TestBigintBitXor("0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
                  "-0x876543210FEDCBA0987654321",
                  "-0x1234567890ABCDEF012345678789ABCDEF012345F6789ABCE0");
  TestBigintBitXor("0x12345678", "0xFFFFFFF", "0x1DCBA987");
  TestBigintBitXor("0x123456789", "0xFFFFFFFF", "0x1DCBA9876");
  TestBigintBitXor("-0x10000000", "0xFFFFFFF", "-0x1");
  TestBigintBitXor("-0x100000000", "0xFFFFFFFF", "-0x1");
  TestBigintBitXor("-0x10000001", "0xFFFFFFF", "-0x20000000");
  TestBigintBitXor("-0x100000001", "0xFFFFFFFF", "-0x200000000");
  TestBigintBitXor("-0x10000001", "0x3FFFFFFF", "-0x30000000");
  TestBigintBitXor("-0x100000001", "0x3FFFFFFFF", "-0x300000000");
  TestBigintBitXor("-0x10000000000000001",
                   "0x3FFFFFFFFFFFFFFFF",
                   "-0x30000000000000000");
  TestBigintBitXor("-0x100000000000000", "0xFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitXor("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "-0x1");
  TestBigintBitXor("-0x300000000000000",
                   "0xFFFFFFFFFFFFFFF",
                   "-0xD00000000000001");
  TestBigintBitXor("-0x30000000000000000",
                   "0xFFFFFFFFFFFFFFFFF",
                   "-0xD0000000000000001");
  TestBigintBitXor("-0x10000000", "-0x10000000", zero);
  TestBigintBitXor("-0x100000000", "-0x100000000", zero);
  TestBigintBitXor("-0x100000000000000", "-0x100000000000000", zero);
  TestBigintBitXor("-0x10000000000000000", "-0x10000000000000000", zero);
  TestBigintBitXor("-0x10000000", "-0x10000001", "0x1FFFFFFF");
  TestBigintBitXor("-0x100000000", "-0x100000001", "0x1FFFFFFFF");
  TestBigintBitXor("-0x100000000000000",
                   "-0x100000000000001",
                   "0x1FFFFFFFFFFFFFF");
  TestBigintBitXor("-0x10000000000000000",
                   "-0x10000000000000001",
                   "0x1FFFFFFFFFFFFFFFF");
}


static void TestBigintBitNot(const char* a, const char* result) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& inverted =
      Bigint::Handle(BigintOperations::BitNot(bigint_a));
  const char* str_inverted = BigintOperations::ToHexCString(inverted,
                                                            &ZoneAllocator);
  EXPECT_STREQ(result, str_inverted);
  const Bigint& back =
      Bigint::Handle(BigintOperations::BitNot(inverted));
  const char* str_back = BigintOperations::ToHexCString(back, &ZoneAllocator);
  EXPECT_STREQ(a, str_back);
}


TEST_CASE(BigintBitNot) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintBitNot(zero, minus_one);
  TestBigintBitNot(one, "-0x2");
  TestBigintBitNot("0x5", "-0x6");
  TestBigintBitNot("0x50000000", "-0x50000001");
  TestBigintBitNot("0xFFFFFFF", "-0x10000000");
  TestBigintBitNot("0xFFFFFFFF", "-0x100000000");
  TestBigintBitNot("0xFFFFFFFFFFFFFF", "-0x100000000000000");
  TestBigintBitNot("0xFFFFFFFFFFFFFFFF", "-0x10000000000000000");
  TestBigintBitNot("0x1234567890ABCDEF012345678",
                   "-0x1234567890ABCDEF012345679");
}


#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
static void TestBigintMultiplyDivide(const char* a,
                                     const char* b,
                                     const char* product) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& computed_product =
      Bigint::Handle(BigintOperations::Multiply(bigint_a, bigint_b));
  const char* str_product = BigintOperations::ToHexCString(computed_product,
                                                           &ZoneAllocator);
  EXPECT_STREQ(product, str_product);
  const Bigint& computed_product2 =
      Bigint::Handle(BigintOperations::Multiply(bigint_b, bigint_a));
  const char* str_product2 = BigintOperations::ToHexCString(computed_product2,
                                                            &ZoneAllocator);
  EXPECT_STREQ(product, str_product2);

  const Bigint& bigint_product =
      Bigint::Handle(BigintOperations::NewFromCString(product));
  if (!bigint_a.IsZero()) {
    const Bigint& computed_quotient1 =
        Bigint::Handle(BigintOperations::Divide(bigint_product, bigint_a));
    const char* str_quotient1 =
        BigintOperations::ToHexCString(computed_quotient1, &ZoneAllocator);
    EXPECT_STREQ(b, str_quotient1);
  }

  if (!bigint_b.IsZero()) {
    const Bigint& computed_quotient2 =
        Bigint::Handle(BigintOperations::Divide(bigint_product, bigint_b));
    const char* str_quotient2 =
        BigintOperations::ToHexCString(computed_quotient2, &ZoneAllocator);
    EXPECT_STREQ(a, str_quotient2);
  }
}


TEST_CASE(BigintMultiplyDivide) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintMultiplyDivide(zero, zero, zero);
  TestBigintMultiplyDivide(one, one, one);
  TestBigintMultiplyDivide(one, zero, zero);
  TestBigintMultiplyDivide(zero, one, zero);
  TestBigintMultiplyDivide(one, minus_one, minus_one);
  TestBigintMultiplyDivide(minus_one, minus_one, one);
  TestBigintMultiplyDivide("0x42", one, "0x42");
  TestBigintMultiplyDivide("0x42", "0x2", "0x84");
  TestBigintMultiplyDivide("0xFFFF", "0x2", "0x1FFFE");
  TestBigintMultiplyDivide("0x3", "0x5", "0xF");
  TestBigintMultiplyDivide("0xFFFFF", "0x5", "0x4FFFFB");
  TestBigintMultiplyDivide("0xFFFFFFF", "0x5", "0x4FFFFFFB");
  TestBigintMultiplyDivide("0xFFFFFFFF", "0x5", "0x4FFFFFFFB");
  TestBigintMultiplyDivide("0xFFFFFFFFFFFFFFFF", "0x5", "0x4FFFFFFFFFFFFFFFB");
  TestBigintMultiplyDivide("0xFFFFFFFFFFFFFFFF", "0x3039",
                           "0x3038FFFFFFFFFFFFCFC7");
  TestBigintMultiplyDivide("0xFFFFFFFFFFFFFFFF",
                           "0xFFFFFFFFFFFFFFFFFFFFFFFFFF",
                           "0xFFFFFFFFFFFFFFFEFFFFFFFFFF0000000000000001");
  TestBigintMultiplyDivide(
      "0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000",
      "0xFFFFFFFFFFFFFFFEFFFFFFFFFF000000000000000100000000000000"
      "000000000000000000000000000000000000000000000000000000000000");
  TestBigintMultiplyDivide("0x10000001", "0x5", "0x50000005");
  TestBigintMultiplyDivide(
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF01234567890ABCDEF",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF01234567890ABCDEF",
      "0x14B66DC328828BCA670CBE52943AA3894CCCE15C8F5ED1E55F"
      "328F6D3F579F992299850C4B5B95213EF3FB7B4E73B5F43D4299"
      "5B9F6FD5441C275F2FF89F86F28F47A94CA37481090DCCCDCA6475F09A2F2A521");
  TestBigintMultiplyDivide(
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027"
      "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE70");
  TestBigintMultiplyDivide(
      "0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFF",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000000000000000000000000000000000000000000001");
  TestBigintMultiplyDivide(
      "0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFF",
      "0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFF",
      "0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFC0000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000001");

  // A 256 28-bit digits number squared.
  TestBigintMultiplyDivide(
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000000000000000000000000000000001");


  TestBigintMultiplyDivide(
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "000000000000000000000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000000000000000000000000000000001");
}
#endif


static void TestBigintDivideRemainder(const char* a,
                                      const char* b,
                                      const char* quotient,
                                      const char* remainder) {
  const Bigint& bigint_a = Bigint::Handle(BigintOperations::NewFromCString(a));
  const Bigint& bigint_b = Bigint::Handle(BigintOperations::NewFromCString(b));
  const Bigint& computed_quotient =
      Bigint::Handle(BigintOperations::Divide(bigint_a, bigint_b));
  const Bigint& computed_remainder =
      Bigint::Handle(BigintOperations::Remainder(bigint_a, bigint_b));
  const char* str_quotient = BigintOperations::ToHexCString(computed_quotient,
                                                            &ZoneAllocator);
  const char* str_remainder =
      BigintOperations::ToHexCString(computed_remainder, &ZoneAllocator);
  EXPECT_STREQ(quotient, str_quotient);
  EXPECT_STREQ(remainder, str_remainder);
}


TEST_CASE(BigintDivideRemainder) {
  const char* zero = "0x0";
  const char* one = "0x1";
  const char* minus_one = "-0x1";

  TestBigintDivideRemainder(one, one, one, zero);
  TestBigintDivideRemainder(zero, one, zero, zero);
  TestBigintDivideRemainder(minus_one, one, minus_one, zero);
  TestBigintDivideRemainder(one, "0x2", zero, one);
  TestBigintDivideRemainder(minus_one, "0x7", zero, minus_one);
  TestBigintDivideRemainder("0xB", "0x7", one, "0x4");
  TestBigintDivideRemainder("0x12345678", "0x7", "0x299C335", "0x5");
  TestBigintDivideRemainder("-0x12345678", "0x7", "-0x299C335", "-0x5");
  TestBigintDivideRemainder("0x12345678", "-0x7", "-0x299C335", "0x5");
  TestBigintDivideRemainder("-0x12345678", "-0x7", "0x299C335", "-0x5");
  TestBigintDivideRemainder("0x7", "0x12345678", zero, "0x7");
  TestBigintDivideRemainder("-0x7", "0x12345678", zero, "-0x7");
  TestBigintDivideRemainder("-0x7", "-0x12345678", zero, "-0x7");
  TestBigintDivideRemainder("0x7", "-0x12345678", zero, "0x7");
  TestBigintDivideRemainder("0x12345678", "0x7", "0x299C335", "0x5");
  TestBigintDivideRemainder("-0x12345678", "0x7", "-0x299C335", "-0x5");
  TestBigintDivideRemainder("0x12345678", "-0x7", "-0x299C335", "0x5");
  TestBigintDivideRemainder("-0x12345678", "-0x7", "0x299C335", "-0x5");
  TestBigintDivideRemainder(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027"
      "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE70",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      zero);
  TestBigintDivideRemainder(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027"
      "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE71",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      one);
  TestBigintDivideRemainder(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B5710591E051CF233A56DEA99087BDC08417F08B6758E"
      "E5EA90FCF7B39165D365D139DC60403E8743421AC5E",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEE");
}

}  // namespace dart
