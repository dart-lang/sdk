// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_POOL_H_
#define RUNTIME_VM_THREAD_POOL_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/os_thread.h"

namespace dart {

class ThreadPool {
 public:
  // Subclasses of Task are able to run on a ThreadPool.
  class Task {
   protected:
    Task();

   public:
    virtual ~Task();

    // Override this to provide task-specific behavior.
    virtual void Run() = 0;

   private:
    DISALLOW_COPY_AND_ASSIGN(Task);
  };

  ThreadPool();

  // Shuts down this thread pool. Causes workers to terminate
  // themselves when they are active again.
  ~ThreadPool();

  // Runs a task on the thread pool.
  bool Run(Task* task);

  // Some simple stats.
  uint64_t workers_running() const { return count_running_; }
  uint64_t workers_idle() const { return count_idle_; }
  uint64_t workers_started() const { return count_started_; }
  uint64_t workers_stopped() const { return count_stopped_; }

 private:
  class Worker {
   public:
    explicit Worker(ThreadPool* pool);

    // Sets a task on the worker.
    void SetTask(Task* task);

    // Starts the thread for the worker.  This should only be called
    // after a task has been set by the initial call to SetTask().
    void StartThread();

    // Main loop for a worker. Returns true if worker is removed from thread
    // lists, false otherwise.
    bool Loop();

    // Causes worker to terminate eventually.
    void Shutdown();

    // Get the Worker's thread id.
    ThreadId id();

   private:
    friend class ThreadPool;

    // The main entry point for new worker threads.
    static void Main(uword args);

    bool IsDone() const { return done_; }

    // Fields owned by Worker.
    Monitor monitor_;
    ThreadPool* pool_;
    Task* task_;
    ThreadId id_;
    bool done_;

    // Fields owned by ThreadPool.  Workers should not look at these
    // directly.  It's like looking at the sun.
    bool owned_;         // Protected by ThreadPool::mutex_
    Worker* all_next_;   // Protected by ThreadPool::mutex_
    Worker* idle_next_;  // Protected by ThreadPool::mutex_

    Worker* shutdown_next_;  // Protected by ThreadPool::exit_monitor

    DISALLOW_COPY_AND_ASSIGN(Worker);
  };

  class JoinList {
   public:
    explicit JoinList(ThreadJoinId id, JoinList* next) : id_(id), next_(next) {}

    // The thread pool's mutex_ must be held when calling this.
    static void AddLocked(ThreadJoinId id, JoinList** list);

    static void Join(JoinList** list);

    ThreadJoinId id() const { return id_; }
    JoinList* next() const { return next_; }

   private:
    ThreadJoinId id_;
    JoinList* next_;

    DISALLOW_COPY_AND_ASSIGN(JoinList);
  };

  void Shutdown();

  // Expensive.  Use only in assertions.
  bool IsIdle(Worker* worker);

  bool RemoveWorkerFromIdleList(Worker* worker);
  bool RemoveWorkerFromAllList(Worker* worker);

  void AddWorkerToShutdownList(Worker* worker);
  bool RemoveWorkerFromShutdownList(Worker* worker);

  void ReapExitedIdleThreads();

  // Worker operations.
  void SetIdleLocked(Worker* worker);  // Assumes mutex_ is held.
  void SetIdleAndReapExited(Worker* worker);
  bool ReleaseIdleWorker(Worker* worker);

  Mutex mutex_;
  bool shutting_down_;
  Worker* all_workers_;
  Worker* idle_workers_;
  uint64_t count_started_;
  uint64_t count_stopped_;
  uint64_t count_running_;
  uint64_t count_idle_;

  Monitor exit_monitor_;
  Worker* shutting_down_workers_;
  JoinList* join_list_;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_POOL_H_
