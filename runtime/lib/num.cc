// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Num_toString, 1) {
  const Number& number = Number::CheckedHandle(arguments->NativeArgAt(0));
  return number.ToString(Heap::kNew);
}

}  // namespace dart
