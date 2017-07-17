// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ATOMIC_SIMULATOR_H_
#define RUNTIME_VM_ATOMIC_SIMULATOR_H_

#if !defined RUNTIME_VM_ATOMIC_H_
#error Do not include atomic_simulator.h directly. Use atomic.h instead.
#endif

namespace dart {

#if defined(USING_SIMULATOR_ATOMICS)
// Forward atomic operations to the simulator if the simulator is active.
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
  return Simulator::CompareExchange(ptr, old_value, new_value);
}

inline uint32_t AtomicOperations::CompareAndSwapUint32(uint32_t* ptr,
                                                       uint32_t old_value,
                                                       uint32_t new_value) {
  return Simulator::CompareExchangeUint32(ptr, old_value, new_value);
}
#endif  // defined(USING_SIMULATOR_ATOMICS)

}  // namespace dart

#endif  // RUNTIME_VM_ATOMIC_SIMULATOR_H_
