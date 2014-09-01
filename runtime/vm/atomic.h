// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ATOMIC_H_
#define VM_ATOMIC_H_

#include "platform/globals.h"

#include "vm/allocation.h"

namespace dart {

class AtomicOperations : public AllStatic {
 public:
  // Atomically fetch the value at p and increment the value at p.
  // Returns the original value at p.
  static uintptr_t FetchAndIncrement(uintptr_t* p);

  static uword CompareAndSwapWord(uword* ptr, uword old_value, uword new_value);
};


}  // namespace dart

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
