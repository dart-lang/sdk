// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/thread.h"

#include <process.h>  // NOLINT

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
  ThreadStartData* data = reinterpret_cast<ThreadStartData*>(data_ptr);

  Thread::ThreadStartFunction function = data->function();
  uword parameter = data->parameter();
  delete data;

  MonitorData::GetMonitorWaitDataForThread();

  // Call the supplied thread start function handing it its parameters.
  function(parameter);

  // Clean up the monitor wait data for this thread.
  MonitorWaitData::ThreadExit();

  return 0;
}


int Thread::Start(ThreadStartFunction function, uword parameter) {
  ThreadStartData* start_data = new ThreadStartData(function, parameter);
  uint32_t tid;
  uintptr_t thread = _beginthreadex(NULL, Thread::GetMaxStackSize(),
                                    ThreadEntry, start_data, 0, &tid);
  if (thread == -1L || thread == 0) {
#ifdef DEBUG
    fprintf(stderr, "_beginthreadex error: %d (%s)\n", errno, strerror(errno));
#endif
    return errno;
  }

  // Close the handle, so we don't leak the thread object.
  CloseHandle(reinterpret_cast<HANDLE>(thread));

  return 0;
}

ThreadLocalKey Thread::kUnsetThreadLocalKey = TLS_OUT_OF_INDEXES;
ThreadId Thread::kInvalidThreadId = 0;

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


bool Thread::Join(ThreadId id) {
  HANDLE handle = OpenThread(SYNCHRONIZE, false, id);
  if (handle == INVALID_HANDLE_VALUE) {
    return false;
  }
  DWORD res = WaitForSingleObject(handle, INFINITE);
  CloseHandle(handle);
  return res == WAIT_OBJECT_0;
}


intptr_t Thread::ThreadIdToIntPtr(ThreadId id) {
  ASSERT(sizeof(id) <= sizeof(intptr_t));
  return static_cast<intptr_t>(id);
}


bool Thread::Compare(ThreadId a, ThreadId b) {
  return a == b;
}


void Thread::GetThreadCpuUsage(ThreadId thread_id, int64_t* cpu_usage) {
  static const int64_t kTimeEpoc = 116444736000000000LL;
  static const int64_t kTimeScaler = 10;  // 100 ns to us.
  // Although win32 uses 64-bit integers for representing timestamps,
  // these are packed into a FILETIME structure. The FILETIME
  // structure is just a struct representing a 64-bit integer. The
  // TimeStamp union allows access to both a FILETIME and an integer
  // representation of the timestamp. The Windows timestamp is in
  // 100-nanosecond intervals since January 1, 1601.
  union TimeStamp {
    FILETIME ft_;
    int64_t t_;
  };
  ASSERT(cpu_usage != NULL);
  TimeStamp created;
  TimeStamp exited;
  TimeStamp kernel;
  TimeStamp user;
  HANDLE handle = OpenThread(THREAD_QUERY_INFORMATION, false, thread_id);
  BOOL result = GetThreadTimes(handle,
                               &created.ft_,
                               &exited.ft_,
                               &kernel.ft_,
                               &user.ft_);
  CloseHandle(handle);
  if (!result) {
    FATAL1("GetThreadCpuUsage failed %d\n", GetLastError());
  }
  *cpu_usage = (user.t_ - kTimeEpoc) / kTimeScaler;
}


void Thread::SetThreadLocal(ThreadLocalKey key, uword value) {
  ASSERT(key != kUnsetThreadLocalKey);
  BOOL result = TlsSetValue(key, reinterpret_cast<void*>(value));
  if (!result) {
    FATAL1("TlsSetValue failed %d", GetLastError());
  }
}


Mutex::Mutex() {
  // Allocate unnamed semaphore with initial count 1 and max count 1.
  data_.semaphore_ = CreateSemaphore(NULL, 1, 1, NULL);
  if (data_.semaphore_ == NULL) {
    FATAL1("Mutex allocation failed %d", GetLastError());
  }
}


Mutex::~Mutex() {
  CloseHandle(data_.semaphore_);
}


void Mutex::Lock() {
  DWORD result = WaitForSingleObject(data_.semaphore_, INFINITE);
  if (result != WAIT_OBJECT_0) {
    FATAL1("Mutex lock failed %d", GetLastError());
  }
}


bool Mutex::TryLock() {
  // Attempt to pass the semaphore but return immediately.
  DWORD result = WaitForSingleObject(data_.semaphore_, 0);
  if (result == WAIT_OBJECT_0) {
    return true;
  }
  if (result == WAIT_ABANDONED || result == WAIT_FAILED) {
    FATAL1("Mutex try lock failed %d", GetLastError());
  }
  ASSERT(result == WAIT_TIMEOUT);
  return false;
}


void Mutex::Unlock() {
  BOOL result = ReleaseSemaphore(data_.semaphore_, 1, NULL);
  if (result == 0) {
    FATAL1("Mutex unlock failed %d", GetLastError());
  }
}


ThreadLocalKey MonitorWaitData::monitor_wait_data_key_ =
    Thread::kUnsetThreadLocalKey;


Monitor::Monitor() {
  InitializeCriticalSection(&data_.cs_);
  InitializeCriticalSection(&data_.waiters_cs_);
  data_.waiters_head_ = NULL;
  data_.waiters_tail_ = NULL;
}


Monitor::~Monitor() {
  DeleteCriticalSection(&data_.cs_);
  DeleteCriticalSection(&data_.waiters_cs_);
}


void Monitor::Enter() {
  EnterCriticalSection(&data_.cs_);
}


void Monitor::Exit() {
  LeaveCriticalSection(&data_.cs_);
}


void MonitorWaitData::ThreadExit() {
  if (MonitorWaitData::monitor_wait_data_key_ !=
      Thread::kUnsetThreadLocalKey) {
    uword raw_wait_data =
      Thread::GetThreadLocal(MonitorWaitData::monitor_wait_data_key_);
    if (raw_wait_data != 0) {
      MonitorWaitData* wait_data =
          reinterpret_cast<MonitorWaitData*>(raw_wait_data);
      delete wait_data;
    }
  }
}


void MonitorData::AddWaiter(MonitorWaitData* wait_data) {
  // Add the MonitorWaitData object to the list of objects waiting for
  // this monitor.
  EnterCriticalSection(&waiters_cs_);
  if (waiters_tail_ == NULL) {
    ASSERT(waiters_head_ == NULL);
    waiters_head_ = waiters_tail_ = wait_data;
  } else {
    waiters_tail_->next_ = wait_data;
    waiters_tail_ = wait_data;
  }
  LeaveCriticalSection(&waiters_cs_);
}


void MonitorData::RemoveWaiter(MonitorWaitData* wait_data) {
  // Remove the MonitorWaitData object from the list of objects
  // waiting for this monitor.
  EnterCriticalSection(&waiters_cs_);
  MonitorWaitData* previous = NULL;
  MonitorWaitData* current = waiters_head_;
  while (current != NULL) {
    if (current == wait_data) {
      if (waiters_head_ == waiters_tail_) {
        waiters_head_ = waiters_tail_ = NULL;
      } else if (current == waiters_head_) {
        waiters_head_ = waiters_head_->next_;
      } else if (current == waiters_tail_) {
        ASSERT(previous != NULL);
        waiters_tail_ = previous;
        previous->next_ = NULL;
      } else {
        ASSERT(previous != NULL);
        previous->next_ = current->next_;
      }
      // Clear next.
      wait_data->next_ = NULL;
      break;
    }
    previous = current;
    current = current->next_;
  }
  LeaveCriticalSection(&waiters_cs_);
}


void MonitorData::SignalAndRemoveFirstWaiter() {
  EnterCriticalSection(&waiters_cs_);
  MonitorWaitData* first = waiters_head_;
  if (first != NULL) {
    // Remove from list.
    if (waiters_head_ == waiters_tail_) {
      waiters_tail_ = waiters_head_ = NULL;
    } else {
      waiters_head_ = waiters_head_->next_;
    }
    // Clear next.
    first->next_ = NULL;
    // Signal event.
    BOOL result = SetEvent(first->event_);
    if (result == 0) {
      FATAL1("Monitor::Notify failed to signal event %d", GetLastError());
    }
  }
  LeaveCriticalSection(&waiters_cs_);
}


void MonitorData::SignalAndRemoveAllWaiters() {
  EnterCriticalSection(&waiters_cs_);
  // Extract list to signal.
  MonitorWaitData* current = waiters_head_;
  // Clear list.
  waiters_head_ = waiters_tail_ = NULL;
  // Iterate and signal all events.
  while (current != NULL) {
    // Copy next.
    MonitorWaitData* next = current->next_;
    // Clear next.
    current->next_ = NULL;
    // Signal event.
    BOOL result = SetEvent(current->event_);
    if (result == 0) {
      FATAL1("Failed to set event for NotifyAll %d", GetLastError());
    }
    current = next;
  }
  LeaveCriticalSection(&waiters_cs_);
}


MonitorWaitData* MonitorData::GetMonitorWaitDataForThread() {
  // Ensure that the thread local key for monitor wait data objects is
  // initialized.
  ASSERT(MonitorWaitData::monitor_wait_data_key_ !=
         Thread::kUnsetThreadLocalKey);

  // Get the MonitorWaitData object containing the event for this
  // thread from thread local storage. Create it if it does not exist.
  uword raw_wait_data =
    Thread::GetThreadLocal(MonitorWaitData::monitor_wait_data_key_);
  MonitorWaitData* wait_data = NULL;
  if (raw_wait_data == 0) {
    HANDLE event = CreateEvent(NULL, FALSE, FALSE, NULL);
    wait_data = new MonitorWaitData(event);
    Thread::SetThreadLocal(MonitorWaitData::monitor_wait_data_key_,
                           reinterpret_cast<uword>(wait_data));
  } else {
    wait_data = reinterpret_cast<MonitorWaitData*>(raw_wait_data);
    wait_data->next_ = NULL;
  }
  return wait_data;
}


Monitor::WaitResult Monitor::Wait(int64_t millis) {
  Monitor::WaitResult retval = kNotified;

  // Get the wait data object containing the event to wait for.
  MonitorWaitData* wait_data = MonitorData::GetMonitorWaitDataForThread();

  // Start waiting by adding the MonitorWaitData to the list of
  // waiters.
  data_.AddWaiter(wait_data);

  // Leave the monitor critical section while waiting.
  LeaveCriticalSection(&data_.cs_);

  // Perform the actual wait on the event.
  DWORD result = WAIT_FAILED;
  if (millis == 0) {
    // Wait forever for a Notify or a NotifyAll event.
    result = WaitForSingleObject(wait_data->event_, INFINITE);
    if (result == WAIT_FAILED) {
      FATAL1("Monitor::Wait failed %d", GetLastError());
    }
  } else {
    // Wait for the given period of time for a Notify or a NotifyAll
    // event.
    result = WaitForSingleObject(wait_data->event_, millis);
    if (result == WAIT_FAILED) {
      FATAL1("Monitor::Wait with timeout failed %d", GetLastError());
    }
    if (result == WAIT_TIMEOUT) {
      // No longer waiting. Remove from the list of waiters.
      data_.RemoveWaiter(wait_data);
      retval = kTimedOut;
    }
  }

  // Reacquire the monitor critical section before continuing.
  EnterCriticalSection(&data_.cs_);

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
  data_.SignalAndRemoveFirstWaiter();
}


void Monitor::NotifyAll() {
  // If one of the objects in the list of waiters wakes because of a
  // timeout before we signal it, that object will get an extra
  // signal. This will be treated as a spurious wake-up and is OK
  // since all uses of monitors should recheck the condition after a
  // Wait.
  data_.SignalAndRemoveAllWaiters();
}

}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
