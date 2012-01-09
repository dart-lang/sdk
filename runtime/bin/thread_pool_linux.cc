// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <pthread.h>

#include "bin/thread_pool.h"

TaskQueue::TaskQueue() : terminate_(false), head_(NULL), tail_(NULL) {
  int result;

  result = pthread_mutex_init(data_.mutex(), NULL);
  if (result != 0) {
    FATAL("pthread_mutex_init failed");
  }

  result = pthread_cond_init(data_.cond(), NULL);
  if (result != 0) {
    FATAL("pthread_cond_init failed");
  }
}


void TaskQueue::Insert(TaskQueueEntry* entry) {
  pthread_mutex_lock(data_.mutex());
  if (head_ == NULL) {
    head_ = entry;
    tail_ = entry;
    pthread_cond_signal(data_.cond());
  } else {
    tail_->set_next(entry);
    tail_ = entry;
  }
  pthread_mutex_unlock(data_.mutex());
}


TaskQueueEntry* TaskQueue::Remove() {
  pthread_mutex_lock(data_.mutex());
  TaskQueueEntry* result = head_;
  while (result == NULL) {
    if (terminate_) {
      pthread_mutex_unlock(data_.mutex());
      return NULL;
    }
    pthread_cond_wait(data_.cond(), data_.mutex());
    if (terminate_) {
      pthread_mutex_unlock(data_.mutex());
      return NULL;
    }
    result = head_;
  }
  head_ = result->next();
  ASSERT(head_ != NULL || tail_ == result);
  pthread_mutex_unlock(data_.mutex());
  return result;
}


void TaskQueue::Shutdown() {
  pthread_mutex_lock(data_.mutex());
  terminate_ = true;
  pthread_cond_broadcast(data_.cond());
  pthread_mutex_unlock(data_.mutex());
}


void ThreadPool::Start() {
  pthread_t* threads
      = reinterpret_cast<pthread_t*>(calloc(size_, sizeof(pthread_t*)));  // NOLINT
  data_.set_threads(threads);
  for (int i = 0; i < size_; i++) {
    pthread_t handler_thread;
    int result = pthread_create(&handler_thread,
                                NULL,
                                &ThreadPool::Main,
                                this);
    if (result != 0) {
      FATAL("Create and start thread pool thread");
    }
    data_.threads()[i] = handler_thread;
  }
}


void ThreadPool::Shutdown() {
  terminate_ = true;
  queue_.Shutdown();
  for (int i = 0; i < size_; i++) {
    pthread_join(data_.threads()[i], NULL);
  }
}
