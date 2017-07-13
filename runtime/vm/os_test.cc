// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"
#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(Sleep) {
  // All times measured in microseconds.
  int64_t start_time = OS::GetCurrentMonotonicMicros();
  int64_t sleep_time = 702000;
  OS::SleepMicros(sleep_time);
  int64_t delta = OS::GetCurrentMonotonicMicros() - start_time;
  const int kAcceptableSleepWakeupJitter = 200000;
  EXPECT_GE(delta, sleep_time - kAcceptableSleepWakeupJitter);
  EXPECT_LE(delta, sleep_time + kAcceptableSleepWakeupJitter);
}

VM_UNIT_TEST_CASE(SNPrint) {
  char buffer[256];
  int length;
  length = OS::SNPrint(buffer, 10, "%s", "foo");
  EXPECT_EQ(3, length);
  EXPECT_STREQ("foo", buffer);
  length = OS::SNPrint(buffer, 3, "%s", "foo");
  EXPECT_EQ(3, length);
  EXPECT_STREQ("fo", buffer);
  length = OS::SNPrint(buffer, 256, "%s%c%d", "foo", 'Z', 42);
  EXPECT_EQ(6, length);
  EXPECT_STREQ("fooZ42", buffer);
  length = OS::SNPrint(NULL, 0, "foo");
  EXPECT_EQ(3, length);
}

// This test is expected to crash when it runs.
VM_UNIT_TEST_CASE(SNPrint_BadArgs) {
  int width = kMaxInt32;
  int num = 7;
  OS::SNPrint(NULL, 0, "%*d%*d", width, num, width, num);
}

VM_UNIT_TEST_CASE(OsFuncs) {
  EXPECT(Utils::IsPowerOfTwo(OS::ActivationFrameAlignment()));
  EXPECT(Utils::IsPowerOfTwo(OS::PreferredCodeAlignment()));
  int procs = OS::NumberOfAvailableProcessors();
  EXPECT_LE(1, procs);
}

}  // namespace dart
