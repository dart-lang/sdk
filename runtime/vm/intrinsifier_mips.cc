// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/intrinsifier.h"

namespace dart {

bool Intrinsifier::ObjectArray_Allocate(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Array_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::ImmutableArray_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::ImmutableArray_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GArray_Allocate(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_getCapacity(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_setLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_setData(Assembler* assembler) {
  return false;
}


bool Intrinsifier::GrowableArray_add(Assembler* assembler) {
  return false;
}


bool Intrinsifier::ByteArrayBase_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int8Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int8Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int8Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint8Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint8Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint8Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::UintClamped8Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint8ClampedArray_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint8ClampedArray_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int16Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int16Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint16Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint16Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint16Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int32Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int32Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint32Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint32Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int64Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Int64Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint64Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Uint64Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float32Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float32Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float32Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float64Array_getIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float64Array_setIndexed(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Float64Array_new(Assembler* assembler) {
  return false;
}


bool Intrinsifier::ExternalUint8Array_getIndexed(Assembler* assembler) {
  return false;
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


bool Intrinsifier::Integer_greaterThanFromInt(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Integer_lessThan(Assembler* assembler) {
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


bool Intrinsifier::Double_getIsNaN(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_getIsNegative(Assembler* assembler) {
  return false;
}


bool Intrinsifier::Double_toInt(Assembler* assembler) {
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


bool Intrinsifier::String_getHashCode(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_getLength(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_charCodeAt(Assembler* assembler) {
  return false;
}


bool Intrinsifier::String_getIsEmpty(Assembler* assembler) {
  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
