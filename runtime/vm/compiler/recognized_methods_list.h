// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
#define RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_

namespace dart {

// clang-format off
// (class-name, function-name, recognized enum, fingerprint).
// When adding a new function, add a 0 as the fingerprint and run the build in
// debug mode to get the correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(::, identical, ObjectIdentical, 0xc6e9467a)                                \
  V(ClassID, getID, ClassIDgetID, 0xf0376ced)                                  \
  V(Object, Object., ObjectConstructor, 0x8f3ae7ea)                            \
  V(List, ., ListFactory, 0xdf9970a9)                                          \
  V(_List, ., ObjectArrayAllocate, 0x03ddbd3a)                                 \
  V(_List, []=, ObjectArraySetIndexed, 0x4d5e74cf)                             \
  V(_GrowableList, []=, GrowableArraySetIndexed, 0x4d5e74cf)                   \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0xa24c2704)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0xa491df3e)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0xb65ae1fc)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0xb4b776e5)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0xb460abe4)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x8c066c71)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xacf2f222)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0xa74b200b)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xa33a9f77)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0x87d86b60)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x3e76086e)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0xfea5f17f)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xd2c4e74b)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 0xec62b082)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xc3566903)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 0xdb50780f)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xbeeeea8a)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xca02f10a)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xcf587ccf)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xe01a1df0)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0xb6a6294f)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0xce7dad17)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x4b773b59)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xfa2a6f88)              \
  V(ByteData, ., ByteDataFactory, 0x0d31f187)                                  \
  V(_ByteDataView, get:offsetInBytes, ByteDataViewOffsetInBytes, 0x0d956c6d)   \
  V(_ByteDataView, get:_typedData, ByteDataViewTypedData, 0x28cc4efc)          \
  V(_TypedListView, get:offsetInBytes, TypedDataViewOffsetInBytes, 0x0d956c6d) \
  V(_TypedListView, get:_typedData, TypedDataViewTypedData, 0x28cc4efc)        \
  V(_ByteDataView, ._, TypedData_ByteDataView_factory, 0xb839ff59)             \
  V(_Int8ArrayView, ._, TypedData_Int8ArrayView_factory, 0x3d000a8d)           \
  V(_Uint8ArrayView, ._, TypedData_Uint8ArrayView_factory, 0xff69de0f)         \
  V(_Uint8ClampedArrayView, ._, TypedData_Uint8ClampedArrayView_factory,       \
    0xdff11b9a)                                                                \
  V(_Int16ArrayView, ._, TypedData_Int16ArrayView_factory, 0x1635c91e)         \
  V(_Uint16ArrayView, ._, TypedData_Uint16ArrayView_factory, 0x287cbc66)       \
  V(_Int32ArrayView, ._, TypedData_Int32ArrayView_factory, 0xf5270227)         \
  V(_Uint32ArrayView, ._, TypedData_Uint32ArrayView_factory, 0xbb74a021)       \
  V(_Int64ArrayView, ._, TypedData_Int64ArrayView_factory, 0xf348a583)         \
  V(_Uint64ArrayView, ._, TypedData_Uint64ArrayView_factory, 0x10589491)       \
  V(_Float32ArrayView, ._, TypedData_Float32ArrayView_factory, 0xbb4124b3)     \
  V(_Float64ArrayView, ._, TypedData_Float64ArrayView_factory, 0x5f0b81e9)     \
  V(_Float32x4ArrayView, ._, TypedData_Float32x4ArrayView_factory, 0xd8c71a39) \
  V(_Int32x4ArrayView, ._, TypedData_Int32x4ArrayView_factory, 0x9bfbd6d5)     \
  V(_Float64x2ArrayView, ._, TypedData_Float64x2ArrayView_factory, 0x1a383408) \
  V(::, _toClampedUint8, ConvertIntToClampedUint8, 0x59765a4a)                 \
  V(::, copyRangeFromUint8ListToOneByteString,                                 \
    CopyRangeFromUint8ListToOneByteString, 0x00000000)                         \
  V(_StringBase, _interpolate, StringBaseInterpolate, 0xc0a650e4)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 0x22a26db3)             \
  V(_Double, _add, DoubleAdd, 0x2f5c036a)                                      \
  V(_Double, _sub, DoubleSub, 0x6d3cec71)                                      \
  V(_Double, _mul, DoubleMul, 0x648e67af)                                      \
  V(_Double, _div, DoubleDiv, 0x6d72d7d4)                                      \
  V(::, min, MathMin, 0x935b799b)                                              \
  V(::, max, MathMax, 0xe188dec2)                                              \
  V(::, _doublePow, MathDoublePow, 0x5ae04e61)                                 \
  V(::, _intPow, MathIntPow, 0x569ffd3f)                                       \
  V(Float32x4, _Float32x4FromDoubles, Float32x4FromDoubles, 0xbe902b89)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 0x9b875c7f)                      \
  V(Float32x4, _Float32x4Splat, Float32x4Splat, 0xd0cf3e6c)                    \
  V(Float32x4, Float32x4.fromInt32x4Bits, Int32x4ToFloat32x4, 0x7339b2bd)      \
  V(Float32x4, Float32x4.fromFloat64x2, Float64x2ToFloat32x4, 0x5de0e788)      \
  V(_Float32x4, shuffle, Float32x4Shuffle, 0x5bc2446e)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 0x61887391)                   \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 0x2931936f)                \
  V(_Float32x4, equal, Float32x4Equal, 0x63e87fb9)                             \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, 0x71db0fc2)                 \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, 0x6dfbf3fa)   \
  V(_Float32x4, lessThan, Float32x4LessThan, 0x69a60360)                       \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, 0x6604e583)         \
  V(_Float32x4, notEqual, Float32x4NotEqual, 0x83dcc786)                       \
  V(_Float32x4, min, Float32x4Min, 0xf70ed6d5)                                 \
  V(_Float32x4, max, Float32x4Max, 0xd93e58a6)                                 \
  V(_Float32x4, scale, Float32x4Scale, 0xea28b605)                             \
  V(_Float32x4, sqrt, Float32x4Sqrt, 0xacff17f7)                               \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, 0xa5e00f7d)           \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, 0x9c5a3fb7)                   \
  V(_Float32x4, unary-, Float32x4Negate, 0xae8af7f1)                           \
  V(_Float32x4, abs, Float32x4Abs, 0xb34e9b8d)                                 \
  V(_Float32x4, clamp, Float32x4Clamp, 0xbed4ce62)                             \
  V(_Float32x4, _withX, Float32x4WithX, 0xf0211c74)                            \
  V(_Float32x4, _withY, Float32x4WithY, 0x074539fc)                            \
  V(_Float32x4, _withZ, Float32x4WithZ, 0xf026c2e5)                            \
  V(_Float32x4, _withW, Float32x4WithW, 0xe364aa0f)                            \
  V(Float64x2, _Float64x2FromDoubles, Float64x2FromDoubles, 0x1ca49394)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 0x5e70f315)                      \
  V(Float64x2, _Float64x2Splat, Float64x2Splat, 0x05711520)                    \
  V(Float64x2, Float64x2.fromFloat32x4, Float32x4ToFloat64x2, 0x956c2161)      \
  V(_Float64x2, get:x, Float64x2GetX, 0x00b83193)                              \
  V(_Float64x2, get:y, Float64x2GetY, 0xee498cb6)                              \
  V(_Float64x2, unary-, Float64x2Negate, 0x71748e87)                           \
  V(_Float64x2, abs, Float64x2Abs, 0x76383223)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 0x6fe8ae8d)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 0x2931936f)                \
  V(_Float64x2, scale, Float64x2Scale, 0xad124c9b)                             \
  V(_Float64x2, _withX, Float64x2WithX, 0xb30ab30a)                            \
  V(_Float64x2, _withY, Float64x2WithY, 0xca2ed092)                            \
  V(_Float64x2, min, Float64x2Min,  0x57938495)                                \
  V(_Float64x2, max, Float64x2Max,  0x39c30666)                                \
  V(Int32x4, _Int32x4FromInts, Int32x4FromInts, 0xbce3fab8)                    \
  V(Int32x4, _Int32x4FromBools, Int32x4FromBools, 0x45ef1b0f)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4, 0x64c906dc)        \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 0x9f8da5bb)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 0xbafddc9b)                          \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 0xc8a777ee)                          \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 0xd1c78a2f)                          \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 0x2931936f)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 0x00cff856)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 0x57a21961)                       \
  V(_Int32x4, select, Int32x4Select, 0xafd1fc25)                               \
  V(_Int32x4, _withFlagX, Int32x4WithFlagX, 0x7d654214)                        \
  V(_Int32x4, _withFlagY, Int32x4WithFlagY, 0x7e67ec85)                        \
  V(_Int32x4, _withFlagZ, Int32x4WithFlagZ, 0x9363a67c)                        \
  V(_Int32x4, _withFlagW, Int32x4WithFlagW, 0x7035cb54)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0x09db1d9d)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0xb643fb19)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0x9a54182a)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x8bc58326)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0xf3cf0e2e)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x75261d2a)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0xfbd541dd)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x7d2c50d9)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0xfdd43ee1)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x7f2b4ddd)   \
  V(::, _classRangeCheck, ClassRangeCheck, 0xca52e30a)                         \
  V(::, _asyncStackTraceHelper, AsyncStackTraceHelper, 0xaeaed5cb)             \
  V(::, _abi, FfiAbi, 0xf2e89620)                                              \
  V(::, _asFunctionInternal, FfiAsFunctionInternal, 0x77414ede)                \
  V(::, _nativeCallbackFunction, FfiNativeCallbackFunction, 0x5bd261b8)        \
  V(::, _loadInt8, FfiLoadInt8, 0x9b1e4a8d)                                    \
  V(::, _loadInt16, FfiLoadInt16, 0x2824dc24)                                  \
  V(::, _loadInt32, FfiLoadInt32, 0x3f9bf49d)                                  \
  V(::, _loadInt64, FfiLoadInt64, 0xbb4e2186)                                  \
  V(::, _loadUint8, FfiLoadUint8, 0xc93d1241)                                  \
  V(::, _loadUint16, FfiLoadUint16, 0x4bc4c8ae)                                \
  V(::, _loadUint32, FfiLoadUint32, 0x5fd2e17c)                                \
  V(::, _loadUint64, FfiLoadUint64, 0xec4e4e0a)                                \
  V(::, _loadIntPtr, FfiLoadIntPtr, 0x1ad8e69f)                                \
  V(::, _loadFloat, FfiLoadFloat, 0x234b92dc)                                  \
  V(::, _loadDouble, FfiLoadDouble, 0x97c755b3)                                \
  V(::, _loadPointer, FfiLoadPointer, 0xd9d293a5)                              \
  V(::, _storeInt8, FfiStoreInt8, 0x9a637adf)                                  \
  V(::, _storeInt16, FfiStoreInt16, 0x7c5ad40b)                                \
  V(::, _storeInt32, FfiStoreInt32, 0xc729a9da)                                \
  V(::, _storeInt64, FfiStoreInt64, 0x748af071)                                \
  V(::, _storeUint8, FfiStoreUint8, 0xea22235e)                                \
  V(::, _storeUint16, FfiStoreUint16, 0x0c61dd74)                              \
  V(::, _storeUint32, FfiStoreUint32, 0x32962fcb)                              \
  V(::, _storeUint64, FfiStoreUint64, 0xe55a10c2)                              \
  V(::, _storeIntPtr, FfiStoreIntPtr, 0xc75ef10f)                              \
  V(::, _storeFloat, FfiStoreFloat, 0x34a22e07)                                \
  V(::, _storeDouble, FfiStoreDouble, 0x09226ca7)                              \
  V(::, _storePointer, FfiStorePointer, 0x3c7143a8)                            \
  V(::, _fromAddress, FfiFromAddress, 0x612a64d5)                              \
  V(Pointer, get:address, FfiGetAddress, 0x29a505a1)                           \
  V(::, reachabilityFence, ReachabilityFence, 0x0)                             \
  V(_Utf8Decoder, _scan, Utf8DecoderScan, 0x78f44c3c)                          \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 0x2f002cba)                                        \
  V(_Smi, get:bitLength, Smi_bitLength, 0x277b8ace)                            \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, 0x90b94dd3)                       \
  V(_BigIntImpl, _lsh, Bigint_lsh, 0x776e33c7)                                 \
  V(_BigIntImpl, _rsh, Bigint_rsh, 0x2bf277fc)                                 \
  V(_BigIntImpl, _absAdd, Bigint_absAdd, 0x147eb8ec)                           \
  V(_BigIntImpl, _absSub, Bigint_absSub, 0xed4c4e74)                           \
  V(_BigIntImpl, _mulAdd, Bigint_mulAdd, 0x634f75a0)                           \
  V(_BigIntImpl, _sqrAdd, Bigint_sqrAdd, 0xc0a29ed4)                           \
  V(_BigIntImpl, _estimateQuotientDigit, Bigint_estimateQuotientDigit,         \
    0x03b20399)                                                                \
  V(_BigIntMontgomeryReduction, _mulMod, Montgomery_mulMod, 0x3b707797)        \
  V(_Double, >, Double_greaterThan, 0x682a02bc)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x2961f8ee)                          \
  V(_Double, <, Double_lessThan, 0xcbff42e5)                                   \
  V(_Double, <=, Double_lessEqualThan, 0xd2253d90)                             \
  V(_Double, ==, Double_equal, 0x6a306911)                                     \
  V(_Double, +, Double_add, 0xf7d8da94)                                        \
  V(_Double, -, Double_sub, 0xc8dda725)                                        \
  V(_Double, *, Double_mul, 0x2dac85a2)                                        \
  V(_Double, /, Double_div, 0x6cf1f09e)                                        \
  V(_Double, get:hashCode, Double_hashCode, 0x22a75218)                        \
  V(_Double, get:_identityHashCode, Double_identityHash, 0xf46be6d6)           \
  V(_Double, get:isNaN, Double_getIsNaN, 0xb177a8f6)                           \
  V(_Double, get:isInfinite, Double_getIsInfinite, 0xa1e96db5)                 \
  V(_Double, get:isNegative, Double_getIsNegative, 0xb15ff274)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 0xe2853768)               \
  V(_Double, .fromInteger, DoubleFromInteger, 0x89504536)                      \
  V(_GrowableList, ._withData, GrowableArray_Allocate, 0x5cfd6a7f)             \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 0xb961fc8d)                   \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, 0xb22daf53)       \
  V(Object, ==, ObjectEquals, 0x91ead0d6)                                      \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x8cdba093)                    \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, 0xcee5d65a)       \
  V(_StringBase, get:hashCode, String_getHashCode, 0x22a75237)                 \
  V(_StringBase, get:_identityHashCode, String_identityHash, 0xf46be6f5)       \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 0xd7218394)                   \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 0x46fc3731)    \
  V(_StringBase, [], StringBaseCharAt, 0xe67164fe)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 0x22a75237)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked,  0x94c41563)                             \
  V(_OneByteString, ==, OneByteString_equality, 0xe1ea0c11)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 0xe1ea0c11)                    \
  V(_Type, get:hashCode, Type_getHashCode, 0x22a75237)                         \
  V(_Type, ==, Type_equality, 0x91ead098)                                      \
  V(::, _getHash, Object_getHash, 0xb05aa13f)                                  \
  V(::, _setHash, Object_setHash, 0xcb404dd2)                                  \

#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    0xc7bd74ae)                                                                \
  V(_IntegerImplementation, +, Integer_add, 0x49774600)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    0x8e0de2a2)                                                                \
  V(_IntegerImplementation, -, Integer_sub, 0x1a853bf1)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    0x95751a41)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 0xefe7fbce)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    0xbc75fece)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x42d9b723)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0xdb5f0d70)                \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    0xb7e724d2)                                                                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0xd9888ca4)                     \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    0xa97501aa)                                                                \
  V(_IntegerImplementation, |, Integer_bitOr, 0xc82cc85c)                      \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    0x9ab4d16e)                                                                \
  V(_IntegerImplementation, ^, Integer_bitXor, 0xc1ed9463)                     \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, 0x3366ff66)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 0xe74b678c)                \
  V(_IntegerImplementation, ==, Integer_equal, 0xdf47652c)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    0x39d3cd05)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 0xcbff42e5)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0xd2253d90)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x2961f8ee)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x972a7fd6)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0xfe022e7b)                       \
  V(_Double, toInt, DoubleToInteger, 0x14433ded)                               \

#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 0x2c20a879)                                            \
  V(_Random, _nextState, Random_nextState, 0x30682e3d)                         \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, 0x18e743c0)                                              \
  V(::, cos, MathCos, 0x6623c0ce)                                              \
  V(::, tan, MathTan, 0x3584ee62)                                              \
  V(::, asin, MathAsin, 0xb023f0df)                                            \
  V(::, acos, MathAcos, 0x165661fa)                                            \
  V(::, atan, MathAtan, 0xc91eca17)                                            \
  V(::, atan2, MathAtan2, 0x79b3a5e6)                                          \

#define TYPED_DATA_LIB_INTRINSIC_LIST(V)                                       \
  V(Int8List, ., TypedData_Int8Array_factory, 0x6ce2f102)                      \
  V(Uint8List, ., TypedData_Uint8Array_factory, 0x1163d489)                    \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory, 0x0b0e9f0f)      \
  V(Int16List, ., TypedData_Int16Array_factory, 0x6addd02d)                    \
  V(Uint16List, ., TypedData_Uint16Array_factory, 0x139a6464)                  \
  V(Int32List, ., TypedData_Int32Array_factory, 0x40dad19a)                    \
  V(Uint32List, ., TypedData_Uint32Array_factory, 0x988357c5)                  \
  V(Int64List, ., TypedData_Int64Array_factory, 0xef0a3469)                    \
  V(Uint64List, ., TypedData_Uint64Array_factory, 0xf49c0472)                  \
  V(Float32List, ., TypedData_Float32Array_factory, 0x779b26f8)                \
  V(Float64List, ., TypedData_Float64Array_factory, 0xf623554b)                \
  V(Float32x4List, ., TypedData_Float32x4Array_factory, 0x9edf5402)            \
  V(Int32x4List, ., TypedData_Int32x4Array_factory, 0x915e8e68)                \
  V(Float64x2List, ., TypedData_Float64x2Array_factory, 0x0d206864)            \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, 0xdab47d5d)                            \
  V(_Int8List, []=, Int8ArraySetIndexed, 0x09ba0f32)                           \
  V(_Uint8List, [], Uint8ArrayGetIndexed, 0xa9468b1d)                          \
  V(_Uint8List, []=, Uint8ArraySetIndexed, 0xa6fd9dce)                         \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 0xa9468b1d)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 0xa6fd9dce)        \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 0xa9468b1d)            \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 0x7d60b42e)           \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    0xa9468b1d)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    0x7d60b42e)                                                                \
  V(_Int16List, [], Int16ArrayGetIndexed, 0x2b783e9d)                          \
  V(_Int16List, []=, Int16ArraySetIndexed, 0x894edd67)                         \
  V(_Uint16List, [], Uint16ArrayGetIndexed, 0x3d599bdd)                        \
  V(_Uint16List, []=, Uint16ArraySetIndexed, 0x146065d0)                       \
  V(_Int32List, [], Int32ArrayGetIndexed, 0x645ac57e)                          \
  V(_Int32List, []=, Int32ArraySetIndexed, 0x58343408)                         \
  V(_Uint32List, [], Uint32ArrayGetIndexed, 0xe6f6183e)                        \
  V(_Uint32List, []=, Uint32ArraySetIndexed, 0x7ee99568)                       \
  V(_Int64List, [], Int64ArrayGetIndexed, 0x57d917de)                          \
  V(_Int64List, []=, Int64ArraySetIndexed, 0x94485c32)                         \
  V(_Uint64List, [], Uint64ArrayGetIndexed, 0x7fb017de)                        \
  V(_Uint64List, []=, Uint64ArraySetIndexed, 0x1c695796)                       \
  V(_Float64List, [], Float64ArrayGetIndexed, 0x9e20a2c3)                      \
  V(_Float64List, []=, Float64ArraySetIndexed, 0xcd01ec0c)                     \
  V(_Float32List, [], Float32ArrayGetIndexed, 0x7c01bb83)                      \
  V(_Float32List, []=, Float32ArraySetIndexed, 0xcb87f800)                     \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, 0x5a2a83fc)                  \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, 0x5ae5c9f3)                 \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, 0x05ef16d4)                      \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, 0x2e8437b1)                     \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, 0xe7fbf246)                  \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, 0xce826d19)                 \
  V(_TypedList, get:length, TypedListLength, 0x05176aac)                       \
  V(_TypedListView, get:length, TypedListViewLength, 0x05176aac)               \
  V(_ByteDataView, get:length, ByteDataViewLength, 0x05176aac)                 \
  V(_Float32x4, get:x, Float32x4ShuffleX, 0x00b83193)                          \
  V(_Float32x4, get:y, Float32x4ShuffleY, 0xee498cb6)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 0x2414f84c)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 0x06553cce)                          \
  V(_Float32x4, *, Float32x4Mul, 0xf817cb64)                                   \
  V(_Float32x4, /, Float32x4Div, 0xd36681e1)                                   \
  V(_Float32x4, -, Float32x4Sub, 0xeff9bb27)                                   \
  V(_Float32x4, +, Float32x4Add, 0xcac0f0b6)                                   \
  V(_Float64x2, *, Float64x2Mul, 0x589c7905)                                   \
  V(_Float64x2, /, Float64x2Div, 0x33eb2fa1)                                   \
  V(_Float64x2, -, Float64x2Sub, 0x507e68c8)                                   \
  V(_Float64x2, +, Float64x2Add, 0x2b459e57)                                   \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 0x05176aac)                          \
  V(_List, [], ObjectArrayGetIndexed, 0x7e13418e)                              \
  V(_List, _setIndexed, ObjectArraySetIndexedUnchecked, 0x91b2c203)            \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x05176aac)              \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 0x7e13418e)                  \
  V(_GrowableList, get:length, GrowableArrayLength, 0x05176aac)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x2a661633)           \
  V(_GrowableList, _setData, GrowableArraySetData, 0x9e2350fe)                 \
  V(_GrowableList, _setLength, GrowableArraySetLength, 0x8d94d91d)             \
  V(_GrowableList, [], GrowableArrayGetIndexed, 0x7e13418e)                    \
  V(_GrowableList, _setIndexed, GrowableArraySetIndexedUnchecked, 0x91b2c203)  \
  V(_StringBase, get:length, StringBaseLength, 0x05176aac)                     \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, 0xb0959953)           \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, 0xb0959953)           \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    0xb0959953)                                                                \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    0xb0959953)                                                                \
  V(_Double, unary-, DoubleFlipSignBit, 0x039c6e4a)                            \
  V(_Double, truncateToDouble, DoubleTruncate, 0x2960d21d)                     \
  V(_Double, roundToDouble, DoubleRound, 0x1cd615c4)                           \
  V(_Double, floorToDouble, DoubleFloor, 0x1b41170c)                           \
  V(_Double, ceilToDouble, DoubleCeil, 0x25a81a9d)                             \
  V(_Double, _modulo, DoubleMod, 0x42a93471)

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 0x472d1eb5)                    \
  V(::, _getDefaultTag, UserTag_defaultTag, 0x5c124271)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 0x5d6d8a14)                    \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, 0xcf6f3099)        \

#define ASYNC_LIB_INTRINSIC_LIST(V)                                            \
  V(::, _clearAsyncThreadStackTrace, ClearAsyncThreadStackTrace, 0x341efd8e)   \
  V(::, _setAsyncThreadStackTrace, SetAsyncThreadStackTrace, 0x5f29f453)       \

#define INTERNAL_LIB_INTRINSIC_LIST(V)                                         \
  V(::, allocateOneByteString, AllocateOneByteString, 0x3e7f209a)              \
  V(::, allocateTwoByteString, AllocateTwoByteString, 0x46445c37)              \
  V(::, writeIntoOneByteString, WriteIntoOneByteString, 0x63d30528)            \
  V(::, writeIntoTwoByteString, WriteIntoTwoByteString, 0x5b280bf1)            \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  ASYNC_LIB_INTRINSIC_LIST(V)                                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  DEVELOPER_LIB_INTRINSIC_LIST(V)                                              \
  INTERNAL_LIB_INTRINSIC_LIST(V)                                               \
  MATH_LIB_INTRINSIC_LIST(V)                                                   \
  TYPED_DATA_LIB_INTRINSIC_LIST(V)                                             \

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0xe67164fe)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0xa24c2704)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0xa491df3e)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0xb65ae1fc)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0xb4b776e5)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0xb460abe4)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x8c066c71)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xacf2f222)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0xa74b200b)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xa33a9f77)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0x87d86b60)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x3e76086e)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0xfea5f17f)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xd2c4e74b)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0xec62b082)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xc3566903)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0xdb50780f)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xbeeeea8a)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xca02f10a)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xcf587ccf)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xe01a1df0)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0xb6a6294f)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0xce7dad17)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x4b773b59)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xfa2a6f88)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x8cdba093)

// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x03ddbd3a)                             \
  V(_ListFilledFactory, _List, .filled, kArrayCid, 0x0)                        \
  V(_GrowableListWithData, _GrowableList, ._withData, kGrowableObjectArrayCid, \
    0x5cfd6a7f)                                                                \
  V(_GrowableListFilledFactory, _GrowableList, .filled,                        \
    kGrowableObjectArrayCid, 0x0)                                              \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0x3eed680b)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x6ce2f102)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x1163d489)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x0b0e9f0f)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x6addd02d)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x139a6464)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x40dad19a)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0x988357c5)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0xef0a3469)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0xf49c0472)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0xf623554b)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0x779b26f8)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0x9edf5402)

// clang-format on

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
