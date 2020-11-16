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
  V(::, identical, ObjectIdentical, 0x8fd6ea77)                                \
  V(ClassID, getID, ClassIDgetID, 0x0401ffad)                                  \
  V(Object, Object., ObjectConstructor, 0x89c467da)                            \
  V(List, ., ListFactory, 0xbec87d52)                                          \
  V(_List, ., ObjectArrayAllocate, 0x6de199c0)                                 \
  V(_List, []=, ObjectArraySetIndexed, 0xba1597ae)                             \
  V(_GrowableList, []=, GrowableArraySetIndexed, 0xba1597ae)                   \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0xc28aff56)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0xc3e7214c)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0xdaa7b971)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0xdc2919db)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0xc57f53ce)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0xc5c4953f)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xa2c7e6c3)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0xd8c2a01d)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xaf15f2a9)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xbe4987d6)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x76c82c47)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x29abed6d)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xfc13ada6)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 0xc9e4214c)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xd570aa2b)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 0xe8acb253)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xd8651544)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xd3f10db6)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xe357b97e)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xf4d19c09)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0xd6272664)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0xca4af156)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x71767f9e)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xf048329f)              \
  V(ByteData, ., ByteDataFactory, 0x63fefa6a)                                  \
  V(_ByteDataView, get:offsetInBytes, ByteDataViewOffsetInBytes, 0xe51b928a)   \
  V(_ByteDataView, get:_typedData, ByteDataViewTypedData, 0x3c781fd8)          \
  V(_TypedListView, get:offsetInBytes, TypedDataViewOffsetInBytes, 0xe51b928a) \
  V(_TypedListView, get:_typedData, TypedDataViewTypedData, 0x3c781fd8)        \
  V(_ByteDataView, ._, TypedData_ByteDataView_factory, 0xe9e9daf8)             \
  V(_Int8ArrayView, ._, TypedData_Int8ArrayView_factory, 0x016014c6)           \
  V(_Uint8ArrayView, ._, TypedData_Uint8ArrayView_factory, 0x8c3fc251)         \
  V(_Uint8ClampedArrayView, ._, TypedData_Uint8ClampedArrayView_factory,       \
    0x36da9725)                                                                \
  V(_Int16ArrayView, ._, TypedData_Int16ArrayView_factory, 0x09a36717)         \
  V(_Uint16ArrayView, ._, TypedData_Uint16ArrayView_factory, 0x8f74c32e)       \
  V(_Int32ArrayView, ._, TypedData_Int32ArrayView_factory, 0x8c100d35)         \
  V(_Uint32ArrayView, ._, TypedData_Uint32ArrayView_factory, 0x4f7f075d)       \
  V(_Int64ArrayView, ._, TypedData_Int64ArrayView_factory, 0xb85546eb)         \
  V(_Uint64ArrayView, ._, TypedData_Uint64ArrayView_factory, 0x019c22b9)       \
  V(_Float32ArrayView, ._, TypedData_Float32ArrayView_factory, 0x2290e5c0)     \
  V(_Float64ArrayView, ._, TypedData_Float64ArrayView_factory, 0xbe62c753)     \
  V(_Float32x4ArrayView, ._, TypedData_Float32x4ArrayView_factory, 0x5bb7773c) \
  V(_Int32x4ArrayView, ._, TypedData_Int32x4ArrayView_factory, 0x30b9f2c1)     \
  V(_Float64x2ArrayView, ._, TypedData_Float64x2ArrayView_factory, 0x96490d20) \
  V(Int8List, ., TypedData_Int8Array_factory, 0x80ad8400)                      \
  V(Uint8List, ., TypedData_Uint8Array_factory, 0x252e6787)                    \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory, 0x1ed9320d)      \
  V(Int16List, ., TypedData_Int16Array_factory, 0x7ea8632b)                    \
  V(Uint16List, ., TypedData_Uint16Array_factory, 0x2764f762)                  \
  V(Int32List, ., TypedData_Int32Array_factory, 0x54a56498)                    \
  V(Uint32List, ., TypedData_Uint32Array_factory, 0xac4deac3)                  \
  V(Int64List, ., TypedData_Int64Array_factory, 0x02d4c767)                    \
  V(Uint64List, ., TypedData_Uint64Array_factory, 0x08669770)                  \
  V(Float32List, ., TypedData_Float32Array_factory, 0x8b65b9f6)                \
  V(Float64List, ., TypedData_Float64Array_factory, 0x09ede849)                \
  V(Float32x4List, ., TypedData_Float32x4Array_factory, 0xb2a9e700)            \
  V(Int32x4List, ., TypedData_Int32x4Array_factory, 0xa5292166)                \
  V(Float64x2List, ., TypedData_Float64x2Array_factory, 0x20eafb62)            \
  V(::, _toClampedUint8, ConvertIntToClampedUint8, 0x143ed694)                 \
  V(::, copyRangeFromUint8ListToOneByteString,                                 \
    CopyRangeFromUint8ListToOneByteString, 0x89d6a629)                         \
  V(_StringBase, _interpolate, StringBaseInterpolate, 0xd5a58f1b)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 0x5f8db614)             \
  V(_Double, _add, DoubleAdd, 0x43269649)                                      \
  V(_Double, _sub, DoubleSub, 0x81077f50)                                      \
  V(_Double, _mul, DoubleMul, 0x7858fa8e)                                      \
  V(_Double, _div, DoubleDiv, 0x813d6ab3)                                      \
  V(::, min, MathMin, 0xe6a2f523)                                              \
  V(::, max, MathMax, 0x4cfa6f8a)                                              \
  V(::, _doublePow, MathDoublePow, 0x9772a8e0)                                 \
  V(::, _intPow, MathIntPow, 0x65762aa8)                                       \
  V(Float32x4, _Float32x4FromDoubles, Float32x4FromDoubles, 0x4ddbf1ef)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 0x730d829c)                      \
  V(Float32x4, _Float32x4Splat, Float32x4Splat, 0x36ae8807)                    \
  V(Float32x4, Float32x4.fromInt32x4Bits, Int32x4ToFloat32x4, 0x8704459c)      \
  V(Float32x4, Float32x4.fromFloat64x2, Float64x2ToFloat32x4, 0x71ab7a67)      \
  V(_Float32x4, shuffle, Float32x4Shuffle, 0x6f8cd74d)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 0xd9fe42ee)                   \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 0x00b7b98c)                \
  V(_Float32x4, equal, Float32x4Equal, 0x77b31298)                             \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, 0x85a5a2a1)                 \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, 0x81c686d9)   \
  V(_Float32x4, lessThan, Float32x4LessThan, 0x7d70963f)                       \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, 0x79cf7862)         \
  V(_Float32x4, notEqual, Float32x4NotEqual, 0x97a75a65)                       \
  V(_Float32x4, min, Float32x4Min, 0x0ad969b4)                                 \
  V(_Float32x4, max, Float32x4Max, 0xed08eb85)                                 \
  V(_Float32x4, scale, Float32x4Scale, 0xfdf348e4)                             \
  V(_Float32x4, sqrt, Float32x4Sqrt, 0x84853e14)                               \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, 0x7d66359a)           \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, 0x73e065d4)                   \
  V(_Float32x4, unary-, Float32x4Negate, 0x86111e0e)                           \
  V(_Float32x4, abs, Float32x4Abs, 0x8ad4c1aa)                                 \
  V(_Float32x4, clamp, Float32x4Clamp, 0x374a9dbf)                             \
  V(_Float32x4, _withX, Float32x4WithX, 0xfd53a091)                            \
  V(_Float32x4, _withY, Float32x4WithY, 0xf5f5b525)                            \
  V(_Float32x4, _withZ, Float32x4WithZ, 0xf2122f82)                            \
  V(_Float32x4, _withW, Float32x4WithW, 0xef6f233d)                            \
  V(Float64x2, _Float64x2FromDoubles, Float64x2FromDoubles, 0x9688f495)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 0x35f71932)                      \
  V(Float64x2, _Float64x2Splat, Float64x2Splat, 0xf2e6bd08)                    \
  V(Float64x2, Float64x2.fromFloat32x4, Float32x4ToFloat64x2, 0xa936b440)      \
  V(_Float64x2, get:x, Float64x2GetX, 0xd83e57b0)                              \
  V(_Float64x2, get:y, Float64x2GetY, 0xc5cfb2d3)                              \
  V(_Float64x2, unary-, Float64x2Negate, 0x48fab4a4)                           \
  V(_Float64x2, abs, Float64x2Abs, 0x4dbe5840)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 0x476ed4aa)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 0x00b7b98c)                \
  V(_Float64x2, scale, Float64x2Scale, 0xc0dcdf7a)                             \
  V(_Float64x2, _withX, Float64x2WithX, 0xc03d3727)                            \
  V(_Float64x2, _withY, Float64x2WithY, 0xb8df4bbb)                            \
  V(_Float64x2, min, Float64x2Min,  0x6b5e1774)                                \
  V(_Float64x2, max, Float64x2Max,  0x4d8d9945)                                \
  V(Int32x4, _Int32x4FromInts, Int32x4FromInts, 0xa646ec74)                    \
  V(Int32x4, _Int32x4FromBools, Int32x4FromBools, 0x5e05bf0c)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4, 0x789399bb)        \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 0x7713cbd8)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 0x928402b8)                          \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 0xa02d9e0b)                          \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 0xa94db04c)                          \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 0x00b7b98c)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 0x149a8b35)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 0xd017e8be)                       \
  V(_Int32x4, select, Int32x4Select, 0x2847cb82)                               \
  V(_Int32x4, _withFlagX, Int32x4WithFlagX, 0xa365d5c5)                        \
  V(_Int32x4, _withFlagY, Int32x4WithFlagY, 0x94567108)                        \
  V(_Int32x4, _withFlagZ, Int32x4WithFlagZ, 0x938c5db6)                        \
  V(_Int32x4, _withFlagW, Int32x4WithFlagW, 0x9ebaceba)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0xe16143ba)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0x8c8999b6)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0xb1d03a0b)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x7c713c87)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0xcb55344b)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0x4b6bbbc7)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0xd35b67fa)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0x5371ef76)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0xd55a64fe)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0x5570ec7a)   \
  V(::, _classRangeCheck, ClassRangeCheck, 0x5ee76890)                         \
  V(::, _asyncStackTraceHelper, AsyncStackTraceHelper, 0x92cea93f)             \
  V(::, _abi, FfiAbi, 0x00a48df9)                                              \
  V(::, _asFunctionInternal, FfiAsFunctionInternal, 0x4ea3f680)                \
  V(::, _nativeCallbackFunction, FfiNativeCallbackFunction, 0xe7a60d02)        \
  V(::, _loadInt8, FfiLoadInt8, 0x7b779ef2)                                    \
  V(::, _loadInt16, FfiLoadInt16, 0x58b6f049)                                  \
  V(::, _loadInt32, FfiLoadInt32, 0x5a94fedf)                                  \
  V(::, _loadInt64, FfiLoadInt64, 0x4b627ebf)                                  \
  V(::, _loadUint8, FfiLoadUint8, 0x4dc0dbed)                                  \
  V(::, _loadUint16, FfiLoadUint16, 0x79491c06)                                \
  V(::, _loadUint32, FfiLoadUint32, 0x62e14f71)                                \
  V(::, _loadUint64, FfiLoadUint64, 0x7178bce8)                                \
  V(::, _loadIntPtr, FfiLoadIntPtr, 0x584c735a)                                \
  V(::, _loadFloat, FfiLoadFloat, 0x7f0471f9)                                  \
  V(::, _loadDouble, FfiLoadDouble, 0x7d37b3b5)                                \
  V(::, _loadPointer, FfiLoadPointer, 0x3691c06c)                              \
  V(::, _storeInt8, FfiStoreInt8, 0x118e5be8)                                  \
  V(::, _storeInt16, FfiStoreInt16, 0x0a8ba00e)                                \
  V(::, _storeInt32, FfiStoreInt32, 0x2e23d939)                                \
  V(::, _storeInt64, FfiStoreInt64, 0x2411ba56)                                \
  V(::, _storeUint8, FfiStoreUint8, 0x37ab7fd2)                                \
  V(::, _storeUint16, FfiStoreUint16, 0x153b57ba)                              \
  V(::, _storeUint32, FfiStoreUint32, 0x181595a1)                              \
  V(::, _storeUint64, FfiStoreUint64, 0x1516df15)                              \
  V(::, _storeIntPtr, FfiStoreIntPtr, 0x3a401384)                              \
  V(::, _storeFloat, FfiStoreFloat, 0x23292bda)                                \
  V(::, _storeDouble, FfiStoreDouble, 0x013dc7c0)                              \
  V(::, _storePointer, FfiStorePointer, 0x43c38f81)                            \
  V(::, _fromAddress, FfiFromAddress, 0xab4ae572)                              \
  V(Pointer, get:address, FfiGetAddress, 0x012b2bbe)                           \
  V(::, reachabilityFence, ReachabilityFence, 0xad39d0c5)                      \
  V(_Utf8Decoder, _scan, Utf8DecoderScan, 0x288d0097)                          \
  V(_Future, timeout, FutureTimeout, 0xdea67277)                               \
  V(Future, wait, FutureWait, 0x6c0c3295)                                      \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 0x068652d7)                                        \
  V(_Smi, get:bitLength, Smi_bitLength, 0xff01b0eb)                            \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, 0xa483e0b2)                       \
  V(_BigIntImpl, _lsh, Bigint_lsh, 0x772fb61c)                                 \
  V(_BigIntImpl, _rsh, Bigint_rsh, 0xb52a24d7)                                 \
  V(_BigIntImpl, _absAdd, Bigint_absAdd, 0x90dc61c7)                           \
  V(_BigIntImpl, _absSub, Bigint_absSub, 0x7688734f)                           \
  V(_BigIntImpl, _mulAdd, Bigint_mulAdd, 0xb27412b5)                           \
  V(_BigIntImpl, _sqrAdd, Bigint_sqrAdd, 0xcee0faeb)                           \
  V(_BigIntImpl, _estimateQuotientDigit, Bigint_estimateQuotientDigit,         \
    0x14527ef8)                                                                \
  V(_BigIntMontgomeryReduction, _mulMod, Montgomery_mulMod, 0x08df27b4)        \
  V(_Double, >, Double_greaterThan, 0xe88b701b)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x1fb70bcd)                          \
  V(_Double, <, Double_lessThan, 0xae875044)                                   \
  V(_Double, <=, Double_lessEqualThan, 0xc87a506f)                             \
  V(_Double, ==, Double_equal, 0x5299f1f1)                                     \
  V(_Double, +, Double_add, 0x783a47f3)                                        \
  V(_Double, -, Double_sub, 0x493f1484)                                        \
  V(_Double, *, Double_mul, 0xae0df301)                                        \
  V(_Double, /, Double_div, 0xed535dfd)                                        \
  V(_Double, get:hashCode, Double_hashCode, 0xfa2d7835)                        \
  V(_Double, get:_identityHashCode, Double_identityHash, 0xcbf20cf3)           \
  V(_Double, get:isNaN, Double_getIsNaN, 0x88fdcf13)                           \
  V(_Double, get:isInfinite, Double_getIsInfinite, 0x796f93d2)                 \
  V(_Double, get:isNegative, Double_getIsNegative, 0x88e61891)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 0xc5afaa47)               \
  V(_Double, .fromInteger, DoubleFromInteger, 0x9d1ad815)                      \
  V(_GrowableList, ._withData, GrowableArray_Allocate, 0x00be5947)             \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 0x6817558d)                   \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, 0x60e30853)       \
  V(Object, ==, ObjectEquals, 0xbc3cad68)                                      \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x6461c6b0)                    \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, 0xa66bfc77)       \
  V(_StringBase, get:hashCode, String_getHashCode, 0xfa2d7854)                 \
  V(_StringBase, get:_identityHashCode, String_identityHash, 0xcbf20d12)       \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 0xbdfe9cb1)                   \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 0xf5c3c892)    \
  V(_StringBase, [], StringBaseCharAt, 0xfa3bf7dd)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 0xfa2d7854)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked,  0x0d39e4c0)                             \
  V(_OneByteString, ==, OneByteString_equality, 0x3399def0)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 0x3399def0)                    \
  V(_Type, get:hashCode, Type_getHashCode, 0xfa2d7854)                         \
  V(_Type, ==, Type_equality, 0xbc3cad2a)                                      \
  V(::, _getHash, Object_getHash, 0x87e0c75c)                                  \
  V(::, _setHash, Object_setHash, 0xcb4f51f1)                                  \

#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    0xdb88078d)                                                                \
  V(_IntegerImplementation, +, Integer_add, 0x9b2718df)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    0xa1d87581)                                                                \
  V(_IntegerImplementation, -, Integer_sub, 0x6c350ed0)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    0xa93fad20)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 0x4197cead)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    0xd04091ad)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x79adb421)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0xf07a7728)                \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    0xcbb1b7b1)                                                                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x2b385f83)                     \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    0xbd3f9489)                                                                \
  V(_IntegerImplementation, |, Integer_bitOr, 0x19dc9b3b)                      \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    0xae7f644d)                                                                \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x139d6742)                     \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, 0x47319245)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 0xc9d374eb)                \
  V(_IntegerImplementation, ==, Integer_equal, 0xca4e70a6)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    0x4d9e5fe4)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 0xae875044)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0xc87a506f)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x1fb70bcd)          \
  V(_IntegerImplementation, <<, Integer_shl, 0xe8da52b5)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0x4fb2015a)                       \
  V(_Double, toInt, DoubleToInteger, 0xebc9640a)                               \

#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 0x98d7cb58)                                            \
  V(_Random, _nextState, Random_nextState, 0x2c1cf101)                         \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, 0x859e669f)                                              \
  V(::, cos, MathCos, 0xd2dae3ad)                                              \
  V(::, tan, MathTan, 0xa23c1141)                                              \
  V(::, asin, MathAsin, 0x1cdb13be)                                            \
  V(::, acos, MathAcos, 0x830d84d9)                                            \
  V(::, atan, MathAtan, 0x35d5ecf6)                                            \
  V(::, atan2, MathAtan2, 0xb4e03b07)                                          \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, 0xd61e79dc)                            \
  V(_Int8List, []=, Int8ArraySetIndexed, 0x6e0b2e91)                           \
  V(_Uint8List, [], Uint8ArrayGetIndexed, 0xe1a67e1c)                          \
  V(_Uint8List, []=, Uint8ArraySetIndexed, 0x89499a4d)                         \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 0xe1a67e1c)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 0x89499a4d)        \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 0xe1a67e1c)            \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 0x5facb0ad)           \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    0xe1a67e1c)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    0x5facb0ad)                                                                \
  V(_Int16List, [], Int16ArrayGetIndexed, 0x1726ae7c)                          \
  V(_Int16List, []=, Int16ArraySetIndexed, 0xde0f4da6)                         \
  V(_Uint16List, [], Uint16ArrayGetIndexed, 0x26c2527c)                        \
  V(_Uint16List, []=, Uint16ArraySetIndexed, 0x69ae5b4f)                       \
  V(_Int32List, [], Int32ArrayGetIndexed, 0x407e58fd)                          \
  V(_Int32List, []=, Int32ArraySetIndexed, 0x61194127)                         \
  V(_Uint32List, [], Uint32ArrayGetIndexed, 0xf078bf5d)                        \
  V(_Uint32List, []=, Uint32ArraySetIndexed, 0x70f53ca7)                       \
  V(_Int64List, [], Int64ArrayGetIndexed, 0x7c21b6bd)                          \
  V(_Int64List, []=, Int64ArraySetIndexed, 0xcaa7c6e9)                         \
  V(_Uint64List, [], Uint64ArrayGetIndexed, 0x0a7aa13d)                        \
  V(_Uint64List, []=, Uint64ArraySetIndexed, 0xd1374eb1)                       \
  V(_Float64List, [], Float64ArrayGetIndexed, 0x9e4b2422)                      \
  V(_Float64List, []=, Float64ArraySetIndexed, 0x0a43d557)                     \
  V(_Float32List, [], Float32ArrayGetIndexed, 0xbdf87f02)                      \
  V(_Float32List, []=, Float32ArraySetIndexed, 0x2e3e1a69)                     \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, 0xa90520db)                  \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, 0xb9c7402e)                 \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, 0xfbcc0e93)                      \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, 0x79152ace)                     \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, 0xd90a3205)                  \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, 0x4fd1921a)                 \
  V(_TypedList, get:length, TypedListLength, 0xdc9d90c9)                       \
  V(_TypedListView, get:length, TypedListViewLength, 0xdc9d90c9)               \
  V(_ByteDataView, get:length, ByteDataViewLength, 0xdc9d90c9)                 \
  V(_Float32x4, get:x, Float32x4ShuffleX, 0xd83e57b0)                          \
  V(_Float32x4, get:y, Float32x4ShuffleY, 0xc5cfb2d3)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 0xfb9b1e69)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 0xdddb62eb)                          \
  V(_Float32x4, *, Float32x4Mul, 0x0be25e43)                                   \
  V(_Float32x4, /, Float32x4Div, 0xe73114c0)                                   \
  V(_Float32x4, -, Float32x4Sub, 0x03c44e06)                                   \
  V(_Float32x4, +, Float32x4Add, 0xde8b8395)                                   \
  V(_Float64x2, *, Float64x2Mul, 0x6c670be4)                                   \
  V(_Float64x2, /, Float64x2Div, 0x47b5c280)                                   \
  V(_Float64x2, -, Float64x2Sub, 0x6448fba7)                                   \
  V(_Float64x2, +, Float64x2Add, 0x3f103136)                                   \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 0xdc9d90c9)                          \
  V(_List, [], ObjectArrayGetIndexed, 0xd159deed)                              \
  V(_List, _setIndexed, ObjectArraySetIndexedUnchecked, 0xf5780f62)            \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0xdc9d90c9)              \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 0xd159deed)                  \
  V(_GrowableList, get:length, GrowableArrayLength, 0xdc9d90c9)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x01ec3c50)           \
  V(_GrowableList, _setData, GrowableArraySetData, 0x8ecf0a5f)                 \
  V(_GrowableList, _setLength, GrowableArraySetLength, 0x63da77ba)             \
  V(_GrowableList, [], GrowableArrayGetIndexed, 0xd159deed)                    \
  V(_GrowableList, _setIndexed, GrowableArraySetIndexedUnchecked, 0x012e9e43)  \
  V(_StringBase, get:length, StringBaseLength, 0xdc9d90c9)                     \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, 0xc4602c32)           \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, 0xc4602c32)           \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    0xc4602c32)                                                                \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    0xc4602c32)                                                                \
  V(_Double, unary-, DoubleFlipSignBit, 0xdb229467)                            \
  V(_Double, truncateToDouble, DoubleTruncate, 0x00e6f83a)                     \
  V(_Double, roundToDouble, DoubleRound, 0xf45c3be1)                           \
  V(_Double, floorToDouble, DoubleFloor, 0xf2c73d29)                           \
  V(_Double, ceilToDouble, DoubleCeil, 0xfd2e40ba)                             \
  V(_Double, _modulo, DoubleMod, 0x5673c750)

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 0x1eb344d2)                    \
  V(::, _getDefaultTag, UserTag_defaultTag, 0x2ef2e44b)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 0x33c3ec34)                    \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, 0x7dfcaa37)        \

#define ASYNC_LIB_INTRINSIC_LIST(V)                                            \
  V(::, _clearAsyncThreadStackTrace, ClearAsyncThreadStackTrace, 0x20fecae5)   \
  V(::, _setAsyncThreadStackTrace, SetAsyncThreadStackTrace, 0x39346972)       \

#define INTERNAL_LIB_INTRINSIC_LIST(V)                                         \
  V(::, allocateOneByteString, AllocateOneByteString, 0xc86bebfa)              \
  V(::, allocateTwoByteString, AllocateTwoByteString, 0xd0312797)              \
  V(::, writeIntoOneByteString, WriteIntoOneByteString, 0xe0d28307)            \
  V(::, writeIntoTwoByteString, WriteIntoTwoByteString, 0xd82789d0)            \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  ASYNC_LIB_INTRINSIC_LIST(V)                                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  DEVELOPER_LIB_INTRINSIC_LIST(V)                                              \
  INTERNAL_LIB_INTRINSIC_LIST(V)                                               \
  MATH_LIB_INTRINSIC_LIST(V)                                                   \

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0xfa3bf7dd)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0xc28aff56)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0xc3e7214c)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0xdaa7b971)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0xdc2919db)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0xc57f53ce)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0xc5c4953f)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xa2c7e6c3)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0xd8c2a01d)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xaf15f2a9)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xbe4987d6)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0x76c82c47)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x29abed6d)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xfc13ada6)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0xc9e4214c)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xd570aa2b)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0xe8acb253)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xd8651544)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xd3f10db6)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xe357b97e)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xf4d19c09)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0xd6272664)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0xca4af156)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x71767f9e)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xf048329f)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x6461c6b0)

// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x6de199c0)                             \
  V(_ListFilledFactory, _List, .filled, kArrayCid, 0x871c7eb6)                 \
  V(_ListGenerateFactory, _List, .generate, kArrayCid, 0x045b9063)             \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0xdc1f9e09)                                                                \
  V(_GrowableListFilledFactory, _GrowableList, .filled,                        \
    kGrowableObjectArrayCid, 0xbc894d36)                                       \
  V(_GrowableListGenerateFactory, _GrowableList, .generate,                    \
    kGrowableObjectArrayCid, 0xf6fbbee3)                                       \
  V(_GrowableListWithData, _GrowableList, ._withData, kGrowableObjectArrayCid, \
    0x00be5947)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x80ad8400)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x252e6787)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x1ed9320d)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x7ea8632b)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x2764f762)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x54a56498)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0xac4deac3)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0x02d4c767)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0x08669770)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0x09ede849)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0x8b65b9f6)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0xb2a9e700)

// clang-format on

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
