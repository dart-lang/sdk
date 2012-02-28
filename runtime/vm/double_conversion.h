// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DOUBLE_CONVERSION_H_
#define VM_DOUBLE_CONVERSION_H_

#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

void DoubleToCString(double d, char* buffer, int buffer_size);
RawString* DoubleToStringAsFixed(double d, int fraction_digits);
RawString* DoubleToStringAsExponential(double d, int fraction_digits);
RawString* DoubleToStringAsPrecision(double d, int precision);

}  // namespace dart

#endif  // VM_DOUBLE_CONVERSION_H_
