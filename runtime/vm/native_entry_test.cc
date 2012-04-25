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

namespace dart {

struct NativeTestEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} TestEntries[] = {
  REGISTER_NATIVE_ENTRY(TestSmiSub, 2)
  REGISTER_NATIVE_ENTRY(TestSmiSum, 6)
  REGISTER_NATIVE_ENTRY(TestStaticCallPatching, 0)
};


Dart_NativeFunction NativeTestEntry_Lookup(const String& name,
                                           int argument_count) {
  int num_entries = sizeof(TestEntries) / sizeof(struct NativeTestEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeTestEntries* entry = &(TestEntries[i]);
    if (name.Equals(entry->name_)) {
      if (entry->argument_count_ == argument_count) {
        return entry->function_;
      } else {
        // Wrong number of arguments.
        // TODO(regis): Should we pass a buffer for error reporting?
        return NULL;
      }
    }
  }
  return NULL;
}


// A native call for test purposes.
// Arg0: a smi.
// Arg1: a smi.
// Result: a smi representing arg0 - arg1.
DEFINE_NATIVE_ENTRY(TestSmiSub, 2) {
  const Smi& left = Smi::CheckedHandle(arguments->At(0));
  const Smi& right = Smi::CheckedHandle(arguments->At(1));
  // Ignoring overflow in the calculation below.
  intptr_t result = left.Value() - right.Value();
  arguments->SetReturn(Smi::Handle(Smi::New(result)));
}


// A native call for test purposes.
// Arg0-4: 5 smis.
// Result: a smi representing the sum of all arguments.
DEFINE_NATIVE_ENTRY(TestSmiSum, 5) {
  intptr_t result = 0;
  for (int i = 0; i < arguments->Count(); i++) {
    const Smi& arg = Smi::CheckedHandle(arguments->At(i));
    // Ignoring overflow in the addition below.
    result += arg.Value();
  }
  arguments->SetReturn(Smi::Handle(Smi::New(result)));
}


// Test code patching.
DEFINE_NATIVE_ENTRY(TestStaticCallPatching, 0) {
  uword target_address = 0;
  Function& target_function = Function::Handle();
  DartFrameIterator iterator;
  iterator.NextFrame();  // Skip native call.
  StackFrame* static_caller_frame = iterator.NextFrame();
  CodePatcher::GetStaticCallAt(static_caller_frame->pc(),
                               &target_function,
                               &target_address);
  EXPECT(String::Handle(target_function.name()).
      Equals(String::Handle(String::New("NativePatchStaticCall"))));
  const uword function_entry_address =
      Code::Handle(target_function.CurrentCode()).EntryPoint();
  EXPECT_EQ(function_entry_address, target_address);
}

}  // namespace dart
