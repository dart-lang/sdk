// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_arguments.h"

#include "platform/assert.h"
#include "vm/object.h"

namespace dart {

void NativeArguments::SetReturn(const Object& value) const {
  *retval_ = value.raw();
}

void NativeArguments::SetReturnUnsafe(RawObject* value) const {
  *retval_ = value;
}

}  // namespace dart
