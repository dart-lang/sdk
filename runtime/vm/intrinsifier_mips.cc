// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

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
// S4: Arguments descriptor
// RA: Return address
// The S4 register can be destroyed only if there is no slow-path, i.e.
// if the intrinsified method always executes a return.
// The FP register should not be modified, because it is used by the profiler.
// The PP and THR registers (see constants_mips.h) must be preserved.

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
  ASSERT(CALLEE_SAVED_TEMP != CODE_REG);
  ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);

  assembler->Comment("IntrinsicCallPrologue");
  assembler->mov(CALLEE_SAVED_TEMP, LRREG);
}


void Intrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->mov(LRREG, CALLEE_SAVED_TEMP);
}


// Intrinsify only for Smi value and index. Non-smi values need a store buffer
// update. Array length is always a Smi.
void Intrinsifier::ObjectArraySetIndexed(Assembler* assembler) {
  if (Isolate::Current()->type_checks()) {
    return;
  }

  Label fall_through;
  __ lw(T1, Address(SP, 1 * kWordSize));  // Index.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  // Index not Smi.
  __ bne(CMPRES1, ZR, &fall_through);

  __ lw(T0, Address(SP, 2 * kWordSize));  // Array.
  // Range check.
  __ lw(T3, FieldAddress(T0, Array::length_offset()));  // Array length.
  // Runtime throws exception.
  __ BranchUnsignedGreaterEqual(T1, T3, &fall_through);

  // Note that T1 is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ lw(T2, Address(SP, 0 * kWordSize));  // Value.
  __ sll(T1, T1, 1);                      // T1 is Smi.
  __ addu(T1, T0, T1);
  __ StoreIntoObject(T0, FieldAddress(T1, Array::data_offset()), T2);
  // Caller is responsible for preserving the value if necessary.
  __ Ret();
  __ Bind(&fall_through);
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+1), data (+0).
void Intrinsifier::GrowableArray_Allocate(Assembler* assembler) {
  // The newly allocated object is returned in V0.
  const intptr_t kTypeArgumentsOffset = 1 * kWordSize;
  const intptr_t kArrayOffset = 0 * kWordSize;
  Label fall_through;

  // Try allocating in new space.
  const Class& cls = Class::Handle(
      Isolate::Current()->object_store()->growable_object_array_class());
  __ TryAllocate(cls, &fall_through, V0, T1);

  // Store backing array object in growable array object.
  __ lw(T1, Address(SP, kArrayOffset));  // Data argument.
  // V0 is new, no barrier needed.
  __ StoreIntoObjectNoBarrier(
      V0, FieldAddress(V0, GrowableObjectArray::data_offset()), T1);

  // V0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ lw(T1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreIntoObjectNoBarrier(
      V0, FieldAddress(V0, GrowableObjectArray::type_arguments_offset()), T1);
  // Set the length field in the growable array object to 0.
  __ Ret();  // Returns the newly allocated object in V0.
  __ delay_slot()->sw(ZR,
                      FieldAddress(V0, GrowableObjectArray::length_offset()));

  __ Bind(&fall_through);
}


// Add an element to growable array if it doesn't need to grow, otherwise
// call into regular code.
// On stack: growable array (+1), value (+0).
void Intrinsifier::GrowableArray_add(Assembler* assembler) {
  // In checked mode we need to type-check the incoming argument.
  if (Isolate::Current()->type_checks()) return;
  Label fall_through;
  __ lw(T0, Address(SP, 1 * kWordSize));  // Array.
  __ lw(T1, FieldAddress(T0, GrowableObjectArray::length_offset()));
  // T1: length.
  __ lw(T2, FieldAddress(T0, GrowableObjectArray::data_offset()));
  // T2: data.
  __ lw(T3, FieldAddress(T2, Array::length_offset()));
  // Compare length with capacity.
  // T3: capacity.
  __ beq(T1, T3, &fall_through);  // Must grow data.
  const int32_t value_one = reinterpret_cast<int32_t>(Smi::New(1));
  // len = len + 1;
  __ addiu(T3, T1, Immediate(value_one));
  __ sw(T3, FieldAddress(T0, GrowableObjectArray::length_offset()));
  __ lw(T0, Address(SP, 0 * kWordSize));  // Value.
  ASSERT(kSmiTagShift == 1);
  __ sll(T1, T1, 1);
  __ addu(T1, T2, T1);
  __ StoreIntoObject(T2, FieldAddress(T1, Array::data_offset()), T0);
  __ LoadObject(T7, Object::null_object());
  __ Ret();
  __ delay_slot()->mov(V0, T7);
  __ Bind(&fall_through);
}


#define TYPED_ARRAY_ALLOCATION(type_name, cid, max_len, scale_shift)           \
  Label fall_through;                                                          \
  const intptr_t kArrayLengthStackOffset = 0 * kWordSize;                      \
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(cid, T2, &fall_through));             \
  __ lw(T2, Address(SP, kArrayLengthStackOffset)); /* Array length. */         \
  /* Check that length is a positive Smi. */                                   \
  /* T2: requested array length argument. */                                   \
  __ andi(CMPRES1, T2, Immediate(kSmiTagMask));                                \
  __ bne(CMPRES1, ZR, &fall_through);                                          \
  __ BranchSignedLess(T2, Immediate(0), &fall_through);                        \
  __ SmiUntag(T2);                                                             \
  /* Check for maximum allowed length. */                                      \
  /* T2: untagged array length. */                                             \
  __ BranchSignedGreater(T2, Immediate(max_len), &fall_through);               \
  __ sll(T2, T2, scale_shift);                                                 \
  const intptr_t fixed_size_plus_alignment_padding =                           \
      sizeof(Raw##type_name) + kObjectAlignment - 1;                           \
  __ AddImmediate(T2, fixed_size_plus_alignment_padding);                      \
  __ LoadImmediate(TMP, -kObjectAlignment);                                    \
  __ and_(T2, T2, TMP);                                                        \
  Heap::Space space = Heap::kNew;                                              \
  __ lw(T3, Address(THR, Thread::heap_offset()));                              \
  __ lw(V0, Address(T3, Heap::TopOffset(space)));                              \
                                                                               \
  /* T2: allocation size. */                                                   \
  __ addu(T1, V0, T2);                                                         \
  /* Branch on unsigned overflow. */                                           \
  __ BranchUnsignedLess(T1, V0, &fall_through);                                \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* V0: potential new object start. */                                        \
  /* T1: potential next object start. */                                       \
  /* T2: allocation size. */                                                   \
  /* T3: heap. */                                                              \
  __ lw(T4, Address(T3, Heap::EndOffset(space)));                              \
  __ BranchUnsignedGreaterEqual(T1, T4, &fall_through);                        \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  __ sw(T1, Address(T3, Heap::TopOffset(space)));                              \
  __ AddImmediate(V0, kHeapObjectTag);                                         \
  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, T2, T4, space));        \
  /* Initialize the tags. */                                                   \
  /* V0: new object start as a tagged pointer. */                              \
  /* T1: new object end address. */                                            \
  /* T2: allocation size. */                                                   \
  {                                                                            \
    Label size_tag_overflow, done;                                             \
    __ BranchUnsignedGreater(T2, Immediate(RawObject::SizeTag::kMaxSizeTag),   \
                             &size_tag_overflow);                              \
    __ b(&done);                                                               \
    __ delay_slot()->sll(T2, T2,                                               \
                         RawObject::kSizeTagPos - kObjectAlignmentLog2);       \
                                                                               \
    __ Bind(&size_tag_overflow);                                               \
    __ mov(T2, ZR);                                                            \
    __ Bind(&done);                                                            \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));                 \
    __ or_(T2, T2, TMP);                                                       \
    __ sw(T2, FieldAddress(V0, type_name::tags_offset())); /* Tags. */         \
  }                                                                            \
  /* Set the length field. */                                                  \
  /* V0: new object start as a tagged pointer. */                              \
  /* T1: new object end address. */                                            \
  __ lw(T2, Address(SP, kArrayLengthStackOffset)); /* Array length. */         \
  __ StoreIntoObjectNoBarrier(                                                 \
      V0, FieldAddress(V0, type_name::length_offset()), T2);                   \
  /* Initialize all array elements to 0. */                                    \
  /* V0: new object start as a tagged pointer. */                              \
  /* T1: new object end address. */                                            \
  /* T2: iterator which initially points to the start of the variable */       \
  /* data area to be initialized. */                                           \
  __ AddImmediate(T2, V0, sizeof(Raw##type_name) - 1);                         \
  Label done, init_loop;                                                       \
  __ Bind(&init_loop);                                                         \
  __ BranchUnsignedGreaterEqual(T2, T1, &done);                                \
  __ sw(ZR, Address(T2, 0));                                                   \
  __ b(&init_loop);                                                            \
  __ delay_slot()->addiu(T2, T2, Immediate(kWordSize));                        \
  __ Bind(&done);                                                              \
                                                                               \
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


// Loads args from stack into T0 and T1
// Tests if they are smis, jumps to label not_smi if not.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T1, Address(SP, 1 * kWordSize));
  __ or_(CMPRES1, T0, T1);
  __ andi(CMPRES1, CMPRES1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, not_smi);
  return;
}


void Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two Smis.
  __ AdduDetectOverflow(V0, T0, T1, CMPRES1);       // Add.
  __ bltz(CMPRES1, &fall_through);                  // Fall through on overflow.
  __ Ret();  // Nothing in branch delay slot.
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_add(Assembler* assembler) {
  Integer_addFromInteger(assembler);
}


void Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ SubuDetectOverflow(V0, T0, T1, CMPRES1);  // Subtract.
  __ bltz(CMPRES1, &fall_through);             // Fall through on overflow.
  __ Ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_sub(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ SubuDetectOverflow(V0, T1, T0, CMPRES1);  // Subtract.
  __ bltz(CMPRES1, &fall_through);             // Fall through on overflow.
  __ Ret();                                    // Nothing in branch delay slot.
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ SmiUntag(T0);  // untags T0. only want result shifted by one

  __ mult(T0, T1);                // HI:LO <- T0 * T1.
  __ mflo(V0);                    // V0 <- LO.
  __ mfhi(T2);                    // T2 <- HI.
  __ sra(T3, V0, 31);             // T3 <- V0 >> 31.
  __ bne(T2, T3, &fall_through);  // Fall through on overflow.
  __ Ret();
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
// T1: Tagged left (dividend).
// T0: Tagged right (divisor).
// Returns:
//   V0: Untagged fallthrough result (remainder to be adjusted), or
//   V0: Tagged return result (remainder).
static void EmitRemainderOperation(Assembler* assembler) {
  Label return_zero, modulo;
  const Register left = T1;
  const Register right = T0;
  const Register result = V0;

  __ beq(left, ZR, &return_zero);
  __ beq(left, right, &return_zero);

  __ bltz(left, &modulo);
  // left is positive.
  __ BranchSignedGreaterEqual(left, right, &modulo);
  // left is less than right. return left.
  __ Ret();
  __ delay_slot()->mov(result, left);

  __ Bind(&return_zero);
  __ Ret();
  __ delay_slot()->mov(result, ZR);

  __ Bind(&modulo);
  __ SmiUntag(right);
  __ SmiUntag(left);
  __ div(left, right);  // Divide, remainder goes in HI.
  __ mfhi(result);      // result <- HI.
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
  Label fall_through, subtract;
  // Test arguments for smi.
  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(T0, Address(SP, 1 * kWordSize));
  __ or_(CMPRES1, T0, T1);
  __ andi(CMPRES1, CMPRES1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);
  // T1: Tagged left (dividend).
  // T0: Tagged right (divisor).
  // Check if modulo by zero -> exception thrown in main function.
  __ beq(T0, ZR, &fall_through);
  EmitRemainderOperation(assembler);
  // Untagged right in T0. Untagged remainder result in V0.

  Label done;
  __ bgez(V0, &done);
  __ bltz(T0, &subtract);
  __ addu(V0, V0, T0);
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&subtract);
  __ subu(V0, V0, T0);
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&done);
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ beq(T0, ZR, &fall_through);  // If b is 0, fall through.

  __ SmiUntag(T0);
  __ SmiUntag(T1);
  __ div(T1, T0);  // LO <- T1 / T0
  __ mflo(V0);     // V0 <- LO
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ BranchEqual(V0, Immediate(0x40000000), &fall_through);
  __ Ret();
  __ delay_slot()->SmiTag(V0);
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_negate(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, +0 * kWordSize));        // Grabs first argument.
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));  // Test for Smi.
  __ bne(CMPRES1, ZR, &fall_through);            // Fall through if not a Smi.
  __ SubuDetectOverflow(V0, ZR, T0, CMPRES1);
  __ bltz(CMPRES1, &fall_through);  // There was overflow.
  __ Ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ Ret();
  __ delay_slot()->and_(V0, T0, T1);
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}


void Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ Ret();
  __ delay_slot()->or_(V0, T0, T1);
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitOr(Assembler* assembler) {
  Integer_bitOrFromInteger(assembler);
}


void Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // Checks two smis.
  __ Ret();
  __ delay_slot()->xor_(V0, T0, T1);
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitXor(Assembler* assembler) {
  Integer_bitXorFromInteger(assembler);
}


void Intrinsifier::Integer_shl(Assembler* assembler) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(kSmiTag == 0);
  Label fall_through, overflow;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ BranchUnsignedGreater(T0, Immediate(Smi::RawValue(Smi::kBits)),
                           &fall_through);
  __ SmiUntag(T0);

  // Check for overflow by shifting left and shifting back arithmetically.
  // If the result is different from the original, there was overflow.
  __ sllv(TMP, T1, T0);
  __ srav(CMPRES1, TMP, T0);
  __ bne(CMPRES1, T1, &overflow);

  // No overflow, result in V0.
  __ Ret();
  __ delay_slot()->sllv(V0, T1, T0);

  __ Bind(&overflow);
  // Arguments are Smi but the shift produced an overflow to Mint.
  __ bltz(T1, &fall_through);
  __ SmiUntag(T1);

  // Pull off high bits that will be shifted off of T1 by making a mask
  // ((1 << T0) - 1), shifting it to the right, masking T1, then shifting back.
  // high bits = (((1 << T0) - 1) << (32 - T0)) & T1) >> (32 - T0)
  // lo bits = T1 << T0
  __ LoadImmediate(T3, 1);
  __ sllv(T3, T3, T0);              // T3 <- T3 << T0
  __ addiu(T3, T3, Immediate(-1));  // T3 <- T3 - 1
  __ subu(T4, ZR, T0);              // T4 <- -T0
  __ addiu(T4, T4, Immediate(32));  // T4 <- 32 - T0
  __ sllv(T3, T3, T4);              // T3 <- T3 << T4
  __ and_(T3, T3, T1);              // T3 <- T3 & T1
  __ srlv(T3, T3, T4);              // T3 <- T3 >> T4
  // Now T3 has the bits that fall off of T1 on a left shift.
  __ sllv(T0, T1, T0);  // T0 gets low bits.

  const Class& mint_class =
      Class::Handle(Isolate::Current()->object_store()->mint_class());
  __ TryAllocate(mint_class, &fall_through, V0, T1);

  __ sw(T0, FieldAddress(V0, Mint::value_offset()));
  __ Ret();
  __ delay_slot()->sw(T3, FieldAddress(V0, Mint::value_offset() + kWordSize));
  __ Bind(&fall_through);
}


static void Get64SmiOrMint(Assembler* assembler,
                           Register res_hi,
                           Register res_lo,
                           Register reg,
                           Label* not_smi_or_mint) {
  Label not_smi, done;
  __ andi(CMPRES1, reg, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &not_smi);
  __ SmiUntag(reg);

  // Sign extend to 64 bit
  __ mov(res_lo, reg);
  __ b(&done);
  __ delay_slot()->sra(res_hi, reg, 31);

  __ Bind(&not_smi);
  __ LoadClassId(CMPRES1, reg);
  __ BranchNotEqual(CMPRES1, Immediate(kMintCid), not_smi_or_mint);

  // Mint.
  __ lw(res_lo, FieldAddress(reg, Mint::value_offset()));
  __ lw(res_hi, FieldAddress(reg, Mint::value_offset() + kWordSize));
  __ Bind(&done);
  return;
}


static void CompareIntegers(Assembler* assembler, RelationOperator rel_op) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // T0 contains the right argument. T1 contains left argument

  switch (rel_op) {
    case LT:
      __ BranchSignedLess(T1, T0, &is_true);
      break;
    case LE:
      __ BranchSignedLessEqual(T1, T0, &is_true);
      break;
    case GT:
      __ BranchSignedGreater(T1, T0, &is_true);
      break;
    case GE:
      __ BranchSignedGreaterEqual(T1, T0, &is_true);
      break;
    default:
      UNREACHABLE();
      break;
  }

  __ Bind(&is_false);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();

  __ Bind(&try_mint_smi);
  // Get left as 64 bit integer.
  Get64SmiOrMint(assembler, T3, T2, T1, &fall_through);
  // Get right as 64 bit integer.
  Get64SmiOrMint(assembler, T5, T4, T0, &fall_through);
  // T3: left high.
  // T2: left low.
  // T5: right high.
  // T4: right low.

  // 64-bit comparison
  switch (rel_op) {
    case LT:
    case LE: {
      // Compare left hi, right high.
      __ BranchSignedGreater(T3, T5, &is_false);
      __ BranchSignedLess(T3, T5, &is_true);
      // Compare left lo, right lo.
      if (rel_op == LT) {
        __ BranchUnsignedGreaterEqual(T2, T4, &is_false);
      } else {
        __ BranchUnsignedGreater(T2, T4, &is_false);
      }
      break;
    }
    case GT:
    case GE: {
      // Compare left hi, right high.
      __ BranchSignedLess(T3, T5, &is_false);
      __ BranchSignedGreater(T3, T5, &is_true);
      // Compare left lo, right lo.
      if (rel_op == GT) {
        __ BranchUnsignedLessEqual(T2, T4, &is_false);
      } else {
        __ BranchUnsignedLess(T2, T4, &is_false);
      }
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
  // Else is true.
  __ b(&is_true);

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  CompareIntegers(assembler, LT);
}


void Intrinsifier::Integer_lessThan(Assembler* assembler) {
  CompareIntegers(assembler, LT);
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
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T1, Address(SP, 1 * kWordSize));
  __ beq(T0, T1, &true_label);

  __ or_(T2, T0, T1);
  __ andi(CMPRES1, T2, Immediate(kSmiTagMask));
  // If T0 or T1 is not a smi do Mint checks.
  __ bne(CMPRES1, ZR, &check_for_mint);

  // Both arguments are smi, '===' is good enough.
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&true_label);
  __ LoadObject(V0, Bool::True());
  __ Ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &receiver_not_smi);  // Check receiver.

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint or Bigint never contains a value that can be
  // represented by Smi.

  __ LoadClassId(CMPRES1, T0);
  __ BranchEqual(CMPRES1, Immediate(kDoubleCid), &fall_through);
  __ LoadObject(V0, Bool::False());  // Smi == Mint -> false.
  __ Ret();

  __ Bind(&receiver_not_smi);
  // T1:: receiver.

  __ LoadClassId(CMPRES1, T1);
  __ BranchNotEqual(CMPRES1, Immediate(kMintCid), &fall_through);
  // Receiver is Mint, return false if right is Smi.
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_equal(Assembler* assembler) {
  Integer_equalToInteger(assembler);
}


void Intrinsifier::Integer_sar(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  // Shift amount in T0. Value to shift in T1.

  __ SmiUntag(T0);
  __ bltz(T0, &fall_through);

  __ LoadImmediate(T2, 0x1F);
  __ slt(CMPRES1, T2, T0);   // CMPRES1 <- 0x1F < T0 ? 1 : 0
  __ movn(T0, T2, CMPRES1);  // T0 <- 0x1F < T0 ? 0x1F : T0

  __ SmiUntag(T1);
  __ srav(V0, T1, T0);
  __ Ret();
  __ delay_slot()->SmiTag(V0);
  __ Bind(&fall_through);
}


void Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ nor(V0, T0, ZR);
  __ Ret();
  __ delay_slot()->addiu(V0, V0, Immediate(-1));  // Remove inverted smi-tag.
}


void Intrinsifier::Smi_bitLength(Assembler* assembler) {
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ SmiUntag(V0);
  // XOR with sign bit to complement bits if value is negative.
  __ sra(T0, V0, 31);
  __ xor_(V0, V0, T0);
  __ clz(V0, V0);
  __ LoadImmediate(T0, 32);
  __ subu(V0, T0, V0);
  __ Ret();
  __ delay_slot()->SmiTag(V0);
}


void Intrinsifier::Smi_bitAndFromSmi(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}


void Intrinsifier::Bigint_lsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // T2 = x_used, T3 = x_digits, x_used > 0, x_used is Smi.
  __ lw(T2, Address(SP, 2 * kWordSize));
  __ lw(T3, Address(SP, 3 * kWordSize));
  // T4 = r_digits, T5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ lw(T4, Address(SP, 0 * kWordSize));
  __ lw(T5, Address(SP, 1 * kWordSize));
  __ SmiUntag(T5);
  // T0 = n ~/ _DIGIT_BITS
  __ sra(T0, T5, 5);
  // T6 = &x_digits[0]
  __ addiu(T6, T3, Immediate(TypedData::data_offset() - kHeapObjectTag));
  // V0 = &x_digits[x_used]
  __ sll(T2, T2, 1);
  __ addu(V0, T6, T2);
  // V1 = &r_digits[1]
  __ addiu(V1, T4, Immediate(TypedData::data_offset() - kHeapObjectTag +
                             Bigint::kBytesPerDigit));
  // V1 = &r_digits[x_used + n ~/ _DIGIT_BITS + 1]
  __ addu(V1, V1, T2);
  __ sll(T1, T0, 2);
  __ addu(V1, V1, T1);
  // T3 = n % _DIGIT_BITS
  __ andi(T3, T5, Immediate(31));
  // T2 = 32 - T3
  __ subu(T2, ZR, T3);
  __ addiu(T2, T2, Immediate(32));
  __ mov(T1, ZR);
  Label loop;
  __ Bind(&loop);
  __ addiu(V0, V0, Immediate(-Bigint::kBytesPerDigit));
  __ lw(T0, Address(V0, 0));
  __ srlv(AT, T0, T2);
  __ or_(T1, T1, AT);
  __ addiu(V1, V1, Immediate(-Bigint::kBytesPerDigit));
  __ sw(T1, Address(V1, 0));
  __ bne(V0, T6, &loop);
  __ delay_slot()->sllv(T1, T0, T3);
  __ sw(T1, Address(V1, -Bigint::kBytesPerDigit));
  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}


void Intrinsifier::Bigint_rsh(Assembler* assembler) {
  // static void _lsh(Uint32List x_digits, int x_used, int n,
  //                  Uint32List r_digits)

  // T2 = x_used, T3 = x_digits, x_used > 0, x_used is Smi.
  __ lw(T2, Address(SP, 2 * kWordSize));
  __ lw(T3, Address(SP, 3 * kWordSize));
  // T4 = r_digits, T5 = n, n is Smi, n % _DIGIT_BITS != 0.
  __ lw(T4, Address(SP, 0 * kWordSize));
  __ lw(T5, Address(SP, 1 * kWordSize));
  __ SmiUntag(T5);
  // T0 = n ~/ _DIGIT_BITS
  __ sra(T0, T5, 5);
  // V1 = &r_digits[0]
  __ addiu(V1, T4, Immediate(TypedData::data_offset() - kHeapObjectTag));
  // V0 = &x_digits[n ~/ _DIGIT_BITS]
  __ addiu(V0, T3, Immediate(TypedData::data_offset() - kHeapObjectTag));
  __ sll(T1, T0, 2);
  __ addu(V0, V0, T1);
  // T6 = &r_digits[x_used - n ~/ _DIGIT_BITS - 1]
  __ sll(T2, T2, 1);
  __ addu(T6, V1, T2);
  __ subu(T6, T6, T1);
  __ addiu(T6, T6, Immediate(-4));
  // T3 = n % _DIGIT_BITS
  __ andi(T3, T5, Immediate(31));
  // T2 = 32 - T3
  __ subu(T2, ZR, T3);
  __ addiu(T2, T2, Immediate(32));
  // T1 = x_digits[n ~/ _DIGIT_BITS] >> (n % _DIGIT_BITS)
  __ lw(T1, Address(V0, 0));
  __ addiu(V0, V0, Immediate(Bigint::kBytesPerDigit));
  Label loop_exit;
  __ beq(V1, T6, &loop_exit);
  __ delay_slot()->srlv(T1, T1, T3);
  Label loop;
  __ Bind(&loop);
  __ lw(T0, Address(V0, 0));
  __ addiu(V0, V0, Immediate(Bigint::kBytesPerDigit));
  __ sllv(AT, T0, T2);
  __ or_(T1, T1, AT);
  __ sw(T1, Address(V1, 0));
  __ addiu(V1, V1, Immediate(Bigint::kBytesPerDigit));
  __ bne(V1, T6, &loop);
  __ delay_slot()->srlv(T1, T0, T3);
  __ Bind(&loop_exit);
  __ sw(T1, Address(V1, 0));
  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}


void Intrinsifier::Bigint_absAdd(Assembler* assembler) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // T2 = used, T3 = digits
  __ lw(T2, Address(SP, 3 * kWordSize));
  __ lw(T3, Address(SP, 4 * kWordSize));
  // T3 = &digits[0]
  __ addiu(T3, T3, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T4 = a_used, T5 = a_digits
  __ lw(T4, Address(SP, 1 * kWordSize));
  __ lw(T5, Address(SP, 2 * kWordSize));
  // T5 = &a_digits[0]
  __ addiu(T5, T5, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T6 = r_digits
  __ lw(T6, Address(SP, 0 * kWordSize));
  // T6 = &r_digits[0]
  __ addiu(T6, T6, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // V0 = &digits[a_used >> 1], a_used is Smi.
  __ sll(V0, T4, 1);
  __ addu(V0, V0, T3);

  // V1 = &digits[used >> 1], used is Smi.
  __ sll(V1, T2, 1);
  __ addu(V1, V1, T3);

  // T2 = carry in = 0.
  __ mov(T2, ZR);
  Label add_loop;
  __ Bind(&add_loop);
  // Loop a_used times, a_used > 0.
  __ lw(T0, Address(T3, 0));  // T0 = x.
  __ addiu(T3, T3, Immediate(Bigint::kBytesPerDigit));
  __ lw(T1, Address(T5, 0));  // T1 = y.
  __ addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));
  __ addu(T1, T0, T1);  // T1 = x + y.
  __ sltu(T4, T1, T0);  // T4 = carry out of x + y.
  __ addu(T0, T1, T2);  // T0 = x + y + carry in.
  __ sltu(T2, T0, T1);  // T2 = carry out of (x + y) + carry in.
  __ or_(T2, T2, T4);   // T2 = carry out of x + y + carry in.
  __ sw(T0, Address(T6, 0));
  __ bne(T3, V0, &add_loop);
  __ delay_slot()->addiu(T6, T6, Immediate(Bigint::kBytesPerDigit));

  Label last_carry;
  __ beq(T3, V1, &last_carry);

  Label carry_loop;
  __ Bind(&carry_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ lw(T0, Address(T3, 0));  // T0 = x.
  __ addiu(T3, T3, Immediate(Bigint::kBytesPerDigit));
  __ addu(T1, T0, T2);  // T1 = x + carry in.
  __ sltu(T2, T1, T0);  // T2 = carry out of x + carry in.
  __ sw(T1, Address(T6, 0));
  __ bne(T3, V1, &carry_loop);
  __ delay_slot()->addiu(T6, T6, Immediate(Bigint::kBytesPerDigit));

  __ Bind(&last_carry);
  __ sw(T2, Address(T6, 0));

  // Returning Object::null() is not required, since this method is private.
  __ Ret();
}


void Intrinsifier::Bigint_absSub(Assembler* assembler) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // T2 = used, T3 = digits
  __ lw(T2, Address(SP, 3 * kWordSize));
  __ lw(T3, Address(SP, 4 * kWordSize));
  // T3 = &digits[0]
  __ addiu(T3, T3, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T4 = a_used, T5 = a_digits
  __ lw(T4, Address(SP, 1 * kWordSize));
  __ lw(T5, Address(SP, 2 * kWordSize));
  // T5 = &a_digits[0]
  __ addiu(T5, T5, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T6 = r_digits
  __ lw(T6, Address(SP, 0 * kWordSize));
  // T6 = &r_digits[0]
  __ addiu(T6, T6, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // V0 = &digits[a_used >> 1], a_used is Smi.
  __ sll(V0, T4, 1);
  __ addu(V0, V0, T3);

  // V1 = &digits[used >> 1], used is Smi.
  __ sll(V1, T2, 1);
  __ addu(V1, V1, T3);

  // T2 = borrow in = 0.
  __ mov(T2, ZR);
  Label sub_loop;
  __ Bind(&sub_loop);
  // Loop a_used times, a_used > 0.
  __ lw(T0, Address(T3, 0));  // T0 = x.
  __ addiu(T3, T3, Immediate(Bigint::kBytesPerDigit));
  __ lw(T1, Address(T5, 0));  // T1 = y.
  __ addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));
  __ subu(T1, T0, T1);  // T1 = x - y.
  __ sltu(T4, T0, T1);  // T4 = borrow out of x - y.
  __ subu(T0, T1, T2);  // T0 = x - y - borrow in.
  __ sltu(T2, T1, T0);  // T2 = borrow out of (x - y) - borrow in.
  __ or_(T2, T2, T4);   // T2 = borrow out of x - y - borrow in.
  __ sw(T0, Address(T6, 0));
  __ bne(T3, V0, &sub_loop);
  __ delay_slot()->addiu(T6, T6, Immediate(Bigint::kBytesPerDigit));

  Label done;
  __ beq(T3, V1, &done);

  Label borrow_loop;
  __ Bind(&borrow_loop);
  // Loop used - a_used times, used - a_used > 0.
  __ lw(T0, Address(T3, 0));  // T0 = x.
  __ addiu(T3, T3, Immediate(Bigint::kBytesPerDigit));
  __ subu(T1, T0, T2);  // T1 = x - borrow in.
  __ sltu(T2, T0, T1);  // T2 = borrow out of x - borrow in.
  __ sw(T1, Address(T6, 0));
  __ bne(T3, V1, &borrow_loop);
  __ delay_slot()->addiu(T6, T6, Immediate(Bigint::kBytesPerDigit));

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
  // T3 = x, no_op if x == 0
  __ lw(T0, Address(SP, 5 * kWordSize));  // T0 = xi as Smi.
  __ lw(T1, Address(SP, 6 * kWordSize));  // T1 = x_digits.
  __ sll(T0, T0, 1);
  __ addu(T1, T0, T1);
  __ lw(T3, FieldAddress(T1, TypedData::data_offset()));
  __ beq(T3, ZR, &done);

  // T6 = SmiUntag(n), no_op if n == 0
  __ lw(T6, Address(SP, 0 * kWordSize));
  __ SmiUntag(T6);
  __ beq(T6, ZR, &done);
  __ delay_slot()->addiu(T6, T6, Immediate(-1));  // ... while (n-- > 0).

  // T4 = mip = &m_digits[i >> 1]
  __ lw(T0, Address(SP, 3 * kWordSize));  // T0 = i as Smi.
  __ lw(T1, Address(SP, 4 * kWordSize));  // T1 = m_digits.
  __ sll(T0, T0, 1);
  __ addu(T1, T0, T1);
  __ addiu(T4, T1, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T5 = ajp = &a_digits[j >> 1]
  __ lw(T0, Address(SP, 1 * kWordSize));  // T0 = j as Smi.
  __ lw(T1, Address(SP, 2 * kWordSize));  // T1 = a_digits.
  __ sll(T0, T0, 1);
  __ addu(T1, T0, T1);
  __ addiu(T5, T1, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T1 = c = 0
  __ mov(T1, ZR);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   T3
  // mip: T4
  // ajp: T5
  // c:   T1
  // n-1: T6

  // uint32_t mi = *mip++
  __ lw(T2, Address(T4, 0));

  // uint32_t aj = *ajp
  __ lw(T0, Address(T5, 0));

  // uint64_t t = x*mi + aj + c
  __ multu(T2, T3);  // HI:LO = x*mi.
  __ addiu(T4, T4, Immediate(Bigint::kBytesPerDigit));
  __ mflo(V0);
  __ mfhi(V1);
  __ addu(V0, V0, T0);  // V0 = low32(x*mi) + aj.
  __ sltu(T7, V0, T0);  // T7 = carry out of low32(x*mi) + aj.
  __ addu(V1, V1, T7);  // V1:V0 = x*mi + aj.
  __ addu(T0, V0, T1);  // T0 = low32(x*mi + aj) + c.
  __ sltu(T7, T0, T1);  // T7 = carry out of low32(x*mi + aj) + c.
  __ addu(T1, V1, T7);  // T1 = c = high32(x*mi + aj + c).

  // *ajp++ = low32(t) = T0
  __ sw(T0, Address(T5, 0));
  __ addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));

  // while (n-- > 0)
  __ bgtz(T6, &muladd_loop);
  __ delay_slot()->addiu(T6, T6, Immediate(-1));  // --n

  __ beq(T1, ZR, &done);

  // *ajp++ += c
  __ lw(T0, Address(T5, 0));
  __ addu(T0, T0, T1);
  __ sltu(T1, T0, T1);
  __ sw(T0, Address(T5, 0));
  __ beq(T1, ZR, &done);
  __ delay_slot()->addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ lw(T0, Address(T5, 0));
  __ addiu(T0, T0, Immediate(1));
  __ sw(T0, Address(T5, 0));
  __ beq(T0, ZR, &propagate_carry_loop);
  __ delay_slot()->addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));

  __ Bind(&done);
  __ addiu(V0, ZR, Immediate(Smi::RawValue(1)));  // One digit processed.
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

  // T4 = xip = &x_digits[i >> 1]
  __ lw(T2, Address(SP, 2 * kWordSize));  // T2 = i as Smi.
  __ lw(T3, Address(SP, 3 * kWordSize));  // T3 = x_digits.
  __ sll(T0, T2, 1);
  __ addu(T3, T0, T3);
  __ addiu(T4, T3, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T3 = x = *xip++, return if x == 0
  Label x_zero;
  __ lw(T3, Address(T4, 0));
  __ beq(T3, ZR, &x_zero);
  __ delay_slot()->addiu(T4, T4, Immediate(Bigint::kBytesPerDigit));

  // T5 = ajp = &a_digits[i]
  __ lw(T1, Address(SP, 1 * kWordSize));  // a_digits
  __ sll(T0, T2, 2);                      // j == 2*i, i is Smi.
  __ addu(T1, T0, T1);
  __ addiu(T5, T1, Immediate(TypedData::data_offset() - kHeapObjectTag));

  // T6:T0 = t = x*x + *ajp
  __ lw(T0, Address(T5, 0));  // *ajp.
  __ mthi(ZR);
  __ mtlo(T0);
  __ maddu(T3, T3);  // HI:LO = T3*T3 + *ajp.
  __ mfhi(T6);
  __ mflo(T0);

  // *ajp++ = low32(t) = R0
  __ sw(T0, Address(T5, 0));
  __ addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));

  // T6 = low32(c) = high32(t)
  // T7 = high32(c) = 0
  __ mov(T7, ZR);

  // int n = used - i - 1; while (--n >= 0) ...
  __ lw(T0, Address(SP, 0 * kWordSize));  // used is Smi
  __ subu(V0, T0, T2);
  __ SmiUntag(V0);  // V0 = used - i
  // int n = used - i - 2; if (n >= 0) ... while (n-- > 0)
  __ addiu(V0, V0, Immediate(-2));

  Label loop, done;
  __ bltz(V0, &done);

  __ Bind(&loop);
  // x:   T3
  // xip: T4
  // ajp: T5
  // c:   T7:T6
  // t:   A2:A1:A0 (not live at loop entry)
  // n:   V0

  // uint32_t xi = *xip++
  __ lw(T2, Address(T4, 0));
  __ addiu(T4, T4, Immediate(Bigint::kBytesPerDigit));

  // uint32_t aj = *ajp
  __ lw(T0, Address(T5, 0));

  // uint96_t t = T7:T6:T0 = 2*x*xi + aj + c
  __ multu(T2, T3);
  __ mfhi(A1);
  __ mflo(A0);  // A1:A0 = x*xi.
  __ srl(A2, A1, 31);
  __ sll(A1, A1, 1);
  __ srl(T1, A0, 31);
  __ or_(A1, A1, T1);
  __ sll(A0, A0, 1);  // A2:A1:A0 = 2*x*xi.
  __ addu(A0, A0, T0);
  __ sltu(T1, A0, T0);
  __ addu(A1, A1, T1);  // No carry out possible; A2:A1:A0 = 2*x*xi + aj.
  __ addu(T0, A0, T6);
  __ sltu(T1, T0, T6);
  __ addu(T6, A1, T1);  // No carry out; A2:T6:T0 = 2*x*xi + aj + low32(c).
  __ addu(T6, T6, T7);  // No carry out; A2:T6:T0 = 2*x*xi + aj + c.
  __ mov(T7, A2);       // T7:T6:T0 = 2*x*xi + aj + c.

  // *ajp++ = low32(t) = T0
  __ sw(T0, Address(T5, 0));
  __ addiu(T5, T5, Immediate(Bigint::kBytesPerDigit));

  // while (n-- > 0)
  __ bgtz(V0, &loop);
  __ delay_slot()->addiu(V0, V0, Immediate(-1));  // --n

  __ Bind(&done);
  // uint32_t aj = *ajp
  __ lw(T0, Address(T5, 0));

  // uint64_t t = aj + c
  __ addu(T6, T6, T0);
  __ sltu(T1, T6, T0);
  __ addu(T7, T7, T1);

  // *ajp = low32(t) = T6
  // *(ajp + 1) = high32(t) = T7
  __ sw(T6, Address(T5, 0));
  __ sw(T7, Address(T5, Bigint::kBytesPerDigit));

  __ Bind(&x_zero);
  __ addiu(V0, ZR, Immediate(Smi::RawValue(1)));  // One digit processed.
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

  // T4 = args
  __ lw(T4, Address(SP, 2 * kWordSize));  // args

  // T3 = rho = args[2]
  __ lw(T3, FieldAddress(
                T4, TypedData::data_offset() + 2 * Bigint::kBytesPerDigit));

  // T2 = d = digits[i >> 1]
  __ lw(T0, Address(SP, 0 * kWordSize));  // T0 = i as Smi.
  __ lw(T1, Address(SP, 1 * kWordSize));  // T1 = digits.
  __ sll(T0, T0, 1);
  __ addu(T1, T0, T1);
  __ lw(T2, FieldAddress(T1, TypedData::data_offset()));

  // HI:LO = t = rho*d
  __ multu(T2, T3);

  // args[4] = t mod DIGIT_BASE = low32(t)
  __ mflo(T0);
  __ sw(T0, FieldAddress(
                T4, TypedData::data_offset() + 4 * Bigint::kBytesPerDigit));

  __ addiu(V0, ZR, Immediate(Smi::RawValue(1)));  // One digit processed.
  __ Ret();
}


// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in T0.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, is_smi);
  __ LoadClassId(CMPRES1, T0);
  __ BranchNotEqual(CMPRES1, Immediate(kDoubleCid), not_double_smi);
  // Fall through with Double in T0.
}


// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register V0. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler, RelationOperator rel_op) {
  Label is_smi, double_op, no_NaN, fall_through;
  __ Comment("CompareDoubles Intrinsic");

  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Both arguments are double, right operand is in T0.
  __ LoadDFromOffset(D1, T0, Double::value_offset() - kHeapObjectTag);
  __ Bind(&double_op);
  __ lw(T0, Address(SP, 1 * kWordSize));  // Left argument.
  __ LoadDFromOffset(D0, T0, Double::value_offset() - kHeapObjectTag);
  // Now, left is in D0, right is in D1.

  __ cund(D0, D1);  // Check for NaN.
  __ bc1f(&no_NaN);
  __ LoadObject(V0, Bool::False());  // Return false if either is NaN.
  __ Ret();
  __ Bind(&no_NaN);

  switch (rel_op) {
    case EQ:
      __ ceqd(D0, D1);
      break;
    case LT:
      __ coltd(D0, D1);
      break;
    case LE:
      __ coled(D0, D1);
      break;
    case GT:
      __ coltd(D1, D0);
      break;
    case GE:
      __ coled(D1, D0);
      break;
    default: {
      // Only passing the above conditions to this function.
      UNREACHABLE();
      break;
    }
  }

  Label is_true;
  __ bc1t(&is_true);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();


  __ Bind(&is_smi);
  __ SmiUntag(T0);
  __ mtc1(T0, STMP1);
  __ b(&double_op);
  __ delay_slot()->cvtdw(D1, STMP1);


  __ Bind(&fall_through);
}


void Intrinsifier::Double_greaterThan(Assembler* assembler) {
  CompareDoubles(assembler, GT);
}


void Intrinsifier::Double_greaterEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, GE);
}


void Intrinsifier::Double_lessThan(Assembler* assembler) {
  CompareDoubles(assembler, LT);
}


void Intrinsifier::Double_equal(Assembler* assembler) {
  CompareDoubles(assembler, EQ);
}


void Intrinsifier::Double_lessEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, LE);
}


// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler, Token::Kind kind) {
  Label fall_through, is_smi, double_op;

  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Both arguments are double, right operand is in T0.
  __ lwc1(F2, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F3, FieldAddress(T0, Double::value_offset() + kWordSize));
  __ Bind(&double_op);
  __ lw(T0, Address(SP, 1 * kWordSize));  // Left argument.
  __ lwc1(F0, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F1, FieldAddress(T0, Double::value_offset() + kWordSize));
  switch (kind) {
    case Token::kADD:
      __ addd(D0, D0, D1);
      break;
    case Token::kSUB:
      __ subd(D0, D0, D1);
      break;
    case Token::kMUL:
      __ muld(D0, D0, D1);
      break;
    case Token::kDIV:
      __ divd(D0, D0, D1);
      break;
    default:
      UNREACHABLE();
  }
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));

  __ Bind(&is_smi);
  __ SmiUntag(T0);
  __ mtc1(T0, STMP1);
  __ b(&double_op);
  __ delay_slot()->cvtdw(D1, STMP1);

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
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);

  // Is Smi.
  __ SmiUntag(T0);
  __ mtc1(T0, F4);
  __ cvtdw(D1, F4);

  __ lw(T0, Address(SP, 1 * kWordSize));
  __ lwc1(F0, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F1, FieldAddress(T0, Double::value_offset() + kWordSize));
  __ muld(D0, D0, D1);
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));
  __ Bind(&fall_through);
}


void Intrinsifier::DoubleFromInteger(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);

  // Is Smi.
  __ SmiUntag(T0);
  __ mtc1(T0, F4);
  __ cvtdw(D0, F4);
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));
  __ Bind(&fall_through);
}


void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  Label is_true;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lwc1(F0, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F1, FieldAddress(T0, Double::value_offset() + kWordSize));
  __ cund(D0, D0);  // Check for NaN.
  __ bc1t(&is_true);
  __ LoadObject(V0, Bool::False());  // Return false if either is NaN.
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();
}


void Intrinsifier::Double_getIsInfinite(Assembler* assembler) {
  Label not_inf;
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T1, FieldAddress(T0, Double::value_offset()));
  __ lw(T2, FieldAddress(T0, Double::value_offset() + kWordSize));
  // If the low word isn't zero, then it isn't infinity.
  __ bne(T1, ZR, &not_inf);
  // Mask off the sign bit.
  __ AndImmediate(T2, T2, 0x7FFFFFFF);
  // Compare with +infinity.
  __ BranchNotEqual(T2, Immediate(0x7FF00000), &not_inf);

  __ LoadObject(V0, Bool::True());
  __ Ret();

  __ Bind(&not_inf);
  __ LoadObject(V0, Bool::False());
  __ Ret();
}


void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  Label is_false, is_true, is_zero;
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ LoadDFromOffset(D0, T0, Double::value_offset() - kHeapObjectTag);

  __ cund(D0, D0);
  __ bc1t(&is_false);  // NaN -> false.

  __ LoadImmediate(D1, 0.0);
  __ ceqd(D0, D1);
  __ bc1t(&is_zero);  // Check for negative zero.

  __ coled(D1, D0);
  __ bc1t(&is_false);  // >= 0 -> false.

  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();

  __ Bind(&is_false);
  __ LoadObject(V0, Bool::False());
  __ Ret();

  __ Bind(&is_zero);
  // Check for negative zero by looking at the sign bit.
  __ mfc1(T0, F1);                     // Moves bits 32...63 of D0 to T0.
  __ srl(T0, T0, 31);                  // Get the sign bit down to bit 0 of T0.
  __ andi(CMPRES1, T0, Immediate(1));  // Check if the bit is set.
  __ bne(T0, ZR, &is_true);            // Sign bit set. True.
  __ b(&is_false);
}


void Intrinsifier::DoubleToInteger(Assembler* assembler) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ LoadDFromOffset(D0, T0, Double::value_offset() - kHeapObjectTag);

  __ truncwd(F2, D0);
  __ mfc1(V0, F2);

  // Overflow is signaled with minint.
  Label fall_through;
  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES1, V0, TMP);
  __ bltz(CMPRES1, &fall_through);
  __ Ret();
  __ delay_slot()->SmiTag(V0);
  __ Bind(&fall_through);
}


void Intrinsifier::MathSqrt(Assembler* assembler) {
  Label fall_through, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Argument is double and is in T0.
  __ LoadDFromOffset(D1, T0, Double::value_offset() - kHeapObjectTag);
  __ Bind(&double_op);
  __ sqrtd(D0, D1);
  const Class& double_class =
      Class::Handle(Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));

  __ Bind(&is_smi);
  __ SmiUntag(T0);
  __ mtc1(T0, F2);
  __ b(&double_op);
  __ delay_slot()->cvtdw(D1, F2);
  __ Bind(&fall_through);
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
  __ lw(T0, Address(SP, 0 * kWordSize));
  // Field '_state'.
  __ lw(T1, FieldAddress(T0, state_field.Offset()));

  // Addresses of _state[0] and _state[1].
  const intptr_t scale = Instance::ElementSizeFor(kTypedDataUint32ArrayCid);
  const intptr_t offset = Instance::DataOffsetFor(kTypedDataUint32ArrayCid);
  const Address& addr_0 = FieldAddress(T1, 0 * scale + offset);
  const Address& addr_1 = FieldAddress(T1, 1 * scale + offset);

  __ LoadImmediate(T0, a_int32_value);
  __ lw(T2, addr_0);
  __ lw(T3, addr_1);
  __ mtlo(T3);
  __ mthi(ZR);  // HI:LO <- ZR:T3  Zero extend T3 into HI.
  // 64-bit multiply and accumulate into T6:T3.
  __ maddu(T0, T2);  // HI:LO <- HI:LO + T0 * T2.
  __ mflo(T3);
  __ mfhi(T6);
  __ sw(T3, addr_0);
  __ sw(T6, addr_1);
  __ Ret();
}


void Intrinsifier::ObjectEquals(Assembler* assembler) {
  Label is_true;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T1, Address(SP, 1 * kWordSize));
  __ beq(T0, T1, &is_true);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();
}


enum RangeCheckCondition { kIfNotInRange, kIfInRange };


static void RangeCheck(Assembler* assembler,
                       Register val,
                       Register tmp,
                       intptr_t low,
                       intptr_t high,
                       RangeCheckCondition cc,
                       Label* target) {
  __ AddImmediate(tmp, val, -low);
  if (cc == kIfInRange) {
    __ BranchUnsignedLessEqual(tmp, Immediate(high - low), target);
  } else {
    ASSERT(cc == kIfNotInRange);
    __ BranchUnsignedGreater(tmp, Immediate(high - low), target);
  }
}


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
  Label fall_through, use_canonical_type, not_integer, not_double;
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ LoadClassIdMayBeSmi(T1, T0);

  // Closures are handled in the runtime.
  __ BranchEqual(T1, Immediate(kClosureCid), &fall_through);

  __ BranchUnsignedGreaterEqual(T1, Immediate(kNumPredefinedCids),
                                &use_canonical_type);

  __ BranchNotEqual(T1, Immediate(kDoubleCid), &not_double);
  // Object is a double.
  __ LoadIsolate(T1);
  __ LoadFromOffset(T1, T1, Isolate::object_store_offset());
  __ LoadFromOffset(V0, T1, ObjectStore::double_type_offset());
  __ Ret();

  __ Bind(&not_double);
  JumpIfNotInteger(assembler, T1, T2, &not_integer);
  // Object is an integer.
  __ LoadIsolate(T1);
  __ LoadFromOffset(T1, T1, Isolate::object_store_offset());
  __ LoadFromOffset(V0, T1, ObjectStore::int_type_offset());
  __ Ret();

  __ Bind(&not_integer);
  JumpIfNotString(assembler, T1, T2, &use_canonical_type);
  // Object is a string.
  __ LoadIsolate(T1);
  __ LoadFromOffset(T1, T1, Isolate::object_store_offset());
  __ LoadFromOffset(V0, T1, ObjectStore::string_type_offset());
  __ Ret();

  __ Bind(&use_canonical_type);
  __ LoadClassById(T2, T1);
  __ lhu(T1, FieldAddress(T2, Class::num_type_arguments_offset()));
  __ BranchNotEqual(T1, Immediate(0), &fall_through);

  __ lw(V0, FieldAddress(T2, Class::canonical_type_offset()));
  __ BranchEqual(V0, Object::null_object(), &fall_through);
  __ Ret();

  __ Bind(&fall_through);
}


void Intrinsifier::ObjectHaveSameRuntimeType(Assembler* assembler) {
  Label fall_through, different_cids, equal, not_equal, not_integer;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ LoadClassIdMayBeSmi(T1, T0);

  // Closures are handled in the runtime.
  __ BranchEqual(T1, Immediate(kClosureCid), &fall_through);

  __ lw(T0, Address(SP, 1 * kWordSize));
  __ LoadClassIdMayBeSmi(T2, T0);

  // Check whether class ids match. If class ids don't match objects can still
  // have the same runtime type (e.g. multiple string implementation classes
  // map to a single String type).
  __ BranchNotEqual(T1, T2, &different_cids);

  // Objects have the same class and neither is a closure.
  // Check if there are no type arguments. In this case we can return true.
  // Otherwise fall through into the runtime to handle comparison.
  __ LoadClassById(T2, T1);
  __ lhu(T1, FieldAddress(T2, Class::num_type_arguments_offset()));
  __ BranchNotEqual(T1, Immediate(0), &fall_through);

  __ Bind(&equal);
  __ LoadObject(V0, Bool::True());
  __ Ret();

  // Class ids are different. Check if we are comparing runtime types of
  // two strings (with different representations) or two integers.
  __ Bind(&different_cids);
  __ BranchUnsignedGreaterEqual(T1, Immediate(kNumPredefinedCids), &not_equal);

  // Check if both are integers.
  JumpIfNotInteger(assembler, T1, T0, &not_integer);
  JumpIfInteger(assembler, T2, T0, &equal);
  __ b(&not_equal);

  __ Bind(&not_integer);
  // Check if both are strings.
  JumpIfNotString(assembler, T1, T0, &not_equal);
  JumpIfString(assembler, T2, T0, &equal);

  // Neither strings nor integers and have different class ids.
  __ Bind(&not_equal);
  __ LoadObject(V0, Bool::False());
  __ Ret();

  __ Bind(&fall_through);
}


void Intrinsifier::String_getHashCode(Assembler* assembler) {
  Label fall_through;
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(V0, FieldAddress(T0, String::hash_offset()));
  __ beq(V0, ZR, &fall_through);
  __ Ret();
  __ Bind(&fall_through);  // Hash not yet computed.
}


void GenerateSubstringMatchesSpecialization(Assembler* assembler,
                                            intptr_t receiver_cid,
                                            intptr_t other_cid,
                                            Label* return_true,
                                            Label* return_false) {
  __ SmiUntag(A1);
  __ lw(T1, FieldAddress(A0, String::length_offset()));  // this.length
  __ SmiUntag(T1);
  __ lw(T2, FieldAddress(A2, String::length_offset()));  // other.length
  __ SmiUntag(T2);

  // if (other.length == 0) return true;
  __ beq(T2, ZR, return_true);

  // if (start < 0) return false;
  __ bltz(A1, return_false);

  // if (start + other.length > this.length) return false;
  __ addu(T0, A1, T2);
  __ BranchSignedGreater(T0, T1, return_false);

  if (receiver_cid == kOneByteStringCid) {
    __ AddImmediate(A0, A0, OneByteString::data_offset() - kHeapObjectTag);
    __ addu(A0, A0, A1);
  } else {
    ASSERT(receiver_cid == kTwoByteStringCid);
    __ AddImmediate(A0, A0, TwoByteString::data_offset() - kHeapObjectTag);
    __ addu(A0, A0, A1);
    __ addu(A0, A0, A1);
  }
  if (other_cid == kOneByteStringCid) {
    __ AddImmediate(A2, A2, OneByteString::data_offset() - kHeapObjectTag);
  } else {
    ASSERT(other_cid == kTwoByteStringCid);
    __ AddImmediate(A2, A2, TwoByteString::data_offset() - kHeapObjectTag);
  }

  // i = 0
  __ LoadImmediate(T0, 0);

  // do
  Label loop;
  __ Bind(&loop);

  if (receiver_cid == kOneByteStringCid) {
    __ lbu(T3, Address(A0, 0));  // this.codeUnitAt(i + start)
  } else {
    __ lhu(T3, Address(A0, 0));  // this.codeUnitAt(i + start)
  }
  if (other_cid == kOneByteStringCid) {
    __ lbu(T4, Address(A2, 0));  // other.codeUnitAt(i)
  } else {
    __ lhu(T4, Address(A2, 0));  // other.codeUnitAt(i)
  }
  __ bne(T3, T4, return_false);

  // i++, while (i < len)
  __ AddImmediate(T0, T0, 1);
  __ AddImmediate(A0, A0, receiver_cid == kOneByteStringCid ? 1 : 2);
  __ AddImmediate(A2, A2, other_cid == kOneByteStringCid ? 1 : 2);
  __ BranchSignedLess(T0, T2, &loop);

  __ b(return_true);
}


// bool _substringMatches(int start, String other)
// This intrinsic handles a OneByteString or TwoByteString receiver with a
// OneByteString other.
void Intrinsifier::StringBaseSubstringMatches(Assembler* assembler) {
  Label fall_through, return_true, return_false, try_two_byte;
  __ lw(A0, Address(SP, 2 * kWordSize));  // this
  __ lw(A1, Address(SP, 1 * kWordSize));  // start
  __ lw(A2, Address(SP, 0 * kWordSize));  // other

  __ andi(CMPRES1, A1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // 'start' is not a Smi.

  __ LoadClassId(CMPRES1, A2);
  __ BranchNotEqual(CMPRES1, Immediate(kOneByteStringCid), &fall_through);

  __ LoadClassId(CMPRES1, A0);
  __ BranchNotEqual(CMPRES1, Immediate(kOneByteStringCid), &try_two_byte);

  GenerateSubstringMatchesSpecialization(assembler, kOneByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&try_two_byte);
  __ LoadClassId(CMPRES1, A0);
  __ BranchNotEqual(CMPRES1, Immediate(kTwoByteStringCid), &fall_through);

  GenerateSubstringMatchesSpecialization(assembler, kTwoByteStringCid,
                                         kOneByteStringCid, &return_true,
                                         &return_false);

  __ Bind(&return_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();

  __ Bind(&return_false);
  __ LoadObject(V0, Bool::False());
  __ Ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseCharAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;

  __ lw(T1, Address(SP, 0 * kWordSize));  // Index.
  __ lw(T0, Address(SP, 1 * kWordSize));  // String.

  // Checks.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);                    // Index is not a Smi.
  __ lw(T2, FieldAddress(T0, String::length_offset()));  // Range check.
  // Runtime throws exception.
  __ BranchUnsignedGreaterEqual(T1, T2, &fall_through);
  __ LoadClassId(CMPRES1, T0);  // Class ID check.
  __ BranchNotEqual(CMPRES1, Immediate(kOneByteStringCid),
                    &try_two_byte_string);

  // Grab byte and return.
  __ SmiUntag(T1);
  __ addu(T2, T0, T1);
  __ lbu(T2, FieldAddress(T2, OneByteString::data_offset()));
  __ BranchUnsignedGreaterEqual(
      T2, Immediate(Symbols::kNumberOfOneCharCodeSymbols), &fall_through);
  __ lw(V0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(V0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ sll(T2, T2, 2);
  __ addu(T2, T2, V0);
  __ Ret();
  __ delay_slot()->lw(V0, Address(T2));

  __ Bind(&try_two_byte_string);
  __ BranchNotEqual(CMPRES1, Immediate(kTwoByteStringCid), &fall_through);
  ASSERT(kSmiTagShift == 1);
  __ addu(T2, T0, T1);
  __ lhu(T2, FieldAddress(T2, TwoByteString::data_offset()));
  __ BranchUnsignedGreaterEqual(
      T2, Immediate(Symbols::kNumberOfOneCharCodeSymbols), &fall_through);
  __ lw(V0, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(V0, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ sll(T2, T2, 2);
  __ addu(T2, T2, V0);
  __ Ret();
  __ delay_slot()->lw(V0, Address(T2));

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseIsEmpty(Assembler* assembler) {
  Label is_true;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(T0, FieldAddress(T0, String::length_offset()));

  __ beq(T0, ZR, &is_true);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
  __ Ret();
}


void Intrinsifier::OneByteString_getHashCode(Assembler* assembler) {
  Label no_hash;

  __ lw(T1, Address(SP, 0 * kWordSize));
  __ lw(V0, FieldAddress(T1, String::hash_offset()));
  __ beq(V0, ZR, &no_hash);
  __ Ret();  // Return if already computed.
  __ Bind(&no_hash);

  __ lw(T2, FieldAddress(T1, String::length_offset()));

  Label done;
  // If the string is empty, set the hash to 1, and return.
  __ BranchEqual(T2, Immediate(Smi::RawValue(0)), &done);
  __ delay_slot()->mov(V0, ZR);

  __ SmiUntag(T2);
  __ AddImmediate(T3, T1, OneByteString::data_offset() - kHeapObjectTag);
  __ addu(T4, T3, T2);
  // V0: Hash code, untagged integer.
  // T1: Instance of OneByteString.
  // T2: String length, untagged integer.
  // T3: String data start.
  // T4: String data end.

  Label loop;
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ Bind(&loop);
  __ lbu(T5, Address(T3));
  // T5: ch.
  __ addiu(T3, T3, Immediate(1));
  __ addu(V0, V0, T5);
  __ sll(T6, V0, 10);
  __ addu(V0, V0, T6);
  __ srl(T6, V0, 6);
  __ bne(T3, T4, &loop);
  __ delay_slot()->xor_(V0, V0, T6);

  // Finalize.
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ sll(T6, V0, 3);
  __ addu(V0, V0, T6);
  __ srl(T6, V0, 11);
  __ xor_(V0, V0, T6);
  __ sll(T6, V0, 15);
  __ addu(V0, V0, T6);
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ LoadImmediate(T6, (static_cast<intptr_t>(1) << String::kHashBits) - 1);
  __ and_(V0, V0, T6);
  __ Bind(&done);

  __ LoadImmediate(T2, 1);
  __ movz(V0, T2, V0);  // If V0 is 0, set to 1.
  __ SmiTag(V0);

  __ Ret();
  __ delay_slot()->sw(V0, FieldAddress(T1, String::hash_offset()));
}


// Allocates one-byte string of length 'end - start'. The content is not
// initialized.
// 'length-reg' (T2) contains tagged length.
// Returns new string as tagged pointer in V0.
static void TryAllocateOnebyteString(Assembler* assembler,
                                     Label* ok,
                                     Label* failure) {
  const Register length_reg = T2;
  NOT_IN_PRODUCT(__ MaybeTraceAllocation(kOneByteStringCid, V0, failure));
  __ mov(T6, length_reg);  // Save the length register.
  // TODO(koda): Protect against negative length and overflow here.
  __ SmiUntag(length_reg);
  const intptr_t fixed_size_plus_alignment_padding =
      sizeof(RawString) + kObjectAlignment - 1;
  __ AddImmediate(length_reg, fixed_size_plus_alignment_padding);
  __ LoadImmediate(TMP, ~(kObjectAlignment - 1));
  __ and_(length_reg, length_reg, TMP);

  const intptr_t cid = kOneByteStringCid;
  Heap::Space space = Heap::kNew;
  __ lw(T3, Address(THR, Thread::heap_offset()));
  __ lw(V0, Address(T3, Heap::TopOffset(space)));

  // length_reg: allocation size.
  __ addu(T1, V0, length_reg);
  __ BranchUnsignedLess(T1, V0, failure);  // Fail on unsigned overflow.

  // Check if the allocation fits into the remaining space.
  // V0: potential new object start.
  // T1: potential next object start.
  // T2: allocation size.
  // T3: heap.
  __ lw(T4, Address(T3, Heap::EndOffset(space)));
  __ BranchUnsignedGreaterEqual(T1, T4, failure);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ sw(T1, Address(T3, Heap::TopOffset(space)));
  __ AddImmediate(V0, kHeapObjectTag);

  NOT_IN_PRODUCT(__ UpdateAllocationStatsWithSize(cid, T2, T3, space));

  // Initialize the tags.
  // V0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: allocation size.
  {
    Label overflow, done;
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ BranchUnsignedGreater(T2, Immediate(RawObject::SizeTag::kMaxSizeTag),
                             &overflow);
    __ b(&done);
    __ delay_slot()->sll(T2, T2, shift);
    __ Bind(&overflow);
    __ mov(T2, ZR);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    // T2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));
    __ or_(T2, T2, TMP);
    __ sw(T2, FieldAddress(V0, String::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (T6).
  __ StoreIntoObjectNoBarrier(V0, FieldAddress(V0, String::length_offset()),
                              T6);
  // Clear hash.
  __ b(ok);
  __ delay_slot()->sw(ZR, FieldAddress(V0, String::hash_offset()));
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

  __ lw(T2, Address(SP, kEndIndexOffset));
  __ lw(TMP, Address(SP, kStartIndexOffset));
  __ or_(CMPRES1, T2, TMP);
  __ andi(CMPRES1, CMPRES1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // 'start', 'end' not Smi.

  __ subu(T2, T2, TMP);
  TryAllocateOnebyteString(assembler, &ok, &fall_through);
  __ Bind(&ok);
  // V0: new string as tagged pointer.
  // Copy string.
  __ lw(T3, Address(SP, kStringOffset));
  __ lw(T1, Address(SP, kStartIndexOffset));
  __ SmiUntag(T1);
  __ addu(T3, T3, T1);
  __ AddImmediate(T3, OneByteString::data_offset() - 1);

  // T3: Start address to copy from (untagged).
  // T1: Untagged start index.
  __ lw(T2, Address(SP, kEndIndexOffset));
  __ SmiUntag(T2);
  __ subu(T2, T2, T1);

  // T3: Start address to copy from (untagged).
  // T2: Untagged number of bytes to copy.
  // V0: Tagged result string.
  // T6: Pointer into T3.
  // T7: Pointer into T0.
  // T1: Scratch register.
  Label loop, done;
  __ beq(T2, ZR, &done);
  __ mov(T6, T3);
  __ mov(T7, V0);

  __ Bind(&loop);
  __ lbu(T1, Address(T6, 0));
  __ AddImmediate(T6, 1);
  __ addiu(T2, T2, Immediate(-1));
  __ sb(T1, FieldAddress(T7, OneByteString::data_offset()));
  __ bgtz(T2, &loop);
  __ delay_slot()->addiu(T7, T7, Immediate(1));

  __ Bind(&done);
  __ Ret();
  __ Bind(&fall_through);
}


void Intrinsifier::OneByteStringSetAt(Assembler* assembler) {
  __ lw(T2, Address(SP, 0 * kWordSize));  // Value.
  __ lw(T1, Address(SP, 1 * kWordSize));  // Index.
  __ lw(T0, Address(SP, 2 * kWordSize));  // OneByteString.
  __ SmiUntag(T1);
  __ SmiUntag(T2);
  __ addu(T3, T0, T1);
  __ Ret();
  __ delay_slot()->sb(T2, FieldAddress(T3, OneByteString::data_offset()));
}


void Intrinsifier::OneByteString_allocate(Assembler* assembler) {
  Label fall_through, ok;

  __ lw(T2, Address(SP, 0 * kWordSize));  // Length.
  TryAllocateOnebyteString(assembler, &ok, &fall_through);

  __ Bind(&ok);
  __ Ret();

  __ Bind(&fall_through);
}


// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
static void StringEquality(Assembler* assembler, intptr_t string_cid) {
  Label fall_through, is_true, is_false, loop;
  __ lw(T0, Address(SP, 1 * kWordSize));  // This.
  __ lw(T1, Address(SP, 0 * kWordSize));  // Other.

  // Are identical?
  __ beq(T0, T1, &is_true);

  // Is other OneByteString?
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, &fall_through);  // Other is Smi.
  __ LoadClassId(CMPRES1, T1);         // Class ID check.
  __ BranchNotEqual(CMPRES1, Immediate(string_cid), &fall_through);

  // Have same length?
  __ lw(T2, FieldAddress(T0, String::length_offset()));
  __ lw(T3, FieldAddress(T1, String::length_offset()));
  __ bne(T2, T3, &is_false);

  // Check contents, no fall-through possible.
  ASSERT((string_cid == kOneByteStringCid) ||
         (string_cid == kTwoByteStringCid));
  __ SmiUntag(T2);
  __ Bind(&loop);
  __ AddImmediate(T2, -1);
  __ BranchSignedLess(T2, Immediate(0), &is_true);
  if (string_cid == kOneByteStringCid) {
    __ lbu(V0, FieldAddress(T0, OneByteString::data_offset()));
    __ lbu(V1, FieldAddress(T1, OneByteString::data_offset()));
    __ AddImmediate(T0, 1);
    __ AddImmediate(T1, 1);
  } else if (string_cid == kTwoByteStringCid) {
    __ lhu(V0, FieldAddress(T0, OneByteString::data_offset()));
    __ lhu(V1, FieldAddress(T1, OneByteString::data_offset()));
    __ AddImmediate(T0, 2);
    __ AddImmediate(T1, 2);
  } else {
    UNIMPLEMENTED();
  }
  __ bne(V0, V1, &is_false);
  __ b(&loop);

  __ Bind(&is_false);
  __ LoadObject(V0, Bool::False());
  __ Ret();
  __ Bind(&is_true);
  __ LoadObject(V0, Bool::True());
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
  // start_index smi is located at 0.

  // Incoming registers:
  // T0: Function. (Will be reloaded with the specialized matcher function.)
  // S4: Arguments descriptor. (Will be preserved.)
  // S5: Unknown. (Must be GC safe on tail call.)

  // Load the specialized function pointer into T0. Leverage the fact the
  // string CIDs as well as stored function pointers are in sequence.
  __ lw(T1, Address(SP, kRegExpParamOffset));
  __ lw(T3, Address(SP, kStringParamOffset));
  __ LoadClassId(T2, T3);
  __ AddImmediate(T2, -kOneByteStringCid);
  __ sll(T2, T2, kWordSizeLog2);
  __ addu(T2, T2, T1);
  __ lw(T0,
        FieldAddress(T2, RegExp::function_offset(kOneByteStringCid, sticky)));

  // Registers are now set up for the lazy compile stub. It expects the function
  // in T0, the argument descriptor in S4, and IC-Data in S5.
  __ mov(S5, ZR);

  // Tail-call the function.
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ lw(T3, FieldAddress(T0, Function::entry_point_offset()));
  __ jr(T3);
}


// On stack: user tag (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  // T1: Isolate.
  __ LoadIsolate(T1);
  // V0: Current user tag.
  __ lw(V0, Address(T1, Isolate::current_tag_offset()));
  // T2: UserTag.
  __ lw(T2, Address(SP, +0 * kWordSize));
  // Set Isolate::current_tag_.
  __ sw(T2, Address(T1, Isolate::current_tag_offset()));
  // T2: UserTag's tag.
  __ lw(T2, FieldAddress(T2, UserTag::tag_offset()));
  // Set Isolate::user_tag_.
  __ sw(T2, Address(T1, Isolate::user_tag_offset()));
  __ Ret();
  __ delay_slot()->sw(T2, Address(T1, Isolate::user_tag_offset()));
}


void Intrinsifier::UserTag_defaultTag(Assembler* assembler) {
  __ LoadIsolate(V0);
  __ Ret();
  __ delay_slot()->lw(V0, Address(V0, Isolate::default_tag_offset()));
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  __ LoadIsolate(V0);
  __ Ret();
  __ delay_slot()->lw(V0, Address(V0, Isolate::current_tag_offset()));
}


void Intrinsifier::Timeline_isDartStreamEnabled(Assembler* assembler) {
  if (!FLAG_support_timeline) {
    __ LoadObject(V0, Bool::False());
    __ Ret();
    return;
  }
  // Load TimelineStream*.
  __ lw(V0, Address(THR, Thread::dart_stream_offset()));
  // Load uintptr_t from TimelineStream*.
  __ lw(T0, Address(V0, TimelineStream::enabled_offset()));
  __ LoadObject(V0, Bool::True());
  __ LoadObject(V1, Bool::False());
  __ Ret();
  __ delay_slot()->movz(V0, V1, T0);  // V0 = (T0 == 0) ? V1 : V0.
}


void Intrinsifier::ClearAsyncThreadStackTrace(Assembler* assembler) {
  __ LoadObject(V0, Object::null_object());
  __ sw(V0, Address(THR, Thread::async_stack_trace_offset()));
  __ Ret();
}


void Intrinsifier::SetAsyncThreadStackTrace(Assembler* assembler) {
  __ lw(V0, Address(THR, Thread::async_stack_trace_offset()));
  __ LoadObject(V0, Object::null_object());
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
