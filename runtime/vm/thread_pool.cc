// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_pool.h"

#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/lockers.h"

namespace dart {

DEFINE_FLAG(int,
            worker_timeout_millis,
            5000,
            "Free workers when they have been idle for this amount of time.");

static int64_t ComputeTimeout(int64_t idle_start) {
  int64_t worker_timeout_micros =
      FLAG_worker_timeout_millis * kMicrosecondsPerMillisecond;
  if (worker_timeout_micros <= 0) {
    // No timeout.
    return 0;
  } else {
    int64_t waited = OS::GetCurrentMonotonicMicros() - idle_start;
    if (waited >= worker_timeout_micros) {
      // We must have gotten a spurious wakeup just before we timed
      // out.  Give the worker one last desperate chance to live.  We
      // are merciful.
      return 1;
    } else {
      return worker_timeout_micros - waited;
    }
  }
}

ThreadPool::ThreadPool(uintptr_t max_pool_size)
    : all_workers_dead_(false), max_pool_size_(max_pool_size) {}

ThreadPool::~ThreadPool() {
  Shutdown();
}

void ThreadPool::RequestWorkersToShutdown() {
  MutexLocker ml(&pool_mutex_);

  // If we are just starting to shutdown threads then this should be done
  // before OSThread::DisableOSThreadCreation is called. If |OSThread| creation
  // is disabled after |Worker::StartThread| is called but before
  // |ThreadPool::Worker::Main| is called then a worker will be stuck in the
  // state idle but will never properly start and thus will never transition to
  // dead - leading to a deadlock.
  RELEASE_ASSERT(shutting_down_ || OSThread::CanCreateOSThreads());

  // Prevent scheduling of new tasks.
  shutting_down_ = true;

  if (running_workers_.IsEmpty() && idle_workers_.IsEmpty()) {
    // All workers have already died.
    all_workers_dead_ = true;
  } else {
    // Tell all idling workers to drain remaining work and then shut down.
    for (auto worker : idle_workers_) {
      worker->Wakeup();
    }
  }
}

void ThreadPool::RequestShutdown(
    ThreadPool* pool,
    std::function<void(void)>&& shutdown_complete) {
  pool->RequestWorkersToShutdown();

  {
    MonitorLocker eml(&pool->exit_monitor_);
    if (!pool->all_workers_dead_) {
      // Workers are still doing some work. Mark this pool for asynchronous
      // deletion. When the last worker finishes it will delete itself and
      // call shutdown_complete.
      pool->shutdown_complete_callback_ = std::move(shutdown_complete);
      return;
    }

    // Threads are in the process of exiting already and there is no way to ask
    // them to do additional cleanup asynchronously. We will just join the
    // last dead worker and delete it synchronously.
  }
  pool->DeleteLastDeadWorker();
  shutdown_complete();
}

void ThreadPool::Shutdown() {
  // Should not combine |Shutdown| and |RequestShutdown| on the same pool.
  ASSERT(shutdown_complete_callback_ == nullptr);

  RequestWorkersToShutdown();

  // Wait until all workers are dead. Any new death will notify the exit
  // monitor.
  {
    MonitorLocker eml(&exit_monitor_);
    while (!all_workers_dead_) {
      eml.Wait();
    }
  }

  DeleteLastDeadWorker();
}

void ThreadPool::DeleteLastDeadWorker() {
  ASSERT(all_workers_dead_);
  ASSERT(count_idle_ == 0);
  ASSERT(count_running_ == 0);
  ASSERT(idle_workers_.IsEmpty());
  ASSERT(running_workers_.IsEmpty());
  JoinDeadWorker(last_dead_worker_);
  last_dead_worker_ = nullptr;
}

bool ThreadPool::RunImpl(std::unique_ptr<Task> task) {
  Worker* new_worker = nullptr;
  {
    MutexLocker ml(&pool_mutex_);
    if (shutting_down_) {
      return false;
    }
    new_worker = ScheduleTaskLocked(std::move(task));
  }
  if (new_worker != nullptr) {
    new_worker->StartThread();
  }
  return true;
}

bool ThreadPool::CurrentThreadIsWorker() {
  auto worker =
      static_cast<Worker*>(OSThread::Current()->owning_thread_pool_worker_);
  return worker != nullptr && worker->pool_ == this;
}

void ThreadPool::MarkCurrentWorkerAsBlocked() {
  auto worker =
      static_cast<Worker*>(OSThread::Current()->owning_thread_pool_worker_);
  Worker* new_worker = nullptr;
  if (worker != nullptr) {
    MutexLocker ml(&pool_mutex_);
    ASSERT(!worker->is_blocked_);
    worker->is_blocked_ = true;
    if (max_pool_size_ > 0) {
      ++max_pool_size_;
      // This thread is blocked and therefore no longer usable as a worker.
      // If we have pending tasks and there are no idle workers, we will spawn a
      // new thread (temporarily allow exceeding the maximum pool size) to
      // handle the pending tasks.
      if (idle_workers_.IsEmpty() && pending_tasks_ > 0) {
        new_worker = new Worker(this);
        idle_workers_.Append(new_worker);
        count_idle_++;
      }
    }
  }
  if (new_worker != nullptr) {
    new_worker->StartThread();
  }
}

void ThreadPool::MarkCurrentWorkerAsUnBlocked() {
  auto worker =
      static_cast<Worker*>(OSThread::Current()->owning_thread_pool_worker_);
  if (worker != nullptr) {
    MutexLocker ml(&pool_mutex_);
    if (worker->is_blocked_) {
      worker->is_blocked_ = false;
      if (max_pool_size_ > 0) {
        --max_pool_size_;
        ASSERT(max_pool_size_ > 0);
      }
    }
  }
}

std::unique_ptr<ThreadPool::Task> ThreadPool::TakeNextAvailableTaskLocked() {
  std::unique_ptr<Task> task(tasks_.RemoveFirst());
  pending_tasks_--;
  if (pending_tasks_ > 0 && !idle_workers_.IsEmpty()) {
    // Wake up one more worker if more tasks are left.
    idle_workers_.Last()->Wakeup();
  }
  return task;
}

void ThreadPool::WorkerLoop(Worker* worker) {
  Worker* previous_dead_worker = nullptr;

  while (true) {
    MutexLocker ml(&pool_mutex_);

    if (!tasks_.IsEmpty()) {
      IdleToRunningLocked(worker);
      while (!tasks_.IsEmpty()) {
        auto task = TakeNextAvailableTaskLocked();
        MutexUnlocker mls(&ml);
        task->Run();
        ASSERT(Isolate::Current() == nullptr);
        task.reset();  // Delete the task while unlocked.
      }
      RunningToIdleLocked(worker);
    }

    if (running_workers_.IsEmpty()) {
      ASSERT(tasks_.IsEmpty());
      OnEnterIdleLocked(&ml, worker);
      if (!tasks_.IsEmpty()) {
        continue;
      }
    }

    if (shutting_down_) {
      previous_dead_worker = IdleToDeadLocked(worker);
      break;
    }

    // Sleep until we get a new task, we time out or we're shutdown.
    const int64_t idle_start = OS::GetCurrentMonotonicMicros();
    bool done = false;
    while (!done) {
      const auto result = worker->Sleep(ComputeTimeout(idle_start));

      // We have to drain all pending tasks.
      if (!tasks_.IsEmpty()) break;

      if (shutting_down_ || result == ConditionVariable::kTimedOut) {
        done = true;
        break;
      }
    }
    if (done) {
      previous_dead_worker = IdleToDeadLocked(worker);
      break;
    }
  }

  // |IdleToDeadLocked| obtained the worker which died before us, which we will
  // join here. Since every dead worker will join the previous one, all dead
  // workers effectively form a chain and it is enough to join the worker which
  // died last to join all workers which died before it.
  JoinDeadWorker(previous_dead_worker);
}

void ThreadPool::IdleToRunningLocked(Worker* worker) {
  ASSERT(idle_workers_.ContainsForDebugging(worker));
  idle_workers_.Remove(worker);
  running_workers_.Append(worker);
  count_idle_--;
  count_running_++;
}

void ThreadPool::RunningToIdleLocked(Worker* worker) {
  ASSERT(tasks_.IsEmpty());

  ASSERT(running_workers_.ContainsForDebugging(worker));
  running_workers_.Remove(worker);
  idle_workers_.Append(worker);
  count_running_--;
  count_idle_++;
}

ThreadPool::Worker* ThreadPool::IdleToDeadLocked(Worker* worker) {
  ASSERT(tasks_.IsEmpty());
  Worker* previous_dead = last_dead_worker_;

  ASSERT(idle_workers_.ContainsForDebugging(worker));
  idle_workers_.Remove(worker);
  last_dead_worker_ = worker;
  count_idle_--;

  // Notify shutdown thread that the worker thread is about to finish.
  if (shutting_down_) {
    if (running_workers_.IsEmpty() && idle_workers_.IsEmpty()) {
      all_workers_dead_ = true;
      MonitorLocker eml(&exit_monitor_);
      eml.Notify();
    }
  }

  return previous_dead;
}

void ThreadPool::JoinDeadWorker(Worker* worker) {
  if (worker != nullptr) {
    OSThread::Join(worker->join_id_);
    delete worker;
  }
}

ThreadPool::Worker* ThreadPool::ScheduleTaskLocked(std::unique_ptr<Task> task) {
  // Enqueue the new task.
  tasks_.Append(task.release());
  pending_tasks_++;
  ASSERT(pending_tasks_ >= 1);

  // Notify existing idle worker (if available).
  if (count_idle_ >= pending_tasks_) {
    ASSERT(!idle_workers_.IsEmpty());
    // We always notify only the last worker which became idle. It will wake up
    // more workers if needed.
    idle_workers_.Last()->Wakeup();
    return nullptr;
  }

  // If we have maxed out the number of threads running, we will not start a
  // new one.
  if (max_pool_size_ > 0 && (count_idle_ + count_running_) >= max_pool_size_) {
    if (!idle_workers_.IsEmpty()) {
      // We always notify only the last worker which became idle. It will
      // wake up more workers if needed.
      idle_workers_.Last()->Wakeup();
    }
    return nullptr;
  }

  // Otherwise start a new worker.
  auto new_worker = new Worker(this);
  idle_workers_.Append(new_worker);
  count_idle_++;
  return new_worker;
}

ThreadPool::Worker::Worker(ThreadPool* pool)
    : pool_(pool), join_id_(OSThread::kInvalidThreadJoinId) {}

void ThreadPool::Worker::StartThread() {
  OSThread::Start("DartWorker", &Worker::Main, reinterpret_cast<uword>(this));
}

void ThreadPool::Worker::Main(uword args) {
  // Call the thread start hook here to notify the embedder that the
  // thread pool thread has started.
  Dart_ThreadStartCallback start_cb = Dart::thread_start_callback();
  if (start_cb != nullptr) {
    start_cb();
  }

  OSThread* os_thread = OSThread::Current();
  ASSERT(os_thread != nullptr);

  Worker* worker = reinterpret_cast<Worker*>(args);
  ThreadPool* pool = worker->pool_;

  os_thread->owning_thread_pool_worker_ = worker;
  worker->os_thread_ = os_thread;

  // Once the worker quits it needs to be joined.
  worker->join_id_ = OSThread::GetCurrentThreadJoinId(os_thread);

#if defined(DEBUG)
  {
    MutexLocker ml(&pool->pool_mutex_);
    ASSERT(pool->idle_workers_.ContainsForDebugging(worker));
  }
#endif

  pool->WorkerLoop(worker);

  worker->os_thread_ = nullptr;
  os_thread->owning_thread_pool_worker_ = nullptr;

  // Call the thread exit hook here to notify the embedder that the
  // thread pool thread is exiting.
  Dart_ThreadExitCallback exit_cb = Dart::thread_exit_callback();
  if (exit_cb != nullptr) {
    exit_cb();
  }

  ThreadPool::WorkerThreadExit(pool, worker);
}

void ThreadPool::WorkerThreadExit(ThreadPool* pool, Worker* worker) {
  if (pool->shutdown_complete_callback_ != nullptr && pool->all_workers_dead_ &&
      pool->last_dead_worker_ == worker) {
    // Asynchronous shutdown was requested and this is the last exiting worker.
    // It needs to delete itself and notify the code which requested the
    // shutdown that we are done.
    // Start by detaching the thread (because nobody is going to join it) so
    // that we don't keep any thread related data structures behind.
    OSThread::Detach(worker->join_id_);
    delete worker;
    pool->last_dead_worker_ = nullptr;

    // Run the callback. It might (and most likely will) delete |pool| so this
    // should be the last time we touch the |pool| pointer.
    auto callback = pool->shutdown_complete_callback_;
    pool->shutdown_complete_callback_ = nullptr;
    callback();
  }
}

}  // namespace dart
