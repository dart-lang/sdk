// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#ifndef VM_INTRINSIFIER_H_
#define VM_INTRINSIFIER_H_

#include "vm/allocation.h"

namespace dart {

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
//
// When adding a new function for intrinsification add a 0 as fingerprint,
// build and run to get the correct fingerprint from the mismatch error.
#define INTRINSIC_LIST(V)                                                      \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger, 726019207)\
  V(_IntegerImplementation, +, Integer_add, 1821133110)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 726019207)\
  V(_IntegerImplementation, -, Integer_sub, 2091907336)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger, 726019207)\
  V(_IntegerImplementation, *, Integer_mul, 146702919)                         \
  V(_IntegerImplementation, %, Integer_modulo, 578878541)                      \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1806780482)               \
  V(_IntegerImplementation, unary-, Integer_negate, 1705538272)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 726019207)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 927461461)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 726019207)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 2056857508)                      \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 726019207)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 837002595)                      \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 79222670)                                      \
  V(_IntegerImplementation, >, Integer_greaterThan, 2126978373)                \
  V(_IntegerImplementation, ==, Integer_equal, 507939054)                      \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, 79222670) \
  V(_IntegerImplementation, <, Integer_lessThan, 1277579871)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 806519877)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 807443398)           \
  V(_IntegerImplementation, <<, Integer_shl, 1246348641)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1937635847)                       \
  V(_Smi, ~, Smi_bitNegate, 882629793)                                         \
  V(_Double, >, Double_greaterThan, 1471126121)                                \
  V(_Double, >=, Double_greaterEqualThan, 1664965640)                          \
  V(_Double, <, Double_lessThan, 148927649)                                    \
  V(_Double, <=, Double_lessEqualThan, 1664042119)                             \
  V(_Double, ==, Double_equal, 900686217)                                      \
  V(_Double, +, Double_add, 786489945)                                         \
  V(_Double, -, Double_sub, 1074937651)                                        \
  V(_Double, *, Double_mul, 1515140403)                                        \
  V(_Double, /, Double_div, 1481616340)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 54462366)                             \
  V(_Double, get:isNegative, Double_getIsNegative, 54462366)                   \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1668662807)               \
  V(_Double, .fromInteger, Double_fromInteger, 842078193)                      \
  V(_Double, toInt, Double_toInt, 362666636)                                   \
  V(_ObjectArray, ., ObjectArray_Allocate, 577949617)                          \
  V(_ObjectArray, get:length, Array_getLength, 405297088)                      \
  V(_ObjectArray, [], Array_getIndexed, 71937385)                              \
  V(_ObjectArray, []=, Array_setIndexed, 255863719)                            \
  V(_GrowableObjectArray, .fromObjectArray, GArray_Allocate, 989879928)        \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 725548050)      \
  V(_GrowableObjectArray, get:capacity, GrowableArray_getCapacity, 725548050)  \
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 581838973)             \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 1048007636)           \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 796709584)      \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 477312179)          \
  V(_GrowableObjectArray, add, GrowableArray_add, 455936651)                   \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 486821199)                 \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 433698233)          \
  V(::, sqrt, Math_sqrt, 2232519)                                              \
  V(::, sin, Math_sin, 837187616)                                              \
  V(::, cos, Math_cos, 548880317)                                              \
  V(Object, ==, Object_equal, 1511145014)                                      \
  V(_FixedSizeArrayIterator, get:hasNext,                                      \
    FixedSizeArrayIterator_getHasNext, 1819226215)                             \
  V(_FixedSizeArrayIterator, next, FixedSizeArrayIterator_next, 1147008464)    \
  V(_StringBase, get:hashCode, String_getHashCode, 320803993)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 583130725)                    \
  V(_StringBase, get:length, String_getLength, 320803993)                      \
  V(_StringBase, charCodeAt, String_charCodeAt, 984449525)                     \
  V(_ByteArrayBase, get:length, ByteArrayBase_getLength, 1828280001)           \
  V(_Int8Array, [], Int8Array_getIndexed, 1499790324)                          \
  V(_Int8Array, []=, Int8Array_setIndexed, 1469038436)                         \
  V(_Uint8Array, [], Uint8Array_getIndexed, 748420218)                         \
  V(_Uint8Array, []=, Uint8Array_setIndexed, 1619321522)                       \
  V(_Int16Array, [], Int16Array_getIndexed, 1203257976)                        \
  V(_Uint16Array, [], Uint16Array_getIndexed, 1549909675)                      \
  V(_Int32Array, [], Int32Array_getIndexed, 1849422378)                        \
  V(_Uint32Array, [], Uint32Array_getIndexed, 586613266)                       \
  V(_Int64Array, [], Int64Array_getIndexed, 619332438)                         \
  V(_Uint64Array, [], Uint64Array_getIndexed, 969448467)                       \
  V(_Float32Array, [], Float32Array_getIndexed, 280103602)                     \
  V(_Float32Array, []=, Float32Array_setIndexed, 1270729544)                   \
  V(_Float64Array, [], Float64Array_getIndexed, 476393480)                     \
  V(_Float64Array, []=, Float64Array_setIndexed, 283625119)                    \
  V(_ExternalUint8Array, [], ExternalUint8Array_getIndexed, 1892679907)        \

// Forward declarations.
class Assembler;
class Function;

class Intrinsifier : public AllStatic {
 public:
  // Try to intrinsify 'function'. Returns true if the function intrinsified
  // completely and the code does not need to be generated (i.e., no slow
  // path possible).
  static bool Intrinsify(const Function& function, Assembler* assembler);
  static bool CanIntrinsify(const Function& function);

 private:
#define DECLARE_FUNCTION(test_class_name, test_function_name, destination, fp) \
  static bool destination(Assembler* assembler);

INTRINSIC_LIST(DECLARE_FUNCTION)
#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
