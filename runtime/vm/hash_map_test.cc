// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/unit_test.h"
#include "vm/hash_map.h"

namespace dart {

class TestValue {
 public:
  explicit TestValue(intptr_t x) : x_(x) { }
  intptr_t Hashcode() const { return x_ & 1; }
  bool Equals(TestValue* other) { return x_ == other->x_; }
 private:
  intptr_t x_;
};


TEST_CASE(DirectChainedHashMap) {
  DirectChainedHashMap<TestValue*> map;
  EXPECT(map.IsEmpty());
  TestValue v1(0);
  TestValue v2(1);
  TestValue v3(0);
  map.Insert(&v1);
  EXPECT(map.Lookup(&v1) == &v1);
  map.Insert(&v2);
  EXPECT(map.Lookup(&v1) == &v1);
  EXPECT(map.Lookup(&v2) == &v2);
  EXPECT(map.Lookup(&v3) == &v1);
}

}  // namespace dart
