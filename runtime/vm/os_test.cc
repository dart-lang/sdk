// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(SNPrint) {
  char buffer[256];
  int length;
  length = Utils::SNPrint(buffer, 10, "%s", "foo");
  EXPECT_EQ(3, length);
  EXPECT_STREQ("foo", buffer);
  length = Utils::SNPrint(buffer, 3, "%s", "foo");
  EXPECT_EQ(3, length);
  EXPECT_STREQ("fo", buffer);
  length = Utils::SNPrint(buffer, 256, "%s%c%d", "foo", 'Z', 42);
  EXPECT_EQ(6, length);
  EXPECT_STREQ("fooZ42", buffer);
  length = Utils::SNPrint(NULL, 0, "foo");
  EXPECT_EQ(3, length);
}

VM_UNIT_TEST_CASE(OsFuncs) {
  EXPECT(Utils::IsPowerOfTwo(OS::ActivationFrameAlignment()));
  int procs = OS::NumberOfAvailableProcessors();
  EXPECT_LE(1, procs);
}

}  // namespace dart
