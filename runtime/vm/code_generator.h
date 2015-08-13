// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_H_
#define VM_CODE_GENERATOR_H_

#include "vm/globals.h"
#include "vm/runtime_entry.h"

namespace dart {

class Array;
template <typename T> class GrowableArray;
class ICData;
class Instance;

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(const Code& optimized_code, uword pc);
void DeoptimizeFunctionsOnStack();

double DartModulo(double a, double b);
void SinCos(double arg, double* sin_res, double* cos_res);

}  // namespace dart

#endif  // VM_CODE_GENERATOR_H_
