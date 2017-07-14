// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ATOMIC_WIN_H_
#define RUNTIME_VM_ATOMIC_WIN_H_

#if !defined RUNTIME_VM_ATOMIC_H_
#error Do not include atomic_win.h directly. Use atomic.h instead.
#endif

#if !defined(HOST_OS_WINDOWS)
#error This file should only be included on Windows builds.
#endif

namespace dart {

inline uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
#if defined(HOST_ARCH_X64)
  return static_cast<uintptr_t>(
             InterlockedIncrement64(reinterpret_cast<LONGLONG*>(p))) -
         1;
#elif defined(HOST_ARCH_IA32)
  return static_cast<uintptr_t>(
             InterlockedIncrement(reinterpret_cast<LONG*>(p))) -
         1;
#else
#error Unsupported host architecture.
#endif
}

inline intptr_t AtomicOperations::FetchAndIncrement(intptr_t* p) {
#if defined(HOST_ARCH_X64)
  return static_cast<intptr_t>(
             InterlockedIncrement64(reinterpret_cast<LONGLONG*>(p))) -
         1;
#elif defined(HOST_ARCH_IA32)
  return static_cast<intptr_t>(
             InterlockedIncrement(reinterpret_cast<LONG*>(p))) -
         1;
#else
#error Unsupported host architecture.
#endif
}

inline void AtomicOperations::IncrementBy(intptr_t* p, intptr_t value) {
#if defined(HOST_ARCH_X64)
  InterlockedExchangeAdd64(reinterpret_cast<LONGLONG*>(p),
                           static_cast<LONGLONG>(value));
#elif defined(HOST_ARCH_IA32)
  InterlockedExchangeAdd(reinterpret_cast<LONG*>(p), static_cast<LONG>(value));
#else
#error Unsupported host architecture.
#endif
}

inline void AtomicOperations::IncrementInt64By(int64_t* p, int64_t value) {
#if defined(HOST_ARCH_IA32) || defined(HOST_ARCH_X64)
  InterlockedExchangeAdd64(reinterpret_cast<LONGLONG*>(p),
                           static_cast<LONGLONG>(value));
#else
#error Unsupported host architecture.
#endif
}

inline uintptr_t AtomicOperations::FetchAndDecrement(uintptr_t* p) {
#if defined(HOST_ARCH_X64)
  return static_cast<uintptr_t>(
             InterlockedDecrement64(reinterpret_cast<LONGLONG*>(p))) +
         1;
#elif defined(HOST_ARCH_IA32)
  return static_cast<uintptr_t>(
             InterlockedDecrement(reinterpret_cast<LONG*>(p))) +
         1;
#else
#error Unsupported host architecture.
#endif
}

inline intptr_t AtomicOperations::FetchAndDecrement(intptr_t* p) {
#if defined(HOST_ARCH_X64)
  return static_cast<intptr_t>(
             InterlockedDecrement64(reinterpret_cast<LONGLONG*>(p))) +
         1;
#elif defined(HOST_ARCH_IA32)
  return static_cast<intptr_t>(
             InterlockedDecrement(reinterpret_cast<LONG*>(p))) +
         1;
#else
#error Unsupported host architecture.
#endif
}

inline void AtomicOperations::DecrementBy(intptr_t* p, intptr_t value) {
#if defined(HOST_ARCH_X64)
  InterlockedExchangeAdd64(reinterpret_cast<LONGLONG*>(p),
                           static_cast<LONGLONG>(-value));
#elif defined(HOST_ARCH_IA32)
  InterlockedExchangeAdd(reinterpret_cast<LONG*>(p), static_cast<LONG>(-value));
#else
#error Unsupported host architecture.
#endif
}

#if !defined(USING_SIMULATOR)
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
#if defined(HOST_ARCH_X64)
  return static_cast<uword>(InterlockedCompareExchange64(
      reinterpret_cast<LONGLONG*>(ptr), static_cast<LONGLONG>(new_value),
      static_cast<LONGLONG>(old_value)));
#elif defined(HOST_ARCH_IA32)
  return static_cast<uword>(InterlockedCompareExchange(
      reinterpret_cast<LONG*>(ptr), static_cast<LONG>(new_value),
      static_cast<LONG>(old_value)));
#else
#error Unsupported host architecture.
#endif
}
inline uint32_t AtomicOperations::CompareAndSwapUint32(uint32_t* ptr,
                                                       uint32_t old_value,
                                                       uint32_t new_value) {
#if (defined(HOST_ARCH_X64) || defined(HOST_ARCH_IA32))
  return static_cast<uint32_t>(InterlockedCompareExchange(
      reinterpret_cast<LONG*>(ptr), static_cast<LONG>(new_value),
      static_cast<LONG>(old_value)));
#else
#error Unsupported host architecture.
#endif
}
#endif  // !defined(USING_SIMULATOR)

}  // namespace dart

#endif  // RUNTIME_VM_ATOMIC_WIN_H_
