// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/regexp.h"
#include "vm/unit_test.h"

namespace dart {

static RawArray* Match(const String& pat, const String& str) {
  Isolate* isolate = Isolate::Current();
  const JSRegExp& regexp = JSRegExp::Handle(
      RegExpEngine::CreateJSRegExp(isolate, pat, false, false));
  const intptr_t cid = str.GetClassId();
  const Function& fn = Function::Handle(regexp.function(cid));
  EXPECT(!fn.IsNull());
  const Smi& idx = Smi::Handle(Smi::New(0));
  return IRRegExpMacroAssembler::Execute(fn, str, idx, Isolate::Current());
}

TEST_CASE(RegExp_OneByteString) {
  uint8_t chars[] = { 'a', 'b', 'c', 'b', 'a' };
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(
      OneByteString::New(chars, len, Heap::kNew));

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

TEST_CASE(RegExp_TwoByteString) {
  uint16_t chars[] = { 'a', 'b', 'c', 'b', 'a' };
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(
      TwoByteString::New(chars, len, Heap::kNew));

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

TEST_CASE(RegExp_ExternalOneByteString) {
  uint8_t chars[] = { 'a', 'b', 'c', 'b', 'a' };
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(
      ExternalOneByteString::New(chars, len, NULL, NULL, Heap::kNew));

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

TEST_CASE(RegExp_ExternalTwoByteString) {
  uint16_t chars[] = { 'a', 'b', 'c', 'b', 'a' };
  intptr_t len = ARRAY_SIZE(chars);
  const String& str = String::Handle(
      ExternalTwoByteString::New(chars, len, NULL, NULL, Heap::kNew));

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
