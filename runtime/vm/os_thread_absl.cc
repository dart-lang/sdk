// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(DART_USE_ABSL)

#include <errno.h>  // NOLINT
#include <stdio.h>
#include <sys/resource.h>  // NOLINT
#include <sys/syscall.h>   // NOLINT
#include <sys/time.h>      // NOLINT
#if defined(DART_HOST_OS_ANDROID)
#include <sys/prctl.h>
#endif  // defined(DART_HOST_OS_ANDROID)

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/safe_stack.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/os_thread.h"

namespace dart {

DEFINE_FLAG(int,
            worker_thread_priority,
            kMinInt,
            "The thread priority the VM should use for new worker threads.");

#define VALIDATE_PTHREAD_RESULT(result)                                        \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_buf[kBufferSize];                                               \
    FATAL("pthread error: %d (%s)", result,                                    \
          Utils::StrError(result, error_buf, kBufferSize));                    \
  }

// Variation of VALIDATE_PTHREAD_RESULT for named objects.
#if defined(PRODUCT)
#define VALIDATE_PTHREAD_RESULT_NAMED(result) VALIDATE_PTHREAD_RESULT(result)
#else
#define VALIDATE_PTHREAD_RESULT_NAMED(result)                                  \
  if (result != 0) {                                                           \
    const int kBufferSize = 1024;                                              \
    char error_buf[kBufferSize];                                               \
    FATAL("[%s] pthread error: %d (%s)", name_, result,                        \
          Utils::StrError(result, error_buf, kBufferSize));                    \
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
    char error_buf[kBufferSize];                                               \
    fprintf(stderr, "%s:%d: pthread error: %d (%s)\n", __FILE__, __LINE__,     \
            result, Utils::StrError(result, error_buf, kBufferSize));          \
    return result;                                                             \
  }
#else
#define RETURN_ON_PTHREAD_FAILURE(result)                                      \
  if (result != 0) return result;
#endif

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

// TODO(bkonyi): remove this call once the prebuilt SDK is updated.
// Spawned threads inherit their spawner's signal mask. We sometimes spawn
// threads for running Dart code from a thread that is blocking SIGPROF.
// This function explicitly unblocks SIGPROF so the profiler continues to
// sample this thread.
static void UnblockSIGPROF() {
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGPROF);
  int r = pthread_sigmask(SIG_UNBLOCK, &set, nullptr);
  USE(r);
  ASSERT(r == 0);
  ASSERT(!CHECK_IS_BLOCKING(SIGPROF));
}

// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  if (FLAG_worker_thread_priority != kMinInt) {
    if (setpriority(PRIO_PROCESS, syscall(__NR_gettid),
                    FLAG_worker_thread_priority) == -1) {
      FATAL("Setting thread priority to %d failed: errno = %d\n",
            FLAG_worker_thread_priority, errno);
    }
  }
#elif defined(DART_HOST_OS_MACOS)
  if (FLAG_worker_thread_priority != kMinInt) {
    const pthread_t thread = pthread_self();
    int policy = SCHED_FIFO;
    struct sched_param schedule;
    if (pthread_getschedparam(thread, &policy, &schedule) != 0) {
      FATAL("Obtaining sched param failed: errno = %d\n", errno);
    }
    schedule.sched_priority = FLAG_worker_thread_priority;
    if (pthread_setschedparam(thread, policy, &schedule) != 0) {
      FATAL("Setting thread priority to %d failed: errno = %d\n",
            FLAG_worker_thread_priority, errno);
    }
  }
#endif

  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  OSThread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Set the thread name. There is 16 bytes limit on the name (including \0).
  // pthread_setname_np ignores names that are too long rather than truncating.
  char truncated_name[16];
  snprintf(truncated_name, ARRAY_SIZE(truncated_name), "%s", name);
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  pthread_setname_np(pthread_self(), truncated_name);
#elif defined(DART_HOST_OS_MACOS)
  // Set the thread name.
  pthread_setname_np(name);
#endif

  // Create new OSThread object and set as TLS for new thread.
  OSThread* thread = OSThread::CreateOSThread();
  if (thread != nullptr) {
    OSThread::SetCurrent(thread);
    thread->SetName(name);
    UnblockSIGPROF();
    // Call the supplied thread start function handing it its parameters.
    function(parameter);
  }

  return nullptr;
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
  return pthread_self();
}

#ifdef SUPPORT_TIMELINE
ThreadId OSThread::GetCurrentThreadTraceId() {
#if defined(DART_HOST_OS_ANDROID)
  return GetCurrentThreadId();
#elif defined(DART_HOST_OS_LINUX)
  return syscall(__NR_gettid);
#elif defined(DART_HOST_OS_MACOS)
  return ThreadIdFromIntPtr(pthread_mach_thread_np(pthread_self()));
#endif
}
#endif  // SUPPORT_TIMELINE

char* OSThread::GetCurrentThreadName() {
  const intptr_t kNameBufferSize = 16;
  char* name = static_cast<char*>(malloc(kNameBufferSize));

#if defined(DART_HOST_OS_ANDROID)
  prctl(PR_GET_NAME, name);
#elif defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS)
  pthread_getname_np(pthread_self(), name, kNameBufferSize);
#endif

  return name;
}

ThreadJoinId OSThread::GetCurrentThreadJoinId(OSThread* thread) {
  ASSERT(thread != nullptr);
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
  int result = pthread_join(id, nullptr);
  ASSERT(result == 0);
}

intptr_t OSThread::ThreadIdToIntPtr(ThreadId id) {
  COMPILE_ASSERT(sizeof(id) <= sizeof(intptr_t));
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  return static_cast<intptr_t>(id);
#elif defined(DART_HOST_OS_MACOS)
  return reinterpret_cast<intptr_t>(id);
#endif
}

ThreadId OSThread::ThreadIdFromIntPtr(intptr_t id) {
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  return static_cast<ThreadId>(id);
#elif defined(DART_HOST_OS_MACOS)
  return reinterpret_cast<ThreadId>(id);
#endif
}

bool OSThread::Compare(ThreadId a, ThreadId b) {
  return pthread_equal(a, b) != 0;
}

bool OSThread::GetCurrentStackBounds(uword* lower, uword* upper) {
#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
  pthread_attr_t attr;
  // May fail on the main thread.
  if (pthread_getattr_np(pthread_self(), &attr) != 0) {
    return false;
  }

  void* base;
  size_t size;
  int error = pthread_attr_getstack(&attr, &base, &size);
  pthread_attr_destroy(&attr);
  if (error != 0) {
    return false;
  }

  *lower = reinterpret_cast<uword>(base);
  *upper = *lower + size;
  return true;
#elif defined(DART_HOST_OS_MACOS)
  *upper = reinterpret_cast<uword>(pthread_get_stackaddr_np(pthread_self()));
  *lower = *upper - pthread_get_stacksize_np(pthread_self());
  return true;
#endif
}

#if defined(USING_SAFE_STACK)
NO_SANITIZE_ADDRESS
NO_SANITIZE_SAFE_STACK
uword OSThread::GetCurrentSafestackPointer() {
#error "SAFE_STACK is unsupported on this platform"
  return 0;
}

NO_SANITIZE_ADDRESS
NO_SANITIZE_SAFE_STACK
void OSThread::SetCurrentSafestackPointer(uword ssp) {
#error "SAFE_STACK is unsupported on this platform"
}
#endif

Mutex::Mutex(NOT_IN_PRODUCT(const char* name))
#if !defined(PRODUCT)
    : name_(name)
#endif
{
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
}

Mutex::~Mutex() {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
#endif  // defined(DEBUG)
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Lock() {
  data_.mutex()->Lock();
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
bool Mutex::TryLock() {
  if (!data_.mutex()->TryLock()) {
    return false;
  }
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
  return true;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Unlock() {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
  data_.mutex()->Unlock();
}

Monitor::Monitor() {
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
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
bool Monitor::TryEnter() {
  if (!data_.mutex()->TryLock()) {
    return false;
  }
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
  return true;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Enter() {
  data_.mutex()->Lock();
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(owner_ == OSThread::kInvalidThreadId);
  owner_ = OSThread::GetCurrentThreadId();
#endif  // defined(DEBUG)
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Exit() {
#if defined(DEBUG)
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  owner_ = OSThread::kInvalidThreadId;
#endif  // defined(DEBUG)
  data_.mutex()->Unlock();
}

Monitor::WaitResult Monitor::Wait(int64_t millis) {
  Monitor::WaitResult retval = WaitMicros(millis * kMicrosecondsPerMillisecond);
  return retval;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
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
    data_.cond()->Wait(data_.mutex());
  } else {
    if (data_.cond()->WaitWithTimeout(data_.mutex(),
                                      absl::Microseconds(micros))) {
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

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::Notify() {
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  data_.cond()->Signal();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Monitor::NotifyAll() {
  // When running with assertions enabled we track the owner.
  ASSERT(IsOwnedByCurrentThread());
  data_.cond()->SignalAll();
}

}  // namespace dart

#endif  // defined(DART_USE_ABSL)
