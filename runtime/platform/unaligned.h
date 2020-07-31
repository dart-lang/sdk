// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNALIGNED_H_
#define RUNTIME_PLATFORM_UNALIGNED_H_

#include "platform/globals.h"
#include "platform/undefined_behavior_sanitizer.h"

namespace dart {

#if defined(HOST_ARCH_ARM) || defined(HOST_ARCH_ARM64)
template <typename T>
static inline T LoadUnaligned(const T* ptr) {
  T value;
  memcpy(reinterpret_cast<void*>(&value), reinterpret_cast<const void*>(ptr),
         sizeof(value));
  return value;
}

template <typename T>
static inline void StoreUnaligned(T* ptr, T value) {
  memcpy(reinterpret_cast<void*>(ptr), reinterpret_cast<const void*>(&value),
         sizeof(value));
}
#else   // !(HOST_ARCH_ARM || HOST_ARCH_ARM64)
template <typename T>
NO_SANITIZE_UNDEFINED("alignment")
static inline T LoadUnaligned(const T* ptr) {
  return *ptr;
}

template <typename T>
NO_SANITIZE_UNDEFINED("alignment")
static inline void StoreUnaligned(T* ptr, T value) {
  *ptr = value;
}
#endif  // !(HOST_ARCH_ARM || HOST_ARCH_ARM64)

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UNALIGNED_H_
