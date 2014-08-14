// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/thread.h"

#include <errno.h>  // NOLINT
#include <sys/time.h>  // NOLINT

#include "platform/assert.h"

namespace dart {
namespace bin {

#define VALIDATE_PTHREAD_RESULT(result) \
  if (result != 0) { \
    const int kBufferSize = 1024; \
    char error_message[kBufferSize]; \
    strerror_r(result, error_message, kBufferSize); \
    FATAL2("pthread error: %d (%s)", result, error_message); \
  }


#ifdef DEBUG
#define RETURN_ON_PTHREAD_FAILURE(result) \
  if (result != 0) { \
    const int kBufferSize = 1024; \
    char error_message[kBufferSize]; \
    strerror_r(result, error_message, kBufferSize); \
    fprintf(stderr, "%s:%d: pthread error: %d (%s)\n", \
            __FILE__, __LINE__, result, error_message); \
    return result; \
  }
#else
#define RETURN_ON_PTHREAD_FAILURE(result) \
  if (result != 0) return result;
#endif


static void ComputeTimeSpecMicros(struct timespec* ts, int64_t micros) {
  struct timeval tv;
  int64_t secs = micros / kMicrosecondsPerSecond;
  int64_t remaining_micros = (micros - (secs * kMicrosecondsPerSecond));
  int result = gettimeofday(&tv, NULL);
  ASSERT(result == 0);
  ts->tv_sec = tv.tv_sec + secs;
  ts->tv_nsec = (tv.tv_usec + remaining_micros) * kNanosecondsPerMicrosecond;
  if (ts->tv_nsec >= kNanosecondsPerSecond) {
    ts->tv_sec += 1;
    ts->tv_nsec -= kNanosecondsPerSecond;
  }
}


class ThreadStartData {
 public:
  ThreadStartData(Thread::ThreadStartFunction function,
                  uword parameter)
      : function_(function), parameter_(parameter) {}

  Thread::ThreadStartFunction function() const { return function_; }
  uword parameter() const { return parameter_; }

 private:
  Thread::ThreadStartFunction function_;
  uword parameter_;

  DISALLOW_COPY_AND_ASSIGN(ThreadStartData);
};


// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  return NULL;
}


int Thread::Start(ThreadStartFunction function, uword parameter) {
  pthread_attr_t attr;
  int result = pthread_attr_init(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_setstacksize(&attr, Thread::GetMaxStackSize());
  RETURN_ON_PTHREAD_FAILURE(result);

  ThreadStartData* data = new ThreadStartData(function, parameter);

  pthread_t tid;
  result = pthread_create(&tid, &attr, ThreadStart, data);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_destroy(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  return 0;
}


ThreadLocalKey Thread::kUnsetThreadLocalKey = static_cast<pthread_key_t>(-1);
ThreadId Thread::kInvalidThreadId = static_cast<ThreadId>(0);

ThreadLocalKey Thread::CreateThreadLocal() {
  pthread_key_t key = kUnsetThreadLocalKey;
  int result = pthread_key_create(&key, NULL);
  VALIDATE_PTHREAD_RESULT(result);
  ASSERT(key != kUnsetThreadLocalKey);
  return key;
}


void Thread::DeleteThreadLocal(ThreadLocalKey key) {
  ASSERT(key != kUnsetThreadLocalKey);
  int result = pthread_key_delete(key);
  VALIDATE_PTHREAD_RESULT(result);
}


void Thread::SetThreadLocal(ThreadLocalKey key, uword value) {
  ASSERT(key != kUnsetThreadLocalKey);
  int result = pthread_setspecific(key, reinterpret_cast<void*>(value));
  VALIDATE_PTHREAD_RESULT(result);
}


intptr_t Thread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}


ThreadId Thread::GetCurrentThreadId() {
  return gettid();
}


bool Thread::Join(ThreadId id) {
  return false;
}


intptr_t Thread::ThreadIdToIntPtr(ThreadId id) {
  ASSERT(sizeof(id) == sizeof(intptr_t));
  return static_cast<intptr_t>(id);
}


bool Thread::Compare(ThreadId a, ThreadId b) {
  return a == b;
}


void Thread::GetThreadCpuUsage(ThreadId thread_id, int64_t* cpu_usage) {
  ASSERT(thread_id == GetCurrentThreadId());
  ASSERT(cpu_usage != NULL);
  struct timespec ts;
  int r = clock_gettime(CLOCK_THREAD_CPUTIME_ID, &ts);
  ASSERT(r == 0);
  *cpu_usage = (ts.tv_sec * kNanosecondsPerSecond + ts.tv_nsec) /
               kNanosecondsPerMicrosecond;
}


void Thread::InitOnce() {
  // Nothing to be done.
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
  pthread_mutexattr_t mutex_attr;
  int result = pthread_mutexattr_init(&mutex_attr);
  VALIDATE_PTHREAD_RESULT(result);

#if defined(DEBUG)
  result = pthread_mutexattr_settype(&mutex_attr, PTHREAD_MUTEX_ERRORCHECK);
  VALIDATE_PTHREAD_RESULT(result);
#endif  // defined(DEBUG)

  result = pthread_mutex_init(data_.mutex(), &mutex_attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_mutexattr_destroy(&mutex_attr);
  VALIDATE_PTHREAD_RESULT(result);

  pthread_condattr_t cond_attr;
  result = pthread_condattr_init(&cond_attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_cond_init(data_.cond(), &cond_attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_condattr_destroy(&cond_attr);
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
  return WaitMicros(millis * kMicrosecondsPerMillisecond);
}


Monitor::WaitResult Monitor::WaitMicros(int64_t micros) {
  // TODO(iposva): Do we need to track lock owners?
  Monitor::WaitResult retval = kNotified;
  if (micros == kNoTimeout) {
    // Wait forever.
    int result = pthread_cond_wait(data_.cond(), data_.mutex());
    VALIDATE_PTHREAD_RESULT(result);
  } else {
    struct timespec ts;
    ComputeTimeSpecMicros(&ts, micros);
    int result = pthread_cond_timedwait(data_.cond(), data_.mutex(), &ts);
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

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
