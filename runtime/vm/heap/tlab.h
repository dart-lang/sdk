// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_TLAB_H_
#define RUNTIME_VM_HEAP_TLAB_H_

#include "platform/assert.h"
#include "platform/globals.h"

namespace dart {

struct TLAB {
  TLAB() : top(0), end(0) {}
  TLAB(uword top, uword end) : top(top), end(end) {}
  TLAB(const TLAB& other) : top(other.top), end(other.end) {}
  TLAB& operator=(const TLAB& other) {
    top = other.top;
    end = other.end;
    return *this;
  }

  intptr_t RemainingSize() const { return end - top; }
  bool IsAbandoned() const { return top == 0 && end == 0; }

  TLAB BumpAllocate(intptr_t size) const {
    ASSERT(RemainingSize() >= size);
    return TLAB(top + size, end);
  }

  uword top;
  uword end;
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_TLAB_H_
