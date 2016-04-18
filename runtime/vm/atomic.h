// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_H_
#define VM_ATOMIC_H_

#include "platform/globals.h"

#include "vm/allocation.h"
#include "vm/simulator.h"

namespace dart {

class AtomicOperations : public AllStatic {
 public:
  // Atomically fetch the value at p and increment the value at p.
  // Returns the original value at p.
  //
  // NOTE: Not to be used for any atomic operations involving memory locations
  // that are accessed by generated code.
  static uintptr_t FetchAndIncrement(uintptr_t* p);

  // Atomically increment the value at p by 'value'.
  //
  // NOTE: Not to be used for any atomic operations involving memory locations
  // that are accessed by generated code.
  static void IncrementBy(intptr_t* p, intptr_t value);
  static void IncrementInt64By(int64_t* p, int64_t value);

  // Atomically fetch the value at p and decrement the value at p.
  // Returns the original value at p.
  //
  // NOTE: Not to be used for any atomic operations involving memory locations
  // that are accessed by generated code.
  static uintptr_t FetchAndDecrement(uintptr_t* p);

  // Atomically decrement the value at p by 'value'.
  //
  // NOTE: Not to be used for any atomic operations involving memory locations
  // that are accessed by generated code.
  static void DecrementBy(intptr_t* p, intptr_t value);

  // Atomically compare *ptr to old_value, and if equal, store new_value.
  // Returns the original value at ptr.
  //
  // NOTE: OK to use with memory locations that are accessed by generated code
  static uword CompareAndSwapWord(uword* ptr, uword old_value, uword new_value);
  static uint32_t CompareAndSwapUint32(
      uint32_t* ptr, uint32_t old_value, uint32_t new_value);

  // Performs a load of a word from 'ptr', but without any guarantees about
  // memory order (i.e., no load barriers/fences).
  static uword LoadRelaxed(uword* ptr) {
    return *static_cast<volatile uword*>(ptr);
  }

  // Performs a load of a word from 'ptr', but without any guarantees about
  // memory order (i.e., no load barriers/fences).
  static intptr_t LoadRelaxedIntPtr(intptr_t* ptr) {
    return *static_cast<volatile intptr_t*>(ptr);
  }
};


}  // namespace dart

#if defined(USING_SIMULATOR) && !defined(TARGET_ARCH_DBC)
#define USING_SIMULATOR_ATOMICS
#endif

#if defined(USING_SIMULATOR_ATOMICS)
// We need to use the simulator to ensure that atomic operations are observed
// both in C++ and in generated code if the simulator is active.
#include "vm/atomic_simulator.h"
#endif

#if defined(TARGET_OS_ANDROID)
#include "vm/atomic_android.h"
#elif defined(TARGET_OS_LINUX)
#include "vm/atomic_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "vm/atomic_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "vm/atomic_win.h"
#else
#error Unknown target os.
#endif

#endif  // VM_ATOMIC_H_
