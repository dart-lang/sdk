// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/intrinsifier.h"

#include "vm/assembler.h"
#include "vm/flow_graph_compiler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, enable_type_checks);


#define __ assembler->


void Intrinsifier::Array_getLength(Assembler* assembler) {
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(V0, Array::length_offset()));
}


void Intrinsifier::ImmutableList_getLength(Assembler* assembler) {
  Array_getLength(assembler);
}


void Intrinsifier::Array_getIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 0 * kWordSize));  // Index

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through
  __ delay_slot()->lw(T1, Address(SP, + 1 * kWordSize));  // Array

  // Range check.
  __ lw(T2, FieldAddress(T1, Array::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  ASSERT(kSmiTagShift == 1);
  // array element at T1 + T0*2 + Array::data_offset - 1
  __ sll(T2, T0, 1);
  __ addu(T2, T1, T2);
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(T2, Array::data_offset()));
  __ Bind(&fall_through);
}


void Intrinsifier::ImmutableList_getIndexed(Assembler* assembler) {
  Array_getIndexed(assembler);
}


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
void Intrinsifier::Array_setIndexed(Assembler* assembler) {
  Label fall_through;

  if (FLAG_enable_type_checks) {
    const intptr_t type_args_field_offset =
        ComputeObjectArrayTypeArgumentsOffset();
    // Inline simple tests (Smi, null), fallthrough if not positive.
    Label checked_ok;
    __ lw(T2, Address(SP, 0 * kWordSize));  // Value.

    // Null value is valid for any type.
    __ LoadImmediate(T7, reinterpret_cast<int32_t>(Object::null()));
    __ beq(T2, T7, &checked_ok);

    __ lw(T1, Address(SP, 2 * kWordSize));  // Array.
    __ lw(T1, FieldAddress(T1, type_args_field_offset));

    // T1: Type arguments of array.
    __ beq(T1, T7, &checked_ok);

    // Check if it's dynamic.
    // Get type at index 0.
    __ lw(T0, FieldAddress(T1, TypeArguments::type_at_offset(0)));
    __ BranchEqual(T0, Type::ZoneHandle(Type::DynamicType()), &checked_ok);

    // Check for int and num.
    __ andi(CMPRES1, T2, Immediate(kSmiTagMask));
    __ bne(CMPRES1, ZR, &fall_through);  // Non-smi value.

    __ BranchEqual(T0, Type::ZoneHandle(Type::IntType()), &checked_ok);
    __ BranchNotEqual(T0, Type::ZoneHandle(Type::Number()), &fall_through);
    __ Bind(&checked_ok);
  }
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
  __ sll(T1, T1, 1);  // T1 is Smi.
  __ addu(T1, T0, T1);
  __ StoreIntoObject(T0,
                     FieldAddress(T1, Array::data_offset()),
                     T2);
  // Caller is responsible for preserving the value if necessary.
  __ Ret();
  __ Bind(&fall_through);
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+1), data (+0).
void Intrinsifier::GrowableList_Allocate(Assembler* assembler) {
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
      V0,
      FieldAddress(V0, GrowableObjectArray::data_offset()),
      T1);

  // V0: new growable array object start as a tagged pointer.
  // Store the type argument field in the growable array object.
  __ lw(T1, Address(SP, kTypeArgumentsOffset));  // Type argument.
  __ StoreIntoObjectNoBarrier(
      V0,
      FieldAddress(V0, GrowableObjectArray::type_arguments_offset()),
      T1);
  __ UpdateAllocationStats(kGrowableObjectArrayCid, T1);
  // Set the length field in the growable array object to 0.
  __ Ret();  // Returns the newly allocated object in V0.
  __ delay_slot()->sw(ZR,
      FieldAddress(V0, GrowableObjectArray::length_offset()));

  __ Bind(&fall_through);
}


void Intrinsifier::GrowableList_getLength(Assembler* assembler) {
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->lw(V0,
      FieldAddress(V0, GrowableObjectArray::length_offset()));
}


void Intrinsifier::GrowableList_getCapacity(Assembler* assembler) {
  __ lw(V0, Address(SP, 0 * kWordSize));
  __ lw(V0, FieldAddress(V0, GrowableObjectArray::data_offset()));
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(V0, Array::length_offset()));
}


void Intrinsifier::GrowableList_getIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, 0 * kWordSize));  // Index

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through
  __ delay_slot()->lw(T1, Address(SP, 1 * kWordSize));  // Array

  // Range check.
  __ lw(T2, FieldAddress(T1, GrowableObjectArray::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  __ lw(T2, FieldAddress(T1, GrowableObjectArray::data_offset()));  // data

  ASSERT(kSmiTagShift == 1);
  // array element at T2 + T0 * 2 + Array::data_offset - 1
  __ sll(T3, T0, 1);
  __ addu(T2, T2, T3);
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(T2, Array::data_offset()));
  __ Bind(&fall_through);
}


// Set value into growable object array at specified index.
// On stack: growable array (+2), index (+1), value (+0).
void Intrinsifier::GrowableList_setIndexed(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ lw(T1, Address(SP, 1 * kWordSize));  // Index.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Non-smi index.
  __ delay_slot()->lw(T0, Address(SP, 2 * kWordSize));  // GrowableArray.
  // Range check using _length field.
  __ lw(T2, FieldAddress(T0, GrowableObjectArray::length_offset()));
  // Runtime throws exception.
  __ BranchUnsignedGreaterEqual(T1, T2, &fall_through);
  __ lw(T0, FieldAddress(T0, GrowableObjectArray::data_offset()));  // data.
  __ lw(T2, Address(SP, 0 * kWordSize));  // Value.
  // Note that T1 is Smi, i.e, times 2.
  ASSERT(kSmiTagShift == 1);
  __ sll(T1, T1, 1);
  __ addu(T1, T0, T1);
  __ StoreIntoObject(T0,
                     FieldAddress(T1, Array::data_offset()),
                     T2);
  __ Ret();
  __ Bind(&fall_through);
}


// Set length of growable object array. The length cannot
// be greater than the length of the data container.
// On stack: growable array (+1), length (+0).
void Intrinsifier::GrowableList_setLength(Assembler* assembler) {
  Label fall_through;
  __ lw(T1, Address(SP, 0 * kWordSize));  // Length value.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Non-smi length.
  __ delay_slot()->lw(T0, Address(SP, 1 * kWordSize));  // Growable array.
  __ Ret();
  __ delay_slot()->sw(T1,
      FieldAddress(T0, GrowableObjectArray::length_offset()));
  __ Bind(&fall_through);
}


// Set data of growable object array.
// On stack: growable array (+1), data (+0).
void Intrinsifier::GrowableList_setData(Assembler* assembler) {
  if (FLAG_enable_type_checks) {
    return;
  }
  Label fall_through;
  __ lw(T1, Address(SP, 0 * kWordSize));  // Data.
  // Check that data is an ObjectArray.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, &fall_through);  // Data is Smi.
  __ LoadClassId(CMPRES1, T1);
  __ BranchNotEqual(CMPRES1, kArrayCid, &fall_through);
  __ lw(T0, Address(SP, 1 * kWordSize));  // Growable array.
  __ StoreIntoObject(T0,
                     FieldAddress(T0, GrowableObjectArray::data_offset()),
                     T1);
  __ Ret();
  __ Bind(&fall_through);
}


// Add an element to growable array if it doesn't need to grow, otherwise
// call into regular code.
// On stack: growable array (+1), value (+0).
void Intrinsifier::GrowableList_add(Assembler* assembler) {
  // In checked mode we need to type-check the incoming argument.
  if (FLAG_enable_type_checks) return;
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
  __ StoreIntoObject(T2,
                     FieldAddress(T1, Array::data_offset()),
                     T0);
  __ LoadImmediate(T7, reinterpret_cast<int32_t>(Object::null()));
  __ Ret();
  __ delay_slot()->mov(V0, T7);
  __ Bind(&fall_through);
}


#define TYPED_ARRAY_ALLOCATION(type_name, cid, max_len, scale_shift)           \
  Label fall_through;                                                          \
  const intptr_t kArrayLengthStackOffset = 0 * kWordSize;                      \
  __ lw(T2, Address(SP, kArrayLengthStackOffset));  /* Array length. */        \
  /* Check that length is a positive Smi. */                                   \
  /* T2: requested array length argument. */                                   \
  __ andi(CMPRES1, T2, Immediate(kSmiTagMask));                                \
  __ bne(CMPRES1, ZR, &fall_through);                                          \
  __ BranchSignedLess(T2, 0, &fall_through);                                   \
  __ SmiUntag(T2);                                                             \
  /* Check for maximum allowed length. */                                      \
  /* T2: untagged array length. */                                             \
  __ BranchSignedGreater(T2, max_len, &fall_through);                          \
  __ sll(T2, T2, scale_shift);                                                 \
  const intptr_t fixed_size = sizeof(Raw##type_name) + kObjectAlignment - 1;   \
  __ AddImmediate(T2, fixed_size);                                             \
  __ LoadImmediate(TMP, -kObjectAlignment);                                    \
  __ and_(T2, T2, TMP);                                                        \
  Heap* heap = Isolate::Current()->heap();                                     \
                                                                               \
  __ LoadImmediate(V0, heap->TopAddress());                                    \
  __ lw(V0, Address(V0, 0));                                                   \
                                                                               \
  /* T2: allocation size. */                                                   \
  __ AdduDetectOverflow(T1, V0, T2, CMPRES1);                                  \
  __ bltz(CMPRES1, &fall_through);                                             \
                                                                               \
  /* Check if the allocation fits into the remaining space. */                 \
  /* V0: potential new object start. */                                        \
  /* T1: potential next object start. */                                       \
  /* T2: allocation size. */                                                   \
  __ LoadImmediate(T3, heap->EndAddress());                                    \
  __ lw(T3, Address(T3, 0));                                                   \
  __ BranchUnsignedGreaterEqual(T1, T3, &fall_through);                        \
                                                                               \
  /* Successfully allocated the object(s), now update top to point to */       \
  /* next object start and initialize the object. */                           \
  __ LoadImmediate(T3, heap->TopAddress());                                    \
  __ sw(T1, Address(T3, 0));                                                   \
  __ AddImmediate(V0, kHeapObjectTag);                                         \
  __ UpdateAllocationStatsWithSize(cid, T2, T4);                               \
  /* Initialize the tags. */                                                   \
  /* V0: new object start as a tagged pointer. */                              \
  /* T1: new object end address. */                                            \
  /* T2: allocation size. */                                                   \
  {                                                                            \
    Label size_tag_overflow, done;                                             \
    __ BranchUnsignedGreater(T2, RawObject::SizeTag::kMaxSizeTag,              \
                             &size_tag_overflow);                              \
    __ b(&done);                                                               \
    __ delay_slot()->sll(T2, T2,                                               \
        RawObject::kSizeTagPos - kObjectAlignmentLog2);                        \
                                                                               \
    __ Bind(&size_tag_overflow);                                               \
    __ mov(T2, ZR);                                                            \
    __ Bind(&done);                                                            \
                                                                               \
    /* Get the class index and insert it into the tags. */                     \
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cid));                 \
    __ or_(T2, T2, TMP);                                                       \
    __ sw(T2, FieldAddress(V0, type_name::tags_offset()));  /* Tags. */        \
  }                                                                            \
  /* Set the length field. */                                                  \
  /* V0: new object start as a tagged pointer. */                              \
  /* T1: new object end address. */                                            \
  __ lw(T2, Address(SP, kArrayLengthStackOffset));  /* Array length. */        \
  __ StoreIntoObjectNoBarrier(V0,                                              \
                              FieldAddress(V0, type_name::length_offset()),    \
                              T2);                                             \
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
  __ Bind(&fall_through);                                                      \


// Gets the length of a TypedData.
void Intrinsifier::TypedData_getLength(Assembler* assembler) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(T0, TypedData::length_offset()));
}


void Intrinsifier::Uint8Array_getIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 0 * kWordSize));  // Index.

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through.
  __ delay_slot()->lw(T1, Address(SP, + 1 * kWordSize));  // Array.

  // Range check.
  __ lw(T2, FieldAddress(T1, TypedData::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  __ SmiUntag(T0);
  __ addu(T1, T1, T0);
  __ lbu(V0, FieldAddress(T1, TypedData::data_offset()));
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&fall_through);
}


void Intrinsifier::ExternalUint8Array_getIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 0 * kWordSize));  // Index.

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through.
  __ delay_slot()->lw(T1, Address(SP, + 1 * kWordSize));  // Array.

  // Range check.
  __ lw(T2, FieldAddress(T1, TypedData::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  __ lw(T1, FieldAddress(T1, ExternalTypedData::data_offset()));
  __ SmiUntag(T0);
  __ addu(T1, T1, T0);
  __ lbu(V0, Address(T1, 0));
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&fall_through);
}


void Intrinsifier::Float64Array_getIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 0 * kWordSize));  // Index.

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through.
  __ delay_slot()->lw(T1, Address(SP, + 1 * kWordSize));  // Array.

  // Range check.
  __ lw(T2, FieldAddress(T1, TypedData::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  Address element_address =
      __ ElementAddressForRegIndex(true,  // Load.
                                   false,  // Not external.
                                   kTypedDataFloat64ArrayCid,  // Cid.
                                   8,  // Index scale.
                                   T1,  // Array.
                                   T0);  // Index.

  __ LoadDFromOffset(D0, element_address.base(), element_address.offset());

  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class,
                 &fall_through,
                 V0,  // Result register.
                 T1);
  __ StoreDToOffset(D0, V0, Double::value_offset() - kHeapObjectTag);
  __ Ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Float64Array_setIndexed(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 1 * kWordSize));  // Index.

  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, &fall_through);  // Index is not an smi, fall through.
  __ delay_slot()->lw(T1, Address(SP, + 2 * kWordSize));  // Array.

  // Range check.
  __ lw(T2, FieldAddress(T1, TypedData::length_offset()));
  __ BranchUnsignedGreaterEqual(T0, T2, &fall_through);

  __ lw(T2, Address(SP, + 0 * kWordSize));  // Value.
  __ andi(CMPRES1, T2, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, &fall_through);  // Value is a Smi. Fall through.

  __ LoadClassId(T3, T2);
  __ BranchNotEqual(T3, kDoubleCid, &fall_through);  // Not a Double.

  __ LoadDFromOffset(D0, T2, Double::value_offset() - kHeapObjectTag);

  Address element_address =
      __ ElementAddressForRegIndex(false,  // Store.
                                   false,  // Not external.
                                   kTypedDataFloat64ArrayCid,  // Cid.
                                   8,  // Index scale.
                                   T1,  // Array.
                                   T0);  // Index.
  __ StoreDToOffset(D0, element_address.base(), element_address.offset());
  __ Ret();
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
  __ AdduDetectOverflow(V0, T0, T1, CMPRES1);  // Add.
  __ bltz(CMPRES1, &fall_through);  // Fall through on overflow.
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
  __ bltz(CMPRES1, &fall_through);  // Fall through on overflow.
  __ Ret();
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_sub(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);
  __ SubuDetectOverflow(V0, T1, T0, CMPRES1);  // Subtract.
  __ bltz(CMPRES1, &fall_through);  // Fall through on overflow.
  __ Ret();  // Nothing in branch delay slot.
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  Label fall_through;

  TestBothArgumentsSmis(assembler, &fall_through);  // checks two smis
  __ SmiUntag(T0);  // untags T0. only want result shifted by one

  __ mult(T0, T1);  // HI:LO <- T0 * T1.
  __ mflo(V0);  // V0 <- LO.
  __ mfhi(T2);  // T2 <- HI.
  __ sra(T3, V0, 31);  // T3 <- V0 >> 31.
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
// V0: Untagged result.
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
  __ mfhi(result);  // result <- HI.
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
  __ mflo(V0);  // V0 <- LO
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which case we
  // cannot tag the result.
  __ BranchEqual(V0, 0x40000000, &fall_through);
  __ Ret();
  __ delay_slot()->SmiTag(V0);
  __ Bind(&fall_through);
}


void Intrinsifier::Integer_negate(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, + 0 * kWordSize));  // Grabs first argument.
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));  // Test for Smi.
  __ bne(CMPRES1, ZR, &fall_through);  // Fall through if not a Smi.
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
  __ BranchUnsignedGreater(T0, Smi::RawValue(Smi::kBits), &fall_through);
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
  __ sllv(T3, T3, T0);  // T3 <- T3 << T0
  __ addiu(T3, T3, Immediate(-1));  // T3 <- T3 - 1
  __ subu(T4, ZR, T0);  // T4 <- -T0
  __ addiu(T4, T4, Immediate(32));  // T4 <- 32 - T0
  __ sllv(T3, T3, T4);  // T3 <- T3 << T4
  __ and_(T3, T3, T1);  // T3 <- T3 & T1
  __ srlv(T3, T3, T4);  // T3 <- T3 >> T4
  // Now T3 has the bits that fall off of T1 on a left shift.
  __ sllv(T0, T1, T0);  // T0 gets low bits.

  const Class& mint_class = Class::Handle(
      Isolate::Current()->object_store()->mint_class());
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
  __ BranchNotEqual(CMPRES1, kMintCid, not_smi_or_mint);

  // Mint.
  __ lw(res_lo, FieldAddress(reg, Mint::value_offset()));
  __ lw(res_hi, FieldAddress(reg, Mint::value_offset() + kWordSize));
  __ Bind(&done);
  return;
}


static void CompareIntegers(Assembler* assembler, Condition true_condition) {
  Label try_mint_smi, is_true, is_false, drop_two_fall_through, fall_through;
  TestBothArgumentsSmis(assembler, &try_mint_smi);
  // T0 contains the right argument. T1 contains left argument

  switch (true_condition) {
    case LT: __ BranchSignedLess(T1, T0, &is_true); break;
    case LE: __ BranchSignedLessEqual(T1, T0, &is_true); break;
    case GT: __ BranchSignedGreater(T1, T0, &is_true); break;
    case GE: __ BranchSignedGreaterEqual(T1, T0, &is_true); break;
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
  // Condition hi_true_cond, hi_false_cond, lo_false_cond;
  switch (true_condition) {
    case LT:
    case LE: {
      // Compare left hi, right high.
      __ BranchSignedGreater(T3, T5, &is_false);
      __ BranchSignedLess(T3, T5, &is_true);
      // Compare left lo, right lo.
      if (true_condition == LT) {
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
      if (true_condition == GT) {
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
  __ BranchEqual(CMPRES1, kDoubleCid, &fall_through);
  __ LoadObject(V0, Bool::False());  // Smi == Mint -> false.
  __ Ret();

  __ Bind(&receiver_not_smi);
  // T1:: receiver.

  __ LoadClassId(CMPRES1, T1);
  __ BranchNotEqual(CMPRES1, kMintCid, &fall_through);
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
  __ slt(CMPRES1, T2, T0);  // CMPRES1 <- 0x1F < T0 ? 1 : 0
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
  // TODO(sra): Implement.
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
  __ BranchNotEqual(CMPRES1, kDoubleCid, not_double_smi);
  // Fall through with Double in T0.
}


// Both arguments on stack, arg0 (left) is a double, arg1 (right) is of unknown
// type. Return true or false object in the register V0. Any NaN argument
// returns false. Any non-double arg1 causes control flow to fall through to the
// slow case (compiled method body).
static void CompareDoubles(Assembler* assembler, Condition true_condition) {
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

  switch (true_condition) {
    case EQ: __ ceqd(D0, D1); break;
    case LT: __ coltd(D0, D1); break;
    case LE: __ coled(D0, D1); break;
    case GT: __ coltd(D1, D0); break;
    case GE: __ coled(D1, D0); break;
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
  __ cvtdw(D1, STMP1);
  __ b(&double_op);

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
  Label fall_through;

  TestLastArgumentIsDouble(assembler, &fall_through, &fall_through);
  // Both arguments are double, right operand is in T0.
  __ lwc1(F2, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F3, FieldAddress(T0, Double::value_offset() + kWordSize));
  __ lw(T0, Address(SP, 1 * kWordSize));  // Left argument.
  __ lwc1(F0, FieldAddress(T0, Double::value_offset()));
  __ lwc1(F1, FieldAddress(T0, Double::value_offset() + kWordSize));
  switch (kind) {
    case Token::kADD: __ addd(D0, D0, D1); break;
    case Token::kSUB: __ subd(D0, D0, D1); break;
    case Token::kMUL: __ muld(D0, D0, D1); break;
    case Token::kDIV: __ divd(D0, D0, D1); break;
    default: UNREACHABLE();
  }
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));
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
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
  __ TryAllocate(double_class, &fall_through, V0, T1);  // Result register.
  __ swc1(F0, FieldAddress(V0, Double::value_offset()));
  __ Ret();
  __ delay_slot()->swc1(F1,
                        FieldAddress(V0, Double::value_offset() + kWordSize));
  __ Bind(&fall_through);
}


void Intrinsifier::Double_fromInteger(Assembler* assembler) {
  Label fall_through;

  __ lw(T0, Address(SP, 0 * kWordSize));
  __ andi(CMPRES1, T0, Immediate(kSmiTagMask));
  __ bne(T0, ZR, &fall_through);

  // Is Smi.
  __ SmiUntag(T0);
  __ mtc1(T0, F4);
  __ cvtdw(D0, F4);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
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
  __ mfc1(T0, F1);  // Moves bits 32...63 of D0 to T0.
  __ srl(T0, T0, 31);  // Get the sign bit down to bit 0 of T0.
  __ andi(CMPRES1, T0, Immediate(1));  // Check if the bit is set.
  __ bne(T0, ZR, &is_true);  // Sign bit set. True.
  __ b(&is_false);
}


void Intrinsifier::Double_toInt(Assembler* assembler) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ LoadDFromOffset(D0, T0, Double::value_offset() - kHeapObjectTag);

  __ cvtwd(F2, D0);
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


void Intrinsifier::Math_sqrt(Assembler* assembler) {
  Label fall_through, is_smi, double_op;
  TestLastArgumentIsDouble(assembler, &is_smi, &fall_through);
  // Argument is double and is in T0.
  __ LoadDFromOffset(D1, T0, Double::value_offset() - kHeapObjectTag);
  __ Bind(&double_op);
  __ sqrtd(D0, D1);
  const Class& double_class = Class::Handle(
      Isolate::Current()->object_store()->double_class());
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

  __ lw(T0, Address(SP, 0 * kWordSize));  // Receiver.
  __ lw(T1, FieldAddress(T0, state_field.Offset()));  // Field '_state'.

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


void Intrinsifier::Object_equal(Assembler* assembler) {
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


void Intrinsifier::String_getHashCode(Assembler* assembler) {
  Label fall_through;
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ lw(V0, FieldAddress(T0, String::hash_offset()));
  __ beq(V0, ZR, &fall_through);
  __ Ret();
  __ Bind(&fall_through);  // Hash not yet computed.
}


void Intrinsifier::String_getLength(Assembler* assembler) {
  __ lw(T0, Address(SP, 0 * kWordSize));
  __ Ret();
  __ delay_slot()->lw(V0, FieldAddress(T0, String::length_offset()));
}


void Intrinsifier::String_codeUnitAt(Assembler* assembler) {
  Label fall_through, try_two_byte_string;

  __ lw(T1, Address(SP, 0 * kWordSize));  // Index.
  __ lw(T0, Address(SP, 1 * kWordSize));  // String.

  // Checks.
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ bne(T1, ZR, &fall_through);  // Index is not a Smi.
  __ lw(T2, FieldAddress(T0, String::length_offset()));  // Range check.
  // Runtime throws exception.
  __ BranchUnsignedGreaterEqual(T1, T2, &fall_through);
  __ LoadClassId(CMPRES1, T0);  // Class ID check.
  __ BranchNotEqual(CMPRES1, kOneByteStringCid, &try_two_byte_string);

  // Grab byte and return.
  __ SmiUntag(T1);
  __ addu(T2, T0, T1);
  __ lbu(V0, FieldAddress(T2, OneByteString::data_offset()));
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&try_two_byte_string);
  __ BranchNotEqual(CMPRES1, kTwoByteStringCid, &fall_through);
  ASSERT(kSmiTagShift == 1);
  __ addu(T2, T0, T1);
  __ lhu(V0, FieldAddress(T2, OneByteString::data_offset()));
  __ Ret();
  __ delay_slot()->SmiTag(V0);

  __ Bind(&fall_through);
}


void Intrinsifier::String_getIsEmpty(Assembler* assembler) {
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
  __ BranchEqual(T2, Smi::RawValue(0), &done);
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

  __ mov(T6, length_reg);  // Save the length register.
  __ SmiUntag(length_reg);
  const intptr_t fixed_size = sizeof(RawString) + kObjectAlignment - 1;
  __ AddImmediate(length_reg, fixed_size);
  __ LoadImmediate(TMP, ~(kObjectAlignment - 1));
  __ and_(length_reg, length_reg, TMP);

  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();

  __ LoadImmediate(T3, heap->TopAddress());
  __ lw(V0, Address(T3, 0));

  // length_reg: allocation size.
  __ AdduDetectOverflow(T1, V0, length_reg, CMPRES1);
  __ bltz(CMPRES1, failure);  // Fail on overflow.

  // Check if the allocation fits into the remaining space.
  // V0: potential new object start.
  // T1: potential next object start.
  // T2: allocation size.
  // T3: heap->TopAddress().
  __ LoadImmediate(T4, heap->EndAddress());
  __ lw(T4, Address(T4, 0));
  __ BranchUnsignedGreaterEqual(T1, T4, failure);

  // Successfully allocated the object(s), now update top to point to
  // next object start and initialize the object.
  __ sw(T1, Address(T3, 0));
  __ AddImmediate(V0, kHeapObjectTag);

  __ UpdateAllocationStatsWithSize(kOneByteStringCid, T2, T3);

  // Initialize the tags.
  // V0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: allocation size.
  {
    Label overflow, done;
    const intptr_t shift = RawObject::kSizeTagPos - kObjectAlignmentLog2;
    const Class& cls =
        Class::Handle(isolate->object_store()->one_byte_string_class());

    __ BranchUnsignedGreater(T2, RawObject::SizeTag::kMaxSizeTag, &overflow);
    __ b(&done);
    __ delay_slot()->sll(T2, T2, shift);
    __ Bind(&overflow);
    __ mov(T2, ZR);
    __ Bind(&done);

    // Get the class index and insert it into the tags.
    // T2: size and bit tags.
    __ LoadImmediate(TMP, RawObject::ClassIdTag::encode(cls.id()));
    __ or_(T2, T2, TMP);
    __ sw(T2, FieldAddress(V0, String::tags_offset()));  // Store tags.
  }

  // Set the length field using the saved length (T6).
  __ StoreIntoObjectNoBarrier(V0,
                              FieldAddress(V0, String::length_offset()),
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


void Intrinsifier::OneByteString_setAt(Assembler* assembler) {
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
void StringEquality(Assembler* assembler, intptr_t string_cid) {
  Label fall_through, is_true, is_false, loop;
  __ lw(T0, Address(SP, 1 * kWordSize));  // This.
  __ lw(T1, Address(SP, 0 * kWordSize));  // Other.

  // Are identical?
  __ beq(T0, T1, &is_true);

  // Is other OneByteString?
  __ andi(CMPRES1, T1, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, &fall_through);  // Other is Smi.
  __ LoadClassId(CMPRES1, T1);  // Class ID check.
  __ BranchNotEqual(CMPRES1, string_cid, &fall_through);

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
  __ BranchSignedLess(T2, 0, &is_true);
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

// On stack: user tag (+0).
void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  // T1: Isolate.
  Isolate* isolate = Isolate::Current();
  __ LoadImmediate(T1, reinterpret_cast<uword>(isolate));
  // V0: Current user tag.
  __ lw(V0, Address(T1, Isolate::current_tag_offset()));
  // T2: UserTag.
  __ lw(T2, Address(SP, + 0 * kWordSize));
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
  Isolate* isolate = Isolate::Current();
  // V0: Address of default tag.
  __ LoadImmediate(V0,
      reinterpret_cast<uword>(isolate->object_store()) +
                              ObjectStore::default_tag_offset());
  __ Ret();
  __ delay_slot()->lw(V0, Address(V0, 0));
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  // V0: Isolate.
  Isolate* isolate = Isolate::Current();
  __ LoadImmediate(V0, reinterpret_cast<uword>(isolate));
  // Set return value.
  __ Ret();
  __ delay_slot()->lw(V0, Address(V0, Isolate::current_tag_offset()));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
