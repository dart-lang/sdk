// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dispatch_table.h"

#include "platform/assert.h"

namespace dart {

const uword* DispatchTable::ArrayOrigin() const {
  return &array_.get()[kOriginElement];
}

}  // namespace dart
