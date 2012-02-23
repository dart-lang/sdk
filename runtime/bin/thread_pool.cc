// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"

#include "bin/thread.h"


bool ThreadPool::InsertTask(Task task) {
  TaskQueueEntry* entry = new TaskQueueEntry(task);
  MonitorLocker locker(&monitor_);
  if (terminate_) return false;
  if (head_ == NULL) {
    head_ = entry;
    tail_ = entry;
    locker.Notify();
  } else {
    tail_->set_next(entry);
    tail_ = entry;
  }
  return true;
}


ThreadPool::TaskQueueEntry* ThreadPool::WaitForTask() {
  MonitorLocker locker(&monitor_);
  if (terminate_ && (drain_flag_ == kDoNotDrain || head_ == NULL)) {
    return NULL;
  }
  TaskQueueEntry* result = head_;
  while (result == NULL) {
    locker.Wait();
    if (terminate_ && (drain_flag_ == kDoNotDrain || head_ == NULL)) {
      return NULL;
    }
    result = head_;
  }
  head_ = result->next();
  ASSERT(head_ != NULL || tail_ == result);
  return result;
}


void ThreadPool::Start() {
  MonitorLocker locker(&monitor_);
  terminate_ = false;
  for (int i = 0; i < initial_number_of_threads_; i++) {
    int result = dart::Thread::Start(&ThreadPool::Main,
                                     reinterpret_cast<uword>(this));
    if (result != 0) {
      FATAL1("Failed to start thread pool thread %d", result);
    }
    number_of_threads_++;
  }
}


void ThreadPool::Shutdown(DrainFlag drain_flag) {
  MonitorLocker locker(&monitor_);
  terminate_ = true;
  drain_flag_ = drain_flag;
  locker.NotifyAll();
  int shutdown_count = 0;
  while (number_of_threads_ > 0 && shutdown_count < 10) {
    locker.Wait(1000);
    shutdown_count++;
    if (number_of_threads_ > 0) {
      fprintf(stderr,
              "Waiting for thread pool termination, %d running threads\n",
              number_of_threads_);
    }
  }
  if (number_of_threads_ > 0) {
      fprintf(stderr,
              "Failed thread pool termination, still %d running threads\n",
              number_of_threads_);
  }
}


void ThreadPool::ThreadTerminated() {
  MonitorLocker locker(&monitor_);
  number_of_threads_--;
  locker.Notify();
}


void ThreadPool::Main(uword args) {
  if (Dart_IsVMFlagSet("trace_thread_pool")) {
    printf("Thread pool thread started\n");
  }
  ThreadPool* pool = reinterpret_cast<ThreadPool*>(args);
  while (true) {
    if (Dart_IsVMFlagSet("trace_thread_pool")) {
      printf("Waiting for task\n");
    }
    TaskQueueEntry* task = pool->WaitForTask();
    if (task == NULL) break;
    (*(pool->task_handler_))(task->task());
  }
  pool->ThreadTerminated();
};
