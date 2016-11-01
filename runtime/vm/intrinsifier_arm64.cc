// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/regexp_assembler.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

namespace dart {

// When entering intrinsics code:
// R4: Arguments descriptor
// LR: Return address
// The R4 register can be destroyed only if there is no slow-path, i.e.
// if the intrinsified method always executes a return.
// The FP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_arm64.h) must be preserved.

#define __ assembler->


intptr_t Intrinsifier::ParameterSlotFromSp() { return -1; }


static bool IsABIPreservedRegister(Register reg) {
  return ((1 << reg) & kAbiPreservedCpuRegs) != 0;
}


void Intrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  ASSERT(IsABIPreservedRegister(CODE_REG));
  ASSERT(!IsABIPreservedRegister(ARGS_DESC_REG));
  ASSERT(IsABIPreservedRegister(CALLEE_SAVED_TEMP));
  ASSERT(IsABIPreservedRegister(CALLEE_SAVED_TEMP2));
  ASSERT(CALLEE_SAVED_TEMP != CODE_REG);
  ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);
  ASSERT(CALLEE_SAVED_TEMP2 != CODE_REG);
  ASSERT(CALLEE_SAVED_TEMP2 != ARGS_DESC_REG);

  assembler->Comment("IntrinsicCallPrologue");
  assembler->mov(CALLEE_SAVED_TEMP, LR);
  assembler->mov(CALLEE_SAVED_TEMP2, ARGS_DESC_REG);
}


void Intrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->mov(LR, CALLEE_SAVED_TEMP);
  assembler->mov(ARGS_DESC_REG, CALLEE_SAVED_TEMP2);
}


// Intrinsify only for Smi value and index. Non-smi values need a store buffer
// update. Array length is always a Smi.
void Intrinsifier::ObjectArraySetIndexed(Assembler* assembler) {
  if (Isolate::Current()->type_checks()) {
    return;
  }

  Label fall_through;
  __ ldr(R1, Address(SP, 1 * kWordSize));  // Index.
  __ tsti(R1, Immediate(kSmiTagMask));
  // Index not Smi.
  __ b(&fall_through, NE);
  __ ldr(R0, Address(SP, 2 * kWordSize));  // Array.

  // Range check.
  __ ldr(R3, FieldAddress(R0, Array::length_offset()));  // Array length.
  __ cmp(R1, Operand(R3));
  // Runtime throws exception.
  __ b(&fall_through, CS);

  // Note that R1 is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ ldr(R2, Address(SP, 0 * kWordSize));  // Value.
  __ add(R1, R0, Operand(R1, LSL, 2));  // R1 is Smi.
  __ StoreIntoObject(R0,
                     FieldAddress(R1, Array::data_offset()),
                     R2);
  // Caller is responsible for preserving the value if necessary.
  __ ret();
  __ Bind(&fall_through);
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+1), data (+0).
void Intrinsifier::GrowableArray_Allocate(Assembler* assembler) {
  // The newly allocated object is returned in R0.
  const intptr_t kTypeArgumentsOffset = 1 * kWordSize;
  const intptr_t kArrayOffset = 0 * kWordSize;
  Label fall_through;

  // Try allocating in new space.
  const Class& cls = Class::Handle(
      Isolate::Current()->object_store()->growable_object_array_class());
  __ TryAllocate(cls, &fall_through, R0, R1);

  // Store backing array object in growable array object.
  __ ldr(R1, Address(SP, kArrayOffset));  // Data argument.
  // R0 is new, no barrier needed.
  __ StoreIntoObjectNoBarrier(
      R0,
      FieldAddress(R0, GrowableObjectArray::data_offset()),
      R1);

  // R0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ ldr(R1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreIntoObjectNoBarrier(
      R0,
      FieldAddress(R0, GrowableObjectArray::type_arguments_offset()),
      R1);

  // Set the length field in the growable array object to 0.
  __ LoadImmediate(R1, 0);
  __ str(R1, FieldAddress(R0, GrowableObjectArray::length_offset()));
  __ ret();  // Returns the newly allocated object in R0.

  __ Bind(&fall_through);
}


// Add an element to growable array if it doesn't need to grow, otherwise
// call into regular code.
// On stack: growable array (+1), value (+0).
void Intrinsifier::GrowableArray_add(Assembler* assembler) {
  // In checked mode we need to type-check the incoming argument.
  if (Isolate::Current()->type_checks()) {
    return;
  }
  Label fall_through;
  // R0: Array.
  __ ldr(R0, Address(SP, 1 * kWordSize));
  // R1: length.
  __ ldr(R1, FieldAddress(R0, GrowableObjectArray::length_offset()));
  // R2: data.
  __ ldr(R2, FieldAddress(R0, GrowableObjectArray::data_offset()));
  // R3: capacity.
  __ ldr(R3, FieldAddress(R2, Array::length_offset()));
  // Compare length with capacity.
  __ cmp(R1, Operand(R3));
  __ b(&fall_through, EQ);  // Must grow data.
  const int64_t value_one = reinterpret_cast<int64_t>(Smi::New(1));
  // len = len + 1;
  __ add(R3, R1, Operand(value_one));
  __ str(R3, FieldAddress(R0, GrowableObjectArray::length_offset()));
  __ ldr(R0, Address(SP, 0 * kWordSize));  // Value.
  ASSERT(kSmiTagShift == 1);
  __ add(R1, R2, Operand(R1, LSL, 2));
  __ StoreIntoObject(R2,
                     FieldAddress(R1, Array::data_offset()),
                     R0);
  __ LoadObject(R0, Object::null_object());
  __ ret();
  __ Bind(&fall_through);
}


static int GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1: return 0;
    case 2: return 1;
    case 4: return 2;
    case 8: return 3;
    case 16: return 4;
  }
  UNREACHABLE();
  return -1;
}


#define TYPED_ARRAY_ALLOCATION(type_name, cid, max_len, scale_shift)           \
  Label fall_through;                                                          \
  const intptr_t kArrayLengthStackOffset = 0 * kWordSize;                      \
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, R2, &fall_through));             \
  __ ldr(R2, Address(SP, kArrayLengthStackOffset));  /* Array length. */       \
  /* Check that length is a positive Smi. */                                   \
  /* R2: requested array length argument. */                                   \
  __ tsti(R2, Immediate(kSmiTagMask));                                         \
  __ b(&fall_through, NE);                                                     \
  __ CompareRegisters(R2, ZR);                                                 \
  __ b(&fall_through, LT);                                                     \
  __ SmiUntag(R2);                                                             \
  /* Check for maximum allowed length. */                                      \
  /* R2: untagged array length. */                                             \
  __ CompareImmediate(R2, max_len);                                            \
  __ b(&fall_through, GT);                                                     \
  __ LslImmediate(R2, R2, scale_shift);                                        \
  const intptr_t fixed_size = sizeof(Raw##type_name) + kObjectAlignment - 1;   \
  __ AddImmediate(R2, R2, fixed_size);                                         \
  __ andi(R2, R2, Immediate(~(kObjectAlignment - 1)));                         \
  Heap::Space space = Heap::kNew;                                              \
  __ ldr(R3, Address(THR, Thread::heap_offset()));                             \
  __ ldr(R0, Address(R3, Heap::TopOffset(space)));                             \
                                                                               \
  /* R2: allocation size. */                                                   \
  __ adds(R1, R0, Operand(R2));                                                \
  __ b(&fall_through, CS);  /* Fail on unsigned overflow. */                   \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* R0: potential new object start. */                                        \
  /* R1: potential next object start. */                                       \
  /* R2: allocation size. */                                                   \
  /* R3: heap. */                                                              \
  __ ldr(R6, Address(R3, Heap::EndOffset(space)));                             \
  __ cmp(R1, Operand(R6));                                                     \
  __ b(&fall_through, CS);                                                     \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  __ str(R1, Address(R3, Heap::TopOffset(space)));                             \
  __ AddImmediate(R0, R0, kHeapObjectTag);                                     \
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, R2, space));            \
  /* Initialize the tags. */                                                   \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: allocation size. */                                                   \
  {                                                                            \
    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);                  \
    __ LslImmediate(R2, R2, RawObject::kSizeTagPos - kObjectAlignmentLog2);    \
    __ csel(R2, ZR, R2, HI);                                                   \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));                 \
    __ orr(R2, R2, Operand(TMP));                                              \
    __ str(R2, FieldAddress(R0, type_name::tags_offset()));  /* Tags. */       \
  }                                                                            \
  /* Set the length field. */                                                  \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  __ ldr(R2, Address(SP, kArrayLengthStackOffset));  /* Array length. */       \
  __ StoreIntoObjectNoBarrier(R0,                                              \
                              FieldAddress(R0, type_name::length_offset()),    \
                              R2);                                             \
  /* Initialize all array elements to 0. */                                    \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: iterator which initially points to the start of the variable */       \
  /* R3: scratch register. */                                                  \
  /* data area to be initialized. */                                           \
  __ mov(R3, ZR);                                                              \
  __ AddImmediate(R2, R0, sizeof(Raw##type_name) - 1);                         \
  Label init_loop, done;                                                       \
  __ Bind(&init_loop);                                                         \
  __ cmp(R2, Operand(R1));                                                     \
  __ b(&done, CS);                                                             \
  __ str(R3, Address(R2, 0));                                                  \
  __ add(R2, R2, Operand(kWordSize));                                          \
  __ b(&init_loop);                                                            \
  __ Bind(&done);                                                              \
                                                                               \
  __ ret();                                                                    \
  __ Bind(&fall_through);                                                      \


#define TYPED_DATA_ALLOCATOR(clazz)                                            \
void Intrinsifier::TypedData_##clazz##_factory(Assembler* assembler) {         \
  intptr_t size = TypedData::ElementSizeInBytes(kTypedData##clazz##Cid);       \
  intptr_t max_len = TypedData::MaxElements(kTypedData##clazz##Cid);           \
  int shift = GetScaleFactor(size);                                            \
  TYPED_ARRAY_ALLOCATION(TypedData, kTypedData##clazz##Cid, max_len, shift);   \
}
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATOR)
#undef TYPED_DATA_ALLOCATOR


// Loads args from stack into R0 and R1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ ldr(R0, Address(SP, + 0 * kWordSize));
  __ ldr(R1, Address(SP, + 1 * kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tsti(TMP, Immediate(kSmiTagMask));
  __ b(not_smi, NE);
}


void Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ adds(R0, R0, Operand(R1));  // Adds.
  __ b(&fall_through, VS);  // Fall-through on overflow.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_add(Assembler* assembler) {
  Integer_addFromInteger(assembler);
}


void Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ subs(R0, R0, Operand(R1));  // Subtract.
  __ b(&fall_through, VS);  // Fall-through on overflow.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_sub(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ subs(R0, R1, Operand(R0));  // Subtract.
  __ b(&fall_through, VS);  // Fall-through on overflow.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ SmiUntag(R0);  // Untags R6. We only want result shifted by one.

  __ mul(TMP, R0, R1);
  __ smulh(TMP2, R0, R1);
  // TMP: result bits 64..127.
  __ cmp(TMP2, Operand(TMP, ASR, 63));
  __ b(&fall_through, NE);
  __ mov(R0, TMP);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_mul(Assembler* assembler) {
  Integer_mulFromInteger(assembler);
}


// Optimizations:
// - result is 0 if:
//   - left is 0
//   - left equals right
// - result is left if
//   - left > 0 && left < right
// R1: Tagged left (dividend).
// R0: Tagged right (divisor).
// Returns:
//   R1: Untagged fallthrough result (remainder to be adjusted), or
//   R0: Tagged return result (remainder).
static void EmitRemainderOperation(Assembler* assembler) {
  Label return_zero, modulo;
  const Register left = R1;
  const Register right = R0;
  const Register result = R1;
  const Register tmp = R2;
  ASSERT(left == result);

  // Check for quick zero results.
  __ CompareRegisters(left, ZR);
  __ b(&return_zero, EQ);
  __ CompareRegisters(left, right);
  __ b(&return_zero, EQ);

  // Check if result should be left.
  __ CompareRegisters(left, ZR);
  __ b(&modulo, LT);
  // left is positive.
  __ CompareRegisters(left, right);
  // left is less than right, result is left.
  __ b(&modulo, GT);
  __ mov(R0, left);
  __ ret();

  __ Bind(&return_zero);
  __ mov(R0, ZR);
  __ ret();

  __ Bind(&modulo);
  // result <- left - right * (left / right)
  __ SmiUntag(left);
  __ SmiUntag(right);

  __ sdiv(tmp, left, right);
  __ msub(result, right, tmp, left);  // result <- left - right * tmp
}


// Implementation:
//  res = left % right;
//  if (res < 0) {
//    if (right < 0) {
//      res = res - right;
//    } else {
//      res = res + right;
//    }
//  }
void Intrinsifier::Integer_moduloFromInteger(Assembler* assembler) {
  // Check to see if we have integer division
  Label neg_remainder, fall_through;
  __ ldr(R1, Address(SP, + 0 * kWordSize));
  __ ldr(R0, Address(SP, + 1 * kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tsti(TMP, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);
  // R1: Tagged left (dividend).
  // R0: Tagged right (divisor).
  // Check if modulo by zero -> exception thrown in main function.
  __ CompareRegisters(R0, ZR);
  __ b(&fall_through, EQ);
  EmitRemainderOperation(assembler);
  // Untagged right in R0. Untagged remainder result in R1.

  __ CompareRegisters(R1, ZR);
  __ b(&neg_remainder, LT);
  __ SmiTag(R0, R1);  // Tag and move result to R0.
  __ ret();

  __ Bind(&neg_remainder);
  // Result is negative, adjust it.
  __ CompareRegisters(R0, ZR);
  __ sub(TMP, R1, Operand(R0));
  __ add(TMP2, R1, Operand(R0));
  __ csel(R0, TMP2, TMP, GE);
  __ SmiTag(R0);
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  // Check to see if we have integer division
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ CompareRegisters(R0, ZR);
  __ b(&fall_through, EQ);  // If b is 0, fall through.

  __ SmiUntag(R0);
  __ SmiUntag(R1);

  __ sdiv(R0, R1, R0);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ CompareImmediate(R0, 0x4000000000000000);
  __ b(&fall_through, EQ);
  __ SmiTag(R0);  // Not equal. Okay to tag and return.
  __ ret();  // Return.
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_negate(Assembler* assembler) {
  Label fall_through;
  __ ldr(R0, Address(SP, + 0 * kWordSize));  // Grab first argument.
  __ tsti(R0, Immediate(kSmiTagMask));  // Test for Smi.
  __ b(&fall_through, NE);
  __ negs(R0, R0);
  __ b(&fall_through, VS);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ and_(R0, R0, Operand(R1));
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}


void Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ orr(R0, R0, Operand(R1));
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitOr(Assembler* assembler) {
  Integer_bitOrFromInteger(assembler);
}


void Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ eor(R0, R0, Operand(R1));
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitXor(Assembler* assembler) {
  Integer_bitXorFromInteger(assembler);
}


void Intrinsifier::Integer_shl(Assembler* assembler) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  const Register right = R0;
  const Register left = R1;
  const Register temp = R2;
  const Register result = R0;
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ CompareImmediate(
      right, reinterpret_cast<int64_t>(Smi::New(Smi::kBits)));
  __ b(&fall_through, CS);

  // Left is not a constant.
  // Check if count too large for handling it inlined.
  __ SmiUntag(TMP, right);  // SmiUntag right into TMP.
  // Overflow test (preserve left, right, and TMP);
  __ lslv(temp, left, TMP);
  __ asrv(TMP2, temp, TMP);
  __ CompareRegisters(left, TMP2);
  __ b(&fall_through, NE);  // Overflow.
  // Shift for result now we know there is no overflow.
  __ lslv(result, left, TMP);
  __ ret();
  __ Bind(&fall_through);
}


static void CompareIntegers(Assembler* assembler, Condition true_condition) {
  Label fall_through, true_label;
  TestBothArgumentsSmis(assembler, &fall_through);
  // R0 contains the right argument, R1 the left.
  __ CompareRegisters(R1, R0);
  __ LoadObject(R0, Bool::False());
  __ LoadObject(TMP, Bool::True());
  __ csel(R0, TMP, R0, true_condition);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  CompareIntegers(assembler, LT);
}


void Intrinsifier::Integer_lessThan(Assembler* assembler) {
  Integer_greaterThanFromInt(assembler);
}


void Intrinsifier::Integer_greaterThan(Assembler* assembler) {
  CompareIntegers(assembler, GT);
}


void Intrinsifier::Integer_lessEqualThan(Assembler* assembler) {
  CompareIntegers(assembler, LE);
}


void Intrinsifier::Integer_greaterEqualThan(Assembler* assembler) {
  CompareIntegers(assembler, GE);
}


// This is called for Smi, Mint and Bigint receivers. The right argument
// can be Smi, Mint, Bigint or double.
void Intrinsifier::Integer_equalToInteger(Assembler* assembler) {
  Label fall_through, true_label, check_for_mint;
  // For integer receiver '===' check first.
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ cmp(R0, Operand(R1));
  __ b(&true_label, EQ);

  __ orr(R2, R0, Operand(R1));
  __ tsti(R2, Immediate(kSmiTagMask));
  __ b(&check_for_mint, NE);  // If R0 or R1 is not a smi do Mint checks.

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(R0, Bool::False());
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(R0, Bool::True());
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ tsti(R1, Immediate(kSmiTagMask));  // Check receiver.
  __ b(&receiver_not_smi, NE);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint or Bigint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(R0, kDoubleCid);
  __ b(&fall_through, EQ);
  __ LoadObject(R0, Bool::False());  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // R1: receiver.

  __ CompareClassId(R1, kMintCid);
  __ b(&fall_through, NE);
  // Receiver is Mint, return false if right is Smi.
  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);
  __ LoadObject(R0, Bool::False());
  __ ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_equal(Assembler* assembler) {
  Integer_equalToInteger(assembler);
}


void Intrinsifier::Integer_sar(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  // Shift amount in R0. Value to shift in R1.

  // Fall through if shift amount is negative.
  __ SmiUntag(R0);
  __ CompareRegisters(R0, ZR);
  __ b(&fall_through, LT);

  // If shift amount is bigger than 63, set to 63.
  __ LoadImmediate(TMP, 0x3F);
  __ CompareRegisters(R0, TMP);
  __ csel(R0, TMP, R0, GT);
  __ SmiUntag(R1);
  __ asrv(R0, R1, R0);
  __ SmiTag(R0);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ mvn(R0, R0);
  __ andi(R0, R0, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
  __ ret();
}


void Intrinsifier::Smi_bitLength(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ SmiUntag(R0);
  // XOR with sign bit to complement bits if value is negative.
  __ eor(R0, R0, Operand(R0, ASR, 63));
  __ clz(R0, R0);
  __ LoadImmediate(R1, 64);
  __ sub(R0, R1, Operand(R0));
  __ SmiTag(R0);
  __ ret();
}


void Intrinsifier::Smi_bitAndFromSmi(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}


void Intrinsifier::Bigint_lsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R2 = x_used, R3 = x_digits, x_used > 0, x_used is Smi.
  __ ldp(R2, R3, Address(SP, 2 * kWordSize, Address::PairOffset));
  __ add(R2, R2, Operand(2));  // x_used > 0, Smi. R2 = x_used + 1, round up.
  __ AsrImmediate(R2, R2, 2);  // R2 = num of digit pairs to read.
  // R4 = r_digits, R5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldp(R4, R5, Address(SP, 0 * kWordSize, Address::PairOffset));
  __ SmiUntag(R5);
  // R0 = n ~/ (2*_DIGIT_BITS)
  __ AsrImmediate(R0, R5, 6);
  // R6 = &x_digits[0]
  __ add(R6, R3, Operand(TypedData::data_offset() - kHeapObjectTag));
  // R7 = &x_digits[2*R2]
  __ add(R7, R6, Operand(R2, LSL, 3));
  // R8 = &r_digits[2*1]
  __ add(R8, R4, Operand(TypedData::data_offset() - kHeapObjectTag +
                         2 * Bigint::kBytesPerDigit));
  // R8 = &r_digits[2*(R2 + n ~/ (2*_DIGIT_BITS) + 1)]
  __ add(R0, R0, Operand(R2));
  __ add(R8, R8, Operand(R0, LSL, 3));
  // R3 = n % (2 * _DIGIT_BITS)
  __ AndImmediate(R3, R5, 63);
  // R2 = 64 - R3
  __ LoadImmediate(R2, 64);
  __ sub(R2, R2, Operand(R3));
  __ mov(R1, ZR);
  Label loop;
  __ Bind(&loop);
  __ ldr(R0, Address(R7, -2 * Bigint::kBytesPerDigit, Address::PreIndex));
  __ lsrv(R4, R0, R2);
  __ orr(R1, R1, Operand(R4));
  __ str(R1, Address(R8, -2 * Bigint::kBytesPerDigit, Address::PreIndex));
  __ lslv(R1, R0, R3);
  __ cmp(R7, Operand(R6));
  __ b(&loop, NE);
  __ str(R1, Address(R8, -2 * Bigint::kBytesPerDigit, Address::PreIndex));
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_rsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R2 = x_used, R3 = x_digits, x_used > 0, x_used is Smi.
  __ ldp(R2, R3, Address(SP, 2 * kWordSize, Address::PairOffset));
  __ add(R2, R2, Operand(2));  // x_used > 0, Smi. R2 = x_used + 1, round up.
  __ AsrImmediate(R2, R2, 2);  // R2 = num of digit pairs to read.
  // R4 = r_digits, R5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldp(R4, R5, Address(SP, 0 * kWordSize, Address::PairOffset));
  __ SmiUntag(R5);
  // R0 = n ~/ (2*_DIGIT_BITS)
  __ AsrImmediate(R0, R5, 6);
  // R8 = &r_digits[0]
  __ add(R8, R4, Operand(TypedData::data_offset() - kHeapObjectTag));
  // R7 = &x_digits[2*(n ~/ (2*_DIGIT_BITS))]
  __ add(R7, R3, Operand(TypedData::data_offset() - kHeapObjectTag));
  __ add(R7, R7, Operand(R0, LSL, 3));
  // R6 = &r_digits[2*(R2 - n ~/ (2*_DIGIT_BITS) - 1)]
  __ add(R0, R0, Operand(1));
  __ sub(R0, R2, Operand(R0));
  __ add(R6, R8, Operand(R0, LSL, 3));
  // R3 = n % (2*_DIGIT_BITS)
  __ AndImmediate(R3, R5, 63);
  // R2 = 64 - R3
  __ LoadImmediate(R2, 64);
  __ sub(R2, R2, Operand(R3));
  // R1 = x_digits[n ~/ (2*_DIGIT_BITS)] >> (n % (2*_DIGIT_BITS))
  __ ldr(R1, Address(R7, 2 * Bigint::kBytesPerDigit, Address::PostIndex));
  __ lsrv(R1, R1, R3);
  Label loop_entry;
  __ b(&loop_entry);
  Label loop;
  __ Bind(&loop);
  __ ldr(R0, Address(R7, 2 * Bigint::kBytesPerDigit, Address::PostIndex));
  __ lslv(R4, R0, R2);
  __ orr(R1, R1, Operand(R4));
  __ str(R1, Address(R8, 2 * Bigint::kBytesPerDigit, Address::PostIndex));
  __ lsrv(R1, R0, R3);
  __ Bind(&loop_entry);
  __ cmp(R8, Operand(R6));
  __ b(&loop, NE);
  __ str(R1, Address(R8, 0));
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_absAdd(Assembler* assembler) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R2 = used, R3 = digits
  __ ldp(R2, R3, Address(SP, 3 * kWordSize, Address::PairOffset));
  __ add(R2, R2, Operand(2));  // used > 0, Smi. R2 = used + 1, round up.
  __ add(R2, ZR, Operand(R2, ASR, 2));  // R2 = num of digit pairs to process.
  // R3 = &digits[0]
  __ add(R3, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R4 = a_used, R5 = a_digits
  __ ldp(R4, R5, Address(SP, 1 * kWordSize, Address::PairOffset));
  __ add(R4, R4, Operand(2));  // a_used > 0, Smi. R4 = a_used + 1, round up.
  __ add(R4, ZR, Operand(R4, ASR, 2));  // R4 = num of digit pairs to process.
  // R5 = &a_digits[0]
  __ add(R5, R5, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R6 = r_digits
  __ ldr(R6, Address(SP, 0 * kWordSize));
  // R6 = &r_digits[0]
  __ add(R6, R6, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R7 = &digits[a_used rounded up to even number].
  __ add(R7, R3, Operand(R4, LSL, 3));

  // R8 = &digits[a_used rounded up to even number].
  __ add(R8, R3, Operand(R2, LSL, 3));

  __ adds(R0, R0, Operand(0));  // carry flag = 0
  Label add_loop;
  __ Bind(&add_loop);
  // Loop (a_used+1)/2 times, a_used > 0.
  __ ldr(R0, Address(R3, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ ldr(R1, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ adcs(R0, R0, R1);
  __ sub(R9, R3, Operand(R7));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ cbnz(&add_loop, R9);  // Does not affect carry flag.

  Label last_carry;
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ cbz(&last_carry, R9);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, used - a_used > 0.
  __ ldr(R0, Address(R3, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ adcs(R0, R0, ZR);
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ cbnz(&carry_loop, R9);

  __ Bind(&last_carry);
  Label done;
  __ b(&done, CC);
  __ LoadImmediate(R0, 1);
  __ str(R0, Address(R6, 0));

  __ Bind(&done);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_absSub(Assembler* assembler) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R2 = used, R3 = digits
  __ ldp(R2, R3, Address(SP, 3 * kWordSize, Address::PairOffset));
  __ add(R2, R2, Operand(2));  // used > 0, Smi. R2 = used + 1, round up.
  __ add(R2, ZR, Operand(R2, ASR, 2));  // R2 = num of digit pairs to process.
  // R3 = &digits[0]
  __ add(R3, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R4 = a_used, R5 = a_digits
  __ ldp(R4, R5, Address(SP, 1 * kWordSize, Address::PairOffset));
  __ add(R4, R4, Operand(2));  // a_used > 0, Smi. R4 = a_used + 1, round up.
  __ add(R4, ZR, Operand(R4, ASR, 2));  // R4 = num of digit pairs to process.
  // R5 = &a_digits[0]
  __ add(R5, R5, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R6 = r_digits
  __ ldr(R6, Address(SP, 0 * kWordSize));
  // R6 = &r_digits[0]
  __ add(R6, R6, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R7 = &digits[a_used rounded up to even number].
  __ add(R7, R3, Operand(R4, LSL, 3));

  // R8 = &digits[a_used rounded up to even number].
  __ add(R8, R3, Operand(R2, LSL, 3));

  __ subs(R0, R0, Operand(0));  // carry flag = 1
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop (a_used+1)/2 times, a_used > 0.
  __ ldr(R0, Address(R3, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ ldr(R1, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ sbcs(R0, R0, R1);
  __ sub(R9, R3, Operand(R7));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ cbnz(&sub_loop, R9);  // Does not affect carry flag.

  Label done;
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ cbz(&done, R9);  // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop (used+1)/2 - (a_used+1)/2 times, used - a_used > 0.
  __ ldr(R0, Address(R3, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ sbcs(R0, R0, ZR);
  __ sub(R9, R3, Operand(R8));  // Does not affect carry flag.
  __ str(R0, Address(R6, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ cbnz(&carry_loop, R9);

  __ Bind(&done);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_mulAdd(Assembler* assembler) {
  // Pseudo code:
  // static int _mulAdd(Uint32List x_digits, int xi,
  //                    Uint32List m_digits, int i,
  //                    Uint32List a_digits, int j, int n) {
  //   uint64_t x = x_digits[xi >> 1 .. (xi >> 1) + 1];  // xi is Smi and even.
  //   if (x == 0 || n == 0) {
  //     return 2;
  //   }
  //   uint64_t* mip = &m_digits[i >> 1];  // i is Smi and even.
  //   uint64_t* ajp = &a_digits[j >> 1];  // j is Smi and even.
  //   uint64_t c = 0;
  //   SmiUntag(n);  // n is Smi and even.
  //   n = (n + 1)/2;  // Number of pairs to process.
  //   do {
  //     uint64_t mi = *mip++;
  //     uint64_t aj = *ajp;
  //     uint128_t t = x*mi + aj + c;  // 64-bit * 64-bit -> 128-bit.
  //     *ajp++ = low64(t);
  //     c = high64(t);
  //   } while (--n > 0);
  //   while (c != 0) {
  //     uint128_t t = *ajp + c;
  //     *ajp++ = low64(t);
  //     c = high64(t);  // c == 0 or 1.
  //   }
  //   return 2;
  // }

  Label done;
  // R3 = x, no_op if x == 0
  // R0 = xi as Smi, R1 = x_digits.
  __ ldp(R0, R1, Address(SP, 5 * kWordSize, Address::PairOffset));
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R3, FieldAddress(R1, TypedData::data_offset()));
  __ tst(R3, Operand(R3));
  __ b(&done, EQ);

  // R6 = (SmiUntag(n) + 1)/2, no_op if n == 0
  __ ldr(R6, Address(SP, 0 * kWordSize));
  __ add(R6, R6, Operand(2));
  __ adds(R6, ZR, Operand(R6, ASR, 2));  // SmiUntag(R6) and set cc.
  __ b(&done, EQ);

  // R4 = mip = &m_digits[i >> 1]
  // R0 = i as Smi, R1 = m_digits.
  __ ldp(R0, R1, Address(SP, 3 * kWordSize, Address::PairOffset));
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R4, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R5 = ajp = &a_digits[j >> 1]
  // R0 = j as Smi, R1 = a_digits.
  __ ldp(R0, R1, Address(SP, 1 * kWordSize, Address::PairOffset));
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R5, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R1 = c = 0
  __ mov(R1, ZR);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   R3
  // mip: R4
  // ajp: R5
  // c:   R1
  // n:   R6
  // t:   R7:R8 (not live at loop entry)

  // uint64_t mi = *mip++
  __ ldr(R2, Address(R4, 2*Bigint::kBytesPerDigit, Address::PostIndex));

  // uint64_t aj = *ajp
  __ ldr(R0, Address(R5, 0));

  // uint128_t t = x*mi + aj + c
  __ mul(R7, R2, R3);  // R7 = low64(R2*R3).
  __ umulh(R8, R2, R3);  // R8 = high64(R2*R3), t = R8:R7 = x*mi.
  __ adds(R7, R7, Operand(R0));
  __ adc(R8, R8, ZR);  // t += aj.
  __ adds(R0, R7, Operand(R1));  // t += c, R0 = low64(t).
  __ adc(R1, R8, ZR);  // c = R1 = high64(t).

  // *ajp++ = low64(t) = R0
  __ str(R0, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));

  // while (--n > 0)
  __ subs(R6, R6, Operand(1));  // --n
  __ b(&muladd_loop, NE);

  __ tst(R1, Operand(R1));
  __ b(&done, EQ);

  // *ajp++ += c
  __ ldr(R0, Address(R5, 0));
  __ adds(R0, R0, Operand(R1));
  __ str(R0, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&done, CC);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ ldr(R0, Address(R5, 0));
  __ adds(R0, R0, Operand(1));
  __ str(R0, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&propagate_carry_loop, CS);

  __ Bind(&done);
  __ LoadImmediate(R0, Smi::RawValue(2));  // Two digits processed.
  __ ret();
}


void Intrinsifier::Bigint_sqrAdd(Assembler* assembler) {
  // Pseudo code:
  // static int _sqrAdd(Uint32List x_digits, int i,
  //                    Uint32List a_digits, int used) {
  //   uint64_t* xip = &x_digits[i >> 1];  // i is Smi and even.
  //   uint64_t x = *xip++;
  //   if (x == 0) return 2;
  //   uint64_t* ajp = &a_digits[i];  // j == 2*i, i is Smi.
  //   uint64_t aj = *ajp;
  //   uint128_t t = x*x + aj;
  //   *ajp++ = low64(t);
  //   uint128_t c = high64(t);
  //   int n = ((used - i + 2) >> 2) - 1;  // used and i are Smi. n: num pairs.
  //   while (--n >= 0) {
  //     uint64_t xi = *xip++;
  //     uint64_t aj = *ajp;
  //     uint192_t t = 2*x*xi + aj + c;  // 2-bit * 64-bit * 64-bit -> 129-bit.
  //     *ajp++ = low64(t);
  //     c = high128(t);  // 65-bit.
  //   }
  //   uint64_t aj = *ajp;
  //   uint128_t t = aj + c;  // 64-bit + 65-bit -> 66-bit.
  //   *ajp++ = low64(t);
  //   *ajp = high64(t);
  //   return 2;
  // }

  // R4 = xip = &x_digits[i >> 1]
  // R2 = i as Smi, R3 = x_digits
  __ ldp(R2, R3, Address(SP, 2 * kWordSize, Address::PairOffset));
  __ add(R3, R3, Operand(R2, LSL, 1));
  __ add(R4, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R3 = x = *xip++, return if x == 0
  Label x_zero;
  __ ldr(R3, Address(R4, 2*Bigint::kBytesPerDigit, Address::PostIndex));
  __ tst(R3, Operand(R3));
  __ b(&x_zero, EQ);

  // R5 = ajp = &a_digits[i]
  __ ldr(R1, Address(SP, 1 * kWordSize));  // a_digits
  __ add(R1, R1, Operand(R2, LSL, 2));  // j == 2*i, i is Smi.
  __ add(R5, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R6:R1 = t = x*x + *ajp
  __ ldr(R0, Address(R5, 0));
  __ mul(R1, R3, R3);  // R1 = low64(R3*R3).
  __ umulh(R6, R3, R3);  // R6 = high64(R3*R3).
  __ adds(R1, R1, Operand(R0));  // R6:R1 += *ajp.
  __ adc(R6, R6, ZR);  // R6 = low64(c) = high64(t).
  __ mov(R7, ZR);  // R7 = high64(c) = 0.

  // *ajp++ = low64(t) = R1
  __ str(R1, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));

  // int n = (used - i + 1)/2 - 1
  __ ldr(R0, Address(SP, 0 * kWordSize));  // used is Smi
  __ sub(R8, R0, Operand(R2));
  __ add(R8, R8, Operand(2));
  __ movn(R0, Immediate(1), 0);  // R0 = ~1 = -2.
  __ adds(R8, R0, Operand(R8, ASR, 2));  // while (--n >= 0)

  Label loop, done;
  __ b(&done, MI);

  __ Bind(&loop);
  // x:   R3
  // xip: R4
  // ajp: R5
  // c:   R7:R6
  // t:   R2:R1:R0 (not live at loop entry)
  // n:   R8

  // uint64_t xi = *xip++
  __ ldr(R2, Address(R4, 2*Bigint::kBytesPerDigit, Address::PostIndex));

  // uint192_t t = R2:R1:R0 = 2*x*xi + aj + c
  __ mul(R0, R2, R3);  // R0 = low64(R2*R3) = low64(x*xi).
  __ umulh(R1, R2, R3);  // R1 = high64(R2*R3) = high64(x*xi).
  __ adds(R0, R0, Operand(R0));
  __ adcs(R1, R1, R1);
  __ adc(R2, ZR, ZR);  // R2:R1:R0 = R1:R0 + R1:R0 = 2*x*xi.
  __ adds(R0, R0, Operand(R6));
  __ adcs(R1, R1, R7);
  __ adc(R2, R2, ZR);  // R2:R1:R0 += c.
  __ ldr(R7, Address(R5, 0));  // R7 = aj = *ajp.
  __ adds(R0, R0, Operand(R7));
  __ adcs(R6, R1, ZR);
  __ adc(R7, R2, ZR);  // R7:R6:R0 = 2*x*xi + aj + c.

  // *ajp++ = low64(t) = R0
  __ str(R0, Address(R5, 2*Bigint::kBytesPerDigit, Address::PostIndex));

  // while (--n >= 0)
  __ subs(R8, R8, Operand(1));  // --n
  __ b(&loop, PL);

  __ Bind(&done);
  // uint64_t aj = *ajp
  __ ldr(R0, Address(R5, 0));

  // uint128_t t = aj + c
  __ adds(R6, R6, Operand(R0));
  __ adc(R7, R7, ZR);

  // *ajp = low64(t) = R6
  // *(ajp + 1) = high64(t) = R7
  __ stp(R6, R7, Address(R5, 0, Address::PairOffset));

  __ Bind(&x_zero);
  __ LoadImmediate(R0, Smi::RawValue(2));  // Two digits processed.
  __ ret();
}


void Intrinsifier::Bigint_estQuotientDigit(Assembler* assembler) {
  // There is no 128-bit by 64-bit division instruction on arm64, so we use two
  // 64-bit by 32-bit divisions and two 64-bit by 64-bit multiplications to
  // adjust the two 32-bit digits of the estimated quotient.
  //
  // Pseudo code:
  // static int _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
  //   uint64_t yt = args[_YT_LO .. _YT];  // _YT_LO == 0, _YT == 1.
  //   uint64_t* dp = &digits[(i >> 1) - 1];  // i is Smi.
  //   uint64_t dh = dp[0];  // dh == digits[(i >> 1) - 1 .. i >> 1].
  //   uint64_t qd;
  //   if (dh == yt) {
  //     qd = (DIGIT_MASK << 32) | DIGIT_MASK;
  //   } else {
  //     dl = dp[-1];  // dl == digits[(i >> 1) - 3 .. (i >> 1) - 2].
  //     // We cannot calculate qd = dh:dl / yt, so ...
  //     uint64_t yth = yt >> 32;
  //     uint64_t qh = dh / yth;
  //     uint128_t ph:pl = yt*qh;
  //     uint64_t tl = (dh << 32)|(dl >> 32);
  //     uint64_t th = dh >> 32;
  //     while ((ph > th) || ((ph == th) && (pl > tl))) {
  //       if (pl < yt) --ph;
  //       pl -= yt;
  //       --qh;
  //     }
  //     qd = qh << 32;
  //     tl = (pl << 32);
  //     th = (ph << 32)|(pl >> 32);
  //     if (tl > dl) ++th;
  //     dl -= tl;
  //     dh -= th;
  //     uint64_t ql = ((dh << 32)|(dl >> 32)) / yth;
  //     ph:pl = yt*ql;
  //     while ((ph > dh) || ((ph == dh) && (pl > dl))) {
  //       if (pl < yt) --ph;
  //       pl -= yt;
  //       --ql;
  //     }
  //     qd |= ql;
  //   }
  //   args[_QD .. _QD_HI] = qd;  // _QD == 2, _QD_HI == 3.
  //   return 2;
  // }

  // R4 = args
  __ ldr(R4, Address(SP, 2 * kWordSize));  // args

  // R3 = yt = args[0..1]
  __ ldr(R3, FieldAddress(R4, TypedData::data_offset()));

  // R2 = dh = digits[(i >> 1) - 1 .. i >> 1]
  // R0 = i as Smi, R1 = digits
  __ ldp(R0, R1, Address(SP, 0 * kWordSize, Address::PairOffset));
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2,
         FieldAddress(R1, TypedData::data_offset() - Bigint::kBytesPerDigit));

  // R0 = qd = (DIGIT_MASK << 32) | DIGIT_MASK = -1
  __ movn(R0, Immediate(0), 0);

  // Return qd if dh == yt
  Label return_qd;
  __ cmp(R2, Operand(R3));
  __ b(&return_qd, EQ);

  // R1 = dl = digits[(i >> 1) - 3 .. (i >> 1) - 2]
  __ ldr(R1,
         FieldAddress(R1, TypedData::data_offset() - 3*Bigint::kBytesPerDigit));

  // R5 = yth = yt >> 32
  __ orr(R5, ZR, Operand(R3, LSR, 32));

  // R6 = qh = dh / yth
  __ udiv(R6, R2, R5);

  // R8:R7 = ph:pl = yt*qh
  __ mul(R7, R3, R6);
  __ umulh(R8, R3, R6);

  // R9 = tl = (dh << 32)|(dl >> 32)
  __ orr(R9, ZR, Operand(R2, LSL, 32));
  __ orr(R9, R9, Operand(R1, LSR, 32));

  // R10 = th = dh >> 32
  __ orr(R10, ZR, Operand(R2, LSR, 32));

  // while ((ph > th) || ((ph == th) && (pl > tl)))
  Label qh_adj_loop, qh_adj, qh_ok;
  __ Bind(&qh_adj_loop);
  __ cmp(R8, Operand(R10));
  __ b(&qh_adj, HI);
  __ b(&qh_ok, NE);
  __ cmp(R7, Operand(R9));
  __ b(&qh_ok, LS);

  __ Bind(&qh_adj);
  // if (pl < yt) --ph
  __ sub(TMP, R8, Operand(1));  // TMP = ph - 1
  __ cmp(R7, Operand(R3));
  __ csel(R8, TMP, R8, CC);  // R8 = R7 < R3 ? TMP : R8

  // pl -= yt
  __ sub(R7, R7, Operand(R3));

  // --qh
  __ sub(R6, R6, Operand(1));

  __ Bind(&qh_ok);
  // R0 = qd = qh << 32
  __ orr(R0, ZR, Operand(R6, LSL, 32));

  // tl = (pl << 32)
  __ orr(R9, ZR, Operand(R7, LSL, 32));

  // th = (ph << 32)|(pl >> 32);
  __ orr(R10, ZR, Operand(R8, LSL, 32));
  __ orr(R10, R10, Operand(R7, LSR, 32));

  // if (tl > dl) ++th
  __ add(TMP, R10, Operand(1));  // TMP = th + 1
  __ cmp(R9, Operand(R1));
  __ csel(R10, TMP, R10, HI);  // R10 = R9 > R1 ? TMP : R10

  // dl -= tl
  __ sub(R1, R1, Operand(R9));

  // dh -= th
  __ sub(R2, R2, Operand(R10));

  // R6 = ql = ((dh << 32)|(dl >> 32)) / yth
  __ orr(R6, ZR, Operand(R2, LSL, 32));
  __ orr(R6, R6, Operand(R1, LSR, 32));
  __ udiv(R6, R6, R5);

  // R8:R7 = ph:pl = yt*ql
  __ mul(R7, R3, R6);
  __ umulh(R8, R3, R6);

  // while ((ph > dh) || ((ph == dh) && (pl > dl))) {
  Label ql_adj_loop, ql_adj, ql_ok;
  __ Bind(&ql_adj_loop);
  __ cmp(R8, Operand(R2));
  __ b(&ql_adj, HI);
  __ b(&ql_ok, NE);
  __ cmp(R7, Operand(R1));
  __ b(&ql_ok, LS);

  __ Bind(&ql_adj);
  // if (pl < yt) --ph
  __ sub(TMP, R8, Operand(1));  // TMP = ph - 1
  __ cmp(R7, Operand(R3));
  __ csel(R8, TMP, R8, CC);  // R8 = R7 < R3 ? TMP : R8

  // pl -= yt
  __ sub(R7, R7, Operand(R3));

  // --ql
  __ sub(R6, R6, Operand(1));

  __ Bind(&ql_ok);
  // qd |= ql;
  __ orr(R0, R0, Operand(R6));

  __ Bind(&return_qd);
  // args[2..3] = qd
  __ str(R0,
         FieldAddress(R4, TypedData::data_offset() + 2*Bigint::kBytesPerDigit));

  __ LoadImmediate(R0, Smi::RawValue(2));  // Two digits processed.
  __ ret();
}


void Intrinsifier::Montgomery_mulMod(Assembler* assembler) {
  // Pseudo code:
  // static int _mulMod(Uint32List args, Uint32List digits, int i) {
  //   uint64_t rho = args[_RHO .. _RHO_HI];  // _RHO == 2, _RHO_HI == 3.
  //   uint64_t d = digits[i >> 1 .. (i >> 1) + 1];  // i is Smi and even.
  //   uint128_t t = rho*d;
  //   args[_MU .. _MU_HI] = t mod DIGIT_BASE^2;  // _MU == 4, _MU_HI == 5.
  //   return 2;
  // }

  // R4 = args
  __ ldr(R4, Address(SP, 2 * kWordSize));  // args

  // R3 = rho = args[2..3]
  __ ldr(R3,
         FieldAddress(R4, TypedData::data_offset() + 2*Bigint::kBytesPerDigit));

  // R2 = digits[i >> 1 .. (i >> 1) + 1]
  // R0 = i as Smi, R1 = digits
  __ ldp(R0, R1, Address(SP, 0 * kWordSize, Address::PairOffset));
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2, FieldAddress(R1, TypedData::data_offset()));

  // R0 = rho*d mod DIGIT_BASE
  __ mul(R0, R2, R3);  // R0 = low64(R2*R3).

  // args[4 .. 5] = R0
  __ str(R0,
         FieldAddress(R4, TypedData::data_offset() + 4*Bigint::kBytesPerDigit));

  __ LoadImmediate(R0, Smi::RawValue(2));  // Two digits processed.
  __ ret();
}


// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in R0.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(is_smi, EQ);
  __ CompareClassId(R0, kDoubleCid);
  __ b(not_double_smi, NE);
  // Fall through with Double in R0.
}


// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register R0. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler, Condition true_condition) {
  Label fall_through, is_smi, double_op, not_nan;

  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Both arguments are double, right operand is in R0.

  __ LoadDFieldFromOffset(V1, R0, Double::value_offset());
  __ Bind(&double_op);
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());

  __ fcmpd(V0, V1);
  __ LoadObject(R0, Bool::False());
  // Return false if D0 or D1 was NaN before checking true condition.
  __ b(&not_nan, VC);
  __ ret();
  __ Bind(&not_nan);
  __ LoadObject(TMP, Bool::True());
  __ csel(R0, TMP, R0, true_condition);
  __ ret();

  __ Bind(&is_smi);  // Convert R0 to a double.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ b(&double_op);  // Then do the comparison.
  __ Bind(&fall_through);
}


void Intrinsifier::Double_greaterThan(Assembler* assembler) {
  CompareDoubles(assembler, HI);
}


void Intrinsifier::Double_greaterEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, CS);
}


void Intrinsifier::Double_lessThan(Assembler* assembler) {
  CompareDoubles(assembler, CC);
}


void Intrinsifier::Double_equal(Assembler* assembler) {
  CompareDoubles(assembler, EQ);
}


void Intrinsifier::Double_lessEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, LS);
}


// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler, Token::Kind kind) {
  Label fall_through, is_smi, double_op;

  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Both arguments are double, right operand is in R0.
  __ LoadDFieldFromOffset(V1, R0, Double::value_offset());
  __ Bind(&double_op);
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());
  switch (kind) {
    case Token::kADD: __ faddd(V0, V0, V1); break;
    case Token::kSUB: __ fsubd(V0, V0, V1); break;
    case Token::kMUL: __ fmuld(V0, V0, V1); break;
    case Token::kDIV: __ fdivd(V0, V0, V1); break;
    default: UNREACHABLE();
  }
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset());
  __ ret();

  __ Bind(&is_smi);  // Convert R0 to a double.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ b(&double_op);

  __ Bind(&fall_through);
}


void Intrinsifier::Double_add(Assembler* assembler) {
  DoubleArithmeticOperations(assembler, Token::kADD);
}


void Intrinsifier::Double_mul(Assembler* assembler) {
  DoubleArithmeticOperations(assembler, Token::kMUL);
}


void Intrinsifier::Double_sub(Assembler* assembler) {
  DoubleArithmeticOperations(assembler, Token::kSUB);
}


void Intrinsifier::Double_div(Assembler* assembler) {
  DoubleArithmeticOperations(assembler, Token::kDIV);
}


// Left is double right is integer (Bigint, Mint or Smi)
void Intrinsifier::Double_mulFromInteger(Assembler* assembler) {
  Label fall_through;
  // Only smis allowed.
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);
  // Is Smi.
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ ldr(R0, Address(SP, 1 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());
  __ fmuld(V0, V0, V1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset());
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::DoubleFromInteger(Assembler* assembler) {
  Label fall_through;

  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);
  // Is Smi.
  __ SmiUntag(R0);
  __ scvtfdx(V0, R0);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset());
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());
  __ fcmpd(V0, V0);
  __ LoadObject(TMP, Bool::False());
  __ LoadObject(R0, Bool::True());
  __ csel(R0, TMP, R0, VC);
  __ ret();
}


void Intrinsifier::Double_getIsInfinite(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadFieldFromOffset(R0, R0, Double::value_offset());
  // Mask off the sign.
  __ AndImmediate(R0, R0, 0x7FFFFFFFFFFFFFFFLL);
  // Compare with +infinity.
  __ CompareImmediate(R0, 0x7FF0000000000000LL);
  __ LoadObject(R0, Bool::False());
  __ LoadObject(TMP, Bool::True());
  __ csel(R0, TMP, R0, EQ);
  __ ret();
}


void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  const Register false_reg = R0;
  const Register true_reg = R2;
  Label is_false, is_true, is_zero;

  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());
  __ fcmpdz(V0);
  __ LoadObject(true_reg, Bool::True());
  __ LoadObject(false_reg, Bool::False());
  __ b(&is_false, VS);  // NaN -> false.
  __ b(&is_zero, EQ);  // Check for negative zero.
  __ b(&is_false, CS);  // >= 0 -> false.

  __ Bind(&is_true);
  __ mov(R0, true_reg);

  __ Bind(&is_false);
  __ ret();

  __ Bind(&is_zero);
  // Check for negative zero by looking at the sign bit.
  __ fmovrd(R1, V0);
  __ LsrImmediate(R1, R1, 63);
  __ tsti(R1, Immediate(1));
  __ csel(R0, true_reg, false_reg, NE);  // Sign bit set.
  __ ret();
}


void Intrinsifier::DoubleToInteger(Assembler* assembler) {
  Label fall_through;

  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset());

  // Explicit NaN check, since ARM gives an FPU exception if you try to
  // convert NaN to an int.
  __ fcmpd(V0, V0);
  __ b(&fall_through, VS);

  __ fcvtzds(R0, V0);
  // Overflow is signaled with minint.
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(R0, 0xC000000000000000);
  __ b(&fall_through, MI);
  __ SmiTag(R0);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::MathSqrt(Assembler* assembler) {
  Label fall_through, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Argument is double and is in R0.
  __ LoadDFieldFromOffset(V1, R0, Double::value_offset());
  __ Bind(&double_op);
  __ fsqrtd(V0, V1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset());
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(R0);
  __ scvtfdx(V1, R0);
  __ b(&double_op);
  __ Bind(&fall_through);
}


//    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//    _state[kSTATE_LO] = state & _MASK_32;
//    _state[kSTATE_HI] = state >> 32;
void Intrinsifier::Random_nextState(Assembler* assembler) {
  const Library& math_lib = Library::Handle(Library::MathLibrary());
  ASSERT(!math_lib.IsNull());
  const Class& random_class = Class::Handle(
      math_lib.LookupClassAllowPrivate(Symbols::_Random()));
  ASSERT(!random_class.IsNull());
  const Field& state_field = Field::ZoneHandle(
      random_class.LookupInstanceFieldAllowPrivate(Symbols::_state()));
  ASSERT(!state_field.IsNull());
  const Field& random_A_field = Field::ZoneHandle(
      random_class.LookupStaticFieldAllowPrivate(Symbols::_A()));
  ASSERT(!random_A_field.IsNull());
  ASSERT(random_A_field.is_const());
  const Instance& a_value = Instance::Handle(random_A_field.StaticValue());
  const int64_t a_int_value = Integer::Cast(a_value).AsInt64Value();

  // Receiver.
  __ ldr(R0, Address(SP, 0 * kWordSize));
  // Field '_state'.
  __ ldr(R1, FieldAddress(R0, state_field.Offset()));

  // Addresses of _state[0].
  const int64_t disp =
      Instance::DataOffsetFor(kTypedDataUint32ArrayCid) - kHeapObjectTag;

  __ LoadImmediate(R0, a_int_value);
  __ LoadFromOffset(R2, R1, disp);
  __ LsrImmediate(R3, R2, 32);
  __ andi(R2, R2, Immediate(0xffffffff));
  __ mul(R2, R0, R2);
  __ add(R2, R2, Operand(R3));
  __ StoreToOffset(R2, R1, disp);
  __ ret();
}


void Intrinsifier::ObjectEquals(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ cmp(R0, Operand(R1));
  __ LoadObject(R0, Bool::False());
  __ LoadObject(TMP, Bool::True());
  __ csel(R0, TMP, R0, EQ);
  __ ret();
}


// Return type quickly for simple types (not parameterized and not signature).
void Intrinsifier::ObjectRuntimeType(Assembler* assembler) {
  Label fall_through;
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);
  __ CompareImmediate(R1, kClosureCid);
  __ b(&fall_through, EQ);  // Instance is a closure.
  __ LoadClassById(R2, R1);
  // R2: class of instance (R0).

  __ ldr(R3, FieldAddress(R2, Class::num_type_arguments_offset()), kHalfword);
  __ CompareImmediate(R3, 0);
  __ b(&fall_through, NE);

  __ ldr(R0, FieldAddress(R2, Class::canonical_type_offset()));
  __ CompareObject(R0, Object::null_object());
  __ b(&fall_through, EQ);
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::String_getHashCode(Assembler* assembler) {
  Label fall_through;
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R0, String::hash_offset()));
  __ CompareRegisters(R0, ZR);
  __ b(&fall_through, EQ);
  __ ret();
  // Hash not yet computed.
  __ Bind(&fall_through);
}


void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(R1);
  __ ldr(R8, FieldAddress(R0, String::length_offset()));  // this.length
  __ SmiUntag(R8);
  __ ldr(R9, FieldAddress(R2, String::length_offset()));  // other.length
  __ SmiUntag(R9);

  // if (other.length == 0) return true;
  __ cmp(R9, Operand(0));
  __ b(return_true, EQ);

  // if (start < 0) return false;
  __ cmp(R1, Operand(0));
  __ b(return_false, LT);

  // if (start + other.length > this.length) return false;
  __ add(R3, R1, Operand(R9));
  __ cmp(R3, Operand(R8));
  __ b(return_false, GT);

  if (receiver_cid == kOneByteStringCid) {
    __ AddImmediate(R0, R0, OneByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ AddImmediate(R0, R0, TwoByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R1));
  }
  if (other_cid == kOneByteStringCid) {
    __ AddImmediate(R2, R2, OneByteString::data_offset() - kHeapObjectTag);
  } else {
    ASSERT(other_cid == kTwoByteStringCid);
    __ AddImmediate(R2, R2, TwoByteString::data_offset() - kHeapObjectTag);
  }

  // i = 0
  __ LoadImmediate(R3, 0);

  // do
  Label loop;
  __ Bind(&loop);

  // this.codeUnitAt(i + start)
  __ ldr(R10, Address(R0, 0),
         receiver_cid == kOneByteStringCid ? kUnsignedByte : kUnsignedHalfword);
  // other.codeUnitAt(i)
  __ ldr(R11, Address(R2, 0),
         other_cid == kOneByteStringCid ? kUnsignedByte : kUnsignedHalfword);
  __ cmp(R10, Operand(R11));
  __ b(return_false, NE);

  // i++, while (i < len)
  __ add(R3, R3, Operand(1));
  __ add(R0, R0, Operand(receiver_cid == kOneByteStringCid ? 1 : 2));
  __ add(R2, R2, Operand(other_cid == kOneByteStringCid ? 1 : 2));
  __ cmp(R3, Operand(R9));
  __ b(&loop, LT);

  __ b(return_true);
}


// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void Intrinsifier::StringBaseSubstringMatches(Assembler* assembler) {
  Label fall_through, return_true, return_false, try_two_byte;
  __ ldr(R0, Address(SP, 2 * kWordSize));  // this
  __ ldr(R1, Address(SP, 1 * kWordSize));  // start
  __ ldr(R2, Address(SP, 0 * kWordSize));  // other

  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // 'start' is not a Smi.

  __ CompareClassId(R2, kOneByteStringCid);
  __ b(&fall_through, NE);

  __ CompareClassId(R0, kOneByteStringCid);
  __ b(&fall_through, NE);

  GenerateSubstringMatchesSpecialization(assembler,
                                         kOneByteStringCid,
                                         kOneByteStringCid,
                                         &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(R0, kTwoByteStringCid);
  __ b(&fall_through, NE);

  GenerateSubstringMatchesSpecialization(assembler,
                                         kTwoByteStringCid,
                                         kOneByteStringCid,
                                         &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ LoadObject(R0, Bool::True());
  __ ret();

  __ Bind(&return_false);
  __ LoadObject(R0, Bool::False());
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseCharAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;

  __ ldr(R1, Address(SP, 0 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 1 * kWordSize));  // String.
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // Index is not a Smi.
  // Range check.
  __ ldr(R2, FieldAddress(R0, String::length_offset()));
  __ cmp(R1, Operand(R2));
  __ b(&fall_through, CS);  // Runtime throws exception.

  __ CompareClassId(R0, kOneByteStringCid);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, R0, OneByteString::data_offset() - kHeapObjectTag);
  __ ldr(R1, Address(R0, R1), kUnsignedByte);
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols);
  __ b(&fall_through, GE);
  __ ldr(R0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, R0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid);
  __ b(&fall_through, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, R0, TwoByteString::data_offset() - kHeapObjectTag);
  __ ldr(R1, Address(R0, R1), kUnsignedHalfword);
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols);
  __ b(&fall_through, GE);
  __ ldr(R0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(
      R0, R0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseIsEmpty(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R0, String::length_offset()));
  __ cmp(R0, Operand(Smi::RawValue(0)));
  __ LoadObject(R0, Bool::True());
  __ LoadObject(TMP, Bool::False());
  __ csel(R0, TMP, R0, NE);
  __ ret();
}


void Intrinsifier::OneByteString_getHashCode(Assembler* assembler) {
  Label compute_hash;
  __ ldr(R1, Address(SP, 0 * kWordSize));  // OneByteString object.
  __ ldr(R0, FieldAddress(R1, String::hash_offset()));
  __ CompareRegisters(R0, ZR);
  __ b(&compute_hash, EQ);
  __ ret();  // Return if already computed.

  __ Bind(&compute_hash);
  __ ldr(R2, FieldAddress(R1, String::length_offset()));
  __ SmiUntag(R2);

  Label done;
  // If the string is empty, set the hash to 1, and return.
  __ CompareRegisters(R2, ZR);
  __ b(&done, EQ);

  __ mov(R3, ZR);
  __ AddImmediate(R6, R1, OneByteString::data_offset() - kHeapObjectTag);
  // R1: Instance of OneByteString.
  // R2: String length, untagged integer.
  // R3: Loop counter, untagged integer.
  // R6: String data.
  // R0: Hash code, untagged integer.

  Label loop;
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ Bind(&loop);
  __ ldr(R7, Address(R6, R3), kUnsignedByte);
  // R7: ch.
  __ add(R3, R3, Operand(1));
  __ addw(R0, R0, Operand(R7));
  __ addw(R0, R0, Operand(R0, LSL, 10));
  __ eorw(R0, R0, Operand(R0, LSR, 6));
  __ cmp(R3, Operand(R2));
  __ b(&loop, NE);

  // Finalize.
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ addw(R0, R0, Operand(R0, LSL, 3));
  __ eorw(R0, R0, Operand(R0, LSR, 11));
  __ addw(R0, R0, Operand(R0, LSL, 15));
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ AndImmediate(
      R0, R0, (static_cast<intptr_t>(1) << String::kHashBits) - 1);
  __ CompareRegisters(R0, ZR);
  // return hash_ == 0 ? 1 : hash_;
  __ Bind(&done);
  __ csinc(R0, R0, ZR, NE);  // R0 <- (R0 != 0) ? R0 : (ZR + 1).
  __ SmiTag(R0);
  __ str(R0, FieldAddress(R1, String::hash_offset()));
  __ ret();
}


// Allocates one-byte string of length 'end - start'. The content is not
// initialized.
// 'length-reg' (R2) contains tagged length.
// Returns new string as tagged pointer in R0.
static void TryAllocateOnebyteString(Assembler* assembler,
                                     Label* ok,
                                     Label* failure) {
  const Register length_reg = R2;
  Label fail;
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kOneByteStringCid, R0, failure));
  __ mov(R6, length_reg);  // Save the length register.
  // TODO(koda): Protect against negative length and overflow here.
  __ SmiUntag(length_reg);
  const intptr_t fixed_size = sizeof(RawString) + kObjectAlignment - 1;
  __ AddImmediate(length_reg, length_reg, fixed_size);
  __ andi(length_reg, length_reg, Immediate(~(kObjectAlignment - 1)));

  const intptr_t cid = kOneByteStringCid;
  Heap::Space space = Heap::kNew;
  __ ldr(R3, Address(THR, Thread::heap_offset()));
  __ ldr(R0, Address(R3, Heap::TopOffset(space)));

  // length_reg: allocation size.
  __ adds(R1, R0, Operand(length_reg));
  __ b(&fail, CS);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: potential next object start.
  // R2: allocation size.
  // R3: heap.
  __ ldr(R7, Address(R3, Heap::EndOffset(space)));
  __ cmp(R1, Operand(R7));
  __ b(&fail, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ str(R1, Address(R3, Heap::TopOffset(space)));
  __ AddImmediate(R0, R0, kHeapObjectTag);
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, R2, space));

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R1: new object end address.
  // R2: allocation size.
  {
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);
    __ LslImmediate(R2, R2, shift);
    __ csel(R2, R2, ZR, LS);

    // Get the class index and insert it into the tags.
    // R2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ orr(R2, R2, Operand(TMP));
    __ str(R2, FieldAddress(R0, String::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (R6).
  __ StoreIntoObjectNoBarrier(R0,
                              FieldAddress(R0, String::length_offset()),
                              R6);
  // Clear hash.
  __ mov(TMP, ZR);
  __ str(TMP, FieldAddress(R0, String::hash_offset()));
  __ b(ok);

  __ Bind(&fail);
  __ b(failure);
}


// Arg0: OneByteString (receiver).
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void Intrinsifier::OneByteString_substringUnchecked(Assembler* assembler) {
  const intptr_t kStringOffset = 2 * kWordSize;
  const intptr_t kStartIndexOffset = 1 * kWordSize;
  const intptr_t kEndIndexOffset = 0 * kWordSize;
  Label fall_through, ok;

  __ ldr(R2, Address(SP, kEndIndexOffset));
  __ ldr(TMP, Address(SP, kStartIndexOffset));
  __ orr(R3, R2,  Operand(TMP));
  __ tsti(R3, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // 'start', 'end' not Smi.

  __ sub(R2, R2, Operand(TMP));
  TryAllocateOnebyteString(assembler, &ok, &fall_through);
  __ Bind(&ok);
  // R0: new string as tagged pointer.
  // Copy string.
  __ ldr(R3, Address(SP, kStringOffset));
  __ ldr(R1, Address(SP, kStartIndexOffset));
  __ SmiUntag(R1);
  __ add(R3, R3, Operand(R1));
  // Calculate start address and untag (- 1).
  __ AddImmediate(R3, R3, OneByteString::data_offset() - 1);

  // R3: Start address to copy from (untagged).
  // R1: Untagged start index.
  __ ldr(R2, Address(SP, kEndIndexOffset));
  __ SmiUntag(R2);
  __ sub(R2, R2, Operand(R1));

  // R3: Start address to copy from (untagged).
  // R2: Untagged number of bytes to copy.
  // R0: Tagged result string.
  // R6: Pointer into R3.
  // R7: Pointer into R0.
  // R1: Scratch register.
  Label loop, done;
  __ cmp(R2, Operand(0));
  __ b(&done, LE);
  __ mov(R6, R3);
  __ mov(R7, R0);
  __ Bind(&loop);
  __ ldr(R1, Address(R6), kUnsignedByte);
  __ AddImmediate(R6, R6, 1);
  __ sub(R2, R2, Operand(1));
  __ cmp(R2, Operand(0));
  __ str(R1, FieldAddress(R7, OneByteString::data_offset()), kUnsignedByte);
  __ AddImmediate(R7, R7, 1);
  __ b(&loop, GT);

  __ Bind(&done);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::OneByteStringSetAt(Assembler* assembler) {
  __ ldr(R2, Address(SP, 0 * kWordSize));  // Value.
  __ ldr(R1, Address(SP, 1 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 2 * kWordSize));  // OneByteString.
  __ SmiUntag(R1);
  __ SmiUntag(R2);
  __ AddImmediate(R3, R0, OneByteString::data_offset() - kHeapObjectTag);
  __ str(R2, Address(R3, R1), kUnsignedByte);
  __ ret();
}


void Intrinsifier::OneByteString_allocate(Assembler* assembler) {
  Label fall_through, ok;

  __ ldr(R2, Address(SP, 0 * kWordSize));  // Length.
  TryAllocateOnebyteString(assembler, &ok, &fall_through);

  __ Bind(&ok);
  __ ret();

  __ Bind(&fall_through);
}


// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler, intptr_t string_cid) {
  Label fall_through, is_true, is_false, loop;
  __ ldr(R0, Address(SP, 1 * kWordSize));  // This.
  __ ldr(R1, Address(SP, 0 * kWordSize));  // Other.

  // Are identical?
  __ cmp(R0, Operand(R1));
  __ b(&is_true, EQ);

  // Is other OneByteString?
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, EQ);
  __ CompareClassId(R1, string_cid);
  __ b(&fall_through, NE);

  // Have same length?
  __ ldr(R2, FieldAddress(R0, String::length_offset()));
  __ ldr(R3, FieldAddress(R1, String::length_offset()));
  __ cmp(R2, Operand(R3));
  __ b(&is_false, NE);

  // Check contents, no fall-through possible.
  // TODO(zra): try out other sequences.
  ASSERT((string_cid == kOneByteStringCid) ||
         (string_cid == kTwoByteStringCid));
  const intptr_t offset = (string_cid == kOneByteStringCid) ?
      OneByteString::data_offset() : TwoByteString::data_offset();
  __ AddImmediate(R0, R0, offset - kHeapObjectTag);
  __ AddImmediate(R1, R1, offset - kHeapObjectTag);
  __ SmiUntag(R2);
  __ Bind(&loop);
  __ AddImmediate(R2, R2, -1);
  __ CompareRegisters(R2, ZR);
  __ b(&is_true, LT);
  if (string_cid == kOneByteStringCid) {
    __ ldr(R3, Address(R0), kUnsignedByte);
    __ ldr(R4, Address(R1), kUnsignedByte);
    __ AddImmediate(R0, R0, 1);
    __ AddImmediate(R1, R1, 1);
  } else if (string_cid == kTwoByteStringCid) {
    __ ldr(R3, Address(R0), kUnsignedHalfword);
    __ ldr(R4, Address(R1), kUnsignedHalfword);
    __ AddImmediate(R0, R0, 2);
    __ AddImmediate(R1, R1, 2);
  } else {
    UNIMPLEMENTED();
  }
  __ cmp(R3, Operand(R4));
  __ b(&is_false, NE);
  __ b(&loop);

  __ Bind(&is_true);
  __ LoadObject(R0, Bool::True());
  __ ret();

  __ Bind(&is_false);
  __ LoadObject(R0, Bool::False());
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::OneByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kOneByteStringCid);
}


void Intrinsifier::TwoByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kTwoByteStringCid);
}


void Intrinsifier::RegExp_ExecuteMatch(Assembler* assembler) {
  if (FLAG_interpret_irregexp) return;

  static const intptr_t kRegExpParamOffset = 2 * kWordSize;
  static const intptr_t kStringParamOffset = 1 * kWordSize;
  // start_index smi is located at offset 0.

  // Incoming registers:
  // R0: Function. (Will be reloaded with the specialized matcher function.)
  // R4: Arguments descriptor. (Will be preserved.)
  // R5: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into R0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ ldr(R2, Address(SP, kRegExpParamOffset));
  __ ldr(R1, Address(SP, kStringParamOffset));
  __ LoadClassId(R1, R1);
  __ AddImmediate(R1, R1, -kOneByteStringCid);
  __ add(R1, R2, Operand(R1, LSL, kWordSizeLog2));
  __ ldr(R0, FieldAddress(R1, RegExp::function_offset(kOneByteStringCid)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in R0, the argument descriptor in R4, and IC-Data in R5.
  __ eor(R5, R5, Operand(R5));

  // Tail-call the function.
  __ ldr(CODE_REG, FieldAddress(R0, Function::code_offset()));
  __ ldr(R1, FieldAddress(R0, Function::entry_point_offset()));
  __ br(R1);
}


// On stack: user tag (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  // R1: Isolate.
  __ LoadIsolate(R1);
  // R0: Current user tag.
  __ ldr(R0, Address(R1, Isolate::current_tag_offset()));
  // R2: UserTag.
  __ ldr(R2, Address(SP, + 0 * kWordSize));
  // Set Isolate::current_tag_.
  __ str(R2, Address(R1, Isolate::current_tag_offset()));
  // R2: UserTag's tag.
  __ ldr(R2, FieldAddress(R2, UserTag::tag_offset()));
  // Set Isolate::user_tag_.
  __ str(R2, Address(R1, Isolate::user_tag_offset()));
  __ ret();
}


void Intrinsifier::UserTag_defaultTag(Assembler* assembler) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, Isolate::default_tag_offset()));
  __ ret();
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, Isolate::current_tag_offset()));
  __ ret();
}


void Intrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler) {
  if (!FLAG_support_timeline) {
    __ LoadObject(R0, Bool::False());
    __ ret();
    return;
  }
  // Load TimelineStream*.
  __ ldr(R0, Address(THR, Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ ldr(R0, Address(R0, TimelineStream::enabled_offset()));
  __ cmp(R0, Operand(0));
  __ LoadObject(R0, Bool::False());
  __ LoadObject(TMP, Bool::True());
  __ csel(R0, TMP, R0, NE);
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
