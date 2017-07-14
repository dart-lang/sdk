// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BOOLFIELD_H_
#define RUNTIME_VM_BOOLFIELD_H_

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

// BoolField is a template for encoding and decoding a bit inside an
// unsigned machine word.
template <int position>
class BoolField {
 public:
  // Returns a uword with the bool value encoded.
  static uword encode(bool value) {
    ASSERT(position < sizeof(uword));
    return static_cast<uword>((value ? 1U : 0) << position);
  }

  // Extracts the bool from the value.
  static bool decode(uword value) {
    ASSERT(position < sizeof(uword));
    return (value & (1U << position)) != 0;
  }

  // Returns a uword with the bool field value encoded based on the
  // original value. Only the single bit corresponding to this bool
  // field will be changed.
  static uword update(bool value, uword original) {
    ASSERT(position < sizeof(uword));
    const uword mask = 1U << position;
    return value ? original | mask : original & ~mask;
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_BOOLFIELD_H_
