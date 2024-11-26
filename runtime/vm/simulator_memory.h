// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SIMULATOR_MEMORY_H_
#define RUNTIME_VM_SIMULATOR_MEMORY_H_

#include <atomic>

#include "platform/unaligned.h"
#include "vm/globals.h"

namespace dart {

class DirectSimulatorMemory {
 public:
  template <typename T>
  T Load(uword addr) {
    return LoadUnaligned(reinterpret_cast<T*>(addr));
  }

  template <typename T>
  void Store(uword addr, T value) {
    StoreUnaligned(reinterpret_cast<T*>(addr), value);
  }

  template <typename T>
  T Load(uword addr, std::memory_order order) {
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    return reinterpret_cast<std::atomic<T>*>(addr)->load(order);
  }

  template <typename T>
  void Store(uword addr, T value, std::memory_order order) {
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    reinterpret_cast<std::atomic<T>*>(addr)->store(value, order);
  }

  template <typename T>
  bool CompareExchange(uword addr,
                       T& old_value,
                       T value,
                       std::memory_order order) {
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    return reinterpret_cast<std::atomic<T>*>(addr)->compare_exchange_weak(
        old_value, value, order);
  }

  void FlushAddress(uword addr) {}
  void FlushAll() {}
};

class BufferedSimulatorMemory {
 public:
  template <typename T>
  T Load(uword addr) {
    if (UNLIKELY((sizeof(T) > sizeof(uword)) ||
                 ((addr & (sizeof(T) - 1)) != 0))) {
      FlushAll();
      return LoadUnaligned(reinterpret_cast<T*>(addr));
    }
    uword word_addr = addr & ~(sizeof(uword) - 1);
    uword word_offset = addr - word_addr;
    for (intptr_t i = size_ - 1; i >= 0; i--) {
      if (buffer_[i].addr == word_addr) {
        uword buffer_addr =
            reinterpret_cast<uword>(&buffer_[i].value) + word_offset;
        return *reinterpret_cast<T*>(buffer_addr);
      }
    }
    return *reinterpret_cast<T*>(addr);
  }

  template <typename T>
  void Store(uword addr, T value) {
    if (UNLIKELY((sizeof(T) > sizeof(uword)) ||
                 ((addr & (sizeof(T) - 1)) != 0))) {
      FlushAll();
      StoreUnaligned(reinterpret_cast<T*>(addr), value);
      return;
    }
    uword word_addr = addr & ~(sizeof(uword) - 1);
    uword word_offset = addr - word_addr;
    for (intptr_t i = size_ - 1; i >= 0; i--) {
      if (buffer_[i].addr == word_addr) {
        uword buffer_addr =
            reinterpret_cast<uword>(&buffer_[i].value) + word_offset;
        *reinterpret_cast<T*>(buffer_addr) = value;
        return;
      }
    }
    buffer_[size_] = {word_addr, *reinterpret_cast<uword*>(word_addr)};
    uword buffer_addr =
        reinterpret_cast<uword>(&buffer_[size_].value) + word_offset;
    *reinterpret_cast<T*>(buffer_addr) = value;
    size_++;

    if (size_ == kCapacity) {
      FlushSome();
    }
  }

  template <typename T>
  T Load(uword addr, std::memory_order order) {
    FlushAddress(addr);
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    return reinterpret_cast<std::atomic<T>*>(addr)->load(order);
  }

  template <typename T>
  void Store(uword addr, T value, std::memory_order order) {
    FlushAddress(addr);
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    reinterpret_cast<std::atomic<T>*>(addr)->store(value, order);
  }

  template <typename T>
  bool CompareExchange(uword addr,
                       T& old_value,
                       T value,
                       std::memory_order order) {
    FlushAddress(addr);
    // TODO(42074): Once we switch to C++20 we should change this to use use
    // `std::atomic_ref<T>` which supports performing atomic operations on
    // non-atomic data.
    static_assert(sizeof(std::atomic<T>) == sizeof(T));
    return reinterpret_cast<std::atomic<T>*>(addr)->compare_exchange_weak(
        old_value, value, order);
  }

  void FlushAddress(uword addr) {
    for (intptr_t i = 0; i < size_; i++) {
      if (buffer_[i].addr == addr) {
        *reinterpret_cast<uword*>(buffer_[i].addr) = buffer_[i].value;
        buffer_[i] = buffer_[size_ - 1];
        size_--;
      }
    }
  }

  void FlushAll() {
    for (intptr_t i = 0; i < size_; i++) {
      *reinterpret_cast<uword*>(buffer_[i].addr) = buffer_[i].value;
    }
    size_ = 0;
  }

 private:
  void FlushSome() {
    while (size_ > (kCapacity / 2)) {
      intptr_t i = buffer_[0].value;
      i ^= (i >> 4);
      i ^= (i >> 8);
      i = i % size_;
      *reinterpret_cast<uword*>(buffer_[i].addr) = buffer_[i].value;
      buffer_[i] = buffer_[size_ - 1];
      size_--;
    }
  }

  struct Entry {
    uword addr;
    uword value;
  };
  static constexpr intptr_t kCapacity = 16;
  intptr_t size_ = 0;
  Entry buffer_[kCapacity];
};

class SimulatorMemory {
 public:
  explicit SimulatorMemory(bool use_buffered) : use_buffered_(use_buffered) {}

  template <typename T>
  T Load(uword addr) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.Load<T>(addr);
    } else {
      return direct_.Load<T>(addr);
    }
  }

  template <typename T>
  void Store(uword addr, T value) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.Store<T>(addr, value);
    } else {
      return direct_.Store<T>(addr, value);
    }
  }

  template <typename T>
  T Load(uword addr, std::memory_order order) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.Load<T>(addr, order);
    } else {
      return direct_.Load<T>(addr, order);
    }
  }

  template <typename T>
  void Store(uword addr, T value, std::memory_order order) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.Store<T>(addr, value, order);
    } else {
      return direct_.Store<T>(addr, value, order);
    }
  }

  template <typename T>
  bool CompareExchange(uword addr,
                       T& old_value,
                       T value,
                       std::memory_order order) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.CompareExchange<T>(addr, old_value, value, order);
    } else {
      return direct_.CompareExchange<T>(addr, old_value, value, order);
    }
  }

  void FlushAddress(uword addr) {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.FlushAddress(addr);
    } else {
      return direct_.FlushAddress(addr);
    }
  }

  void FlushAll() {
    if (UNLIKELY(use_buffered_)) {
      return buffered_.FlushAll();
    } else {
      return direct_.FlushAll();
    }
  }

  DirectSimulatorMemory direct_;
  BufferedSimulatorMemory buffered_;
  const bool use_buffered_;
};

}  // namespace dart

#endif  // RUNTIME_VM_SIMULATOR_MEMORY_H_
