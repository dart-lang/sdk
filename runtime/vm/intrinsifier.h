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
  V(_Smi, ~, Smi_bitNegate, 635678453)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 383357874)                             \
  V(_Double, >, Double_greaterThan, 1021232334)                                \
  V(_Double, >=, Double_greaterEqualThan, 324955595)                           \
  V(_Double, <, Double_lessThan, 978151157)                                    \
  V(_Double, <=, Double_lessEqualThan, 1169397675)                             \
  V(_Double, ==, Double_equal, 223604237)                                      \
  V(_Double, +, Double_add, 295873577)                                         \
  V(_Double, -, Double_sub, 1180117486)                                        \
  V(_Double, *, Double_mul, 1999983053)                                        \
  V(_Double, /, Double_div, 1904009451)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 916506740)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1711332287)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 930284178)                \
  V(_Double, .fromInteger, Double_fromInteger, 475441744)                      \
  V(_ObjectArray, ., ObjectArray_Allocate, 1930677134)                         \
  V(_ObjectArray, get:length, Array_getLength, 259323113)                      \
  V(_ObjectArray, [], Array_getIndexed, 93386978)                              \
  V(_ObjectArray, []=, Array_setIndexed, 1296046137)                           \
  V(_GrowableObjectArray, .withData, GrowableArray_Allocate, 1012992871)       \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 1160357614)     \
  V(_GrowableObjectArray, get:_capacity, GrowableArray_getCapacity, 1509781988)\
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 500679426)             \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 211112998)            \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 1922121178)     \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 236295352)          \
  V(_GrowableObjectArray, add, GrowableArray_add, 1442410650)                  \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 894753724)                 \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 1341942416)         \
  V(Object, ==, Object_equal, 677817295)                                       \
  V(_StringBase, get:hashCode, String_getHashCode, 654483446)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 1588094430)                   \
  V(_StringBase, get:length, String_getLength, 1483460481)                     \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 1958436584)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1236404434)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 25652388)                              \
  V(_OneByteString, _setAt, OneByteString_setAt, 1754827784)                   \
  V(_OneByteString, _allocate, OneByteString_allocate, 1064009711)             \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    740884607)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 714540399)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    584777821)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 1880284412)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    1757603756)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 1935440252)                        \
  V(_IntegerImplementation, remainder, Integer_remainder, 2140653009)          \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    1398988805)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 250357385)                \
  V(_IntegerImplementation, unary-, Integer_negate, 732448114)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 512285096)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 1677634910)                     \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 333543947)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 1062616305)                      \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 1746295953)                                     \
  V(_IntegerImplementation, ^, Integer_bitXor, 2111001841)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 1883218996)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 195542579)                 \
  V(_IntegerImplementation, ==, Integer_equal, 288044426)                      \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    111745915)                                                                 \
  V(_IntegerImplementation, <, Integer_lessThan, 1133694259)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1724243945)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 879801865)           \
  V(_IntegerImplementation, <<, Integer_shl, 1508088336)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1786839625)                       \
  V(_Double, toInt, Double_toInt, 1328149975)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 465520247)                                            \
  V(::, sin, Math_sin, 730107143)                                              \
  V(::, cos, Math_cos, 1282146521)                                             \
  V(_Random, _nextState, Random_nextState, 1088413969)                         \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_TypedList, get:length, TypedData_getLength, 26556746)                     \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1145746295)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 1097983968)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 2036179275)     \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1550281862)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 381457023)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 1331503368)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 2068855037)                 \
  V(_Int64Array, _new, TypedData_Int64Array_new, 2608399)                      \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 1855520143)                 \
  V(_Float32Array, _new, TypedData_Float32Array_new, 1251124964)               \
  V(_Float64Array, _new, TypedData_Float64Array_new, 1439361428)               \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 1902726893)           \
  V(_Int8Array, ., TypedData_Int8Array_factory, 1340298556)                    \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 1775618642)                  \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 264668024)     \
  V(_Int16Array, ., TypedData_Int16Array_factory, 1095249987)                  \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 1275304272)                \
  V(_Int32Array, ., TypedData_Int32Array_factory, 523449884)                   \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 458531362)                 \
  V(_Int64Array, ., TypedData_Int64Array_factory, 1753070829)                  \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1561660391)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 368082071)               \
  V(_Float64Array, ., TypedData_Float64Array_factory, 245916452)               \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1674296969)          \

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
