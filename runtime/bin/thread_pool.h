// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_THREAD_POOL_H_
#define BIN_THREAD_POOL_H_

#include "bin/builtin.h"
#include "platform/globals.h"

// Declare the OS-specific types ahead of defining the generic classes.
#if defined(TARGET_OS_LINUX)
#include "bin/thread_pool_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "bin/thread_pool_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "bin/thread_pool_win.h"
#else
#error Unknown target os.
#endif


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
  TaskQueue();

  void Insert(TaskQueueEntry* task);
  TaskQueueEntry* Remove();
  void Shutdown();

 private:
  bool terminate_;
  TaskQueueEntry* head_;
  TaskQueueEntry* tail_;
  TaskQueueData data_;

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

 private:
  Task WaitForTask();

  static void* Main(void* args);

  TaskQueue queue_;
  // TODO(sgjesse): Move the monitor in TaskQueue to ThreadPool and
  // obtain it for updating terminate_.
  bool terminate_;
  int size_;  // Number of threads.
  TaskHandler task_handler_;
  ThreadPoolData data_;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

#endif  // BIN_THREAD_POOL_H_
