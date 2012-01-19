// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_THREAD_POOL_WIN_H_
#define BIN_THREAD_POOL_WIN_H_

#if !defined(BIN_THREAD_POOL_H_)
#error Do not include thread_pool_win.h directly; use thread_pool.h instead.
#endif

#include "platform/globals.h"

class ThreadPoolData {
 private:
  static const int kMaxThreadPoolSize = 16;

  ThreadPoolData() { UNIMPLEMENTED(); }
  ~ThreadPoolData() {}

  friend class ThreadPool;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ThreadPoolData);
};

#endif  // BIN_THREAD_POOL_WIN_H_
