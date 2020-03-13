// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DISPATCH_TABLE_H_
#define RUNTIME_VM_DISPATCH_TABLE_H_

#include <memory>

#include "vm/globals.h"

namespace dart {

class DispatchTable {
 public:
  explicit DispatchTable(intptr_t length)
      : length_(length), array_(new uword[length]()) {}

  intptr_t length() const { return length_; }

  // The element of the dispatch table array to which the dispatch table
  // register points.
  static intptr_t OriginElement();
  static intptr_t LargestSmallOffset();
  // Dispatch table array pointer to put into the dispatch table register.
  const uword* ArrayOrigin() const;

 private:
  uword* array() { return array_.get(); }

  intptr_t length_;
  std::unique_ptr<uword[]> array_;

  friend class Deserializer;  // For non-const array().
  DISALLOW_COPY_AND_ASSIGN(DispatchTable);
};

}  // namespace dart

#endif  // RUNTIME_VM_DISPATCH_TABLE_H_
