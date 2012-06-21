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
  uintptr_t thread = _beginthreadex(NULL, Thread::GetMaxStackSize(),
                                    ThreadEntry, start_data, 0, &tid);
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


intptr_t Thread::GetMaxStackSize() {
  const int kStackSize = (512 * KB);
  return kStackSize;
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
    // Signal event.
    BOOL result = SetEvent(first->event_);
    if (result == 0) {
      FATAL("Monitor::Notify failed to signal event");
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
    BOOL result = SetEvent(current->event_);
    if (result == 0) {
      FATAL("Failed to set event for NotifyAll");
    }
    current = current->next_;
  }
  LeaveCriticalSection(&waiters_cs_);
}


MonitorWaitData* MonitorData::GetMonitorWaitDataForThread() {
  // Ensure that the thread local key for monitor wait data objects is
  // initialized.
  EnterCriticalSection(&waiters_cs_);
  if (MonitorWaitData::monitor_wait_data_key_ == Thread::kUnsetThreadLocalKey) {
    MonitorWaitData::monitor_wait_data_key_ = Thread::CreateThreadLocal();
  }
  LeaveCriticalSection(&waiters_cs_);

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
  MonitorWaitData* wait_data = data_.GetMonitorWaitDataForThread();

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
      FATAL("Monitor::Wait failed");
    }
  } else {
    // Wait for the given period of time for a Notify or a NotifyAll
    // event.
    result = WaitForSingleObject(wait_data->event_, millis);
    if (result == WAIT_FAILED) {
      FATAL("Monitor::Wait with timeout failed");
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
