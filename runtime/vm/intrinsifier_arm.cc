// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/cpu.h"
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
// The PP and THR registers (see constants_arm.h) must be preserved.

#define __ assembler->

intptr_t Intrinsifier::ParameterSlotFromSp() {
  return -1;
}

static bool IsABIPreservedRegister(Register reg) {
  return ((1 << reg) & kAbiPreservedCpuRegs) != 0;
}

void Intrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  ASSERT(IsABIPreservedRegister(CODE_REG));
  ASSERT(IsABIPreservedRegister(ARGS_DESC_REG));
  ASSERT(IsABIPreservedRegister(CALLEE_SAVED_TEMP));

  // Save LR by moving it to a callee saved temporary register.
  assembler->Comment("IntrinsicCallPrologue");
  assembler->mov(CALLEE_SAVED_TEMP, Operand(LR));
}

void Intrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  // Restore LR.
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->mov(LR, Operand(CALLEE_SAVED_TEMP));
}

// Intrinsify only for Smi value and index. Non-smi values need a store buffer
// update. Array length is always a Smi.
void Intrinsifier::ObjectArraySetIndexed(Assembler* assembler) {
  if (Isolate::Current()->type_checks()) {
    return;
  }

  Label fall_through;
  __ ldr(R1, Address(SP, 1 * kWordSize));  // Index.
  __ tst(R1, Operand(kSmiTagMask));
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
  __ add(R1, R0, Operand(R1, LSL, 1));     // R1 is Smi.
  __ StoreIntoObject(R0, FieldAddress(R1, Array::data_offset()), R2);
  // Caller is responsible for preserving the value if necessary.
  __ Ret();
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
      R0, FieldAddress(R0, GrowableObjectArray::data_offset()), R1);

  // R0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ ldr(R1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, GrowableObjectArray::type_arguments_offset()), R1);

  // Set the length field in the growable array object to 0.
  __ LoadImmediate(R1, 0);
  __ StoreIntoObjectNoBarrier(
      R0, FieldAddress(R0, GrowableObjectArray::length_offset()), R1);
  __ Ret();  // Returns the newly allocated object in R0.

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
  const int32_t value_one = reinterpret_cast<int32_t>(Smi::New(1));
  // len = len + 1;
  __ add(R3, R1, Operand(value_one));
  __ StoreIntoSmiField(FieldAddress(R0, GrowableObjectArray::length_offset()),
                       R3);
  __ ldr(R0, Address(SP, 0 * kWordSize));  // Value.
  ASSERT(kSmiTagShift == 1);
  __ add(R1, R2, Operand(R1, LSL, 1));
  __ StoreIntoObject(R2, FieldAddress(R1, Array::data_offset()), R0);
  __ LoadObject(R0, Object::null_object());
  __ Ret();
  __ Bind(&fall_through);
}

#define TYPED_ARRAY_ALLOCATION(type_name, cid, max_len, scale_shift)           \
  Label fall_through;                                                          \
  const intptr_t kArrayLengthStackOffset = 0 * kWordSize;                      \
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, R2, &fall_through));             \
  __ ldr(R2, Address(SP, kArrayLengthStackOffset)); /* Array length. */        \
  /* Check that length is a positive Smi. */                                   \
  /* R2: requested array length argument. */                                   \
  __ tst(R2, Operand(kSmiTagMask));                                            \
  __ b(&fall_through, NE);                                                     \
  __ CompareImmediate(R2, 0);                                                  \
  __ b(&fall_through, LT);                                                     \
  __ SmiUntag(R2);                                                             \
  /* Check for maximum allowed length. */                                      \
  /* R2: untagged array length. */                                             \
  __ CompareImmediate(R2, max_len);                                            \
  __ b(&fall_through, GT);                                                     \
  __ mov(R2, Operand(R2, LSL, scale_shift));                                   \
  const intptr_t fixed_size_plus_alignment_padding =                           \
      sizeof(Raw##type_name) + kObjectAlignment - 1;                           \
  __ AddImmediate(R2, fixed_size_plus_alignment_padding);                      \
  __ bic(R2, R2, Operand(kObjectAlignment - 1));                               \
  NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);                              \
  __ ldr(R0, Address(THR, Thread::top_offset()));                              \
                                                                               \
  /* R2: allocation size. */                                                   \
  __ adds(R1, R0, Operand(R2));                                                \
  __ b(&fall_through, CS); /* Fail on unsigned overflow. */                    \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* R0: potential new object start. */                                        \
  /* R1: potential next object start. */                                       \
  /* R2: allocation size. */                                                   \
  __ ldr(IP, Address(THR, Thread::end_offset()));                              \
  __ cmp(R1, Operand(IP));                                                     \
  __ b(&fall_through, CS);                                                     \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R4, cid));                      \
  __ str(R1, Address(THR, Thread::top_offset()));                              \
  __ AddImmediate(R0, kHeapObjectTag);                                         \
  /* Initialize the tags. */                                                   \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: allocation size. */                                                   \
  /* R4: allocation stats address */                                           \
  {                                                                            \
    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);                  \
    __ mov(R3,                                                                 \
           Operand(R2, LSL, RawObject::kSizeTagPos - kObjectAlignmentLog2),    \
           LS);                                                                \
    __ mov(R3, Operand(0), HI);                                                \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));                 \
    __ orr(R3, R3, Operand(TMP));                                              \
    __ str(R3, FieldAddress(R0, type_name::tags_offset())); /* Tags. */        \
  }                                                                            \
  /* Set the length field. */                                                  \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: allocation size. */                                                   \
  /* R4: allocation stats address. */                                          \
  __ ldr(R3, Address(SP, kArrayLengthStackOffset)); /* Array length. */        \
  __ StoreIntoObjectNoBarrier(                                                 \
      R0, FieldAddress(R0, type_name::length_offset()), R3);                   \
  /* Initialize all array elements to 0. */                                    \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: allocation size. */                                                   \
  /* R3: iterator which initially points to the start of the variable */       \
  /* R4: allocation stats address */                                           \
  /* R8, R9: zero. */                                                          \
  /* data area to be initialized. */                                           \
  __ LoadImmediate(R8, 0);                                                     \
  __ mov(R9, Operand(R8));                                                     \
  __ AddImmediate(R3, R0, sizeof(Raw##type_name) - 1);                         \
  Label init_loop;                                                             \
  __ Bind(&init_loop);                                                         \
  __ AddImmediate(R3, 2 * kWordSize);                                          \
  __ cmp(R3, Operand(R1));                                                     \
  __ strd(R8, R9, R3, -2 * kWordSize, LS);                                     \
  __ b(&init_loop, CC);                                                        \
  __ str(R8, Address(R3, -2 * kWordSize), HI);                                 \
                                                                               \
  NOT_IN_PRODUCT(__ IncrementAllocationStatsWithSize(R4, R2, space));          \
  __ Ret();                                                                    \
  __ Bind(&fall_through);

static int GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1:
      return 0;
    case 2:
      return 1;
    case 4:
      return 2;
    case 8:
      return 3;
    case 16:
      return 4;
  }
  UNREACHABLE();
  return -1;
}

#define TYPED_DATA_ALLOCATOR(clazz)                                            \
  void Intrinsifier::TypedData_##clazz##_factory(Assembler* assembler) {       \
    intptr_t size = TypedData::ElementSizeInBytes(kTypedData##clazz##Cid);     \
    intptr_t max_len = TypedData::MaxElements(kTypedData##clazz##Cid);         \
    int shift = GetScaleFactor(size);                                          \
    TYPED_ARRAY_ALLOCATION(TypedData, kTypedData##clazz##Cid, max_len, shift); \
  }
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATOR)
#undef TYPED_DATA_ALLOCATOR

// Loads args from stack into R0 and R1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ ldr(R0, Address(SP, +0 * kWordSize));
  __ ldr(R1, Address(SP, +1 * kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(not_smi, NE);
  return;
}

void Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ adds(R0, R0, Operand(R1));                     // Adds.
  __ bx(LR, VC);                                    // Return if no overflow.
  // Otherwise fall through.
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_add(Assembler* assembler) {
  Integer_addFromInteger(assembler);
}

void Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ subs(R0, R0, Operand(R1));  // Subtract.
  __ bx(LR, VC);                 // Return if no overflow.
  // Otherwise fall through.
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_sub(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ subs(R0, R1, Operand(R0));  // Subtract.
  __ bx(LR, VC);                 // Return if no overflow.
  // Otherwise fall through.
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ SmiUntag(R0);           // Untags R0. We only want result shifted by one.
  __ smull(R0, IP, R0, R1);  // IP:R0 <- R0 * R1.
  __ cmp(IP, Operand(R0, ASR, 31));
  __ bx(LR, EQ);
  __ Bind(&fall_through);  // Fall through on overflow.
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
  Label modulo;
  const Register left = R1;
  const Register right = R0;
  const Register result = R1;
  const Register tmp = R2;
  ASSERT(left == result);

  // Check for quick zero results.
  __ cmp(left, Operand(0));
  __ mov(R0, Operand(0), EQ);
  __ bx(LR, EQ);  // left is 0? Return 0.
  __ cmp(left, Operand(right));
  __ mov(R0, Operand(0), EQ);
  __ bx(LR, EQ);  // left == right? Return 0.

  // Check if result should be left.
  __ cmp(left, Operand(0));
  __ b(&modulo, LT);
  // left is positive.
  __ cmp(left, Operand(right));
  // left is less than right, result is left.
  __ mov(R0, Operand(left), LT);
  __ bx(LR, LT);

  __ Bind(&modulo);
  // result <- left - right * (left / right)
  __ SmiUntag(left);
  __ SmiUntag(right);

  __ IntegerDivide(tmp, left, right, D1, D0);

  __ mls(result, right, tmp, left);  // result <- left - right * TMP
  return;
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
  if (!TargetCPUFeatures::can_divide()) {
    return;
  }
  // Check to see if we have integer division
  Label fall_through;
  __ ldr(R1, Address(SP, +0 * kWordSize));
  __ ldr(R0, Address(SP, +1 * kWordSize));
  __ orr(TMP, R0, Operand(R1));
  __ tst(TMP, Operand(kSmiTagMask));
  __ b(&fall_through, NE);
  // R1: Tagged left (dividend).
  // R0: Tagged right (divisor).
  // Check if modulo by zero -> exception thrown in main function.
  __ cmp(R0, Operand(0));
  __ b(&fall_through, EQ);
  EmitRemainderOperation(assembler);
  // Untagged right in R0. Untagged remainder result in R1.

  __ cmp(R1, Operand(0));
  __ mov(R0, Operand(R1, LSL, 1), GE);  // Tag and move result to R0.
  __ bx(LR, GE);

  // Result is negative, adjust it.
  __ cmp(R0, Operand(0));
  __ sub(R0, R1, Operand(R0), LT);
  __ add(R0, R1, Operand(R0), GE);
  __ SmiTag(R0);
  __ Ret();

  __ Bind(&fall_through);
}

void Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  if (!TargetCPUFeatures::can_divide()) {
    return;
  }
  // Check to see if we have integer division
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ cmp(R0, Operand(0));
  __ b(&fall_through, EQ);  // If b is 0, fall through.

  __ SmiUntag(R0);
  __ SmiUntag(R1);

  __ IntegerDivide(R0, R1, R0, D1, D0);

  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ CompareImmediate(R0, 0x40000000);
  __ SmiTag(R0, NE);  // Not equal. Okay to tag and return.
  __ bx(LR, NE);      // Return.
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_negate(Assembler* assembler) {
  Label fall_through;
  __ ldr(R0, Address(SP, +0 * kWordSize));  // Grab first argument.
  __ tst(R0, Operand(kSmiTagMask));         // Test for Smi.
  __ b(&fall_through, NE);
  __ rsbs(R0, R0, Operand(0));  // R0 is a Smi. R0 <- 0 - R0.
  __ bx(LR, VC);  // Return if there wasn't overflow, fall through otherwise.
  // R0 is not a Smi. Fall through.
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ and_(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}

void Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ orr(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_bitOr(Assembler* assembler) {
  Integer_bitOrFromInteger(assembler);
}

void Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ eor(R0, R0, Operand(R1));

  __ Ret();
  __ Bind(&fall_through);
}

void Intrinsifier::Integer_bitXor(Assembler* assembler) {
  Integer_bitXorFromInteger(assembler);
}

void Intrinsifier::Integer_shl(Assembler* assembler) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ CompareImmediate(R0, Smi::RawValue(Smi::kBits));
  __ b(&fall_through, HI);

  __ SmiUntag(R0);

  // Check for overflow by shifting left and shifting back arithmetically.
  // If the result is different from the original, there was overflow.
  __ mov(IP, Operand(R1, LSL, R0));
  __ cmp(R1, Operand(IP, ASR, R0));

  // No overflow, result in R0.
  __ mov(R0, Operand(R1, LSL, R0), EQ);
  __ bx(LR, EQ);

  // Arguments are Smi but the shift produced an overflow to Mint.
  __ CompareImmediate(R1, 0);
  __ b(&fall_through, LT);
  __ SmiUntag(R1);

  // Pull off high bits that will be shifted off of R1 by making a mask
  // ((1 << R0) - 1), shifting it to the left, masking R1, then shifting back.
  // high bits = (((1 << R0) - 1) << (32 - R0)) & R1) >> (32 - R0)
  // lo bits = R1 << R0
  __ LoadImmediate(NOTFP, 1);
  __ mov(NOTFP, Operand(NOTFP, LSL, R0));  // NOTFP <- 1 << R0
  __ sub(NOTFP, NOTFP, Operand(1));        // NOTFP <- NOTFP - 1
  __ rsb(R3, R0, Operand(32));             // R3 <- 32 - R0
  __ mov(NOTFP, Operand(NOTFP, LSL, R3));  // NOTFP <- NOTFP << R3
  __ and_(NOTFP, R1, Operand(NOTFP));      // NOTFP <- NOTFP & R1
  __ mov(NOTFP, Operand(NOTFP, LSR, R3));  // NOTFP <- NOTFP >> R3
  // Now NOTFP has the bits that fall off of R1 on a left shift.
  __ mov(R1, Operand(R1, LSL, R0));  // R1 gets the low bits.

  const Class& mint_class =
      Class::Handle(Isolate::Current()->object_store()->mint_class());
  __ TryAllocate(mint_class, &fall_through, R0, R2);

  __ str(R1, FieldAddress(R0, Mint::value_offset()));
  __ str(NOTFP, FieldAddress(R0, Mint::value_offset() + kWordSize));
  __ Ret();
  __ Bind(&fall_through);
}

static void Get64SmiOrMint(Assembler* assembler,
                           Register res_hi,
                           Register res_lo,
                           Register reg,
                           Label* not_smi_or_mint) {
  Label not_smi, done;
  __ tst(reg, Operand(kSmiTagMask));
  __ b(&not_smi, NE);
  __ SmiUntag(reg);

  // Sign extend to 64 bit
  __ mov(res_lo, Operand(reg));
  __ mov(res_hi, Operand(res_lo, ASR, 31));
  __ b(&done);

  __ Bind(&not_smi);
  __ CompareClassId(reg, kMintCid, res_lo);
  __ b(not_smi_or_mint, NE);

  // Mint.
  __ ldr(res_lo, FieldAddress(reg, Mint::value_offset()));
  __ ldr(res_hi, FieldAddress(reg, Mint::value_offset() + kWordSize));
  __ Bind(&done);
  return;
}

static void CompareIntegers(Assembler* assembler, Condition true_condition) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // R0 contains the right argument. R1 contains left argument

  __ cmp(R1, Operand(R0));
  __ b(&is_true, true_condition);
  __ Bind(&is_false);
  __ LoadObject(R0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(R0, Bool::True());
  __ Ret();

  // 64-bit comparison
  Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (true_condition) {
    case LT:
    case LE:
      hi_true_cond = LT;
      hi_false_cond = GT;
      lo_false_cond = (true_condition == LT) ? CS : HI;
      break;
    case GT:
    case GE:
      hi_true_cond = GT;
      hi_false_cond = LT;
      lo_false_cond = (true_condition == GT) ? LS : CC;
      break;
    default:
      UNREACHABLE();
      hi_true_cond = hi_false_cond = lo_false_cond = VS;
  }

  __ Bind(&try_mint_smi);
  // Get left as 64 bit integer.
  Get64SmiOrMint(assembler, R3, R2, R1, &fall_through);
  // Get right as 64 bit integer.
  Get64SmiOrMint(assembler, NOTFP, R8, R0, &fall_through);
  // R3: left high.
  // R2: left low.
  // NOTFP: right high.
  // R8: right low.

  __ cmp(R3, Operand(NOTFP));  // Compare left hi, right high.
  __ b(&is_false, hi_false_cond);
  __ b(&is_true, hi_true_cond);
  __ cmp(R2, Operand(R8));  // Compare left lo, right lo.
  __ b(&is_false, lo_false_cond);
  // Else is true.
  __ b(&is_true);

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
  __ tst(R2, Operand(kSmiTagMask));
  __ b(&check_for_mint, NE);  // If R0 or R1 is not a smi do Mint checks.

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(R0, Bool::False());
  __ Ret();
  __ Bind(&true_label);
  __ LoadObject(R0, Bool::True());
  __ Ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ tst(R1, Operand(kSmiTagMask));  // Check receiver.
  __ b(&receiver_not_smi, NE);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint or Bigint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(R0, kDoubleCid, R2);
  __ b(&fall_through, EQ);
  __ LoadObject(R0, Bool::False());  // Smi == Mint -> false.
  __ Ret();

  __ Bind(&receiver_not_smi);
  // R1:: receiver.

  __ CompareClassId(R1, kMintCid, R2);
  __ b(&fall_through, NE);
  // Receiver is Mint, return false if right is Smi.
  __ tst(R0, Operand(kSmiTagMask));
  __ LoadObject(R0, Bool::False(), EQ);
  __ bx(LR, EQ);
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
  __ CompareImmediate(R0, 0);
  __ b(&fall_through, LT);

  // If shift amount is bigger than 31, set to 31.
  __ CompareImmediate(R0, 0x1F);
  __ LoadImmediate(R0, 0x1F, GT);
  __ SmiUntag(R1);
  __ mov(R0, Operand(R1, ASR, R0));
  __ SmiTag(R0);
  __ Ret();
  __ Bind(&fall_through);
}

void Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ mvn(R0, Operand(R0));
  __ bic(R0, R0, Operand(kSmiTagMask));  // Remove inverted smi-tag.
  __ Ret();
}

void Intrinsifier::Smi_bitLength(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ SmiUntag(R0);
  // XOR with sign bit to complement bits if value is negative.
  __ eor(R0, R0, Operand(R0, ASR, 31));
  __ clz(R0, R0);
  __ rsb(R0, R0, Operand(32));
  __ SmiTag(R0);
  __ Ret();
}

void Intrinsifier::Smi_bitAndFromSmi(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}

void Intrinsifier::Bigint_lsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R0 = x_used, R1 = x_digits, x_used > 0, x_used is Smi.
  __ ldrd(R0, R1, SP, 2 * kWordSize);
  // R2 = r_digits, R3 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldrd(R2, R3, SP, 0 * kWordSize);
  __ SmiUntag(R3);
  // R4 = n ~/ _DIGIT_BITS
  __ Asr(R4, R3, Operand(5));
  // R8 = &x_digits[0]
  __ add(R8, R1, Operand(TypedData::data_offset() - kHeapObjectTag));
  // NOTFP = &x_digits[x_used]
  __ add(NOTFP, R8, Operand(R0, LSL, 1));
  // R6 = &r_digits[1]
  __ add(R6, R2,
         Operand(TypedData::data_offset() - kHeapObjectTag +
                 Bigint::kBytesPerDigit));
  // R6 = &r_digits[x_used + n ~/ _DIGIT_BITS + 1]
  __ add(R4, R4, Operand(R0, ASR, 1));
  __ add(R6, R6, Operand(R4, LSL, 2));
  // R1 = n % _DIGIT_BITS
  __ and_(R1, R3, Operand(31));
  // R0 = 32 - R1
  __ rsb(R0, R1, Operand(32));
  __ mov(R9, Operand(0));
  Label loop;
  __ Bind(&loop);
  __ ldr(R4, Address(NOTFP, -Bigint::kBytesPerDigit, Address::PreIndex));
  __ orr(R9, R9, Operand(R4, LSR, R0));
  __ str(R9, Address(R6, -Bigint::kBytesPerDigit, Address::PreIndex));
  __ mov(R9, Operand(R4, LSL, R1));
  __ teq(NOTFP, Operand(R8));
  __ b(&loop, NE);
  __ str(R9, Address(R6, -Bigint::kBytesPerDigit, Address::PreIndex));
  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}

void Intrinsifier::Bigint_rsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // R0 = x_used, R1 = x_digits, x_used > 0, x_used is Smi.
  __ ldrd(R0, R1, SP, 2 * kWordSize);
  // R2 = r_digits, R3 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ ldrd(R2, R3, SP, 0 * kWordSize);
  __ SmiUntag(R3);
  // R4 = n ~/ _DIGIT_BITS
  __ Asr(R4, R3, Operand(5));
  // R6 = &r_digits[0]
  __ add(R6, R2, Operand(TypedData::data_offset() - kHeapObjectTag));
  // NOTFP = &x_digits[n ~/ _DIGIT_BITS]
  __ add(NOTFP, R1, Operand(TypedData::data_offset() - kHeapObjectTag));
  __ add(NOTFP, NOTFP, Operand(R4, LSL, 2));
  // R8 = &r_digits[x_used - n ~/ _DIGIT_BITS - 1]
  __ add(R4, R4, Operand(1));
  __ rsb(R4, R4, Operand(R0, ASR, 1));
  __ add(R8, R6, Operand(R4, LSL, 2));
  // R1 = n % _DIGIT_BITS
  __ and_(R1, R3, Operand(31));
  // R0 = 32 - R1
  __ rsb(R0, R1, Operand(32));
  // R9 = x_digits[n ~/ _DIGIT_BITS] >> (n % _DIGIT_BITS)
  __ ldr(R9, Address(NOTFP, Bigint::kBytesPerDigit, Address::PostIndex));
  __ mov(R9, Operand(R9, LSR, R1));
  Label loop_entry;
  __ b(&loop_entry);
  Label loop;
  __ Bind(&loop);
  __ ldr(R4, Address(NOTFP, Bigint::kBytesPerDigit, Address::PostIndex));
  __ orr(R9, R9, Operand(R4, LSL, R0));
  __ str(R9, Address(R6, Bigint::kBytesPerDigit, Address::PostIndex));
  __ mov(R9, Operand(R4, LSR, R1));
  __ Bind(&loop_entry);
  __ teq(R6, Operand(R8));
  __ b(&loop, NE);
  __ str(R9, Address(R6, 0));
  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}

void Intrinsifier::Bigint_absAdd(Assembler* assembler) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R0 = used, R1 = digits
  __ ldrd(R0, R1, SP, 3 * kWordSize);
  // R1 = &digits[0]
  __ add(R1, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R2 = a_used, R3 = a_digits
  __ ldrd(R2, R3, SP, 1 * kWordSize);
  // R3 = &a_digits[0]
  __ add(R3, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R8 = r_digits
  __ ldr(R8, Address(SP, 0 * kWordSize));
  // R8 = &r_digits[0]
  __ add(R8, R8, Operand(TypedData::data_offset() - kHeapObjectTag));

  // NOTFP = &digits[a_used >> 1], a_used is Smi.
  __ add(NOTFP, R1, Operand(R2, LSL, 1));

  // R6 = &digits[used >> 1], used is Smi.
  __ add(R6, R1, Operand(R0, LSL, 1));

  __ adds(R4, R4, Operand(0));  // carry flag = 0
  Label add_loop;
  __ Bind(&add_loop);
  // Loop a_used times, a_used > 0.
  __ ldr(R4, Address(R1, Bigint::kBytesPerDigit, Address::PostIndex));
  __ ldr(R9, Address(R3, Bigint::kBytesPerDigit, Address::PostIndex));
  __ adcs(R4, R4, Operand(R9));
  __ teq(R1, Operand(NOTFP));  // Does not affect carry flag.
  __ str(R4, Address(R8, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&add_loop, NE);

  Label last_carry;
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ b(&last_carry, EQ);    // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ ldr(R4, Address(R1, Bigint::kBytesPerDigit, Address::PostIndex));
  __ adcs(R4, R4, Operand(0));
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ str(R4, Address(R8, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&carry_loop, NE);

  __ Bind(&last_carry);
  __ mov(R4, Operand(0));
  __ adc(R4, R4, Operand(0));
  __ str(R4, Address(R8, 0));

  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}

void Intrinsifier::Bigint_absSub(Assembler* assembler) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // R0 = used, R1 = digits
  __ ldrd(R0, R1, SP, 3 * kWordSize);
  // R1 = &digits[0]
  __ add(R1, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R2 = a_used, R3 = a_digits
  __ ldrd(R2, R3, SP, 1 * kWordSize);
  // R3 = &a_digits[0]
  __ add(R3, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R8 = r_digits
  __ ldr(R8, Address(SP, 0 * kWordSize));
  // R8 = &r_digits[0]
  __ add(R8, R8, Operand(TypedData::data_offset() - kHeapObjectTag));

  // NOTFP = &digits[a_used >> 1], a_used is Smi.
  __ add(NOTFP, R1, Operand(R2, LSL, 1));

  // R6 = &digits[used >> 1], used is Smi.
  __ add(R6, R1, Operand(R0, LSL, 1));

  __ subs(R4, R4, Operand(0));  // carry flag = 1
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop a_used times, a_used > 0.
  __ ldr(R4, Address(R1, Bigint::kBytesPerDigit, Address::PostIndex));
  __ ldr(R9, Address(R3, Bigint::kBytesPerDigit, Address::PostIndex));
  __ sbcs(R4, R4, Operand(R9));
  __ teq(R1, Operand(NOTFP));  // Does not affect carry flag.
  __ str(R4, Address(R8, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&sub_loop, NE);

  Label done;
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ b(&done, EQ);          // If used - a_used == 0.

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ ldr(R4, Address(R1, Bigint::kBytesPerDigit, Address::PostIndex));
  __ sbcs(R4, R4, Operand(0));
  __ teq(R1, Operand(R6));  // Does not affect carry flag.
  __ str(R4, Address(R8, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&carry_loop, NE);

  __ Bind(&done);
  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}

void Intrinsifier::Bigint_mulAdd(Assembler* assembler) {
  // Pseudo code:
  // static int _mulAdd(Uint32List x_digits, int xi,
  //                    Uint32List m_digits, int i,
  //                    Uint32List a_digits, int j, int n) {
  //   uint32_t x = x_digits[xi >> 1];  // xi is Smi.
  //   if (x == 0 || n == 0) {
  //     return 1;
  //   }
  //   uint32_t* mip = &m_digits[i >> 1];  // i is Smi.
  //   uint32_t* ajp = &a_digits[j >> 1];  // j is Smi.
  //   uint32_t c = 0;
  //   SmiUntag(n);
  //   do {
  //     uint32_t mi = *mip++;
  //     uint32_t aj = *ajp;
  //     uint64_t t = x*mi + aj + c;  // 32-bit * 32-bit -> 64-bit.
  //     *ajp++ = low32(t);
  //     c = high32(t);
  //   } while (--n > 0);
  //   while (c != 0) {
  //     uint64_t t = *ajp + c;
  //     *ajp++ = low32(t);
  //     c = high32(t);  // c == 0 or 1.
  //   }
  //   return 1;
  // }

  Label done;
  // R3 = x, no_op if x == 0
  __ ldrd(R0, R1, SP, 5 * kWordSize);  // R0 = xi as Smi, R1 = x_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R3, FieldAddress(R1, TypedData::data_offset()));
  __ tst(R3, Operand(R3));
  __ b(&done, EQ);

  // R8 = SmiUntag(n), no_op if n == 0
  __ ldr(R8, Address(SP, 0 * kWordSize));
  __ Asrs(R8, R8, Operand(kSmiTagSize));
  __ b(&done, EQ);

  // R4 = mip = &m_digits[i >> 1]
  __ ldrd(R0, R1, SP, 3 * kWordSize);  // R0 = i as Smi, R1 = m_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R4, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R9 = ajp = &a_digits[j >> 1]
  __ ldrd(R0, R1, SP, 1 * kWordSize);  // R0 = j as Smi, R1 = a_digits.
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ add(R9, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R1 = c = 0
  __ mov(R1, Operand(0));

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   R3
  // mip: R4
  // ajp: R9
  // c:   R1
  // n:   R8

  // uint32_t mi = *mip++
  __ ldr(R2, Address(R4, Bigint::kBytesPerDigit, Address::PostIndex));

  // uint32_t aj = *ajp
  __ ldr(R0, Address(R9, 0));

  // uint64_t t = x*mi + aj + c
  __ umaal(R0, R1, R2, R3);  // R1:R0 = R2*R3 + R1 + R0.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(R9, Bigint::kBytesPerDigit, Address::PostIndex));

  // c = high32(t) = R1

  // while (--n > 0)
  __ subs(R8, R8, Operand(1));  // --n
  __ b(&muladd_loop, NE);

  __ tst(R1, Operand(R1));
  __ b(&done, EQ);

  // *ajp++ += c
  __ ldr(R0, Address(R9, 0));
  __ adds(R0, R0, Operand(R1));
  __ str(R0, Address(R9, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&done, CC);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ ldr(R0, Address(R9, 0));
  __ adds(R0, R0, Operand(1));
  __ str(R0, Address(R9, Bigint::kBytesPerDigit, Address::PostIndex));
  __ b(&propagate_carry_loop, CS);

  __ Bind(&done);
  __ mov(R0, Operand(Smi::RawValue(1)));  // One digit processed.
  __ Ret();
}

void Intrinsifier::Bigint_sqrAdd(Assembler* assembler) {
  // Pseudo code:
  // static int _sqrAdd(Uint32List x_digits, int i,
  //                    Uint32List a_digits, int used) {
  //   uint32_t* xip = &x_digits[i >> 1];  // i is Smi.
  //   uint32_t x = *xip++;
  //   if (x == 0) return 1;
  //   uint32_t* ajp = &a_digits[i];  // j == 2*i, i is Smi.
  //   uint32_t aj = *ajp;
  //   uint64_t t = x*x + aj;
  //   *ajp++ = low32(t);
  //   uint64_t c = high32(t);
  //   int n = ((used - i) >> 1) - 1;  // used and i are Smi.
  //   while (--n >= 0) {
  //     uint32_t xi = *xip++;
  //     uint32_t aj = *ajp;
  //     uint96_t t = 2*x*xi + aj + c;  // 2-bit * 32-bit * 32-bit -> 65-bit.
  //     *ajp++ = low32(t);
  //     c = high64(t);  // 33-bit.
  //   }
  //   uint32_t aj = *ajp;
  //   uint64_t t = aj + c;  // 32-bit + 33-bit -> 34-bit.
  //   *ajp++ = low32(t);
  //   *ajp = high32(t);
  //   return 1;
  // }

  // R4 = xip = &x_digits[i >> 1]
  __ ldrd(R2, R3, SP, 2 * kWordSize);  // R2 = i as Smi, R3 = x_digits
  __ add(R3, R3, Operand(R2, LSL, 1));
  __ add(R4, R3, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R3 = x = *xip++, return if x == 0
  Label x_zero;
  __ ldr(R3, Address(R4, Bigint::kBytesPerDigit, Address::PostIndex));
  __ tst(R3, Operand(R3));
  __ b(&x_zero, EQ);

  // NOTFP = ajp = &a_digits[i]
  __ ldr(R1, Address(SP, 1 * kWordSize));  // a_digits
  __ add(R1, R1, Operand(R2, LSL, 2));     // j == 2*i, i is Smi.
  __ add(NOTFP, R1, Operand(TypedData::data_offset() - kHeapObjectTag));

  // R8:R0 = t = x*x + *ajp
  __ ldr(R0, Address(NOTFP, 0));
  __ mov(R8, Operand(0));
  __ umaal(R0, R8, R3, R3);  // R8:R0 = R3*R3 + R8 + R0.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(NOTFP, Bigint::kBytesPerDigit, Address::PostIndex));

  // R8 = low32(c) = high32(t)
  // R9 = high32(c) = 0
  __ mov(R9, Operand(0));

  // int n = used - i - 1; while (--n >= 0) ...
  __ ldr(R0, Address(SP, 0 * kWordSize));  // used is Smi
  __ sub(R6, R0, Operand(R2));
  __ mov(R0, Operand(2));  // n = used - i - 2; if (n >= 0) ... while (--n >= 0)
  __ rsbs(R6, R0, Operand(R6, ASR, kSmiTagSize));

  Label loop, done;
  __ b(&done, MI);

  __ Bind(&loop);
  // x:   R3
  // xip: R4
  // ajp: NOTFP
  // c:   R9:R8
  // t:   R2:R1:R0 (not live at loop entry)
  // n:   R6

  // uint32_t xi = *xip++
  __ ldr(R2, Address(R4, Bigint::kBytesPerDigit, Address::PostIndex));

  // uint96_t t = R9:R8:R0 = 2*x*xi + aj + c
  __ umull(R0, R1, R2, R3);  // R1:R0 = R2*R3.
  __ adds(R0, R0, Operand(R0));
  __ adcs(R1, R1, Operand(R1));
  __ mov(R2, Operand(0));
  __ adc(R2, R2, Operand(0));  // R2:R1:R0 = 2*x*xi.
  __ adds(R0, R0, Operand(R8));
  __ adcs(R1, R1, Operand(R9));
  __ adc(R2, R2, Operand(0));     // R2:R1:R0 = 2*x*xi + c.
  __ ldr(R8, Address(NOTFP, 0));  // R8 = aj = *ajp.
  __ adds(R0, R0, Operand(R8));
  __ adcs(R8, R1, Operand(0));
  __ adc(R9, R2, Operand(0));  // R9:R8:R0 = 2*x*xi + c + aj.

  // *ajp++ = low32(t) = R0
  __ str(R0, Address(NOTFP, Bigint::kBytesPerDigit, Address::PostIndex));

  // while (--n >= 0)
  __ subs(R6, R6, Operand(1));  // --n
  __ b(&loop, PL);

  __ Bind(&done);
  // uint32_t aj = *ajp
  __ ldr(R0, Address(NOTFP, 0));

  // uint64_t t = aj + c
  __ adds(R8, R8, Operand(R0));
  __ adc(R9, R9, Operand(0));

  // *ajp = low32(t) = R8
  // *(ajp + 1) = high32(t) = R9
  __ strd(R8, R9, NOTFP, 0);

  __ Bind(&x_zero);
  __ mov(R0, Operand(Smi::RawValue(1)));  // One digit processed.
  __ Ret();
}

void Intrinsifier::Bigint_estQuotientDigit(Assembler* assembler) {
  // No unsigned 64-bit / 32-bit divide instruction.
}

void Intrinsifier::Montgomery_mulMod(Assembler* assembler) {
  // Pseudo code:
  // static int _mulMod(Uint32List args, Uint32List digits, int i) {
  //   uint32_t rho = args[_RHO];  // _RHO == 2.
  //   uint32_t d = digits[i >> 1];  // i is Smi.
  //   uint64_t t = rho*d;
  //   args[_MU] = t mod DIGIT_BASE;  // _MU == 4.
  //   return 1;
  // }

  // R4 = args
  __ ldr(R4, Address(SP, 2 * kWordSize));  // args

  // R3 = rho = args[2]
  __ ldr(R3, FieldAddress(
                 R4, TypedData::data_offset() + 2 * Bigint::kBytesPerDigit));

  // R2 = digits[i >> 1]
  __ ldrd(R0, R1, SP, 0 * kWordSize);  // R0 = i as Smi, R1 = digits
  __ add(R1, R1, Operand(R0, LSL, 1));
  __ ldr(R2, FieldAddress(R1, TypedData::data_offset()));

  // R1:R0 = t = rho*d
  __ umull(R0, R1, R2, R3);

  // args[4] = t mod DIGIT_BASE = low32(t)
  __ str(R0, FieldAddress(
                 R4, TypedData::data_offset() + 4 * Bigint::kBytesPerDigit));

  __ mov(R0, Operand(Smi::RawValue(1)));  // One digit processed.
  __ Ret();
}

// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in R0.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ tst(R0, Operand(kSmiTagMask));
  __ b(is_smi, EQ);
  __ CompareClassId(R0, kDoubleCid, R1);
  __ b(not_double_smi, NE);
  // Fall through with Double in R0.
}

// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register R0. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler, Condition true_condition) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through, is_smi, double_op;

    TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
    // Both arguments are double, right operand is in R0.

    __ LoadDFromOffset(D1, R0, Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);

    __ vcmpd(D0, D1);
    __ vmstat();
    __ LoadObject(R0, Bool::False());
    // Return false if D0 or D1 was NaN before checking true condition.
    __ bx(LR, VS);
    __ LoadObject(R0, Bool::True(), true_condition);
    __ Ret();

    __ Bind(&is_smi);  // Convert R0 to a double.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);  // Then do the comparison.
    __ Bind(&fall_through);
  }
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
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through, is_smi, double_op;

    TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
    // Both arguments are double, right operand is in R0.
    __ LoadDFromOffset(D1, R0, Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    switch (kind) {
      case Token::kADD:
        __ vaddd(D0, D0, D1);
        break;
      case Token::kSUB:
        __ vsubd(D0, D0, D1);
        break;
      case Token::kMUL:
        __ vmuld(D0, D0, D1);
        break;
      case Token::kDIV:
        __ vdivd(D0, D0, D1);
        break;
      default:
        UNREACHABLE();
    }
    const Class& double_class =
        Class::Handle(Isolate::Current()->object_store()->double_class());
    __ TryAllocate(double_class, &fall_through, R0, R1);  // Result register.
    __ StoreDToOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&is_smi);  // Convert R0 to a double.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);
    __ Bind(&fall_through);
  }
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
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;
    // Only smis allowed.
    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ tst(R0, Operand(kSmiTagMask));
    __ b(&fall_through, NE);
    // Is Smi.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ ldr(R0, Address(SP, 1 * kWordSize));
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ vmuld(D0, D0, D1);
    const Class& double_class =
        Class::Handle(Isolate::Current()->object_store()->double_class());
    __ TryAllocate(double_class, &fall_through, R0, R1);  // Result register.
    __ StoreDToOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&fall_through);
  }
}

void Intrinsifier::DoubleFromInteger(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;

    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ tst(R0, Operand(kSmiTagMask));
    __ b(&fall_through, NE);
    // Is Smi.
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D0, S0);
    const Class& double_class =
        Class::Handle(Isolate::Current()->object_store()->double_class());
    __ TryAllocate(double_class, &fall_through, R0, R1);  // Result register.
    __ StoreDToOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&fall_through);
  }
}

void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_true;
    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ vcmpd(D0, D0);
    __ vmstat();
    __ LoadObject(R0, Bool::False(), VC);
    __ LoadObject(R0, Bool::True(), VS);
    __ Ret();
  }
}

void Intrinsifier::Double_getIsInfinite(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    __ ldr(R0, Address(SP, 0 * kWordSize));
    // R1 <- value[0:31], R2 <- value[32:63]
    __ LoadFieldFromOffset(kWord, R1, R0, Double::value_offset());
    __ LoadFieldFromOffset(kWord, R2, R0, Double::value_offset() + kWordSize);

    // If the low word isn't 0, then it isn't infinity.
    __ cmp(R1, Operand(0));
    __ LoadObject(R0, Bool::False(), NE);
    __ bx(LR, NE);  // Return if NE.

    // Mask off the sign bit.
    __ AndImmediate(R2, R2, 0x7FFFFFFF);
    // Compare with +infinity.
    __ CompareImmediate(R2, 0x7FF00000);
    __ LoadObject(R0, Bool::False(), NE);
    __ bx(LR, NE);

    __ LoadObject(R0, Bool::True());
    __ Ret();
  }
}

void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label is_false, is_true, is_zero;
    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ vcmpdz(D0);
    __ vmstat();
    __ b(&is_false, VS);  // NaN -> false.
    __ b(&is_zero, EQ);   // Check for negative zero.
    __ b(&is_false, CS);  // >= 0 -> false.

    __ Bind(&is_true);
    __ LoadObject(R0, Bool::True());
    __ Ret();

    __ Bind(&is_false);
    __ LoadObject(R0, Bool::False());
    __ Ret();

    __ Bind(&is_zero);
    // Check for negative zero by looking at the sign bit.
    __ vmovrrd(R0, R1, D0);  // R1:R0 <- D0, so sign bit is in bit 31 of R1.
    __ mov(R1, Operand(R1, LSR, 31));
    __ tst(R1, Operand(1));
    __ b(&is_true, NE);  // Sign bit set.
    __ b(&is_false);
  }
}

void Intrinsifier::DoubleToInteger(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through;

    __ ldr(R0, Address(SP, 0 * kWordSize));
    __ LoadDFromOffset(D0, R0, Double::value_offset() - kHeapObjectTag);

    // Explicit NaN check, since ARM gives an FPU exception if you try to
    // convert NaN to an int.
    __ vcmpd(D0, D0);
    __ vmstat();
    __ b(&fall_through, VS);

    __ vcvtid(S0, D0);
    __ vmovrs(R0, S0);
    // Overflow is signaled with minint.
    // Check for overflow and that it fits into Smi.
    __ CompareImmediate(R0, 0xC0000000);
    __ SmiTag(R0, PL);
    __ bx(LR, PL);
    __ Bind(&fall_through);
  }
}

void Intrinsifier::MathSqrt(Assembler* assembler) {
  if (TargetCPUFeatures::vfp_supported()) {
    Label fall_through, is_smi, double_op;
    TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
    // Argument is double and is in R0.
    __ LoadDFromOffset(D1, R0, Double::value_offset() - kHeapObjectTag);
    __ Bind(&double_op);
    __ vsqrtd(D0, D1);
    const Class& double_class =
        Class::Handle(Isolate::Current()->object_store()->double_class());
    __ TryAllocate(double_class, &fall_through, R0, R1);  // Result register.
    __ StoreDToOffset(D0, R0, Double::value_offset() - kHeapObjectTag);
    __ Ret();
    __ Bind(&is_smi);
    __ SmiUntag(R0);
    __ vmovsr(S0, R0);
    __ vcvtdi(D1, S0);
    __ b(&double_op);
    __ Bind(&fall_through);
  }
}

//    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//    _state[kSTATE_LO] = state & _MASK_32;
//    _state[kSTATE_HI] = state >> 32;
void Intrinsifier::Random_nextState(Assembler* assembler) {
  const Library& math_lib = Library::Handle(Library::MathLibrary());
  ASSERT(!math_lib.IsNull());
  const Class& random_class =
      Class::Handle(math_lib.LookupClassAllowPrivate(Symbols::_Random()));
  ASSERT(!random_class.IsNull());
  const Field& state_field = Field::ZoneHandle(
      random_class.LookupInstanceFieldAllowPrivate(Symbols::_state()));
  ASSERT(!state_field.IsNull());
  const Field& random_A_field = Field::ZoneHandle(
      random_class.LookupStaticFieldAllowPrivate(Symbols::_A()));
  ASSERT(!random_A_field.IsNull());
  ASSERT(random_A_field.is_const());
  Instance& a_value = Instance::Handle(random_A_field.StaticValue());
  if (a_value.raw() == Object::sentinel().raw() ||
      a_value.raw() == Object::transition_sentinel().raw()) {
    random_A_field.EvaluateInitializer();
    a_value = random_A_field.StaticValue();
  }
  const int64_t a_int_value = Integer::Cast(a_value).AsInt64Value();
  // 'a_int_value' is a mask.
  ASSERT(Utils::IsUint(32, a_int_value));
  int32_t a_int32_value = static_cast<int32_t>(a_int_value);

  // Receiver.
  __ ldr(R0, Address(SP, 0 * kWordSize));
  // Field '_state'.
  __ ldr(R1, FieldAddress(R0, state_field.Offset()));
  // Addresses of _state[0] and _state[1].

  const int64_t disp_0 = Instance::DataOffsetFor(kTypedDataUint32ArrayCid);
  const int64_t disp_1 =
      disp_0 + Instance::ElementSizeFor(kTypedDataUint32ArrayCid);

  __ LoadImmediate(R0, a_int32_value);
  __ LoadFromOffset(kWord, R2, R1, disp_0 - kHeapObjectTag);
  __ LoadFromOffset(kWord, R3, R1, disp_1 - kHeapObjectTag);
  __ mov(R8, Operand(0));  // Zero extend unsigned _state[kSTATE_HI].
  // Unsigned 32-bit multiply and 64-bit accumulate into R8:R3.
  __ umlal(R3, R8, R0, R2);  // R8:R3 <- R8:R3 + R0 * R2.
  __ StoreToOffset(kWord, R3, R1, disp_0 - kHeapObjectTag);
  __ StoreToOffset(kWord, R8, R1, disp_1 - kHeapObjectTag);
  __ Ret();
}

void Intrinsifier::ObjectEquals(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ cmp(R0, Operand(R1));
  __ LoadObject(R0, Bool::False(), NE);
  __ LoadObject(R0, Bool::True(), EQ);
  __ Ret();
}

static void RangeCheck(Assembler* assembler,
                       Register val,
                       Register tmp,
                       intptr_t low,
                       intptr_t high,
                       Condition cc,
                       Label* target) {
  __ AddImmediate(tmp, val, -low);
  __ CompareImmediate(tmp, high - low);
  __ b(target, cc);
}

const Condition kIfNotInRange = HI;
const Condition kIfInRange = LS;

static void JumpIfInteger(Assembler* assembler,
                          Register cid,
                          Register tmp,
                          Label* target) {
  RangeCheck(assembler, cid, tmp, kSmiCid, kBigintCid, kIfInRange, target);
}

static void JumpIfNotInteger(Assembler* assembler,
                             Register cid,
                             Register tmp,
                             Label* target) {
  RangeCheck(assembler, cid, tmp, kSmiCid, kBigintCid, kIfNotInRange, target);
}

static void JumpIfString(Assembler* assembler,
                         Register cid,
                         Register tmp,
                         Label* target) {
  RangeCheck(assembler, cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfInRange, target);
}

static void JumpIfNotString(Assembler* assembler,
                            Register cid,
                            Register tmp,
                            Label* target) {
  RangeCheck(assembler, cid, tmp, kOneByteStringCid, kExternalTwoByteStringCid,
             kIfNotInRange, target);
}

// Return type quickly for simple types (not parameterized and not signature).
void Intrinsifier::ObjectRuntimeType(Assembler* assembler) {
  Label fall_through, use_canonical_type, not_double, not_integer;
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);

  __ CompareImmediate(R1, kClosureCid);
  __ b(&fall_through, EQ);  // Instance is a closure.

  __ CompareImmediate(R1, kNumPredefinedCids);
  __ b(&use_canonical_type, HI);

  __ CompareImmediate(R1, kDoubleCid);
  __ b(&not_double, NE);

  __ LoadIsolate(R0);
  __ LoadFromOffset(kWord, R0, R0, Isolate::object_store_offset());
  __ LoadFromOffset(kWord, R0, R0, ObjectStore::double_type_offset());
  __ Ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, R1, R0, &not_integer);
  __ LoadIsolate(R0);
  __ LoadFromOffset(kWord, R0, R0, Isolate::object_store_offset());
  __ LoadFromOffset(kWord, R0, R0, ObjectStore::int_type_offset());
  __ Ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, R1, R0, &use_canonical_type);
  __ LoadIsolate(R0);
  __ LoadFromOffset(kWord, R0, R0, Isolate::object_store_offset());
  __ LoadFromOffset(kWord, R0, R0, ObjectStore::string_type_offset());
  __ Ret();

  __ Bind(&use_canonical_type);
  __ LoadClassById(R2, R1);
  __ ldrh(R3, FieldAddress(R2, Class::num_type_arguments_offset()));
  __ CompareImmediate(R3, 0);
  __ b(&fall_through, NE);

  __ ldr(R0, FieldAddress(R2, Class::canonical_type_offset()));
  __ CompareObject(R0, Object::null_object());
  __ b(&fall_through, EQ);
  __ Ret();

  __ Bind(&fall_through);
}

void Intrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler) {
  Label fall_through, different_cids, equal, not_equal, not_integer;
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadClassIdMayBeSmi(R1, R0);

  // Check if left hand size is a closure. Closures are handled in the runtime.
  __ CompareImmediate(R1, kClosureCid);
  __ b(&fall_through, EQ);

  __ ldr(R0, Address(SP, 1 * kWordSize));
  __ LoadClassIdMayBeSmi(R2, R0);

  // Check whether class ids match. If class ids don't match objects can still
  // have the same runtime type (e.g. multiple string implementation classes
  // map to a single String type).
  __ cmp(R1, Operand(R2));
  __ b(&different_cids, NE);

  // Objects have the same class and neither is a closure.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(R3, R1);
  __ ldrh(R3, FieldAddress(R3, Class::num_type_arguments_offset()));
  __ CompareImmediate(R3, 0);
  __ b(&fall_through, NE);

  __ Bind(&equal);
  __ LoadObject(R0, Bool::True());
  __ Ret();

  // Class ids are different. Check if we are comparing runtime types of
  // two strings (with different representations) or two integers.
  __ Bind(&different_cids);
  __ CompareImmediate(R1, kNumPredefinedCids);
  __ b(&not_equal, HI);

  // Check if both are integers.
  JumpIfNotInteger(assembler, R1, R0, &not_integer);
  JumpIfInteger(assembler, R2, R0, &equal);
  __ b(&not_equal);

  __ Bind(&not_integer);
  // Check if both are strings.
  JumpIfNotString(assembler, R1, R0, &not_equal);
  JumpIfString(assembler, R2, R0, &equal);

  // Neither strings nor integers and have different class ids.
  __ Bind(&not_equal);
  __ LoadObject(R0, Bool::False());
  __ Ret();

  __ Bind(&fall_through);
}

void Intrinsifier::String_getHashCode(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R0, String::hash_offset()));
  __ cmp(R0, Operand(0));
  __ bx(LR, NE);  // Hash not yet computed.
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
    __ AddImmediate(R0, OneByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ AddImmediate(R0, TwoByteString::data_offset() - kHeapObjectTag);
    __ add(R0, R0, Operand(R1));
    __ add(R0, R0, Operand(R1));
  }
  if (other_cid == kOneByteStringCid) {
    __ AddImmediate(R2, OneByteString::data_offset() - kHeapObjectTag);
  } else {
    ASSERT(other_cid == kTwoByteStringCid);
    __ AddImmediate(R2, TwoByteString::data_offset() - kHeapObjectTag);
  }

  // i = 0
  __ LoadImmediate(R3, 0);

  // do
  Label loop;
  __ Bind(&loop);

  if (receiver_cid == kOneByteStringCid) {
    __ ldrb(R4, Address(R0, 0));  // this.codeUnitAt(i + start)
  } else {
    __ ldrh(R4, Address(R0, 0));  // this.codeUnitAt(i + start)
  }
  if (other_cid == kOneByteStringCid) {
    __ ldrb(NOTFP, Address(R2, 0));  // other.codeUnitAt(i)
  } else {
    __ ldrh(NOTFP, Address(R2, 0));  // other.codeUnitAt(i)
  }
  __ cmp(R4, Operand(NOTFP));
  __ b(return_false, NE);

  // i++, while (i < len)
  __ AddImmediate(R3, 1);
  __ AddImmediate(R0, receiver_cid == kOneByteStringCid ? 1 : 2);
  __ AddImmediate(R2, other_cid == kOneByteStringCid ? 1 : 2);
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
  __ Push(R4);                             // Make ARGS_DESC_REG available.

  __ tst(R1, Operand(kSmiTagMask));
  __ b(&fall_through, NE);  // 'start' is not a Smi.

  __ CompareClassId(R2, kOneByteStringCid, R3);
  __ b(&fall_through, NE);

  __ CompareClassId(R0, kOneByteStringCid, R3);
  __ b(&try_two_byte, NE);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ CompareClassId(R0, kTwoByteStringCid, R3);
  __ b(&fall_through, NE);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ Pop(R4);
  __ LoadObject(R0, Bool::True());
  __ Ret();

  __ Bind(&return_false);
  __ Pop(R4);
  __ LoadObject(R0, Bool::False());
  __ Ret();

  __ Bind(&fall_through);
  __ Pop(R4);
}

void Intrinsifier::Object_getHash(Assembler* assembler) {
  UNREACHABLE();
}

void Intrinsifier::Object_setHash(Assembler* assembler) {
  UNREACHABLE();
}

void Intrinsifier::StringBaseCharAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;

  __ ldr(R1, Address(SP, 0 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 1 * kWordSize));  // String.
  __ tst(R1, Operand(kSmiTagMask));
  __ b(&fall_through, NE);  // Index is not a Smi.
  // Range check.
  __ ldr(R2, FieldAddress(R0, String::length_offset()));
  __ cmp(R1, Operand(R2));
  __ b(&fall_through, CS);  // Runtime throws exception.

  __ CompareClassId(R0, kOneByteStringCid, R3);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, OneByteString::data_offset() - kHeapObjectTag);
  __ ldrb(R1, Address(R0, R1));
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols);
  __ b(&fall_through, GE);
  __ ldr(R0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(R0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(R0, Address(R0, R1, LSL, 2));
  __ Ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid, R3);
  __ b(&fall_through, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, TwoByteString::data_offset() - kHeapObjectTag);
  __ ldrh(R1, Address(R0, R1));
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols);
  __ b(&fall_through, GE);
  __ ldr(R0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(R0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ ldr(R0, Address(R0, R1, LSL, 2));
  __ Ret();

  __ Bind(&fall_through);
}

void Intrinsifier::StringBaseIsEmpty(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R0, String::length_offset()));
  __ cmp(R0, Operand(Smi::RawValue(0)));
  __ LoadObject(R0, Bool::True(), EQ);
  __ LoadObject(R0, Bool::False(), NE);
  __ Ret();
}

void Intrinsifier::OneByteString_getHashCode(Assembler* assembler) {
  __ ldr(R1, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R1, String::hash_offset()));
  __ cmp(R0, Operand(0));
  __ bx(LR, NE);  // Return if already computed.

  __ ldr(R2, FieldAddress(R1, String::length_offset()));

  Label done;
  // If the string is empty, set the hash to 1, and return.
  __ cmp(R2, Operand(Smi::RawValue(0)));
  __ b(&done, EQ);

  __ SmiUntag(R2);
  __ mov(R3, Operand(0));
  __ AddImmediate(R8, R1, OneByteString::data_offset() - kHeapObjectTag);
  // R1: Instance of OneByteString.
  // R2: String length, untagged integer.
  // R3: Loop counter, untagged integer.
  // R8: String data.
  // R0: Hash code, untagged integer.

  Label loop;
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ Bind(&loop);
  __ ldrb(NOTFP, Address(R8, 0));
  // NOTFP: ch.
  __ add(R3, R3, Operand(1));
  __ add(R8, R8, Operand(1));
  __ add(R0, R0, Operand(NOTFP));
  __ add(R0, R0, Operand(R0, LSL, 10));
  __ eor(R0, R0, Operand(R0, LSR, 6));
  __ cmp(R3, Operand(R2));
  __ b(&loop, NE);

  // Finalize.
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ add(R0, R0, Operand(R0, LSL, 3));
  __ eor(R0, R0, Operand(R0, LSR, 11));
  __ add(R0, R0, Operand(R0, LSL, 15));
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ LoadImmediate(R2, (static_cast<intptr_t>(1) << String::kHashBits) - 1);
  __ and_(R0, R0, Operand(R2));
  __ cmp(R0, Operand(0));
  // return hash_ == 0 ? 1 : hash_;
  __ Bind(&done);
  __ mov(R0, Operand(1), EQ);
  __ SmiTag(R0);
  __ StoreIntoSmiField(FieldAddress(R1, String::hash_offset()), R0);
  __ Ret();
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
  __ mov(R8, Operand(length_reg));  // Save the length register.
  // TODO(koda): Protect against negative length and overflow here.
  __ SmiUntag(length_reg);
  const intptr_t fixed_size_plus_alignment_padding =
      sizeof(RawString) + kObjectAlignment - 1;
  __ AddImmediate(length_reg, fixed_size_plus_alignment_padding);
  __ bic(length_reg, length_reg, Operand(kObjectAlignment - 1));

  const intptr_t cid = kOneByteStringCid;
  NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
  __ ldr(R0, Address(THR, Thread::top_offset()));

  // length_reg: allocation size.
  __ adds(R1, R0, Operand(length_reg));
  __ b(&fail, CS);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: potential next object start.
  // R2: allocation size.
  __ ldr(NOTFP, Address(THR, Thread::end_offset()));
  __ cmp(R1, Operand(NOTFP));
  __ b(&fail, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  NOT_IN_PRODUCT(__ LoadAllocationStatsAddress(R4, cid));
  __ str(R1, Address(THR, Thread::top_offset()));
  __ AddImmediate(R0, kHeapObjectTag);

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R1: new object end address.
  // R2: allocation size.
  // R4: allocation stats address.
  {
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag);
    __ mov(R3, Operand(R2, LSL, shift), LS);
    __ mov(R3, Operand(0), HI);

    // Get the class index and insert it into the tags.
    // R3: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ orr(R3, R3, Operand(TMP));
    __ str(R3, FieldAddress(R0, String::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (R8).
  __ StoreIntoObjectNoBarrier(R0, FieldAddress(R0, String::length_offset()),
                              R8);
  // Clear hash.
  __ LoadImmediate(TMP, 0);
  __ StoreIntoObjectNoBarrier(R0, FieldAddress(R0, String::hash_offset()), TMP);

  NOT_IN_PRODUCT(__ IncrementAllocationStatsWithSize(R4, R2, space));
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
  __ orr(R3, R2, Operand(TMP));
  __ tst(R3, Operand(kSmiTagMask));
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
  __ AddImmediate(R3, OneByteString::data_offset() - 1);

  // R3: Start address to copy from (untagged).
  // R1: Untagged start index.
  __ ldr(R2, Address(SP, kEndIndexOffset));
  __ SmiUntag(R2);
  __ sub(R2, R2, Operand(R1));

  // R3: Start address to copy from (untagged).
  // R2: Untagged number of bytes to copy.
  // R0: Tagged result string.
  // R8: Pointer into R3.
  // NOTFP: Pointer into R0.
  // R1: Scratch register.
  Label loop, done;
  __ cmp(R2, Operand(0));
  __ b(&done, LE);
  __ mov(R8, Operand(R3));
  __ mov(NOTFP, Operand(R0));
  __ Bind(&loop);
  __ ldrb(R1, Address(R8, 0));
  __ AddImmediate(R8, 1);
  __ sub(R2, R2, Operand(1));
  __ cmp(R2, Operand(0));
  __ strb(R1, FieldAddress(NOTFP, OneByteString::data_offset()));
  __ AddImmediate(NOTFP, 1);
  __ b(&loop, GT);

  __ Bind(&done);
  __ Ret();
  __ Bind(&fall_through);
}

void Intrinsifier::OneByteStringSetAt(Assembler* assembler) {
  __ ldr(R2, Address(SP, 0 * kWordSize));  // Value.
  __ ldr(R1, Address(SP, 1 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 2 * kWordSize));  // OneByteString.
  __ SmiUntag(R1);
  __ SmiUntag(R2);
  __ AddImmediate(R3, R0, OneByteString::data_offset() - kHeapObjectTag);
  __ strb(R2, Address(R3, R1));
  __ Ret();
}

void Intrinsifier::OneByteString_allocate(Assembler* assembler) {
  __ ldr(R2, Address(SP, 0 * kWordSize));  // Length.
  Label fall_through, ok;
  TryAllocateOnebyteString(assembler, &ok, &fall_through);

  __ Bind(&ok);
  __ Ret();

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
  __ tst(R1, Operand(kSmiTagMask));
  __ b(&fall_through, EQ);
  __ CompareClassId(R1, string_cid, R2);
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
  const intptr_t offset = (string_cid == kOneByteStringCid)
                              ? OneByteString::data_offset()
                              : TwoByteString::data_offset();
  __ AddImmediate(R0, offset - kHeapObjectTag);
  __ AddImmediate(R1, offset - kHeapObjectTag);
  __ SmiUntag(R2);
  __ Bind(&loop);
  __ AddImmediate(R2, -1);
  __ cmp(R2, Operand(0));
  __ b(&is_true, LT);
  if (string_cid == kOneByteStringCid) {
    __ ldrb(R3, Address(R0));
    __ ldrb(R4, Address(R1));
    __ AddImmediate(R0, 1);
    __ AddImmediate(R1, 1);
  } else if (string_cid == kTwoByteStringCid) {
    __ ldrh(R3, Address(R0));
    __ ldrh(R4, Address(R1));
    __ AddImmediate(R0, 2);
    __ AddImmediate(R1, 2);
  } else {
    UNIMPLEMENTED();
  }
  __ cmp(R3, Operand(R4));
  __ b(&is_false, NE);
  __ b(&loop);

  __ Bind(&is_true);
  __ LoadObject(R0, Bool::True());
  __ Ret();

  __ Bind(&is_false);
  __ LoadObject(R0, Bool::False());
  __ Ret();

  __ Bind(&fall_through);
}

void Intrinsifier::OneByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kOneByteStringCid);
}

void Intrinsifier::TwoByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kTwoByteStringCid);
}

void Intrinsifier::IntrinsifyRegExpExecuteMatch(Assembler* assembler,
                                                bool sticky) {
  if (FLAG_interpret_irregexp) return;

  static const intptr_t kRegExpParamOffset = 2 * kWordSize;
  static const intptr_t kStringParamOffset = 1 * kWordSize;
  // start_index smi is located at offset 0.

  // Incoming registers:
  // R0: Function. (Will be reloaded with the specialized matcher function.)
  // R4: Arguments descriptor. (Will be preserved.)
  // R9: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into R0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ ldr(R2, Address(SP, kRegExpParamOffset));
  __ ldr(R1, Address(SP, kStringParamOffset));
  __ LoadClassId(R1, R1);
  __ AddImmediate(R1, -kOneByteStringCid);
  __ add(R1, R2, Operand(R1, LSL, kWordSizeLog2));
  __ ldr(R0,
         FieldAddress(R1, RegExp::function_offset(kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in R0, the argument descriptor in R4, and IC-Data in R9.
  __ eor(R9, R9, Operand(R9));

  // Tail-call the function.
  __ ldr(CODE_REG, FieldAddress(R0, Function::code_offset()));
  __ ldr(R1, FieldAddress(R0, Function::entry_point_offset()));
  __ bx(R1);
}

// On stack: user tag (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  // R1: Isolate.
  __ LoadIsolate(R1);
  // R0: Current user tag.
  __ ldr(R0, Address(R1, Isolate::current_tag_offset()));
  // R2: UserTag.
  __ ldr(R2, Address(SP, +0 * kWordSize));
  // Set Isolate::current_tag_.
  __ str(R2, Address(R1, Isolate::current_tag_offset()));
  // R2: UserTag's tag.
  __ ldr(R2, FieldAddress(R2, UserTag::tag_offset()));
  // Set Isolate::user_tag_.
  __ str(R2, Address(R1, Isolate::user_tag_offset()));
  __ Ret();
}

void Intrinsifier::UserTag_defaultTag(Assembler* assembler) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, Isolate::default_tag_offset()));
  __ Ret();
}

void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  __ LoadIsolate(R0);
  __ ldr(R0, Address(R0, Isolate::current_tag_offset()));
  __ Ret();
}

void Intrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler) {
  if (!FLAG_support_timeline) {
    __ LoadObject(R0, Bool::False());
    __ Ret();
    return;
  }
  // Load TimelineStream*.
  __ ldr(R0, Address(THR, Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ ldr(R0, Address(R0, TimelineStream::enabled_offset()));
  __ cmp(R0, Operand(0));
  __ LoadObject(R0, Bool::True(), NE);
  __ LoadObject(R0, Bool::False(), EQ);
  __ Ret();
}

void Intrinsifier::ClearAsyncThreadStackTrace(Assembler* assembler) {
  __ LoadObject(R0, Object::null_object());
  __ str(R0, Address(THR, Thread::async_stack_trace_offset()));
  __ Ret();
}

void Intrinsifier::SetAsyncThreadStackTrace(Assembler* assembler) {
  __ ldr(R0, Address(THR, Thread::async_stack_trace_offset()));
  __ LoadObject(R0, Object::null_object());
  __ Ret();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)
