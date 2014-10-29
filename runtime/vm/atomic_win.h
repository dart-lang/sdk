// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_WIN_H_
#define VM_ATOMIC_WIN_H_

#if !defined VM_ATOMIC_H_
#error Do not include atomic_win.h directly. Use atomic.h instead.
#endif

#if !defined(TARGET_OS_WINDOWS)
#error This file should only be included on Windows builds.
#endif

namespace dart {

inline uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
#if defined(TARGET_ARCH_X64)
  return static_cast<uintptr_t>(
      InterlockedIncrement64(reinterpret_cast<LONGLONG*>(p))) - 1;
#elif defined(TARGET_ARCH_IA32)
  return static_cast<uintptr_t>(
      InterlockedIncrement(reinterpret_cast<LONG*>(p))) - 1;
#else
  UNIMPLEMENTED();
#endif
}


#if !defined(USING_SIMULATOR)
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
#if defined(TARGET_ARCH_X64)
  return static_cast<uword>(
      InterlockedCompareExchange64(reinterpret_cast<LONGLONG*>(ptr),
                                   static_cast<LONGLONG>(new_value),
                                   static_cast<LONGLONG>(old_value)));
#elif defined(TARGET_ARCH_IA32)
  return static_cast<uword>(
      InterlockedCompareExchange(reinterpret_cast<LONG*>(ptr),
                                 static_cast<LONG>(new_value),
                                 static_cast<LONG>(old_value)));
#else
  UNIMPLEMENTED();
#endif
}
#endif  // !defined(USING_SIMULATOR)

}  // namespace dart

#endif  // VM_ATOMIC_WIN_H_
