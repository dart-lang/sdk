// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry_test.h"

#include "vm/assembler.h"
#include "vm/code_patcher.h"
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
  Dart_EnterScope();
  Dart_Handle left = Dart_GetNativeArgument(args, 0);
  Dart_Handle right = Dart_GetNativeArgument(args, 1);
  int64_t left_value = -1;
  int64_t right_value = -1;
  EXPECT_VALID(Dart_IntegerToInt64(left, &left_value));
  EXPECT_VALID(Dart_IntegerToInt64(right, &right_value));

  // Ignoring overflow in the calculation below.
  int64_t result = left_value - right_value;
  Dart_SetReturnValue(args, Dart_NewInteger(result));
  Dart_ExitScope();
}


// A native call for test purposes.
// Arg0-4: 5 smis.
// Result: a smi representing the sum of all arguments.
void TestSmiSum(Dart_NativeArguments args) {
  Dart_EnterScope();
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
  Dart_ExitScope();
}


// Test code patching.
void TestStaticCallPatching(Dart_NativeArguments args) {
  Dart_EnterScope();
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  StackFrame* static_caller_frame = iterator.NextFrame();
  uword target_address =
      CodePatcher::GetStaticCallTargetAt(static_caller_frame->pc());
  const Code& code = Code::Handle(static_caller_frame->LookupDartCode());
  const Function& target_function =
      Function::Handle(code.GetStaticCallTargetFunctionAt(
          static_caller_frame->pc()));
  EXPECT(String::Handle(target_function.name()).
      Equals(String::Handle(String::New("NativePatchStaticCall"))));
  const uword function_entry_address =
      Code::Handle(target_function.CurrentCode()).EntryPoint();
  EXPECT_EQ(function_entry_address, target_address);
  Dart_ExitScope();
}

}  // namespace dart
