// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/unit_test.h"
#include "vm/profiler.h"

namespace dart {

UNIT_TEST_CASE(Mutex) {
  // This unit test case needs a running isolate.
  Isolate* isolate = Isolate::Init(NULL);

  Mutex* mutex = new Mutex();
  mutex->Lock();
  EXPECT_EQ(false, mutex->TryLock());
  mutex->Unlock();
  EXPECT_EQ(true, mutex->TryLock());
  mutex->Unlock();
  {
    MutexLocker ml(mutex);
    EXPECT_EQ(false, mutex->TryLock());
  }
  // The isolate shutdown and the destruction of the mutex are out-of-order on
  // purpose.
  isolate->Shutdown();
  delete isolate;
  delete mutex;
}


UNIT_TEST_CASE(Monitor) {
  // This unit test case needs a running isolate.
  Isolate* isolate = Isolate::Init(NULL);
  // Thread interrupter interferes with this test, disable interrupts.
  isolate->set_thread_state(NULL);
  Profiler::EndExecution(isolate);
  Monitor* monitor = new Monitor();
  monitor->Enter();
  monitor->Exit();

  const int kNumAttempts = 5;
  int attempts = 0;
  while (attempts < kNumAttempts) {
    MonitorLocker ml(monitor);
    int64_t start = OS::GetCurrentTimeMillis();
    int64_t wait_time = 2017;
    Monitor::WaitResult wait_result = ml.Wait(wait_time);
    int64_t stop = OS::GetCurrentTimeMillis();

    // We expect to be timing out here.
    EXPECT_EQ(Monitor::kTimedOut, wait_result);

    // Check whether this attempt falls within the exptected time limits.
    int64_t wakeup_time = stop - start;
    OS::Print("wakeup_time: %" Pd64 "\n", wakeup_time);
    const int kAcceptableTimeJitter = 20;  // Measured in milliseconds.
    const int kAcceptableWakeupDelay = 150;  // Measured in milliseconds.
    if (((wait_time - kAcceptableTimeJitter) <= wakeup_time) &&
        (wakeup_time <= (wait_time + kAcceptableWakeupDelay))) {
      break;
    }

    // Record the attempt.
    attempts++;
  }
  EXPECT_LT(attempts, kNumAttempts);

  // The isolate shutdown and the destruction of the mutex are out-of-order on
  // purpose.
  isolate->Shutdown();
  delete isolate;
  delete monitor;
}

}  // namespace dart
