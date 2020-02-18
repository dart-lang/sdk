// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_BASE_H_
#define RUNTIME_VM_CONSTANTS_BASE_H_

namespace dart {

// Alignment strategies for how to align values.
enum AlignmentStrategy {
  // Align to the size of the value.
  kAlignedToValueSize,
  // Align to the size of the value, but align 8 byte-sized values to 4 bytes.
  // Both double and int64.
  kAlignedToValueSizeBut8AlignedTo4,
  // Align to the architecture size.
  kAlignedToWordSize,
  // Align to the architecture size, but align 8 byte-sized values to 8 bytes.
  // Both double and int64.
  kAlignedToWordSizeBut8AlignedTo8,
};

// Minimum size strategies for how to store values.
enum ExtensionStrategy {
  // Values can have arbitrary small size with the upper bits undefined.
  kNotExtended,
  // Values smaller than 4 bytes are passed around zero- or signextended to
  // 4 bytes.
  kExtendedTo4,
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_BASE_H_
