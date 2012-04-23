// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/unit_test.h"
#include "vm/thread.h"

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

  Monitor* monitor = new Monitor();
  monitor->Enter();
  monitor->Exit();

  {
    MonitorLocker ml(monitor);
    int64_t start = OS::GetCurrentTimeMillis();
    int64_t wait_time = 2017;
    Monitor::WaitResult wait_result = ml.Wait(wait_time);
    int64_t stop = OS::GetCurrentTimeMillis();
    EXPECT_EQ(Monitor::kTimedOut, wait_result);
    const int kAcceptableTimeJitter = 20;  // Measured in milliseconds.
    EXPECT_LE(wait_time - kAcceptableTimeJitter, stop - start);
    const int kAcceptableWakeupDelay = 150;  // Measured in milliseconds.
    EXPECT_GE(wait_time + kAcceptableWakeupDelay, stop - start);
  }
  // The isolate shutdown and the destruction of the mutex are out-of-order on
  // purpose.
  isolate->Shutdown();
  delete isolate;
  delete monitor;
}

}  // namespace dart
