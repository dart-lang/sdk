// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/flow_graph_compiler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);


#define __ assembler->


intptr_t Intrinsifier::ParameterSlotFromSp() { return -1; }


static intptr_t ComputeObjectArrayTypeArgumentsOffset() {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::Handle(
      core_lib.LookupClassAllowPrivate(Symbols::_List()));
  ASSERT(!cls.IsNull());
  ASSERT(cls.NumTypeArguments() == 1);
  const intptr_t field_offset = cls.type_arguments_field_offset();
  ASSERT(field_offset != Class::kNoTypeArguments);
  return field_offset;
}


// Intrinsify only for Smi value and index. Non-smi values need a store buffer
// update. Array length is always a Smi.
void Intrinsifier::ObjectArraySetIndexed(Assembler* assembler) {
  Label fall_through;

  if (FLAG_enable_type_checks) {
    const intptr_t type_args_field_offset =
        ComputeObjectArrayTypeArgumentsOffset();
    // Inline simple tests (Smi, null), fallthrough if not positive.
    Label checked_ok;
    __ ldr(R2, Address(SP, 0 * kWordSize));  // Value.

    // Null value is valid for any type.
    __ CompareObject(R2, Object::null_object(), PP);
    __ b(&checked_ok, EQ);

    __ ldr(R1, Address(SP, 2 * kWordSize));  // Array.
    __ ldr(R1, FieldAddress(R1, type_args_field_offset));

    // R1: Type arguments of array.
    __ CompareObject(R1, Object::null_object(), PP);
    __ b(&checked_ok, EQ);

    // Check if it's dynamic.
    // Get type at index 0.
    __ ldr(R0, FieldAddress(R1, TypeArguments::type_at_offset(0)));
    __ CompareObject(R0, Type::ZoneHandle(Type::DynamicType()), PP);
    __ b(&checked_ok, EQ);

    // Check for int and num.
    __ tsti(R2, Immediate(Immediate(kSmiTagMask)));  // Value is Smi?
    __ b(&fall_through, NE);  // Non-smi value.
    __ CompareObject(R0, Type::ZoneHandle(Type::IntType()), PP);
    __ b(&checked_ok, EQ);
    __ CompareObject(R0, Type::ZoneHandle(Type::Number()), PP);
    __ b(&fall_through, NE);
    __ Bind(&checked_ok);
  }
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
  __ TryAllocate(cls, &fall_through, R0, R1, kNoPP);

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
  __ LoadImmediate(R1, 0, kNoPP);
  __ str(R1, FieldAddress(R0, GrowableObjectArray::length_offset()));
  __ ret();  // Returns the newly allocated object in R0.

  __ Bind(&fall_through);
}


void Intrinsifier::GrowableArrayGetIndexed(Assembler* assembler) {
  Label fall_through;

  __ ldr(R0, Address(SP, + 0 * kWordSize));  // Index
  __ ldr(R1, Address(SP, + 1 * kWordSize));  // Array

  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // Index is not an smi, fall through.

  // Range check.
  __ ldr(R6, FieldAddress(R1, GrowableObjectArray::length_offset()));
  __ cmp(R0, Operand(R6));
  __ b(&fall_through, CS);

  ASSERT(kSmiTagShift == 1);
  // array element at R6 + R0 * 4 + Array::data_offset - 1
  __ ldr(R6, FieldAddress(R1, GrowableObjectArray::data_offset()));  // Data
  __ add(R6, R6, Operand(R0, LSL, 2));
  __ ldr(R0, FieldAddress(R6, Array::data_offset()));
  __ ret();
  __ Bind(&fall_through);
}


// Set value into growable object array at specified index.
// On stack: growable array (+2), index (+1), value (+0).
void Intrinsifier::GrowableArraySetIndexed(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ ldr(R1, Address(SP, 1 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 2 * kWordSize));  // GrowableArray.
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // Non-smi index.
  // Range check using _length field.
  __ ldr(R2, FieldAddress(R0, GrowableObjectArray::length_offset()));
  __ cmp(R1, Operand(R2));
  // Runtime throws exception.
  __ b(&fall_through, CS);
  __ ldr(R0, FieldAddress(R0, GrowableObjectArray::data_offset()));  // data.
  __ ldr(R2, Address(SP, 0 * kWordSize));  // Value.
  // Note that R1 is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ add(R1, R0, Operand(R1, LSL, 2));
  __ StoreIntoObject(R0,
                     FieldAddress(R1, Array::data_offset()),
                     R2);
  __ ret();
  __ Bind(&fall_through);
}


// Set length of growable object array. The length cannot
// be greater than the length of the data container.
// On stack: growable array (+1), length (+0).
void Intrinsifier::GrowableArraySetLength(Assembler* assembler) {
  Label fall_through;
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Growable array.
  __ ldr(R1, Address(SP, 0 * kWordSize));  // Length value.
  __ tsti(R1, Immediate(kSmiTagMask));  // Check for Smi.
  __ b(&fall_through, NE);
  __ str(R1, FieldAddress(R0, GrowableObjectArray::length_offset()));
  __ ret();
  __ Bind(&fall_through);
  // Fall through on non-Smi.
}


// Set data of growable object array.
// On stack: growable array (+1), data (+0).
void Intrinsifier::GrowableArraySetData(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ ldr(R1, Address(SP, 0 * kWordSize));  // Data.
  // Check that data is an ObjectArray.
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, EQ);  // Data is Smi.
  __ CompareClassId(R1, kArrayCid, kNoPP);
  __ b(&fall_through, NE);
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Growable array.
  __ StoreIntoObject(R0,
                     FieldAddress(R0, GrowableObjectArray::data_offset()),
                     R1);
  __ ret();
  __ Bind(&fall_through);
}


// Add an element to growable array if it doesn't need to grow, otherwise
// call into regular code.
// On stack: growable array (+1), value (+0).
void Intrinsifier::GrowableArray_add(Assembler* assembler) {
  // In checked mode we need to type-check the incoming argument.
  if (FLAG_enable_type_checks) {
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
  __ LoadObject(R0, Object::null_object(), PP);
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
  __ CompareImmediate(R2, max_len, kNoPP);                                     \
  __ b(&fall_through, GT);                                                     \
  __ LslImmediate(R2, R2, scale_shift);                                        \
  const intptr_t fixed_size = sizeof(Raw##type_name) + kObjectAlignment - 1;   \
  __ AddImmediate(R2, R2, fixed_size, kNoPP);                                  \
  __ andi(R2, R2, Immediate(~(kObjectAlignment - 1)));                         \
  Heap* heap = Isolate::Current()->heap();                                     \
  Heap::Space space = heap->SpaceForAllocation(cid);                           \
  __ LoadImmediate(R0, heap->TopAddress(space), kNoPP);                        \
  __ ldr(R0, Address(R0, 0));                                                  \
                                                                               \
  /* R2: allocation size. */                                                   \
  __ add(R1, R0, Operand(R2));                                                 \
  __ b(&fall_through, VS);                                                     \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* R0: potential new object start. */                                        \
  /* R1: potential next object start. */                                       \
  /* R2: allocation size. */                                                   \
  __ LoadImmediate(R3, heap->EndAddress(space), kNoPP);                        \
  __ ldr(R3, Address(R3, 0));                                                  \
  __ cmp(R1, Operand(R3));                                                     \
  __ b(&fall_through, CS);                                                     \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  __ LoadImmediate(R3, heap->TopAddress(space), kNoPP);                        \
  __ str(R1, Address(R3, 0));                                                  \
  __ AddImmediate(R0, R0, kHeapObjectTag, kNoPP);                              \
  __ UpdateAllocationStatsWithSize(cid, R2, kNoPP, space);                     \
  /* Initialize the tags. */                                                   \
  /* R0: new object start as a tagged pointer. */                              \
  /* R1: new object end address. */                                            \
  /* R2: allocation size. */                                                   \
  {                                                                            \
    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag, kNoPP);           \
    __ LslImmediate(R2, R2, RawObject::kSizeTagPos - kObjectAlignmentLog2);    \
    __ csel(R2, ZR, R2, HI);                                                   \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid), kNoPP);          \
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
  __ AddImmediate(R2, R0, sizeof(Raw##type_name) - 1, kNoPP);                  \
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
void Intrinsifier::TypedData_##clazz##_new(Assembler* assembler) {             \
  intptr_t size = TypedData::ElementSizeInBytes(kTypedData##clazz##Cid);       \
  intptr_t max_len = TypedData::MaxElements(kTypedData##clazz##Cid);           \
  int shift = GetScaleFactor(size);                                            \
  TYPED_ARRAY_ALLOCATION(TypedData, kTypedData##clazz##Cid, max_len, shift);   \
}                                                                              \
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
// Returns with result in R0, OR:
//   R1: Untagged result (remainder).
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
  __ CompareImmediate(R0, 0x4000000000000000, kNoPP);
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
      right, reinterpret_cast<int64_t>(Smi::New(Smi::kBits)), PP);
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
  __ LoadObject(R0, Bool::False(), PP);
  __ LoadObject(TMP, Bool::True(), PP);
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
  __ LoadObject(R0, Bool::False(), PP);
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(R0, Bool::True(), PP);
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);

  __ tsti(R1, Immediate(kSmiTagMask));  // Check receiver.
  __ b(&receiver_not_smi, NE);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint or Bigint never contains a value that can be
  // represented by Smi.

  __ CompareClassId(R0, kDoubleCid, kNoPP);
  __ b(&fall_through, EQ);
  __ LoadObject(R0, Bool::False(), PP);  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // R1: receiver.

  __ CompareClassId(R1, kMintCid, kNoPP);
  __ b(&fall_through, NE);
  // Receiver is Mint, return false if right is Smi.
  __ tsti(R0, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);
  __ LoadObject(R0, Bool::False(), PP);
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
  __ LoadImmediate(TMP, 0x3F, kNoPP);
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
  // TODO(sra): Implement as word-length - CLZ.
}


void Intrinsifier::Bigint_setNeg(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ StoreIntoObject(R1, FieldAddress(R1, Bigint::neg_offset()), R0, false);
  __ ret();
}


void Intrinsifier::Bigint_setUsed(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ StoreIntoObject(R1, FieldAddress(R1, Bigint::used_offset()), R0);
  __ ret();
}


void Intrinsifier::Bigint_setDigits(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ StoreIntoObject(R1, FieldAddress(R1, Bigint::digits_offset()), R0, false);
  __ ret();
}


void Intrinsifier::Bigint_absAdd(Assembler* assembler) {
  // TODO(regis): Implement.
}


void Intrinsifier::Bigint_absSub(Assembler* assembler) {
  // TODO(regis): Implement.
}


void Intrinsifier::Bigint_mulAdd(Assembler* assembler) {
  // TODO(regis): Implement.
}


void Intrinsifier::Bigint_sqrAdd(Assembler* assembler) {
  // TODO(regis): Implement.
}


void Intrinsifier::Bigint_estQuotientDigit(Assembler* assembler) {
  // TODO(regis): Implement.
}


void Intrinsifier::Montgomery_mulMod(Assembler* assembler) {
  // TODO(regis): Implement.
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
  __ CompareClassId(R0, kDoubleCid, kNoPP);
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

  __ LoadDFieldFromOffset(V1, R0, Double::value_offset(), kNoPP);
  __ Bind(&double_op);
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);

  __ fcmpd(V0, V1);
  __ LoadObject(R0, Bool::False(), PP);
  // Return false if D0 or D1 was NaN before checking true condition.
  __ b(&not_nan, VC);
  __ ret();
  __ Bind(&not_nan);
  __ LoadObject(TMP, Bool::True(), PP);
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
  Label fall_through;

  TestLastArgumentIsDouble(assembler, &fall_through, &fall_through);
  // Both arguments are double, right operand is in R0.
  __ LoadDFieldFromOffset(V1, R0, Double::value_offset(), kNoPP);
  __ ldr(R0, Address(SP, 1 * kWordSize));  // Left argument.
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);
  switch (kind) {
    case Token::kADD: __ faddd(V0, V0, V1); break;
    case Token::kSUB: __ fsubd(V0, V0, V1); break;
    case Token::kMUL: __ fmuld(V0, V0, V1); break;
    case Token::kDIV: __ fdivd(V0, V0, V1); break;
    default: UNREACHABLE();
  }
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1, kNoPP);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset(), kNoPP);
  __ ret();
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
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);
  __ fmuld(V0, V0, V1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1, kNoPP);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset(), kNoPP);
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
  __ TryAllocate(double_class, &fall_through, R0, R1, kNoPP);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset(), kNoPP);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  Label is_true;
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);
  __ fcmpd(V0, V0);
  __ LoadObject(TMP, Bool::False(), PP);
  __ LoadObject(R0, Bool::True(), PP);
  __ csel(R0, TMP, R0, VC);
  __ ret();
}


void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  const Register false_reg = R0;
  const Register true_reg = R2;
  Label is_false, is_true, is_zero;

  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);
  __ fcmpdz(V0);
  __ LoadObject(true_reg, Bool::True(), PP);
  __ LoadObject(false_reg, Bool::False(), PP);
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
  __ LoadDFieldFromOffset(V0, R0, Double::value_offset(), kNoPP);

  // Explicit NaN check, since ARM gives an FPU exception if you try to
  // convert NaN to an int.
  __ fcmpd(V0, V0);
  __ b(&fall_through, VS);

  __ fcvtzds(R0, V0);
  // Overflow is signaled with minint.
  // Check for overflow and that it fits into Smi.
  __ CompareImmediate(R0, 0xC000000000000000, kNoPP);
  __ b(&fall_through, MI);
  __ SmiTag(R0);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::MathSqrt(Assembler* assembler) {
  Label fall_through, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Argument is double and is in R0.
  __ LoadDFieldFromOffset(V1, R0, Double::value_offset(), kNoPP);
  __ Bind(&double_op);
  __ fsqrtd(V0, V1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, R0, R1, kNoPP);
  __ StoreDFieldToOffset(V0, R0, Double::value_offset(), kNoPP);
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
      random_class.LookupInstanceField(Symbols::_state()));
  ASSERT(!state_field.IsNull());
  const Field& random_A_field = Field::ZoneHandle(
      random_class.LookupStaticField(Symbols::_A()));
  ASSERT(!random_A_field.IsNull());
  ASSERT(random_A_field.is_const());
  const Instance& a_value = Instance::Handle(random_A_field.value());
  const int64_t a_int_value = Integer::Cast(a_value).AsInt64Value();

  __ ldr(R0, Address(SP, 0 * kWordSize));  // Receiver.
  __ ldr(R1, FieldAddress(R0, state_field.Offset()));  // Field '_state'.

  // Addresses of _state[0].
  const int64_t disp =
      Instance::DataOffsetFor(kTypedDataUint32ArrayCid) - kHeapObjectTag;

  __ LoadImmediate(R0, a_int_value, kNoPP);
  __ LoadFromOffset(R2, R1, disp, kNoPP);
  __ LsrImmediate(R3, R2, 32);
  __ andi(R2, R2, Immediate(0xffffffff));
  __ mul(R2, R0, R2);
  __ add(R2, R2, Operand(R3));
  __ StoreToOffset(R2, R1, disp, kNoPP);
  __ ret();
}


void Intrinsifier::ObjectEquals(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R1, Address(SP, 1 * kWordSize));
  __ cmp(R0, Operand(R1));
  __ LoadObject(R0, Bool::False(), PP);
  __ LoadObject(TMP, Bool::True(), PP);
  __ csel(R0, TMP, R0, EQ);
  __ ret();
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


void Intrinsifier::StringBaseCodeUnitAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;

  __ ldr(R1, Address(SP, 0 * kWordSize));  // Index.
  __ ldr(R0, Address(SP, 1 * kWordSize));  // String.
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, NE);  // Index is not a Smi.
  // Range check.
  __ ldr(R2, FieldAddress(R0, String::length_offset()));
  __ cmp(R1, Operand(R2));
  __ b(&fall_through, CS);  // Runtime throws exception.
  __ CompareClassId(R0, kOneByteStringCid, kNoPP);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, R0, OneByteString::data_offset() - kHeapObjectTag, kNoPP);
  __ ldr(R0, Address(R0, R1), kUnsignedByte);
  __ SmiTag(R0);
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid, kNoPP);
  __ b(&fall_through, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, R0, TwoByteString::data_offset() - kHeapObjectTag, kNoPP);
  __ ldr(R0, Address(R0, R1), kUnsignedHalfword);
  __ SmiTag(R0);
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

  __ CompareClassId(R0, kOneByteStringCid, kNoPP);
  __ b(&try_two_byte_string, NE);
  __ SmiUntag(R1);
  __ AddImmediate(R0, R0, OneByteString::data_offset() - kHeapObjectTag, kNoPP);
  __ ldr(R1, Address(R0, R1), kUnsignedByte);
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols, kNoPP);
  __ b(&fall_through, GE);
  __ LoadImmediate(
      R0, reinterpret_cast<uword>(Symbols::PredefinedAddress()), kNoPP);
  __ AddImmediate(
      R0, R0, Symbols::kNullCharCodeSymbolOffset * kWordSize, kNoPP);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(R0, kTwoByteStringCid, kNoPP);
  __ b(&fall_through, NE);
  ASSERT(kSmiTagShift == 1);
  __ AddImmediate(R0, R0, TwoByteString::data_offset() - kHeapObjectTag, kNoPP);
  __ ldr(R1, Address(R0, R1), kUnsignedHalfword);
  __ CompareImmediate(R1, Symbols::kNumberOfOneCharCodeSymbols, kNoPP);
  __ b(&fall_through, GE);
  __ LoadImmediate(
      R0, reinterpret_cast<uword>(Symbols::PredefinedAddress()), kNoPP);
  __ AddImmediate(
      R0, R0, Symbols::kNullCharCodeSymbolOffset * kWordSize, kNoPP);
  __ ldr(R0, Address(R0, R1, UXTX, Address::Scaled));
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseIsEmpty(Assembler* assembler) {
  __ ldr(R0, Address(SP, 0 * kWordSize));
  __ ldr(R0, FieldAddress(R0, String::length_offset()));
  __ cmp(R0, Operand(Smi::RawValue(0)));
  __ LoadObject(R0, Bool::True(), PP);
  __ LoadObject(TMP, Bool::False(), PP);
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
  __ AddImmediate(R6, R1, OneByteString::data_offset() - kHeapObjectTag, kNoPP);
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
      R0, R0, (static_cast<intptr_t>(1) << String::kHashBits) - 1, kNoPP);
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

  __ mov(R6, length_reg);  // Save the length register.
  __ SmiUntag(length_reg);
  const intptr_t fixed_size = sizeof(RawString) + kObjectAlignment - 1;
  __ AddImmediate(length_reg, length_reg, fixed_size, kNoPP);
  __ andi(length_reg, length_reg, Immediate(~(kObjectAlignment - 1)));

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  const intptr_t cid = kOneByteStringCid;
  Heap::Space space = heap->SpaceForAllocation(cid);
  __ LoadImmediate(R3, heap->TopAddress(space), kNoPP);
  __ ldr(R0, Address(R3));

  // length_reg: allocation size.
  __ adds(R1, R0, Operand(length_reg));
  __ b(&fail, VS);  // Fail on overflow.

  // Check if the allocation fits into the remaining space.
  // R0: potential new object start.
  // R1: potential next object start.
  // R2: allocation size.
  // R3: heap->TopAddress(space).
  __ LoadImmediate(R7, heap->EndAddress(space), kNoPP);
  __ ldr(R7, Address(R7));
  __ cmp(R1, Operand(R7));
  __ b(&fail, CS);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ str(R1, Address(R3));
  __ AddImmediate(R0, R0, kHeapObjectTag, kNoPP);
  __ UpdateAllocationStatsWithSize(cid, R2, kNoPP, space);

  // Initialize the tags.
  // R0: new object start as a tagged pointer.
  // R1: new object end address.
  // R2: allocation size.
  {
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;

    __ CompareImmediate(R2, RawObject::SizeTag::kMaxSizeTag, kNoPP);
    __ LslImmediate(R2, R2, shift);
    __ csel(R2, R2, ZR, LS);

    // Get the class index and insert it into the tags.
    // R2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid), kNoPP);
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
  __ AddImmediate(R3, R3, OneByteString::data_offset() - 1, kNoPP);

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
  __ AddImmediate(R6, R6, 1, kNoPP);
  __ sub(R2, R2, Operand(1));
  __ cmp(R2, Operand(0));
  __ str(R1, FieldAddress(R7, OneByteString::data_offset()), kUnsignedByte);
  __ AddImmediate(R7, R7, 1, kNoPP);
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
  __ AddImmediate(R3, R0, OneByteString::data_offset() - kHeapObjectTag, kNoPP);
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
void StringEquality(Assembler* assembler, intptr_t string_cid) {
  Label fall_through, is_true, is_false, loop;
  __ ldr(R0, Address(SP, 1 * kWordSize));  // This.
  __ ldr(R1, Address(SP, 0 * kWordSize));  // Other.

  // Are identical?
  __ cmp(R0, Operand(R1));
  __ b(&is_true, EQ);

  // Is other OneByteString?
  __ tsti(R1, Immediate(kSmiTagMask));
  __ b(&fall_through, EQ);
  __ CompareClassId(R1, string_cid, kNoPP);
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
  __ AddImmediate(R0, R0, offset - kHeapObjectTag, kNoPP);
  __ AddImmediate(R1, R1, offset - kHeapObjectTag, kNoPP);
  __ SmiUntag(R2);
  __ Bind(&loop);
  __ AddImmediate(R2, R2, -1, kNoPP);
  __ CompareRegisters(R2, ZR);
  __ b(&is_true, LT);
  if (string_cid == kOneByteStringCid) {
    __ ldr(R3, Address(R0), kUnsignedByte);
    __ ldr(R4, Address(R1), kUnsignedByte);
    __ AddImmediate(R0, R0, 1, kNoPP);
    __ AddImmediate(R1, R1, 1, kNoPP);
  } else if (string_cid == kTwoByteStringCid) {
    __ ldr(R3, Address(R0), kUnsignedHalfword);
    __ ldr(R4, Address(R1), kUnsignedHalfword);
    __ AddImmediate(R0, R0, 2, kNoPP);
    __ AddImmediate(R1, R1, 2, kNoPP);
  } else {
    UNIMPLEMENTED();
  }
  __ cmp(R3, Operand(R4));
  __ b(&is_false, NE);
  __ b(&loop);

  __ Bind(&is_true);
  __ LoadObject(R0, Bool::True(), PP);
  __ ret();

  __ Bind(&is_false);
  __ LoadObject(R0, Bool::False(), PP);
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::OneByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kOneByteStringCid);
}


void Intrinsifier::TwoByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kTwoByteStringCid);
}


// On stack: user tag (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  // R1: Isolate.
  Isolate* isolate = Isolate::Current();
  __ LoadImmediate(R1, reinterpret_cast<uword>(isolate), kNoPP);
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
  Isolate* isolate = Isolate::Current();
  // Set return value to default tag address.
  __ LoadImmediate(R0,
      reinterpret_cast<uword>(isolate) + Isolate::default_tag_offset(),
      kNoPP);
  __ ldr(R0, Address(R0));
  __ ret();
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  // R1: Default tag address.
  Isolate* isolate = Isolate::Current();
  __ LoadImmediate(R1, reinterpret_cast<uword>(isolate), kNoPP);
  // Set return value to Isolate::current_tag_.
  __ ldr(R0, Address(R1, Isolate::current_tag_offset()));
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
