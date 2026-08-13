// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/assembler_test.h"
#include "vm/globals.h"
#include "vm/hash.h"
#include "vm/os.h"
#include "vm/random.h"
#include "vm/simulator.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

namespace compiler {
ASSEMBLER_TEST_EXTERN(StoreIntoObject);
}  // namespace compiler

ASSEMBLER_TEST_RUN(StoreIntoObject, test) {
#define TEST_CODE(value, growable_array, thread)                               \
  test->Invoke<void, ObjectPtr, ObjectPtr, Thread*>(value, growable_array,     \
                                                    thread)

  const Array& old_array = Array::Handle(Array::New(3, Heap::kOld));
  const Array& new_array = Array::Handle(Array::New(3, Heap::kNew));
  const GrowableObjectArray& grow_old_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kOld));
  const GrowableObjectArray& grow_new_array = GrowableObjectArray::Handle(
      GrowableObjectArray::New(old_array, Heap::kNew));
  Smi& smi = Smi::Handle();
  Thread* thread = Thread::Current();

  EXPECT(old_array.ptr() == grow_old_array.data());
  EXPECT(!thread->StoreBufferContains(grow_old_array.ptr()));
  EXPECT(old_array.ptr() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.ptr()));

  // Store Smis into the old object.
  for (int i = -128; i < 128; i++) {
    smi = Smi::New(i);
    TEST_CODE(smi.ptr(), grow_old_array.ptr(), thread);
    EXPECT(static_cast<CompressedObjectPtr>(smi.ptr()) ==
           static_cast<CompressedObjectPtr>(grow_old_array.data()));
    EXPECT(!thread->StoreBufferContains(grow_old_array.ptr()));
  }

  // Store an old object into the old object.
  TEST_CODE(old_array.ptr(), grow_old_array.ptr(), thread);
  EXPECT(old_array.ptr() == grow_old_array.data());
  EXPECT(!thread->StoreBufferContains(grow_old_array.ptr()));

  // Store a new object into the old object.
  TEST_CODE(new_array.ptr(), grow_old_array.ptr(), thread);
  EXPECT(new_array.ptr() == grow_old_array.data());
  EXPECT(thread->StoreBufferContains(grow_old_array.ptr()));

  // Store a new object into the new object.
  TEST_CODE(new_array.ptr(), grow_new_array.ptr(), thread);
  EXPECT(new_array.ptr() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.ptr()));

  // Store an old object into the new object.
  TEST_CODE(old_array.ptr(), grow_new_array.ptr(), thread);
  EXPECT(old_array.ptr() == grow_new_array.data());
  EXPECT(!thread->StoreBufferContains(grow_new_array.ptr()));
}

namespace compiler {
#define __ assembler->

ASSEMBLER_TEST_GENERATE(InstantiateTypeArgumentsHashKeys, assembler) {
#if defined(TARGET_ARCH_IA32)
  const Register kArg1Reg = EAX;
  const Register kArg2Reg = ECX;
  __ movl(kArg1Reg, Address(ESP, 2 * target::kWordSize));
  __ movl(kArg2Reg, Address(ESP, 1 * target::kWordSize));
#else
  const Register kArg1Reg = CallingConventions::ArgumentRegisters[0];
  const Register kArg2Reg = CallingConventions::ArgumentRegisters[1];
#endif
  __ CombineHashes(kArg1Reg, kArg2Reg);
  __ FinalizeHash(kArg1Reg, kArg2Reg);
  __ MoveRegister(CallingConventions::kReturnReg, kArg1Reg);
  __ Ret();
}

#undef __
}  // namespace compiler

ASSEMBLER_TEST_RUN(InstantiateTypeArgumentsHashKeys, test) {
  typedef uint32_t (*HashKeysCode)(uword hash, uword other) DART_UNUSED;

  auto hash_test = [&](const Expect& expect, uword hash1, uword hash2) {
    const uint32_t expected = FinalizeHash(CombineHashes(hash1, hash2));
    const uint32_t got = EXECUTE_TEST_CODE_UWORD_UWORD_UINT32(
        HashKeysCode, test->entry(), hash1, hash2);
    if (got == expected) return;
    TextBuffer buffer(128);
    buffer.Printf("For hash1 = %" Pu " and hash2 = %" Pu
                  ": expected result %u, got result %u",
                  hash1, hash2, expected, got);
    expect.Fail("%s", buffer.buffer());
  };

#define HASH_TEST(hash1, hash2)                                                \
  hash_test(Expect(__FILE__, __LINE__), hash1, hash2)

  const intptr_t kNumRandomTests = 500;
  Random random;

  // First, fixed and random 32 bit tests for all architectures.
  HASH_TEST(1, 1);
  HASH_TEST(10, 20);
  HASH_TEST(20, 10);
  HASH_TEST(kMaxUint16, kMaxUint32 - kMaxUint16);
  HASH_TEST(kMaxUint32 - kMaxUint16, kMaxUint16);

  for (intptr_t i = 0; i < kNumRandomTests; i++) {
    const uword hash1 = random.NextUInt32();
    const uword hash2 = random.NextUInt32();
    HASH_TEST(hash1, hash2);
  }

#if defined(TARGET_ARCH_IS_64_BIT)
  // Now 64-bit tests on 64-bit architectures.
  HASH_TEST(kMaxUint16, kMaxUint64 - kMaxUint16);
  HASH_TEST(kMaxUint64 - kMaxUint16, kMaxUint16);

  for (intptr_t i = 0; i < kNumRandomTests; i++) {
    const uword hash1 = random.NextUInt64();
    const uword hash2 = random.NextUInt64();
    HASH_TEST(hash1, hash2);
  }
#endif
#undef HASH_TEST
}

#define __ assembler->

#if defined(TARGET_ARCH_IA32)
const Register kArg1Reg = EAX;
const Register kArg2Reg = ECX;
#else
const Register kArg1Reg = CallingConventions::ArgumentRegisters[0];
const Register kArg2Reg = CallingConventions::ArgumentRegisters[1];
#endif

#define LOAD_FROM_BOX_TEST(SIZE, TYPE, VALUE, SAME_REGISTER)                   \
  ASSEMBLER_TEST_GENERATE(Load##SIZE##FromBoxOrSmi##VALUE##SAME_REGISTER,      \
                          assembler) {                                         \
    const bool same_register = SAME_REGISTER;                                  \
                                                                               \
    const Register src = kArg1Reg;                                             \
    const Register dst = same_register ? src : kArg2Reg;                       \
    const TYPE value = VALUE;                                                  \
                                                                               \
    EnterTestFrame(assembler);                                                 \
                                                                               \
    __ LoadObject(src, Integer::ZoneHandle(Integer::New(value, Heap::kOld)));  \
    __ Load##SIZE##FromBoxOrSmi(dst, src);                                     \
    __ MoveRegister(CallingConventions::kReturnReg, dst);                      \
                                                                               \
    LeaveTestFrame(assembler);                                                 \
                                                                               \
    __ Ret();                                                                  \
  }                                                                            \
                                                                               \
  ASSEMBLER_TEST_RUN(Load##SIZE##FromBoxOrSmi##VALUE##SAME_REGISTER, test) {   \
    const int64_t res = test->InvokeWithCodeAndThread<int64_t>();              \
    EXPECT_EQ(static_cast<TYPE>(VALUE), static_cast<TYPE>(res));               \
  }

LOAD_FROM_BOX_TEST(Word, intptr_t, 0, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0, false)
LOAD_FROM_BOX_TEST(Word, intptr_t, 1, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 1, false)
#if defined(TARGET_ARCH_IS_32_BIT)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x7FFFFFFF, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x7FFFFFFF, false)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x80000000, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x80000000, false)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0xFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0xFFFFFFFF, false)
#else
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x7FFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x7FFFFFFFFFFFFFFF, false)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x8000000000000000, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0x8000000000000000, false)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0xFFFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Word, intptr_t, 0xFFFFFFFFFFFFFFFF, false)
#endif

LOAD_FROM_BOX_TEST(Int32, int32_t, 0, true)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0, false)
LOAD_FROM_BOX_TEST(Int32, int32_t, 1, true)
LOAD_FROM_BOX_TEST(Int32, int32_t, 1, false)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0x7FFFFFFF, true)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0x7FFFFFFF, false)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0x80000000, true)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0x80000000, false)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0xFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Int32, int32_t, 0xFFFFFFFF, false)

#if !defined(TARGET_ARCH_IS_32_BIT)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0, true)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0, false)
LOAD_FROM_BOX_TEST(Int64, int64_t, 1, true)
LOAD_FROM_BOX_TEST(Int64, int64_t, 1, false)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0x7FFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0x7FFFFFFFFFFFFFFF, false)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0x8000000000000000, true)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0x8000000000000000, false)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0xFFFFFFFFFFFFFFFF, true)
LOAD_FROM_BOX_TEST(Int64, int64_t, 0xFFFFFFFFFFFFFFFF, false)
#endif

#if defined(TARGET_ARCH_ARM)
ISOLATE_UNIT_TEST_CASE(Assembler_Regress54621) {
  auto zone = thread->zone();
  const classid_t cid = kTypedDataInt32ArrayCid;
  const intptr_t index_scale = 1;
  const intptr_t kMaxAllowedOffsetForExternal = (2 << 11) - 1;
  auto& smi = Smi::Handle(zone, Smi::New(kMaxAllowedOffsetForExternal));
  bool needs_base;
  EXPECT(compiler::Assembler::AddressCanHoldConstantIndex(
      smi, /*is_load=*/true,
      /*is_external=*/true, cid, index_scale, &needs_base));
  EXPECT(!needs_base);
  EXPECT(compiler::Assembler::AddressCanHoldConstantIndex(
      smi, /*is_load=*/true,
      /*is_external=*/false, cid, index_scale, &needs_base));
  EXPECT(needs_base);
  // Double-checking we're on a boundary of what's allowed.
  smi = Smi::New(kMaxAllowedOffsetForExternal + 1);
  EXPECT(!compiler::Assembler::AddressCanHoldConstantIndex(
      smi, /*is_load=*/true,
      /*is_external=*/false, cid, index_scale));
  EXPECT(!compiler::Assembler::AddressCanHoldConstantIndex(
      smi, /*is_load=*/true,
      /*is_external=*/true, cid, index_scale));
}
#endif

namespace compiler {

intptr_t RegRegImmTests::ExtendValue(intptr_t value, OperandSize sz) {
  switch (sz) {
#if defined(TARGET_ARCH_IS_64_BIT)
    case kEightBytes:
      return value;  // We only simulate 64-bit architectures on 64-bit.
#endif
    case kFourBytes:
      return static_cast<int32_t>(value);
    case kUnsignedFourBytes:
      return static_cast<uint32_t>(value);
    default:
      break;
  }
  UNREACHABLE();
  return value;
}

intptr_t RegRegImmTests::ZeroExtendValue(intptr_t value, OperandSize sz) {
  if (!Assembler::NeedsSignExtension(sz)) return ExtendValue(value, sz);
  switch (sz) {
    case kFourBytes:
      return ExtendValue(value, kUnsignedFourBytes);
    default:
      break;
  }
  UNREACHABLE();
  return value;
}

intptr_t RegRegImmTests::SignExtendValue(intptr_t value, OperandSize sz) {
  if (Assembler::IsSignedOperand(sz)) return ExtendValue(value, sz);
  switch (sz) {
    case kUnsignedFourBytes:
      return ExtendValue(value, kFourBytes);
    default:
      break;
  }
  UNREACHABLE();
  return value;
}

void CheckRegRegImmOperation(
    Expect& expect,
    AssemblerTest* test,
    intptr_t rhs,
    OperandSize sz,
    const std::function<intptr_t(intptr_t, intptr_t, OperandSize)>& f) {
  RELEASE_ASSERT(Assembler::OperandSizeInBits(sz) <= target::kBitsPerWord);
  for (size_t i = 0; i < ARRAY_SIZE(kRegRegImmInputs); ++i) {
    auto const input = kRegRegImmInputs[i];
    intptr_t expected = f(input, rhs, sz);
    intptr_t got = test->Invoke<intptr_t, intptr_t>(input);
#if defined(TARGET_ARCH_IS_32_BIT)
    // In case the test is running on a 64-bit simulator, use static casts to
    // uint32_t (which has the benefit of only printing the lower 32 bits
    // for failures).
    expected = static_cast<uint32_t>(expected);
    got = static_cast<uint32_t>(got);
#endif
    if (expected != got) {
      expect.Fail("For input %#" Px ": expected %#" Px ", got %#" Px "\n",
                  input, expected, got);
    }
  }
  if (expect.failed()) {
    OS::PrintErr("Generated assembly:\n%s\n", test->RelativeDisassembly());
  }
}

#if defined(TARGET_ARCH_IA32)
const Register RegRegImmTests::kInputReg = kNoRegister;
#else
const Register RegRegImmTests::kInputReg =
    CallingConventions::ArgumentRegisters[0];
#endif
const Register RegRegImmTests::kReturnReg = CallingConventions::kReturnReg;

#if TARGET_ARCH_IS_32_BIT
#define FOR_EACH_RHS_AND_SIZE(V)                                               \
  V(0, kFourBytes)                                                             \
  V(0, kUnsignedFourBytes)                                                     \
  V(1, kFourBytes)                                                             \
  V(1, kUnsignedFourBytes)                                                     \
  V(0x2E, kFourBytes)                                                          \
  V(0x2E, kUnsignedFourBytes)                                                  \
  V(kMaxUint8, kFourBytes)                                                     \
  V(kMaxUint8, kUnsignedFourBytes)                                             \
  V(0x2E4F, kFourBytes)                                                        \
  V(0x2E4F, kUnsignedFourBytes)                                                \
  V(kMaxUint16, kFourBytes)                                                    \
  V(kMaxUint16, kUnsignedFourBytes)                                            \
  V(0x2E4F5B3C, kFourBytes)                                                    \
  V(0x2E4F5B3C, kUnsignedFourBytes)                                            \
  V(kMaxUint32, kFourBytes)                                                    \
  V(kMaxUint32, kUnsignedFourBytes)
#else
#define FOR_EACH_RHS_AND_SIZE(V)                                               \
  V(0, kFourBytes)                                                             \
  V(0, kUnsignedFourBytes)                                                     \
  V(0, kEightBytes)                                                            \
  V(1, kFourBytes)                                                             \
  V(1, kUnsignedFourBytes)                                                     \
  V(1, kEightBytes)                                                            \
  V(0x2E, kFourBytes)                                                          \
  V(0x2E, kUnsignedFourBytes)                                                  \
  V(0x2E, kEightBytes)                                                         \
  V(kMaxUint8, kFourBytes)                                                     \
  V(kMaxUint8, kUnsignedFourBytes)                                             \
  V(kMaxUint8, kEightBytes)                                                    \
  V(0x2E4F, kFourBytes)                                                        \
  V(0x2E4F, kUnsignedFourBytes)                                                \
  V(0x2E4F, kEightBytes)                                                       \
  V(kMaxUint16, kFourBytes)                                                    \
  V(kMaxUint16, kUnsignedFourBytes)                                            \
  V(kMaxUint16, kEightBytes)                                                   \
  V(0x2E4F5B3C, kFourBytes)                                                    \
  V(0x2E4F5B3C, kUnsignedFourBytes)                                            \
  V(0x2E4F5B3C, kEightBytes)                                                   \
  V(kMaxUint32, kFourBytes)                                                    \
  V(kMaxUint32, kUnsignedFourBytes)                                            \
  V(kMaxUint32, kEightBytes)                                                   \
  V(0x2E4F5B3C9D8716A0, kEightBytes)                                           \
  V(kMaxUint64, kFourBytes)                                                    \
  V(kMaxUint64, kUnsignedFourBytes)                                            \
  V(kMaxUint64, kEightBytes)
#endif

#if defined(TARGET_ARCH_IA32)
#define AND_ASSEMBLER_TEST_GENERATE(rhs, sz)                                   \
  ASSEMBLER_TEST_GENERATE(AndImmediate_X_##rhs##_##sz, assembler) {            \
    __ movl(RegRegImmTests::kReturnReg, Address(ESP, 4));                      \
    __ AndImmediate(RegRegImmTests::kReturnReg, RegRegImmTests::kReturnReg,    \
                    rhs, sz);                                                  \
    __ Ret();                                                                  \
  }
#else
#define AND_ASSEMBLER_TEST_GENERATE(rhs, sz)                                   \
  ASSEMBLER_TEST_GENERATE(AndImmediate_X_##rhs##_##sz, assembler) {            \
    __ AndImmediate(RegRegImmTests::kReturnReg, RegRegImmTests::kInputReg,     \
                    rhs, sz);                                                  \
    __ Ret();                                                                  \
  }
#endif

intptr_t RegRegImmTests::And(intptr_t value, intptr_t rhs, OperandSize sz) {
  // On all architectures, the result is zero-extended for non-word-sized sz.
  return ZeroExtendValue(value & rhs, sz);
}

#define AND_ASSEMBLER_TEST_RUN(rhs, sz)                                        \
  ASSEMBLER_TEST_RUN(AndImmediate_X_##rhs##_##sz, test) {                      \
    dart::Expect expect(__FILE__, __LINE__);                                   \
    CheckRegRegImmOperation(expect, test, rhs, sz, RegRegImmTests::And);       \
  }

FOR_EACH_RHS_AND_SIZE(AND_ASSEMBLER_TEST_GENERATE)
FOR_EACH_RHS_AND_SIZE(AND_ASSEMBLER_TEST_RUN)

#undef AND_ASSEMBLER_TEST_RUN
#undef AND_ASSEMBLER_TEST_GENERATE
#undef FOR_EACH_RHS_AND_SIZE

#if TARGET_ARCH_IS_32_BIT
#define FOR_EACH_SHIFT_AND_SIGNED_SIZE(V)                                      \
  V(0, kFourBytes)                                                             \
  V(1, kFourBytes)                                                             \
  V(7, kFourBytes)                                                             \
  V(15, kFourBytes)                                                            \
  V(16, kFourBytes)                                                            \
  V(25, kFourBytes)                                                            \
  V(31, kFourBytes)
#else
#define FOR_EACH_SHIFT_AND_SIGNED_SIZE(V)                                      \
  V(0, kFourBytes)                                                             \
  V(0, kEightBytes)                                                            \
  V(1, kFourBytes)                                                             \
  V(1, kEightBytes)                                                            \
  V(7, kFourBytes)                                                             \
  V(7, kEightBytes)                                                            \
  V(15, kFourBytes)                                                            \
  V(15, kEightBytes)                                                           \
  V(16, kFourBytes)                                                            \
  V(16, kEightBytes)                                                           \
  V(25, kFourBytes)                                                            \
  V(25, kEightBytes)                                                           \
  V(31, kFourBytes)                                                            \
  V(31, kEightBytes)                                                           \
  V(52, kEightBytes)                                                           \
  V(63, kEightBytes)
#endif

#if TARGET_ARCH_IS_32_BIT
#define FOR_EACH_SHIFT_AND_UNSIGNED_SIZE(V)                                    \
  V(0, kUnsignedFourBytes)                                                     \
  V(1, kUnsignedFourBytes)                                                     \
  V(7, kUnsignedFourBytes)                                                     \
  V(15, kUnsignedFourBytes)                                                    \
  V(16, kUnsignedFourBytes)                                                    \
  V(25, kUnsignedFourBytes)                                                    \
  V(31, kUnsignedFourBytes)
#else
#define FOR_EACH_SHIFT_AND_UNSIGNED_SIZE(V)                                    \
  V(0, kUnsignedFourBytes)                                                     \
  V(1, kUnsignedFourBytes)                                                     \
  V(7, kUnsignedFourBytes)                                                     \
  V(15, kUnsignedFourBytes)                                                    \
  V(16, kUnsignedFourBytes)                                                    \
  V(25, kUnsignedFourBytes)                                                    \
  V(31, kUnsignedFourBytes)
#endif

#if defined(TARGET_ARCH_IA32)
#define LSL_ASSEMBLER_TEST_GENERATE(shift, sz)                                 \
  ASSEMBLER_TEST_GENERATE(LslImmediate_X_##shift##_##sz, assembler) {          \
    __ movl(RegRegImmTests::kReturnReg, Address(ESP, 4));                      \
    __ LslImmediate(RegRegImmTests::kReturnReg, RegRegImmTests::kReturnReg,    \
                    shift, sz);                                                \
    __ Ret();                                                                  \
  }
#else
#define LSL_ASSEMBLER_TEST_GENERATE(shift, sz)                                 \
  ASSEMBLER_TEST_GENERATE(LslImmediate_X_##shift##_##sz, assembler) {          \
    __ LslImmediate(RegRegImmTests::kReturnReg, RegRegImmTests::kInputReg,     \
                    shift, sz);                                                \
    __ Ret();                                                                  \
  }
#endif

#define LSL_ASSEMBLER_TEST_RUN(shift, sz)                                      \
  ASSEMBLER_TEST_RUN(LslImmediate_X_##shift##_##sz, test) {                    \
    dart::Expect expect(__FILE__, __LINE__);                                   \
    CheckRegRegImmOperation(expect, test, shift, sz, RegRegImmTests::Lsl);     \
  }

FOR_EACH_SHIFT_AND_SIGNED_SIZE(LSL_ASSEMBLER_TEST_GENERATE)
FOR_EACH_SHIFT_AND_SIGNED_SIZE(LSL_ASSEMBLER_TEST_RUN)
FOR_EACH_SHIFT_AND_UNSIGNED_SIZE(LSL_ASSEMBLER_TEST_GENERATE)
FOR_EACH_SHIFT_AND_UNSIGNED_SIZE(LSL_ASSEMBLER_TEST_RUN)

#undef LSL_ASSEMBLER_TEST_RUN
#undef LSL_ASSEMBLER_TEST_GENERATE

#if defined(TARGET_ARCH_IA32)
#define ASR_ASSEMBLER_TEST_GENERATE(shift, sz)                                 \
  ASSEMBLER_TEST_GENERATE(ArithmeticShiftRightImmediate_X_##shift##_##sz,      \
                          assembler) {                                         \
    if (Assembler::IsSignedOperand(sz)) {                                      \
      __ movl(RegRegImmTests::kReturnReg, Address(ESP, 4));                    \
      __ ArithmeticShiftRightImmediate(RegRegImmTests::kReturnReg,             \
                                       RegRegImmTests::kReturnReg, shift, sz); \
    }                                                                          \
    __ Ret();                                                                  \
  }
#else
#define ASR_ASSEMBLER_TEST_GENERATE(shift, sz)                                 \
  ASSEMBLER_TEST_GENERATE(ArithmeticShiftRightImmediate_X_##shift##_##sz,      \
                          assembler) {                                         \
    __ ArithmeticShiftRightImmediate(RegRegImmTests::kReturnReg,               \
                                     RegRegImmTests::kInputReg, shift, sz);    \
    __ Ret();                                                                  \
  }
#endif

#define ASR_ASSEMBLER_TEST_RUN(shift, sz)                                      \
  ASSEMBLER_TEST_RUN(ArithmeticShiftRightImmediate_X_##shift##_##sz, test) {   \
    dart::Expect expect(__FILE__, __LINE__);                                   \
    CheckRegRegImmOperation(expect, test, shift, sz, RegRegImmTests::Asr);     \
  }

FOR_EACH_SHIFT_AND_SIGNED_SIZE(ASR_ASSEMBLER_TEST_GENERATE)
FOR_EACH_SHIFT_AND_SIGNED_SIZE(ASR_ASSEMBLER_TEST_RUN)

#undef ASR_ASSEMBLER_TEST_RUN
#undef ASR_ASSEMBLER_TEST_GENERATE
#undef FOR_EACH_SHIFT_AND_UNSIGNED_SIZE
#undef FOR_EACH_SHIFT_AND_SIGNED_SIZE

}  // namespace compiler

}  // namespace dart
