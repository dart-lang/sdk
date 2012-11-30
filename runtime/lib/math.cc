// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <ctype.h>  // isspace.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/scanner.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Math_sqrt, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sqrt(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_sin, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_cos, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(cos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_tan, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(tan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_asin, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(asin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_acos, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(acos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(atan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan2, 2) {
  GET_NATIVE_ARGUMENT(Double, operand1, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Double, operand2, arguments->NativeArgAt(1));
  return Double::New(atan2_ieee(operand1.value(), operand2.value()));
}

DEFINE_NATIVE_ENTRY(Math_exp, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(exp(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_log, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(log(operand.value()));
}

}  // namespace dart
