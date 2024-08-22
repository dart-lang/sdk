// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_POOL_H_
#define RUNTIME_VM_THREAD_POOL_H_

#include <memory>
#include <utility>

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/intrusive_dlist.h"
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

  // Returns `true` if the current thread is running on the [this] thread pool.
  bool CurrentThreadIsWorker();

  // Mark the current thread as being blocked (e.g. in native code). This might
  // temporarily increase the max thread pool size.
  void MarkCurrentWorkerAsBlocked();

  // Mark the current thread as being unblocked. Must be called iff
  // [MarkCurrentWorkerAsBlocked] was called before and the thread is now ready
  // to continue executing.
  void MarkCurrentWorkerAsUnBlocked();

  // Triggers shutdown, prevents scheduling of new tasks.
  void Shutdown();

  // Exposed for unit test in thread_pool_test.cc
  uint64_t workers_started() const { return count_idle_ + count_running_; }
  // Exposed for unit test in thread_pool_test.cc
  uint64_t workers_stopped() const { return count_dead_; }

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
  using TaskList = IntrusiveDList<Task>;
  using WorkerList = IntrusiveDList<Worker>;

  bool RunImpl(std::unique_ptr<Task> task);
  void WorkerLoop(Worker* worker);

  Worker* ScheduleTaskLocked(std::unique_ptr<Task> task);

  std::unique_ptr<Task> TakeNextAvailableTaskLocked();

  void IdleToRunningLocked(Worker* worker);
  void RunningToIdleLocked(Worker* worker);
  void IdleToDeadLocked(Worker* worker);
  void ObtainDeadWorkersLocked(WorkerList* dead_workers_to_join);
  void JoinDeadWorkersLocked(WorkerList* dead_workers_to_join);

  Mutex pool_mutex_;
  bool shutting_down_ = false;
  uint64_t count_running_ = 0;
  uint64_t count_idle_ = 0;
  uint64_t count_dead_ = 0;
  WorkerList running_workers_;
  WorkerList idle_workers_;
  WorkerList dead_workers_;
  uint64_t pending_tasks_ = 0;
  TaskList tasks_;

  Monitor exit_monitor_;
  std::atomic<bool> all_workers_dead_;

  uintptr_t max_pool_size_ = 0;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_POOL_H_
