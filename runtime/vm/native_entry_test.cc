// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry_test.h"

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/dart_api_impl.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

// A native call for test purposes.
// Arg0: a smi.
// Arg1: a smi.
// Result: a smi representing arg0 - arg1.
void TestSmiSub(Dart_NativeArguments args) {
  Dart_Handle left = Dart_GetNativeArgument(args, 0);
  Dart_Handle right = Dart_GetNativeArgument(args, 1);
  int64_t left_value = -1;
  int64_t right_value = -1;
  EXPECT_VALID(Dart_IntegerToInt64(left, &left_value));
  EXPECT_VALID(Dart_IntegerToInt64(right, &right_value));

  // Ignoring overflow in the calculation below.
  int64_t result = left_value - right_value;
  Dart_SetReturnValue(args, Dart_NewInteger(result));
}

// A native call for test purposes.
// Arg0-4: 5 smis.
// Result: a smi representing the sum of all arguments.
void TestSmiSum(Dart_NativeArguments args) {
  int64_t result = 0;
  int arg_count = Dart_GetNativeArgumentCount(args);
  for (int i = 0; i < arg_count; i++) {
    Dart_Handle arg = Dart_GetNativeArgument(args, i);
    int64_t arg_value = -1;
    EXPECT_VALID(Dart_IntegerToInt64(arg, &arg_value));

    // Ignoring overflow in the addition below.
    result += arg_value;
  }
  Dart_SetReturnValue(args, Dart_NewInteger(result));
}

// Test for accepting null arguments in native function.
// Arg0-4: 5 smis or null.
// Result: a smi representing the sum of all non-null arguments.
void TestNonNullSmiSum(Dart_NativeArguments args) {
  int64_t result = 0;
  int arg_count = Dart_GetNativeArgumentCount(args);
  // Test the lower level macro GET_NATIVE_ARGUMENT.
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Zone* zone = Thread::Current()->zone();  // Used by GET_NATIVE_ARGUMENT.
  for (int i = 0; i < arg_count; i++) {
    Dart_Handle arg = Dart_GetNativeArgument(args, i);
    GET_NATIVE_ARGUMENT(Integer, argument, arguments->NativeArgAt(i));
    EXPECT(argument.IsInteger());                       // May be null.
    EXPECT_EQ(Api::UnwrapHandle(arg), argument.raw());  // May be null.
    int64_t arg_value = -1;
    if (argument.IsNull()) {
      EXPECT_ERROR(Dart_IntegerToInt64(arg, &arg_value),
                   "Dart_IntegerToInt64 expects argument 'integer' "
                   "to be non-null.");
    } else {
      EXPECT_VALID(Dart_IntegerToInt64(arg, &arg_value));
      EXPECT_EQ(arg_value, argument.AsInt64Value());
      // Ignoring overflow in the addition below.
      result += arg_value;
    }
  }
  Dart_SetReturnValue(args, Dart_NewInteger(result));
}

}  // namespace dart
