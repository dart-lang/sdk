// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_THREAD_POOL_H_
#define BIN_THREAD_POOL_H_

#include "bin/builtin.h"
#include "platform/globals.h"
#include "platform/thread.h"

class ThreadPool {
 public:
  typedef void* Task;
  typedef void (*TaskHandler)(Task args);

  enum DrainFlag {
    kDrain,
    kDoNotDrain
  };

  ThreadPool(TaskHandler task_handler, int initial_number_of_threads = 4)
      : initial_number_of_threads_(initial_number_of_threads),
        terminate_(false),
        drain_flag_(kDoNotDrain),
        number_of_threads_(0),
        head_(NULL),
        tail_(NULL),
        task_handler_(task_handler) {}

  // Start the thread pool.
  void Start();

  // Shutdown the thread pool. The drain flags specifies whether all
  // tasks pending in the queue will be processed. When this function
  // returns all threads are terminated.
  void Shutdown(DrainFlag drain_flag = kDoNotDrain);

  // Insert a new task into the thread pool. Returns true on success.
  bool InsertTask(Task task);

 private:
  class TaskQueueEntry {
   public:
    explicit TaskQueueEntry(Task task) : task_(task), next_(NULL) {}

    Task task() { return task_; }
    TaskQueueEntry* next() { return next_; }
    void set_next(TaskQueueEntry* value) { next_ = value; }

   private:
    Task task_;
    TaskQueueEntry* next_;

    DISALLOW_COPY_AND_ASSIGN(TaskQueueEntry);
  };


  TaskQueueEntry* WaitForTask();
  void ThreadTerminated();

  static void Main(uword args);

  dart::Monitor monitor_;  // Monitor protecting all shared state.

  int initial_number_of_threads_;  // Initial number of threads to start.
  bool terminate_;  // Set to true when the thread pool is terminating.
  DrainFlag drain_flag_;  // Queue handling before termination.
  int number_of_threads_;  // Current number of threads.

  // The task queue is a single linked list. Link direction is from tail
  // to head. New entries are inserted at the tail and entries are
  // removed from the head.
  TaskQueueEntry* head_;
  TaskQueueEntry* tail_;
  TaskHandler task_handler_;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

#endif  // BIN_THREAD_POOL_H_
