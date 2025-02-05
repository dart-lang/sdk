// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/no_tsan.h"

namespace dart {

#if defined(__clang__)

#if defined(__has_feature)
#if __has_feature(thread_sanitizer)
#error Misconfigured build
#endif
#endif

uintptr_t FetchAndRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                    uintptr_t value) {
  return ptr->fetch_and(value, std::memory_order_relaxed);
}

uintptr_t FetchOrRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                   uintptr_t value) {
  return ptr->fetch_or(value, std::memory_order_relaxed);
}

uintptr_t LoadRelaxedIgnoreRace(const std::atomic<uintptr_t>* ptr) {
  return ptr->load(std::memory_order_relaxed);
}

#endif  // defined(__clang__)

}  // namespace dart
