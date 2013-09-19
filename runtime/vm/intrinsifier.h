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
  V(_Smi, ~, Smi_bitNegate, 664307604)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 383387665)                             \
  V(_Double, >, Double_greaterThan, 30544878)                                  \
  V(_Double, >=, Double_greaterEqualThan, 2121667821)                          \
  V(_Double, <, Double_lessThan, 1108157428)                                   \
  V(_Double, <=, Double_lessEqualThan, 818626253)                              \
  V(_Double, ==, Double_equal, 1070770955)                                     \
  V(_Double, +, Double_add, 1452669769)                                        \
  V(_Double, -, Double_sub, 189430030)                                         \
  V(_Double, *, Double_mul, 1009295597)                                        \
  V(_Double, /, Double_div, 913321995)                                         \
  V(_Double, get:isNaN, Double_getIsNaN, 916536531)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1711362078)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1084302993)               \
  V(_Double, .fromInteger, Double_fromInteger, 278928239)                      \
  V(_ObjectArray, ., ObjectArray_Allocate, 670697167)                          \
  V(_ObjectArray, get:length, Array_getLength, 259352904)                      \
  V(_ObjectArray, [], Array_getIndexed, 948693632)                             \
  V(_ObjectArray, []=, Array_setIndexed, 1972174650)                           \
  V(_GrowableObjectArray, .withData, GrowableArray_Allocate, 816479366)        \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 1160387405)     \
  V(_GrowableObjectArray, get:_capacity, GrowableArray_getCapacity, 1509811779)\
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 1355986080)            \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 887241511)            \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 1517447865)     \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 1979105687)         \
  V(_GrowableObjectArray, add, GrowableArray_add, 2112847740)                  \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 1750060378)                \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 1341972207)         \
  V(Object, ==, Object_equal, 806929805)                                       \
  V(_StringBase, get:hashCode, String_getHashCode, 654513237)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 160230109)                    \
  V(_StringBase, get:length, String_getLength, 1483490272)                     \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 1958436584)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1236434225)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 25652388)                              \
  V(_OneByteString, _setAt, OneByteString_setAt, 2105360073)                   \
  V(_OneByteString, _allocate, OneByteString_allocate, 1404038896)             \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    740884607)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 1817419856)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    584777821)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 835680221)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    1757603756)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 890836061)                         \
  V(_IntegerImplementation, remainder, Integer_remainder, 1735980657)          \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    1398988805)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1219779912)               \
  V(_IntegerImplementation, unary-, Integer_negate, 536858161)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 512285096)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 633030719)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 333543947)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 18012114)                        \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 1746295953)                                     \
  V(_IntegerImplementation, ^, Integer_bitXor, 1066397650)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 1883218996)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 1298422036)                \
  V(_IntegerImplementation, ==, Integer_equal, 19900075)                       \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    111745915)                                                                 \
  V(_IntegerImplementation, <, Integer_lessThan, 1263700530)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1373472523)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 529030443)           \
  V(_IntegerImplementation, <<, Integer_shl, 463484145)                        \
  V(_IntegerImplementation, >>, Integer_sar, 742235434)                        \
  V(_Double, toInt, Double_toInt, 1328149975)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 465520247)                                            \
  V(::, sin, Math_sin, 730107143)                                              \
  V(::, cos, Math_cos, 1282146521)                                             \
  V(_Random, _nextState, Random_nextState, 1117043120)                         \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_TypedList, get:length, TypedData_getLength, 26586537)                     \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1485775480)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 1438013153)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 228724812)      \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1890311047)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 721486208)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 1671532553)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 261400574)                  \
  V(_Int64Array, _new, TypedData_Int64Array_new, 342637584)                    \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 48065680)                   \
  V(_Float32Array, _new, TypedData_Float32Array_new, 1591154149)               \
  V(_Float64Array, _new, TypedData_Float64Array_new, 1779390613)               \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 95272430)             \
  V(_Int8Array, ., TypedData_Int8Array_factory, 1075524700)                    \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 1510844786)                  \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 2147377816)    \
  V(_Int16Array, ., TypedData_Int16Array_factory, 830476131)                   \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 1010530416)                \
  V(_Int32Array, ., TypedData_Int32Array_factory, 258676028)                   \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 193757506)                 \
  V(_Int64Array, ., TypedData_Int64Array_factory, 1488296973)                  \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1296886535)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 103308215)               \
  V(_Float64Array, ., TypedData_Float64Array_factory, 2128626244)              \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1409523113)          \

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
