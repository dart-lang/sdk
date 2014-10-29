// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_MACOS_H_
#define VM_ATOMIC_MACOS_H_

#if !defined VM_ATOMIC_H_
#error Do not include atomic_macos.h directly. Use atomic.h instead.
#endif

#if !defined(TARGET_OS_MACOS)
#error This file should only be included on Mac OS X builds.
#endif

namespace dart {


inline uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
  return __sync_fetch_and_add(p, 1);
}


#if !defined(USING_SIMULATOR)
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
  return __sync_val_compare_and_swap(ptr, old_value, new_value);
}
#endif  // !defined(USING_SIMULATOR)

}  // namespace dart

#endif  // VM_ATOMIC_MACOS_H_
