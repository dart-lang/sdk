// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_METHOD_RECOGNIZER_H_
#define RUNTIME_VM_METHOD_RECOGNIZER_H_

#include "vm/allocation.h"

namespace dart {

// clang-format off
// (class-name, function-name, recognized enum, result type, fingerprint).
// When adding a new function add a 0 as fingerprint, build and run to get the
// correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, Bool, 0x49c6e96a)                          \
  V(ClassID, getID, ClassIDgetID, Smi, 0x528fd455)                             \
  V(Object, Object., ObjectConstructor, Dynamic, 0x681617fe)                   \
  V(_List, ., ObjectArrayAllocate, Array, 0x63078b15)                          \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, Smi, 0x59e7291d)               \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, Smi, 0x38d3e5bf)             \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, Smi, 0x19dde22c)             \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, Smi, 0x4f3dbe58)           \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, Dynamic, 0x082db131)         \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, Dynamic, 0x1dcbfb98)       \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, Dynamic, 0x61b71474)         \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, Double, 0x63b56e15)      \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, Double, 0x399dacf8)      \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, Float32x4,           \
    0x4761a5be)                                                                \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, Int32x4, 0x3053e92c)     \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, Dynamic, 0x4e82d1e9)           \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, Dynamic, 0x4f3587fc)         \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, Dynamic, 0x6cef30ee)         \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, Dynamic, 0x64f938ac)       \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, Dynamic, 0x3693c029)         \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, Dynamic, 0x74bbf260)       \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, Dynamic, 0x75764edb)         \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, Dynamic, 0x6e72f2a4)     \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, Dynamic, 0x4765edda)     \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, Dynamic, 0x7cca4533) \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, Dynamic, 0x7631bdbc)     \
  V(_StringBase, _interpolate, StringBaseInterpolate, Dynamic, 0x6f98eb49)     \
  V(_IntegerImplementation, toDouble, IntegerToDouble, Double, 0x2f409861)     \
  V(_Double, _add, DoubleAdd, Double, 0x0021c560)                              \
  V(_Double, _sub, DoubleSub, Double, 0x419b3c66)                              \
  V(_Double, _mul, DoubleMul, Double, 0x1a08cbe1)                              \
  V(_Double, _div, DoubleDiv, Double, 0x38d2770f)                              \
  V(::, min, MathMin, Dynamic, 0x4276561c)                                     \
  V(::, max, MathMax, Dynamic, 0x54121d6a)                                     \
  V(::, _doublePow, MathDoublePow, Double, 0x698eb78d)                         \
  V(Float32x4, Float32x4., Float32x4Constructor, Float32x4, 0x05968999)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, Float32x4, 0x472a4c46)           \
  V(Float32x4, Float32x4.splat, Float32x4Splat, Float32x4, 0x00bba1a5)         \
  V(Float32x4, Float32x4.fromInt32x4Bits, Float32x4FromInt32x4Bits, Float32x4, \
    0x46d00995)                                                                \
  V(Float32x4, Float32x4.fromFloat64x2, Float32x4FromFloat64x2, Float32x4,     \
    0x685a86d2)                                                                \
  V(Float32x4, shuffle, Float32x4Shuffle, Float32x4, 0x7829101f)               \
  V(Float32x4, shuffleMix, Float32x4ShuffleMix, Float32x4, 0x4182c06b)         \
  V(Float32x4, get:signMask, Float32x4GetSignMask, Dynamic, 0x1d07ca93)        \
  V(Float32x4, _cmpequal, Float32x4Equal, Int32x4, 0x079804cb)                 \
  V(Float32x4, _cmpgt, Float32x4GreaterThan, Int32x4, 0x7e441585)              \
  V(Float32x4, _cmpgte, Float32x4GreaterThanOrEqual, Int32x4, 0x213f782d)      \
  V(Float32x4, _cmplt, Float32x4LessThan, Int32x4, 0x3f481f31)                 \
  V(Float32x4, _cmplte, Float32x4LessThanOrEqual, Int32x4, 0x061db061)         \
  V(Float32x4, _cmpnequal, Float32x4NotEqual, Int32x4, 0x6fada13e)             \
  V(Float32x4, _min, Float32x4Min, Float32x4, 0x4505ee78)                      \
  V(Float32x4, _max, Float32x4Max, Float32x4, 0x071681c6)                      \
  V(Float32x4, _scale, Float32x4Scale, Float32x4, 0x18c7f49d)                  \
  V(Float32x4, _sqrt, Float32x4Sqrt, Float32x4, 0x734e6ad0)                    \
  V(Float32x4, _reciprocalSqrt, Float32x4ReciprocalSqrt, Float32x4,            \
    0x5e8a97f6)                                                                \
  V(Float32x4, _reciprocal, Float32x4Reciprocal, Float32x4, 0x626f6106)        \
  V(Float32x4, _negate, Float32x4Negate, Float32x4, 0x7fb3a154)                \
  V(Float32x4, _abs, Float32x4Absolute, Float32x4, 0x1420f447)                 \
  V(Float32x4, _clamp, Float32x4Clamp, Float32x4, 0x4200222d)                  \
  V(Float32x4, withX, Float32x4WithX, Float32x4, 0x4e336aff)                   \
  V(Float32x4, withY, Float32x4WithY, Float32x4, 0x0a72b910)                   \
  V(Float32x4, withZ, Float32x4WithZ, Float32x4, 0x31e93658)                   \
  V(Float32x4, withW, Float32x4WithW, Float32x4, 0x60ddc105)                   \
  V(Float64x2, Float64x2., Float64x2Constructor, Float64x2, 0x193be61d)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, Float64x2, 0x7b2ed5df)           \
  V(Float64x2, Float64x2.splat, Float64x2Splat, Float64x2, 0x2abbfcb2)         \
  V(Float64x2, Float64x2.fromFloat32x4, Float64x2FromFloat32x4, Float64x2,     \
    0x2f43d3a6)                                                                \
  V(Float64x2, get:x, Float64x2GetX, Double, 0x58bfb39a)                       \
  V(Float64x2, get:y, Float64x2GetY, Double, 0x3cf4fcfa)                       \
  V(Float64x2, _negate, Float64x2Negate, Float64x2, 0x64ef7b77)                \
  V(Float64x2, abs, Float64x2Abs, Float64x2, 0x031f9e47)                       \
  V(Float64x2, sqrt, Float64x2Sqrt, Float64x2, 0x77f711dd)                     \
  V(Float64x2, get:signMask, Float64x2GetSignMask, Dynamic, 0x27ddf18d)        \
  V(Float64x2, scale, Float64x2Scale, Float64x2, 0x26830a61)                   \
  V(Float64x2, withX, Float64x2WithX, Float64x2, 0x1d2bcaf5)                   \
  V(Float64x2, withY, Float64x2WithY, Float64x2, 0x383ed6ac)                   \
  V(Float64x2, min, Float64x2Min, Float64x2, 0x28d7ddf6)                       \
  V(Float64x2, max, Float64x2Max, Float64x2, 0x0bd74e5b)                       \
  V(Int32x4, Int32x4., Int32x4Constructor, Int32x4, 0x26b199a7)                \
  V(Int32x4, Int32x4.bool, Int32x4BoolConstructor, Int32x4, 0x1b55a5e1)        \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Int32x4FromFloat32x4Bits, Int32x4,     \
    0x7e82564c)                                                                \
  V(Int32x4, get:flagX, Int32x4GetFlagX, Bool, 0x563883c4)                     \
  V(Int32x4, get:flagY, Int32x4GetFlagY, Bool, 0x446f5e7a)                     \
  V(Int32x4, get:flagZ, Int32x4GetFlagZ, Bool, 0x20d61679)                     \
  V(Int32x4, get:flagW, Int32x4GetFlagW, Bool, 0x504478ac)                     \
  V(Int32x4, get:signMask, Int32x4GetSignMask, Dynamic, 0x2c1ec9e5)            \
  V(Int32x4, shuffle, Int32x4Shuffle, Int32x4, 0x20bc0b16)                     \
  V(Int32x4, shuffleMix, Int32x4ShuffleMix, Int32x4, 0x5c7056e1)               \
  V(Int32x4, select, Int32x4Select, Float32x4, 0x518ee337)                     \
  V(Int32x4, withFlagX, Int32x4WithFlagX, Int32x4, 0x0ef58fcf)                 \
  V(Int32x4, withFlagY, Int32x4WithFlagY, Int32x4, 0x6485a9c4)                 \
  V(Int32x4, withFlagZ, Int32x4WithFlagZ, Int32x4, 0x267acdfa)                 \
  V(Int32x4, withFlagW, Int32x4WithFlagW, Int32x4, 0x345ac675)                 \
  V(Int64List, [], Int64ArrayGetIndexed, Dynamic, 0x0c0c939a)                  \
  V(Int64List, []=, Int64ArraySetIndexed, Dynamic, 0x3714d004)                 \
  V(_Bigint, get:_neg, Bigint_getNeg, Bool, 0x7bf17a57)                        \
  V(_Bigint, get:_used, Bigint_getUsed, Smi, 0x55041013)                       \
  V(_Bigint, get:_digits, Bigint_getDigits, TypedDataUint32Array, 0x46a6c1b3)  \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, Dynamic, 0x7d6bb76b)      \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, Dynamic, 0x4beb13f2)      \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, Array, 0x4bf5ccb3)          \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, Dynamic, 0x6007556d)        \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, Smi, 0x15e70845)    \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, Dynamic, 0x3e8c6edc)\
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, Smi, 0x35c5ac00)    \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, Dynamic, 0x49adf69e)\
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, Smi,          \
    0x306e6a79)                                                                \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, Dynamic,      \
    0x3fe95fc2)                                                                \
  V(::, _classRangeCheck, ClassRangeCheck, Bool, 0x6279a7b3)                   \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, Bool, 0x4799dac1)    \


// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, Smi, 0x63bfee11)                                   \
  V(_Smi, get:bitLength, Smi_bitLength, Smi, 0x25b2e24c)                       \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, Smi, 0x0df806ed)                  \
  V(_Bigint, _lsh, Bigint_lsh, Dynamic, 0x5cd95513)                            \
  V(_Bigint, _rsh, Bigint_rsh, Dynamic, 0x2d68d0e1)                            \
  V(_Bigint, _absAdd, Bigint_absAdd, Dynamic, 0x492f4865)                      \
  V(_Bigint, _absSub, Bigint_absSub, Dynamic, 0x174a3a34)                      \
  V(_Bigint, _mulAdd, Bigint_mulAdd, Dynamic, 0x24ced3ee)                      \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, Dynamic, 0x60c6b633)                      \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, Dynamic, 0x2f867482)  \
  V(_Montgomery, _mulMod, Montgomery_mulMod, Dynamic, 0x741bed13)              \
  V(_Double, >, Double_greaterThan, Bool, 0x569b0a81)                          \
  V(_Double, >=, Double_greaterEqualThan, Bool, 0x6c317340)                    \
  V(_Double, <, Double_lessThan, Bool, 0x26dda4bc)                             \
  V(_Double, <=, Double_lessEqualThan, Bool, 0x1e869d20)                       \
  V(_Double, ==, Double_equal, Bool, 0x578a1a51)                               \
  V(_Double, +, Double_add, Double, 0x4bac5dd5)                                \
  V(_Double, -, Double_sub, Double, 0x62052dbb)                                \
  V(_Double, *, Double_mul, Double, 0x23d068d8)                                \
  V(_Double, /, Double_div, Double, 0x48bac1dc)                                \
  V(_Double, get:isNaN, Double_getIsNaN, Bool, 0x0af8ebeb)                     \
  V(_Double, get:isInfinite, Double_getIsInfinite, Bool, 0x0f79e289)           \
  V(_Double, get:isNegative, Double_getIsNegative, Bool, 0x3a58ff36)           \
  V(_Double, _mulFromInteger, Double_mulFromInteger, Double, 0x330e9a36)       \
  V(_Double, .fromInteger, DoubleFromInteger, Double, 0x7ef45843)              \
  V(_List, []=, ObjectArraySetIndexed, Dynamic, 0x34d2c72c)                    \
  V(_GrowableList, .withData, GrowableArray_Allocate, GrowableObjectArray,     \
    0x25a786de)                                                                \
  V(_GrowableList, add, GrowableArray_add, Dynamic, 0x0d1358ed)                \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, Dynamic, 0x6036d7fa)          \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, Dynamic,          \
    0x71c67f7d)                                                                \
  V(Object, ==, ObjectEquals, Bool, 0x11662ed8)                                \
  V(Object, get:runtimeType, ObjectRuntimeType, Type, 0x00e7c26b)              \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, Bool, 0x72aad7e2) \
  V(_StringBase, get:hashCode, String_getHashCode, Smi, 0x78c2eb88)            \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, Bool, 0x74c21fca)             \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, Bool,          \
    0x2f851deb)                                                                \
  V(_StringBase, [], StringBaseCharAt, Dynamic, 0x2cf92c45)                    \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, Smi, 0x78c2eb88)  \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked, OneByteString, 0x638c3722)               \
  V(_OneByteString, _setAt, OneByteStringSetAt, Dynamic, 0x452533ef)           \
  V(_OneByteString, _allocate, OneByteString_allocate, OneByteString,          \
    0x3d4fad8a)                                                                \
  V(_OneByteString, ==, OneByteString_equality, Bool, 0x3f59b700)              \
  V(_TwoByteString, ==, TwoByteString_equality, Bool, 0x3f59b700)              \


#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    Dynamic, 0x79bde54b)                                                       \
  V(_IntegerImplementation, +, Integer_add, Dynamic, 0x0e4300c2)               \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger, Dynamic,  \
    0x3918c1af)                                                                \
  V(_IntegerImplementation, -, Integer_sub, Dynamic, 0x0ce294c3)               \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    Dynamic, 0x791ecebc)                                                       \
  V(_IntegerImplementation, *, Integer_mul, Dynamic, 0x4d8e01a4)               \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    Dynamic, 0x2e72f552)                                                       \
  V(_IntegerImplementation, ~/, Integer_truncDivide, Dynamic, 0x3caf6780)      \
  V(_IntegerImplementation, unary-, Integer_negate, Dynamic, 0x59dce57c)       \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    Dynamic, 0x1dfbe172)                                                       \
  V(_IntegerImplementation, &, Integer_bitAnd, Dynamic, 0x596a453e)            \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    Dynamic, 0x3d79aa1c)                                                       \
  V(_IntegerImplementation, |, Integer_bitOr, Dynamic, 0x071e153c)             \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    Dynamic, 0x4fd73f45)                                                       \
  V(_IntegerImplementation, ^, Integer_bitXor, Dynamic, 0x0c8aeb3d)            \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, Bool, 0x2e801bc8)                              \
  V(_IntegerImplementation, >, Integer_greaterThan, Bool, 0x28287b8f)          \
  V(_IntegerImplementation, ==, Integer_equal, Bool, 0x103da147)               \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger, Bool,     \
    0x7773d51d)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, Bool, 0x26dda4bc)             \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, Bool, 0x1e869d20)       \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, Bool, 0x6c317340)    \
  V(_IntegerImplementation, <<, Integer_shl, Dynamic, 0x4334dfc0)              \
  V(_IntegerImplementation, >>, Integer_sar, Dynamic, 0x4a2583a1)              \
  V(_Double, toInt, DoubleToInteger, Dynamic, 0x26ef344b)


#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, Double, 0x1afb83d4)                                    \
  V(_Random, _nextState, Random_nextState, Dynamic, 0x1e4b0103)                \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, Double, 0x0213abe6)                                      \
  V(::, cos, MathCos, Double, 0x79a7611c)                                      \
  V(::, tan, MathTan, Double, 0x4e2e20db)                                      \
  V(::, asin, MathAsin, Double, 0x661ff68b)                                    \
  V(::, acos, MathAcos, Double, 0x44e71d5f)                                    \
  V(::, atan, MathAtan, Double, 0x4436a657)                                    \
  V(::, atan2, MathAtan2, Double, 0x60a40743)                                  \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, TypedDataInt8Array, 0x2e7749e3)  \
  V(Uint8List, ., TypedData_Uint8Array_factory, TypedDataUint8Array,           \
    0x6ab75439)                                                                \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory,                  \
    TypedDataUint8ClampedArray, 0x183129d7)                                    \
  V(Int16List, ., TypedData_Int16Array_factory, TypedDataInt16Array,           \
    0x14b563ea)                                                                \
  V(Uint16List, ., TypedData_Uint16Array_factory, TypedDataUint16Array,        \
    0x07456be4)                                                                \
  V(Int32List, ., TypedData_Int32Array_factory, TypedDataInt32Array,           \
    0x5bd49250)                                                                \
  V(Uint32List, ., TypedData_Uint32Array_factory,                              \
    TypedDataUint32Array, 0x3c59b3a4)                                          \
  V(Int64List, ., TypedData_Int64Array_factory,                                \
    TypedDataInt64Array, 0x57d85ac7)                                           \
  V(Uint64List, ., TypedData_Uint64Array_factory,                              \
    TypedDataUint64Array, 0x2c093004)                                          \
  V(Float32List, ., TypedData_Float32Array_factory,                            \
    TypedDataFloat32Array, 0x738e124b)                                         \
  V(Float64List, ., TypedData_Float64Array_factory,                            \
    TypedDataFloat64Array, 0x501be4f1)                                         \
  V(Float32x4List, ., TypedData_Float32x4Array_factory,                        \
    TypedDataFloat32x4Array, 0x7a7dd718)                                       \
  V(Int32x4List, ., TypedData_Int32x4Array_factory,                            \
    TypedDataInt32x4Array, 0x1e0dca48)                                         \
  V(Float64x2List, ., TypedData_Float64x2Array_factory,                        \
    TypedDataFloat64x2Array, 0x18cbf4d9)                                       \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(Int8List, [], Int8ArrayGetIndexed, Smi, 0x069af8b3)                        \
  V(Int8List, []=, Int8ArraySetIndexed, Dynamic, 0x33994cd7)                   \
  V(Uint8List, [], Uint8ArrayGetIndexed, Smi, 0x027603ed)                      \
  V(Uint8List, []=, Uint8ArraySetIndexed, Dynamic, 0x060d5256)                 \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, Smi, 0x027603ed)    \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, Dynamic,           \
    0x060d5256)                                                                \
  V(Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, Smi, 0x027603ed)        \
  V(Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, Dynamic, 0x28f5f058)   \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    Smi, 0x027603ed)                                                           \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    Dynamic, 0x28f5f058)                                                       \
  V(Int16List, [], Int16ArrayGetIndexed, Smi, 0x173cd6a1)                      \
  V(Int16List, []=, Int16ArraySetIndexed, Dynamic, 0x32f84e3c)                 \
  V(Uint16List, [], Uint16ArrayGetIndexed, Smi, 0x3ececa2f)                    \
  V(Uint16List, []=, Uint16ArraySetIndexed, Dynamic, 0x5c3a0bb9)               \
  V(Int32List, [], Int32ArrayGetIndexed, Dynamic, 0x262eef09)                  \
  V(Int32List, []=, Int32ArraySetIndexed, Dynamic, 0x1b05b471)                 \
  V(Uint32List, [], Uint32ArrayGetIndexed, Dynamic, 0x6040f7fb)                \
  V(Uint32List, []=, Uint32ArraySetIndexed, Dynamic, 0x3a4e1119)               \
  V(Float64List, [], Float64ArrayGetIndexed, Double, 0x7a27098d)               \
  V(Float64List, []=, Float64ArraySetIndexed, Dynamic, 0x139b2465)             \
  V(Float32List, [], Float32ArrayGetIndexed, Double, 0x5686528f)               \
  V(Float32List, []=, Float32ArraySetIndexed, Dynamic, 0x1b0d90df)             \
  V(Float32x4List, [], Float32x4ArrayGetIndexed, Float32x4, 0x01c7017b)        \
  V(Float32x4List, []=, Float32x4ArraySetIndexed, Dynamic, 0x56e843aa)         \
  V(Int32x4List, [], Int32x4ArrayGetIndexed, Int32x4, 0x08353f8d)              \
  V(Int32x4List, []=, Int32x4ArraySetIndexed, Dynamic, 0x1d9a47a5)             \
  V(Float64x2List, [], Float64x2ArrayGetIndexed, Float64x2, 0x669b1498)        \
  V(Float64x2List, []=, Float64x2ArraySetIndexed, Dynamic, 0x76da6ffe)         \
  V(_TypedList, get:length, TypedDataLength, Smi, 0x2090dc1a)                  \
  V(Float32x4, get:x, Float32x4ShuffleX, Double, 0x63d0c13f)                   \
  V(Float32x4, get:y, Float32x4ShuffleY, Double, 0x20343b1b)                   \
  V(Float32x4, get:z, Float32x4ShuffleZ, Double, 0x13181dba)                   \
  V(Float32x4, get:w, Float32x4ShuffleW, Double, 0x69895020)                   \
  V(Float32x4, _mul, Float32x4Mul, Float32x4, 0x028d3146)                      \
  V(Float32x4, _sub, Float32x4Sub, Float32x4, 0x062f78f7)                      \
  V(Float32x4, _add, Float32x4Add, Float32x4, 0x509f9006)                      \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, Smi, 0x25943ad2)                     \
  V(_List, [], ObjectArrayGetIndexed, Dynamic, 0x157b4670)                     \
  V(_ImmutableList, get:length, ImmutableArrayLength, Smi, 0x25943ad2)         \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, Dynamic, 0x157b4670)         \
  V(_GrowableList, get:length, GrowableArrayLength, Smi, 0x18dc9df6)           \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, Smi, 0x02734d82)      \
  V(_GrowableList, _setData, GrowableArraySetData, Dynamic, 0x0c854013)        \
  V(_GrowableList, _setLength, GrowableArraySetLength, Dynamic, 0x1401a7d6)    \
  V(_GrowableList, [], GrowableArrayGetIndexed, Dynamic, 0x74ad8832)           \
  V(_GrowableList, []=, GrowableArraySetIndexed, Dynamic, 0x0d6cfe96)          \
  V(_StringBase, get:length, StringBaseLength, Smi, 0x2a2c1b13)                \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, Smi, 0x55a0a1f3)      \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    Smi, 0x55a0a1f3)                                                           \
  V(_Double, unary-, DoubleFlipSignBit, Double, 0x6a4ab611)                    \
  V(_Double, truncateToDouble, DoubleTruncate, Double, 0x2f27e5d3)             \
  V(_Double, roundToDouble, DoubleRound, Double, 0x2f89c512)                   \
  V(_Double, floorToDouble, DoubleFloor, Double, 0x6aa87a5f)                   \
  V(_Double, ceilToDouble, DoubleCeil, Double, 0x1b045e9e)                     \
  V(_Double, _modulo, DoubleMod, Double, 0x2e41c4fc)


#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, Dynamic, 0x0b3066fd)           \
  V(::, _getDefaultTag, UserTag_defaultTag, Dynamic, 0x14ddc3b7)               \
  V(::, _getCurrentTag, Profiler_getCurrentTag, Dynamic, 0x486ee02d)           \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, Dynamic,           \
    0x1667ce76)                                                                \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
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
  V(Object, ==, ObjectEquals, 0x11662ed8)                                      \
  V(_List, get:length, ObjectArrayLength, 0x25943ad2)                          \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x25943ad2)              \
  V(_TypedList, get:length, TypedDataLength, 0x2090dc1a)                       \
  V(_GrowableList, get:length, GrowableArrayLength, 0x18dc9df6)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x02734d82)           \
  V(_GrowableList, add, GrowableListAdd, 0x0d1358ed)                           \
  V(_GrowableList, removeLast, GrowableListRemoveLast, 0x7add0363)             \
  V(_StringBase, get:length, StringBaseLength, 0x2a2c1b13)                     \
  V(ListIterator, moveNext, ListIteratorMoveNext, 0x3f892e71)                  \
  V(_FixedSizeArrayIterator, moveNext, FixedListIteratorMoveNext, 0x5681c902)  \
  V(_GrowableList, get:iterator, GrowableArrayIterator, 0x6db11a73)            \
  V(_GrowableList, forEach, GrowableArrayForEach, 0x250036fe)                  \
  V(_List, ., ObjectArrayAllocate, 0x63078b15)                                 \
  V(ListMixin, get:isEmpty, ListMixinIsEmpty, 0x787d9bc6)                      \
  V(_List, get:iterator, ObjectArrayIterator, 0x119cf41a)                      \
  V(_List, forEach, ObjectArrayForEach, 0x0abce191)                            \
  V(_List, _slice, ObjectArraySlice, 0x3219e715)                               \
  V(_ImmutableList, get:iterator, ImmutableArrayIterator, 0x119cf41a)          \
  V(_ImmutableList, forEach, ImmutableArrayForEach, 0x0abce191)                \
  V(_Uint8ArrayView, [], Uint8ArrayViewGetIndexed, 0x4fc6b3d3)                 \
  V(_Uint8ArrayView, []=, Uint8ArrayViewSetIndexed, 0x2032fdf0)                \
  V(_Int8ArrayView, [], Int8ArrayViewGetIndexed, 0x12036952)                   \
  V(_Int8ArrayView, []=, Int8ArrayViewSetIndexed, 0x6d881658)                  \
  V(_ByteDataView, setInt8, ByteDataViewSetInt8, 0x275cbdca)                   \
  V(_ByteDataView, setUint8, ByteDataViewSetUint8, 0x62774e77)                 \
  V(_ByteDataView, setInt16, ByteDataViewSetInt16, 0x7a43c6c2)                 \
  V(_ByteDataView, setUint16, ByteDataViewSetUint16, 0x64dd988f)               \
  V(_ByteDataView, setInt32, ByteDataViewSetInt32, 0x3363264a)                 \
  V(_ByteDataView, setUint32, ByteDataViewSetUint32, 0x158f9899)               \
  V(_ByteDataView, setInt64, ByteDataViewSetInt64, 0x480f73a5)                 \
  V(_ByteDataView, setUint64, ByteDataViewSetUint64, 0x5c23db8c)               \
  V(_ByteDataView, setFloat32, ByteDataViewSetFloat32, 0x4f76c49a)             \
  V(_ByteDataView, setFloat64, ByteDataViewSetFloat64, 0x5e1ddd4f)             \
  V(_ByteDataView, getInt8, ByteDataViewGetInt8, 0x01bac87d)                   \
  V(_ByteDataView, getUint8, ByteDataViewGetUint8, 0x129dab34)                 \
  V(_ByteDataView, getInt16, ByteDataViewGetInt16, 0x60282377)                 \
  V(_ByteDataView, getUint16, ByteDataViewGetUint16, 0x10edcd89)               \
  V(_ByteDataView, getInt32, ByteDataViewGetInt32, 0x79630f81)                 \
  V(_ByteDataView, getUint32, ByteDataViewGetUint32, 0x220d3da8)               \
  V(_ByteDataView, getInt64, ByteDataViewGetInt64, 0x757dd5c8)                 \
  V(_ByteDataView, getUint64, ByteDataViewGetUint64, 0x2fab992e)               \
  V(_ByteDataView, getFloat32, ByteDataViewGetFloat32, 0x387e9fc6)             \
  V(_ByteDataView, getFloat64, ByteDataViewGetFloat64, 0x5396432d)             \
  V(::, exp, MathExp, 0x5b894d7b)                                              \
  V(::, log, MathLog, 0x2e25132c)                                              \
  V(::, max, MathMax, 0x54121d6a)                                              \
  V(::, min, MathMin, 0x4276561c)                                              \
  V(::, pow, MathPow, 0x438e3089)                                              \
  V(::, _classRangeCheck, ClassRangeCheck, 0x6279a7b3)                         \
  V(::, _classRangeCheckNegative, ClassRangeCheckNegated, 0x4799dac1)          \
  V(Lists, copy, ListsCopy, 0x21a194fa)                                        \
  V(_Bigint, get:_neg, Bigint_getNeg, 0x7bf17a57)                              \
  V(_Bigint, get:_used, Bigint_getUsed, 0x55041013)                            \
  V(_Bigint, get:_digits, Bigint_getDigits, 0x46a6c1b3)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0x7d6bb76b)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0x4beb13f2)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0x4bf5ccb3)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x6007556d)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0x15e70845)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x3e8c6edc)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0x35c5ac00)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x49adf69e)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0x306e6a79)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x3fe95fc2)   \

// A list of core function that should never be inlined.
#define INLINE_BLACK_LIST(V)                                                   \
  V(::, asin, MathAsin, 0x661ff68b)                                            \
  V(::, acos, MathAcos, 0x44e71d5f)                                            \
  V(::, atan, MathAtan, 0x4436a657)                                            \
  V(::, atan2, MathAtan2, 0x60a40743)                                          \
  V(::, cos, MathCos, 0x79a7611c)                                              \
  V(::, sin, MathSin, 0x0213abe6)                                              \
  V(::, sqrt, MathSqrt, 0x1afb83d4)                                            \
  V(::, tan, MathTan, 0x4e2e20db)                                              \
  V(_Bigint, _lsh, Bigint_lsh, 0x5cd95513)                                     \
  V(_Bigint, _rsh, Bigint_rsh, 0x2d68d0e1)                                     \
  V(_Bigint, _absAdd, Bigint_absAdd, 0x492f4865)                               \
  V(_Bigint, _absSub, Bigint_absSub, 0x174a3a34)                               \
  V(_Bigint, _mulAdd, Bigint_mulAdd, 0x24ced3ee)                               \
  V(_Bigint, _sqrAdd, Bigint_sqrAdd, 0x60c6b633)                               \
  V(_Bigint, _estQuotientDigit, Bigint_estQuotientDigit, 0x2f867482)           \
  V(_Montgomery, _mulMod, Montgomery_mulMod, 0x741bed13)                       \
  V(_Double, >, Double_greaterThan, 0x569b0a81)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x6c317340)                          \
  V(_Double, <, Double_lessThan, 0x26dda4bc)                                   \
  V(_Double, <=, Double_lessEqualThan, 0x1e869d20)                             \
  V(_Double, ==, Double_equal, 0x578a1a51)                                     \
  V(_Double, +, Double_add, 0x4bac5dd5)                                        \
  V(_Double, -, Double_sub, 0x62052dbb)                                        \
  V(_Double, *, Double_mul, 0x23d068d8)                                        \
  V(_Double, /, Double_div, 0x48bac1dc)                                        \
  V(_IntegerImplementation, +, Integer_add, 0x0e4300c2)                        \
  V(_IntegerImplementation, -, Integer_sub, 0x0ce294c3)                        \
  V(_IntegerImplementation, *, Integer_mul, 0x4d8e01a4)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x3caf6780)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x59dce57c)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x596a453e)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 0x071e153c)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x0c8aeb3d)                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 0x28287b8f)                \
  V(_IntegerImplementation, ==, Integer_equal, 0x103da147)                     \
  V(_IntegerImplementation, <, Integer_lessThan, 0x26dda4bc)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0x1e869d20)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x6c317340)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x4334dfc0)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0x4a2583a1)                       \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0x2cf92c45)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x59e7291d)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x38d3e5bf)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x19dde22c)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x4f3dbe58)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x082db131)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x1dcbfb98)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0x63b56e15)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0x399dacf8)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x4761a5be)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x3053e92c)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x4e82d1e9)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0x4f3587fc)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x6cef30ee)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0x64f938ac)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x3693c029)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x74bbf260)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x6e72f2a4)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x4765edda)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x7cca4533)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x7631bdbc)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x00e7c26b)

// clang-format on

// Forward declarations.
class Function;

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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};


#if !defined(DART_PRECOMPILED_RUNTIME)
#define CHECK_FINGERPRINT2(f, p0, p1, fp)                                      \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1, fp))

#define CHECK_FINGERPRINT3(f, p0, p1, p2, fp)                                  \
  ASSERT(f.CheckSourceFingerprint(#p0 ", " #p1 ", " #p2, fp))
#endif  // !defined(DART_PRECOMPILED_RUNTIME)


// clang-format off
// List of recognized list factories:
// (factory-name-symbol, result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, kArrayCid, 0x63078b15)                                       \
  V(_GrowableListWithData, kGrowableObjectArrayCid, 0x25a786de)                \
  V(_GrowableListFactory, kGrowableObjectArrayCid, 0x4f4d4790)                 \
  V(_Int8ArrayFactory, kTypedDataInt8ArrayCid, 0x2e7749e3)                     \
  V(_Uint8ArrayFactory, kTypedDataUint8ArrayCid, 0x6ab75439)                   \
  V(_Uint8ClampedArrayFactory, kTypedDataUint8ClampedArrayCid, 0x183129d7)     \
  V(_Int16ArrayFactory, kTypedDataInt16ArrayCid, 0x14b563ea)                   \
  V(_Uint16ArrayFactory, kTypedDataUint16ArrayCid, 0x07456be4)                 \
  V(_Int32ArrayFactory, kTypedDataInt32ArrayCid, 0x5bd49250)                   \
  V(_Uint32ArrayFactory, kTypedDataUint32ArrayCid, 0x3c59b3a4)                 \
  V(_Int64ArrayFactory, kTypedDataInt64ArrayCid, 0x57d85ac7)                   \
  V(_Uint64ArrayFactory, kTypedDataUint64ArrayCid, 0x2c093004)                 \
  V(_Float64ArrayFactory, kTypedDataFloat64ArrayCid, 0x501be4f1)               \
  V(_Float32ArrayFactory, kTypedDataFloat32ArrayCid, 0x738e124b)               \
  V(_Float32x4ArrayFactory, kTypedDataFloat32x4ArrayCid, 0x7a7dd718)

// clang-format on

// Class that recognizes factories and returns corresponding result cid.
class FactoryRecognizer : public AllStatic {
 public:
  // Return kDynamicCid if factory is not recognized.
  static intptr_t ResultCid(const Function& factory);
};

}  // namespace dart

#endif  // RUNTIME_VM_METHOD_RECOGNIZER_H_
