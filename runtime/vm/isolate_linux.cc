// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <pthread.h>

#include "vm/assert.h"
#include "vm/isolate.h"

namespace dart {

#define VALIDATE_PTHREAD_RESULT(result)                                        \
  if (result != 0) {                                                           \
    FATAL2("pthread error: %d (%s)", result, strerror(result));                \
  }


// The single pthread key which stores all the thread local data for a
// thread. Since an Isolate is the central repository for storing all
// isolate specific information a single pthread key is sufficient.
pthread_key_t isolate_key = PTHREAD_KEY_UNSET;


void Isolate::SetCurrent(Isolate* current) {
  ASSERT(isolate_key != PTHREAD_KEY_UNSET);
  int result = pthread_setspecific(isolate_key, current);
  VALIDATE_PTHREAD_RESULT(result);
}


// Empty isolate init callback which is registered before VM isolate creation.
static void* VMIsolateInitCallback(void* data) {
  return reinterpret_cast<void*>(1);
}


void Isolate::InitOnce() {
  ASSERT(isolate_key == PTHREAD_KEY_UNSET);
  int result = pthread_key_create(&isolate_key, NULL);
  // Make sure creating a key was successful.
  VALIDATE_PTHREAD_RESULT(result);
  ASSERT(isolate_key != PTHREAD_KEY_UNSET);
  init_callback_ = VMIsolateInitCallback;
}

}  // namespace dart
