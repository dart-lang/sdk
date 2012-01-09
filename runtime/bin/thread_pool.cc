// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"

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
