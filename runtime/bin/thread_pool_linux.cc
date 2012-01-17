// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <pthread.h>

#include "bin/thread_pool.h"

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
