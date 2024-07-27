// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_USE_ABSL)

#include <errno.h>         // NOLINT
#include <sys/resource.h>  // NOLINT
#include <sys/time.h>      // NOLINT

#include "bin/thread.h"
#include "bin/thread_absl.h"
#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

#define VALIDATE_PTHREAD_RESULT(result)                                        \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_buf[kBufferSize];                                               \
    FATAL("pthread error: %d (%s)", result,                                    \
          Utils::StrError(result, error_buf, kBufferSize));                    \
  }

#ifdef DEBUG
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_buf[kBufferSize];                                               \
    fprintf(stderr, "%s:%d: pthread error: %d (%s)\n", __FILE__, __LINE__,     \
            result, Utils::StrError(result, error_buf, kBufferSize));          \
    return result;                                                             \
  }
#else
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
  if (result != 0) {                                                           \
    return result;                                                             \
  }
#endif

class ThreadStartData {
 public:
  ThreadStartData(const char* name,
                  Thread::ThreadStartFunction function,
                  uword parameter)
      : name_(name), function_(function), parameter_(parameter) {}

  const char* name() const { return name_; }
  Thread::ThreadStartFunction function() const { return function_; }
  uword parameter() const { return parameter_; }

 private:
  const char* name_;
  Thread::ThreadStartFunction function_;
  uword parameter_;

  DISALLOW_COPY_AND_ASSIGN(ThreadStartData);
};

// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  // Set the thread name. There is 16 bytes limit on the name (including \0).
  // pthread_setname_np ignores names that are too long rather than truncating.
  char truncated_name[16];
  snprintf(truncated_name, sizeof(truncated_name), "%s", name);
  pthread_setname_np(pthread_self(), truncated_name);
#elif defined(DART_HOST_OS_MACOS)
  // Set the thread name.
  pthread_setname_np(name);
#endif

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  return nullptr;
}

int Thread::Start(const char* name,
                  ThreadStartFunction function,
                  uword parameter) {
  pthread_attr_t attr;
  int result = pthread_attr_init(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_setstacksize(&attr, Thread::GetMaxStackSize());
  RETURN_ON_PTHREAD_FAILURE(result);

  ThreadStartData* data = new ThreadStartData(name, function, parameter);

  pthread_t tid;
  result = pthread_create(&tid, &attr, ThreadStart, data);
  RETURN_ON_PTHREAD_FAILURE(result);

  result = pthread_attr_destroy(&attr);
  RETURN_ON_PTHREAD_FAILURE(result);

  return 0;
}

const ThreadId Thread::kInvalidThreadId = static_cast<ThreadId>(0);

intptr_t Thread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}

ThreadId Thread::GetCurrentThreadId() {
  return pthread_self();
}

bool Thread::Compare(ThreadId a, ThreadId b) {
  return (pthread_equal(a, b) != 0);
}

Mutex::Mutex() : data_() {}

Mutex::~Mutex() {}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Lock() {
  data_.mutex()->Lock();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
bool Mutex::TryLock() {
  if (!data_.mutex()->TryLock()) {
    return false;
  }
  return true;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Unlock() {
  data_.mutex()->Unlock();
}

Monitor::Monitor() : data_() {}

Monitor::~Monitor() {}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Enter() {
  data_.mutex()->Lock();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Exit() {
  data_.mutex()->Unlock();
}

Monitor::WaitResult Monitor::Wait(int64_t millis) {
  return WaitMicros(millis * kMicrosecondsPerMillisecond);
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
Monitor::WaitResult Monitor::WaitMicros(int64_t micros) {
  Monitor::WaitResult retval = kNotified;
  if (micros == kNoTimeout) {
    // Wait forever.
    data_.cond()->Wait(data_.mutex());
  } else {
    if (data_.cond()->WaitWithTimeout(data_.mutex(),
                                      absl::Microseconds(micros))) {
      retval = kTimedOut;
    }
  }
  return retval;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Notify() {
  data_.cond()->Signal();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::NotifyAll() {
  data_.cond()->SignalAll();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_USE_ABSL)
