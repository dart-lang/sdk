// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_pool.h"
#include "vm/lockers.h"
#include "vm/os.h"
#include "vm/unit_test.h"

namespace dart {

DECLARE_FLAG(int, worker_timeout_millis);

VM_UNIT_TEST_CASE(ThreadPool_Create) {
  ThreadPool thread_pool;
}

class TestTask : public ThreadPool::Task {
 public:
  TestTask(Monitor* sync, bool* done) : sync_(sync), done_(done) {}

  // Before running the task, *done_ should be true. This lets the caller
  // ASSERT things knowing that the thread is still around. To unblock the
  // thread, the caller should take the lock, set *done_ to false, and Notify()
  // the monitor.
  virtual void Run() {
    {
      MonitorLocker ml(sync_);
      while (*done_) {
        ml.Wait();
      }
    }
    MonitorLocker ml(sync_);
    *done_ = true;
    ml.Notify();
  }

 private:
  Monitor* sync_;
  bool* done_;
};

VM_UNIT_TEST_CASE(ThreadPool_RunOne) {
  ThreadPool thread_pool;
  Monitor sync;
  bool done = true;
  thread_pool.Run(new TestTask(&sync, &done));
  {
    MonitorLocker ml(&sync);
    done = false;
    ml.Notify();
    while (!done) {
      ml.Wait();
    }
  }
  EXPECT(done);

  // Do a sanity test on the worker stats.
  EXPECT_EQ(1U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());
}

VM_UNIT_TEST_CASE(ThreadPool_RunMany) {
  const int kTaskCount = 100;
  ThreadPool thread_pool;
  Monitor sync[kTaskCount];
  bool done[kTaskCount];

  for (int i = 0; i < kTaskCount; i++) {
    done[i] = true;
    thread_pool.Run(new TestTask(&sync[i], &done[i]));
  }
  for (int i = 0; i < kTaskCount; i++) {
    MonitorLocker ml(&sync[i]);
    done[i] = false;
    ml.Notify();
    while (!done[i]) {
      ml.Wait();
    }
    EXPECT(done[i]);
  }
}

class SleepTask : public ThreadPool::Task {
 public:
  SleepTask(Monitor* sync, int* started_count, int* slept_count, int millis)
      : sync_(sync),
        started_count_(started_count),
        slept_count_(slept_count),
        millis_(millis) {}

  virtual void Run() {
    {
      MonitorLocker ml(sync_);
      *started_count_ = *started_count_ + 1;
      ml.Notify();
    }
    // Sleep so we can be sure the ThreadPool destructor blocks until we're
    // done.
    OS::Sleep(millis_);
    {
      MonitorLocker ml(sync_);
      *slept_count_ = *slept_count_ + 1;
      // No notification here. The main thread is blocked in ThreadPool
      // shutdown waiting for this thread to finish.
    }
  }

 private:
  Monitor* sync_;
  int* started_count_;
  int* slept_count_;
  int millis_;
};

VM_UNIT_TEST_CASE(ThreadPool_WorkerShutdown) {
  const int kTaskCount = 10;
  Monitor sync;
  int slept_count = 0;
  int started_count = 0;

  // Set up the ThreadPool so that workers notify before they exit.
  ThreadPool* thread_pool = new ThreadPool();

  // Run a single task.
  for (int i = 0; i < kTaskCount; i++) {
    thread_pool->Run(new SleepTask(&sync, &started_count, &slept_count, 2));
  }

  {
    // Wait for everybody to start.
    MonitorLocker ml(&sync);
    while (started_count < kTaskCount) {
      ml.Wait();
    }
  }

  // Kill the thread pool while the workers are sleeping.
  delete thread_pool;
  thread_pool = NULL;

  int final_count = 0;
  {
    MonitorLocker ml(&sync);
    final_count = slept_count;
  }

  // We should have waited for all the workers to finish, so they all should
  // have had a chance to increment slept_count.
  EXPECT_EQ(kTaskCount, final_count);
}

VM_UNIT_TEST_CASE(ThreadPool_WorkerTimeout) {
  // Adjust the worker timeout so that we timeout quickly.
  int saved_timeout = FLAG_worker_timeout_millis;
  FLAG_worker_timeout_millis = 1;

  ThreadPool thread_pool;
  EXPECT_EQ(0U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());

  // Run a worker.
  Monitor sync;
  bool done = true;
  thread_pool.Run(new TestTask(&sync, &done));
  EXPECT_EQ(1U, thread_pool.workers_started());
  EXPECT_EQ(0U, thread_pool.workers_stopped());
  {
    MonitorLocker ml(&sync);
    done = false;
    ml.Notify();
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
      : pool_(pool), sync_(sync), todo_(todo), total_(total), done_(done) {}

  virtual void Run() {
    todo_--;  // Subtract one for current task.
    int child_todo = todo_ / 2;

    // Spawn 0-2 children.
    if (todo_ > 0) {
      pool_->Run(
          new SpawnTask(pool_, sync_, todo_ - child_todo, total_, done_));
    }
    if (todo_ > 1) {
      pool_->Run(new SpawnTask(pool_, sync_, child_todo, total_, done_));
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

VM_UNIT_TEST_CASE(ThreadPool_RecursiveSpawn) {
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
