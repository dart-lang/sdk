// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/crypto.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {
namespace bin {

TEST_CASE(GetRandomBytes) {
  const intptr_t kNumRandomBytes = 127;
  uint8_t buf[kNumRandomBytes];
  const bool res = Crypto::GetRandomBytes(kNumRandomBytes, buf);
  EXPECT(res);
}

}  // namespace bin
}  // namespace dart
