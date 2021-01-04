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
  V(::, identical, ObjectIdentical, 0x19eb7f33)                                \
  V(ClassID, getID, ClassIDgetID, 0x4d140cb3)                                  \
  V(Object, Object., ObjectConstructor, 0x89c467da)                            \
  V(List, ., ListFactory, 0x1892cc51)                                          \
  V(_List, ., ObjectArrayAllocate, 0x4c9d39e2)                                 \
  V(_List, []=, ObjectArraySetIndexed, 0xa06ee8ae)                             \
  V(_GrowableList, []=, GrowableArraySetIndexed, 0xa06ee8ae)                   \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x30688af4)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x31c4acea)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x4885450f)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x4a06a579)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x335cdbca)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x33a21d3b)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0x10a56ebf)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0x46a02819)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xe425bcd3)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xf3595200)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0xb3cc1803)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0xbe4aee59)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x89b17e2a)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 0x5781f1d0)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x630e7aaf)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 0x764a82d7)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x6602e5c8)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x618ede3a)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0x70f58a02)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0x826f6c8d)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x2761c274)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x1b858d66)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x9e2320c0)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xfa1f5cf1)              \
  V(ByteData, ., ByteDataFactory, 0x1a2bee78)                                  \
  V(_ByteDataView, get:offsetInBytes, ByteDataViewOffsetInBytes, 0x3915c92a)   \
  V(_ByteDataView, get:_typedData, ByteDataViewTypedData, 0x487f857c)          \
  V(_TypedListView, get:offsetInBytes, TypedDataViewOffsetInBytes, 0x3915c92a) \
  V(_TypedListView, get:_typedData, TypedDataViewTypedData, 0x487f857c)        \
  V(_ByteDataView, ._, TypedData_ByteDataView_factory, 0xbdff93f4)             \
  V(_Int8ArrayView, ._, TypedData_Int8ArrayView_factory, 0x955093e6)           \
  V(_Uint8ArrayView, ._, TypedData_Uint8ArrayView_factory, 0x666697bb)         \
  V(_Uint8ClampedArrayView, ._, TypedData_Uint8ClampedArrayView_factory,       \
    0x0f265d67)                                                                \
  V(_Int16ArrayView, ._, TypedData_Int16ArrayView_factory, 0x95778bb5)         \
  V(_Uint16ArrayView, ._, TypedData_Uint16ArrayView_factory, 0xc9d1b27e)       \
  V(_Int32ArrayView, ._, TypedData_Int32ArrayView_factory, 0x609fa957)         \
  V(_Uint32ArrayView, ._, TypedData_Uint32ArrayView_factory, 0x0b0ff42f)       \
  V(_Int64ArrayView, ._, TypedData_Int64ArrayView_factory, 0xbd01a661)         \
  V(_Uint64ArrayView, ._, TypedData_Uint64ArrayView_factory, 0x9c964453)       \
  V(_Float32ArrayView, ._, TypedData_Float32ArrayView_factory, 0x9a39e22c)     \
  V(_Float64ArrayView, ._, TypedData_Float64ArrayView_factory, 0x78a432f9)     \
  V(_Float32x4ArrayView, ._, TypedData_Float32x4ArrayView_factory, 0x85e58030) \
  V(_Int32x4ArrayView, ._, TypedData_Int32x4ArrayView_factory, 0x5132754b)     \
  V(_Float64x2ArrayView, ._, TypedData_Float64x2ArrayView_factory, 0x9d86a6cc) \
  V(Int8List, ., TypedData_Int8Array_factory, 0x934e97a2)                      \
  V(Uint8List, ., TypedData_Uint8Array_factory, 0x7eea24fb)                    \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory, 0xba98ab35)      \
  V(Int16List, ., TypedData_Int16Array_factory, 0x54af9dd7)                    \
  V(Uint16List, ., TypedData_Uint16Array_factory, 0xc3859080)                  \
  V(Int32List, ., TypedData_Int32Array_factory, 0x3e52ca0a)                    \
  V(Uint32List, ., TypedData_Uint32Array_factory, 0xdbbb093f)                  \
  V(Int64List, ., TypedData_Int64Array_factory, 0x560fc11b)                    \
  V(Uint64List, ., TypedData_Uint64Array_factory, 0x02b7f232)                  \
  V(Float32List, ., TypedData_Float32Array_factory, 0xdf9d206c)                \
  V(Float64List, ., TypedData_Float64Array_factory, 0x321abc79)                \
  V(Float32x4List, ., TypedData_Float32x4Array_factory, 0xa0de94a2)            \
  V(Int32x4List, ., TypedData_Int32x4Array_factory, 0xfe46a6fc)                \
  V(Float64x2List, ., TypedData_Float64x2Array_factory, 0xfac00c80)            \
  V(::, _toClampedUint8, ConvertIntToClampedUint8, 0x84e4b390)                 \
  V(::, copyRangeFromUint8ListToOneByteString,                                 \
    CopyRangeFromUint8ListToOneByteString, 0xeb5abaa9)                         \
  V(_StringBase, _interpolate, StringBaseInterpolate, 0xe8ece5a1)              \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 0x33d887fc)             \
  V(_Double, _add, DoubleAdd, 0x1ba15967)                                      \
  V(_Double, _sub, DoubleSub, 0x5982426e)                                      \
  V(_Double, _mul, DoubleMul, 0x50d3bdac)                                      \
  V(_Double, _div, DoubleDiv, 0x59b82dd1)                                      \
  V(::, min, MathMin, 0xa24c3a83)                                              \
  V(::, max, MathMax, 0x8552d67e)                                              \
  V(::, _doublePow, MathDoublePow, 0x9441cc3a)                                 \
  V(::, _intPow, MathIntPow, 0x409dd978)                                       \
  V(Float32x4, _Float32x4FromDoubles, Float32x4FromDoubles, 0x790497df)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 0x9657735e)                      \
  V(Float32x4, _Float32x4Splat, Float32x4Splat, 0xb0d7702d)                    \
  V(Float32x4, Float32x4.fromInt32x4Bits, Int32x4ToFloat32x4, 0xda38dd92)      \
  V(Float32x4, Float32x4.fromFloat64x2, Float64x2ToFloat32x4, 0xe41a2079)      \
  V(_Float32x4, shuffle, Float32x4Shuffle, 0xac90c309)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 0x3d6d7e46)                   \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 0x54b1e8e8)                \
  V(_Float32x4, equal, Float32x4Equal, 0xc9591626)                             \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, 0xd74ba62f)                 \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, 0xd36c8a67)   \
  V(_Float32x4, lessThan, Float32x4LessThan, 0xcf1699cd)                       \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, 0xcb757bf0)         \
  V(_Float32x4, notEqual, Float32x4NotEqual, 0xe94d5df3)                       \
  V(_Float32x4, min, Float32x4Min, 0x04e45812)                                 \
  V(_Float32x4, max, Float32x4Max, 0xe713d9e3)                                 \
  V(_Float32x4, scale, Float32x4Scale, 0xde622d94)                             \
  V(_Float32x4, sqrt, Float32x4Sqrt, 0xa7982e0e)                               \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, 0xa0792594)           \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, 0x96f355ce)                   \
  V(_Float32x4, unary-, Float32x4Negate, 0xa94cf76e)                           \
  V(_Float32x4, abs, Float32x4Abs, 0xade7b1a4)                                 \
  V(_Float32x4, clamp, Float32x4Clamp, 0x57c0dbb9)                             \
  V(_Float32x4, _withX, Float32x4WithX, 0xddc28541)                            \
  V(_Float32x4, _withY, Float32x4WithY, 0xd66499d5)                            \
  V(_Float32x4, _withZ, Float32x4WithZ, 0xd2811432)                            \
  V(_Float32x4, _withW, Float32x4WithW, 0xcfde07ed)                            \
  V(Float64x2, _Float64x2FromDoubles, Float64x2FromDoubles, 0x9f0a0865)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 0x30a0af88)                      \
  V(Float64x2, _Float64x2Splat, Float64x2Splat, 0xe169544e)                    \
  V(Float64x2, Float64x2.fromFloat32x4, Float32x4ToFloat64x2, 0x7ad848fa)      \
  V(_Float64x2, get:x, Float64x2GetX, 0xf36ac93a)                              \
  V(_Float64x2, get:y, Float64x2GetY, 0xe0fc245d)                              \
  V(_Float64x2, unary-, Float64x2Negate, 0x43963398)                           \
  V(_Float64x2, abs, Float64x2Abs, 0x4830edce)                                 \
  V(_Float64x2, sqrt, Float64x2Sqrt, 0x41e16a38)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 0x54b1e8e8)                \
  V(_Float64x2, scale, Float64x2Scale, 0x78ab69be)                             \
  V(_Float64x2, _withX, Float64x2WithX, 0x780bc16b)                            \
  V(_Float64x2, _withY, Float64x2WithY, 0x70add5ff)                            \
  V(_Float64x2, min, Float64x2Min,  0xb4f56252)                                \
  V(_Float64x2, max, Float64x2Max,  0x9724e423)                                \
  V(Int32x4, _Int32x4FromInts, Int32x4FromInts, 0x533214b0)                    \
  V(Int32x4, _Int32x4FromBools, Int32x4FromBools, 0x17964f48)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4, 0xca709e11)        \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 0x998cbdb6)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 0xb4fcf496)                          \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 0xc2a68fe9)                          \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 0xcbc6a22a)                          \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 0x54b1e8e8)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 0xa9398c21)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 0x0a889276)                       \
  V(_Int32x4, select, Int32x4Select, 0x48be097c)                               \
  V(_Int32x4, _withFlagX, Int32x4WithFlagX, 0x7f4a63d1)                        \
  V(_Int32x4, _withFlagY, Int32x4WithFlagY, 0x703aff14)                        \
  V(_Int32x4, _withFlagZ, Int32x4WithFlagZ, 0x6f70ebc2)                        \
  V(_Int32x4, _withFlagW, Int32x4WithFlagW, 0x7a9f5cc6)                        \
  V(_HashVMBase, get:_index, LinkedHashMap_getIndex, 0xf6b408ce)               \
  V(_HashVMBase, set:_index, LinkedHashMap_setIndex, 0xb0967252)               \
  V(_HashVMBase, get:_data, LinkedHashMap_getData, 0xe81ec483)                 \
  V(_HashVMBase, set:_data, LinkedHashMap_setData, 0x719e1187)                 \
  V(_HashVMBase, get:_usedData, LinkedHashMap_getUsedData, 0x1f4f6aeb)         \
  V(_HashVMBase, set:_usedData, LinkedHashMap_setUsedData, 0xa209d2ef)         \
  V(_HashVMBase, get:_hashMask, LinkedHashMap_getHashMask, 0x27559e9a)         \
  V(_HashVMBase, set:_hashMask, LinkedHashMap_setHashMask, 0xaa10069e)         \
  V(_HashVMBase, get:_deletedKeys, LinkedHashMap_getDeletedKeys, 0x29549b9e)   \
  V(_HashVMBase, set:_deletedKeys, LinkedHashMap_setDeletedKeys, 0xac0f03a2)   \
  V(_WeakProperty, get:key, WeakProperty_getKey, 0x16b8624c)                   \
  V(_WeakProperty, set:key, WeakProperty_setKey, 0x8b5df091)                   \
  V(_WeakProperty, get:value, WeakProperty_getValue, 0x0baa0898)               \
  V(_WeakProperty, set:value, WeakProperty_setValue, 0x804f96dd)               \
  V(::, _classRangeCheck, ClassRangeCheck, 0x071d2ec8)                         \
  V(::, _abi, FfiAbi, 0x54918e73)                                              \
  V(::, _asFunctionInternal, FfiAsFunctionInternal, 0x2d4e5e32)                \
  V(::, _nativeCallbackFunction, FfiNativeCallbackFunction, 0x68db1afc)        \
  V(::, _loadInt8, FfiLoadInt8, 0x3b38d254)                                    \
  V(::, _loadInt16, FfiLoadInt16, 0x187823ab)                                  \
  V(::, _loadInt32, FfiLoadInt32, 0x1a563241)                                  \
  V(::, _loadInt64, FfiLoadInt64, 0x0b23b221)                                  \
  V(::, _loadUint8, FfiLoadUint8, 0x0d820f4f)                                  \
  V(::, _loadUint16, FfiLoadUint16, 0x390a4f68)                                \
  V(::, _loadUint32, FfiLoadUint32, 0x22a282d3)                                \
  V(::, _loadUint64, FfiLoadUint64, 0x3139f04a)                                \
  V(::, _loadIntPtr, FfiLoadIntPtr, 0x180da6bc)                                \
  V(::, _loadFloat, FfiLoadFloat, 0x05f7e3e7)                                  \
  V(::, _loadDouble, FfiLoadDouble, 0x042b25a3)                                \
  V(::, _loadPointer, FfiLoadPointer, 0x117833fa)                              \
  V(::, _storeInt8, FfiStoreInt8, 0xdaa635d2)                                  \
  V(::, _storeInt16, FfiStoreInt16, 0xd3a379f8)                                \
  V(::, _storeInt32, FfiStoreInt32, 0xf73bb323)                                \
  V(::, _storeInt64, FfiStoreInt64, 0xed299440)                                \
  V(::, _storeUint8, FfiStoreUint8, 0x00c359bc)                                \
  V(::, _storeUint16, FfiStoreUint16, 0xde5331a4)                              \
  V(::, _storeUint32, FfiStoreUint32, 0xe12d6f8b)                              \
  V(::, _storeUint64, FfiStoreUint64, 0xde2eb8ff)                              \
  V(::, _storeIntPtr, FfiStoreIntPtr, 0x0357ed6e)                              \
  V(::, _storeFloat, FfiStoreFloat, 0xafddd150)                                \
  V(::, _storeDouble, FfiStoreDouble, 0x8df26d36)                              \
  V(::, _storePointer, FfiStorePointer, 0xf3b14e97)                            \
  V(::, _fromAddress, FfiFromAddress, 0x811e2220)                              \
  V(Pointer, get:address, FfiGetAddress, 0x55255ebc)                           \
  V(::, reachabilityFence, ReachabilityFence, 0xde1dc5bd)                      \
  V(_Utf8Decoder, _scan, Utf8DecoderScan, 0xb35ced99)                          \
  V(_Future, timeout, FutureTimeout, 0x6ad7d1ef)                               \
  V(Future, wait, FutureWait, 0xb4396ca1)                                      \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, ~, Smi_bitNegate, 0x5a9bcc19)                                        \
  V(_Smi, get:bitLength, Smi_bitLength, 0x52fbe3e9)                            \
  V(_Smi, _bitAndFromSmi, Smi_bitAndFromSmi, 0x7818c386)                       \
  V(_BigIntImpl, _lsh, Bigint_lsh, 0xb7f65896)                                 \
  V(_BigIntImpl, _rsh, Bigint_rsh, 0x3922f42b)                                 \
  V(_BigIntImpl, _absAdd, Bigint_absAdd, 0x295e93f3)                           \
  V(_BigIntImpl, _absSub, Bigint_absSub, 0x273f7af1)                           \
  V(_BigIntImpl, _mulAdd, Bigint_mulAdd, 0xba45f6ad)                           \
  V(_BigIntImpl, _sqrAdd, Bigint_sqrAdd, 0x2db11c6b)                           \
  V(_BigIntImpl, _estimateQuotientDigit, Bigint_estimateQuotientDigit,         \
    0x3c62c74c)                                                                \
  V(_BigIntMontgomeryReduction, _mulMod, Montgomery_mulMod, 0x091127d0)        \
  V(_Double, >, Double_greaterThan, 0xc4a96c0f)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x335a31b3)                          \
  V(_Double, <, Double_lessThan, 0x059b1fd8)                                   \
  V(_Double, <=, Double_lessEqualThan, 0xeb04cf95)                             \
  V(_Double, ==, Double_equal, 0x094145f1)                                     \
  V(_Double, +, Double_add, 0x74e922bb)                                        \
  V(_Double, -, Double_sub, 0x67d62f0c)                                        \
  V(_Double, *, Double_mul, 0xa95d3909)                                        \
  V(_Double, /, Double_div, 0x9f8bc745)                                        \
  V(_Double, get:hashCode, Double_hashCode, 0x4e27a791)                        \
  V(_Double, get:_identityHashCode, Double_identityHash, 0x1fec3c4f)           \
  V(_Double, get:isNaN, Double_getIsNaN, 0xab76c0f1)                           \
  V(_Double, get:isInfinite, Double_getIsInfinite, 0x9be885b0)                 \
  V(_Double, get:isNegative, Double_getIsNegative, 0xab5f0a6f)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 0x88ace077)               \
  V(_Double, .fromInteger, DoubleFromInteger, 0x0f908a15)                      \
  V(_GrowableList, ._withData, GrowableArray_Allocate, 0x1947d8a1)             \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 0xd8114d5f)                   \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, 0xd0dd0025)       \
  V(Object, ==, ObjectEquals, 0xd3f5f95a)                                      \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x8177627e)                    \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, 0xe61da79f)       \
  V(_StringBase, get:hashCode, String_getHashCode, 0x4e27ab52)                 \
  V(_StringBase, get:_identityHashCode, String_identityHash, 0x1fec4010)       \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 0xfda61c55)                   \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 0xf07e5912)    \
  V(_StringBase, [], StringBaseCharAt, 0x6c55f9a1)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 0x4e27ab52)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked,  0xd81afdbe)                             \
  V(_OneByteString, ==, OneByteString_equality, 0x483ef8d2)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 0x483ef8d2)                    \
  V(_Type, get:hashCode, Type_getHashCode, 0x4e27ab52)                         \
  V(_Type, ==, Type_equality, 0xd3f5f1d8)                                      \
  V(::, _getHash, Object_getHash, 0x1d1372ac)                                  \
  V(::, _setHash, Object_setHash, 0x77e0bb27)                                  \

#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, _addFromInteger, Integer_addFromInteger,           \
    0x4965932b)                                                                \
  V(_IntegerImplementation, +, Integer_add, 0xaf966f4f)                        \
  V(_IntegerImplementation, _subFromInteger, Integer_subFromInteger,           \
    0x0fb6011f)                                                                \
  V(_IntegerImplementation, -, Integer_sub, 0xa39f7e40)                        \
  V(_IntegerImplementation, _mulFromInteger, Integer_mulFromInteger,           \
    0x171d38be)                                                                \
  V(_IntegerImplementation, *, Integer_mul, 0x870ed2dd)                        \
  V(_IntegerImplementation, _moduloFromInteger, Integer_moduloFromInteger,     \
    0x3e1e1d4b)                                                                \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0xaade713f)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x8c0ec194)                \
  V(_IntegerImplementation, _bitAndFromInteger, Integer_bitAndFromInteger,     \
    0x398f434f)                                                                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0xd8a76af3)                     \
  V(_IntegerImplementation, _bitOrFromInteger, Integer_bitOrFromInteger,       \
    0x2b1d2027)                                                                \
  V(_IntegerImplementation, |, Integer_bitOr, 0xdc51e4ab)                      \
  V(_IntegerImplementation, _bitXorFromInteger, Integer_bitXorFromInteger,     \
    0x1c5cefeb)                                                                \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x2542adb2)                     \
  V(_IntegerImplementation, _greaterThanFromInteger,                           \
    Integer_greaterThanFromInt, 0x838ddcc3)                                    \
  V(_IntegerImplementation, >, Integer_greaterThan, 0x0c62013f)                \
  V(_IntegerImplementation, ==, Integer_equal, 0x881c9ddc)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    0x89faaa62)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 0x059b1fd8)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0xeb04cf95)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x335a31b3)          \
  V(_IntegerImplementation, <<, Integer_shl, 0xc378efa5)                       \
  V(_IntegerImplementation, >>, Integer_sar, 0xe029aa4a)                       \
  V(_Double, toInt, DoubleToInteger, 0x3fb5f3e6)                               \

#define MATH_LIB_INTRINSIC_LIST(V)                                             \
  V(::, sqrt, MathSqrt, 0x1d97494a)                                            \
  V(_Random, _nextState, Random_nextState, 0x7e5ba345)                         \

#define GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                       \
  V(::, sin, MathSin, 0xb89b1cb1)                                              \
  V(::, cos, MathCos, 0x82a25065)                                              \
  V(::, tan, MathTan, 0x65b9839b)                                              \
  V(::, asin, MathAsin, 0x7e24237c)                                            \
  V(::, acos, MathAcos, 0xc484d233)                                            \
  V(::, atan, MathAtan, 0xb6c154e6)                                            \
  V(::, atan2, MathAtan2, 0x8e6e8a7b)                                          \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, 0x0cc3b782)                            \
  V(_Int8List, []=, Int8ArraySetIndexed, 0xbbb0b00b)                           \
  V(_Uint8List, [], Uint8ArrayGetIndexed, 0x723c3b42)                          \
  V(_Uint8List, []=, Uint8ArraySetIndexed, 0x083fbbcf)                         \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 0x723c3b42)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 0x083fbbcf)        \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 0x723c3b42)            \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 0xfe3f716f)           \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    0x723c3b42)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    0xfe3f716f)                                                                \
  V(_Int16List, [], Int16ArrayGetIndexed, 0xecc216e2)                          \
  V(_Int16List, []=, Int16ArraySetIndexed, 0x4c307396)                         \
  V(_Uint16List, [], Uint16ArrayGetIndexed, 0xd09af2e2)                        \
  V(_Uint16List, []=, Uint16ArraySetIndexed, 0x34731b0d)                       \
  V(_Int32List, [], Int32ArrayGetIndexed, 0xee5fbc81)                          \
  V(_Int32List, []=, Int32ArraySetIndexed, 0x2a64f035)                         \
  V(_Uint32List, [], Uint32ArrayGetIndexed, 0x3db22221)                        \
  V(_Uint32List, []=, Uint32ArraySetIndexed, 0x160864b5)                       \
  V(_Int64List, [], Int64ArrayGetIndexed, 0x272816c1)                          \
  V(_Int64List, []=, Int64ArraySetIndexed, 0x53c7e8d3)                         \
  V(_Uint64List, [], Uint64ArrayGetIndexed, 0x63ec7c41)                        \
  V(_Uint64List, []=, Uint64ArraySetIndexed, 0x1f295a0b)                       \
  V(_Float64List, [], Float64ArrayGetIndexed, 0x4a2c55fc)                      \
  V(_Float64List, []=, Float64ArraySetIndexed, 0x07ada825)                     \
  V(_Float32List, [], Float32ArrayGetIndexed, 0x202a571c)                      \
  V(_Float32List, []=, Float32ArraySetIndexed, 0x62fc0553)                     \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, 0x96b1f063)                  \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, 0x4897982e)                 \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, 0x9cc8b9ab)                      \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, 0x7307018e)                     \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, 0x674f0479)                  \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, 0x73d783c2)                 \
  V(_TypedList, get:length, TypedListLength, 0x3097c769)                       \
  V(_TypedListView, get:length, TypedListViewLength, 0x3097c769)               \
  V(_ByteDataView, get:length, ByteDataViewLength, 0x3097c769)                 \
  V(_Float32x4, get:x, Float32x4ShuffleX, 0xf36ac93a)                          \
  V(_Float32x4, get:y, Float32x4ShuffleY, 0xe0fc245d)                          \
  V(_Float32x4, get:z, Float32x4ShuffleZ, 0x16c78ff3)                          \
  V(_Float32x4, get:w, Float32x4ShuffleW, 0xf907d475)                          \
  V(_Float32x4, *, Float32x4Mul, 0x06163607)                                   \
  V(_Float32x4, /, Float32x4Div, 0xe164e8e2)                                   \
  V(_Float32x4, -, Float32x4Sub, 0xfdf825ca)                                   \
  V(_Float32x4, +, Float32x4Add, 0xd8bf5b59)                                   \
  V(_Float64x2, *, Float64x2Mul, 0xb6273c86)                                   \
  V(_Float64x2, /, Float64x2Div, 0x9175f322)                                   \
  V(_Float64x2, -, Float64x2Sub, 0xae092c49)                                   \
  V(_Float64x2, +, Float64x2Add, 0x88d061d8)                                   \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_List, get:length, ObjectArrayLength, 0x3097c769)                          \
  V(_List, [], ObjectArrayGetIndexed, 0x78f4f491)                              \
  V(_List, _setIndexed, ObjectArraySetIndexedUnchecked, 0xf233cfd8)            \
  V(_ImmutableList, get:length, ImmutableArrayLength, 0x3097c769)              \
  V(_ImmutableList, [], ImmutableArrayGetIndexed, 0x78f4f491)                  \
  V(_GrowableList, get:length, GrowableArrayLength, 0x3097c769)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x55e672f0)           \
  V(_GrowableList, _setData, GrowableArraySetData, 0x9388253f)                 \
  V(_GrowableList, _setLength, GrowableArraySetLength, 0xba5d44fc)             \
  V(_GrowableList, [], GrowableArrayGetIndexed, 0x78f4f491)                    \
  V(_GrowableList, _setIndexed, GrowableArraySetIndexedUnchecked, 0x5d4f1d17)  \
  V(_StringBase, get:length, StringBaseLength, 0x3097c769)                     \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, 0x323db7d0)           \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, 0x323db7d0)           \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    0x323db7d0)                                                                \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    0x323db7d0)                                                                \
  V(_Double, unary-, DoubleFlipSignBit, 0xf66a4c35)                            \
  V(_Double, truncateToDouble, DoubleTruncate, 0x1c05c6a2)                     \
  V(_Double, roundToDouble, DoubleRound, 0x0f7b0a49)                           \
  V(_Double, floorToDouble, DoubleFloor, 0x0de60b91)                           \
  V(_Double, ceilToDouble, DoubleCeil, 0x184d0f22)                             \
  V(_Double, _modulo, DoubleMod, 0x2eee8a6e)

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \
  GRAPH_MATH_LIB_INTRINSIC_LIST(V)                                             \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(_UserTag, makeCurrent, UserTag_makeCurrent, 0xc0abd700)                    \
  V(::, _getDefaultTag, UserTag_defaultTag, 0xd0ebe717)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 0xd5bcef00)                    \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, 0xa0686991)        \

#define INTERNAL_LIB_INTRINSIC_LIST(V)                                         \
  V(::, allocateOneByteString, AllocateOneByteString, 0x3a5d74f6)              \
  V(::, allocateTwoByteString, AllocateTwoByteString, 0x4222b093)              \
  V(::, writeIntoOneByteString, WriteIntoOneByteString, 0xa2337709)            \
  V(::, writeIntoTwoByteString, WriteIntoTwoByteString, 0x99887dd2)            \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
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
  V(_StringBase, [], StringBaseCharAt, 0x6c55f9a1)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x30688af4)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x31c4acea)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x4885450f)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x4a06a579)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x335cdbca)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x33a21d3b)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0x10a56ebf)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0x46a02819)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xe425bcd3)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xf3595200)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0xb3cc1803)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0xbe4aee59)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0x89b17e2a)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0x5781f1d0)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0x630e7aaf)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0x764a82d7)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0x6602e5c8)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0x618ede3a)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0x70f58a02)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0x826f6c8d)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x2761c274)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x1b858d66)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x9e2320c0)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0xfa1f5cf1)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x8177627e)

// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x4c9d39e2)                             \
  V(_ListFilledFactory, _List, .filled, kArrayCid, 0xaf758106)                 \
  V(_ListGenerateFactory, _List, .generate, kArrayCid, 0xff53e115)             \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0xa61fbeb9)                                                                \
  V(_GrowableListFilledFactory, _GrowableList, .filled,                        \
    kGrowableObjectArrayCid, 0x27a28286)                                       \
  V(_GrowableListGenerateFactory, _GrowableList, .generate,                    \
    kGrowableObjectArrayCid, 0x60b98295)                                       \
  V(_GrowableListWithData, _GrowableList, ._withData, kGrowableObjectArrayCid, \
    0x1947d8a1)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x934e97a2)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0x7eea24fb)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0xba98ab35)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0x54af9dd7)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0xc3859080)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x3e52ca0a)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0xdbbb093f)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0x560fc11b)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0x02b7f232)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0x321abc79)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0xdf9d206c)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0xa0de94a2)

// clang-format on

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
