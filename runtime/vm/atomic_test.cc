// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/atomic.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(FetchAndIncrement) {
  uintptr_t v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42),
            AtomicOperations::FetchAndIncrement(&v));
  EXPECT_EQ(static_cast<uintptr_t>(43), v);
}


UNIT_TEST_CASE(FetchAndDecrement) {
  uintptr_t v = 42;
  EXPECT_EQ(static_cast<uintptr_t>(42),
            AtomicOperations::FetchAndDecrement(&v));
  EXPECT_EQ(static_cast<uintptr_t>(41), v);
}


UNIT_TEST_CASE(LoadRelaxed) {
  uword v = 42;
  EXPECT_EQ(static_cast<uword>(42), AtomicOperations::LoadRelaxed(&v));
}

}  // namespace dart
