// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/store_buffer.h"

#include "vm/assert.h"

namespace dart {

void StoreBufferBlock::ProcessBuffer() {
  // TODO(iposva): Do the right thing for store buffer overflow.
  top_ = 0;  // Currently just reset back to the beginning.
}

}  // namespace dart
