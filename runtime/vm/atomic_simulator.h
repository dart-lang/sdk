// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_SIMULATOR_H_
#define VM_ATOMIC_SIMULATOR_H_

#if !defined VM_ATOMIC_H_
#error Do not include atomic_simulator.h directly. Use atomic.h instead.
#endif

namespace dart {

#if defined(USING_SIMULATOR)
// Forward atomic operations to the simulator if the simulator is active.
inline uword AtomicOperations::CompareAndSwapWord(uword* ptr,
                                                  uword old_value,
                                                  uword new_value) {
  return Simulator::CompareExchange(ptr, old_value, new_value);
}
#endif  // defined(USING_SIMULATOR)

}  // namespace dart

#endif  // VM_ATOMIC_SIMULATOR_H_
