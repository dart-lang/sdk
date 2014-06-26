// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"
#include "vm/report.h"

namespace dart {

DECLARE_FLAG(bool, warn_on_javascript_compatibility);

DEFINE_NATIVE_ENTRY(Identical_comparison, 2) {
  GET_NATIVE_ARGUMENT(Instance, a, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, b, arguments->NativeArgAt(1));
  const bool is_identical = a.IsIdenticalTo(b);
  if (FLAG_warn_on_javascript_compatibility) {
    if (!is_identical) {
      if (a.IsString()) {
        if (String::Cast(a).Equals(b)) {
          Report::JSWarningFromNative(
              true,  // Identical_comparison is static.
              "strings that are equal are also identical");
        }
      } else if (a.IsInteger()) {
        if (b.IsDouble()) {
          const int64_t a_value = Integer::Cast(a).AsInt64Value();
          const double b_value = Double::Cast(b).value();
          if (a_value == floor(b_value)) {
            Report::JSWarningFromNative(
                true,  // Identical_comparison is static.
                "integer value and integral double value that are equal "
                "are also identical");
          }
        }
      } else if (a.IsDouble()) {
        if (b.IsInteger()) {
          const double a_value = Double::Cast(a).value();
          const int64_t b_value = Integer::Cast(b).AsInt64Value();
          if (floor(a_value) == b_value) {
            Report::JSWarningFromNative(
                true,  // Identical_comparison is static.
                "integral double value and integer value that are equal "
                "are also identical");
          }
        }
      }
    }
  }
  return Bool::Get(is_identical).raw();
}

}  // namespace dart
