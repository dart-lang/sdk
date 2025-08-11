// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_POOL_H_
#define RUNTIME_VM_THREAD_POOL_H_

#include <functional>
#include <memory>
#include <utility>

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/intrusive_dlist.h"
#include "vm/lockers.h"
#include "vm/os_thread.h"

namespace dart {

class MutexLocker;

class ThreadPool {
 public:
  // Subclasses of Task are able to run on a ThreadPool.
  class Task : public IntrusiveDListEntry<Task> {
   protected:
    Task() {}

   public:
    virtual ~Task() {}

    // Override this to provide task-specific behavior.
    virtual void Run() = 0;

   private:
    DISALLOW_COPY_AND_ASSIGN(Task);
  };

  explicit ThreadPool(uintptr_t max_pool_size = 0);

  // Prevent scheduling of new tasks, wait until all pending tasks are done
  // and join worker threads.
  virtual ~ThreadPool();

  // Runs a task on the thread pool.
  template <typename T, typename... Args>
  bool Run(Args&&... args) {
    return RunImpl(std::unique_ptr<Task>(new T(std::forward<Args>(args)...)));
  }
  bool Run(Task* task) { return RunImpl(std::unique_ptr<Task>(task)); }

  // Returns `true` if the current thread is running on the [this] thread pool.
  bool CurrentThreadIsWorker();

  // Mark the current thread as being blocked (e.g. in native code). This might
  // temporarily increase the max thread pool size.
  void MarkCurrentWorkerAsBlocked();
  void MarkWorkerAsBlocked(OSThread* thread);

  // Mark the current thread as being unblocked. Must be called iff
  // [MarkCurrentWorkerAsBlocked] was called before and the thread is now ready
  // to continue executing.
  void MarkCurrentWorkerAsUnBlocked();

  // Triggers shutdown, prevents scheduling of new tasks and waits for all
  // worker threads to exit.
  //
  // Existing tasks are executed to completion.
  void Shutdown();

  // Prevent scheduling of new tasks on |pool| and request it to shutdown
  // after all currently running tasks finish. |shutdown_complete| will be
  // invoked when shutdown is complete. This might happen synchronously
  // if all workers are already stopped or on one of the worker threads.
  //
  // It is safe to delete |pool| from |shutdown_complete|.
  static void RequestShutdown(ThreadPool* pool,
                              std::function<void(void)>&& shutdown_complete);

#if defined(TESTING)
  uint64_t workers_started() const {
    MutexLocker ml(&pool_mutex_);
    return count_idle_ + count_running_;
  }
  bool has_pending_dead_worker() const {
    MutexLocker ml(&pool_mutex_);
    return last_dead_worker_ != nullptr;
  }
#endif

 protected:
  class Worker : public IntrusiveDListEntry<Worker> {
   public:
    explicit Worker(ThreadPool* pool);

    // Starts the thread for the worker.  This should only be called
    // after a task has been set by the initial call to SetTask().
    void StartThread();

    ConditionVariable::WaitResult Sleep(int64_t timeout_micros) {
      return wakeup_cv_.WaitMicros(&pool_->pool_mutex_, timeout_micros);
    }

   private:
    friend class ThreadPool;

    void Wakeup() { wakeup_cv_.Notify(); }

    // The main entry point for new worker threads.
    static void Main(uword args);

    // Fields initialized during construction or in start of main function of
    // thread.
    ThreadPool* pool_;
    ThreadJoinId join_id_;
    OSThread* os_thread_ = nullptr;
    bool is_blocked_ = false;
    ConditionVariable wakeup_cv_;

    DISALLOW_COPY_AND_ASSIGN(Worker);
  };

  // Called when the thread pool turns idle.
  //
  // Subclasses can override this to perform some action.
  // NOTE: While this function is running the thread pool will be locked.
  virtual void OnEnterIdleLocked(MutexLocker* ml, Worker* worker) {}

  // Whether a shutdown was requested.
  bool ShuttingDownLocked() { return shutting_down_; }

  // Whether new tasks are ready to be run.
  bool TasksWaitingToRunLocked() { return !tasks_.IsEmpty(); }

 private:
  static void WorkerThreadExit(ThreadPool* pool, ThreadPool::Worker* worker);

  using TaskList = IntrusiveDList<Task>;
  using WorkerList = IntrusiveDList<Worker>;

  bool RunImpl(std::unique_ptr<Task> task);
  void WorkerLoop(Worker* worker);

  Worker* ScheduleTaskLocked(std::unique_ptr<Task> task);

  std::unique_ptr<Task> TakeNextAvailableTaskLocked();

  void IdleToRunningLocked(Worker* worker);
  void RunningToIdleLocked(Worker* worker);
  DART_WARN_UNUSED_RESULT Worker* IdleToDeadLocked(Worker* worker);
  void JoinDeadWorker(Worker* worker);

  Worker* TakeLastDeadWorker();

  void RequestWorkersToShutdown();

  void DeleteLastDeadWorker();

  mutable Mutex pool_mutex_;
  bool shutting_down_ = false;
  uint64_t count_running_ = 0;
  uint64_t count_idle_ = 0;
  uint64_t count_dead_ = 0;
  WorkerList running_workers_;
  WorkerList idle_workers_;

  Worker* last_dead_worker_ = nullptr;

  uint64_t pending_tasks_ = 0;
  TaskList tasks_;

  Monitor exit_monitor_;
  std::atomic<bool> all_workers_dead_;

  // If asynchronous shutdown is requested then this callback will be
  // invoked by the last exiting worker.
  std::function<void(void)> shutdown_complete_callback_;

  uintptr_t max_pool_size_ = 0;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_POOL_H_
