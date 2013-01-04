// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Identical_comparison, 2) {
  GET_NATIVE_ARGUMENT(Instance, a, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, b, arguments->NativeArgAt(1));
  if (a.raw() == b.raw()) return Bool::True().raw();
  if (a.IsInteger() && b.IsInteger()) {
    return Bool::Get(a.Equals(b));
  }
  if (a.IsDouble() && b.IsDouble()) {
    if (a.Equals(b)) return Bool::True().raw();
    // Check for NaN.
    const Double& a_double = Double::Cast(a);
    const Double& b_double = Double::Cast(b);
    if (isnan(a_double.value()) && isnan(b_double.value())) {
      return Bool::True().raw();
    }
  }
  return Bool::False().raw();
}


}  // namespace dart
