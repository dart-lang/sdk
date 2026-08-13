// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT
#if defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)

#include "vm/os_thread.h"

#include <process.h>
#include <processthreadsapi.h>

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/safe_stack.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/lockers.h"

namespace dart {

DEFINE_FLAG(int,
            worker_thread_priority,
            kMinInt,
            "The thread priority the VM should use for new worker threads.");

// This flag is flipped by platform_win.cc when the process is exiting.
// TODO(zra): Remove once VM shuts down cleanly.
bool private_flag_windows_run_tls_destructors = true;

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
static unsigned int __stdcall ThreadEntry(void* data_ptr) {
  if (FLAG_worker_thread_priority != kMinInt) {
    if (SetThreadPriority(GetCurrentThread(), FLAG_worker_thread_priority) ==
        0) {
      FATAL("Setting thread priority to %d failed: GetLastError() = %d\n",
            FLAG_worker_thread_priority, GetLastError());
    }
  }

  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  const char* name = data->name();
  OSThread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Create new OSThread object and set as TLS for new thread.
  OSThread* thread = OSThread::CreateOSThread();
  if (thread != nullptr) {
    OSThread::SetCurrent(thread);
    thread->SetName(name);

    // Call the supplied thread start function handing it its parameters.
    function(parameter);
  }

  return 0;
}

int OSThread::TryStart(const char* name,
                       ThreadStartFunction function,
                       uword parameter) {
  ThreadStartData* start_data = new ThreadStartData(name, function, parameter);
  uint32_t tid;
  uintptr_t thread = _beginthreadex(nullptr, OSThread::GetMaxStackSize(),
                                    ThreadEntry, start_data, 0, &tid);
  if (thread == -1L || thread == 0) {
    return errno;
  }

  // Close the handle, so we don't leak the thread object.
  CloseHandle(reinterpret_cast<HANDLE>(thread));

  return 0;
}

const ThreadJoinId OSThread::kInvalidThreadJoinId = nullptr;

intptr_t OSThread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}

#ifdef SUPPORT_TIMELINE
ThreadId OSThread::GetCurrentThreadTraceId() {
  return ::GetCurrentThreadId();
}
#endif  // SUPPORT_TIMELINE

char* OSThread::GetCurrentThreadName() {
  // TODO(derekx): We aren't even setting the thread name on Windows, so we need
  // to figure out how to set/get the thread name on Windows.
  return nullptr;
}

ThreadJoinId OSThread::GetCurrentThreadJoinId(OSThread* thread) {
  ASSERT(thread != nullptr);
  // Make sure we're filling in the join id for the current thread.
  ThreadId id = GetCurrentThreadId();
  ASSERT(thread->id() == id);
  // Make sure the join_id_ hasn't been set, yet.
  DEBUG_ASSERT(thread->join_id_ == kInvalidThreadJoinId);
  HANDLE handle = OpenThread(SYNCHRONIZE, false, id);
  ASSERT(handle != nullptr);
#if defined(DEBUG)
  thread->join_id_ = handle;
#endif
  return handle;
}

void OSThread::Join(ThreadJoinId id) {
  HANDLE handle = static_cast<HANDLE>(id);
  ASSERT(handle != nullptr);
  DWORD res = WaitForSingleObject(handle, INFINITE);
  CloseHandle(handle);
  ASSERT(res == WAIT_OBJECT_0);
}

void OSThread::Detach(ThreadJoinId id) {
  HANDLE handle = static_cast<HANDLE>(id);
  ASSERT(handle != nullptr);
  CloseHandle(handle);
}

intptr_t OSThread::ThreadIdToIntPtr(ThreadId id) {
  COMPILE_ASSERT(sizeof(id) <= sizeof(intptr_t));
  return static_cast<intptr_t>(id);
}

ThreadId OSThread::ThreadIdFromIntPtr(intptr_t id) {
  return static_cast<ThreadId>(id);
}

bool OSThread::GetCurrentStackBounds(uword* lower, uword* upper) {
  // PULONG and uword are sometimes different fundamental types.
  ::GetCurrentThreadStackLimits(reinterpret_cast<PULONG_PTR>(lower),
                                reinterpret_cast<PULONG_PTR>(upper));
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

#endif  // defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)
