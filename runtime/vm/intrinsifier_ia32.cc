// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// The intrinsic code below is executed before a method has built its frame.
// The return address is on the stack and the arguments below it.
// Registers EDX (arguments descriptor) and ECX (function) must be preserved.
// Each intrinsification method returns true if the corresponding
// Dart method was intrinsified.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/flow_graph_compiler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);


#define __ assembler->


intptr_t Intrinsifier::ParameterSlotFromSp() { return 0; }


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
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    Label checked_ok;
    __ movl(EDI, Address(ESP, + 1 * kWordSize));  // Value.
    // Null value is valid for any type.
    __ cmpl(EDI, raw_null);
    __ j(EQUAL, &checked_ok, Assembler::kNearJump);

    __ movl(EBX, Address(ESP, + 3 * kWordSize));  // Array.
    __ movl(EBX, FieldAddress(EBX, type_args_field_offset));
    // EBX: Type arguments of array.
    __ cmpl(EBX, raw_null);
    __ j(EQUAL, &checked_ok, Assembler::kNearJump);
    // Check if it's dynamic.
    // Get type at index 0.
    __ movl(EAX, FieldAddress(EBX, TypeArguments::type_at_offset(0)));
    __ CompareObject(EAX, Type::ZoneHandle(Type::DynamicType()));
    __ j(EQUAL,  &checked_ok, Assembler::kNearJump);
    // Check for int and num.
    __ testl(EDI, Immediate(kSmiTagMask));  // Value is Smi?
    __ j(NOT_ZERO, &fall_through);  // Non-smi value.
    __ CompareObject(EAX, Type::ZoneHandle(Type::IntType()));
    __ j(EQUAL,  &checked_ok, Assembler::kNearJump);
    __ CompareObject(EAX, Type::ZoneHandle(Type::Number()));
    __ j(NOT_EQUAL, &fall_through);
    __ Bind(&checked_ok);
  }
  __ movl(EBX, Address(ESP, + 2 * kWordSize));  // Index.
  __ testl(EBX, Immediate(kSmiTagMask));
  // Index not Smi.
  __ j(NOT_ZERO, &fall_through);
  __ movl(EAX, Address(ESP, + 3 * kWordSize));  // Array.
  // Range check.
  __ cmpl(EBX, FieldAddress(EAX, Array::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through);
  // Note that EBX is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  // Destroy ECX (ic data) as we will not continue in the function.
  __ movl(ECX, Address(ESP, + 1 * kWordSize));  // Value.
  __ StoreIntoObject(EAX,
                     FieldAddress(EAX, EBX, TIMES_2, Array::data_offset()),
                     ECX);
  // Caller is responsible of preserving the value if necessary.
  __ ret();
  __ Bind(&fall_through);
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+2), data (+1), return-address (+0).
void Intrinsifier::GrowableArray_Allocate(Assembler* assembler) {
  // This snippet of inlined code uses the following registers:
  // EAX, EBX
  // and the newly allocated object is returned in EAX.
  const intptr_t kTypeArgumentsOffset = 2 * kWordSize;
  const intptr_t kArrayOffset = 1 * kWordSize;
  Label fall_through;

  // Try allocating in new space.
  const Class& cls = Class::Handle(
      Isolate::Current()->object_store()->growable_object_array_class());
  __ TryAllocate(cls, &fall_through, Assembler::kNearJump, EAX, EBX);

  // Store backing array object in growable array object.
  __ movl(EBX, Address(ESP, kArrayOffset));  // data argument.
  // EAX is new, no barrier needed.
  __ StoreIntoObjectNoBarrier(
      EAX,
      FieldAddress(EAX, GrowableObjectArray::data_offset()),
      EBX);

  // EAX: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ movl(EBX, Address(ESP, kTypeArgumentsOffset));  // type argument.
  __ StoreIntoObjectNoBarrier(
      EAX,
      FieldAddress(EAX, GrowableObjectArray::type_arguments_offset()),
      EBX);

  // Set the length field in the growable array object to 0.
  __ movl(FieldAddress(EAX, GrowableObjectArray::length_offset()),
          Immediate(0));
  __ ret();  // returns the newly allocated object in EAX.

  __ Bind(&fall_through);
}


// Access growable object array at specified index.
// On stack: growable array (+2), index (+1), return-address (+0).
void Intrinsifier::GrowableArrayGetIndexed(Assembler* assembler) {
  Label fall_through;
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Index.
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // GrowableArray.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check using _length field.
  __ cmpl(EBX, FieldAddress(EAX, GrowableObjectArray::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  __ movl(EAX, FieldAddress(EAX, GrowableObjectArray::data_offset()));  // data.

  // Note that EBX is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ movl(EAX, FieldAddress(EAX, EBX, TIMES_2, Array::data_offset()));
  __ ret();
  __ Bind(&fall_through);
}


// Set value into growable object array at specified index.
// On stack: growable array (+3), index (+2), value (+1), return-address (+0).
void Intrinsifier::GrowableArraySetIndexed(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ movl(EBX, Address(ESP, + 2 * kWordSize));  // Index.
  __ movl(EAX, Address(ESP, + 3 * kWordSize));  // GrowableArray.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through);  // Non-smi index.
  // Range check using _length field.
  __ cmpl(EBX, FieldAddress(EAX, GrowableObjectArray::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through);
  __ movl(EAX, FieldAddress(EAX, GrowableObjectArray::data_offset()));  // data.
  __ movl(EDI, Address(ESP, + 1 * kWordSize));  // Value.
  // Note that EBX is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ StoreIntoObject(EAX,
                     FieldAddress(EAX, EBX, TIMES_2, Array::data_offset()),
                     EDI);
  __ ret();
  __ Bind(&fall_through);
}


// Set length of growable object array. The length cannot
// be greater than the length of the data container.
// On stack: growable array (+2), length (+1), return-address (+0).
void Intrinsifier::GrowableArraySetLength(Assembler* assembler) {
  Label fall_through;
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Growable array.
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Length value.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi length.
  __ movl(FieldAddress(EAX, GrowableObjectArray::length_offset()), EBX);
  __ ret();
  __ Bind(&fall_through);
}


// Set data of growable object array.
// On stack: growable array (+2), data (+1), return-address (+0).
void Intrinsifier::GrowableArraySetData(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Data.
  // Check that data is an ObjectArray.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(ZERO, &fall_through);  // Data is Smi.
  __ CompareClassId(EBX, kArrayCid, EAX);
  __ j(NOT_EQUAL, &fall_through);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Growable array.
  __ StoreIntoObject(EAX,
                     FieldAddress(EAX, GrowableObjectArray::data_offset()),
                     EBX);
  __ ret();
  __ Bind(&fall_through);
}


// Add an element to growable array if it doesn't need to grow, otherwise
// call into regular code.
// On stack: growable array (+2), value (+1), return-address (+0).
void Intrinsifier::GrowableArray_add(Assembler* assembler) {
  // In checked mode we need to type-check the incoming argument.
  if (FLAG_enable_type_checks) return;

  Label fall_through;
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Array.
  __ movl(EBX, FieldAddress(EAX, GrowableObjectArray::length_offset()));
  // EBX: length.
  __ movl(EDI, FieldAddress(EAX, GrowableObjectArray::data_offset()));
  // EDI: data.
  // Compare length with capacity.
  __ cmpl(EBX, FieldAddress(EDI, Array::length_offset()));
  __ j(EQUAL, &fall_through);  // Must grow data.
  const Immediate& value_one =
      Immediate(reinterpret_cast<int32_t>(Smi::New(1)));
  // len = len + 1;
  __ addl(FieldAddress(EAX, GrowableObjectArray::length_offset()), value_one);
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Value
  ASSERT(kSmiTagShift == 1);
  __ StoreIntoObject(EDI,
                     FieldAddress(EDI, EBX, TIMES_2, Array::data_offset()),
                     EAX);
  const Immediate& raw_null =
      Immediate(reinterpret_cast<int32_t>(Object::null()));
  __ movl(EAX, raw_null);
  __ ret();
  __ Bind(&fall_through);
}


#define TYPED_ARRAY_ALLOCATION(type_name, cid, max_len, scale_factor)          \
  Label fall_through;                                                          \
  const intptr_t kArrayLengthStackOffset = 1 * kWordSize;                      \
  __ movl(EDI, Address(ESP, kArrayLengthStackOffset));  /* Array length. */    \
  /* Check that length is a positive Smi. */                                   \
  /* EDI: requested array length argument. */                                  \
  __ testl(EDI, Immediate(kSmiTagMask));                                       \
  __ j(NOT_ZERO, &fall_through);                                               \
  __ cmpl(EDI, Immediate(0));                                                  \
  __ j(LESS, &fall_through);                                                   \
  __ SmiUntag(EDI);                                                            \
  /* Check for maximum allowed length. */                                      \
  /* EDI: untagged array length. */                                            \
  __ cmpl(EDI, Immediate(max_len));                                            \
  __ j(GREATER, &fall_through);                                                \
  /* Special case for scaling by 16. */                                        \
  if (scale_factor == TIMES_16) {                                              \
    /* double length of array. */                                              \
    __ addl(EDI, EDI);                                                         \
    /* only scale by 8. */                                                     \
    scale_factor = TIMES_8;                                                    \
  }                                                                            \
  const intptr_t fixed_size = sizeof(Raw##type_name) + kObjectAlignment - 1;   \
  __ leal(EDI, Address(EDI, scale_factor, fixed_size));                        \
  __ andl(EDI, Immediate(-kObjectAlignment));                                  \
  Heap* heap = Isolate::Current()->heap();                                     \
  Heap::Space space = heap->SpaceForAllocation(cid);                           \
  __ movl(EAX, Address::Absolute(heap->TopAddress(space)));                    \
  __ movl(EBX, EAX);                                                           \
                                                                               \
  /* EDI: allocation size. */                                                  \
  __ addl(EBX, EDI);                                                           \
  __ j(CARRY, &fall_through);                                                  \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* EAX: potential new object start. */                                       \
  /* EBX: potential next object start. */                                      \
  /* EDI: allocation size. */                                                  \
  __ cmpl(EBX, Address::Absolute(heap->EndAddress(space)));                    \
  __ j(ABOVE_EQUAL, &fall_through);                                            \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  __ movl(Address::Absolute(heap->TopAddress(space)), EBX);                    \
  __ addl(EAX, Immediate(kHeapObjectTag));                                     \
  __ UpdateAllocationStatsWithSize(cid, EDI, kNoRegister, space);              \
                                                                               \
  /* Initialize the tags. */                                                   \
  /* EAX: new object start as a tagged pointer. */                             \
  /* EBX: new object end address. */                                           \
  /* EDI: allocation size. */                                                  \
  {                                                                            \
    Label size_tag_overflow, done;                                             \
    __ cmpl(EDI, Immediate(RawObject::SizeTag::kMaxSizeTag));                  \
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);                     \
    __ shll(EDI, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));    \
    __ jmp(&done, Assembler::kNearJump);                                       \
                                                                               \
    __ Bind(&size_tag_overflow);                                               \
    __ movl(EDI, Immediate(0));                                                \
    __ Bind(&done);                                                            \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ orl(EDI, Immediate(RawObject::ClassIdTag::encode(cid)));                \
    __ movl(FieldAddress(EAX, type_name::tags_offset()), EDI);  /* Tags. */    \
  }                                                                            \
  /* Set the length field. */                                                  \
  /* EAX: new object start as a tagged pointer. */                             \
  /* EBX: new object end address. */                                           \
  __ movl(EDI, Address(ESP, kArrayLengthStackOffset));  /* Array length. */    \
  __ StoreIntoObjectNoBarrier(EAX,                                             \
                              FieldAddress(EAX, type_name::length_offset()),   \
                              EDI);                                            \
  /* Initialize all array elements to 0. */                                    \
  /* EAX: new object start as a tagged pointer. */                             \
  /* EBX: new object end address. */                                           \
  /* EDI: iterator which initially points to the start of the variable */      \
  /* ECX: scratch register. */                                                 \
  /* data area to be initialized. */                                           \
  __ xorl(ECX, ECX);  /* Zero. */                                              \
  __ leal(EDI, FieldAddress(EAX, sizeof(Raw##type_name)));                     \
  Label done, init_loop;                                                       \
  __ Bind(&init_loop);                                                         \
  __ cmpl(EDI, EBX);                                                           \
  __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);                              \
  __ movl(Address(EDI, 0), ECX);                                               \
  __ addl(EDI, Immediate(kWordSize));                                          \
  __ jmp(&init_loop, Assembler::kNearJump);                                    \
  __ Bind(&done);                                                              \
                                                                               \
  __ ret();                                                                    \
  __ Bind(&fall_through);                                                      \


static ScaleFactor GetScaleFactor(intptr_t size) {
  switch (size) {
    case 1: return TIMES_1;
    case 2: return TIMES_2;
    case 4: return TIMES_4;
    case 8: return TIMES_8;
    case 16: return TIMES_16;
  }
  UNREACHABLE();
  return static_cast<ScaleFactor>(0);
}


#define TYPED_DATA_ALLOCATOR(clazz)                                            \
void Intrinsifier::TypedData_##clazz##_new(Assembler* assembler) {             \
  intptr_t size = TypedData::ElementSizeInBytes(kTypedData##clazz##Cid);       \
  intptr_t max_len = TypedData::MaxElements(kTypedData##clazz##Cid);           \
  ScaleFactor scale = GetScaleFactor(size);                                    \
  TYPED_ARRAY_ALLOCATION(TypedData, kTypedData##clazz##Cid, max_len, scale);   \
}                                                                              \
void Intrinsifier::TypedData_##clazz##_factory(Assembler* assembler) {         \
  intptr_t size = TypedData::ElementSizeInBytes(kTypedData##clazz##Cid);       \
  intptr_t max_len = TypedData::MaxElements(kTypedData##clazz##Cid);           \
  ScaleFactor scale = GetScaleFactor(size);                                    \
  TYPED_ARRAY_ALLOCATION(TypedData, kTypedData##clazz##Cid, max_len, scale);   \
}
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATOR)
#undef TYPED_DATA_ALLOCATOR


// Tests if two top most arguments are smis, jumps to label not_smi if not.
// Topmost argument is in EAX.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  __ orl(EBX, EAX);
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi, Assembler::kNearJump);
}


void Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ addl(EAX, Address(ESP, + 2 * kWordSize));
  __ j(OVERFLOW, &fall_through, Assembler::kNearJump);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_add(Assembler* assembler) {
  Integer_addFromInteger(assembler);
}


void Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ subl(EAX, Address(ESP, + 2 * kWordSize));
  __ j(OVERFLOW, &fall_through, Assembler::kNearJump);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_sub(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ movl(EBX, EAX);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));
  __ subl(EAX, EBX);
  __ j(OVERFLOW, &fall_through, Assembler::kNearJump);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}



void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  ASSERT(kSmiTag == 0);  // Adjust code below if not the case.
  __ SmiUntag(EAX);
  __ imull(EAX, Address(ESP, + 2 * kWordSize));
  __ j(OVERFLOW, &fall_through, Assembler::kNearJump);
  // Result is in EAX.
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
// EAX: Tagged left (dividend).
// EBX: Tagged right (divisor).
// EDX: Untagged result (remainder).
static void EmitRemainderOperation(Assembler* assembler) {
  Label return_zero, modulo;
  // Check for quick zero results.
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &return_zero, Assembler::kNearJump);
  __ cmpl(EAX, EBX);
  __ j(EQUAL, &return_zero, Assembler::kNearJump);

  // Check if result equals left.
  __ cmpl(EAX, Immediate(0));
  __ j(LESS, &modulo, Assembler::kNearJump);
  // left is positive.
  __ cmpl(EAX, EBX);
  __ j(GREATER, &modulo,  Assembler::kNearJump);
  // left is less than right, result is left (EAX).
  __ ret();

  __ Bind(&return_zero);
  __ xorl(EAX, EAX);
  __ ret();

  __ Bind(&modulo);
  __ SmiUntag(EBX);
  __ SmiUntag(EAX);
  __ cdq();
  __ idivl(EBX);
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
  TestBothArgumentsSmis(assembler, &fall_through);
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  // EAX: Tagged left (dividend).
  // EBX: Tagged right (divisor).
  // Check if modulo by zero -> exception thrown in main function.
  __ cmpl(EBX, Immediate(0));
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  EmitRemainderOperation(assembler);
  // Untagged remainder result in EDX.
  Label done;
  __ movl(EAX, EDX);
  __ cmpl(EAX, Immediate(0));
  __ j(GREATER_EQUAL, &done, Assembler::kNearJump);
  // Result is negative, adjust it.
  __ cmpl(EBX, Immediate(0));
  __ j(LESS, &subtract, Assembler::kNearJump);
  __ addl(EAX, EBX);
  __ SmiTag(EAX);
  __ ret();

  __ Bind(&subtract);
  __ subl(EAX, EBX);

  __ Bind(&done);
  // The remainder of two smis is always a smi, no overflow check needed.
  __ SmiTag(EAX);
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  // EAX: right argument (divisor)
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ movl(EBX, EAX);
  __ SmiUntag(EBX);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Left argument (dividend).
  __ SmiUntag(EAX);
  __ pushl(EDX);  // Preserve EDX in case of 'fall_through'.
  __ cdq();
  __ idivl(EBX);
  __ popl(EDX);
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ cmpl(EAX, Immediate(0x40000000));
  __ j(EQUAL, &fall_through);
  __ SmiTag(EAX);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_negate(Assembler* assembler) {
  Label fall_through;
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi value.
  __ negl(EAX);
  __ j(OVERFLOW, &fall_through, Assembler::kNearJump);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  __ andl(EAX, EBX);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  Integer_bitAndFromInteger(assembler);
}


void Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  __ orl(EAX, EBX);
  // Result is in EAX.
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_bitOr(Assembler* assembler) {
  Integer_bitOrFromInteger(assembler);
}


void Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  Label fall_through;
  TestBothArgumentsSmis(assembler, &fall_through);
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  __ xorl(EAX, EBX);
  // Result is in EAX.
  __ ret();
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
  // Shift value is in EAX. Compare with tagged Smi.
  __ cmpl(EAX, Immediate(Smi::RawValue(Smi::kBits)));
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);

  __ SmiUntag(EAX);
  __ movl(ECX, EAX);  // Shift amount must be in ECX.
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Value.

  // Overflow test - all the shifted-out bits must be same as the sign bit.
  __ movl(EBX, EAX);
  __ shll(EAX, ECX);
  __ sarl(EAX, ECX);
  __ cmpl(EAX, EBX);
  __ j(NOT_EQUAL, &overflow, Assembler::kNearJump);

  __ shll(EAX, ECX);  // Shift for result now we know there is no overflow.

  // EAX is a correctly tagged Smi.
  __ ret();

  __ Bind(&overflow);
  // Arguments are Smi but the shift produced an overflow to Mint.
  __ cmpl(EBX, Immediate(0));
  // TODO(srdjan): Implement negative values, for now fall through.
  __ j(LESS, &fall_through, Assembler::kNearJump);
  __ SmiUntag(EBX);
  __ movl(EAX, EBX);
  __ shll(EBX, ECX);
  __ xorl(EDI, EDI);
  __ shld(EDI, EAX);
  // Result in EDI (high) and EBX (low).
  const Class& mint_class = Class::Handle(
      Isolate::Current()->object_store()->mint_class());
  __ TryAllocate(mint_class,
                 &fall_through,
                 Assembler::kNearJump,
                 EAX,  // Result register.
                 kNoRegister);
  // EBX and EDI are not objects but integer values.
  __ movl(FieldAddress(EAX, Mint::value_offset()), EBX);
  __ movl(FieldAddress(EAX, Mint::value_offset() + kWordSize), EDI);
  __ ret();
  __ Bind(&fall_through);
}


static void Push64SmiOrMint(Assembler* assembler,
                            Register reg,
                            Register tmp,
                            Label* not_smi_or_mint) {
  Label not_smi, done;
  __ testl(reg, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &not_smi, Assembler::kNearJump);
  __ SmiUntag(reg);
  // Sign extend to 64 bit
  __ movl(tmp, reg);
  __ sarl(tmp, Immediate(31));
  __ pushl(tmp);
  __ pushl(reg);
  __ jmp(&done);
  __ Bind(&not_smi);
  __ CompareClassId(reg, kMintCid, tmp);
  __ j(NOT_EQUAL, not_smi_or_mint);
  // Mint.
  __ pushl(FieldAddress(reg, Mint::value_offset() + kWordSize));
  __ pushl(FieldAddress(reg, Mint::value_offset()));
  __ Bind(&done);
}


static void CompareIntegers(Assembler* assembler, Condition true_condition) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // EAX contains the right argument.
  __ cmpl(Address(ESP, + 2 * kWordSize), EAX);
  __ j(true_condition, &is_true, Assembler::kNearJump);
  __ Bind(&is_false);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();

  // 64-bit comparison
  Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (true_condition) {
    case LESS:
    case LESS_EQUAL:
      hi_true_cond = LESS;
      hi_false_cond = GREATER;
      lo_false_cond = (true_condition == LESS) ? ABOVE_EQUAL : ABOVE;
      break;
    case GREATER:
    case GREATER_EQUAL:
      hi_true_cond = GREATER;
      hi_false_cond = LESS;
      lo_false_cond = (true_condition == GREATER) ? BELOW_EQUAL : BELOW;
      break;
    default:
      UNREACHABLE();
      hi_true_cond = hi_false_cond = lo_false_cond = OVERFLOW;
  }
  __ Bind(&try_mint_smi);
  // Note that EDX and ECX must be preserved in case we fall through to main
  // method.
  // EAX contains the right argument.
  __ movl(EBX, Address(ESP, + 2 * kWordSize));  // Left argument.
  // Push left as 64 bit integer.
  Push64SmiOrMint(assembler, EBX, EDI, &fall_through);
  // Push right as 64 bit integer.
  Push64SmiOrMint(assembler, EAX, EDI, &drop_two_fall_through);
  __ popl(EBX);  // Right.LO.
  __ popl(ECX);  // Right.HI.
  __ popl(EAX);  // Left.LO.
  __ popl(EDX);  // Left.HI.
  __ cmpl(EDX, ECX);  // cmpl left.HI, right.HI.
  __ j(hi_false_cond, &is_false, Assembler::kNearJump);
  __ j(hi_true_cond, &is_true, Assembler::kNearJump);
  __ cmpl(EAX, EBX);  // cmpl left.LO, right.LO.
  __ j(lo_false_cond, &is_false, Assembler::kNearJump);
  // Else is true.
  __ jmp(&is_true);

  __ Bind(&drop_two_fall_through);
  __ Drop(2);
  __ Bind(&fall_through);
}



void Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  CompareIntegers(assembler, LESS);
}


void Intrinsifier::Integer_lessThan(Assembler* assembler) {
  Integer_greaterThanFromInt(assembler);
}


void Intrinsifier::Integer_greaterThan(Assembler* assembler) {
  CompareIntegers(assembler, GREATER);
}


void Intrinsifier::Integer_lessEqualThan(Assembler* assembler) {
  CompareIntegers(assembler, LESS_EQUAL);
}


void Intrinsifier::Integer_greaterEqualThan(Assembler* assembler) {
  CompareIntegers(assembler, GREATER_EQUAL);
}


// This is called for Smi, Mint and Bigint receivers. The right argument
// can be Smi, Mint, Bigint or double.
void Intrinsifier::Integer_equalToInteger(Assembler* assembler) {
  Label fall_through, true_label, check_for_mint;
  // For integer receiver '===' check first.
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ cmpl(EAX, Address(ESP, + 2 * kWordSize));
  __ j(EQUAL, &true_label, Assembler::kNearJump);
  __ movl(EBX, Address(ESP, + 2 * kWordSize));
  __ orl(EAX, EBX);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &check_for_mint, Assembler::kNearJump);
  // Both arguments are smi, '===' is good enough.
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&true_label);
  __ LoadObject(EAX, Bool::True());
  __ ret();

  // At least one of the arguments was not Smi.
  Label receiver_not_smi;
  __ Bind(&check_for_mint);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Receiver.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &receiver_not_smi);

  // Left (receiver) is Smi, return false if right is not Double.
  // Note that an instance of Mint or Bigint never contains a value that can be
  // represented by Smi.
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Right argument.
  __ CompareClassId(EAX, kDoubleCid, EDI);
  __ j(EQUAL, &fall_through);
  __ LoadObject(EAX, Bool::False());  // Smi == Mint -> false.
  __ ret();

  __ Bind(&receiver_not_smi);
  // EAX:: receiver.
  __ CompareClassId(EAX, kMintCid, EDI);
  __ j(NOT_EQUAL, &fall_through);
  // Receiver is Mint, return false if right is Smi.
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Right argument.
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  // TODO(srdjan): Implement Mint == Mint comparison.

  __ Bind(&fall_through);
}


void Intrinsifier::Integer_equal(Assembler* assembler) {
  Integer_equalToInteger(assembler);
}


void Intrinsifier::Integer_sar(Assembler* assembler) {
  Label fall_through, shift_count_ok;
  TestBothArgumentsSmis(assembler, &fall_through);
  // Can destroy ECX since we are not falling through.
  const Immediate& count_limit = Immediate(0x1F);
  // Check that the count is not larger than what the hardware can handle.
  // For shifting right a Smi the result is the same for all numbers
  // >= count_limit.
  __ SmiUntag(EAX);
  // Negative counts throw exception.
  __ cmpl(EAX, Immediate(0));
  __ j(LESS, &fall_through, Assembler::kNearJump);
  __ cmpl(EAX, count_limit);
  __ j(LESS_EQUAL, &shift_count_ok, Assembler::kNearJump);
  __ movl(EAX, count_limit);
  __ Bind(&shift_count_ok);
  __ movl(ECX, EAX);  // Shift amount must be in ECX.
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Value.
  __ SmiUntag(EAX);  // Value.
  __ sarl(EAX, ECX);
  __ SmiTag(EAX);
  __ ret();
  __ Bind(&fall_through);
}


// Argument is Smi (receiver).
void Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Index.
  __ notl(EAX);
  __ andl(EAX, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
  __ ret();
}


void Intrinsifier::Smi_bitLength(Assembler* assembler) {
  ASSERT(kSmiTagShift == 1);
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Index.
  // XOR with sign bit to complement bits if value is negative.
  __ movl(ECX, EAX);
  __ sarl(ECX, Immediate(31));  // All 0 or all 1.
  __ xorl(EAX, ECX);
  // BSR does not write the destination register if source is zero.  Put a 1 in
  // the Smi tag bit to ensure BSR writes to destination register.
  __ orl(EAX, Immediate(kSmiTagMask));
  __ bsrl(EAX, EAX);
  __ SmiTag(EAX);
  __ ret();
}


void Intrinsifier::Bigint_setNeg(Assembler* assembler) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ movl(ECX, Address(ESP, + 2 * kWordSize));
  __ StoreIntoObject(ECX, FieldAddress(ECX, Bigint::neg_offset()), EAX, false);
  __ ret();
}


void Intrinsifier::Bigint_setUsed(Assembler* assembler) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ movl(ECX, Address(ESP, + 2 * kWordSize));
  __ StoreIntoObject(ECX, FieldAddress(ECX, Bigint::used_offset()), EAX);
  __ ret();
}


void Intrinsifier::Bigint_setDigits(Assembler* assembler) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ movl(ECX, Address(ESP, + 2 * kWordSize));
  __ StoreIntoObject(ECX,
                     FieldAddress(ECX, Bigint::digits_offset()), EAX, false);
  __ ret();
}


void Intrinsifier::Bigint_absAdd(Assembler* assembler) {
  // static void _absAdd(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // Preserve CTX to free ESI.
  __ pushl(CTX);
  ASSERT(CTX == ESI);

  __ movl(EDI, Address(ESP, 6 * kWordSize));  // digits
  __ movl(EAX, Address(ESP, 5 * kWordSize));  // used is Smi
  __ SmiUntag(EAX);  // used > 0.
  __ movl(ESI, Address(ESP, 4 * kWordSize));  // a_digits
  __ movl(ECX, Address(ESP, 3 * kWordSize));  // a_used is Smi
  __ SmiUntag(ECX);  // a_used > 0.
  __ movl(EBX, Address(ESP, 2 * kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subl(EAX, ECX);
  __ incl(EAX);  // To account for the extra test between loops.
  __ pushl(EAX);

  __ xorl(EDX, EDX);  // EDX = 0, carry flag = 0.
  Label add_loop;
  __ Bind(&add_loop);
  __ movl(EAX, FieldAddress(EDI, EDX, TIMES_4, TypedData::data_offset()));
  __ adcl(EAX, FieldAddress(ESI, EDX, TIMES_4, TypedData::data_offset()));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, TypedData::data_offset()), EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &add_loop, Assembler::kNearJump);

  Label last_carry;
  __ popl(ECX);
  __ decl(ECX);  // Does not affect carry flag.
  __ j(ZERO, &last_carry, Assembler::kNearJump);

  Label carry_loop;
  __ Bind(&carry_loop);
  __ movl(EAX, FieldAddress(EDI, EDX, TIMES_4, TypedData::data_offset()));
  __ adcl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, TypedData::data_offset()), EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&last_carry);
  __ movl(EAX, Immediate(0));
  __ adcl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, TypedData::data_offset()), EAX);

  // Restore CTX and return.
  __ popl(CTX);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_absSub(Assembler* assembler) {
  // static void _absSub(Uint32List digits, int used,
  //                     Uint32List a_digits, int a_used,
  //                     Uint32List r_digits)

  // Preserve CTX to free ESI.
  __ pushl(CTX);
  ASSERT(CTX == ESI);

  __ movl(EDI, Address(ESP, 6 * kWordSize));  // digits
  __ movl(EAX, Address(ESP, 5 * kWordSize));  // used is Smi
  __ SmiUntag(EAX);  // used > 0.
  __ movl(ESI, Address(ESP, 4 * kWordSize));  // a_digits
  __ movl(ECX, Address(ESP, 3 * kWordSize));  // a_used is Smi
  __ SmiUntag(ECX);  // a_used > 0.
  __ movl(EBX, Address(ESP, 2 * kWordSize));  // r_digits

  // Precompute 'used - a_used' now so that carry flag is not lost later.
  __ subl(EAX, ECX);
  __ incl(EAX);  // To account for the extra test between loops.
  __ pushl(EAX);

  __ xorl(EDX, EDX);  // EDX = 0, carry flag = 0.
  Label sub_loop;
  __ Bind(&sub_loop);
  __ movl(EAX, FieldAddress(EDI, EDX, TIMES_4, TypedData::data_offset()));
  __ sbbl(EAX, FieldAddress(ESI, EDX, TIMES_4, TypedData::data_offset()));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, TypedData::data_offset()), EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &sub_loop, Assembler::kNearJump);

  Label done;
  __ popl(ECX);
  __ decl(ECX);  // Does not affect carry flag.
  __ j(ZERO, &done, Assembler::kNearJump);

  Label carry_loop;
  __ Bind(&carry_loop);
  __ movl(EAX, FieldAddress(EDI, EDX, TIMES_4, TypedData::data_offset()));
  __ sbbl(EAX, Immediate(0));
  __ movl(FieldAddress(EBX, EDX, TIMES_4, TypedData::data_offset()), EAX);
  __ incl(EDX);  // Does not affect carry flag.
  __ decl(ECX);  // Does not affect carry flag.
  __ j(NOT_ZERO, &carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  // Restore CTX and return.
  __ popl(CTX);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_mulAdd(Assembler* assembler) {
  // Pseudo code:
  // static void _mulAdd(Uint32List x_digits, int xi,
  //                     Uint32List m_digits, int i,
  //                     Uint32List a_digits, int j, int n) {
  //   uint32_t x = x_digits[xi >> 1];  // xi is Smi.
  //   if (x == 0 || n == 0) {
  //     return;
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
  // }

  Label no_op;
  // EBX = x, no_op if x == 0
  __ movl(ECX, Address(ESP, 7 * kWordSize));  // x_digits
  __ movl(EAX, Address(ESP, 6 * kWordSize));  // xi is Smi
  __ movl(EBX, FieldAddress(ECX, EAX, TIMES_2, TypedData::data_offset()));
  __ testl(EBX, EBX);
  __ j(ZERO, &no_op, Assembler::kNearJump);

  // EDX = SmiUntag(n), no_op if n == 0
  __ movl(EDX, Address(ESP, 1 * kWordSize));
  __ SmiUntag(EDX);
  __ j(ZERO, &no_op, Assembler::kNearJump);

  // Preserve CTX to free ESI.
  __ pushl(CTX);
  ASSERT(CTX == ESI);

  // EDI = mip = &m_digits[i >> 1]
  __ movl(EDI, Address(ESP, 6 * kWordSize));  // m_digits
  __ movl(EAX, Address(ESP, 5 * kWordSize));  // i is Smi
  __ leal(EDI, FieldAddress(EDI, EAX, TIMES_2, TypedData::data_offset()));

  // ESI = ajp = &a_digits[j >> 1]
  __ movl(ESI, Address(ESP, 4 * kWordSize));  // a_digits
  __ movl(EAX, Address(ESP, 3 * kWordSize));  // j is Smi
  __ leal(ESI, FieldAddress(ESI, EAX, TIMES_2, TypedData::data_offset()));

  // Save n
  __ pushl(EDX);
  Address n_addr = Address(ESP, 0 * kWordSize);

  // ECX = c = 0
  __ xorl(ECX, ECX);

  Label muladd_loop;
  __ Bind(&muladd_loop);
  // x:   EBX
  // mip: EDI
  // ajp: ESI
  // c:   ECX
  // t:   EDX:EAX (not live at loop entry)
  // n:   ESP[0]

  // uint32_t mi = *mip++
  __ movl(EAX, Address(EDI, 0));
  __ addl(EDI, Immediate(kWordSize));

  // uint64_t t = x*mi
  __ mull(EBX);  // t = EDX:EAX = EAX * EBX
  __ addl(EAX, ECX);  // t += c
  __ adcl(EDX, Immediate(0));

  // uint32_t aj = *ajp; t += aj
  __ addl(EAX, Address(ESI, 0));
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kWordSize));

  // c = high32(t)
  __ movl(ECX, EDX);

  // while (--n > 0)
  __ decl(n_addr);  // --n
  __ j(NOT_ZERO, &muladd_loop, Assembler::kNearJump);

  Label done;
  __ testl(ECX, ECX);
  __ j(ZERO, &done);

  // *ajp += c
  __ addl(Address(ESI, 0), ECX);
  __ j(NOT_CARRY, &done, Assembler::kNearJump);

  Label propagate_carry_loop;
  __ Bind(&propagate_carry_loop);
  __ addl(ESI, Immediate(kWordSize));
  __ incl(Address(ESI, 0));  // c == 0 or 1
  __ j(CARRY, &propagate_carry_loop, Assembler::kNearJump);

  __ Bind(&done);
  __ Drop(1);  // n
  // Restore CTX and return.
  __ popl(CTX);

  __ Bind(&no_op);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_sqrAdd(Assembler* assembler) {
  // Pseudo code:
  // static void _sqrAdd(Uint32List x_digits, int i,
  //                     Uint32List a_digits, int used) {
  //   uint32_t* xip = &x_digits[i >> 1];  // i is Smi.
  //   uint32_t x = *xip++;
  //   if (x == 0) return;
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
  // }

  // EDI = xip = &x_digits[i >> 1]
  __ movl(EDI, Address(ESP, 4 * kWordSize));  // x_digits
  __ movl(EAX, Address(ESP, 3 * kWordSize));  // i is Smi
  __ leal(EDI, FieldAddress(EDI, EAX, TIMES_2, TypedData::data_offset()));

  // EBX = x = *xip++, return if x == 0
  Label x_zero;
  __ movl(EBX, Address(EDI, 0));
  __ cmpl(EBX, Immediate(0));
  __ j(EQUAL, &x_zero);
  __ addl(EDI, Immediate(kWordSize));

  // Preserve CTX to free ESI.
  __ pushl(CTX);
  ASSERT(CTX == ESI);

  // ESI = ajp = &a_digits[i]
  __ movl(ESI, Address(ESP, 3 * kWordSize));  // a_digits
  __ leal(ESI, FieldAddress(ESI, EAX, TIMES_4, TypedData::data_offset()));

  // EDX:EAX = t = x*x + *ajp
  __ movl(EAX, EBX);
  __ mull(EBX);
  __ addl(EAX, Address(ESI, 0));
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kWordSize));

  // int n = used - i - 1
  __ movl(EAX, Address(ESP, 2 * kWordSize));  // used is Smi
  __ subl(EAX, Address(ESP, 4 * kWordSize));  // i is Smi
  __ SmiUntag(EAX);
  __ decl(EAX);
  __ pushl(EAX);  // Save n on stack.

  // uint64_t c = high32(t)
  __ pushl(Immediate(0));  // push high32(c) == 0
  __ pushl(EDX);  // push low32(c) == high32(t)

  Address n_addr = Address(ESP, 2 * kWordSize);
  Address ch_addr = Address(ESP, 1 * kWordSize);
  Address cl_addr = Address(ESP, 0 * kWordSize);

  Label loop, done;
  __ Bind(&loop);
  // x:   EBX
  // xip: EDI
  // ajp: ESI
  // c:   ESP[1]:ESP[0]
  // t:   ECX:EDX:EAX (not live at loop entry)
  // n:   ESP[2]

  // while (--n >= 0)
  __ decl(Address(ESP, 2 * kWordSize));  // --n
  __ j(NEGATIVE, &done);

  // uint32_t xi = *xip++
  __ movl(EAX, Address(EDI, 0));
  __ addl(EDI, Immediate(kWordSize));

  // uint96_t t = ECX:EDX:EAX = 2*x*xi + aj + c
  __ mull(EBX);  // EDX:EAX = EAX * EBX
  __ xorl(ECX, ECX);  // ECX = 0
  __ shld(ECX, EDX, Immediate(1));
  __ shld(EDX, EAX, Immediate(1));
  __ shll(EAX, Immediate(1));  // ECX:EDX:EAX <<= 1
  __ addl(EAX, Address(ESI, 0));  // t += aj
  __ adcl(EDX, Immediate(0));
  __ adcl(ECX, Immediate(0));
  __ addl(EAX, cl_addr);  // t += low32(c)
  __ adcl(EDX, ch_addr);  // t += high32(c) << 32
  __ adcl(ECX, Immediate(0));

  // *ajp++ = low32(t)
  __ movl(Address(ESI, 0), EAX);
  __ addl(ESI, Immediate(kWordSize));

  // c = high64(t)
  __ movl(cl_addr, EDX);
  __ movl(ch_addr, ECX);

  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // uint64_t t = aj + c
  __ movl(EAX, cl_addr);  // t = c
  __ movl(EDX, ch_addr);
  __ addl(EAX, Address(ESI, 0));  // t += *ajp
  __ adcl(EDX, Immediate(0));

  // *ajp++ = low32(t)
  // *ajp = high32(t)
  __ movl(Address(ESI, 0), EAX);
  __ movl(Address(ESI, kWordSize), EDX);

  // Restore CTX and return.
  __ Drop(3);
  __ popl(CTX);
  __ Bind(&x_zero);
  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Bigint_estQuotientDigit(Assembler* assembler) {
  // Pseudo code:
  // static void _estQuotientDigit(Uint32List args, Uint32List digits, int i) {
  //   uint32_t yt = args[_YT];  // _YT == 0.
  //   uint32_t* dp = &digits[i >> 1];  // i is Smi.
  //   uint32_t dh = dp[0];  // dh == digits[i >> 1].
  //   uint32_t qd;
  //   if (dh == yt) {
  //     qd = DIGIT_MASK;
  //   } else {
  //     dl = dp[-1];  // dl == digits[(i - 1) >> 1].
  //     qd = dh:dl / yt;  // No overflow possible, because dh < yt.
  //   }
  //   args[_QD] = qd;  // _QD == 1;
  // }

  // EDI = args
  __ movl(EDI, Address(ESP, 3 * kWordSize));  // args

  // ECX = yt = args[0]
  __ movl(ECX, FieldAddress(EDI, TypedData::data_offset()));

  // EBX = dp = &digits[i >> 1]
  __ movl(EBX, Address(ESP, 2 * kWordSize));  // digits
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // i is Smi
  __ leal(EBX, FieldAddress(EBX, EAX, TIMES_2, TypedData::data_offset()));

  // EDX = dh = dp[0]
  __ movl(EDX, Address(EBX, 0));

  // EAX = qd = DIGIT_MASK = -1
  __ movl(EAX, Immediate(-1));

  // Return qd if dh == yt
  Label return_qd;
  __ cmpl(EDX, ECX);
  __ j(EQUAL, &return_qd, Assembler::kNearJump);

  // EAX = dl = dp[-1]
  __ movl(EAX, Address(EBX, -kWordSize));

  // EAX = qd = dh:dl / yt = EDX:EAX / ECX
  __ divl(ECX);

  __ Bind(&return_qd);
  // args[1] = qd
  __ movl(FieldAddress(EDI, TypedData::data_offset() + kWordSize), EAX);

  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


void Intrinsifier::Montgomery_mulMod(Assembler* assembler) {
  // Pseudo code:
  // static void _mulMod(Uint32List args, Uint32List digits, int i) {
  //   uint32_t rho = args[_RHO];  // _RHO == 0.
  //   uint32_t d = digits[i >> 1];  // i is Smi.
  //   uint64_t t = rho*d;
  //   args[_MU] = t mod DIGIT_BASE;  // _MU == 1.
  // }

  // EDI = args
  __ movl(EDI, Address(ESP, 3 * kWordSize));  // args

  // ECX = rho = args[0]
  __ movl(ECX, FieldAddress(EDI, TypedData::data_offset()));

  // EAX = digits[i >> 1]
  __ movl(EBX, Address(ESP, 2 * kWordSize));  // digits
  __ movl(EAX, Address(ESP, 1 * kWordSize));  // i is Smi
  __ movl(EAX, FieldAddress(EBX, EAX, TIMES_2, TypedData::data_offset()));

  // EDX:EAX = t = rho*d
  __ mull(ECX);

  // args[1] = t mod DIGIT_BASE = low32(t)
  __ movl(FieldAddress(EDI, TypedData::data_offset() + kWordSize), EAX);

  // Returning Object::null() is not required, since this method is private.
  __ ret();
}


// Check if the last argument is a double, jump to label 'is_smi' if smi
// (easy to convert to double), otherwise jump to label 'not_double_smi',
// Returns the last argument in EAX.
static void TestLastArgumentIsDouble(Assembler* assembler,
                                     Label* is_smi,
                                     Label* not_double_smi) {
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(ZERO, is_smi, Assembler::kNearJump);  // Jump if Smi.
  __ CompareClassId(EAX, kDoubleCid, EBX);
  __ j(NOT_EQUAL, not_double_smi, Assembler::kNearJump);
  // Fall through if double.
}


// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register EAX. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler, Condition true_condition) {
  Label fall_through, is_false, is_true, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Both arguments are double, right operand is in EAX.
  __ movsd(XMM1, FieldAddress(EAX, Double::value_offset()));
  __ Bind(&double_op);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false;
  __ j(true_condition, &is_true, Assembler::kNearJump);
  // Fall through false.
  __ Bind(&is_false);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ jmp(&double_op);
  __ Bind(&fall_through);
}


// arg0 is Double, arg1 is unknown.
void Intrinsifier::Double_greaterThan(Assembler* assembler) {
  CompareDoubles(assembler, ABOVE);
}


// arg0 is Double, arg1 is unknown.
void Intrinsifier::Double_greaterEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, ABOVE_EQUAL);
}


// arg0 is Double, arg1 is unknown.
void Intrinsifier::Double_lessThan(Assembler* assembler) {
  CompareDoubles(assembler, BELOW);
}


// arg0 is Double, arg1 is unknown.
void Intrinsifier::Double_equal(Assembler* assembler) {
  CompareDoubles(assembler, EQUAL);
}


// arg0 is Double, arg1 is unknown.
void Intrinsifier::Double_lessEqualThan(Assembler* assembler) {
  CompareDoubles(assembler, BELOW_EQUAL);
}


// Expects left argument to be double (receiver). Right argument is unknown.
// Both arguments are on stack.
static void DoubleArithmeticOperations(Assembler* assembler, Token::Kind kind) {
  Label fall_through;
  TestLastArgumentIsDouble(assembler, &fall_through, &fall_through);
  // Both arguments are double, right operand is in EAX.
  __ movsd(XMM1, FieldAddress(EAX, Double::value_offset()));
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // Left argument.
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  switch (kind) {
    case Token::kADD: __ addsd(XMM0, XMM1); break;
    case Token::kSUB: __ subsd(XMM0, XMM1); break;
    case Token::kMUL: __ mulsd(XMM0, XMM1); break;
    case Token::kDIV: __ divsd(XMM0, XMM1); break;
    default: UNREACHABLE();
  }
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class,
                 &fall_through,
                 Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
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
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ movl(EAX, Address(ESP, + 2 * kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ mulsd(XMM0, XMM1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class,
                 &fall_through,
                 Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::DoubleFromInteger(Assembler* assembler) {
  Label fall_through;
  __ movl(EAX, Address(ESP, +1 * kWordSize));
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);
  // Is Smi.
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM0, EAX);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class,
                 &fall_through,
                 Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  Label is_true;
  __ movl(EAX, Address(ESP, +1 * kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ comisd(XMM0, XMM0);
  __ j(PARITY_EVEN, &is_true, Assembler::kNearJump);  // NaN -> true;
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();
}


void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  Label is_false, is_true, is_zero;
  __ movl(EAX, Address(ESP, +1 * kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ xorpd(XMM1, XMM1);  // 0.0 -> XMM1.
  __ comisd(XMM0, XMM1);
  __ j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN -> false.
  __ j(EQUAL, &is_zero, Assembler::kNearJump);  // Check for negative zero.
  __ j(ABOVE_EQUAL, &is_false, Assembler::kNearJump);  // >= 0 -> false.
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();
  __ Bind(&is_false);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_zero);
  // Check for negative zero (get the sign bit).
  __ movmskpd(EAX, XMM0);
  __ testl(EAX, Immediate(1));
  __ j(NOT_ZERO, &is_true, Assembler::kNearJump);
  __ jmp(&is_false, Assembler::kNearJump);
}


void Intrinsifier::DoubleToInteger(Assembler* assembler) {
  __ movl(EAX, Address(ESP, +1 * kWordSize));
  __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
  __ cvttsd2si(EAX, XMM0);
  // Overflow is signalled with minint.
  Label fall_through;
  // Check for overflow and that it fits into Smi.
  __ cmpl(EAX, Immediate(0xC0000000));
  __ j(NEGATIVE, &fall_through, Assembler::kNearJump);
  __ SmiTag(EAX);
  __ ret();
  __ Bind(&fall_through);
}


// Argument type is not known
void Intrinsifier::MathSqrt(Assembler* assembler) {
  Label fall_through, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Argument is double and is in EAX.
  __ movsd(XMM1, FieldAddress(EAX, Double::value_offset()));
  __ Bind(&double_op);
  __ sqrtsd(XMM0, XMM1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class,
                 &fall_through,
                 Assembler::kNearJump,
                 EAX,  // Result register.
                 EBX);
  __ movsd(FieldAddress(EAX, Double::value_offset()), XMM0);
  __ ret();
  __ Bind(&is_smi);
  __ SmiUntag(EAX);
  __ cvtsi2sd(XMM1, EAX);
  __ jmp(&double_op);
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
  // 'a_int_value' is a mask.
  ASSERT(Utils::IsUint(32, a_int_value));
  int32_t a_int32_value = static_cast<int32_t>(a_int_value);
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // Receiver.
  __ movl(EBX, FieldAddress(EAX, state_field.Offset()));  // Field '_state'.
  // Addresses of _state[0] and _state[1].
  const intptr_t scale = Instance::ElementSizeFor(kTypedDataUint32ArrayCid);
  const intptr_t offset = Instance::DataOffsetFor(kTypedDataUint32ArrayCid);
  Address addr_0 = FieldAddress(EBX, 0 * scale + offset);
  Address addr_1 = FieldAddress(EBX, 1 * scale + offset);
  __ movl(EAX, Immediate(a_int32_value));
  // 64-bit multiply EAX * value -> EDX:EAX.
  __ mull(addr_0);
  __ addl(EAX, addr_1);
  __ adcl(EDX, Immediate(0));
  __ movl(addr_1, EDX);
  __ movl(addr_0, EAX);
  __ ret();
}


// Identity comparison.
void Intrinsifier::ObjectEquals(Assembler* assembler) {
  Label is_true;
  __ movl(EAX, Address(ESP, + 1 * kWordSize));
  __ cmpl(EAX, Address(ESP, + 2 * kWordSize));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();
}


void Intrinsifier::String_getHashCode(Assembler* assembler) {
  Label fall_through;
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // String object.
  __ movl(EAX, FieldAddress(EAX, String::hash_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &fall_through, Assembler::kNearJump);
  __ ret();
  __ Bind(&fall_through);
  // Hash not yet computed.
}


void Intrinsifier::StringBaseCodeUnitAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Index.
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // String.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check.
  __ cmpl(EBX, FieldAddress(EAX, String::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareClassId(EAX, kOneByteStringCid, EDI);
  __ j(NOT_EQUAL, &try_two_byte_string, Assembler::kNearJump);
  __ SmiUntag(EBX);
  __ movzxb(EAX, FieldAddress(EAX, EBX, TIMES_1, OneByteString::data_offset()));
  __ SmiTag(EAX);
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(EAX, kTwoByteStringCid, EDI);
  __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);
  ASSERT(kSmiTagShift == 1);
  __ movzxw(EAX, FieldAddress(EAX, EBX, TIMES_1, TwoByteString::data_offset()));
  __ SmiTag(EAX);
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseCharAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Index.
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // String.
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check.
  __ cmpl(EBX, FieldAddress(EAX, String::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  __ CompareClassId(EAX, kOneByteStringCid, EDI);
  __ j(NOT_EQUAL, &try_two_byte_string, Assembler::kNearJump);
  __ SmiUntag(EBX);
  __ movzxb(EBX, FieldAddress(EAX, EBX, TIMES_1, OneByteString::data_offset()));
  __ cmpl(EBX, Immediate(Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, &fall_through);
  __ movl(EAX,
          Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(EAX, Address(EAX,
                       EBX,
                       TIMES_4,
                       Symbols::kNullCharCodeSymbolOffset * kWordSize));
  __ ret();

  __ Bind(&try_two_byte_string);
  __ CompareClassId(EAX, kTwoByteStringCid, EDI);
  __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);
  ASSERT(kSmiTagShift == 1);
  __ movzxw(EBX, FieldAddress(EAX, EBX, TIMES_1, TwoByteString::data_offset()));
  __ cmpl(EBX, Immediate(Symbols::kNumberOfOneCharCodeSymbols));
  __ j(GREATER_EQUAL, &fall_through);
  __ movl(EAX,
          Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(EAX, Address(EAX,
                       EBX,
                       TIMES_4,
                       Symbols::kNullCharCodeSymbolOffset * kWordSize));
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::StringBaseIsEmpty(Assembler* assembler) {
  Label is_true;
  // Get length.
  __ movl(EAX, Address(ESP, + 1 * kWordSize));  // String object.
  __ movl(EAX, FieldAddress(EAX, String::length_offset()));
  __ cmpl(EAX, Immediate(Smi::RawValue(0)));
  __ j(EQUAL, &is_true, Assembler::kNearJump);
  __ LoadObject(EAX, Bool::False());
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();
}


void Intrinsifier::OneByteString_getHashCode(Assembler* assembler) {
  Label compute_hash;
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // OneByteString object.
  __ movl(EAX, FieldAddress(EBX, String::hash_offset()));
  __ cmpl(EAX, Immediate(0));
  __ j(EQUAL, &compute_hash, Assembler::kNearJump);
  __ ret();

  __ Bind(&compute_hash);
  // Hash not yet computed, use algorithm of class StringHasher.
  __ movl(ECX, FieldAddress(EBX, String::length_offset()));
  __ SmiUntag(ECX);
  __ xorl(EAX, EAX);
  __ xorl(EDI, EDI);
  // EBX: Instance of OneByteString.
  // ECX: String length, untagged integer.
  // EDI: Loop counter, untagged integer.
  // EAX: Hash code, untagged integer.
  Label loop, done, set_hash_code;
  __ Bind(&loop);
  __ cmpl(EDI, ECX);
  __ j(EQUAL, &done, Assembler::kNearJump);
  // Add to hash code: (hash_ is uint32)
  // hash_ += ch;
  // hash_ += hash_ << 10;
  // hash_ ^= hash_ >> 6;
  // Get one characters (ch).
  __ movzxb(EDX, FieldAddress(EBX, EDI, TIMES_1, OneByteString::data_offset()));
  // EDX: ch and temporary.
  __ addl(EAX, EDX);
  __ movl(EDX, EAX);
  __ shll(EDX, Immediate(10));
  __ addl(EAX, EDX);
  __ movl(EDX, EAX);
  __ shrl(EDX, Immediate(6));
  __ xorl(EAX, EDX);

  __ incl(EDI);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&done);
  // Finalize:
  // hash_ += hash_ << 3;
  // hash_ ^= hash_ >> 11;
  // hash_ += hash_ << 15;
  __ movl(EDX, EAX);
  __ shll(EDX, Immediate(3));
  __ addl(EAX, EDX);
  __ movl(EDX, EAX);
  __ shrl(EDX, Immediate(11));
  __ xorl(EAX, EDX);
  __ movl(EDX, EAX);
  __ shll(EDX, Immediate(15));
  __ addl(EAX, EDX);
  // hash_ = hash_ & ((static_cast<intptr_t>(1) << bits) - 1);
  __ andl(EAX,
      Immediate(((static_cast<intptr_t>(1) << String::kHashBits) - 1)));

  // return hash_ == 0 ? 1 : hash_;
  __ cmpl(EAX, Immediate(0));
  __ j(NOT_EQUAL, &set_hash_code, Assembler::kNearJump);
  __ incl(EAX);
  __ Bind(&set_hash_code);
  __ SmiTag(EAX);
  __ movl(FieldAddress(EBX, String::hash_offset()), EAX);
  __ ret();
}


// Allocates one-byte string of length 'end - start'. The content is not
// initialized. 'length-reg' contains tagged length.
// Returns new string as tagged pointer in EAX.
static void TryAllocateOnebyteString(Assembler* assembler,
                                     Label* ok,
                                     Label* failure,
                                     Register length_reg) {
  if (length_reg != EDI) {
    __ movl(EDI, length_reg);
  }
  Label pop_and_fail;
  __ pushl(EDI);  // Preserve length.
  __ SmiUntag(EDI);
  const intptr_t fixed_size = sizeof(RawString) + kObjectAlignment - 1;
  __ leal(EDI, Address(EDI, TIMES_1, fixed_size));  // EDI is untagged.
  __ andl(EDI, Immediate(-kObjectAlignment));

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  const intptr_t cid = kOneByteStringCid;
  Heap::Space space = heap->SpaceForAllocation(cid);
  __ movl(EAX, Address::Absolute(heap->TopAddress(space)));
  __ movl(EBX, EAX);

  // EDI: allocation size.
  __ addl(EBX, EDI);
  __ j(CARRY, &pop_and_fail, Assembler::kNearJump);

  // Check if the allocation fits into the remaining space.
  // EAX: potential new object start.
  // EBX: potential next object start.
  // EDI: allocation size.
  __ cmpl(EBX, Address::Absolute(heap->EndAddress(space)));
  __ j(ABOVE_EQUAL, &pop_and_fail, Assembler::kNearJump);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movl(Address::Absolute(heap->TopAddress(space)), EBX);
  __ addl(EAX, Immediate(kHeapObjectTag));

  __ UpdateAllocationStatsWithSize(cid, EDI, kNoRegister, space);

  // Initialize the tags.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpl(EDI, Immediate(RawObject::SizeTag::kMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shll(EDI, Immediate(RawObject::kSizeTagPos - kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ xorl(EDI, EDI);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    __ orl(EDI, Immediate(RawObject::ClassIdTag::encode(cid)));
    __ movl(FieldAddress(EAX, String::tags_offset()), EDI);  // Tags.
  }

  // Set the length field.
  __ popl(EDI);
  __ StoreIntoObjectNoBarrier(EAX,
                              FieldAddress(EAX, String::length_offset()),
                              EDI);
  // Clear hash.
  __ movl(FieldAddress(EAX, String::hash_offset()), Immediate(0));
  __ jmp(ok, Assembler::kNearJump);

  __ Bind(&pop_and_fail);
  __ popl(EDI);
  __ jmp(failure);
}


// Arg0: OneByteString (receiver)
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void Intrinsifier::OneByteString_substringUnchecked(Assembler* assembler) {
  const intptr_t kStringOffset = 3 * kWordSize;
  const intptr_t kStartIndexOffset = 2 * kWordSize;
  const intptr_t kEndIndexOffset = 1 * kWordSize;
  Label fall_through, ok;
  __ movl(EAX, Address(ESP, + kStartIndexOffset));
  __ movl(EDI, Address(ESP, + kEndIndexOffset));
  __ orl(EAX, EDI);
  __ testl(EAX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through);  // 'start', 'end' not Smi.

  __ subl(EDI, Address(ESP, + kStartIndexOffset));
  TryAllocateOnebyteString(assembler, &ok, &fall_through, EDI);
  __ Bind(&ok);
  // EAX: new string as tagged pointer.
  // Copy string.
  __ movl(EDI, Address(ESP, + kStringOffset));
  __ movl(EBX, Address(ESP, + kStartIndexOffset));
  __ SmiUntag(EBX);
  __ leal(EDI, FieldAddress(EDI, EBX, TIMES_1, OneByteString::data_offset()));
  // EDI: Start address to copy from (untagged).
  // EBX: Untagged start index.
  __ movl(ECX, Address(ESP, + kEndIndexOffset));
  __ SmiUntag(ECX);
  __ subl(ECX, EBX);
  __ xorl(EDX, EDX);
  // EDI: Start address to copy from (untagged).
  // ECX: Untagged number of bytes to copy.
  // EAX: Tagged result string.
  // EDX: Loop counter.
  // EBX: Scratch register.
  Label loop, check;
  __ jmp(&check, Assembler::kNearJump);
  __ Bind(&loop);
  __ movzxb(EBX, Address(EDI, EDX, TIMES_1, 0));
  __ movb(FieldAddress(EAX, EDX, TIMES_1, OneByteString::data_offset()), BL);
  __ incl(EDX);
  __ Bind(&check);
  __ cmpl(EDX, ECX);
  __ j(LESS, &loop, Assembler::kNearJump);
  __ ret();
  __ Bind(&fall_through);
}


void Intrinsifier::OneByteStringSetAt(Assembler* assembler) {
  __ movl(ECX, Address(ESP, + 1 * kWordSize));  // Value.
  __ movl(EBX, Address(ESP, + 2 * kWordSize));  // Index.
  __ movl(EAX, Address(ESP, + 3 * kWordSize));  // OneByteString.
  __ SmiUntag(EBX);
  __ SmiUntag(ECX);
  __ movb(FieldAddress(EAX, EBX, TIMES_1, OneByteString::data_offset()), CL);
  __ ret();
}


void Intrinsifier::OneByteString_allocate(Assembler* assembler) {
  __ movl(EDI, Address(ESP, + 1 * kWordSize));  // Length.
  Label fall_through, ok;
  TryAllocateOnebyteString(assembler, &ok, &fall_through, EDI);
  // EDI: Start address to copy from (untagged).

  __ Bind(&ok);
  __ ret();

  __ Bind(&fall_through);
}


// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
void StringEquality(Assembler* assembler, intptr_t string_cid) {
  Label fall_through, is_true, is_false, loop;
  __ movl(EAX, Address(ESP, + 2 * kWordSize));  // This.
  __ movl(EBX, Address(ESP, + 1 * kWordSize));  // Other.

  // Are identical?
  __ cmpl(EAX, EBX);
  __ j(EQUAL, &is_true, Assembler::kNearJump);

  // Is other OneByteString?
  __ testl(EBX, Immediate(kSmiTagMask));
  __ j(ZERO, &is_false);  // Smi
  __ CompareClassId(EBX, string_cid, EDI);
  __ j(NOT_EQUAL, &fall_through, Assembler::kNearJump);

  // Have same length?
  __ movl(EDI, FieldAddress(EAX, String::length_offset()));
  __ cmpl(EDI, FieldAddress(EBX, String::length_offset()));
  __ j(NOT_EQUAL, &is_false, Assembler::kNearJump);

  // Check contents, no fall-through possible.
  // TODO(srdjan): write a faster check.
  __ SmiUntag(EDI);
  __ Bind(&loop);
  __ decl(EDI);
  __ cmpl(EDI, Immediate(0));
  __ j(LESS, &is_true, Assembler::kNearJump);
  if (string_cid == kOneByteStringCid) {
    __ movzxb(ECX,
        FieldAddress(EAX, EDI, TIMES_1, OneByteString::data_offset()));
    __ movzxb(EDX,
        FieldAddress(EBX, EDI, TIMES_1, OneByteString::data_offset()));
  } else if (string_cid == kTwoByteStringCid) {
    __ movzxw(ECX,
        FieldAddress(EAX, EDI, TIMES_2, TwoByteString::data_offset()));
    __ movzxw(EDX,
        FieldAddress(EBX, EDI, TIMES_2, TwoByteString::data_offset()));
  } else {
    UNIMPLEMENTED();
  }
  __ cmpl(ECX, EDX);
  __ j(NOT_EQUAL, &is_false, Assembler::kNearJump);
  __ jmp(&loop, Assembler::kNearJump);

  __ Bind(&is_true);
  __ LoadObject(EAX, Bool::True());
  __ ret();

  __ Bind(&is_false);
  __ LoadObject(EAX, Bool::False());
  __ ret();

  __ Bind(&fall_through);
}


void Intrinsifier::OneByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kOneByteStringCid);
}


void Intrinsifier::TwoByteString_equality(Assembler* assembler) {
  StringEquality(assembler, kTwoByteStringCid);
}


// On stack: user tag (+1), return-address (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  Isolate* isolate = Isolate::Current();
  const Address current_tag_addr =
      Address::Absolute(reinterpret_cast<uword>(isolate) +
                        Isolate::current_tag_offset());
  const Address user_tag_addr =
      Address::Absolute(reinterpret_cast<uword>(isolate) +
                        Isolate::user_tag_offset());
  // EAX: Current user tag.
  __ movl(EAX, current_tag_addr);
  // EAX: UserTag.
  __ movl(EBX, Address(ESP, + 1 * kWordSize));
  // Set Isolate::current_tag_.
  __ movl(current_tag_addr, EBX);
  // EAX: UserTag's tag.
  __ movl(EBX, FieldAddress(EBX, UserTag::tag_offset()));
  // Set Isolate::user_tag_.
  __ movl(user_tag_addr, EBX);
  __ ret();
}


void Intrinsifier::UserTag_defaultTag(Assembler* assembler) {
  Isolate* isolate = Isolate::Current();
  const Address default_tag_addr =
      Address::Absolute(
          reinterpret_cast<uword>(isolate) + Isolate::default_tag_offset());
  // Set return value.
  __ movl(EAX, default_tag_addr);
  __ ret();
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  Isolate* isolate = Isolate::Current();
  const Address current_tag_addr =
      Address::Absolute(reinterpret_cast<uword>(isolate) +
                        Isolate::current_tag_offset());
  // Set return value to Isolate::current_tag_.
  __ movl(EAX, current_tag_addr);
  __ ret();
}

#undef __
}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
