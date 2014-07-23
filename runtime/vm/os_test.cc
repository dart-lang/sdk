// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/globals.h"
#include "vm/os.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(Sleep) {
  int64_t start_time = OS::GetCurrentTimeMillis();
  int64_t sleep_time = 702;
  OS::Sleep(sleep_time);
  int64_t delta = OS::GetCurrentTimeMillis() - start_time;
  const int kAcceptableSleepWakeupJitter = 200;  // Measured in milliseconds.
  EXPECT_GE(delta, sleep_time - kAcceptableSleepWakeupJitter);
  EXPECT_LE(delta, sleep_time + kAcceptableSleepWakeupJitter);
}


UNIT_TEST_CASE(SNPrint) {
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
UNIT_TEST_CASE(SNPrint_BadArgs) {
  int width = kMaxInt32;
  int num = 7;
  OS::SNPrint(NULL, 0, "%*d%*d", width, num, width, num);
}


UNIT_TEST_CASE(OsFuncs) {
  EXPECT(Utils::IsPowerOfTwo(OS::ActivationFrameAlignment()));
  EXPECT(Utils::IsPowerOfTwo(OS::PreferredCodeAlignment()));
  int procs = OS::NumberOfAvailableProcessors();
  EXPECT_LE(1, procs);
}


UNIT_TEST_CASE(OSAlignedAllocate) {
  // TODO(johnmccutchan): Test other alignments, once we support
  // alignments != 16 on Mac.
  void* p1 = OS::AlignedAllocate(1023, 16);
  void* p2 = OS::AlignedAllocate(1025, 16);
  void* p3 = OS::AlignedAllocate(1025, 16);
  void* p4 = OS::AlignedAllocate(1, 16);
  void* p5 = OS::AlignedAllocate(2, 16);
  void* p6 = OS::AlignedAllocate(4, 16);
  EXPECT((reinterpret_cast<intptr_t>(p1) & 15) == 0);
  EXPECT((reinterpret_cast<intptr_t>(p2) & 15) == 0);
  EXPECT((reinterpret_cast<intptr_t>(p3) & 15) == 0);
  EXPECT((reinterpret_cast<intptr_t>(p4) & 15) == 0);
  EXPECT((reinterpret_cast<intptr_t>(p5) & 15) == 0);
  EXPECT((reinterpret_cast<intptr_t>(p6) & 15) == 0);
  OS::AlignedFree(p1);
  OS::AlignedFree(p2);
  OS::AlignedFree(p3);
  OS::AlignedFree(p4);
  OS::AlignedFree(p5);
  OS::AlignedFree(p6);
}

}  // namespace dart
