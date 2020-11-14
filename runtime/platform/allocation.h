// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ALLOCATION_H_
#define RUNTIME_PLATFORM_ALLOCATION_H_

#include "platform/address_sanitizer.h"
#include "platform/assert.h"

namespace dart {

// Stack allocated objects subclass from this base class. Objects of this type
// cannot be allocated on either the C or object heaps. Destructors for objects
// of this type will not be run unless the stack is unwound through normal
// program control flow.
class ValueObject {
 public:
  ValueObject() {}
  ~ValueObject() {}

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ValueObject);
};

// Static allocated classes only contain static members and can never
// be instantiated in the heap or on the stack.
class AllStatic {
 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(AllStatic);
};

class MallocAllocated {
 public:
  MallocAllocated() {}

  // Intercept operator new to produce clearer error messages when we run out
  // of memory. Don't do this when running under ASAN so it can continue to
  // check malloc/new/new[] are paired with free/delete/delete[] respectively.
#if !defined(USING_ADDRESS_SANITIZER)
  void* operator new(size_t size) {
    void* result = ::malloc(size);
    if (result == nullptr) {
      OUT_OF_MEMORY();
    }
    return result;
  }

  void* operator new[](size_t size) {
    void* result = ::malloc(size);
    if (result == nullptr) {
      OUT_OF_MEMORY();
    }
    return result;
  }

  void operator delete(void* pointer) { ::free(pointer); }

  void operator delete[](void* pointer) { ::free(pointer); }
#endif
};

void* malloc(size_t size);
void* realloc(void* ptr, size_t size);

}  // namespace dart

#endif  // RUNTIME_PLATFORM_ALLOCATION_H_
