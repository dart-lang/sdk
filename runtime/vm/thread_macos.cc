// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <sys/errno.h>

#include "vm/thread.h"

#include "vm/assert.h"

namespace dart {

#define VALIDATE_PTHREAD_RESULT(result) \
  if (result != 0) { \
    FATAL2("pthread error: %d (%s)", result, strerror(result)); \
  }


class ThreadStartData {
 public:
  ThreadStartData(Thread::ThreadStartFunction function,
                  uword parameter,
                  Thread* thread)
      : function_(function), parameter_(parameter), thread_(thread) {}

  Thread::ThreadStartFunction function() const { return function_; }
  uword parameter() const { return parameter_; }
  Thread* thread() const { return thread_; }

 private:
  Thread::ThreadStartFunction function_;
  uword parameter_;
  Thread* thread_;

  DISALLOW_COPY_AND_ASSIGN(ThreadStartData);
};


// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  Thread* thread = data->thread();
  delete data;

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  // When the function returns here, make sure that the thread is deleted.
  delete thread;

  return NULL;
}


Thread::Thread(ThreadStartFunction function, uword parameter) {
  pthread_attr_t attr;
  int result = pthread_attr_init(&attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_attr_setstacksize(&attr, 32 * KB);
  VALIDATE_PTHREAD_RESULT(result);

  ThreadStartData* data = new ThreadStartData(function, parameter, this);

  pthread_t tid;
  result = pthread_create(&tid,
                          &attr,
                          ThreadStart,
                          data);
  VALIDATE_PTHREAD_RESULT(result);

  data_.tid_ = tid;

  result = pthread_attr_destroy(&attr);
  VALIDATE_PTHREAD_RESULT(result);
}


Thread::~Thread() {
}


Mutex::Mutex() {
  pthread_mutexattr_t attr;
  int result = pthread_mutexattr_init(&attr);
  VALIDATE_PTHREAD_RESULT(result);

#if defined(DEBUG)
  result = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
  VALIDATE_PTHREAD_RESULT(result);
#endif  // defined(DEBUG)

  result = pthread_mutex_init(data_.mutex(), &attr);
  // Verify that creating a pthread_mutex succeeded.
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_mutexattr_destroy(&attr);
  VALIDATE_PTHREAD_RESULT(result);
}


Mutex::~Mutex() {
  int result = pthread_mutex_destroy(data_.mutex());
  // Verify that the pthread_mutex was destroyed.
  VALIDATE_PTHREAD_RESULT(result);
}


void Mutex::Lock() {
  int result = pthread_mutex_lock(data_.mutex());
  // Specifically check for dead lock to help debugging.
  ASSERT(result != EDEADLK);
  ASSERT(result == 0);  // Verify no other errors.
  // TODO(iposva): Do we need to track lock owners?
}


bool Mutex::TryLock() {
  int result = pthread_mutex_trylock(data_.mutex());
  // Return false if the lock is busy and locking failed.
  if (result == EBUSY) {
    return false;
  }
  ASSERT(result == 0);  // Verify no other errors.
  // TODO(iposva): Do we need to track lock owners?
  return true;
}


void Mutex::Unlock() {
  // TODO(iposva): Do we need to track lock owners?
  int result = pthread_mutex_unlock(data_.mutex());
  // Specifically check for wrong thread unlocking to aid debugging.
  ASSERT(result != EPERM);
  ASSERT(result == 0);  // Verify no other errors.
}


Monitor::Monitor() {
  pthread_mutexattr_t attr;
  int result = pthread_mutexattr_init(&attr);
  VALIDATE_PTHREAD_RESULT(result);

#if defined(DEBUG)
  result = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
  VALIDATE_PTHREAD_RESULT(result);
#endif  // defined(DEBUG)

  result = pthread_mutex_init(data_.mutex(), &attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_mutexattr_destroy(&attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_cond_init(data_.cond(), NULL);
  VALIDATE_PTHREAD_RESULT(result);
}


Monitor::~Monitor() {
  int result = pthread_mutex_destroy(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_cond_destroy(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}


void Monitor::Enter() {
  int result = pthread_mutex_lock(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);
  // TODO(iposva): Do we need to track lock owners?
}


void Monitor::Exit() {
  // TODO(iposva): Do we need to track lock owners?
  int result = pthread_mutex_unlock(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);
}


Monitor::WaitResult Monitor::Wait(int64_t millis) {
  // TODO(iposva): Do we need to track lock owners?
  Monitor::WaitResult retval = kNotified;
  if (millis == 0) {
    // Wait forever.
    // If the thread receives a signal, pthread_cond_wait may return 0,
    // because of a spurious wakeup.
    int result = pthread_cond_wait(data_.cond(), data_.mutex());
    VALIDATE_PTHREAD_RESULT(result);
  } else {
    struct timespec ts;
    int64_t secs = millis / 1000;
    int64_t nanos = (millis - (secs * 1000)) * 1000000;
    ts.tv_sec = secs;
    ts.tv_nsec = nanos;
    int result = pthread_cond_timedwait_relative_np(data_.cond(),
                                                    data_.mutex(),
                                                    &ts);
    ASSERT((result == 0) || (result == ETIMEDOUT));
    if (result == ETIMEDOUT) {
      retval = kTimedOut;
    }
  }
  return retval;
}


void Monitor::Notify() {
  // TODO(iposva): Do we need to track lock owners?
  int result = pthread_cond_signal(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}


void Monitor::NotifyAll() {
  // TODO(iposva): Do we need to track lock owners?
  int result = pthread_cond_broadcast(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}

}  // namespace dart
