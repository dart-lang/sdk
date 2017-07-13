// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/boolfield.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(BoolField) {
  class TestBoolField : public BoolField<1> {};
  EXPECT(TestBoolField::decode(2));
  EXPECT(!TestBoolField::decode(1));
  EXPECT_EQ(2U, TestBoolField::encode(true));
  EXPECT_EQ(0U, TestBoolField::encode(false));
  EXPECT_EQ(3U, TestBoolField::update(true, 1));
  EXPECT_EQ(1U, TestBoolField::update(false, 1));
}

}  // namespace dart
