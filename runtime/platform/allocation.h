// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_ALLOCATION_H_
#define RUNTIME_PLATFORM_ALLOCATION_H_

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

}  // namespace dart

#endif  // RUNTIME_PLATFORM_ALLOCATION_H_
