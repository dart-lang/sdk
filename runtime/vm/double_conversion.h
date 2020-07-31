// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DOUBLE_CONVERSION_H_
#define RUNTIME_VM_DOUBLE_CONVERSION_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

struct DoubleToStringConstants : AllStatic {
  static char const kExponentChar;
  static const char* const kInfinitySymbol;
  static const char* const kNaNSymbol;
};

void DoubleToCString(double d, char* buffer, int buffer_size);
StringPtr DoubleToStringAsFixed(double d, int fraction_digits);
StringPtr DoubleToStringAsExponential(double d, int fraction_digits);
StringPtr DoubleToStringAsPrecision(double d, int precision);

bool CStringToDouble(const char* str, intptr_t length, double* result);

}  // namespace dart

#endif  // RUNTIME_VM_DOUBLE_CONVERSION_H_
