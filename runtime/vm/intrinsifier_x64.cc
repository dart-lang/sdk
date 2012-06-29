// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/object_store.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);

// When entering intrinsics code:
// RBX: IC Data
// R10: Arguments descriptor
// TOS: Return address
// The RBX, R10 registers can be destroyed only if there is no slow-path (i.e.,
// the methods returns true).

#define __ assembler->


bool Intrinsifier::ObjectArray_Allocate(Assembler* assembler) {
  // This snippet of inlined code uses the following registers:
  // RAX, RCX, RDI, R13
  // and the newly allocated object is returned in RAX.
  const intptr_t kTypeArgumentsOffset = 2 * kWordSize;
  const intptr_t kArrayLengthOffset = 1 * kWordSize;
  Label fall_through;

  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize((array_length * kwordSize) + sizeof(RawArray)).
  __ movq(RDI, Address(RSP, kArrayLengthOffset));  // Array Length.
  // Assert that length is a Smi.
  __ testq(RDI, Immediate(kSmiTagSize));
  __ j(NOT_ZERO, &fall_through);
  __ cmpq(RDI, Immediate(0));
  __ j(LESS, &fall_through);
  intptr_t fixed_size = sizeof(RawArray) + kObjectAlignment - 1;
  __ leaq(RDI, Address(RDI, TIMES_4, fixed_size));  // RDI is a Smi.
  ASSERT(kSmiTagShift == 1);
  __ andq(RDI, Immediate(-kObjectAlignment));

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  // RDI: allocation size.
  __ movq(RAX, Immediate(heap->TopAddress()));
  __ movq(RAX, Address(RAX, 0));
  __ leaq(RCX, Address(RAX, RDI, TIMES_1, 0));

  // Check if the allocation fits into the remaining space.
  // RAX: potential new object start.
  // RCX: potential next object start.
  // RDI: allocation size.
  __ movq(R13, Immediate(heap->TopAddress()));
  __ cmpq(RCX, Address(R13, 0));
  __ j(ABOVE_EQUAL, &fall_through);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movq(Address(R13, 0), RCX);
  __ addq(RAX, Immediate(kHeapObjectTag));

  // Initialize the tags.
  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: allocation size.
  {
    Label size_tag_overflow, done;
    __ cmpl(RDI, Immediate(RawObject::SizeTag::kMaxSizeTag));
    __ j(ABOVE, &size_tag_overflow, Assembler::kNearJump);
    __ shlq(RDI, Immediate(RawObject::kSizeTagBit - kObjectAlignmentLog2));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&size_tag_overflow);
    __ movq(RDI, Immediate(0));
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    const Class& cls = Class::Handle(isolate->object_store()->array_class());
    __ orq(RDI, Immediate(RawObject::ClassIdTag::encode(cls.id())));
    __ movq(FieldAddress(RAX, Array::tags_offset()), RDI);  // Tags.
  }

  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // Store the type argument field.
  __ movl(RDI, Address(RSP, kTypeArgumentsOffset));  // type argument.
  __ StoreIntoObjectNoBarrier(RAX,
                              FieldAddress(RAX, Array::type_arguments_offset()),
                              RDI);

  // Set the length field.
  __ movq(RDI, Address(RSP, kArrayLengthOffset));  // Array Length.
  __ StoreIntoObjectNoBarrier(RAX,
                              FieldAddress(RAX, Array::length_offset()),
                              RDI);

  // Initialize all array elements to raw_null.
  // RAX: new object start as a tagged pointer.
  // RCX: new object end address.
  // RDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  const Immediate raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ leaq(RDI, FieldAddress(RAX, sizeof(RawArray)));
  Label done;
  Label init_loop;
  __ Bind(&init_loop);
  __ cmpq(RDI, RCX);
  __ j(ABOVE_EQUAL, &done, Assembler::kNearJump);
  __ movq(Address(RDI, 0), raw_null);
  __ addq(RDI, Immediate(kWordSize));
  __ jmp(&init_loop, Assembler::kNearJump);
  __ Bind(&done);
  __ ret();  // returns the newly allocated object in RAX.

  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Array_getLength(Assembler* assembler) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, Array::length_offset()));
  __ ret();
  return true;
}


bool Intrinsifier::ImmutableArray_getLength(Assembler* assembler) {
  return Array_getLength(assembler);
}


bool Intrinsifier::Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  __ movq(RCX, Address(RSP, + 1 * kWordSize));  // Index.
  __ movq(RAX, Address(RSP, + 2 * kWordSize));  // Array.
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check.
  __ cmpq(RCX, FieldAddress(RAX, Array::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  // Note that RBX is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ movq(RAX, FieldAddress(RAX, RCX, TIMES_4, sizeof(RawArray)));
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::ImmutableArray_getIndexed(Assembler* assembler) {
  return Array_getIndexed(assembler);
}


bool Intrinsifier::Array_setIndexed(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return false;
  }
  __ movq(RDX, Address(RSP, + 1 * kWordSize));  // Value.
  __ movq(RCX, Address(RSP, + 2 * kWordSize));  // Index.
  __ movq(RAX, Address(RSP, + 3 * kWordSize));  // Array.
  Label fall_through;
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);
  // Range check.
  __ cmpq(RCX, FieldAddress(RAX, Array::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  // Note that RBX is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  // Destroy RCX as we will not continue in the function.
  __ StoreIntoObject(RAX,
                     FieldAddress(RAX, RCX, TIMES_4, sizeof(RawArray)),
                     RDX);
  // Caller is responsible of preserving the value if necessary.
  __ ret();
  __ Bind(&fall_through);
  return false;
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+2), data (+1), return-address (+0).
bool Intrinsifier::GArray_Allocate(Assembler* assembler) {
  // This snippet of inlined code uses the following registers:
  // RAX, RCX, R13
  // and the newly allocated object is returned in RAX.
  const intptr_t kTypeArgumentsOffset = 2 * kWordSize;
  const intptr_t kArrayOffset = 1 * kWordSize;
  Label fall_through;

  // Compute the size to be allocated, it is based on the array length
  // and is computed as:
  // RoundedAllocationSize(sizeof(RawGrowableObjectArray)) +
  intptr_t fixed_size = GrowableObjectArray::InstanceSize();

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  __ movq(RAX, Immediate(heap->TopAddress()));
  __ movq(RAX, Address(RAX, 0));
  __ leaq(RCX, Address(RAX, fixed_size));

  // Check if the allocation fits into the remaining space.
  // RAX: potential new backing array object start.
  // RCX: potential next object start.
  __ movq(R13, Immediate(heap->EndAddress()));
  __ cmpq(RCX, Address(R13, 0));
  __ j(ABOVE_EQUAL, &fall_through);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ movq(R13, Immediate(heap->TopAddress()));
  __ movq(Address(R13, 0), RCX);
  __ addq(RAX, Immediate(kHeapObjectTag));

  // Initialize the tags.
  // EAX: new growable array object start as a tagged pointer.
  const Class& cls = Class::Handle(
      isolate->object_store()->growable_object_array_class());
  uword tags = 0;
  tags = RawObject::SizeTag::update(fixed_size, tags);
  tags = RawObject::ClassIdTag::update(cls.id(), tags);
  __ movq(FieldAddress(RAX, GrowableObjectArray::tags_offset()),
          Immediate(tags));

  // Store backing array object in growable array object.
  __ movq(RCX, Address(RSP, kArrayOffset));  // data argument.
  __ StoreIntoObject(RAX,
                     FieldAddress(RAX, GrowableObjectArray::data_offset()),
                     RCX);

  // RAX: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ movq(RCX, Address(RSP, kTypeArgumentsOffset));  // type argument.
  __ StoreIntoObjectNoBarrier(
      RAX,
      FieldAddress(RAX, GrowableObjectArray::type_arguments_offset()),
      RCX);

  // Set the length field in the growable array object to 0.
  __ movq(FieldAddress(RAX, GrowableObjectArray::length_offset()),
          Immediate(0));
  __ ret();  // returns the newly allocated object in RAX.

  __ Bind(&fall_through);
  return false;
}


// Get length of growable object array.
// On stack: growable array (+1), return-address (+0).
bool Intrinsifier::GrowableArray_getLength(Assembler* assembler) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, GrowableObjectArray::length_offset()));
  __ ret();
  return true;
}


bool Intrinsifier::GrowableArray_getCapacity(Assembler* assembler) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, GrowableObjectArray::data_offset()));
  __ movq(RAX, FieldAddress(RAX, Array::length_offset()));
  __ ret();
  return true;
}


// Access growable object array at specified index.
// On stack: growable array (+2), index (+1), return-address (+0).
bool Intrinsifier::GrowableArray_getIndexed(Assembler* assembler) {
  Label fall_through;
  __ movq(RCX, Address(RSP, + 1 * kWordSize));  // Index.
  __ movq(RAX, Address(RSP, + 2 * kWordSize));  // GrowableArray.
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check using _length field.
  __ cmpq(RCX, FieldAddress(RAX, GrowableObjectArray::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  __ movq(RAX, FieldAddress(RAX, GrowableObjectArray::data_offset()));  // data.

  // Note that RCX is Smi, i.e, times 4.
  ASSERT(kSmiTagShift == 1);
  __ movq(RAX, FieldAddress(RAX, RCX, TIMES_4, sizeof(RawArray)));
  __ ret();
  __ Bind(&fall_through);
  return false;
}


// Set value into growable object array at specified index.
// On stack: growable array (+3), index (+2), value (+1), return-address (+0).
bool Intrinsifier::GrowableArray_setIndexed(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return false;
  }
  __ movq(RDX, Address(RSP, + 1 * kWordSize));  // Value.
  __ movq(RCX, Address(RSP, + 2 * kWordSize));  // Index.
  __ movq(RAX, Address(RSP, + 3 * kWordSize));  // GrowableArray.
  Label fall_through;
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, &fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check using _length field.
  __ cmpq(RCX, FieldAddress(RAX, GrowableObjectArray::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, &fall_through, Assembler::kNearJump);
  __ movq(RAX, FieldAddress(RAX, GrowableObjectArray::data_offset()));  // data.
  // Note that RCX is Smi, i.e, times 4.
  ASSERT(kSmiTagShift == 1);
  __ StoreIntoObject(RAX,
                     FieldAddress(RAX, RCX, TIMES_4, sizeof(RawArray)),
                     RDX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


// Set length of growable object array.
// On stack: growable array (+2), length (+1), return-address (+0).
bool Intrinsifier::GrowableArray_setLength(Assembler* assembler) {
  Label fall_through;
  __ movq(RAX, Address(RSP, + 2 * kWordSize));  // Growable array.
  __ movq(RCX, Address(RSP, + 1 * kWordSize));  // Length.
  __ movq(RDX, FieldAddress(RAX, GrowableObjectArray::data_offset()));
  __ cmpq(RCX, FieldAddress(RDX, Array::length_offset()));
  __ j(ABOVE, &fall_through, Assembler::kNearJump);
  __ movq(FieldAddress(RAX, GrowableObjectArray::length_offset()), RCX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


// Set data of growable object array.
// On stack: growable array (+2), data (+1), return-address (+0).
bool Intrinsifier::GrowableArray_setData(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return false;
  }
  __ movq(RAX, Address(RSP, + 2 * kWordSize));
  __ movq(RBX, Address(RSP, + 1 * kWordSize));
  __ movq(FieldAddress(RAX, GrowableObjectArray::data_offset()), RBX);
  __ ret();
  return true;
}


bool Intrinsifier::ByteArrayBase_getLength(Assembler* assembler) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ movq(RAX, FieldAddress(RAX, ByteArray::length_offset()));
  __ ret();
  // Generate enough code to satisfy patchability constraint.
  intptr_t offset = __ CodeSize();
  __ nop(JumpPattern::InstructionLength() - offset);
  return true;
}


// Assumes the first argument is a byte array, tests if the second
// argument is a smi, tests if the smi is within bounds of the array
// length, and jumps to label fall_through if any test fails.  Leaves
// the second argument in RBX.
void TestByteArrayIndex(Assembler* assembler, Label* fall_through) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));  // Array.
  __ movq(RBX, Address(RSP, + 2 * kWordSize));  // Index.
  __ testq(RBX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, fall_through, Assembler::kNearJump);  // Non-smi index.
  // Range check.
  __ cmpq(RBX, FieldAddress(RAX, ByteArray::length_offset()));
  // Runtime throws exception.
  __ j(ABOVE_EQUAL, fall_through, Assembler::kNearJump);
}


bool Intrinsifier::Int8Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ SmiUntag(RBX);
  __ movsxb(RAX, FieldAddress(RAX,
                              RBX,
                              TIMES_1,
                              Int8Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Uint8Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ SmiUntag(RBX);
  __ movzxb(RAX, FieldAddress(RAX,
                              RBX,
                              TIMES_1,
                              Uint8Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Int16Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ movsxw(RAX, FieldAddress(RAX,
                              RBX,
                              TIMES_1,
                              Int16Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Uint16Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ movzxw(RAX, FieldAddress(RAX,
                              RBX,
                              TIMES_1,
                              Uint16Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Int32Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ movsxl(RAX, FieldAddress(RAX,
                              RBX,
                              TIMES_2,
                              Int32Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Uint32Array_getIndexed(Assembler* assembler) {
  Label fall_through;
  TestByteArrayIndex(assembler, &fall_through);
  __ movl(RAX, FieldAddress(RAX,
                            RBX,
                            TIMES_2,
                            Uint32Array::data_offset()));
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


// Tests if two top most arguments are smis, jumps to label not_smi if not.
// Topmost argument is in RAX.
static void TestBothArgumentsSmis(Assembler* assembler, Label* not_smi) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ movq(RCX, Address(RSP, + 2 * kWordSize));
  __ orq(RCX, RAX);
  __ testq(RCX, Immediate(kSmiTagMask));
  __ j(NOT_ZERO, not_smi, Assembler::kNearJump);
}


bool Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_add(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_sub(Assembler* assembler) {
  return false;
}



bool Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_mul(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_modulo(Assembler* assembler) {
  Label fall_through, return_zero, try_modulo;
  TestBothArgumentsSmis(assembler, &fall_through);
  // RAX: right argument (divisor)
  // Check if modulo by zero -> exception thrown in main function.
  __ cmpq(RAX, Immediate(0));
  __ j(EQUAL, &fall_through,  Assembler::kNearJump);
  __ movq(RCX, Address(RSP, + 2 * kWordSize));  // Left argument (dividend).
  __ cmpq(RCX, Immediate(0));
  __ j(LESS, &fall_through, Assembler::kNearJump);
  __ cmpq(RCX, RAX);
  __ j(EQUAL, &return_zero, Assembler::kNearJump);
  __ j(GREATER, &try_modulo, Assembler::kNearJump);
  __ movq(RAX, RCX);  // Return dividend as it is smaller than divisor.
  __ ret();
  __ Bind(&return_zero);
  __ xorq(RAX, RAX);  // Return zero.
  __ ret();
  __ Bind(&try_modulo);
  // RAX: right (non-null divisor).
  __ movq(RCX, RAX);
  __ SmiUntag(RCX);
  __ movq(RAX, Address(RSP, + 2 * kWordSize));  // Left argument (dividend).
  __ SmiUntag(RAX);
  __ cqo();
  __ idivq(RCX);
  __ movq(RAX, RDX);
  __ SmiTag(RAX);
  __ ret();
  __ Bind(&fall_through);
  return false;
}


bool Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_negate(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitOr(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_bitXor(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_shl(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_lessThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_greaterThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_lessEqualThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_greaterEqualThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_equalToInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_equal(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_sar(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_greaterThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_greaterEqualThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_lessThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_equal(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_lessEqualThan(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_toDouble(Assembler* assembler) {
  __ movq(RAX, Address(RSP, + 1 * kWordSize));
  __ ret();
  // Generate enough code to satisfy patchability constraint.
  intptr_t offset = __ CodeSize();
  __ nop(JumpPattern::InstructionLength() - offset);
  return true;
}

bool Intrinsifier::Double_add(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_mul(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_sub(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_div(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_mulFromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_fromInteger(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_isNaN(Assembler* assembler) {
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  Label is_true;
  __ movq(RAX, Address(RSP, +1 * kWordSize));
  __ movsd(XMM0, FieldAddress(RAX, Double::value_offset()));
  __ comisd(XMM0, XMM0);
  __ j(PARITY_EVEN, &is_true, Assembler::kNearJump);  // NaN -> true;
  __ LoadObject(RAX, bool_false);
  __ ret();
  __ Bind(&is_true);
  __ LoadObject(RAX, bool_true);
  __ ret();
  return true;  // Method is complete, no slow case.
}


bool Intrinsifier::Double_isNegative(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Math_sqrt(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Math_sin(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Math_cos(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Object_equal(Assembler* assembler) {
  return false;
}


bool Intrinsifier::FixedSizeArrayIterator_next(Assembler* assembler) {
  return false;
}


bool Intrinsifier::FixedSizeArrayIterator_hasNext(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_charCodeAt(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_hashCode(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_isEmpty(Assembler* assembler) {
  return false;
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
