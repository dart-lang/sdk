// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_THREADS_H_
#define RUNTIME_PLATFORM_THREADS_H_

#include "platform/assert.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||            \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)
#include <pthread.h>
#endif

namespace dart {

namespace platform {

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||            \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)
typedef pthread_t ThreadId;
#elif defined(DART_HOST_OS_WINDOWS)
typedef DWORD ThreadId;
#else
#error Unknown target os.
#endif

static constexpr ThreadId kInvalidThreadId = static_cast<ThreadId>(0);

inline ThreadId GetCurrentThreadId() {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||            \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)
  return pthread_self();
#elif defined(DART_HOST_OS_WINDOWS)
  return ::GetCurrentThreadId();
#else
#error Unknown target os.
#endif
}

inline bool AreSameThreads(ThreadId a, ThreadId b) {
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||            \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)
  return pthread_equal(a, b) != 0;
#elif defined(DART_HOST_OS_WINDOWS)
  return a == b;
#else
#error Unknown target os.
#endif
}

#if defined(DEBUG)
class ThreadBoundResource {
 public:
  ~ThreadBoundResource() { ASSERT(owner_ == kUnowned); }

  void Acquire() {
    ASSERT(owner_ == kUnowned);
    owner_ = GetCurrentThreadId();
  }

  void Release() {
    ASSERT(IsOwnedByCurrentThread());
    owner_ = kUnowned;
  }

  bool IsOwnedByCurrentThread() const {
    return AreSameThreads(owner_, GetCurrentThreadId());
  }

 private:
  static constexpr ThreadId kUnowned = kInvalidThreadId;
  ThreadId owner_ = kUnowned;
};
#else
class ThreadBoundResource {
 public:
  void Acquire() {}

  void Release() {}

  bool IsOwnedByCurrentThread() const {
    UNREACHABLE();
    return false;
  }
};
#endif

}  // namespace platform

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||            \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)

#define VALIDATE_PTHREAD_RESULT(result)                                        \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_buf[kBufferSize];                                               \
    FATAL("pthread error: %d (%s)", result,                                    \
          Utils::StrError(result, error_buf, kBufferSize));                    \
  }

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
    char error_buf[kBufferSize];                                               \
    fprintf(stderr, "%s:%d: pthread error: %d (%s)\n", __FILE__, __LINE__,     \
            result, Utils::StrError(result, error_buf, kBufferSize));          \
    return result;                                                             \
  }
#else
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
  if (result != 0) return result;
#endif

#endif

}  // namespace dart

#endif  // RUNTIME_PLATFORM_THREADS_H_
