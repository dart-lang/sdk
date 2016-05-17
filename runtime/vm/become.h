// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BECOME_H_
#define VM_BECOME_H_

#include "vm/allocation.h"

namespace dart {

class Array;

// TODO(johnmccutchan): Refactor this class so that it is not all static and
// provides utility methods for building the mapping of before and after.
class Become : public AllStatic {
 public:
  // Smalltalk's one-way bulk become (Array>>#elementsForwardIdentityTo:).
  // Redirects all pointers to elements of 'before' to the corresponding element
  // in 'after'. Every element in 'before' is guaranteed to be not reachable.
  // Useful for atomically applying behavior and schema changes.
  static void ElementsForwardIdentity(const Array& before, const Array& after);
};

}  // namespace dart

#endif  // VM_BECOME_H_
