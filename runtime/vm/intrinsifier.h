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
  V(_IntegerImplementation, +, Integer_add, 959303888)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 726019207)\
  V(_IntegerImplementation, -, Integer_sub, 483122878)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger, 726019207)\
  V(_IntegerImplementation, *, Integer_mul, 1043837343)                        \
  V(_IntegerImplementation, %, Integer_modulo, 2027609817)                     \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 958840900)                \
  V(_IntegerImplementation, unary-, Integer_negate, 678480358)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 726019207)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 1692486097)                     \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 726019207)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 66350242)                        \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 726019207)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 1620294403)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 79222670)                                      \
  V(_IntegerImplementation, >, Integer_greaterThan, 1800453857)                \
  V(_IntegerImplementation, ==, Integer_equal, 1540405784)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, 79222670) \
  V(_IntegerImplementation, <, Integer_lessThan, 1426685575)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1065121761)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1065151552)          \
  V(_IntegerImplementation, <<, Integer_shl, 386573125)                        \
  V(_IntegerImplementation, >>, Integer_sar, 1170883039)                       \
  V(_Smi, ~, Smi_bitNegate, 882629793)                                         \
  V(_Double, >, Double_greaterThan, 2056391997)                                \
  V(_Double, >=, Double_greaterEqualThan, 1300634558)                          \
  V(_Double, <, Double_lessThan, 1598098437)                                   \
  V(_Double, <=, Double_lessEqualThan, 1300604767)                             \
  V(_Double, ==, Double_equal, 1206706717)                                     \
  V(_Double, +, Double_add, 1965033293)                                        \
  V(_Double, -, Double_sub, 1212327731)                                        \
  V(_Double, *, Double_mul, 395243827)                                         \
  V(_Double, /, Double_div, 809804402)                                         \
  V(_Double, get:isNaN, Double_getIsNaN, 54462366)                             \
  V(_Double, get:isNegative, Double_getIsNegative, 54462366)                   \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 815838159)                \
  V(_Double, .fromInteger, Double_fromInteger, 842078193)                      \
  V(_Double, toInt, Double_toInt, 362666636)                                   \
  V(_ObjectArray, ., ObjectArray_Allocate, 577949617)                          \
  V(_ObjectArray, get:length, Array_getLength, 405297088)                      \
  V(_ObjectArray, [], Array_getIndexed, 71937385)                              \
  V(_ObjectArray, []=, Array_setIndexed, 255863719)                            \
  V(_GrowableObjectArray, .withData, GArray_Allocate, 989879928)               \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 725548050)      \
  V(_GrowableObjectArray, get:_capacity, GrowableArray_getCapacity, 725548050) \
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 581838973)             \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 1048007636)           \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 796709584)      \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 477312179)          \
  V(_GrowableObjectArray, add, GrowableArray_add, 1367698386)                  \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 486821199)                 \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 433698233)          \
  V(::, sqrt, Math_sqrt, 1662640002)                                           \
  V(::, sin, Math_sin, 1273932041)                                             \
  V(::, cos, Math_cos, 1749547468)                                             \
  V(Object, ==, Object_equal, 2126956595)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 320803993)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 711547329)                    \
  V(_StringBase, get:length, String_getLength, 320803993)                      \
  V(_StringBase, charCodeAt, String_charCodeAt, 984449525)                     \
  V(_ByteArrayBase, get:length, ByteArrayBase_getLength, 1098081765)           \
  V(_Int8Array, [], Int8Array_getIndexed, 1295306322)                          \
  V(_Int8Array, []=, Int8Array_setIndexed, 1709956322)                         \
  V(_Int8Array, _new, Int8Array_new, 535958453)                                \
  V(_Uint8Array, [], Uint8Array_getIndexed, 578331916)                         \
  V(_Uint8Array, []=, Uint8Array_setIndexed, 121509844)                        \
  V(_Uint8Array, _new, Uint8Array_new, 604355565)                              \
  V(_Uint8ClampedArray, [], UintClamped8Array_getIndexed, 327062422)           \
  V(_Uint8ClampedArray, []=, Uint8ClampedArray_setIndexed, 2054663547)         \
  V(_Uint8ClampedArray, _new, Uint8ClampedArray_new, 1070949952)               \
  V(_Int16Array, [], Int16Array_getIndexed, 870098766)                         \
  V(_Int16Array, _new, Int16Array_new, 903723993)                              \
  V(_Uint16Array, [], Uint16Array_getIndexed, 1019828411)                      \
  V(_Uint16Array, []=, Uint16Array_setIndexed, 1457955615)                     \
  V(_Uint16Array, _new, Uint16Array_new, 133542762)                            \
  V(_Int32Array, [], Int32Array_getIndexed, 1999321436)                        \
  V(_Int32Array, _new, Int32Array_new, 8218286)                                \
  V(_Uint32Array, [], Uint32Array_getIndexed, 1750764660)                      \
  V(_Uint32Array, _new, Uint32Array_new, 469402161)                            \
  V(_Int64Array, [], Int64Array_getIndexed, 504894128)                         \
  V(_Int64Array, _new, Int64Array_new, 60605075)                               \
  V(_Uint64Array, [], Uint64Array_getIndexed, 31272531)                        \
  V(_Uint64Array, _new, Uint64Array_new, 624354107)                            \
  V(_Float32Array, [], Float32Array_getIndexed, 147582932)                     \
  V(_Float32Array, []=, Float32Array_setIndexed, 664454270)                    \
  V(_Float32Array, _new, Float32Array_new, 109944959)                          \
  V(_Float64Array, [], Float64Array_getIndexed, 638830526)                     \
  V(_Float64Array, []=, Float64Array_setIndexed, 1948811847)                   \
  V(_Float64Array, _new, Float64Array_new, 147668392)                          \
  V(_ExternalUint8Array, [], ExternalUint8Array_getIndexed, 753790851)         \

// TODO(srdjan): Implement _FixedSizeArrayIterator, get:current and
//   _FixedSizeArrayIterator, moveNext.

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
