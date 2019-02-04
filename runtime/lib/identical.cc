// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Identical_comparison, 0, 2) {
  GET_NATIVE_ARGUMENT(Instance, a, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, b, arguments->NativeArgAt(1));
  const bool is_identical = a.IsIdenticalTo(b);
  return Bool::Get(is_identical).raw();
}

}  // namespace dart
