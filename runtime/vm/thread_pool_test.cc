// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/os.h"
#include "vm/lockers.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

DECLARE_FLAG(int, worker_timeout_millis);


class ThreadPoolTestPeer {
 public:
  // When the pool has an exit monitor, workers notify a monitor just
  // before they exit.  This is only used in tests to make sure that
  // Shutdown works.
  static void SetExitMonitor(Monitor* exit_monitor, int* exit_count) {
    ThreadPool::exit_monitor_ = exit_monitor;
    ThreadPool::exit_count_ = exit_count;
  }
};


UNIT_TEST_CASE(ThreadPool_Create) {
  ThreadPool thread_pool;
}


class TestTask : public ThreadPool::Task {
 public:
  TestTask(Monitor* sync, bool* done)
      : sync_(sync), done_(done) {
  }

  virtual void Run() {
    MonitorLocker ml(sync_);
    *done_ = true;
    ml.Notify();
  }

 private:
  Monitor* sync_;
  bool* done_;
};


UNIT_TEST_CASE(ThreadPool_RunOne) {
  ThreadPool thread_pool;
  Monitor sync;
  bool done = false;
  thread_pool.Run(new TestTask(&sync, &done));
  {
    MonitorLocker ml(&sync);
    while (!done) {
      ml.Wait();
    }
  }
  EXPECT(done);

  // Do a sanity test on the worker stats.
  EXPECT_EQ(1U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());
}


UNIT_TEST_CASE(ThreadPool_RunMany) {
  const int kTaskCount = 100;
  ThreadPool thread_pool;
  Monitor sync[kTaskCount];
  bool done[kTaskCount];

  for (int i = 0; i < kTaskCount; i++) {
    done[i] = false;
    thread_pool.Run(new TestTask(&sync[i], &done[i]));
  }
  for (int i = 0; i < kTaskCount; i++) {
    MonitorLocker ml(&sync[i]);
    while (!done[i]) {
      ml.Wait();
    }
    EXPECT(done[i]);
  }
}


class SleepTask : public ThreadPool::Task {
 public:
  explicit SleepTask(int millis)
      : millis_(millis) {
  }

  virtual void Run() {
    OS::Sleep(millis_);
  }

 private:
  int millis_;
};


UNIT_TEST_CASE(ThreadPool_WorkerShutdown) {
  Monitor exit_sync;
  int exit_count = 0;
  MonitorLocker ml(&exit_sync);

  // Set up the ThreadPool so that workers notify before they exit.
  ThreadPool* thread_pool = new ThreadPool();
  ThreadPoolTestPeer::SetExitMonitor(&exit_sync, &exit_count);

  // Run a single task.
  thread_pool->Run(new SleepTask(2));

  // Kill the thread pool.
  delete thread_pool;
  thread_pool = NULL;

  // Wait for the workers to terminate.
  while (exit_count == 0) {
    ml.Wait();
  }
  EXPECT_EQ(1, exit_count);
}


UNIT_TEST_CASE(ThreadPool_WorkerTimeout) {
  // Adjust the worker timeout so that we timeout quickly.
  int saved_timeout = FLAG_worker_timeout_millis;
  FLAG_worker_timeout_millis = 1;

  ThreadPool thread_pool;
  EXPECT_EQ(0U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());

  // Run a worker.
  Monitor sync;
  bool done = false;
  thread_pool.Run(new TestTask(&sync, &done));
  EXPECT_EQ(1U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());
  {
    MonitorLocker ml(&sync);
    while (!done) {
      ml.Wait();
    }
  }
  EXPECT(done);

  // Wait up to 5 seconds to see if a worker times out.
  const int kMaxWait = 5000;
  int waited = 0;
  while (thread_pool.workers_stopped() == 0 && waited < kMaxWait) {
    OS::Sleep(1);
    waited += 1;
  }
  EXPECT_EQ(1U, thread_pool.workers_stopped());
  FLAG_worker_timeout_millis = saved_timeout;
}


class SpawnTask : public ThreadPool::Task {
 public:
  SpawnTask(ThreadPool* pool, Monitor* sync, int todo, int total, int* done)
      : pool_(pool), sync_(sync), todo_(todo), total_(total), done_(done) {
  }

  virtual void Run() {
    todo_--;  // Subtract one for current task.
    int child_todo = todo_ / 2;

    // Spawn 0-2 children.
    if (todo_ > 0) {
      pool_->Run(
          new SpawnTask(pool_, sync_, todo_ - child_todo, total_, done_));
    }
    if (todo_ > 1) {
      pool_->Run(
          new SpawnTask(pool_, sync_, child_todo, total_, done_));
    }

    {
      MonitorLocker ml(sync_);
      (*done_)++;
      if (*done_ >= total_) {
        ml.Notify();
      }
    }
  }

 private:
  ThreadPool* pool_;
  Monitor* sync_;
  int todo_;
  int total_;
  int* done_;
};


UNIT_TEST_CASE(ThreadPool_RecursiveSpawn) {
  ThreadPool thread_pool;
  Monitor sync;
  const int kTotalTasks = 500;
  int done = 0;
  thread_pool.Run(
      new SpawnTask(&thread_pool, &sync, kTotalTasks, kTotalTasks, &done));
  {
    MonitorLocker ml(&sync);
    while (done < kTotalTasks) {
      ml.Wait();
    }
  }
  EXPECT_EQ(kTotalTasks, done);
}


}  // namespace dart
