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


typedef int Task;


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

 private:
  TaskQueueEntry* head_;
  TaskQueueEntry* tail_;
  TaskQueueData data_;

  DISALLOW_COPY_AND_ASSIGN(TaskQueue);
};


class ThreadPool {
 public:
  explicit ThreadPool(int initial_size = 4) : size_(initial_size) {}

  void Start();
  void Shutdown();

  void InsertTask(Task task);

 private:
  Task WaitForTask();

  static void* Main(void* args);

  TaskQueue queue;
  int size_;  // Number of threads.
  ThreadPoolData data_;

  DISALLOW_COPY_AND_ASSIGN(ThreadPool);
};

#endif  // BIN_THREAD_POOL_H_
