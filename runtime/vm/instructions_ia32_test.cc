// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  StubCode* stub_code = Isolate::Current()->stub_code();
  __ call(&stub_code->InvokeDartCodeLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Call, test) {
  StubCode* stub_code = Isolate::Current()->stub_code();
  CallPattern call(test->entry());
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  StubCode* stub_code = Isolate::Current()->stub_code();
  __ jmp(&stub_code->InvokeDartCodeLabel());
  const Code& array_stub = Code::Handle(stub_code->GetAllocateArrayStub());
  const ExternalLabel array_label(array_stub.EntryPoint());
  __ jmp(&array_label);
  __ ret();
}


ASSEMBLER_TEST_RUN(Jump, test) {
  const Code& code = test->code();
  const Instructions& instrs = Instructions::Handle(code.instructions());
  StubCode* stub_code = Isolate::Current()->stub_code();
  bool status =
      VirtualMemory::Protect(reinterpret_cast<void*>(instrs.EntryPoint()),
                             instrs.size(),
                             VirtualMemory::kReadWrite);
  EXPECT(status);
  JumpPattern jump1(test->entry(), test->code());
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            jump1.TargetAddress());
  JumpPattern jump2(test->entry() + jump1.pattern_length_in_bytes(),
                    test->code());
  const Code& array_stub = Code::Handle(stub_code->GetAllocateArrayStub());
  EXPECT_EQ(array_stub.EntryPoint(),
            jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(array_stub.EntryPoint(),
            jump1.TargetAddress());
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
