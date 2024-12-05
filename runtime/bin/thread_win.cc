// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)

#include "bin/thread.h"

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

int Thread::TryStart(const char* name,
                     ThreadStartFunction function,
                     uword parameter) {
  ThreadStartData* start_data = new ThreadStartData(name, function, parameter);
  uint32_t tid;
  uintptr_t thread = _beginthreadex(nullptr, Thread::GetMaxStackSize(),
                                    ThreadEntry, start_data, 0, &tid);
  if ((thread == -1L) || (thread == 0)) {
    return errno;
  }

  // Close the handle, so we don't leak the thread object.
  CloseHandle(reinterpret_cast<HANDLE>(thread));

  return 0;
}

intptr_t Thread::GetMaxStackSize() {
  const int kStackSize = (128 * kWordSize * KB);
  return kStackSize;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)
