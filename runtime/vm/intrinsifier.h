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
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger, 726019207)\
  V(_IntegerImplementation, +, Integer_add, 1768648592)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, 726019207)\
  V(_IntegerImplementation, -, Integer_sub, 1292467582)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger, 726019207)\
  V(_IntegerImplementation, *, Integer_mul, 1853182047)                        \
  V(_IntegerImplementation, %, Integer_modulo, 1211518976)                     \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 142750059)                \
  V(_IntegerImplementation, unary-, Integer_negate, 676633254)                 \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 726019207)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 354347153)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 726019207)                                       \
  V(_IntegerImplementation, |, Integer_bitOr, 875694946)                       \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 726019207)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 282155459)                      \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 79222670)                                      \
  V(_IntegerImplementation, >, Integer_greaterThan, 462314913)                 \
  V(_IntegerImplementation, ==, Integer_equal, 1424765465)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, 79222670) \
  V(_IntegerImplementation, <, Integer_lessThan, 1424838471)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 949016155)              \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 949045946)           \
  V(_IntegerImplementation, <<, Integer_shl, 1195917829)                       \
  V(_IntegerImplementation, >>, Integer_sar, 1980227743)                       \
  V(_Smi, ~, Smi_bitNegate, 882629793)                                         \
  V(_Double, >, Double_greaterThan, 301935359)                                 \
  V(_Double, >=, Double_greaterEqualThan, 1184528952)                          \
  V(_Double, <, Double_lessThan, 1596251333)                                   \
  V(_Double, <=, Double_lessEqualThan, 1184499161)                             \
  V(_Double, ==, Double_equal, 1706047712)                                     \
  V(_Double, +, Double_add, 210576655)                                         \
  V(_Double, -, Double_sub, 1605354741)                                        \
  V(_Double, *, Double_mul, 788270837)                                         \
  V(_Double, /, Double_div, 1202831412)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 54462366)                             \
  V(_Double, get:isNegative, Double_getIsNegative, 54462366)                   \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 704314034)                \
  V(_Double, .fromInteger, Double_fromInteger, 842078193)                      \
  V(_Double, toInt, Double_toInt, 362666636)                                   \
  V(_ObjectArray, ., ObjectArray_Allocate, 97987288)                           \
  V(_ObjectArray, get:length, Array_getLength, 405297088)                      \
  V(_ObjectArray, [], Array_getIndexed, 71937385)                              \
  V(_ObjectArray, []=, Array_setIndexed, 255863719)                            \
  V(_GrowableObjectArray, .withData, GrowableArray_Allocate, 816132033)        \
  V(_GrowableObjectArray, get:length, GrowableArray_getLength, 725548050)      \
  V(_GrowableObjectArray, get:_capacity, GrowableArray_getCapacity, 725548050) \
  V(_GrowableObjectArray, [], GrowableArray_getIndexed, 581838973)             \
  V(_GrowableObjectArray, []=, GrowableArray_setIndexed, 1048007636)           \
  V(_GrowableObjectArray, _setLength, GrowableArray_setLength, 796709584)      \
  V(_GrowableObjectArray, _setData, GrowableArray_setData, 629110947)          \
  V(_GrowableObjectArray, add, GrowableArray_add, 1904852879)                  \
  V(_ImmutableArray, [], ImmutableArray_getIndexed, 486821199)                 \
  V(_ImmutableArray, get:length, ImmutableArray_getLength, 433698233)          \
  V(Object, ==, Object_equal, 2126897013)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 320803993)                  \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 1026765313)                   \
  V(_StringBase, get:length, String_getLength, 320803993)                      \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 984449525)                     \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 682660413)        \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 713121438)                             \


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 1662640002)                                           \
  V(::, sin, Math_sin, 1273932041)                                             \
  V(::, cos, Math_cos, 1749547468)                                             \


#define TYPEDDATA_LIB_INTRINSIC_LIST(V)                                        \
  V(_TypedList, get:length, TypedData_getLength, 231908172)                    \
  V(_Int8Array, _new, TypedData_Int8Array_new, 844274443)                      \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 997951645)                    \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 1025045044)     \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1064563368)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 110927177)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 770802406)                    \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 856841876)                  \
  V(_Int64Array, _new, TypedData_Int64Array_new, 941769528)                    \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 977566635)                  \
  V(_Float32Array, _new, TypedData_Float32Array_new, 1053133615)               \
  V(_Float64Array, _new, TypedData_Float64Array_new, 936673303)                \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 212088644)            \
  V(_Int8Array, ., TypedData_Int8Array_factory, 156009974)                     \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 1465460956)                  \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 970170700)     \
  V(_Int16Array, ., TypedData_Int16Array_factory, 1520309224)                  \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 195493071)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 27437702)                    \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 1702451035)                \
  V(_Int64Array, ., TypedData_Int64Array_factory, 225360944)                   \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1730375031)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 563498394)               \
  V(_Float64Array, ., TypedData_Float64Array_factory, 492220296)               \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1845796718)          \

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
  static void InitializeState();

 private:
#define DECLARE_FUNCTION(test_class_name, test_function_name, destination, fp) \
  static bool destination(Assembler* assembler);

  CORE_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)
  MATH_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)
  TYPEDDATA_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
