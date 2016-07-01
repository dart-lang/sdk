// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_FUCHSIA_H_
#define VM_ATOMIC_FUCHSIA_H_

#if !defined VM_ATOMIC_H_
#error Do not include atomic_fuchsia.h directly. Use atomic.h instead.
#endif

#if !defined(TARGET_OS_FUCHSIA)
#error This file should only be included on Fuchsia builds.
#endif

#include "platform/assert.h"

namespace dart {

inline uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
  UNIMPLEMENTED();
  return 0;
}


inline void AtomicOperations::IncrementBy(intptr_t* p, intptr_t value) {
  UNIMPLEMENTED();
}


inline void AtomicOperations::IncrementInt64By(int64_t* p, int64_t value) {
  UNIMPLEMENTED();
}


inline uintptr_t AtomicOperations::FetchAndDecrement(uintptr_t* p) {
  UNIMPLEMENTED();
  return 0;
}


inline void AtomicOperations::DecrementBy(intptr_t* p, intptr_t value) {
  UNIMPLEMENTED();
}


#if !defined(USING_SIMULATOR_ATOMICS)
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
  UNIMPLEMENTED();
  return 0;
}


inline uint32_t AtomicOperations::CompareAndSwapUint32(uint32_t* ptr,
                                                       uint32_t old_value,
                                                       uint32_t new_value) {
  UNIMPLEMENTED();
  return 0;
}
#endif  // !defined(USING_SIMULATOR_ATOMICS)

}  // namespace dart

#endif  // VM_ATOMIC_FUCHSIA_H_
