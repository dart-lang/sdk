// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ATOMIC_H_
#define RUNTIME_PLATFORM_ATOMIC_H_

#include "platform/globals.h"

#include "platform/allocation.h"

namespace dart {

class AtomicOperations : public AllStatic {
 public:
  // Atomically fetch the value at p and increment the value at p.
  // Returns the original value at p.
  static uintptr_t FetchAndIncrement(uintptr_t* p);
  static intptr_t FetchAndIncrement(intptr_t* p);

  // Atomically increment the value at p by 'value'.
  static void IncrementBy(intptr_t* p, intptr_t value);
  static void IncrementInt64By(int64_t* p, int64_t value);

  // Atomically fetch the value at p and decrement the value at p.
  // Returns the original value at p.
  static uintptr_t FetchAndDecrement(uintptr_t* p);
  static intptr_t FetchAndDecrement(intptr_t* p);

  // Atomically decrement the value at p by 'value'.
  static void DecrementBy(intptr_t* p, intptr_t value);

  // Atomically perform { tmp = *ptr; *ptr = (tmp OP value); return tmp; }.
  static uint32_t FetchOrRelaxedUint32(uint32_t* ptr, uint32_t value);
  static uint32_t FetchAndRelaxedUint32(uint32_t* ptr, uint32_t value);

  // Atomically compare *ptr to old_value, and if equal, store new_value.
  // Returns the original value at ptr.
  static uword CompareAndSwapWord(uword* ptr, uword old_value, uword new_value);
  static uint32_t CompareAndSwapUint32(uint32_t* ptr,
                                       uint32_t old_value,
                                       uint32_t new_value);

  // Performs a load of a word from 'ptr', but without any guarantees about
  // memory order (i.e., no load barriers/fences).
  template <typename T>
  static T LoadRelaxed(T* ptr) {
    return *static_cast<volatile T*>(ptr);
  }

  template <typename T>
  static T LoadAcquire(T* ptr);

  template <typename T>
  static void StoreRelease(T* ptr, T value);

  template <typename T>
  static T* CompareAndSwapPointer(T** slot, T* old_value, T* new_value) {
    return reinterpret_cast<T*>(AtomicOperations::CompareAndSwapWord(
        reinterpret_cast<uword*>(slot), reinterpret_cast<uword>(old_value),
        reinterpret_cast<uword>(new_value)));
  }
};

}  // namespace dart

#if defined(HOST_OS_ANDROID)
#include "platform/atomic_android.h"
#elif defined(HOST_OS_FUCHSIA)
#include "platform/atomic_fuchsia.h"
#elif defined(HOST_OS_LINUX)
#include "platform/atomic_linux.h"
#elif defined(HOST_OS_MACOS)
#include "platform/atomic_macos.h"
#elif defined(HOST_OS_WINDOWS)
#include "platform/atomic_win.h"
#else
#error Unknown target os.
#endif

#endif  // RUNTIME_PLATFORM_ATOMIC_H_
