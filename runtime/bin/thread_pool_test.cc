// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"
#include "bin/thread.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"


UNIT_TEST_CASE(ThreadPoolStartStop) {
  ThreadPool thread_pool(NULL, 10);
  thread_pool.Start();
  thread_pool.Shutdown();
}


static dart::Monitor* monitor = NULL;
static uint32_t task_count = 0;
static uint32_t task_sum = 0;


void TestTaskHandler(ThreadPool::Task args) {
  MonitorLocker ml(monitor);
  task_count++;
  task_sum += reinterpret_cast<int>(args);
}


UNIT_TEST_CASE(ThreadPoolTest1) {
  static const uint32_t kNumTestThreads = 10;
  static const uint32_t kNumTestTasks = 1000;
  static const uint32_t kNumLoops = 100;
  monitor = new dart::Monitor();
  ThreadPool thread_pool(&TestTaskHandler, kNumTestThreads);
  uint32_t pool_start_count = 0;
  while (pool_start_count++ < kNumLoops) {
    task_count = 0;
    task_sum = 0;
    thread_pool.Start();
    for (uint32_t i = 1; i <= kNumTestTasks; i++) {
      bool result =
          thread_pool.InsertTask(reinterpret_cast<ThreadPool::Task>(i));
      EXPECT(result);
    }
    thread_pool.Shutdown(ThreadPool::kDrain);

    EXPECT_EQ(kNumTestTasks, task_count);
    EXPECT_EQ((1 + kNumTestTasks) * (kNumTestTasks / 2), task_sum);
  }

  delete monitor;
  monitor = NULL;
}


UNIT_TEST_CASE(ThreadPoolTest2) {
  static const uint32_t kNumTestThreads = 10;
  static const uint32_t kNumTestTasks = 50000;
  static const uint32_t kNumLoops = 100;
  monitor = new dart::Monitor();
  ThreadPool thread_pool(&TestTaskHandler, kNumTestThreads);
  for (uint32_t i = 1; i <= kNumTestTasks; i++) {
    bool result =
        thread_pool.InsertTask(reinterpret_cast<ThreadPool::Task>(i));
    EXPECT(result);
  }

  // Start and stop the thread pool without draining the queue a
  // number of times.
  uint32_t pool_start_count = 0;
  while (pool_start_count++ < kNumLoops) {
    thread_pool.Start();
    dart::OS::Sleep(1);
    thread_pool.Shutdown(ThreadPool::kDoNotDrain);
  }
  // Finally start and drain the queue to get all messages processed.
  thread_pool.Start();
  thread_pool.Shutdown(ThreadPool::kDrain);

  // Check that all tasks where processed.
  EXPECT_EQ(kNumTestTasks, task_count);
  EXPECT_EQ((1 + kNumTestTasks) * (kNumTestTasks / 2), task_sum);

  delete monitor;
  monitor = NULL;
}
