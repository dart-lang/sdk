// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ATOMIC_H_
#define RUNTIME_PLATFORM_ATOMIC_H_

#include <atomic>

namespace dart {

// Like std::atomic, but operations default to relaxed ordering instead of
// sequential consistency.
template <typename T>
class RelaxedAtomic {
 public:
  constexpr RelaxedAtomic() : value_() {}
  constexpr RelaxedAtomic(T arg) : value_(arg) {}           // NOLINT
  RelaxedAtomic(const RelaxedAtomic& arg) : value_(arg) {}  // NOLINT

  T load(std::memory_order order = std::memory_order_relaxed) const {
    return value_.load(order);
  }
  T load(std::memory_order order = std::memory_order_relaxed) const volatile {
    return value_.load(order);
  }
  void store(T arg, std::memory_order order = std::memory_order_relaxed) {
    value_.store(arg, order);
  }
  void store(T arg,
             std::memory_order order = std::memory_order_relaxed) volatile {
    value_.store(arg, order);
  }

  T fetch_add(T arg, std::memory_order order = std::memory_order_relaxed) {
    return value_.fetch_add(arg, order);
  }
  T fetch_sub(T arg, std::memory_order order = std::memory_order_relaxed) {
    return value_.fetch_sub(arg, order);
  }
  T fetch_or(T arg, std::memory_order order = std::memory_order_relaxed) {
    return value_.fetch_or(arg, order);
  }
  T fetch_and(T arg, std::memory_order order = std::memory_order_relaxed) {
    return value_.fetch_and(arg, order);
  }

  T exchange(T arg, std::memory_order order = std::memory_order_relaxed) {
    return value_.exchange(arg, order);
  }

  bool compare_exchange_weak(
      T& expected,  // NOLINT
      T desired,
      std::memory_order order = std::memory_order_relaxed) {
    return value_.compare_exchange_weak(expected, desired, order, order);
  }
  bool compare_exchange_weak(
      T& expected,  // NOLINT
      T desired,
      std::memory_order order = std::memory_order_relaxed) volatile {
    return value_.compare_exchange_weak(expected, desired, order, order);
  }
  bool compare_exchange_strong(
      T& expected,  // NOLINT
      T desired,
      std::memory_order order = std::memory_order_relaxed) {
    return value_.compare_exchange_strong(expected, desired, order, order);
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
  T& operator++() { return fetch_add(1) + 1; }
  T& operator--() { return fetch_sub(1) - 1; }
  T operator++(int) { return fetch_add(1); }
  T operator--(int) { return fetch_sub(1); }

 private:
  std::atomic<T> value_;
};

// Like std::atomic, but operations default to acquire for load, release for
// stores, and acquire-release for read-and-updates.
template <typename T>
class AcqRelAtomic {
 public:
  constexpr AcqRelAtomic() : value_() {}
  constexpr AcqRelAtomic(T arg) : value_(arg) {}  // NOLINT
  AcqRelAtomic(const AcqRelAtomic& arg) = delete;

  T load(std::memory_order order = std::memory_order_acquire) const {
    return value_.load(order);
  }
  void store(T arg, std::memory_order order = std::memory_order_release) {
    value_.store(arg, order);
  }

  T fetch_add(T arg, std::memory_order order = std::memory_order_acq_rel) {
    return value_.fetch_add(arg, order);
  }
  T fetch_sub(T arg, std::memory_order order = std::memory_order_acq_rel) {
    return value_.fetch_sub(arg, order);
  }
  T fetch_or(T arg, std::memory_order order = std::memory_order_acq_rel) {
    return value_.fetch_or(arg, order);
  }
  T fetch_and(T arg, std::memory_order order = std::memory_order_acq_rel) {
    return value_.fetch_and(arg, order);
  }

  bool compare_exchange_weak(
      T& expected,  // NOLINT
      T desired,
      std::memory_order success_order = std::memory_order_acq_rel,
      std::memory_order failure_order = std::memory_order_seq_cst) {
    return value_.compare_exchange_weak(expected, desired, success_order,
                                        failure_order);
  }
  bool compare_exchange_strong(
      T& expected,  // NOLINT
      T desired,
      std::memory_order success_order = std::memory_order_acq_rel,
      std::memory_order failure_order = std::memory_order_seq_cst) {
    return value_.compare_exchange_strong(expected, desired, success_order,
                                          failure_order);
  }

  // Require explicit loads and stores.
  operator T() const = delete;
  T operator=(T arg) = delete;
  T operator=(const AcqRelAtomic& arg) = delete;
  T operator+=(T arg) = delete;
  T operator-=(T arg) = delete;

 private:
  std::atomic<T> value_;
};

template <typename T>
static inline T LoadRelaxed(const T* ptr) {
  static_assert(sizeof(std::atomic<T>) == sizeof(T));
  return reinterpret_cast<const std::atomic<T>*>(ptr)->load(
      std::memory_order_relaxed);
}

template <typename T>
static inline T LoadAcquire(const T* ptr) {
  static_assert(sizeof(std::atomic<T>) == sizeof(T));
  return reinterpret_cast<const std::atomic<T>*>(ptr)->load(
      std::memory_order_acquire);
}

template <typename T>
static inline void StoreRelease(T* ptr, T value) {
  static_assert(sizeof(std::atomic<T>) == sizeof(T));
  reinterpret_cast<std::atomic<T>*>(ptr)->store(value,
                                                std::memory_order_release);
}

}  // namespace dart

#endif  // RUNTIME_PLATFORM_ATOMIC_H_
