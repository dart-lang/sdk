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
  V(_Smi, ~, Smi_bitNegate, 721565906)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 383447247)                             \
  V(_Double, >, Double_greaterThan, 196653614)                                 \
  V(_Double, >=, Double_greaterEqualThan, 1420124977)                          \
  V(_Double, <, Double_lessThan, 1368169970)                                   \
  V(_Double, <=, Double_lessEqualThan, 117083409)                              \
  V(_Double, ==, Double_equal, 617620743)                                      \
  V(_Double, +, Double_add, 1618778505)                                        \
  V(_Double, -, Double_sub, 355538766)                                         \
  V(_Double, *, Double_mul, 1175404333)                                        \
  V(_Double, /, Double_div, 1079430731)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 916596113)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1711421660)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1392340623)               \
  V(_Double, .fromInteger, Double_fromInteger, 2033384877)                     \
  V(_List, ., List_Allocate, 176587978)                                        \
  V(_List, get:length, Array_getLength, 215183186)                             \
  V(_List, [], Array_getIndexed, 675155875)                                    \
  V(_List, []=, Array_setIndexed, 1228569706)                                  \
  V(_GrowableList, .withData, GrowableList_Allocate, 264792196)                \
  V(_GrowableList, get:length, GrowableList_getLength, 1654255033)             \
  V(_GrowableList, get:_capacity, GrowableList_getCapacity, 817119794)         \
  V(_GrowableList, [], GrowableList_getIndexed, 1282104248)                    \
  V(_GrowableList, []=, GrowableList_setIndexed, 807019110)                    \
  V(_GrowableList, _setLength, GrowableList_setLength, 823005129)              \
  V(_GrowableList, _setData, GrowableList_setData, 970836644)                  \
  V(_GrowableList, add, GrowableList_add, 1667349856)                          \
  V(_ImmutableList, [], ImmutableList_getIndexed, 1768793932)                  \
  V(_ImmutableList, get:length, ImmutableList_getLength, 578762861)            \
  V(Object, ==, Object_equal, 1068471689)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 654572819)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 1599468763)                   \
  V(_StringBase, get:length, String_getLength, 1483549854)                     \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 1958436584)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1236493807)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 25652388)                              \
  V(_OneByteString, _setAt, OneByteString_setAt, 658941003)                    \
  V(_OneByteString, _allocate, OneByteString_allocate, 2084097266)             \
  V(_OneByteString, ==, OneByteString_equality, 1194175975)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 1746891238)                    \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    740884607)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 1875695122)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    584777821)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 893955487)                         \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    1757603756)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 949111327)                         \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    1398988805)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 1011141318)               \
  V(_IntegerImplementation, unary-, Integer_negate, 145678255)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 512285096)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 691305985)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 333543947)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 76287380)                        \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 1746295953)                                     \
  V(_IntegerImplementation, ^, Integer_bitXor, 1124672916)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 1883218996)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 1356697302)                \
  V(_IntegerImplementation, ==, Integer_equal, 1631095021)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    111745915)                                                                 \
  V(_IntegerImplementation, <, Integer_lessThan, 1523713072)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 671929679)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 1974971247)          \
  V(_IntegerImplementation, <<, Integer_shl, 521759411)                        \
  V(_IntegerImplementation, >>, Integer_sar, 800510700)                        \
  V(_Double, toInt, Double_toInt, 1328149975)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 465520247)                                            \
  V(_Random, _nextState, Random_nextState, 1174301422)                         \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_TypedList, get:length, TypedData_getLength, 26646119)                     \
  V(_Int8Array, _new, TypedData_Int8Array_new, 18350202)                       \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 2118071523)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 908783182)      \
  V(_Int16Array, _new, TypedData_Int16Array_new, 422885769)                    \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 1401544578)                 \
  V(_Int32Array, _new, TypedData_Int32Array_new, 204107275)                    \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 941458944)                  \
  V(_Int64Array, _new, TypedData_Int64Array_new, 1022695954)                   \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 728124050)                  \
  V(_Float32Array, _new, TypedData_Float32Array_new, 123728871)                \
  V(_Float64Array, _new, TypedData_Float64Array_new, 311965335)                \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 775330800)            \
  V(_Int32x4Array, _new, TypedData_Int32x4Array_new, 2074077580)               \
  V(_Float64x2Array, _new, TypedData_Float64x2Array_new, 1540328543)           \
  V(_Int8Array, ., TypedData_Int8Array_factory, 545976988)                     \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 981297074)                   \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 1617830104)    \
  V(_Int16Array, ., TypedData_Int16Array_factory, 300928419)                   \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 480982704)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 1876611964)                  \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 1811693442)                \
  V(_Int64Array, ., TypedData_Int64Array_factory, 958749261)                   \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 767338823)                 \
  V(_Float32Array, ., TypedData_Float32Array_factory, 1721244151)              \
  V(_Float64Array, ., TypedData_Float64Array_factory, 1599078532)              \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 879975401)           \
  V(_Int32x4Array, ., TypedData_Int32x4Array_factory, 924582681)               \
  V(_Float64x2Array, ., TypedData_Float64x2Array_factory, 1654170890)          \


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
