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
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 692936755)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 383417456)                             \
  V(_Double, >, Double_greaterThan, 1187341070)                                \
  V(_Double, >=, Double_greaterEqualThan, 1770896399)                          \
  V(_Double, <, Double_lessThan, 1238163699)                                   \
  V(_Double, <=, Double_lessEqualThan, 467854831)                              \
  V(_Double, ==, Double_equal, 1917937673)                                     \
  V(_Double, +, Double_add, 461982313)                                         \
  V(_Double, -, Double_sub, 1346226222)                                        \
  V(_Double, *, Double_mul, 18608141)                                          \
  V(_Double, /, Double_div, 2070118187)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 916566322)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1711391869)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1238321808)               \
  V(_Double, .fromInteger, Double_fromInteger, 82414734)                       \
  V(_ObjectArray, ., ObjectArray_Allocate, 1558200848)                         \
  V(_ObjectArray, get:length, Array_getLength, 259382695)                      \
  V(_ObjectArray, [], Array_getIndexed, 544020319)                             \
  V(_ObjectArray, []=, Array_setIndexed, 304306010)                            \
  V(_GrowableObjectArray, .withData, GrowableArray_Allocate, 619965861)        \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 1160417196)     \
  V(_GrowableObjectArray, get:_capacity, GrowableArray_getCapacity, 1509841570)\
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 951312767)             \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 1366856519)           \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 1112774552)     \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 1574432374)         \
  V(_GrowableObjectArray, add, GrowableArray_add, 635801182)                   \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 1345387065)                \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 1342001998)         \
  V(Object, ==, Object_equal, 936042315)                                       \
  V(_StringBase, get:hashCode, String_getHashCode, 654543028)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 879849436)                    \
  V(_StringBase, get:length, String_getLength, 1483520063)                     \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 1958436584)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1236464016)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 25652388)                              \
  V(_OneByteString, _setAt, OneByteString_setAt, 308408714)                    \
  V(_OneByteString, _allocate, OneByteString_allocate, 1744068081)             \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    740884607)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 772815665)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    584777821)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 1938559678)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    1757603756)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 1993715518)                        \
  V(_IntegerImplementation, remainder, Integer_remainder, 1331308305)          \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    1398988805)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 41718791)                 \
  V(_IntegerImplementation, unary-, Integer_negate, 341268208)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 512285096)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 1735910176)                     \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 333543947)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 1120891571)                      \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 1746295953)                                     \
  V(_IntegerImplementation, ^, Integer_bitXor, 21793459)                       \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 1883218996)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 253817845)                 \
  V(_IntegerImplementation, ==, Integer_equal, 1899239372)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    111745915)                                                                 \
  V(_IntegerImplementation, <, Integer_lessThan, 1393706801)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1022701101)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 178259021)           \
  V(_IntegerImplementation, <<, Integer_shl, 1566363602)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1845114891)                       \
  V(_Double, toInt, Double_toInt, 1328149975)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 465520247)                                            \
  V(::, sin, Math_sin, 730107143)                                              \
  V(::, cos, Math_cos, 1282146521)                                             \
  V(_Random, _nextState, Random_nextState, 1145672271)                         \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_TypedList, get:length, TypedData_getLength, 26616328)                     \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1825804665)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 1778042338)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 568753997)      \
  V(_Int16Array, _new, TypedData_Int16Array_new, 82856584)                     \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 1061515393)                 \
  V(_Int32Array, _new, TypedData_Int32Array_new, 2011561738)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 601429759)                  \
  V(_Int64Array, _new, TypedData_Int64Array_new, 682666769)                    \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 388094865)                  \
  V(_Float32Array, _new, TypedData_Float32Array_new, 1931183334)               \
  V(_Float64Array, _new, TypedData_Float64Array_new, 2119419798)               \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 435301615)            \
  V(_Int8Array, ., TypedData_Int8Array_factory, 810750844)                     \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 1246070930)                  \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 1882603960)    \
  V(_Int16Array, ., TypedData_Int16Array_factory, 565702275)                   \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 745756560)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 2141385820)                  \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 2076467298)                \
  V(_Int64Array, ., TypedData_Int64Array_factory, 1223523117)                  \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1032112679)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 1986018007)              \
  V(_Float64Array, ., TypedData_Float64Array_factory, 1863852388)              \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1144749257)          \

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
  static void Intrinsify(const Function& function, Assembler* assembler);
  static bool CanIntrinsify(const Function& function);
  static void InitializeState();

 private:
#define DECLARE_FUNCTION(test_class_name, test_function_name, destination, fp) \
  static void destination(Assembler* assembler);

  CORE_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)
  CORE_INTEGER_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)
  MATH_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)
  TYPED_DATA_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
