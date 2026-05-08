// Copyright 2025 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_BASE_MEMCOPY_H_
#define V8_BASE_MEMCOPY_H_

#include <stdlib.h>

#include <atomic>

#include "vm/regexp/base.h"

namespace base {

// Copy memory area to disjoint memory area.
inline void MemCopy(void* dest, const void* src, size_t size) {
  memcpy(dest, src, size);  // NOLINT
}

inline void MemMove(void* dest, const void* src, size_t size) {
  memmove(dest, src, size);  // NOLINT
}

template <typename T>
V8_INLINE bool TryTrivialCopy(const T* src_begin, const T* src_end, T* dest) {
  DCHECK_LE(src_begin, src_end);
  if constexpr (std::is_trivially_copyable_v<T>) {
    const size_t count = src_end - src_begin;
    base::MemCopy(dest, src_begin, count * sizeof(T));
    return true;
  }
  return false;
}

template <typename T>
V8_INLINE bool TryTrivialMove(const T* src_begin, const T* src_end, T* dest) {
  DCHECK_LE(src_begin, src_end);
  if constexpr (std::is_trivially_copyable_v<T>) {
    const size_t count = src_end - src_begin;
    base::MemMove(dest, src_begin, count * sizeof(T));
    return true;
  }
  return false;
}

// Fills `destination` with `count` `value`s.
template <typename T, typename U>
constexpr void Memset(T* destination, U value, size_t count)
  requires std::is_trivially_assignable_v<T&, U>
{
  for (size_t i = 0; i < count; i++) {
    destination[i] = value;
  }
}

// Fills `destination` with `count` `value`s.
template <typename T>
inline void Relaxed_Memset(T* destination, T value, size_t count)
  requires std::is_integral_v<T>
{
  for (size_t i = 0; i < count; i++) {
    std::atomic_ref<T>(destination[i]).store(value, std::memory_order_relaxed);
  }
}

}  // namespace base

#endif  // V8_BASE_MEMCOPY_H_
