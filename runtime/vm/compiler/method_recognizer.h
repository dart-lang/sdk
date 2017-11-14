// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_
#define RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/token.h"

namespace dart {

// clang-format off
// (class-name, function-name, recognized enum, result type, fingerprint).
// When adding a new function add a 0 as fingerprint, build and run to get the
// correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, Bool, 0x49c6e96a)                          \
  V(ClassID, getID, ClassIDgetID, Smi, 0x7b18b257)                             \
  V(Object, Object., ObjectConstructor, Dynamic, 0x681617fe)                   \
  V(_List, ., ObjectArrayAllocate, Array, 0x2121902f)                          \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, Smi, 0x7041895a)               \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, Smi, 0x336fa3ea)             \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, Smi, 0x231bbe2e)             \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, Smi, 0x0371785f)           \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, Dynamic, 0x65ab3a20)         \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, Dynamic, 0x0cb0fcf6)       \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, Dynamic, 0x7db75d78)         \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, Double, 0x6674ea6f)      \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, Double, 0x236c6e7a)      \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, Float32x4,           \
    0x5c367ffb)                                                                \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, Int32x4, 0x772d1c0f)     \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, Dynamic, 0x12bae36a)           \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, Dynamic, 0x15821cc9)         \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, Dynamic, 0x1f8237fa)         \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, Dynamic, 0x181e5d16)       \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, Dynamic, 0x7ddb9f87)         \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, Dynamic, 0x74094f8d)       \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, Dynamic, 0x4741396e)         \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, Dynamic, 0x03db087b)     \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, Dynamic, 0x38a80b0d)     \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, Dynamic, 0x40052c4e) \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, Dynamic, 0x07b89f54)     \
  V(_StringBase, _interpolate, StringBaseInterpolate, Dynamic, 0x01ecb15a)     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, Double, 0x05da96ed)     \
  V(_Double, _add, DoubleAdd, Double, 0x2a38277b)                              \
  V(_Double, _sub, DoubleSub, Double, 0x4f466391)                              \
  V(_Double, _mul, DoubleMul, Double, 0x175e4f66)                              \
  V(_Double, _div, DoubleDiv, Double, 0x0854181b)                              \
  V(::, min, MathMin, Dynamic, 0x32ebc57d)                                     \
  V(::, max, MathMax, Dynamic, 0x377e8889)                                     \
  V(::, _doublePow, MathDoublePow, Double, 0x5add0ec1)                         \
  V(Float32x4, Float32x4., Float32x4Constructor, Float32x4, 0x26ea459b)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, Float32x4, 0x16eca604)           \
  V(Float32x4, Float32x4.splat, Float32x4Splat, Float32x4, 0x694e83e3)         \
  V(Float32x4, Float32x4.fromInt32x4Bits, Int32x4ToFloat32x4, Float32x4,       \
    0x2f62ebd3)                                                                \
  V(Float32x4, Float32x4.fromFloat64x2, Float64x2ToFloat32x4, Float32x4,       \
    0x50ed6910)                                                                \
  V(_Float32x4, shuffle, Float32x4Shuffle, Float32x4, 0x7829101f)              \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, Float32x4, 0x4182c06b)        \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, Dynamic, 0x1d08b351)       \
  V(_Float32x4, equal, Float32x4Equal, Int32x4, 0x11adb239)                    \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, Int32x4, 0x48adaf58)        \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, Int32x4,      \
    0x32db94ca)                                                                \
  V(_Float32x4, lessThan, Float32x4LessThan, Int32x4, 0x425b000c)              \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, Int32x4,            \
    0x0278c2f8)                                                                \
  V(_Float32x4, notEqual, Float32x4NotEqual, Int32x4, 0x2987cd26)              \
  V(_Float32x4, min, Float32x4Min, Float32x4, 0x5ed74b6f)                      \
  V(_Float32x4, max, Float32x4Max, Float32x4, 0x68696442)                      \
  V(_Float32x4, scale, Float32x4Scale, Float32x4, 0x704e4122)                  \
  V(_Float32x4, sqrt, Float32x4Sqrt, Float32x4, 0x2c967a6f)                    \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, Float32x4,            \
    0x6264bfe8)                                                                \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, Float32x4, 0x3cd7e819)        \
  V(_Float32x4, unary-, Float32x4Negate, Float32x4, 0x37accb52)                \
  V(_Float32x4, abs, Float32x4Abs, Float32x4, 0x471cdd87)                      \
  V(_Float32x4, clamp, Float32x4Clamp, Float32x4, 0x2cb30492)                  \
  V(_Float32x4, withX, Float32x4WithX, Float32x4, 0x4e336aff)                  \
  V(_Float32x4, withY, Float32x4WithY, Float32x4, 0x0a72b910)                  \
  V(_Float32x4, withZ, Float32x4WithZ, Float32x4, 0x31e93658)                  \
  V(_Float32x4, withW, Float32x4WithW, Float32x4, 0x60ddc105)                  \
  V(Float64x2, Float64x2., Float64x2Constructor, Float64x2, 0x43054b9f)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, Float64x2, 0x4af12f9d)           \
  V(Float64x2, Float64x2.splat, Float64x2Splat, Float64x2, 0x134edef0)         \
  V(Float64x2, Float64x2.fromFloat32x4, Float32x4ToFloat64x2, Float64x2,       \
    0x17d6b5e4)                                                                \
  V(_Float64x2, get:x, Float64x2GetX, Double, 0x58c09c58)                      \
  V(_Float64x2, get:y, Float64x2GetY, Double, 0x3cf5e5b8)                      \
  V(_Float64x2, unary-, Float64x2Negate, Float64x2, 0x415ca009)                \
  V(_Float64x2, abs, Float64x2Abs, Float64x2, 0x031f9e47)                      \
  V(_Float64x2, sqrt, Float64x2Sqrt, Float64x2, 0x77f711dd)                    \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, Dynamic, 0x27deda4b)       \
  V(_Float64x2, scale, Float64x2Scale, Float64x2, 0x26830a61)                  \
  V(_Float64x2, withX, Float64x2WithX, Float64x2, 0x1d2bcaf5)                  \
  V(_Float64x2, withY, Float64x2WithY, Float64x2, 0x383ed6ac)                  \
  V(_Float64x2, min, Float64x2Min, Float64x2, 0x28d7ddf6)                      \
  V(_Float64x2, max, Float64x2Max, Float64x2, 0x0bd74e5b)                      \
  V(Int32x4, Int32x4., Int32x4Constructor, Int32x4, 0x480555a9)                \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, Int32x4, 0x36aa6963)        \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4, Int32x4,           \
    0x6715388a)                                                                \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, Bool, 0x56396c82)                    \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, Bool, 0x44704738)                    \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, Bool, 0x20d6ff37)                    \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, Bool, 0x5045616a)                    \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, Dynamic, 0x2c1fb2a3)           \
  V(_Int32x4, shuffle, Int32x4Shuffle, Int32x4, 0x20bc0b16)                    \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, Int32x4, 0x5c7056e1)              \
  V(_Int32x4, select, Int32x4Select, Float32x4, 0x6b49654f)                    \
  V(_Int32x4, withFlagX, Int32x4WithFlagX, Int32x4, 0x0ef58fcf)                \
  V(_Int32x4, withFlagY, Int32x4WithFlagY, Int32x4, 0x6485a9c4)                \
  V(_Int32x4, withFlagZ, Int32x4WithFlagZ, Int32x4, 0x267acdfa)                \
  V(_Int32x4, withFlagW, Int32x4WithFlagW, Int32x4, 0x345ac675)                \
  V(_Int64List, [], Int64ArrayGetIndexed, Dynamic, 0x51eafb97)                 \
  V(_Int64List, []=, Int64ArraySetIndexed, Dynamic, 0x4ddf27d5)                \
  V(_Bigint, get:_neg, Bigint_getNeg, Bool, 0x35608e23)                        \
  V(_Bigint, get:_used, Bigint_getUsed, Smi, 0x33bac590)                       \
  V(_Bigint, get:_digits, Bigint_getDigits, TypedDataUint32Array, 0x68df70f8)  \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, TypedDataUint32Array,     \
      0x02477157)                                                              \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, Dynamic, 0x4fc8d5e0)      \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, Array, 0x2d7a70ac)          \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, Dynamic, 0x0ec032e8)        \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, Smi, 0x088599ed)    \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, Dynamic, 0x5f42ca86)\
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, Smi, 0x32f3b13b)    \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, Dynamic, 0x7219c45b)\
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, Smi,          \
    0x558481c2)                                                                \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, Dynamic,      \
    0x5aa9888d)                                                                \
  V(::, _classRangeCheck, ClassRangeCheck, Bool, 0x2ae76b84)                   \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, Bool, 0x5acdfb75)    \
  V(::, _classRangeAssert, ClassRangeAssert, Dynamic, 0x6c77116e)              \
  V(::, _classIdEqualsAssert, ClassIdEqualsAssert, Dynamic, 0x09e0ae72)        \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, Smi, 0x67299f4f)                                   \
  V(_Smi, get:bitLength, Smi_bitLength, Smi, 0x25b3cb0a)                       \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, Smi, 0x562d5047)                  \
  V(_Bigint, _lsh, Bigint_lsh, Dynamic, 0x7b99f80e)                            \
  V(_Bigint, _rsh, Bigint_rsh, Dynamic, 0x5262b3a1)                            \
  V(_Bigint, _absAdd, Bigint_absAdd, Dynamic, 0x07cad968)                      \
  V(_Bigint, _absSub, Bigint_absSub, Dynamic, 0x1bf1bb4c)                      \
  V(_Bigint, _mulAdd, Bigint_mulAdd, Dynamic, 0x229759b7)                      \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, Dynamic, 0x5212b81f)                      \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, Dynamic, 0x4dd342fe)  \
  V(_Montgomery, _mulMod, Montgomery_mulMod, Dynamic, 0x17a515ac)              \
  V(_Double, >, Double_greaterThan, Bool, 0x4f1375a3)                          \
  V(_Double, >=, Double_greaterEqualThan, Bool, 0x4260c184)                    \
  V(_Double, <, Double_lessThan, Bool, 0x365d1eba)                             \
  V(_Double, <=, Double_lessEqualThan, Bool, 0x74b5eb64)                       \
  V(_Double, ==, Double_equal, Bool, 0x7ec67775)                               \
  V(_Double, +, Double_add, Double, 0x53994370)                                \
  V(_Double, -, Double_sub, Double, 0x3b69d466)                                \
  V(_Double, *, Double_mul, Double, 0x2bb9bd5d)                                \
  V(_Double, /, Double_div, Double, 0x483eee28)                                \
  V(_Double, get:hashCode, Double_hashCode, Dynamic, 0x702b77b7)               \
  V(_Double, get:_identityHashCode, Double_identityHash, Dynamic, 0x7bda5549)  \
  V(_Double, get:isNaN, Double_getIsNaN, Bool, 0x0af9d4a9)                     \
  V(_Double, get:isInfinite, Double_getIsInfinite, Bool, 0x0f7acb47)           \
  V(_Double, get:isNegative, Double_getIsNegative, Bool, 0x3a59e7f4)           \
  V(_Double, _mulFromInteger, Double_mulFromInteger, Double, 0x2017fcf6)       \
  V(_Double, .fromInteger, DoubleFromInteger, Double, 0x6d234f4b)              \
  V(_List, []=, ObjectArraySetIndexed, Dynamic, 0x6dff776c)                    \
  V(_GrowableList, .withData, GrowableArray_Allocate, GrowableObjectArray,     \
    0x28b2138e)                                                                \
  V(_GrowableList, add, GrowableArray_add, Dynamic, 0x40b490b8)                \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, Dynamic, 0x380184b1)          \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, Dynamic,          \
    0x79b8f955)                                                                \
  V(Object, ==, ObjectEquals, Bool, 0x7b32a55a)                                \
  V(Object, get:runtimeType, ObjectRuntimeType, Type, 0x00e8ab29)              \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, Bool, 0x4dc50799) \
  V(_StringBase, get:hashCode, String_getHashCode, Smi, 0x78c3d446)            \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, Bool, 0x4a8b29c8)             \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, Bool,          \
    0x46de4f10)                                                                \
  V(_StringBase, [], StringBaseCharAt, Dynamic, 0x7cbb8603)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, Smi, 0x78c3d446)  \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, OneByteString, 0x3538ad86)               \
  V(_OneByteString, _setAt, OneByteStringSetAt, Dynamic, 0x11ffddd1)           \
  V(_OneByteString, _allocate, OneByteString_allocate, OneByteString,          \
    0x74933376)                                                                \
  V(_OneByteString, ==, OneByteString_equality, Bool, 0x4eda197e)              \
  V(_TwoByteString, ==, TwoByteString_equality, Bool, 0x4eda197e)              \
  V(_Type, get:hashCode, Type_getHashCode, Smi, 0x18d1523f)                    \
  V(::, _getHash, Object_getHash, Smi, 0x2827856d)                             \
  V(::, _setHash, Object_setHash, Dynamic, 0x690faebd)                         \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    Dynamic, 0x6a10c54a)                                                       \
  V(_IntegerImplementation, +, Integer_add, Dynamic, 0x4f5804de)               \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, Dynamic,  \
    0x3fa4b1ed)                                                                \
  V(_IntegerImplementation, -, Integer_sub, Dynamic, 0x183b13bf)               \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    Dynamic, 0x3216e299)                                                       \
  V(_IntegerImplementation, *, Integer_mul, Dynamic, 0x4014c3c0)               \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    Dynamic, 0x6348b974)                                                       \
  V(_IntegerImplementation, ~/, Integer_truncDivide, Dynamic, 0x082b321e)      \
  V(_IntegerImplementation, unary-, Integer_negate, Dynamic, 0x428bf6fa)       \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    Dynamic, 0x395b1678)                                                       \
  V(_IntegerImplementation, &, Integer_bitAnd, Dynamic, 0x32c46c28)            \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    Dynamic, 0x6a36b395)                                                       \
  V(_IntegerImplementation, |, Integer_bitOr, Dynamic, 0x22d38a06)             \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    Dynamic, 0x72da93f0)                                                       \
  V(_IntegerImplementation, ^, Integer_bitXor, Dynamic, 0x79078347)            \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, Bool, 0x4a50ed58)                              \
  V(_IntegerImplementation, >, Integer_greaterThan, Bool, 0x6599a6e1)          \
  V(_IntegerImplementation, ==, Integer_equal, Bool, 0x6d56616e)               \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, Bool,     \
    0x063be842)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, Bool, 0x365d1eba)             \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, Bool, 0x74b5eb64)       \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, Bool, 0x4260c184)    \
  V(_IntegerImplementation, <<, Integer_shl, Dynamic, 0x415da44a)              \
  V(_IntegerImplementation, >>, Integer_sar, Dynamic, 0x6abbf70b)              \
  V(_Double, toInt, DoubleToInteger, Dynamic, 0x26ef344b)                      \

#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, Double, 0x70482cf3)                                    \
  V(_Random, _nextState, Random_nextState, Dynamic, 0x2842c4d5)                \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, Double, 0x6b7bd98c)                                      \
  V(::, cos, MathCos, Double, 0x459bf5fe)                                      \
  V(::, tan, MathTan, Double, 0x3bcd772a)                                      \
  V(::, asin, MathAsin, Double, 0x2ecc2fcd)                                    \
  V(::, acos, MathAcos, Double, 0x08cf2212)                                    \
  V(::, atan, MathAtan, Double, 0x1e2731d5)                                    \
  V(::, atan2, MathAtan2, Double, 0x39f1fa41)                                  \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, TypedDataInt8Array, 0x7e39a3a1)  \
  V(Uint8List, ., TypedData_Uint8Array_factory, TypedDataUint8Array,           \
    0x3a79adf7)                                                                \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory,                  \
    TypedDataUint8ClampedArray, 0x67f38395)                                    \
  V(Int16List, ., TypedData_Int16Array_factory, TypedDataInt16Array,           \
    0x6477bda8)                                                                \
  V(Uint16List, ., TypedData_Uint16Array_factory, TypedDataUint16Array,        \
    0x5707c5a2)                                                                \
  V(Int32List, ., TypedData_Int32Array_factory, TypedDataInt32Array,           \
    0x2b96ec0e)                                                                \
  V(Uint32List, ., TypedData_Uint32Array_factory,                              \
    TypedDataUint32Array, 0x0c1c0d62)                                          \
  V(Int64List, ., TypedData_Int64Array_factory,                                \
    TypedDataInt64Array, 0x279ab485)                                           \
  V(Uint64List, ., TypedData_Uint64Array_factory,                              \
    TypedDataUint64Array, 0x7bcb89c2)                                          \
  V(Float32List, ., TypedData_Float32Array_factory,                            \
    TypedDataFloat32Array, 0x43506c09)                                         \
  V(Float64List, ., TypedData_Float64Array_factory,                            \
    TypedDataFloat64Array, 0x1fde3eaf)                                         \
  V(Float32x4List, ., TypedData_Float32x4Array_factory,                        \
    TypedDataFloat32x4Array, 0x4a4030d6)                                       \
  V(Int32x4List, ., TypedData_Int32x4Array_factory,                            \
    TypedDataInt32x4Array, 0x6dd02406)                                         \
  V(Float64x2List, ., TypedData_Float64x2Array_factory,                        \
    TypedDataFloat64x2Array, 0x688e4e97)                                       \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, Smi, 0x49767a2c)                       \
  V(_Int8List, []=, Int8ArraySetIndexed, Dynamic, 0x24f42cd0)                  \
  V(_Uint8List, [], Uint8ArrayGetIndexed, Smi, 0x088d86d4)                     \
  V(_Uint8List, []=, Uint8ArraySetIndexed, Dynamic, 0x12639541)                \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, Smi, 0x088d86d4)    \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, Dynamic,           \
    0x12639541)                                                                \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, Smi, 0x088d86d4)       \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, Dynamic, 0x6790dba1)  \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    Smi, 0x088d86d4)                                                           \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    Dynamic, 0x6790dba1)                                                       \
  V(_Int16List, [], Int16ArrayGetIndexed, Smi, 0x5ec64948)                     \
  V(_Int16List, []=, Int16ArraySetIndexed, Dynamic, 0x0e4e8221)                \
  V(_Uint16List, [], Uint16ArrayGetIndexed, Smi, 0x5f49d093)                   \
  V(_Uint16List, []=, Uint16ArraySetIndexed, Dynamic, 0x2efbc90f)              \
  V(_Int32List, [], Int32ArrayGetIndexed, Dynamic, 0x4bc0d3dd)                 \
  V(_Int32List, []=, Int32ArraySetIndexed, Dynamic, 0x1adf9823)                \
  V(_Uint32List, [], Uint32ArrayGetIndexed, Dynamic, 0x188658ce)               \
  V(_Uint32List, []=, Uint32ArraySetIndexed, Dynamic, 0x01f51a79)              \
  V(_Float64List, [], Float64ArrayGetIndexed, Double, 0x0a714486)              \
  V(_Float64List, []=, Float64ArraySetIndexed, Dynamic, 0x04937367)            \
  V(_Float32List, [], Float32ArrayGetIndexed, Double, 0x5ade301f)              \
  V(_Float32List, []=, Float32ArraySetIndexed, Dynamic, 0x0d5c2e2b)            \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, Float32x4, 0x128cddeb)       \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, Dynamic, 0x7ad55c72)        \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, Int32x4, 0x4b78af9c)             \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, Dynamic, 0x31453dab)            \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, Float64x2, 0x644a0be1)       \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, Dynamic, 0x6b836b0b)        \
  V(_TypedList, get:length, TypedDataLength, Smi, 0x2091c4d8)                  \
  V(_Float32x4, get:x, Float32x4ShuffleX, Double, 0x63d1a9fd)                  \
  V(_Float32x4, get:y, Float32x4ShuffleY, Double, 0x203523d9)                  \
  V(_Float32x4, get:z, Float32x4ShuffleZ, Double, 0x13190678)                  \
  V(_Float32x4, get:w, Float32x4ShuffleW, Double, 0x698a38de)                  \
  V(_Float32x4, *, Float32x4Mul, Float32x4, 0x5dec68b2)                        \
  V(_Float32x4, -, Float32x4Sub, Float32x4, 0x3ea14461)                        \
  V(_Float32x4, +, Float32x4Add, Float32x4, 0x7ffcf301)                        \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, Smi, 0x25952390)                     \
  V(_List, [], ObjectArrayGetIndexed, Dynamic, 0x653da02e)                     \
  V(_ImmutableList, get:length, ImmutableArrayLength, Smi, 0x25952390)         \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, Dynamic, 0x653da02e)         \
  V(_GrowableList, get:length, GrowableArrayLength, Smi, 0x18dd86b4)           \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, Smi, 0x2e04be60)      \
  V(_GrowableList, _setData, GrowableArraySetData, Dynamic, 0x3dbea348)        \
  V(_GrowableList, _setLength, GrowableArraySetLength, Dynamic, 0x753e55da)    \
  V(_GrowableList, [], GrowableArrayGetIndexed, Dynamic, 0x446fe1f0)           \
  V(_GrowableList, []=, GrowableArraySetIndexed, Dynamic, 0x4699aed6)          \
  V(_StringBase, get:length, StringBaseLength, Smi, 0x2a2d03d1)                \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_Double, unary-, DoubleFlipSignBit, Double, 0x6db4674f)                    \
  V(_Double, truncateToDouble, DoubleTruncate, Double, 0x2f27e5d3)             \
  V(_Double, roundToDouble, DoubleRound, Double, 0x2f89c512)                   \
  V(_Double, floorToDouble, DoubleFloor, Double, 0x6aa87a5f)                   \
  V(_Double, ceilToDouble, DoubleCeil, Double, 0x1b045e9e)                     \
  V(_Double, _modulo, DoubleMod, Double, 0x5b8ceed7)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, Dynamic, 0x0b3066fd)           \
  V(::, _getDefaultTag, UserTag_defaultTag, Dynamic, 0x69f3f1ad)               \
  V(::, _getCurrentTag, Profiler_getCurrentTag, Dynamic, 0x05fa99d2)           \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, Dynamic,           \
    0x72f13f7a)                                                                \

#define ASYNC_LIB_INTRINSIC_LIST(V)                                            \
  V(::, _clearAsyncThreadStackTrace, ClearAsyncThreadStackTrace,               \
    Dynamic, 0x2edd4b25)                                                       \
  V(::, _setAsyncThreadStackTrace, SetAsyncThreadStackTrace,                   \
    Dynamic, 0x04f429a7)

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  ASYNC_LIB_INTRINSIC_LIST(V)                                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  DEVELOPER_LIB_INTRINSIC_LIST(V)                                              \
  MATH_LIB_INTRINSIC_LIST(V)                                                   \
  TYPED_DATA_LIB_INTRINSIC_LIST(V)                                             \

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core function that should always be inlined.
#define INLINE_WHITE_LIST(V)                                                   \
  V(Object, ==, ObjectEquals, 0x7b32a55a)                                      \
  V(_List, get:length, ObjectArrayLength, 0x25952390)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x25952390)              \
  V(_TypedList, get:length, TypedDataLength, 0x2091c4d8)                       \
  V(_GrowableList, get:length, GrowableArrayLength, 0x18dd86b4)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x2e04be60)           \
  V(_GrowableList, add, GrowableListAdd, 0x40b490b8)                           \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 0x007855e5)             \
  V(_StringBase, get:length, StringBaseLength, 0x2a2d03d1)                     \
  V(ListIterator, moveNext, ListIteratorMoveNext, 0x2dca30ce)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 0x324eb20b)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 0x5bd2ef37)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 0x74900bb8)                  \
  V(_List, ., ObjectArrayAllocate, 0x2121902f)                                 \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 0x7be74d04)                      \
  V(_List, get:iterator, ObjectArrayIterator, 0x6c851c55)                      \
  V(_List, forEach, ObjectArrayForEach, 0x11406b13)                            \
  V(_List, _slice, ObjectArraySlice, 0x4c865d1d)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 0x6c851c55)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 0x11406b13)                \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 0x7d308247)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 0x65ba546e)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 0x7e5a8458)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 0x62f615e4)                  \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 0x6395293e)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 0x79979d1f)                 \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 0x57499d9c)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 0x4dd87acb)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 0x57213f62)                 \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 0x5f315c42)               \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 0x476e7eb8)                 \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 0x6d64f0fa)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 0x12197195)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 0x14d20ad7)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 0x68448b4d)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 0x5d68cbf2)                 \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 0x2f4f6115)                 \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 0x10556170)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 0x00435162)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 0x6fd07e56)               \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 0x3e124984)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 0x2798f8e3)               \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 0x77404fe1)             \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 0x771585bf)             \
  V(::, exp, MathExp, 0x32ab9efa)                                              \
  V(::, log, MathLog, 0x1ee8f9fc)                                              \
  V(::, max, MathMax, 0x377e8889)                                              \
  V(::, min, MathMin, 0x32ebc57d)                                              \
  V(::, pow, MathPow, 0x79efc5a2)                                              \
  V(::, _classRangeCheck, ClassRangeCheck, 0x2ae76b84)                         \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, 0x5acdfb75)          \
  V(::, _classRangeAssert, ClassRangeAssert, 0x6c77116e)                       \
  V(::, _classIdEqualsAssert, ClassIdEqualsAssert, 0x09e0ae72)                 \
  V(Lists, copy, ListsCopy, 0x40e974f6)                                        \
  V(_Bigint, get:_neg, Bigint_getNeg, 0x35608e23)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 0x33bac590)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 0x68df70f8)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0x02477157)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0x4fc8d5e0)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0x2d7a70ac)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x0ec032e8)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0x088599ed)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x5f42ca86)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0x32f3b13b)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x7219c45b)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0x558481c2)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x5aa9888d)   \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(::, asin, MathAsin, 0x2ecc2fcd)                                            \
  V(::, acos, MathAcos, 0x08cf2212)                                            \
  V(::, atan, MathAtan, 0x1e2731d5)                                            \
  V(::, atan2, MathAtan2, 0x39f1fa41)                                          \
  V(::, cos, MathCos, 0x459bf5fe)                                              \
  V(::, sin, MathSin, 0x6b7bd98c)                                              \
  V(::, sqrt, MathSqrt, 0x70482cf3)                                            \
  V(::, tan, MathTan, 0x3bcd772a)                                              \
  V(_Bigint, _lsh, Bigint_lsh, 0x7b99f80e)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 0x5262b3a1)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 0x07cad968)                               \
  V(_Bigint, _absSub, Bigint_absSub, 0x1bf1bb4c)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 0x229759b7)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 0x5212b81f)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 0x4dd342fe)           \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 0x17a515ac)                       \
  V(_Double, >, Double_greaterThan, 0x4f1375a3)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x4260c184)                          \
  V(_Double, <, Double_lessThan, 0x365d1eba)                                   \
  V(_Double, <=, Double_lessEqualThan, 0x74b5eb64)                             \
  V(_Double, ==, Double_equal, 0x7ec67775)                                     \
  V(_Double, +, Double_add, 0x53994370)                                        \
  V(_Double, -, Double_sub, 0x3b69d466)                                        \
  V(_Double, *, Double_mul, 0x2bb9bd5d)                                        \
  V(_Double, /, Double_div, 0x483eee28)                                        \
  V(_IntegerImplementation, +, Integer_add, 0x4f5804de)                        \
  V(_IntegerImplementation, -, Integer_sub, 0x183b13bf)                        \
  V(_IntegerImplementation, *, Integer_mul, 0x4014c3c0)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x082b321e)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x428bf6fa)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x32c46c28)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 0x22d38a06)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x79078347)                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 0x6599a6e1)                \
  V(_IntegerImplementation, ==, Integer_equal, 0x6d56616e)                     \
  V(_IntegerImplementation, <, Integer_lessThan, 0x365d1eba)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0x74b5eb64)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x4260c184)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x415da44a)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0x6abbf70b)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0x7cbb8603)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x7041895a)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x336fa3ea)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x231bbe2e)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x0371785f)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x65ab3a20)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x0cb0fcf6)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0x6674ea6f)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0x236c6e7a)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x5c367ffb)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x772d1c0f)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x12bae36a)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0x15821cc9)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x1f8237fa)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0x181e5d16)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x7ddb9f87)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x74094f8d)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x03db087b)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x38a80b0d)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x40052c4e)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x07b89f54)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x00e8ab29)

// clang-format on

// Forward declarations.
class Function;
class Library;
class RawFunction;
class RawGrowableObjectArray;
class String;
class Zone;

// Class that recognizes the name and owner of a function and returns the
// corresponding enum. See RECOGNIZED_LIST above for list of recognizable
// functions.
class MethodRecognizer : public AllStatic {
 public:
  enum Kind {
    kUnknown,
#define DEFINE_ENUM_LIST(class_name, function_name, enum_name, type, fp)       \
  k##enum_name,
    RECOGNIZED_LIST(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
        kNumRecognizedMethods
  };

  static Kind RecognizeKind(const Function& function);
  static bool AlwaysInline(const Function& function);
  static bool PolymorphicTarget(const Function& function);
  static intptr_t ResultCid(const Function& function);
  static intptr_t MethodKindToReceiverCid(Kind kind);
  static const char* KindToCString(Kind kind);

#if !defined(DART_PRECOMPILED_RUNTIME)
  static void InitializeState();
  static RawGrowableObjectArray* QueryRecognizedMethods(Zone* zone);

 private:
  static void Libraries(GrowableArray<Library*>* libs);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

// Recognizes token corresponding to a method name.
class MethodTokenRecognizer : public AllStatic {
 public:
  static Token::Kind RecognizeTokenKind(const String& name);
};

#if !defined(DART_PRECOMPILED_RUNTIME)
#define CHECK_FINGERPRINT2(f, p0, p1, fp)                                      \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1, fp))

#define CHECK_FINGERPRINT3(f, p0, p1, p2, fp)                                  \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1 ", " #p2, fp))
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// clang-format off
// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x2121902f)                             \
  V(_GrowableListWithData, _GrowableList, .withData, kGrowableObjectArrayCid,  \
    0x28b2138e)                                                                \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0x3eed680b)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x7e39a3a1)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x3a79adf7)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x67f38395)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x6477bda8)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x5707c5a2)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x2b96ec0e)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0x0c1c0d62)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0x279ab485)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0x7bcb89c2)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0x1fde3eaf)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0x43506c09)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0x4a4030d6)

// clang-format on

// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_METHOD_RECOGNIZER_H_
