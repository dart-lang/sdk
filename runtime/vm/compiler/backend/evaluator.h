// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_EVALUATOR_H_
#define RUNTIME_VM_COMPILER_BACKEND_EVALUATOR_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/locations.h"

namespace dart {

// Namespace for static helper methods that evaluate constant expressions.
class Evaluator : public AllStatic {
 public:
  // Truncates the given int64 value based on the representation.
  static int64_t TruncateTo(int64_t v, Representation r);

  // Evaluates a binary integer operation and returns a pointer to a
  // canonicalized RawInteger.
  static IntegerPtr BinaryIntegerEvaluate(const Object& left,
                                          const Object& right,
                                          Token::Kind token_kind,
                                          bool is_truncating,
                                          Representation representation,
                                          Thread* thread);

  // Evaluates a unary integer operation and returns a pointer to a
  // canonicalized RawInteger.
  static IntegerPtr UnaryIntegerEvaluate(const Object& value,
                                         Token::Kind token_kind,
                                         Representation representation,
                                         Thread* thread);

  // Evaluates a binary double operation and returns the result.
  static double EvaluateDoubleOp(const double left,
                                 const double right,
                                 Token::Kind token_kind);

  // Returns whether the value is an int64, and returns the int64 value
  // through the result parameter.
  static bool ToIntegerConstant(Value* value, int64_t* result);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_EVALUATOR_H_
