// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_pool.h"

#include "vm/flags.h"
#include "vm/lockers.h"

namespace dart {

DEFINE_FLAG(int, worker_timeout_millis, 5000,
            "Free workers when they have been idle for this amount of time.");

ThreadPool::ThreadPool()
  : shutting_down_(false),
    all_workers_(NULL),
    idle_workers_(NULL),
    count_started_(0),
    count_stopped_(0),
    count_running_(0),
    count_idle_(0),
    shutting_down_workers_(NULL),
    join_list_(NULL) {
}


ThreadPool::~ThreadPool() {
  Shutdown();
}


bool ThreadPool::Run(Task* task) {
  Worker* worker = NULL;
  bool new_worker = false;
  {
    // We need ThreadPool::mutex_ to access worker lists and other
    // ThreadPool state.
    MutexLocker ml(&mutex_);
    if (shutting_down_) {
      return false;
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
      count_running_++;
    } else {
      // Get the first worker from the idle worker list.
      worker = idle_workers_;
      idle_workers_ = worker->idle_next_;
      worker->idle_next_ = NULL;
      count_idle_--;
      count_running_++;
    }
  }

  // Release ThreadPool::mutex_ before calling Worker functions.
  ASSERT(worker != NULL);
  worker->SetTask(task);
  if (new_worker) {
    // Call StartThread after we've assigned the first task.
    worker->StartThread();
  }
  return true;
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

  {
    MonitorLocker eml(&exit_monitor_);

    // First tell all the workers to shut down.
    Worker* current = saved;
    ThreadId id = OSThread::GetCurrentThreadId();
    while (current != NULL) {
      Worker* next = current->all_next_;
      ThreadId currentId = current->id();
      if (currentId != id) {
        AddWorkerToShutdownList(current);
      }
      current->Shutdown();
      current = next;
    }
    saved = NULL;

    // Wait until all workers will exit.
    while (shutting_down_workers_ != NULL) {
      // Here, we are waiting for workers to exit. When a worker exits we will
      // be notified.
      eml.Wait();
    }
  }

  // Extract the join list, and join on the threads.
  JoinList* list = NULL;
  {
    MutexLocker ml(&mutex_);
    list = join_list_;
    join_list_ = NULL;
  }

  // Join non-idle threads.
  JoinList::Join(&list);

#if defined(DEBUG)
  {
    MutexLocker ml(&mutex_);
    ASSERT(join_list_ == NULL);
  }
#endif
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
    worker->done_ = true;
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


void ThreadPool::SetIdleAndReapExited(Worker* worker) {
  JoinList* list = NULL;
  {
    MutexLocker ml(&mutex_);
    if (shutting_down_) {
      return;
    }
    ASSERT(worker->owned_ && !IsIdle(worker));
    worker->idle_next_ = idle_workers_;
    idle_workers_ = worker;
    count_idle_++;
    count_running_--;

    // While we have the lock, opportunistically grab and clear the join_list_.
    list = join_list_;
    join_list_ = NULL;
  }
  JoinList::Join(&list);
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

  // The thread for worker will exit. Add its ThreadId to the join_list_
  // so that we can join on it at the next opportunity.
  JoinList::AddLocked(OSThread::GetCurrentThreadJoinId(), &join_list_);
  count_stopped_++;
  count_idle_--;
  return true;
}


// Only call while holding the exit_monitor_
void ThreadPool::AddWorkerToShutdownList(Worker* worker) {
  worker->shutdown_next_ = shutting_down_workers_;
  shutting_down_workers_ = worker;
}


// Only call while holding the exit_monitor_
bool ThreadPool::RemoveWorkerFromShutdownList(Worker* worker) {
  ASSERT(worker != NULL);
  ASSERT(shutting_down_workers_ != NULL);

  // Special case head of list.
  if (shutting_down_workers_ == worker) {
    shutting_down_workers_ = worker->shutdown_next_;
    worker->shutdown_next_ = NULL;
    return true;
  }

  for (Worker* current = shutting_down_workers_;
       current->shutdown_next_ != NULL;
       current = current->shutdown_next_) {
    if (current->shutdown_next_ == worker) {
      current->shutdown_next_ = worker->shutdown_next_;
      worker->shutdown_next_ = NULL;
      return true;
    }
  }
  return false;
}


void ThreadPool::JoinList::AddLocked(ThreadJoinId id, JoinList** list) {
  *list = new JoinList(id, *list);
}


void ThreadPool::JoinList::Join(JoinList** list) {
  while (*list != NULL) {
    JoinList* current = *list;
    *list = current->next();
    OSThread::Join(current->id());
    delete current;
  }
}


ThreadPool::Task::Task() {
}


ThreadPool::Task::~Task() {
}


ThreadPool::Worker::Worker(ThreadPool* pool)
  : pool_(pool),
    task_(NULL),
    id_(OSThread::kInvalidThreadId),
    done_(false),
    owned_(false),
    all_next_(NULL),
    idle_next_(NULL),
    shutdown_next_(NULL) {
}


ThreadId ThreadPool::Worker::id() {
  MonitorLocker ml(&monitor_);
  return id_;
}


void ThreadPool::Worker::StartThread() {
#if defined(DEBUG)
  // Must call SetTask before StartThread.
  { // NOLINT
    MonitorLocker ml(&monitor_);
    ASSERT(task_ != NULL);
  }
#endif
  int result = OSThread::Start(&Worker::Main, reinterpret_cast<uword>(this));
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


bool ThreadPool::Worker::Loop() {
  MonitorLocker ml(&monitor_);
  int64_t idle_start;
  while (true) {
    ASSERT(task_ != NULL);
    Task* task = task_;
    task_ = NULL;

    // Release monitor while handling the task.
    monitor_.Exit();
    task->Run();
    ASSERT(Isolate::Current() == NULL);
    delete task;
    monitor_.Enter();

    ASSERT(task_ == NULL);
    if (IsDone()) {
      return false;
    }
    ASSERT(!done_);
    pool_->SetIdleAndReapExited(this);
    idle_start = OS::GetCurrentTimeMillis();
    while (true) {
      Monitor::WaitResult result = ml.Wait(ComputeTimeout(idle_start));
      if (task_ != NULL) {
        // We've found a task.  Process it, regardless of whether the
        // worker is done_.
        break;
      }
      if (IsDone()) {
        return false;
      }
      if ((result == Monitor::kTimedOut) && pool_->ReleaseIdleWorker(this)) {
        return true;
      }
    }
  }
  UNREACHABLE();
  return false;
}


void ThreadPool::Worker::Shutdown() {
  MonitorLocker ml(&monitor_);
  done_ = true;
  ml.Notify();
}


// static
void ThreadPool::Worker::Main(uword args) {
  Thread::EnsureInit();
  Worker* worker = reinterpret_cast<Worker*>(args);
  ThreadId id = OSThread::GetCurrentThreadId();
  ThreadJoinId join_id = OSThread::GetCurrentThreadJoinId();
  ThreadPool* pool;

  {
    MonitorLocker ml(&worker->monitor_);
    ASSERT(worker->task_);
    worker->id_ = id;
    pool = worker->pool_;
  }

  bool released = worker->Loop();

  // It should be okay to access these unlocked here in this assert.
  // worker->all_next_ is retained by the pool for shutdown monitoring.
  ASSERT(!worker->owned_ && (worker->idle_next_ == NULL));

  if (!released) {
    // This worker is exiting because the thread pool is being shut down.
    // Inform the thread pool that we are exiting. We remove this worker from
    // shutting_down_workers_ list because there will be no need for the
    // ThreadPool to take action for this worker.
    {
      MutexLocker ml(&pool->mutex_);
      JoinList::AddLocked(join_id, &pool->join_list_);
    }

    // worker->id_ should never be read again, so set to invalid in debug mode
    // for asserts.
#if defined(DEBUG)
    {
      MonitorLocker ml(&worker->monitor_);
      worker->id_ = OSThread::kInvalidThreadId;
    }
#endif

    // Remove from the shutdown list, delete, and notify the thread pool.
    {
      MonitorLocker eml(&pool->exit_monitor_);
      pool->RemoveWorkerFromShutdownList(worker);
      delete worker;
      eml.Notify();
    }
  } else {
    // This worker is going down because it was idle for too long. This case
    // is not due to a ThreadPool Shutdown. Thus, we simply delete the worker.
    // The worker's id is added to the thread pool's join list by
    // ReleaseIdleWorker, so in the case that the thread pool begins shutting
    // down immediately after returning from worker->Loop() above, we still
    // wait for the thread to exit by joining on it in Shutdown().
    delete worker;
  }
}

}  // namespace dart
