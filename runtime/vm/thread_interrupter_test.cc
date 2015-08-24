// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/thread_interrupter.h"
#include "vm/unit_test.h"

namespace dart {

class ThreadInterrupterTestHelper : public AllStatic {
 public:
  static void InterruptTest(const intptr_t run_time, const intptr_t period) {
    const double allowed_error = 0.25;  // +/- 25%
    intptr_t count = 0;
    Thread::EnsureInit();
    Thread* thread = Thread::Current();
    thread->SetThreadInterrupter(IncrementCallback, &count);
    ThreadInterrupter::SetInterruptPeriod(period);
    OS::Sleep(run_time * kMillisecondsPerSecond);
    thread->SetThreadInterrupter(NULL, NULL);
    intptr_t run_time_micros = run_time * kMicrosecondsPerSecond;
    intptr_t expected_interrupts = run_time_micros / period;
    intptr_t error = allowed_error * expected_interrupts;
    intptr_t low_bar = expected_interrupts - error;
    intptr_t high_bar = expected_interrupts + error;
    EXPECT_GE(count, low_bar);
    EXPECT_LE(count, high_bar);
  }

  static void IncrementCallback(const InterruptedThreadState& state,
                                void* data) {
    ASSERT(data != NULL);
    intptr_t* counter = reinterpret_cast<intptr_t*>(data);
    *counter = *counter + 1;
  }
};


TEST_CASE(ThreadInterrupterHigh) {
  const intptr_t kRunTimeSeconds = 5;
  const intptr_t kInterruptPeriodMicros = 250;
  ThreadInterrupterTestHelper::InterruptTest(kRunTimeSeconds,
                                             kInterruptPeriodMicros);
}

TEST_CASE(ThreadInterrupterMedium) {
  const intptr_t kRunTimeSeconds = 5;
  const intptr_t kInterruptPeriodMicros = 500;
  ThreadInterrupterTestHelper::InterruptTest(kRunTimeSeconds,
                                             kInterruptPeriodMicros);
}

TEST_CASE(ThreadInterrupterLow) {
  const intptr_t kRunTimeSeconds = 5;
  const intptr_t kInterruptPeriodMicros = 1000;
  ThreadInterrupterTestHelper::InterruptTest(kRunTimeSeconds,
                                             kInterruptPeriodMicros);
}


}  // namespace dart
