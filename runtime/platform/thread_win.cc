// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/thread.h"

#include <process.h>

#include "platform/assert.h"

namespace dart {

class ThreadStartData {
 public:
  ThreadStartData(Thread::ThreadStartFunction function, uword parameter)
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
static unsigned int __stdcall ThreadEntry(void* data_ptr) {
  ThreadStartData* data =  reinterpret_cast<ThreadStartData*>(data_ptr);

  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  // When the function returns here close the handle.
  CloseHandle(GetCurrentThread());

  return 0;
}


int Thread::Start(ThreadStartFunction function, uword parameter) {
  ThreadStartData* start_data = new ThreadStartData(function, parameter);
  uint32_t tid;
  uintptr_t thread =
      _beginthreadex(NULL, 64 * KB, ThreadEntry, start_data, 0, &tid);
  if (thread == -1L || thread == 0) {
#ifdef DEBUG
    fprintf(stderr, "_beginthreadex error: %d (%s)\n", errno, strerror(errno));
#endif
    return errno;
  }

  return 0;
}


ThreadLocalKey Thread::kUnsetThreadLocalKey = TLS_OUT_OF_INDEXES;


ThreadLocalKey Thread::CreateThreadLocal() {
  ThreadLocalKey key = TlsAlloc();
  if (key == kUnsetThreadLocalKey) {
    FATAL("TlsAlloc failed");
  }
  return key;
}


void Thread::DeleteThreadLocal(ThreadLocalKey key) {
  ASSERT(key != kUnsetThreadLocalKey);
  BOOL result = TlsFree(key);
  if (!result) {
    FATAL("TlsFree failed");
  }
}


void Thread::SetThreadLocal(ThreadLocalKey key, uword value) {
  ASSERT(key != kUnsetThreadLocalKey);
  BOOL result = TlsSetValue(key, reinterpret_cast<void*>(value));
  if (!result) {
    FATAL("TlsSetValue failed");
  }
}


Mutex::Mutex() {
  // Allocate unnamed semaphore with initial count 1 and max count 1.
  data_.semaphore_ = CreateSemaphore(NULL, 1, 1, NULL);
  if (data_.semaphore_ == NULL) {
    FATAL("Mutex allocation failed");
  }
}


Mutex::~Mutex() {
  CloseHandle(data_.semaphore_);
}


void Mutex::Lock() {
  DWORD result = WaitForSingleObject(data_.semaphore_, INFINITE);
  if (result != WAIT_OBJECT_0) {
    FATAL("Mutex lock failed");
  }
}


bool Mutex::TryLock() {
  // Attempt to pass the semaphore but return immediately.
  DWORD result = WaitForSingleObject(data_.semaphore_, 0);
  if (result == WAIT_OBJECT_0) {
    return true;
  }
  if (result == WAIT_ABANDONED || result == WAIT_FAILED) {
    FATAL("Mutex try lock failed");
  }
  ASSERT(result == WAIT_TIMEOUT);
  return false;
}


void Mutex::Unlock() {
  BOOL result = ReleaseSemaphore(data_.semaphore_, 1, NULL);
  if (result == 0) {
    FATAL("Mutex unlock failed");
  }
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
  if (millis == 0) {
    // Wait forever.
    BOOL result = SleepConditionVariableCS(&data_.cond_, &data_.cs_, INFINITE);
    if (result == 0) {
      FATAL("Monitor::Wait failed");
    }
  } else {
    BOOL result = SleepConditionVariableCS(&data_.cond_, &data_.cs_, millis);
    if (result == 0) {
      DWORD error = GetLastError();
      // Windows condition variables should set error to WAIT_TIMEOUT
      // but occationally sets it to ERROR_TIMEOUT for timeouts. On
      // Windows 7 it seems to pretty consistently set it to
      // ERROR_TIMEOUT.
      if ((error == WAIT_TIMEOUT) || (error == ERROR_TIMEOUT)) {
        retval = kTimedOut;
      } else {
        FATAL("Monitor::Wait failed");
      }
    }
  }
  return retval;
}


void Monitor::Notify() {
  WakeConditionVariable(&data_.cond_);
}


void Monitor::NotifyAll() {
  WakeAllConditionVariable(&data_.cond_);
}

}  // namespace dart
