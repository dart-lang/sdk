// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ATOMIC_H_
#define RUNTIME_PLATFORM_ATOMIC_H_

#include <atomic>

#include "platform/allocation.h"
#include "platform/globals.h"

namespace dart {

// Like std::atomic, but operations default to relaxed ordering instead of
// acquire-release ordering.
template <typename T>
class RelaxedAtomic {
 public:
  constexpr RelaxedAtomic() : value_() {}
  constexpr RelaxedAtomic(T arg) : value_(arg) {}           // NOLINT
  RelaxedAtomic(const RelaxedAtomic& arg) : value_(arg) {}  // NOLINT

  T load() const { return value_.load(std::memory_order_relaxed); }
  void store(T arg) { value_.store(arg, std::memory_order_relaxed); }

  T fetch_add(T arg) {
    return value_.fetch_add(arg, std::memory_order_relaxed);
  }
  T fetch_sub(T arg) {
    return value_.fetch_sub(arg, std::memory_order_relaxed);
  }
  T fetch_or(T arg) { return value_.fetch_or(arg, std::memory_order_relaxed); }
  T fetch_and(T arg) {
    return value_.fetch_and(arg, std::memory_order_relaxed);
  }

  bool compare_exchange_weak(T& expected, T desired) {  // NOLINT
    return value_.compare_exchange_weak(expected, desired,
                                        std::memory_order_relaxed,
                                        std::memory_order_relaxed);
  }
  bool compare_exchange_strong(T& expected, T desired) {  // NOLINT
    return value_.compare_exchange_strong(expected, desired,
                                          std::memory_order_relaxed,
                                          std::memory_order_relaxed);
  }

  operator T() const { return load(); }
  T operator=(T arg) {
    store(arg);
    return arg;
  }
  T operator=(const RelaxedAtomic& arg) {
    T loaded_once = arg;
    store(loaded_once);
    return loaded_once;
  }
  T operator+=(T arg) { return fetch_add(arg) + arg; }
  T operator-=(T arg) { return fetch_sub(arg) - arg; }

 private:
  std::atomic<T> value_;
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_ATOMIC_H_
