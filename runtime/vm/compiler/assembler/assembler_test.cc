// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/assembler.h"
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

}  // namespace dart
