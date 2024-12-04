// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_NO_TSAN_H_
#define RUNTIME_PLATFORM_NO_TSAN_H_

#include <stdint.h>

#include <atomic>

namespace dart {

#if defined(__clang__)
// Clang does not honor no_sanitize(thread) for std::atomic, so we place
// the implementation in a separate compilation unit with TSAN disabled.
uintptr_t FetchAndRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                    uintptr_t value);
uintptr_t FetchOrRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                   uintptr_t value);
uintptr_t LoadRelaxedIgnoreRace(const std::atomic<uintptr_t>* ptr);
#else
#if defined(__GNUC__)
__attribute__((no_sanitize("thread")))
#endif
inline uintptr_t
FetchAndRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr, uintptr_t value) {
  return ptr->fetch_and(value, std::memory_order_relaxed);
}
#if defined(__GNUC__)
__attribute__((no_sanitize("thread")))
#endif
inline uintptr_t
FetchOrRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr, uintptr_t value) {
  return ptr->fetch_or(value, std::memory_order_relaxed);
}
#if defined(__GNUC__)
__attribute__((no_sanitize("thread")))
#endif
inline uintptr_t
LoadRelaxedIgnoreRace(const std::atomic<uintptr_t>* ptr) {
  return ptr->load(std::memory_order_relaxed);
}
#endif

}  // namespace dart

#endif  // RUNTIME_PLATFORM_NO_TSAN_H_
