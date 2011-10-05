// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(NotAny, assembler) {
  __ nop();
  __ ret();
}

ASSEMBLER_TEST_RUN(NotAny, entry) {
  ICLoadReceiver load(entry);
  EXPECT(!load.IsValid());
  JumpIfZero jump(entry);
  EXPECT(!jump.IsValid());
  CmpEaxWithImmediate cmp(entry);
  EXPECT(!cmp.IsValid());
  TestEaxIsSmi test(entry);
  EXPECT(!test.IsValid());
  ICCheckReceiverClass check_class(entry);
  EXPECT(!check_class.IsValid());
}


ASSEMBLER_TEST_GENERATE(ICLoadReceiver, assembler) {
  __ movl(EAX, FieldAddress(EDX, Array::data_offset()));
  __ movl(EAX, Address(ESP, EAX, TIMES_2, 0));
  __ ret();
}

ASSEMBLER_TEST_RUN(ICLoadReceiver, entry) {
  ICLoadReceiver load(entry);
  EXPECT(load.IsValid());
}


ASSEMBLER_TEST_GENERATE(JumpIfZero, assembler) {
  __ j(ZERO, &StubCode::MegamorphicLookupLabel());
  __ ret();
}

ASSEMBLER_TEST_RUN(JumpIfZero, entry) {
  JumpIfZero jump(entry);
  EXPECT(jump.IsValid());
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), jump.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(CmpEaxWithImmediate, assembler) {
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(EAX, raw_null);
  __ ret();
}

ASSEMBLER_TEST_RUN(CmpEaxWithImmediate, entry) {
  CmpEaxWithImmediate cmp(entry);
  EXPECT(cmp.IsValid());
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  EXPECT_EQ(raw_null.value(), cmp.immediate()->value());
}


ASSEMBLER_TEST_GENERATE(TestEaxIsSmi, assembler) {
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, &StubCode::MegamorphicLookupLabel());
  __ ret();
}

ASSEMBLER_TEST_RUN(TestEaxIsSmi, entry) {
  TestEaxIsSmi test(entry);
  EXPECT(test.IsValid());
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), test.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(ICCheckReceiverClass, assembler) {
  const Class& test_class =
      Class::ZoneHandle(Isolate::Current()->object_store()->double_class());
  __ CompareObject(EBX, test_class);
  __ j(ZERO, &StubCode::MegamorphicLookupLabel());
  __ ret();
}

ASSEMBLER_TEST_RUN(ICCheckReceiverClass, entry) {
  ICCheckReceiverClass class_check(entry);
  EXPECT(class_check.IsValid());
  EXPECT_EQ(Isolate::Current()->object_store()->double_class(),
            class_check.TestClass());
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(),
            class_check.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(LoadObjectClass, assembler) {
  __ movl(EBX, FieldAddress(EAX, Object::class_offset()));
  __ ret();
}

ASSEMBLER_TEST_RUN(LoadObjectClass, entry) {
  LoadObjectClass load(entry);
  EXPECT(load.IsValid());
}


ASSEMBLER_TEST_GENERATE(Call, assembler) {
  __ call(&StubCode::MegamorphicLookupLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Call, entry) {
  Call call(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  __ jmp(&StubCode::MegamorphicLookupLabel());
  __ jmp(&StubCode::CallInstanceFunctionLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Jump, entry) {
  Jump jump1(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(),
            jump1.TargetAddress());
  Jump jump2(entry + jump1.pattern_length_in_bytes());
  EXPECT_EQ(StubCode::CallInstanceFunctionLabel().address(),
            jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(StubCode::CallInstanceFunctionLabel().address(),
            jump1.TargetAddress());
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
