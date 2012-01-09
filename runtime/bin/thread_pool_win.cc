// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"

TaskQueue::TaskQueue() : terminate_(false), head_(NULL), tail_(NULL) {
  UNIMPLEMENTED();
}


void TaskQueue::Insert(TaskQueueEntry* entry) {
  UNIMPLEMENTED();
}


void TaskQueue::Shutdown() {
  UNIMPLEMENTED();
}


TaskQueueEntry* TaskQueue::Remove() {
  UNIMPLEMENTED();
  return NULL;
}


void ThreadPool::Start() {
  UNIMPLEMENTED();
}


void ThreadPool::Shutdown() {
  UNIMPLEMENTED();
}
