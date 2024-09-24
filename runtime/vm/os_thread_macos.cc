// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT
#if defined(DART_HOST_OS_MACOS) && !defined(DART_USE_ABSL)

#include "vm/os_thread.h"

#include <mach/mach_host.h>    // NOLINT
#include <mach/mach_init.h>    // NOLINT
#include <mach/mach_port.h>    // NOLINT
#include <mach/mach_traps.h>   // NOLINT
#include <mach/task_info.h>    // NOLINT
#include <mach/thread_act.h>   // NOLINT
#include <mach/thread_info.h>  // NOLINT
#include <signal.h>            // NOLINT
#include <sys/errno.h>         // NOLINT
#include <sys/sysctl.h>        // NOLINT
#include <sys/types.h>         // NOLINT

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/safe_stack.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"

#include "vm/flags.h"

namespace dart {

DEFINE_FLAG(int,
            worker_thread_priority,
            kMinInt,
            "The thread priority the VM should use for new worker threads.");

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

// Dispatch to the thread start function provided by the caller. This trampoline
// is used to ensure that the thread is properly destroyed if the thread just
// exits.
static void* ThreadStart(void* data_ptr) {
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

  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  OSThread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Set the thread name. We need to impose a limit on the name length so that
  // we can know how large of a buffer to use when retrieving the name. We
  // truncate the name at 16 bytes to be consistent with Android and Linux.
  char truncated_name[16];
  snprintf(truncated_name, ARRAY_SIZE(truncated_name), "%s", name);
  pthread_setname_np(name);

  // Create new OSThread object and set as TLS for new thread.
  OSThread* thread = OSThread::CreateOSThread();
  if (thread != nullptr) {
    OSThread::SetCurrent(thread);
    thread->SetName(name);
    // Call the supplied thread start function handing it its parameters.
    function(parameter);
  }

  return nullptr;
}

int OSThread::TryStart(const char* name,
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

const ThreadJoinId OSThread::kInvalidThreadJoinId =
    static_cast<ThreadJoinId>(nullptr);

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

#ifdef SUPPORT_TIMELINE
ThreadId OSThread::GetCurrentThreadTraceId() {
  return ThreadIdFromIntPtr(pthread_mach_thread_np(pthread_self()));
}
#endif  // SUPPORT_TIMELINE

char* OSThread::GetCurrentThreadName() {
  const intptr_t kNameBufferSize = 16;
  char* name = static_cast<char*>(malloc(kNameBufferSize));
  pthread_getname_np(pthread_self(), name, kNameBufferSize);
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
  VALIDATE_PTHREAD_RESULT(result);
}

void OSThread::Detach(ThreadJoinId id) {
  int result = pthread_detach(id);
  VALIDATE_PTHREAD_RESULT(result);
}

intptr_t OSThread::ThreadIdToIntPtr(ThreadId id) {
  COMPILE_ASSERT(sizeof(id) <= sizeof(intptr_t));
  return reinterpret_cast<intptr_t>(id);
}

ThreadId OSThread::ThreadIdFromIntPtr(intptr_t id) {
  return reinterpret_cast<ThreadId>(id);
}

bool OSThread::GetCurrentStackBounds(uword* lower, uword* upper) {
  *upper = reinterpret_cast<uword>(pthread_get_stackaddr_np(pthread_self()));
  *lower = *upper - pthread_get_stacksize_np(pthread_self());
  return true;
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

}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
