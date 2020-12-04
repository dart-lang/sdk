// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_UNIT_TEST_CUSTOM_ZONE_H_
#define RUNTIME_VM_COMPILER_FFI_UNIT_TEST_CUSTOM_ZONE_H_

#include <vector>

// We use a custom zone here which doesn't depend on VM internals (e.g. handles,
// thread, ...)
#if defined(RUNTIME_VM_ZONE_H_)
#error "We want our own zone implementation"
#endif
#define RUNTIME_VM_ZONE_H_

namespace dart {

class Zone {
 public:
  Zone() {}
  ~Zone();

  template <class ElementType>
  inline ElementType* Alloc(intptr_t length) {
    return static_cast<ElementType*>(AllocUnsafe(sizeof(ElementType) * length));
  }

  template <class ElementType>
  inline ElementType* Realloc(ElementType* old_array,
                              intptr_t old_length,
                              intptr_t new_length) {
    void* memory = AllocUnsafe(sizeof(ElementType) * new_length);
    memmove(memory, old_array, sizeof(ElementType) * old_length);
    return static_cast<ElementType*>(memory);
  }

  template <class ElementType>
  void Free(ElementType* old_array, intptr_t len) {}

  void* AllocUnsafe(intptr_t size);

 private:
  Zone(const Zone&) = delete;
  void operator=(const Zone&) = delete;
  std::vector<void*> buffers_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_UNIT_TEST_CUSTOM_ZONE_H_
