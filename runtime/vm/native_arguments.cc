// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_arguments.h"

#include "vm/assert.h"
#include "vm/object.h"

namespace dart {

void NativeArguments::SetReturn(const Object& value) const {
  *retval_ = value.raw();
}

}  // namespace dart
