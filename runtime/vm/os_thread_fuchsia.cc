// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT
#if defined(DART_HOST_OS_FUCHSIA) && !defined(DART_USE_ABSL)

#include "vm/os.h"
#include "vm/os_thread.h"
#include "vm/os_thread_fuchsia.h"

#include <errno.h>  // NOLINT
#include <zircon/status.h>
#include <zircon/syscalls.h>
#include <zircon/threads.h>
#include <zircon/tls.h>
#include <zircon/types.h>

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/safe_stack.h"

namespace dart {

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
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  OSThread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Set the thread name.
  char truncated_name[ZX_MAX_NAME_LEN];
  snprintf(truncated_name, ZX_MAX_NAME_LEN, "%s", name);
  zx_handle_t thread_handle = thrd_get_zx_handle(thrd_current());
  zx_object_set_property(thread_handle, ZX_PROP_NAME, truncated_name,
                         ZX_MAX_NAME_LEN);

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

#ifdef SUPPORT_TIMELINE
ThreadId OSThread::GetCurrentThreadTraceId() {
  return pthread_self();
}
#endif  // SUPPORT_TIMELINE

char* OSThread::GetCurrentThreadName() {
  char* name = static_cast<char*>(malloc(ZX_MAX_NAME_LEN));
  zx_handle_t thread_handle = thrd_get_zx_handle(thrd_current());
  zx_object_get_property(thread_handle, ZX_PROP_NAME, name, ZX_MAX_NAME_LEN);
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
  return static_cast<intptr_t>(id);
}

ThreadId OSThread::ThreadIdFromIntPtr(intptr_t id) {
  return static_cast<ThreadId>(id);
}

bool OSThread::GetCurrentStackBounds(uword* lower, uword* upper) {
  pthread_attr_t attr;
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
}

#if defined(USING_SAFE_STACK)
#define STRINGIFY(s) #s
NO_SANITIZE_ADDRESS
NO_SANITIZE_SAFE_STACK
uword OSThread::GetCurrentSafestackPointer() {
  uword result;
#if defined(HOST_ARCH_X64)
#define _loadfsword(index) "movq  %%fs:" STRINGIFY(index) ", %0"
  asm volatile(_loadfsword(ZX_TLS_UNSAFE_SP_OFFSET)
               : "=r"(result)  // outputs
  );
#undef _loadfsword
#elif defined(HOST_ARCH_ARM64)
#define _loadword(index) "ldr %0, [%0, " STRINGIFY(index) "]"
  asm volatile("mrs %0, TPIDR_EL0;\n" _loadword(ZX_TLS_UNSAFE_SP_OFFSET)
               : "=r"(result)  // outputs
  );
#else
#error "Architecture not supported"
#endif
  return result;
}

NO_SANITIZE_ADDRESS
NO_SANITIZE_SAFE_STACK
void OSThread::SetCurrentSafestackPointer(uword ssp) {
#if defined(HOST_ARCH_X64)
#define str(s) #s
#define _storefsword(index) "movq %0, %%fs:" str(index)
  asm volatile(_storefsword(ZX_TLS_UNSAFE_SP_OFFSET)
               :           // outputs.
               : "r"(ssp)  // inputs.
               :           // clobbered.
  );
#undef _storefsword
#undef str
#elif defined(HOST_ARCH_ARM64)
#define _storeword(index) "str %1, [%0, " STRINGIFY(index) "]"
  uword tmp;
  asm volatile("mrs %0, TPIDR_EL0;\n" _storeword(ZX_TLS_UNSAFE_SP_OFFSET)
               : "=r"(tmp)  // outputs.
               : "r"(ssp)   // inputs.
               :            // clobbered.
  );
#else
#error "Architecture not supported"
#endif
}
#undef STRINGIFY
#endif

}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA) && !defined(DART_USE_ABSL)
