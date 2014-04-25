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

#define __ assembler->

void Intrinsifier::List_Allocate(Assembler* assembler) {
  return;
}


void Intrinsifier::Array_getLength(Assembler* assembler) {
  return;
}


void Intrinsifier::ImmutableList_getLength(Assembler* assembler) {
  return;
}


void Intrinsifier::Array_getIndexed(Assembler* assembler) {
  return;
}


void Intrinsifier::ImmutableList_getIndexed(Assembler* assembler) {
  return;
}


void Intrinsifier::Array_setIndexed(Assembler* assembler) {
  return;
}


// Allocate a GrowableObjectArray using the backing array specified.
// On stack: type argument (+1), data (+0).
void Intrinsifier::GrowableList_Allocate(Assembler* assembler) {
  return;
}


void Intrinsifier::GrowableList_getLength(Assembler* assembler) {
  return;
}


void Intrinsifier::GrowableList_getCapacity(Assembler* assembler) {
  return;
}


void Intrinsifier::GrowableList_getIndexed(Assembler* assembler) {
  return;
}


// Set value into growable object array at specified index.
// On stack: growable array (+2), index (+1), value (+0).
void Intrinsifier::GrowableList_setIndexed(Assembler* assembler) {
  return;
}


// Set length of growable object array. The length cannot
// be greater than the length of the data container.
// On stack: growable array (+1), length (+0).
void Intrinsifier::GrowableList_setLength(Assembler* assembler) {
  return;
}


// Set data of growable object array.
// On stack: growable array (+1), data (+0).
void Intrinsifier::GrowableList_setData(Assembler* assembler) {
  return;
}


void Intrinsifier::GrowableList_add(Assembler* assembler) {
  return;
}


// Gets the length of a TypedData.
void Intrinsifier::TypedData_getLength(Assembler* assembler) {
  return;
}


#define TYPED_DATA_ALLOCATOR(clazz)                                            \
void Intrinsifier::TypedData_##clazz##_new(Assembler* assembler) {             \
  return;                                                                      \
}                                                                              \
void Intrinsifier::TypedData_##clazz##_factory(Assembler* assembler) {         \
  return;                                                                      \
}
CLASS_LIST_TYPED_DATA(TYPED_DATA_ALLOCATOR)
#undef TYPED_DATA_ALLOCATOR


void Intrinsifier::Integer_addFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_add(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_subFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_sub(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_mulFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_mul(Assembler* assembler) {
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
  return;
}


void Intrinsifier::Integer_truncDivide(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_negate(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitAndFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitAnd(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitOrFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitOr(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitXorFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_bitXor(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_shl(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_lessThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_greaterThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_lessEqualThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_greaterEqualThan(Assembler* assembler) {
  return;
}


// This is called for Smi, Mint and Bigint receivers. The right argument
// can be Smi, Mint, Bigint or double.
void Intrinsifier::Integer_equalToInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_equal(Assembler* assembler) {
  return;
}


void Intrinsifier::Integer_sar(Assembler* assembler) {
  return;
}


void Intrinsifier::Smi_bitNegate(Assembler* assembler) {
  return;
}


void Intrinsifier::Smi_bitLength(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_greaterThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_greaterEqualThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_lessThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_equal(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_lessEqualThan(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_add(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_mul(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_sub(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_div(Assembler* assembler) {
  return;
}


// Left is double right is integer (Bigint, Mint or Smi)
void Intrinsifier::Double_mulFromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_fromInteger(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  return;
}


void Intrinsifier::Double_toInt(Assembler* assembler) {
  return;
}


void Intrinsifier::Math_sqrt(Assembler* assembler) {
  return;
}


//    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//    _state[kSTATE_LO] = state & _MASK_32;
//    _state[kSTATE_HI] = state >> 32;
void Intrinsifier::Random_nextState(Assembler* assembler) {
  return;
}


void Intrinsifier::Object_equal(Assembler* assembler) {
  return;
}


void Intrinsifier::String_getHashCode(Assembler* assembler) {
  return;
}


void Intrinsifier::String_getLength(Assembler* assembler) {
  return;
}


void Intrinsifier::String_codeUnitAt(Assembler* assembler) {
  return;
}


void Intrinsifier::String_getIsEmpty(Assembler* assembler) {
  return;
}


void Intrinsifier::OneByteString_getHashCode(Assembler* assembler) {
  return;
}


// Arg0: OneByteString (receiver).
// Arg1: Start index as Smi.
// Arg2: End index as Smi.
// The indexes must be valid.
void Intrinsifier::OneByteString_substringUnchecked(Assembler* assembler) {
  return;
}


void Intrinsifier::OneByteString_setAt(Assembler* assembler) {
  return;
}


void Intrinsifier::OneByteString_allocate(Assembler* assembler) {
  return;
}


// TODO(srdjan): Add combinations (one-byte/two-byte/external strings).
void StringEquality(Assembler* assembler, intptr_t string_cid) {
  return;
}


void Intrinsifier::OneByteString_equality(Assembler* assembler) {
  return;
}


void Intrinsifier::TwoByteString_equality(Assembler* assembler) {
  return;
}


void Intrinsifier::UserTag_makeCurrent(Assembler* assembler) {
  return;
}


void Intrinsifier::Profiler_getCurrentTag(Assembler* assembler) {
  return;
}


void Intrinsifier::Profiler_clearCurrentTag(Assembler* assembler) {
  return;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
