// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/atomic.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(FetchAndIncrement) {
  uintptr_t v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42),
            AtomicOperations::FetchAndIncrement(&v));
  EXPECT_EQ(static_cast<uintptr_t>(43), v);
}

VM_UNIT_TEST_CASE(FetchAndDecrement) {
  uintptr_t v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42),
            AtomicOperations::FetchAndDecrement(&v));
  EXPECT_EQ(static_cast<uintptr_t>(41), v);
}

VM_UNIT_TEST_CASE(FetchAndIncrementSigned) {
  intptr_t v = -42;
  EXPECT_EQ(static_cast<intptr_t>(-42),
            AtomicOperations::FetchAndIncrement(&v));
  EXPECT_EQ(static_cast<intptr_t>(-41), v);
}

VM_UNIT_TEST_CASE(FetchAndDecrementSigned) {
  intptr_t v = -42;
  EXPECT_EQ(static_cast<intptr_t>(-42),
            AtomicOperations::FetchAndDecrement(&v));
  EXPECT_EQ(static_cast<intptr_t>(-43), v);
}

VM_UNIT_TEST_CASE(IncrementBy) {
  intptr_t v = 42;
  AtomicOperations::IncrementBy(&v, 100);
  EXPECT_EQ(static_cast<intptr_t>(142), v);
}

VM_UNIT_TEST_CASE(DecrementBy) {
  intptr_t v = 42;
  AtomicOperations::DecrementBy(&v, 41);
  EXPECT_EQ(static_cast<intptr_t>(1), v);
}

VM_UNIT_TEST_CASE(LoadRelaxed) {
  uword v = 42;
  EXPECT_EQ(static_cast<uword>(42), AtomicOperations::LoadRelaxed(&v));
}

TEST_CASE(CompareAndSwapWord) {
  uword old_value = 42;
  uword new_value = 100;
  uword result =
      AtomicOperations::CompareAndSwapWord(&old_value, old_value, new_value);
  EXPECT_EQ(static_cast<uword>(42), result);
}

TEST_CASE(CompareAndSwapUint32) {
  uint32_t old_value = 42;
  uint32_t new_value = 100;
  uint32_t result =
      AtomicOperations::CompareAndSwapUint32(&old_value, old_value, new_value);
  EXPECT_EQ(static_cast<uint32_t>(42), result);
}

}  // namespace dart
