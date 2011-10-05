// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/globals.h"
#include "vm/random.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Random) {
  EXPECT(Random::RandomInt32() != 0);
}

}  // namespace dart
