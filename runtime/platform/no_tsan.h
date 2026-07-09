// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_NO_TSAN_H_
#define RUNTIME_PLATFORM_NO_TSAN_H_

#include <stdint.h>

#include <atomic>

#include "platform/thread_sanitizer.h"

namespace dart {

#if defined(__GNUC__)
// GCC will do what we want with no_sanitize("thread") and std::atomic, but for
// Clang will need to use disable_sanitizer_instrumentation and the atomic
// builtins.
NO_SANITIZE_THREAD DISABLE_SANITIZER_INSTRUMENTATION inline uintptr_t
FetchAndRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr, uintptr_t value) {
  return __atomic_fetch_and(reinterpret_cast<uintptr_t*>(ptr), value,
                            __ATOMIC_RELAXED);
}
NO_SANITIZE_THREAD DISABLE_SANITIZER_INSTRUMENTATION inline uintptr_t
FetchOrRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr, uintptr_t value) {
  return __atomic_fetch_or(reinterpret_cast<uintptr_t*>(ptr), value,
                           __ATOMIC_RELAXED);
}
NO_SANITIZE_THREAD DISABLE_SANITIZER_INSTRUMENTATION inline uintptr_t
LoadRelaxedIgnoreRace(const std::atomic<uintptr_t>* ptr) {
  return __atomic_load_n(reinterpret_cast<const uintptr_t*>(ptr),
                         __ATOMIC_RELAXED);
}
#else
// MSVC doesn't support TSAN.
inline uintptr_t FetchAndRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                           uintptr_t value) {
  return ptr->fetch_and(value, std::memory_order_relaxed);
}
inline uintptr_t FetchOrRelaxedIgnoreRace(std::atomic<uintptr_t>* ptr,
                                          uintptr_t value) {
  return ptr->fetch_or(value, std::memory_order_relaxed);
}
inline uintptr_t LoadRelaxedIgnoreRace(const std::atomic<uintptr_t>* ptr) {
  return ptr->load(std::memory_order_relaxed);
}
#endif

}  // namespace dart

#endif  // RUNTIME_PLATFORM_NO_TSAN_H_
