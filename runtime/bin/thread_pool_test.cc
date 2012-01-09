// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread_pool.h"

// TODO(sgjesse): Get rid of these #undefs
#undef FATAL
#undef ASSERT
#include "vm/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"


UNIT_TEST_CASE(ThreadPoolStartStop) {
  ThreadPool thread_pool(NULL, 10);
  thread_pool.Start();
  thread_pool.Shutdown();
}
