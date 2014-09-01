// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_ANDROID_H_
#define VM_ATOMIC_ANDROID_H_

#if !defined VM_ATOMIC_H_
#error Do not include atomic_android.h directly. Use atomic.h instead.
#endif

#if !defined(TARGET_OS_ANDROID)
#error This file should only be included on Android builds.
#endif

namespace dart {


inline uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
  return __sync_fetch_and_add(p, 1);
}


inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
  return __sync_val_compare_and_swap(ptr, old_value, new_value);
}

}  // namespace dart

#endif  // VM_ATOMIC_ANDROID_H_
