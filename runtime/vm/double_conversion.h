// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DOUBLE_CONVERSION_H_
#define VM_DOUBLE_CONVERSION_H_

#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

bool DoubleToString(double d, String& result);
bool DoubleToStringAsFixed(double d, int fraction_digits, String& result);
bool DoubleToStringAsExponential(double d, int fraction_digits, String& result);
bool DoubleToStringAsPrecision(double d, int precision, String& result);

}  // namespace dart

#endif  // VM_DOUBLE_CONVERSION_H_
