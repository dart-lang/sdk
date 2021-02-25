// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/regexp.h"
#include "vm/regexp_assembler_ir.h"
#include "vm/unit_test.h"

namespace dart {

static ArrayPtr Match(const String& pat, const String& str) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const RegExp& regexp =
      RegExp::Handle(RegExpEngine::CreateRegExp(thread, pat, RegExpFlags()));
  const Smi& idx = Object::smi_zero();
  return IRRegExpMacroAssembler::Execute(regexp, str, idx, /*sticky=*/false,
                                         zone);
}

ISOLATE_UNIT_TEST_CASE(RegExp_OneByteString) {
  uint8_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(OneByteString::New(chars, len, Heap::kNew));

  const String& pat = String::Handle(String::New("bc"));
  const Array& res = Array::Handle(Match(pat, str));
  EXPECT_EQ(2, res.Length());

  const Object& res_1 = Object::Handle(res.At(0));
  const Object& res_2 = Object::Handle(res.At(1));
  EXPECT(res_1.IsSmi());
  EXPECT(res_2.IsSmi());

  const Smi& smi_1 = Smi::Cast(res_1);
  const Smi& smi_2 = Smi::Cast(res_2);
  EXPECT_EQ(1, smi_1.Value());
  EXPECT_EQ(3, smi_2.Value());
}

ISOLATE_UNIT_TEST_CASE(RegExp_TwoByteString) {
  uint16_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str =
      String::Handle(TwoByteString::New(chars, len, Heap::kNew));

  const String& pat = String::Handle(String::New("bc"));
  const Array& res = Array::Handle(Match(pat, str));
  EXPECT_EQ(2, res.Length());

  const Object& res_1 = Object::Handle(res.At(0));
  const Object& res_2 = Object::Handle(res.At(1));
  EXPECT(res_1.IsSmi());
  EXPECT(res_2.IsSmi());

  const Smi& smi_1 = Smi::Cast(res_1);
  const Smi& smi_2 = Smi::Cast(res_2);
  EXPECT_EQ(1, smi_1.Value());
  EXPECT_EQ(3, smi_2.Value());
}

static void NoopFinalizer(void* isolate_callback_data, void* peer) {}

ISOLATE_UNIT_TEST_CASE(RegExp_ExternalOneByteString) {
  uint8_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(ExternalOneByteString::New(
      chars, len, NULL, 0, NoopFinalizer, Heap::kNew));

  const String& pat = String::Handle(String::New("bc"));
  const Array& res = Array::Handle(Match(pat, str));
  EXPECT_EQ(2, res.Length());

  const Object& res_1 = Object::Handle(res.At(0));
  const Object& res_2 = Object::Handle(res.At(1));
  EXPECT(res_1.IsSmi());
  EXPECT(res_2.IsSmi());

  const Smi& smi_1 = Smi::Cast(res_1);
  const Smi& smi_2 = Smi::Cast(res_2);
  EXPECT_EQ(1, smi_1.Value());
  EXPECT_EQ(3, smi_2.Value());
}

ISOLATE_UNIT_TEST_CASE(RegExp_ExternalTwoByteString) {
  uint16_t chars[] = {'a', 'b', 'c', 'b', 'a'};
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(ExternalTwoByteString::New(
      chars, len, NULL, 0, NoopFinalizer, Heap::kNew));

  const String& pat = String::Handle(String::New("bc"));
  const Array& res = Array::Handle(Match(pat, str));
  EXPECT_EQ(2, res.Length());

  const Object& res_1 = Object::Handle(res.At(0));
  const Object& res_2 = Object::Handle(res.At(1));
  EXPECT(res_1.IsSmi());
  EXPECT(res_2.IsSmi());

  const Smi& smi_1 = Smi::Cast(res_1);
  const Smi& smi_2 = Smi::Cast(res_2);
  EXPECT_EQ(1, smi_1.Value());
  EXPECT_EQ(3, smi_2.Value());
}

}  // namespace dart
