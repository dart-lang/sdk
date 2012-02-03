// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_THREAD_POOL_H_
#define BIN_THREAD_POOL_H_

#include "bin/builtin.h"
#include "platform/globals.h"
#include "platform/thread.h"

typedef void* Task;


class TaskQueueEntry {
 public:
  explicit TaskQueueEntry(Task task) : task_(task), next_(NULL) {}

  Task task() { return task_; }

  TaskQueueEntry* next() { return next_; }
  void set_next(TaskQueueEntry* value) { next_ = value; }

 private:
  Task task_;
  TaskQueueEntry* next_;
};


// The task queue is a single linked list. Link direction is from tail
// to head. New entried are inserted at the tail and entries are
// removed from the head.
class TaskQueue {
 public:
  TaskQueue() : terminate_(false), head_(NULL), tail_(NULL) {}

  void Insert(TaskQueueEntry* task);
  TaskQueueEntry* Remove();
  void Shutdown();

 private:
  bool terminate_;
  TaskQueueEntry* head_;
  TaskQueueEntry* tail_;
  dart::Monitor monitor_;

  DISALLOW_COPY_AND_ASSIGN(TaskQueue);
};


class ThreadPool {
 public:
  typedef void* (*TaskHandler)(void* args);

  ThreadPool(TaskHandler task_handler, int initial_size = 4)
      : terminate_(false),
        size_(initial_size),
        task_handler_(task_handler) {}

  void Start();
  void Shutdown();

  void InsertTask(Task task);

  void ThreadTerminated();

 private:
  Task WaitForTask();

  static void Main(uword args);

  TaskQueue queue_;
  // TODO(sgjesse): Move the monitor in TaskQueue to ThreadPool and
  // obtain it for updating terminate_.
  dart::Monitor monitor_;
  bool terminate_;
  int size_;  // Number of threads.
  TaskHandler task_handler_;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

#endif  // BIN_THREAD_POOL_H_
