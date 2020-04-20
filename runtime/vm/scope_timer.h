// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SCOPE_TIMER_H_
#define RUNTIME_VM_SCOPE_TIMER_H_

#include "platform/allocation.h"
#include "platform/globals.h"

#include "vm/os.h"

namespace dart {

// Simple utility class for timing a block of code.
class ScopeTimer : public ValueObject {
 public:
  explicit ScopeTimer(const char* name, bool enabled = true)
      : enabled_(enabled), name_(name), start_(0) {
    if (!enabled_) {
      return;
    }
    start_ = OS::GetCurrentMonotonicMicros();
  }

  int64_t GetElapsed() const {
    int64_t end = OS::GetCurrentMonotonicMicros();
    ASSERT(end >= start_);
    return end - start_;
  }

  ~ScopeTimer() {
    if (!enabled_) {
      return;
    }
    int64_t elapsed = GetElapsed();
    double seconds = MicrosecondsToSeconds(elapsed);
    OS::PrintErr("%s: %f seconds (%" Pd64 " \u00B5s)\n", name_, seconds,
                 elapsed);
  }

 private:
  const bool enabled_;
  const char* name_;
  int64_t start_;
};

}  // namespace dart

#endif  // RUNTIME_VM_SCOPE_TIMER_H_
