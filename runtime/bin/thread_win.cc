// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/thread.h"
#include "bin/thread_win.h"

#include <process.h>  // NOLINT

#include "platform/assert.h"

namespace dart {
namespace bin {

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
static unsigned int __stdcall ThreadEntry(void* data_ptr) {
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  return 0;
}

int Thread::Start(const char* name,
                  ThreadStartFunction function,
                  uword parameter) {
  ThreadStartData* start_data = new ThreadStartData(name, function, parameter);
  uint32_t tid;
  uintptr_t thread = _beginthreadex(NULL, Thread::GetMaxStackSize(),
                                    ThreadEntry, start_data, 0, &tid);
  if ((thread == -1L) || (thread == 0)) {
#ifdef DEBUG
    fprintf(stderr, "_beginthreadex error: %d (%s)\n", errno, strerror(errno));
#endif
    return errno;
  }

  // Close the handle, so we don't leak the thread object.
  CloseHandle(reinterpret_cast<HANDLE>(thread));

  return 0;
}

const ThreadLocalKey Thread::kUnsetThreadLocalKey = TLS_OUT_OF_INDEXES;
const ThreadId Thread::kInvalidThreadId = 0;

ThreadLocalKey Thread::CreateThreadLocal() {
  ThreadLocalKey key = TlsAlloc();
  if (key == kUnsetThreadLocalKey) {
    FATAL1("TlsAlloc failed %d", GetLastError());
  }
  return key;
}

void Thread::DeleteThreadLocal(ThreadLocalKey key) {
  ASSERT(key != kUnsetThreadLocalKey);
  BOOL result = TlsFree(key);
  if (!result) {
    FATAL1("TlsFree failed %d", GetLastError());
  }
}

intptr_t Thread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}

ThreadId Thread::GetCurrentThreadId() {
  return ::GetCurrentThreadId();
}

intptr_t Thread::ThreadIdToIntPtr(ThreadId id) {
  ASSERT(sizeof(id) <= sizeof(intptr_t));
  return static_cast<intptr_t>(id);
}

bool Thread::Compare(ThreadId a, ThreadId b) {
  return (a == b);
}

void Thread::SetThreadLocal(ThreadLocalKey key, uword value) {
  ASSERT(key != kUnsetThreadLocalKey);
  BOOL result = TlsSetValue(key, reinterpret_cast<void*>(value));
  if (!result) {
    FATAL1("TlsSetValue failed %d", GetLastError());
  }
}

Mutex::Mutex() {
  InitializeSRWLock(&data_.lock_);
}

Mutex::~Mutex() {}

void Mutex::Lock() {
  AcquireSRWLockExclusive(&data_.lock_);
}

bool Mutex::TryLock() {
  if (TryAcquireSRWLockExclusive(&data_.lock_) != 0) {
    return true;
  }
  return false;
}

void Mutex::Unlock() {
  ReleaseSRWLockExclusive(&data_.lock_);
}

Monitor::Monitor() {
  InitializeCriticalSection(&data_.cs_);
  InitializeConditionVariable(&data_.cond_);
}

Monitor::~Monitor() {
  DeleteCriticalSection(&data_.cs_);
}

void Monitor::Enter() {
  EnterCriticalSection(&data_.cs_);
}

void Monitor::Exit() {
  LeaveCriticalSection(&data_.cs_);
}

Monitor::WaitResult Monitor::Wait(int64_t millis) {
  Monitor::WaitResult retval = kNotified;
  if (millis == kNoTimeout) {
    SleepConditionVariableCS(&data_.cond_, &data_.cs_, INFINITE);
  } else {
    // Wait for the given period of time for a Notify or a NotifyAll
    // event.
    if (!SleepConditionVariableCS(&data_.cond_, &data_.cs_, millis)) {
      ASSERT(GetLastError() == ERROR_TIMEOUT);
      retval = kTimedOut;
    }
  }

  return retval;
}

Monitor::WaitResult Monitor::WaitMicros(int64_t micros) {
  // TODO(johnmccutchan): Investigate sub-millisecond sleep times on Windows.
  int64_t millis = micros / kMicrosecondsPerMillisecond;
  if ((millis * kMicrosecondsPerMillisecond) < micros) {
    // We've been asked to sleep for a fraction of a millisecond,
    // this isn't supported on Windows. Bumps milliseconds up by one
    // so that we never return too early. We likely return late though.
    millis += 1;
  }
  return Wait(millis);
}

void Monitor::Notify() {
  WakeConditionVariable(&data_.cond_);
}

void Monitor::NotifyAll() {
  WakeAllConditionVariable(&data_.cond_);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
