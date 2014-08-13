// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_pool.h"

#include "vm/flags.h"
#include "vm/lockers.h"

namespace dart {

DEFINE_FLAG(int, worker_timeout_millis, 5000,
            "Free workers when they have been idle for this amount of time.");

Monitor* ThreadPool::exit_monitor_ = NULL;
int* ThreadPool::exit_count_ = NULL;

ThreadPool::ThreadPool()
  : shutting_down_(false),
    all_workers_(NULL),
    idle_workers_(NULL),
    count_started_(0),
    count_stopped_(0),
    count_running_(0),
    count_idle_(0) {
}


ThreadPool::~ThreadPool() {
  Shutdown();
}


void ThreadPool::Run(Task* task) {
  Worker* worker = NULL;
  bool new_worker = false;
  {
    // We need ThreadPool::mutex_ to access worker lists and other
    // ThreadPool state.
    MutexLocker ml(&mutex_);
    if (shutting_down_) {
      return;
    }
    if (idle_workers_ == NULL) {
      worker = new Worker(this);
      ASSERT(worker != NULL);
      new_worker = true;
      count_started_++;

      // Add worker to the all_workers_ list.
      worker->all_next_ = all_workers_;
      all_workers_ = worker;
      worker->owned_ = true;
    } else {
      // Get the first worker from the idle worker list.
      worker = idle_workers_;
      idle_workers_ = worker->idle_next_;
      worker->idle_next_ = NULL;
      count_idle_--;
    }
    count_running_++;
  }
  // Release ThreadPool::mutex_ before calling Worker functions.
  ASSERT(worker != NULL);
  worker->SetTask(task);
  if (new_worker) {
    // Call StartThread after we've assigned the first task.
    worker->StartThread();
  }
}


void ThreadPool::Shutdown() {
  Worker* saved = NULL;
  {
    MutexLocker ml(&mutex_);
    shutting_down_ = true;
    saved = all_workers_;
    all_workers_ = NULL;
    idle_workers_ = NULL;

    Worker* current = saved;
    while (current != NULL) {
      Worker* next = current->all_next_;
      current->idle_next_ = NULL;
      current->owned_ = false;
      current = next;
      count_stopped_++;
    }

    count_idle_ = 0;
    count_running_ = 0;
    ASSERT(count_started_ == count_stopped_);
  }
  // Release ThreadPool::mutex_ before calling Worker functions.

  Worker* current = saved;
  while (current != NULL) {
    // We may access all_next_ without holding ThreadPool::mutex_ here
    // because the worker is no longer owned by the ThreadPool.
    Worker* next = current->all_next_;
    current->all_next_ = NULL;
    current->Shutdown();
    current = next;
  }
}


bool ThreadPool::IsIdle(Worker* worker) {
  ASSERT(worker != NULL && worker->owned_);
  for (Worker* current = idle_workers_;
       current != NULL;
       current = current->idle_next_) {
    if (current == worker) {
      return true;
    }
  }
  return false;
}


bool ThreadPool::RemoveWorkerFromIdleList(Worker* worker) {
  ASSERT(worker != NULL && worker->owned_);
  if (idle_workers_ == NULL) {
    return false;
  }

  // Special case head of list.
  if (idle_workers_ == worker) {
    idle_workers_ = worker->idle_next_;
    worker->idle_next_ = NULL;
    return true;
  }

  for (Worker* current = idle_workers_;
       current->idle_next_ != NULL;
       current = current->idle_next_) {
    if (current->idle_next_ == worker) {
      current->idle_next_ = worker->idle_next_;
      worker->idle_next_ = NULL;
      return true;
    }
  }
  return false;
}


bool ThreadPool::RemoveWorkerFromAllList(Worker* worker) {
  ASSERT(worker != NULL && worker->owned_);
  if (all_workers_ == NULL) {
    return false;
  }

  // Special case head of list.
  if (all_workers_ == worker) {
    all_workers_ = worker->all_next_;
    worker->all_next_ = NULL;
    worker->owned_ = false;
    worker->pool_ = NULL;
    return true;
  }

  for (Worker* current = all_workers_;
       current->all_next_ != NULL;
       current = current->all_next_) {
    if (current->all_next_ == worker) {
      current->all_next_ = worker->all_next_;
      worker->all_next_ = NULL;
      worker->owned_ = false;
      return true;
    }
  }
  return false;
}


void ThreadPool::SetIdle(Worker* worker) {
  MutexLocker ml(&mutex_);
  if (shutting_down_) {
    return;
  }
  ASSERT(worker->owned_ && !IsIdle(worker));
  worker->idle_next_ = idle_workers_;
  idle_workers_ = worker;
  count_idle_++;
  count_running_--;
}


bool ThreadPool::ReleaseIdleWorker(Worker* worker) {
  MutexLocker ml(&mutex_);
  if (shutting_down_) {
    return false;
  }
  // Remove from idle list.
  if (!RemoveWorkerFromIdleList(worker)) {
    return false;
  }
  // Remove from all list.
  bool found = RemoveWorkerFromAllList(worker);
  ASSERT(found);

  count_stopped_++;
  count_idle_--;
  return true;
}


ThreadPool::Task::Task() {
}


ThreadPool::Task::~Task() {
}


ThreadPool::Worker::Worker(ThreadPool* pool)
  : pool_(pool),
    task_(NULL),
    owned_(false),
    all_next_(NULL),
    idle_next_(NULL) {
}


void ThreadPool::Worker::StartThread() {
#if defined(DEBUG)
  // Must call SetTask before StartThread.
  { // NOLINT
    MonitorLocker ml(&monitor_);
    ASSERT(task_ != NULL);
  }
#endif
  int result = Thread::Start(&Worker::Main, reinterpret_cast<uword>(this));
  if (result != 0) {
    FATAL1("Could not start worker thread: result = %d.", result);
  }
}


void ThreadPool::Worker::SetTask(Task* task) {
  MonitorLocker ml(&monitor_);
  ASSERT(task_ == NULL);
  task_ = task;
  ml.Notify();
}


static int64_t ComputeTimeout(int64_t idle_start) {
  if (FLAG_worker_timeout_millis <= 0) {
    // No timeout.
    return 0;
  } else {
    int64_t waited = OS::GetCurrentTimeMillis() - idle_start;
    if (waited >= FLAG_worker_timeout_millis) {
      // We must have gotten a spurious wakeup just before we timed
      // out.  Give the worker one last desperate chance to live.  We
      // are merciful.
      return 1;
    } else {
      return FLAG_worker_timeout_millis - waited;
    }
  }
}


void ThreadPool::Worker::Loop() {
  MonitorLocker ml(&monitor_);
  int64_t idle_start;
  while (true) {
    ASSERT(task_ != NULL);
    Task* task = task_;
    task_ = NULL;

    // Release monitor while handling the task.
    monitor_.Exit();
    task->Run();
    delete task;
    monitor_.Enter();

    ASSERT(task_ == NULL);
    if (IsDone()) {
      return;
    }
    ASSERT(pool_ != NULL);
    pool_->SetIdle(this);
    idle_start = OS::GetCurrentTimeMillis();
    while (true) {
      Monitor::WaitResult result = ml.Wait(ComputeTimeout(idle_start));
      if (task_ != NULL) {
        // We've found a task.  Process it, regardless of whether the
        // worker is done_.
        break;
      }
      if (IsDone()) {
        return;
      }
      if (result == Monitor::kTimedOut &&
          pool_->ReleaseIdleWorker(this)) {
        return;
      }
    }
  }
  UNREACHABLE();
}


void ThreadPool::Worker::Shutdown() {
  MonitorLocker ml(&monitor_);
  pool_ = NULL;  // Fail fast if someone tries to access pool_.
  ml.Notify();
}


// static
void ThreadPool::Worker::Main(uword args) {
  Worker* worker = reinterpret_cast<Worker*>(args);
  worker->Loop();

  // It should be okay to access these unlocked here in this assert.
  ASSERT(!worker->owned_ &&
         worker->all_next_ == NULL &&
         worker->idle_next_ == NULL);

  // The exit monitor is only used during testing.
  if (ThreadPool::exit_monitor_) {
    MonitorLocker ml(ThreadPool::exit_monitor_);
    (*ThreadPool::exit_count_)++;
    ml.Notify();
  }
  delete worker;
}

}  // namespace dart
