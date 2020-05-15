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

void ThreadPool::Shutdown() {
  {
    MonitorLocker ml(&pool_monitor_);

    // Prevent scheduling of new tasks.
    shutting_down_ = true;

    if (running_workers_.IsEmpty() && idle_workers_.IsEmpty()) {
      // All workers have already died.
      all_workers_dead_ = true;
    } else {
      // Tell workers to drain remaining work and then shut down.
      ml.NotifyAll();
    }
  }

  // Wait until all workers are dead. Any new death will notify the exit
  // monitor.
  {
    MonitorLocker eml(&exit_monitor_);
    while (!all_workers_dead_) {
      eml.Wait();
    }
  }
  ASSERT(count_idle_ == 0);
  ASSERT(count_running_ == 0);
  ASSERT(idle_workers_.IsEmpty());
  ASSERT(running_workers_.IsEmpty());

  WorkerList dead_workers_to_join;
  {
    MonitorLocker ml(&pool_monitor_);
    ObtainDeadWorkersLocked(&dead_workers_to_join);
  }
  JoinDeadWorkersLocked(&dead_workers_to_join);

  ASSERT(count_dead_ == 0);
  ASSERT(dead_workers_.IsEmpty());
}

bool ThreadPool::RunImpl(std::unique_ptr<Task> task) {
  Worker* new_worker = nullptr;
  {
    MonitorLocker ml(&pool_monitor_);
    if (shutting_down_) {
      return false;
    }
    new_worker = ScheduleTaskLocked(&ml, std::move(task));
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
    MonitorLocker ml(&pool_monitor_);
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
    MonitorLocker ml(&pool_monitor_);
    if (worker->is_blocked_) {
      worker->is_blocked_ = false;
      if (max_pool_size_ > 0) {
        --max_pool_size_;
        ASSERT(max_pool_size_ > 0);
      }
    }
  }
}

void ThreadPool::WorkerLoop(Worker* worker) {
  WorkerList dead_workers_to_join;

  while (true) {
    MonitorLocker ml(&pool_monitor_);

    if (!tasks_.IsEmpty()) {
      IdleToRunningLocked(worker);
      while (!tasks_.IsEmpty()) {
        std::unique_ptr<Task> task(tasks_.RemoveFirst());
        pending_tasks_--;
        MonitorLeaveScope mls(&ml);
        task->Run();
        ASSERT(Isolate::Current() == nullptr);
        task.reset();
      }
      RunningToIdleLocked(worker);
    }

    if (running_workers_.IsEmpty()) {
      ASSERT(tasks_.IsEmpty());
      OnEnterIdleLocked(&ml);
      if (!tasks_.IsEmpty()) {
        continue;
      }
    }

    if (shutting_down_) {
      ObtainDeadWorkersLocked(&dead_workers_to_join);
      IdleToDeadLocked(worker);
      break;
    }

    // Sleep until we get a new task, we time out or we're shutdown.
    const int64_t idle_start = OS::GetCurrentMonotonicMicros();
    bool done = false;
    while (!done) {
      const auto result = ml.WaitMicros(ComputeTimeout(idle_start));

      // We have to drain all pending tasks.
      if (!tasks_.IsEmpty()) break;

      if (shutting_down_ || result == Monitor::kTimedOut) {
        done = true;
        break;
      }
    }
    if (done) {
      ObtainDeadWorkersLocked(&dead_workers_to_join);
      IdleToDeadLocked(worker);
      break;
    }
  }

  // Before we transitioned to dead we obtained the list of previously died dead
  // workers, which we join here. Since every death of a worker will join
  // previously died workers, we keep the pending non-joined [dead_workers_] to
  // effectively 1.
  JoinDeadWorkersLocked(&dead_workers_to_join);
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

void ThreadPool::IdleToDeadLocked(Worker* worker) {
  ASSERT(tasks_.IsEmpty());

  ASSERT(idle_workers_.ContainsForDebugging(worker));
  idle_workers_.Remove(worker);
  dead_workers_.Append(worker);
  count_idle_--;
  count_dead_++;

  // Notify shutdown thread that the worker thread is about to finish.
  if (shutting_down_) {
    if (running_workers_.IsEmpty() && idle_workers_.IsEmpty()) {
      all_workers_dead_ = true;
      MonitorLocker eml(&exit_monitor_);
      eml.Notify();
    }
  }
}

void ThreadPool::ObtainDeadWorkersLocked(WorkerList* dead_workers_to_join) {
  dead_workers_to_join->AppendList(&dead_workers_);
  ASSERT(dead_workers_.IsEmpty());
  count_dead_ = 0;
}

void ThreadPool::JoinDeadWorkersLocked(WorkerList* dead_workers_to_join) {
  auto it = dead_workers_to_join->begin();
  while (it != dead_workers_to_join->end()) {
    Worker* worker = *it;
    it = dead_workers_to_join->Erase(it);

    OSThread::Join(worker->join_id_);
    delete worker;
  }
  ASSERT(dead_workers_to_join->IsEmpty());
}

ThreadPool::Worker* ThreadPool::ScheduleTaskLocked(MonitorLocker* ml,
                                                   std::unique_ptr<Task> task) {
  // Enqueue the new task.
  tasks_.Append(task.release());
  pending_tasks_++;
  ASSERT(pending_tasks_ >= 1);

  // Notify existing idle worker (if available).
  if (count_idle_ >= pending_tasks_) {
    ASSERT(!idle_workers_.IsEmpty());
    ml->Notify();
    return nullptr;
  }

  // If we have maxed out the number of threads running, we will not start a
  // new one.
  if (max_pool_size_ > 0 && (count_idle_ + count_running_) >= max_pool_size_) {
    if (!idle_workers_.IsEmpty()) {
      ml->Notify();
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
  int result = OSThread::Start("DartWorker", &Worker::Main,
                               reinterpret_cast<uword>(this));
  if (result != 0) {
    FATAL1("Could not start worker thread: result = %d.", result);
  }
}

void ThreadPool::Worker::Main(uword args) {
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
    MonitorLocker ml(&pool->pool_monitor_);
    ASSERT(pool->idle_workers_.ContainsForDebugging(worker));
  }
#endif

  pool->WorkerLoop(worker);

  worker->os_thread_ = nullptr;
  os_thread->owning_thread_pool_worker_ = nullptr;

  // Call the thread exit hook here to notify the embedder that the
  // thread pool thread is exiting.
  if (Dart::thread_exit_callback() != NULL) {
    (*Dart::thread_exit_callback())();
  }
}

}  // namespace dart
