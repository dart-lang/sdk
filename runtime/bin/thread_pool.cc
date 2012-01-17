// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"

void TaskQueue::Insert(TaskQueueEntry* entry) {
  monitor_.Enter();
  if (head_ == NULL) {
    head_ = entry;
    tail_ = entry;
    monitor_.Notify();
  } else {
    tail_->set_next(entry);
    tail_ = entry;
  }
  monitor_.Exit();
}


TaskQueueEntry* TaskQueue::Remove() {
  monitor_.Enter();
  TaskQueueEntry* result = head_;
  while (result == NULL) {
    if (terminate_) {
      monitor_.Exit();
      return NULL;
    }
    monitor_.Wait(dart::Monitor::kNoTimeout);
    if (terminate_) {
      monitor_.Exit();
      return NULL;
    }
    result = head_;
  }
  head_ = result->next();
  ASSERT(head_ != NULL || tail_ == result);
  monitor_.Exit();
  return result;
}


void TaskQueue::Shutdown() {
  monitor_.Enter();
  terminate_ = true;
  monitor_.NotifyAll();
  monitor_.Exit();
}


void ThreadPool::InsertTask(Task task) {
  TaskQueueEntry* entry = new TaskQueueEntry(task);
  queue_.Insert(entry);
}


Task ThreadPool::WaitForTask() {
  TaskQueueEntry* entry = queue_.Remove();
  if (entry == NULL) {
    return NULL;
  }
  Task task = entry->task();
  delete entry;
  return task;
}


void* ThreadPool::Main(void* args) {
  if (Dart_IsVMFlagSet("trace_thread_pool")) {
    printf("Thread pool thread started\n");
  }
  ThreadPool* pool = reinterpret_cast<ThreadPool*>(args);
  while (!pool->terminate_) {
    if (Dart_IsVMFlagSet("trace_thread_pool")) {
      printf("Waiting for task\n");
    }
    Task task = pool->WaitForTask();
    if (pool->terminate_) return NULL;
    (*(pool->task_handler_))(task);
  }
  return NULL;
};
