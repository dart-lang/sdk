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
  // that are accessed by generated code
  static uintptr_t FetchAndIncrement(uintptr_t* p);

  static uword CompareAndSwapWord(uword* ptr, uword old_value, uword new_value);
};


}  // namespace dart

// We need to use the simulator to ensure that atomic operations are observed
// both in C++ and in generated code if the simulator is active.
#include "vm/atomic_simulator.h"

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
