// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(HOST_OS_ANDROID)

#include "vm/os_thread.h"

#include <errno.h>     // NOLINT
#include <sys/time.h>  // NOLINT

#include "platform/assert.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"

#include "vm/profiler.h"

namespace dart {

#define VALIDATE_PTHREAD_RESULT(result)                                        \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_message[kBufferSize];                                           \
    NOT_IN_PRODUCT(Profiler::DumpStackTrace());                                \
    Utils::StrError(result, error_message, kBufferSize);                       \
    FATAL2("pthread error: %d (%s)", result, error_message);                   \
  }

#if defined(PRODUCT)
#define VALIDATE_PTHREAD_RESULT_NAMED(result) VALIDATE_PTHREAD_RESULT(result)
#else
#define VALIDATE_PTHREAD_RESULT_NAMED(result)                                  \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_message[kBufferSize];                                           \
    NOT_IN_PRODUCT(Profiler::DumpStackTrace());                                \
    Utils::StrError(result, error_message, kBufferSize);                       \
    FATAL3("[%s] pthread error: %d (%s)", name_, result, error_message);       \
  }
#endif

#if defined(DEBUG)
#define ASSERT_PTHREAD_SUCCESS(result) VALIDATE_PTHREAD_RESULT(result)
#else
// NOTE: This (currently) expands to a no-op.
#define ASSERT_PTHREAD_SUCCESS(result) ASSERT(result == 0)
#endif

#ifdef DEBUG
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_message[kBufferSize];                                           \
    Utils::StrError(result, error_message, kBufferSize);                       \
    fprintf(stderr, "%s:%d: pthread error: %d (%s)\n", __FILE__, __LINE__,     \
            result, error_message);                                            \
    return result;                                                             \
  }
#else
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
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
  ThreadStartData(const char* name,
                  OSThread::ThreadStartFunction function,
                  uword parameter)
      : name_(name), function_(function), parameter_(parameter) {}

  const char* name() const { return name_; }
  OSThread::ThreadStartFunction function() const { return function_; }
  uword parameter() const { return parameter_; }

 private:
  const char* name_;
  OSThread::ThreadStartFunction function_;
  uword parameter_;

  DISALLOW_COPY_AND_ASSIGN(ThreadStartData);
};

// Spawned threads inherit their spawner's signal mask. We sometimes spawn
// threads for running Dart code from a thread that is blocking SIGPROF.
// This function explicitly unblocks SIGPROF so the profiler continues to
// sample this thread.
static void UnblockSIGPROF() {
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGPROF);
  int r = pthread_sigmask(SIG_UNBLOCK, &set, NULL);
  USE(r);
  ASSERT(r == 0);
  ASSERT(!CHECK_IS_BLOCKING(SIGPROF));
}

// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  OSThread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Create new OSThread object and set as TLS for new thread.
  OSThread* thread = OSThread::CreateOSThread();
  if (thread != NULL) {
    OSThread::SetCurrent(thread);
    thread->set_name(name);
    UnblockSIGPROF();
    // Call the supplied thread start function handing it its parameters.
    function(parameter);
  }

  return NULL;
}

int OSThread::Start(const char* name,
                    ThreadStartFunction function,
                    uword parameter) {
  pthread_attr_t attr;
  int result = pthread_attr_init(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_setstacksize(&attr, OSThread::GetMaxStackSize());
  RETURN_ON_PTHREAD_FAILURE(result);

  ThreadStartData* data = new ThreadStartData(name, function, parameter);

  pthread_t tid;
  result = pthread_create(&tid, &attr, ThreadStart, data);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_destroy(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  return 0;
}

const ThreadId OSThread::kInvalidThreadId = static_cast<ThreadId>(0);
const ThreadJoinId OSThread::kInvalidThreadJoinId =
    static_cast<ThreadJoinId>(0);

ThreadLocalKey OSThread::CreateThreadLocal(ThreadDestructor destructor) {
  pthread_key_t key = kUnsetThreadLocalKey;
  int result = pthread_key_create(&key, destructor);
  VALIDATE_PTHREAD_RESULT(result);
  ASSERT(key != kUnsetThreadLocalKey);
  return key;
}

void OSThread::DeleteThreadLocal(ThreadLocalKey key) {
  ASSERT(key != kUnsetThreadLocalKey);
  int result = pthread_key_delete(key);
  VALIDATE_PTHREAD_RESULT(result);
}

void OSThread::SetThreadLocal(ThreadLocalKey key, uword value) {
  ASSERT(key != kUnsetThreadLocalKey);
  int result = pthread_setspecific(key, reinterpret_cast<void*>(value));
  VALIDATE_PTHREAD_RESULT(result);
}

intptr_t OSThread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}

ThreadId OSThread::GetCurrentThreadId() {
  return gettid();
}

#ifndef PRODUCT
ThreadId OSThread::GetCurrentThreadTraceId() {
  return GetCurrentThreadId();
}
#endif  // PRODUCT

ThreadJoinId OSThread::GetCurrentThreadJoinId(OSThread* thread) {
  ASSERT(thread != NULL);
  // Make sure we're filling in the join id for the current thread.
  ASSERT(thread->id() == GetCurrentThreadId());
  // Make sure the join_id_ hasn't been set, yet.
  DEBUG_ASSERT(thread->join_id_ == kInvalidThreadJoinId);
  pthread_t id = pthread_self();
#if defined(DEBUG)
  thread->join_id_ = id;
#endif
  return id;
}

void OSThread::Join(ThreadJoinId id) {
  int result = pthread_join(id, NULL);
  ASSERT(result == 0);
}

intptr_t OSThread::ThreadIdToIntPtr(ThreadId id) {
  ASSERT(sizeof(id) == sizeof(intptr_t));
  return static_cast<intptr_t>(id);
}

ThreadId OSThread::ThreadIdFromIntPtr(intptr_t id) {
  return static_cast<ThreadId>(id);
}

bool OSThread::Compare(ThreadId a, ThreadId b) {
  return a == b;
}

bool OSThread::GetCurrentStackBounds(uword* lower, uword* upper) {
  pthread_attr_t attr;
  if (pthread_getattr_np(pthread_self(), &attr)) {
    return false;
  }

  void* base;
  size_t size;
  int error = pthread_attr_getstack(&attr, &base, &size);
  pthread_attr_destroy(&attr);
  if (error) {
    return false;
  }

  *lower = reinterpret_cast<uword>(base);
  *upper = *lower + size;
  return true;
}

Mutex::Mutex(NOT_IN_PRODUCT(const char* name))
#if !defined(PRODUCT)
    : name_(name)
#endif
{
  pthread_mutexattr_t attr;
  int result = pthread_mutexattr_init(&attr);
  VALIDATE_PTHREAD_RESULT_NAMED(result);

#if defined(DEBUG)
  result = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
  VALIDATE_PTHREAD_RESULT_NAMED(result);
#endif  // defined(DEBUG)

  result = pthread_mutex_init(data_.mutex(), &attr);
  // Verify that creating a pthread_mutex succeeded.
  VALIDATE_PTHREAD_RESULT_NAMED(result);

  result = pthread_mutexattr_destroy(&attr);
  VALIDATE_PTHREAD_RESULT_NAMED(result);

#if defined(DEBUG)
  // When running with assertions enabled we do track the owner.
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
}

Mutex::~Mutex() {
  int result = pthread_mutex_destroy(data_.mutex());
  // Verify that the pthread_mutex was destroyed.
  VALIDATE_PTHREAD_RESULT_NAMED(result);

#if defined(DEBUG)
  // When running with assertions enabled we do track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
#endif  // defined(DEBUG)
}

void Mutex::Lock() {
  int result = pthread_mutex_lock(data_.mutex());
  // Specifically check for dead lock to help debugging.
  ASSERT(result != EDEADLK);
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
#if defined(DEBUG)
  // When running with assertions enabled we do track the owner.
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
}

bool Mutex::TryLock() {
  int result = pthread_mutex_trylock(data_.mutex());
  // Return false if the lock is busy and locking failed.
  if (result == EBUSY) {
    return false;
  }
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
#if defined(DEBUG)
  // When running with assertions enabled we do track the owner.
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
  return true;
}

void Mutex::Unlock() {
#if defined(DEBUG)
  // When running with assertions enabled we do track the owner.
  ASSERT(IsOwnedByCurrentThread());
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
  int result = pthread_mutex_unlock(data_.mutex());
  // Specifically check for wrong thread unlocking to aid debugging.
  ASSERT(result != EPERM);
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
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

#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
}

Monitor::~Monitor() {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
#endif  // defined(DEBUG)

  int result = pthread_mutex_destroy(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_cond_destroy(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}

bool Monitor::TryEnter() {
  int result = pthread_mutex_trylock(data_.mutex());
  // Return false if the lock is busy and locking failed.
  if (result == EBUSY) {
    return false;
  }
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
  return true;
}

void Monitor::Enter() {
  int result = pthread_mutex_lock(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);

#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
}

void Monitor::Exit() {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)

  int result = pthread_mutex_unlock(data_.mutex());
  VALIDATE_PTHREAD_RESULT(result);
}

Monitor::WaitResult Monitor::Wait(int64_t millis) {
  return WaitMicros(millis * kMicrosecondsPerMillisecond);
}

Monitor::WaitResult Monitor::WaitMicros(int64_t micros) {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  ThreadId saved_owner = owner_;
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)

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

#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
  owner_ = OSThread::GetCurrentThreadId();
  ASSERT(owner_ == saved_owner);
#endif  // defined(DEBUG)
  return retval;
}

void Monitor::Notify() {
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  int result = pthread_cond_signal(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}

void Monitor::NotifyAll() {
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  int result = pthread_cond_broadcast(data_.cond());
  VALIDATE_PTHREAD_RESULT(result);
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
