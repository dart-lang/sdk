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
  V(_IntegerImplementation, +, Integer_add, 13708438)                          \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 726019207)\
  V(_IntegerImplementation, -, Integer_sub, 284482664)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger, 726019207)\
  V(_IntegerImplementation, *, Integer_mul, 486761895)                         \
  V(_IntegerImplementation, %, Integer_modulo, 1370017357)                     \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 450435650)                \
  V(_IntegerImplementation, unary-, Integer_negate, 1734168384)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 726019207)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 1267520437)                     \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 726019207)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 249432836)                       \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 726019207)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 1177061571)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 79222670)                                      \
  V(_IntegerImplementation, >, Integer_greaterThan, 319553701)                 \
  V(_IntegerImplementation, ==, Integer_equal, 1163202222)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, 79222670) \
  V(_IntegerImplementation, <, Integer_lessThan, 1306209983)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 458673122)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 459596643)           \
  V(_IntegerImplementation, <<, Integer_shl, 1586407617)                       \
  V(_IntegerImplementation, >>, Integer_sar, 130211175)                        \
  V(_Smi, ~, Smi_bitNegate, 882629793)                                         \
  V(_Double, >, Double_greaterThan, 1821658410)                                \
  V(_Double, >=, Double_greaterEqualThan, 1317118885)                          \
  V(_Double, <, Double_lessThan, 177557761)                                    \
  V(_Double, <=, Double_lessEqualThan, 1316195364)                             \
  V(_Double, ==, Double_equal, 1896071176)                                     \
  V(_Double, +, Double_add, 1137022234)                                        \
  V(_Double, -, Double_sub, 1425469940)                                        \
  V(_Double, *, Double_mul, 1865672692)                                        \
  V(_Double, /, Double_div, 1832148629)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 54462366)                             \
  V(_Double, get:isNegative, Double_getIsNegative, 54462366)                   \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 795128)                   \
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
  V(_GrowableObjectArray, add, GrowableArray_add, 1776744235)                  \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 486821199)                 \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 433698233)          \
  V(::, sqrt, Math_sqrt, 2232519)                                              \
  V(::, sin, Math_sin, 837187616)                                              \
  V(::, cos, Math_cos, 548880317)                                              \
  V(Object, ==, Object_equal, 1512068535)                                      \
  V(_FixedSizeArrayIterator, get:hasNext,                                      \
    FixedSizeArrayIterator_getHasNext, 1847855366)                             \
  V(_FixedSizeArrayIterator, next, FixedSizeArrayIterator_next, 1739352783)    \
  V(_StringBase, get:hashCode, String_getHashCode, 320803993)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 1065961093)                   \
  V(_StringBase, get:length, String_getLength, 320803993)                      \
  V(_StringBase, charCodeAt, String_charCodeAt, 984449525)                     \
  V(_ByteArrayBase, get:length, ByteArrayBase_getLength, 1856909152)           \
  V(_Int8Array, [], Int8Array_getIndexed, 239810357)                           \
  V(_Int8Array, []=, Int8Array_setIndexed, 1469038436)                         \
  V(_Uint8Array, [], Uint8Array_getIndexed, 1635923899)                        \
  V(_Uint8Array, []=, Uint8Array_setIndexed, 1619321522)                       \
  V(_Int16Array, [], Int16Array_getIndexed, 2090761657)                        \
  V(_Uint16Array, [], Uint16Array_getIndexed, 289929708)                       \
  V(_Int32Array, [], Int32Array_getIndexed, 589442411)                         \
  V(_Uint32Array, [], Uint32Array_getIndexed, 1474116947)                      \
  V(_Int64Array, [], Int64Array_getIndexed, 1506836119)                        \
  V(_Uint64Array, [], Uint64Array_getIndexed, 1856952148)                      \
  V(_Float32Array, [], Float32Array_getIndexed, 1167607283)                    \
  V(_Float32Array, []=, Float32Array_setIndexed, 1270729544)                   \
  V(_Float64Array, [], Float64Array_getIndexed, 1363897161)                    \
  V(_Float64Array, []=, Float64Array_setIndexed, 283625119)                    \
  V(_ExternalUint8Array, [], ExternalUint8Array_getIndexed, 632699940)         \

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
