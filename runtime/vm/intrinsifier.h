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
  V(_Smi, ~, Smi_bitNegate, 105519892)                                         \
  V(_Smi, get:bitLength, Smi_bitLength, 869956497)                             \
  V(_Double, >, Double_greaterThan, 381325711)                                 \
  V(_Double, >=, Double_greaterEqualThan, 1409267140)                          \
  V(_Double, <, Double_lessThan, 2080387973)                                   \
  V(_Double, <=, Double_lessEqualThan, 106225572)                              \
  V(_Double, ==, Double_equal, 2093918133)                                     \
  V(_Double, +, Double_add, 1646350451)                                        \
  V(_Double, -, Double_sub, 1477459276)                                        \
  V(_Double, *, Double_mul, 1334580777)                                        \
  V(_Double, /, Double_div, 1938037155)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 843050033)                            \
  V(_Double, get:isNegative, Double_getIsNegative, 1637875580)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 1594796483)               \
  V(_Double, .fromInteger, Double_fromInteger, 999771940)                      \
  V(_List, get:length, Array_getLength, 1181352729)                            \
  V(_List, [], Array_getIndexed, 795612476)                                    \
  V(_List, []=, Array_setIndexed, 1288827575)                                  \
  V(_GrowableList, .withData, GrowableList_Allocate, 732923072)                \
  V(_GrowableList, get:length, GrowableList_getLength, 778505107)              \
  V(_GrowableList, get:_capacity, GrowableList_getCapacity, 555140075)         \
  V(_GrowableList, [], GrowableList_getIndexed, 919108233)                     \
  V(_GrowableList, []=, GrowableList_setIndexed, 1218649853)                   \
  V(_GrowableList, _setLength, GrowableList_setLength, 89389299)               \
  V(_GrowableList, _setData, GrowableList_setData, 2126927509)                 \
  V(_GrowableList, add, GrowableList_add, 1899133961)                          \
  V(_ImmutableList, [], ImmutableList_getIndexed, 1990177341)                  \
  V(_ImmutableList, get:length, ImmutableList_getLength, 274917727)            \
  V(Object, ==, Object_equal, 1068471689)                                      \
  V(_StringBase, get:hashCode, String_getHashCode, 2102906241)                 \
  V(_StringBase, get:isEmpty, String_getIsEmpty, 49873871)                     \
  V(_StringBase, get:length, String_getLength, 784399628)                      \
  V(_StringBase, codeUnitAt, String_codeUnitAt, 397735324)                     \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 1111837929)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
      OneByteString_substringUnchecked, 1527498975)                            \
  V(_OneByteString, _setAt, OneByteString_setAt, 468605749)                    \
  V(_OneByteString, _allocate, OneByteString_allocate, 2035417022)             \
  V(_OneByteString, ==, OneByteString_equality, 1727047023)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 951149689)                     \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    438687793)                                                                 \
  V(_IntegerImplementation, +, Integer_add, 837070328)                         \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    562800077)                                                                 \
  V(_IntegerImplementation, -, Integer_sub, 1904782019)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    67891834)                                                                  \
  V(_IntegerImplementation, *, Integer_mul, 1012952097)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    93478264)                                                                  \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 724644222)                \
  V(_IntegerImplementation, unary-, Integer_negate, 2095203689)                \
  V(_IntegerImplementation, _bitAndFromInteger,                                \
    Integer_bitAndFromInteger, 504496713)                                      \
  V(_IntegerImplementation, &, Integer_bitAnd, 347192674)                      \
  V(_IntegerImplementation, _bitOrFromInteger,                                 \
    Integer_bitOrFromInteger, 1763728073)                                      \
  V(_IntegerImplementation, |, Integer_bitOr, 1293445202)                      \
  V(_IntegerImplementation, _bitXorFromInteger,                                \
    Integer_bitXorFromInteger, 281425907)                                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 2139935734)                     \
  V(_IntegerImplementation,                                                    \
    _greaterThanFromInteger,                                                   \
    Integer_greaterThanFromInt, 787426822)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 123961041)                 \
  V(_IntegerImplementation, ==, Integer_equal, 1423724294)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    1790821042)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 425560117)                    \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 1512735828)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 668293748)           \
  V(_IntegerImplementation, <<, Integer_shl, 34265041)                         \
  V(_IntegerImplementation, >>, Integer_sar, 1797129864)                       \
  V(_Double, toInt, Double_toInt, 1547535151)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, Math_sqrt, 101545548)                                            \
  V(_Random, _nextState, Random_nextState, 55890711)                           \


#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(_TypedList, get:length, TypedData_getLength, 522565357)                    \
  V(_Int8Array, _new, TypedData_Int8Array_new, 1150131819)                     \
  V(_Uint8Array, _new, TypedData_Uint8Array_new, 2019665760)                   \
  V(_Uint8ClampedArray, _new, TypedData_Uint8ClampedArray_new, 726412668)      \
  V(_Int16Array, _new, TypedData_Int16Array_new, 1879541015)                   \
  V(_Uint16Array, _new, TypedData_Uint16Array_new, 189496401)                  \
  V(_Int32Array, _new, TypedData_Int32Array_new, 1725327048)                   \
  V(_Uint32Array, _new, TypedData_Uint32Array_new, 10306485)                   \
  V(_Int64Array, _new, TypedData_Int64Array_new, 1299501918)                   \
  V(_Uint64Array, _new, TypedData_Uint64Array_new, 1635318703)                 \
  V(_Float32Array, _new, TypedData_Float32Array_new, 577737480)                \
  V(_Float64Array, _new, TypedData_Float64Array_new, 645355686)                \
  V(_Float32x4Array, _new, TypedData_Float32x4Array_new, 596639418)            \
  V(_Int32x4Array, _new, TypedData_Int32x4Array_new, 496358233)                \
  V(_Float64x2Array, _new, TypedData_Float64x2Array_new, 1506975080)           \
  V(_Int8Array, ., TypedData_Int8Array_factory, 1499010120)                    \
  V(_Uint8Array, ., TypedData_Uint8Array_factory, 354210806)                   \
  V(_Uint8ClampedArray, ., TypedData_Uint8ClampedArray_factory, 231626935)     \
  V(_Int16Array, ., TypedData_Int16Array_factory, 1044203454)                  \
  V(_Uint16Array, ., TypedData_Uint16Array_factory, 616427808)                 \
  V(_Int32Array, ., TypedData_Int32Array_factory, 26656923)                    \
  V(_Uint32Array, ., TypedData_Uint32Array_factory, 297463966)                 \
  V(_Int64Array, ., TypedData_Int64Array_factory, 105050331)                   \
  V(_Uint64Array, ., TypedData_Uint64Array_factory, 1469861670)                \
  V(_Float32Array, ., TypedData_Float32Array_factory, 105860920)               \
  V(_Float64Array, ., TypedData_Float64Array_factory, 342242776)               \
  V(_Float32x4Array, ., TypedData_Float32x4Array_factory, 1217848993)          \
  V(_Int32x4Array, ., TypedData_Int32x4Array_factory, 100825417)               \
  V(_Float64x2Array, ., TypedData_Float64x2Array_factory, 611308575)           \
  V(_Uint8Array, [], Uint8Array_getIndexed, 16125140)                          \
  V(_ExternalUint8Array, [], ExternalUint8Array_getIndexed, 1678777951)        \


#define PROFILER_LIB_INTRINSIC_LIST(V)                                         \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 370414636)                     \
  V(::, _getDefaultTag, UserTag_defaultTag, 1159885970)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 1182126114)                    \

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
  PROFILER_LIB_INTRINSIC_LIST(DECLARE_FUNCTION)

#undef DECLARE_FUNCTION
};

}  // namespace dart

#endif  // VM_INTRINSIFIER_H_
