// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_UNALIGNED_H_
#define RUNTIME_PLATFORM_UNALIGNED_H_

#include "platform/globals.h"
#include "platform/undefined_behavior_sanitizer.h"

namespace dart {

template <typename T>
static inline T LoadUnaligned(const T* ptr) {
  T value;
  memcpy(reinterpret_cast<void*>(&value),  // NOLINT
         reinterpret_cast<const void*>(ptr), sizeof(value));
  return value;
}

template <typename T>
static inline void StoreUnaligned(T* ptr, T value) {
  memcpy(reinterpret_cast<void*>(ptr),  // NOLINT
         reinterpret_cast<const void*>(&value), sizeof(value));
}

}  // namespace dart

#endif  // RUNTIME_PLATFORM_UNALIGNED_H_
