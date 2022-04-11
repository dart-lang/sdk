// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_THREAD_ABSL_H_
#define RUNTIME_BIN_THREAD_ABSL_H_

#if !defined(RUNTIME_BIN_THREAD_H_)
#error Do not include thread_absl.h directly; use thread.h instead.
#endif

#include <pthread.h>

#include "platform/assert.h"
#include "platform/globals.h"
#include "third_party/absl/synchronization/mutex.h"

namespace dart {
namespace bin {

typedef pthread_t ThreadId;

class MutexData {
 private:
  MutexData() : mutex_() {}
  ~MutexData() {}

  absl::Mutex* mutex() { return &mutex_; }

  absl::Mutex mutex_;

  friend class Mutex;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MutexData);
};

class MonitorData {
 private:
  MonitorData() : mutex_(), cond_() {}
  ~MonitorData() {}

  absl::Mutex* mutex() { return &mutex_; }
  absl::CondVar* cond() { return &cond_; }

  absl::Mutex mutex_;
  absl::CondVar cond_;

  friend class Monitor;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MonitorData);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_THREAD_ABSL_H_
