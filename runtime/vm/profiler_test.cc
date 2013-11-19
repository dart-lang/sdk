// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/profiler.h"
#include "vm/unit_test.h"

namespace dart {

class ProfileSampleBufferTestHelper {
 public:
  static intptr_t IterateCount(const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (Sample* i = sample_buffer.FirstSample();
         i != sample_buffer.LastSample();
         i = sample_buffer.NextSample(i)) {
      c++;
    }
    return c;
  }


  static intptr_t IterateSumPC(const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (Sample* i = sample_buffer.FirstSample();
         i != sample_buffer.LastSample();
         i = sample_buffer.NextSample(i)) {
      c += i->pcs[0];
    }
    return c;
  }
};


TEST_CASE(ProfilerSampleBufferWrapTest) {
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  EXPECT_EQ(0, ProfileSampleBufferTestHelper::IterateSumPC(*sample_buffer));
  Sample* s;
  s = sample_buffer->ReserveSample();
  s->pcs[0] = 2;
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateSumPC(*sample_buffer));
  s = sample_buffer->ReserveSample();
  s->pcs[0] = 4;
  EXPECT_EQ(6, ProfileSampleBufferTestHelper::IterateSumPC(*sample_buffer));
  s = sample_buffer->ReserveSample();
  s->pcs[0] = 6;
  EXPECT_EQ(10, ProfileSampleBufferTestHelper::IterateSumPC(*sample_buffer));
  s = sample_buffer->ReserveSample();
  s->pcs[0] = 8;
  EXPECT_EQ(14, ProfileSampleBufferTestHelper::IterateSumPC(*sample_buffer));
  delete sample_buffer;
}


TEST_CASE(ProfilerSampleBufferIterateTest) {
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  EXPECT_EQ(0, ProfileSampleBufferTestHelper::IterateCount(*sample_buffer));
  sample_buffer->ReserveSample();
  EXPECT_EQ(1, ProfileSampleBufferTestHelper::IterateCount(*sample_buffer));
  sample_buffer->ReserveSample();
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateCount(*sample_buffer));
  sample_buffer->ReserveSample();
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateCount(*sample_buffer));
  sample_buffer->ReserveSample();
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateCount(*sample_buffer));
  delete sample_buffer;
}

}  // namespace dart
