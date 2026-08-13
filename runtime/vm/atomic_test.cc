// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/atomic.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(FetchAndIncrement) {
  RelaxedAtomic<uintptr_t> v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42), v.fetch_add(1));
  EXPECT_EQ(static_cast<uintptr_t>(43), v);
}

VM_UNIT_TEST_CASE(FetchAndDecrement) {
  RelaxedAtomic<uintptr_t> v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42), v.fetch_sub(1));
  EXPECT_EQ(static_cast<uintptr_t>(41), v);
}

VM_UNIT_TEST_CASE(FetchAndIncrementSigned) {
  RelaxedAtomic<intptr_t> v = -42;
  EXPECT_EQ(static_cast<intptr_t>(-42), v.fetch_add(1));
  EXPECT_EQ(static_cast<intptr_t>(-41), v);
}

VM_UNIT_TEST_CASE(FetchAndDecrementSigned) {
  RelaxedAtomic<intptr_t> v = -42;
  EXPECT_EQ(static_cast<intptr_t>(-42), v.fetch_sub(1));
  EXPECT_EQ(static_cast<intptr_t>(-43), v);
}

VM_UNIT_TEST_CASE(IncrementBy) {
  RelaxedAtomic<intptr_t> v = 42;
  v.fetch_add(100);
  EXPECT_EQ(static_cast<intptr_t>(142), v);
}

VM_UNIT_TEST_CASE(DecrementBy) {
  RelaxedAtomic<intptr_t> v = 42;
  v.fetch_sub(41);
  EXPECT_EQ(static_cast<intptr_t>(1), v);
}

VM_UNIT_TEST_CASE(FetchOrRelaxed) {
  RelaxedAtomic<uint32_t> v = 42;
  uint32_t previous = v.fetch_or(3);
  EXPECT_EQ(static_cast<uint32_t>(42), previous);
  EXPECT_EQ(static_cast<uint32_t>(43), v);
}

VM_UNIT_TEST_CASE(FetchAndRelaxed) {
  RelaxedAtomic<uint32_t> v = 42;
  uint32_t previous = v.fetch_and(3);
  EXPECT_EQ(static_cast<uint32_t>(42), previous);
  EXPECT_EQ(static_cast<uint32_t>(2), v);
}

VM_UNIT_TEST_CASE(LoadRelaxed) {
  RelaxedAtomic<uword> v = 42;
  EXPECT_EQ(static_cast<uword>(42), v.load());
}

TEST_CASE(CompareAndSwapWord) {
  uword old_value = 42;
  RelaxedAtomic<uword> variable = {old_value};
  uword new_value = 100;
  bool success = variable.compare_exchange_strong(old_value, new_value);
  EXPECT_EQ(true, success);
  EXPECT_EQ(static_cast<uword>(42), old_value);

  old_value = 50;
  success = variable.compare_exchange_strong(old_value, new_value);
  EXPECT_EQ(false, success);
  EXPECT_EQ(static_cast<uword>(100), old_value);
}

TEST_CASE(CompareAndSwapUint32) {
  uint32_t old_value = 42;
  RelaxedAtomic<uint32_t> variable = {old_value};
  uint32_t new_value = 100;
  bool success = variable.compare_exchange_strong(old_value, new_value);
  EXPECT_EQ(true, success);
  EXPECT_EQ(static_cast<uword>(42), old_value);

  old_value = 50;
  success = variable.compare_exchange_strong(old_value, new_value);
  EXPECT_EQ(false, success);
  EXPECT_EQ(static_cast<uword>(100), old_value);
}

}  // namespace dart
