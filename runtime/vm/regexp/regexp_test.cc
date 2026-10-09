// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/regexp/regexp-interpreter.h"
#include "vm/regexp/regexp.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static ObjectPtr Match(const String& pattern, const String& subject) {
  const RegExp& regexp = RegExp::Handle(RegExp::New(pattern, RegExpFlags()));
  return RegExpStatics::Interpret(Thread::Current(), regexp, subject, 0,
                                  /*sticky=*/false);
}

ISOLATE_UNIT_TEST_CASE(RegExp_OneByteString) {
  uint8_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(OneByteString::New(chars, len, Heap::kNew));

  const String& pat =
      String::Handle(Symbols::New(thread, String::Handle(String::New("bc"))));
  TypedData& res = TypedData::Handle();
  res ^= Match(pat, str);
  EXPECT_EQ(2, res.Length());
  EXPECT_EQ(1, res.GetInt32(0 * sizeof(int32_t)));
  EXPECT_EQ(3, res.GetInt32(1 * sizeof(int32_t)));
}

ISOLATE_UNIT_TEST_CASE(RegExp_TwoByteString) {
  uint16_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(TwoByteString::New(chars, len, Heap::kNew));

  const String& pat =
      String::Handle(Symbols::New(thread, String::Handle(String::New("bc"))));
  TypedData& res = TypedData::Handle();
  res ^= Match(pat, str);
  EXPECT_EQ(2, res.Length());
  EXPECT_EQ(1, res.GetInt32(0 * sizeof(int32_t)));
  EXPECT_EQ(3, res.GetInt32(1 * sizeof(int32_t)));
}

ISOLATE_UNIT_TEST_CASE(RegExp_RangeInBounds) {
  // Normal cases within bounds.
  EXPECT_EQ(true, RangeInBounds(0, 5, 10));
  EXPECT_EQ(true, RangeInBounds(5, 5, 10));
  EXPECT_EQ(false, RangeInBounds(6, 5, 10));
  EXPECT_EQ(false, RangeInBounds(15, 0, 10));

  // Release safety checks: negative count, index, or length must return false.
  EXPECT_EQ(false, RangeInBounds(-1, 5, 10));
  EXPECT_EQ(false, RangeInBounds(10, -5, 50));
  EXPECT_EQ(false, RangeInBounds(0, -1, 10));
  EXPECT_EQ(false, RangeInBounds(0, 0, -1));
  EXPECT_EQ(false, RangeInBounds(-5, 0, 10));

  // Overflow cases near kMaxInt32: index + count >= 2^31.
  // Evaluates without forming additive overflow.
  constexpr int kMaxInt32 = 0x7FFFFFFF;
  EXPECT_EQ(false, RangeInBounds(kMaxInt32 - 10, 20, kMaxInt32));
  EXPECT_EQ(false, RangeInBounds(1 << 30, 1 << 30, kMaxInt32));
  EXPECT_EQ(true, RangeInBounds(kMaxInt32 - 10, 10, kMaxInt32));
}

}  // namespace dart
