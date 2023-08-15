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
  V(::, identical, ObjectIdentical, 0x0407f735)                                \
  V(ClassID, getID, ClassIDgetID, 0xdc7cfcaa)                                  \
  V(Object, Object., ObjectConstructor, 0xab6d6cfa)                            \
  V(_List, ., ObjectArrayAllocate, 0x4c8eae02)                                 \
  V(_List, []=, ObjectArraySetIndexed, 0x3a3252da)                             \
  V(_GrowableList, ._withData, GrowableArrayAllocateWithData, 0x19394cc1)      \
  V(_GrowableList, []=, GrowableArraySetIndexed, 0x3a3252da)                   \
  V(_Record, get:_fieldNames, Record_fieldNames, 0x68d6b9bd)                   \
  V(_Record, get:_numFields, Record_numFields, 0x7bb37bb2)                     \
  V(_Record, get:_shape, Record_shape, 0x70d29513)                             \
  V(_Record, _fieldAt, Record_fieldAt, 0xb48e2c93)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x16155054)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x1771724a)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x2e320a6f)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x2fb36ad9)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x1909a12a)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x194ee29b)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xf652341f)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0x2c4ced79)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xe8e81527)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xf81baa54)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0xaf1e8105)          \
  V(_TypedList, _getFloat64x2, ByteArrayBaseGetFloat64x2, 0x544ea0e0)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x5564e82b)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xe17ab7c2)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetUint8, 0xaf4b2b68)                  \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xbad7b447)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetUint16, 0xce13bc6f)                \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xbdcc1f60)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xb95817d2)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xc8bec39a)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xda38a625)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x2f27a200)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x234b6cf2)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x38b79d7a)          \
  V(_TypedList, _setFloat64x2, ByteArrayBaseSetFloat64x2, 0xbadc4b5f)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x5cda767b)              \
  V(ByteData, ., ByteDataFactory, 0x45e89423)                                  \
  V(_ByteDataView, get:offsetInBytes, ByteDataViewOffsetInBytes, 0x60c0664c)   \
  V(_ByteDataView, get:_typedData, ByteDataViewTypedData, 0xb9c2d41a)          \
  V(_TypedListView, get:offsetInBytes, TypedDataViewOffsetInBytes, 0x60c0664c) \
  V(_TypedListView, get:_typedData, TypedDataViewTypedData, 0xb9c2d41a)        \
  V(_ByteDataView, ._, TypedData_ByteDataView_factory, 0x3178879c)             \
  V(_Int8ArrayView, ._, TypedData_Int8ArrayView_factory, 0x444785ea)           \
  V(_Uint8ArrayView, ._, TypedData_Uint8ArrayView_factory, 0x95f1fcb5)         \
  V(_Uint8ClampedArrayView, ._, TypedData_Uint8ClampedArrayView_factory,       \
    0x052aec89)                                                                \
  V(_Int16ArrayView, ._, TypedData_Int16ArrayView_factory, 0x48ff87fb)         \
  V(_Uint16ArrayView, ._, TypedData_Uint16ArrayView_factory, 0x9fea3a52)       \
  V(_Int32ArrayView, ._, TypedData_Int32ArrayView_factory, 0xe2db1e99)         \
  V(_Uint32ArrayView, ._, TypedData_Uint32ArrayView_factory, 0x86742ec1)       \
  V(_Int64ArrayView, ._, TypedData_Int64ArrayView_factory, 0x12b8c2cf)         \
  V(_Uint64ArrayView, ._, TypedData_Uint64ArrayView_factory, 0x25b7e31d)       \
  V(_Float32ArrayView, ._, TypedData_Float32ArrayView_factory, 0xdc880064)     \
  V(_Float64ArrayView, ._, TypedData_Float64ArrayView_factory, 0xcb67c937)     \
  V(_Float32x4ArrayView, ._, TypedData_Float32x4ArrayView_factory, 0x665022e0) \
  V(_Int32x4ArrayView, ._, TypedData_Int32x4ArrayView_factory, 0x04a1d125)     \
  V(_Float64x2ArrayView, ._, TypedData_Float64x2ArrayView_factory, 0x42d3cfc4) \
  V(_UnmodifiableByteDataView, ._,                                             \
    TypedData_UnmodifiableByteDataView_factory, 0x9aef8c2b)                    \
  V(_UnmodifiableInt8ArrayView, ._,                                            \
    TypedData_UnmodifiableInt8ArrayView_factory, 0x4f1cb9aa)                   \
  V(_UnmodifiableUint8ArrayView, ._,                                           \
    TypedData_UnmodifiableUint8ArrayView_factory, 0x443a0469)                  \
  V(_UnmodifiableUint8ClampedArrayView, ._,                                    \
    TypedData_UnmodifiableUint8ClampedArrayView_factory, 0x6a4a652d)           \
  V(_UnmodifiableInt16ArrayView, ._,                                           \
    TypedData_UnmodifiableInt16ArrayView_factory, 0xb6d9a15a)                  \
  V(_UnmodifiableUint16ArrayView, ._,                                          \
    TypedData_UnmodifiableUint16ArrayView_factory, 0xa6cd2bf6)                 \
  V(_UnmodifiableInt32ArrayView, ._,                                           \
     TypedData_UnmodifiableInt32ArrayView_factory, 0x48eeef04)                 \
  V(_UnmodifiableUint32ArrayView, ._,                                          \
    TypedData_UnmodifiableUint32ArrayView_factory, 0x95172a94)                 \
  V(_UnmodifiableInt64ArrayView, ._,                                           \
    TypedData_UnmodifiableInt64ArrayView_factory, 0x76444964)                  \
  V(_UnmodifiableUint64ArrayView, ._,                                          \
    TypedData_UnmodifiableUint64ArrayView_factory, 0x400d41a2)                 \
  V(_UnmodifiableFloat32ArrayView, ._,                                         \
    TypedData_UnmodifiableFloat32ArrayView_factory, 0x541577a9)                \
  V(_UnmodifiableFloat64ArrayView, ._,                                         \
    TypedData_UnmodifiableFloat64ArrayView_factory, 0xbf7b608b)                \
  V(_UnmodifiableFloat32x4ArrayView, ._,                                       \
    TypedData_UnmodifiableFloat32x4ArrayView_factory, 0x5f175eba)              \
  V(_UnmodifiableInt32x4ArrayView, ._,                                         \
    TypedData_UnmodifiableInt32x4ArrayView_factory, 0xf66c65d2)                \
  V(_UnmodifiableFloat64x2ArrayView, ._,                                       \
    TypedData_UnmodifiableFloat64x2ArrayView_factory, 0x6d9ae23a)              \
  V(Int8List, ., TypedData_Int8Array_factory, 0x65ff4ca8)                      \
  V(Uint8List, ., TypedData_Uint8Array_factory, 0xedd56a6f)                    \
  V(Uint8ClampedList, ., TypedData_Uint8ClampedArray_factory, 0x27f7ab75)      \
  V(Int16List, ., TypedData_Int16Array_factory, 0xd0bf0d13)                    \
  V(Uint16List, ., TypedData_Uint16Array_factory, 0x3ca76f8a)                  \
  V(Int32List, ., TypedData_Int32Array_factory, 0x1b816740)                    \
  V(Uint32List, ., TypedData_Uint32Array_factory, 0x2b210eab)                  \
  V(Int64List, ., TypedData_Int64Array_factory, 0xfb63524f)                    \
  V(Uint64List, ., TypedData_Uint64Array_factory, 0xe3c14418)                  \
  V(Float32List, ., TypedData_Float32Array_factory, 0xa381dd1e)                \
  V(Float64List, ., TypedData_Float64Array_factory, 0xa0b7c2b1)                \
  V(Float32x4List, ., TypedData_Float32x4Array_factory, 0x0a6eefa8)            \
  V(Int32x4List, ., TypedData_Int32x4Array_factory, 0x5a09288e)                \
  V(Float64x2List, ., TypedData_Float64x2Array_factory, 0xecbc738a)            \
  V(::, _toClampedUint8, ConvertIntToClampedUint8, 0xd0e522d0)                 \
  V(::, copyRangeFromUint8ListToOneByteString,                                 \
    CopyRangeFromUint8ListToOneByteString, 0xcc42cce1)                         \
  V(_StringBase, _interpolate, StringBaseInterpolate, 0x7c662480)              \
  V(_SuspendState, get:_functionData, SuspendState_getFunctionData,            \
    0x7281768e)                                                                \
  V(_SuspendState, set:_functionData, SuspendState_setFunctionData,            \
    0x2b57dccb)                                                                \
  V(_SuspendState, get:_thenCallback, SuspendState_getThenCallback,            \
    0x2b907141)                                                                \
  V(_SuspendState, set:_thenCallback, SuspendState_setThenCallback,            \
    0x752e28fe)                                                                \
  V(_SuspendState, get:_errorCallback, SuspendState_getErrorCallback,          \
    0xaebb7b0f)                                                                \
  V(_SuspendState, set:_errorCallback, SuspendState_setErrorCallback,          \
    0xc3fa77cc)                                                                \
  V(_SuspendState, _clone, SuspendState_clone, 0xae0bb4c0)                     \
  V(_SuspendState, _resume, SuspendState_resume, 0x5d6bf8a9)                   \
  V(_IntegerImplementation, toDouble, IntegerToDouble, 0x9763ff66)             \
  V(_Double, _add, DoubleAdd, 0xea57d747)                                      \
  V(_Double, _sub, DoubleSub, 0x2838c04e)                                      \
  V(_Double, _mul, DoubleMul, 0x1f8a3b8c)                                      \
  V(_Double, _div, DoubleDiv, 0x286eabb1)                                      \
  V(_Double, _modulo, DoubleMod, 0xfda50c0f)                                   \
  V(_Double, ceil, DoubleCeilToInt, 0xceea4be5)                                \
  V(_Double, ceilToDouble, DoubleCeilToDouble, 0x5f0d42f9)                     \
  V(_Double, floor, DoubleFloorToInt, 0x2a23b3a8)                              \
  V(_Double, floorToDouble, DoubleFloorToDouble, 0x54a63f68)                   \
  V(_Double, roundToDouble, DoubleRoundToDouble, 0x563b3e20)                   \
  V(_Double, toInt, DoubleToInteger, 0x676094c9)                               \
  V(_Double, truncateToDouble, DoubleTruncateToDouble, 0x62c5fa79)             \
  V(::, min, MathMin, 0x82d8d2f3)                                              \
  V(::, max, MathMax, 0x4b21168c)                                              \
  V(::, _doublePow, MathDoublePow, 0xaeba6874)                                 \
  V(::, _intPow, MathIntPow, 0xab4873fa)                                       \
  V(::, _sin, MathSin, 0x17cc3e23)                                             \
  V(::, _cos, MathCos, 0xf485f165)                                             \
  V(::, _tan, MathTan, 0xeb0bc957)                                             \
  V(::, _asin, MathAsin, 0x29d649be)                                           \
  V(::, _acos, MathAcos, 0x1ffc14fb)                                           \
  V(::, _atan, MathAtan, 0x10ebd512)                                           \
  V(::, _atan2, MathAtan2, 0x58c66573)                                         \
  V(::, _sqrt, MathSqrt, 0x0309a7b0)                                           \
  V(::, _exp, MathExp, 0x00e673f0)                                             \
  V(::, _log, MathLog, 0x099ff882)                                             \
  V(FinalizerBase, get:_allEntries, FinalizerBase_getAllEntries, 0xf031668b)   \
  V(FinalizerBase, set:_allEntries, FinalizerBase_setAllEntries, 0x8efa9508)   \
  V(FinalizerBase, get:_detachments, FinalizerBase_getDetachments, 0x2f568356) \
  V(FinalizerBase, set:_detachments, FinalizerBase_setDetachments, 0x78809213) \
  V(FinalizerBase, _exchangeEntriesCollectedWithNull,                          \
    FinalizerBase_exchangeEntriesCollectedWithNull, 0x6c82991b)                \
  V(FinalizerBase, _setIsolate, FinalizerBase_setIsolate, 0xbce94fb1)          \
  V(FinalizerBase, get:_isolateFinalizers, FinalizerBase_getIsolateFinalizers, \
    0x70e6af4b)                                                                \
  V(FinalizerBase, set:_isolateFinalizers, FinalizerBase_setIsolateFinalizers, \
    0xb3d7dd48)                                                                \
  V(_FinalizerImpl, get:_callback, Finalizer_getCallback, 0x18503118)          \
  V(_FinalizerImpl, set:_callback, Finalizer_setCallback, 0xacfcd255)          \
  V(_NativeFinalizer, get:_callback, NativeFinalizer_getCallback, 0x5ca4e915)  \
  V(_NativeFinalizer, set:_callback, NativeFinalizer_setCallback, 0xb113dd12)  \
  V(FinalizerEntry, allocate, FinalizerEntry_allocate, 0xe0ac4c98)             \
  V(FinalizerEntry, get:value, FinalizerEntry_getValue, 0xf5bb2df7)            \
  V(FinalizerEntry, get:detach, FinalizerEntry_getDetach, 0x170e4d88)          \
  V(FinalizerEntry, get:token, FinalizerEntry_getToken, 0x0482ce92)            \
  V(FinalizerEntry, set:token, FinalizerEntry_setToken, 0x63bae10f)            \
  V(FinalizerEntry, get:next, FinalizerEntry_getNext, 0x70f44bc4)              \
  V(FinalizerEntry, get:externalSize, FinalizerEntry_getExternalSize,          \
    0x47d0c142)                                                                \
  V(Float32x4, _Float32x4FromDoubles, Float32x4FromDoubles, 0x1836ed4b)        \
  V(Float32x4, Float32x4.zero, Float32x4Zero, 0xd3a7b422)                      \
  V(Float32x4, _Float32x4Splat, Float32x4Splat, 0x1396c6e3)                    \
  V(Float32x4, Float32x4.fromInt32x4Bits, Int32x4ToFloat32x4, 0x7ec70962)      \
  V(Float32x4, Float32x4.fromFloat64x2, Float64x2ToFloat32x4, 0x50b001ad)      \
  V(_Float32x4, shuffle, Float32x4Shuffle, 0xa7e32c0b)                         \
  V(_Float32x4, shuffleMix, Float32x4ShuffleMix, 0x799236ec)                   \
  V(_Float32x4, get:signMask, Float32x4GetSignMask, 0x7c5c860a)                \
  V(_Float32x4, equal, Float32x4Equal, 0x444c6196)                             \
  V(_Float32x4, greaterThan, Float32x4GreaterThan, 0x523ef19f)                 \
  V(_Float32x4, greaterThanOrEqual, Float32x4GreaterThanOrEqual, 0x4e5fd5d7)   \
  V(_Float32x4, lessThan, Float32x4LessThan, 0x4a09e53d)                       \
  V(_Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual, 0x4668c760)         \
  V(_Float32x4, notEqual, Float32x4NotEqual, 0x6440a963)                       \
  V(_Float32x4, min, Float32x4Min, 0xe41012b2)                                 \
  V(_Float32x4, max, Float32x4Max, 0xc63f9483)                                 \
  V(_Float32x4, scale, Float32x4Scale, 0xa3a8bc22)                             \
  V(_Float32x4, sqrt, Float32x4Sqrt, 0xe4e86ed2)                               \
  V(_Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt, 0xddc96658)           \
  V(_Float32x4, reciprocal, Float32x4Reciprocal, 0xd4439692)                   \
  V(_Float32x4, unary-, Float32x4Negate, 0xe69d3832)                           \
  V(_Float32x4, abs, Float32x4Abs, 0xeb37f268)                                 \
  V(_Float32x4, clamp, Float32x4Clamp, 0x77bee5fd)                             \
  V(_Float32x4, _withX, Float32x4WithX, 0xa30913cf)                            \
  V(_Float32x4, _withY, Float32x4WithY, 0x9bab2863)                            \
  V(_Float32x4, _withZ, Float32x4WithZ, 0x97c7a2c0)                            \
  V(_Float32x4, _withW, Float32x4WithW, 0x9524967b)                            \
  V(Float64x2, _Float64x2FromDoubles, Float64x2FromDoubles, 0xd84a5471)        \
  V(Float64x2, Float64x2.zero, Float64x2Zero, 0x8285fd38)                      \
  V(Float64x2, _Float64x2Splat, Float64x2Splat, 0x5b04dfe4)                    \
  V(Float64x2, Float64x2.fromFloat32x4, Float32x4ToFloat64x2, 0x6e991086)      \
  V(_Float64x2, get:x, Float64x2GetX, 0x3a2af950)                              \
  V(_Float64x2, get:y, Float64x2GetY, 0x27bc5473)                              \
  V(_Float64x2, unary-, Float64x2Negate, 0x957b8148)                           \
  V(_Float64x2, abs, Float64x2Abs, 0x9a163b7e)                                 \
  V(_Float64x2, clamp, Float64x2Clamp, 0xfdcd8953)                             \
  V(_Float64x2, sqrt, Float64x2Sqrt, 0x93c6b7e8)                               \
  V(_Float64x2, get:signMask, Float64x2GetSignMask, 0x7c5c860a)                \
  V(_Float64x2, scale, Float64x2Scale, 0x52870538)                             \
  V(_Float64x2, _withX, Float64x2WithX, 0x51e75ce5)                            \
  V(_Float64x2, _withY, Float64x2WithY, 0x4a897179)                            \
  V(_Float64x2, min, Float64x2Min,  0x36205072)                                \
  V(_Float64x2, max, Float64x2Max,  0x184fd243)                                \
  V(Int32x4, _Int32x4FromInts, Int32x4FromInts, 0xa8f23150)                    \
  V(Int32x4, _Int32x4FromBools, Int32x4FromBools, 0xf55e03e8)                  \
  V(Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4, 0x4563e981)        \
  V(_Int32x4, get:flagX, Int32x4GetFlagX, 0xc29077f8)                          \
  V(_Int32x4, get:flagY, Int32x4GetFlagY, 0xde00aed8)                          \
  V(_Int32x4, get:flagZ, Int32x4GetFlagZ, 0xebaa4a2b)                          \
  V(_Int32x4, get:flagW, Int32x4GetFlagW, 0xf4ca5c6c)                          \
  V(_Int32x4, get:signMask, Int32x4GetSignMask, 0x7c5c860a)                    \
  V(_Int32x4, shuffle, Int32x4Shuffle, 0x405385f3)                             \
  V(_Int32x4, shuffleMix, Int32x4ShuffleMix, 0x4fd9a8bc)                       \
  V(_Int32x4, select, Int32x4Select, 0x68bc13c0)                               \
  V(_Int32x4, _withFlagX, Int32x4WithFlagX, 0xb7d07483)                        \
  V(_Int32x4, _withFlagY, Int32x4WithFlagY, 0xa8c10fc6)                        \
  V(_Int32x4, _withFlagZ, Int32x4WithFlagZ, 0xa7f6fc74)                        \
  V(_Int32x4, _withFlagW, Int32x4WithFlagW, 0xb3256d78)                        \
  V(_RawReceivePort, get:sendPort, ReceivePort_getSendPort, 0xe6ace48d)        \
  V(_RawReceivePort, get:_handler, ReceivePort_getHandler, 0xf1e4d653)         \
  V(_RawReceivePort, set:_handler, ReceivePort_setHandler, 0x570dc750)         \
  V(_HashVMBase, get:_index, LinkedHashBase_getIndex, 0x8817e5fc)              \
  V(_HashVMBase, set:_index, LinkedHashBase_setIndex, 0xa2b00838)              \
  V(_HashVMBase, get:_data, LinkedHashBase_getData, 0x2c7cd2a3)                \
  V(_HashVMBase, set:_data, LinkedHashBase_setData, 0x40e963df)                \
  V(_HashVMBase, get:_usedData, LinkedHashBase_getUsedData, 0x46fa080d)        \
  V(_HashVMBase, set:_usedData, LinkedHashBase_setUsedData, 0xb3b9fbc9)        \
  V(_HashVMBase, get:_hashMask, LinkedHashBase_getHashMask, 0x4f003bbc)        \
  V(_HashVMBase, set:_hashMask, LinkedHashBase_setHashMask, 0xbbc02f78)        \
  V(_HashVMBase, get:_deletedKeys, LinkedHashBase_getDeletedKeys, 0x50ff38c0)  \
  V(_HashVMBase, set:_deletedKeys, LinkedHashBase_setDeletedKeys, 0xbdbf2c7c)  \
  V(_HashVMImmutableBase, get:_data, ImmutableLinkedHashBase_getData,          \
    0x2c7cd2a3)                                                                \
  V(_HashVMImmutableBase, get:_indexNullable,                                  \
    ImmutableLinkedHashBase_getIndex, 0xfd78f01b)                              \
  V(_HashVMImmutableBase, set:_index,                                          \
    ImmutableLinkedHashBase_setIndexStoreRelease, 0xa2b00838)                  \
  V(_WeakProperty, get:key, WeakProperty_getKey, 0xddf25882)                   \
  V(_WeakProperty, set:key, WeakProperty_setKey, 0x962b7d7f)                   \
  V(_WeakProperty, get:value, WeakProperty_getValue, 0xd2e3fece)               \
  V(_WeakProperty, set:value, WeakProperty_setValue, 0x8b1d23cb)               \
  V(_WeakReference, get:target, WeakReference_getTarget, 0xc98185aa)           \
  V(_WeakReference, set:_target, WeakReference_setTarget, 0xc71add9a)          \
  V(::, _classRangeCheck, ClassRangeCheck, 0xef2bb89a)                         \
  V(::, _abi, FfiAbi, 0x7c3c27d4)                                              \
  V(::, _asFunctionInternal, FfiAsFunctionInternal, 0x630c8491)                \
  V(::, _nativeCallbackFunction, FfiNativeCallbackFunction, 0x3fe722bc)        \
  V(::, _nativeAsyncCallbackFunction, FfiNativeAsyncCallbackFunction,          \
    0xbec4b7b9)                                                                \
  V(::, _nativeEffect, NativeEffect, 0x536f42b1)                               \
  V(::, _loadAbiSpecificInt, FfiLoadAbiSpecificInt, 0x77f95c92)                \
  V(::, _loadAbiSpecificIntAtIndex, FfiLoadAbiSpecificIntAtIndex, 0x6a963ed4)  \
  V(::, _loadInt8, FfiLoadInt8, 0x0ef653f6)                                    \
  V(::, _loadInt16, FfiLoadInt16, 0xec35a54d)                                  \
  V(::, _loadInt32, FfiLoadInt32, 0xee13b3e3)                                  \
  V(::, _loadInt64, FfiLoadInt64, 0xdee133c3)                                  \
  V(::, _loadUint8, FfiLoadUint8, 0xe13f90f1)                                  \
  V(::, _loadUint16, FfiLoadUint16, 0x0cc7d10a)                                \
  V(::, _loadUint32, FfiLoadUint32, 0xf6600475)                                \
  V(::, _loadUint64, FfiLoadUint64, 0x04f771ec)                                \
  V(::, _loadFloat, FfiLoadFloat, 0xf8caf4bc)                                  \
  V(::, _loadFloatUnaligned, FfiLoadFloatUnaligned, 0xc8ba505e)                \
  V(::, _loadDouble, FfiLoadDouble, 0xf6fe3678)                                \
  V(::, _loadDoubleUnaligned, FfiLoadDoubleUnaligned, 0xc9902d98)              \
  V(::, _loadPointer, FfiLoadPointer, 0x99f98123)                              \
  V(::, _storeAbiSpecificInt, FfiStoreAbiSpecificInt, 0xc6fac8e0)              \
  V(::, _storeAbiSpecificIntAtIndex, FfiStoreAbiSpecificIntAtIndex, 0xc640726b)\
  V(::, _storeInt8, FfiStoreInt8, 0xdf42232c)                                  \
  V(::, _storeInt16, FfiStoreInt16, 0xd83f6752)                                \
  V(::, _storeInt32, FfiStoreInt32, 0xfbd7a07d)                                \
  V(::, _storeInt64, FfiStoreInt64, 0xf1c5819a)                                \
  V(::, _storeUint8, FfiStoreUint8, 0x055f4716)                                \
  V(::, _storeUint16, FfiStoreUint16, 0xe2ef1efe)                              \
  V(::, _storeUint32, FfiStoreUint32, 0xe5c95ce5)                              \
  V(::, _storeUint64, FfiStoreUint64, 0xe2caa659)                              \
  V(::, _storeFloat, FfiStoreFloat, 0x647660dd)                                \
  V(::, _storeFloatUnaligned, FfiStoreFloatUnaligned, 0x5ffc0262)              \
  V(::, _storeDouble, FfiStoreDouble, 0x428afcc3)                              \
  V(::, _storeDoubleUnaligned, FfiStoreDoubleUnaligned, 0x3dc047ba)            \
  V(::, _storePointer, FfiStorePointer, 0x8b5a5578)                            \
  V(::, _fromAddress, FfiFromAddress, 0x810f9640)                              \
  V(Pointer, get:address, FfiGetAddress, 0x7ccff81d)                           \
  V(::, _asExternalTypedDataInt8, FfiAsExternalTypedDataInt8, 0x767b76f7)      \
  V(::, _asExternalTypedDataInt16, FfiAsExternalTypedDataInt16, 0xd08e6a25)    \
  V(::, _asExternalTypedDataInt32, FfiAsExternalTypedDataInt32, 0x3815f9a5)    \
  V(::, _asExternalTypedDataInt64, FfiAsExternalTypedDataInt64, 0xaf9bb85a)    \
  V(::, _asExternalTypedDataUint8, FfiAsExternalTypedDataUint8, 0x3513f893)    \
  V(::, _asExternalTypedDataUint16, FfiAsExternalTypedDataUint16, 0x89968e99)  \
  V(::, _asExternalTypedDataUint32, FfiAsExternalTypedDataUint32, 0xd2644ca0)  \
  V(::, _asExternalTypedDataUint64, FfiAsExternalTypedDataUint64, 0x06afe224)  \
  V(::, _asExternalTypedDataFloat, FfiAsExternalTypedDataFloat, 0x6f37ce6b)    \
  V(::, _asExternalTypedDataDouble, FfiAsExternalTypedDataDouble, 0x40bf4a40)  \
  V(::, _getNativeField, GetNativeField, 0xa0050fa5)                           \
  V(::, reachabilityFence, ReachabilityFence, 0x73009f9f)                      \
  V(_Utf8Decoder, _scan, Utf8DecoderScan, 0xb98ea301)                          \
  V(_FutureListener, handleValue, FutureListenerHandleValue, 0xec1745d2)       \
  V(::, has63BitSmis, Has63BitSmis, 0xf60ccb11)                                \
  V(::, get:extensionStreamHasListener, ExtensionStreamHasListener, 0xfaa5d763)\
  V(_Smi, get:hashCode, Smi_hashCode, 0x75d240f2)                              \
  V(_Mint, get:hashCode, Mint_hashCode, 0x75d240f2)                            \
  V(_Double, get:hashCode, Double_hashCode, 0x75d240f2)                        \
  V(::, _memCopy, MemCopy, 0x2740bc36)                                         \
  V(::, debugger, Debugger, 0xf0b98af4)                                        \

// List of intrinsics:
// (class-name, function-name, intrinsification method, fingerprint).
#define CORE_LIB_INTRINSIC_LIST(V)                                             \
  V(_Smi, get:bitLength, Smi_bitLength, 0x7aa6810b)                            \
  V(_BigIntImpl, _lsh, Bigint_lsh, 0x3fd48b02)                                 \
  V(_BigIntImpl, _rsh, Bigint_rsh, 0xde054a3f)                                 \
  V(_BigIntImpl, _absAdd, Bigint_absAdd, 0x2ab3ee51)                           \
  V(_BigIntImpl, _absSub, Bigint_absSub, 0x70ff3dcb)                           \
  V(_BigIntImpl, _mulAdd, Bigint_mulAdd, 0x3d47f01d)                           \
  V(_BigIntImpl, _sqrAdd, Bigint_sqrAdd, 0x8fa60a65)                           \
  V(_BigIntImpl, _estimateQuotientDigit, Bigint_estimateQuotientDigit,         \
    0x16c6fd68)                                                                \
  V(_BigIntMontgomeryReduction, _mulMod, Montgomery_mulMod, 0xdc900374)        \
  V(_Double, >, Double_greaterThan, 0x7b024427)                                \
  V(_Double, >=, Double_greaterEqualThan, 0x4aae9393)                          \
  V(_Double, <, Double_lessThan, 0xd309ff94)                                   \
  V(_Double, <=, Double_lessEqualThan, 0x02593175)                             \
  V(_Double, ==, Double_equal, 0x27744e0f)                                     \
  V(_Double, +, Double_add, 0xa7d69d7f)                                        \
  V(_Double, -, Double_sub, 0x9ac3a9d0)                                        \
  V(_Double, *, Double_mul, 0xdc4ab3cd)                                        \
  V(_Double, /, Double_div, 0xd2794209)                                        \
  V(_Double, get:isNaN, Double_getIsNaN, 0xd47a7b33)                           \
  V(_Double, get:isInfinite, Double_getIsInfinite, 0xc4ec3ff2)                 \
  V(_Double, get:isNegative, Double_getIsNegative, 0xd462c4b1)                 \
  V(_Double, _mulFromInteger, Double_mulFromInteger, 0xece04a8f)               \
  V(_Double, .fromInteger, DoubleFromInteger, 0x7d014db9)                      \
  V(_RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 0x99034969)                   \
  V(_RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky, 0x91cefc2f)       \
  V(Object, ==, ObjectEquals, 0x4649e450)                                      \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x03733c71)                    \
  V(Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType, 0xce3fd6b5)       \
  V(_StringBase, get:hashCode, String_getHashCode, 0x75d24874)                 \
  V(_StringBase, get:_identityHashCode, String_identityHash, 0x4796dd32)       \
  V(_StringBase, get:isEmpty, StringBaseIsEmpty, 0x98685173)                   \
  V(_StringBase, _substringMatches, StringBaseSubstringMatches, 0x852eb692)    \
  V(_StringBase, [], StringBaseCharAt, 0xd0613adf)                             \
  V(_OneByteString, get:hashCode, OneByteString_getHashCode, 0x75d24874)       \
  V(_OneByteString, _substringUncheckedNative,                                 \
    OneByteString_substringUnchecked,  0x9b098d7e)                             \
  V(_OneByteString, ==, OneByteString_equality, 0x4e9b51e9)                    \
  V(_TwoByteString, ==, TwoByteString_equality, 0x4e9b51e9)                    \
  V(_AbstractType, get:hashCode, AbstractType_getHashCode, 0x75d24874)         \
  V(_AbstractType, ==, AbstractType_equality, 0x4649dcce)                      \
  V(_Type, ==, Type_equality, 0x4649dcce)                                      \
  V(::, _getHash, Object_getHash, 0xc6016b78)                                  \

#define CORE_INTEGER_LIB_INTRINSIC_LIST(V)                                     \
  V(_IntegerImplementation, >, Integer_greaterThan, 0xd9d0e0fb)                \
  V(_IntegerImplementation, ==, Integer_equal, 0xe95d722a)                     \
  V(_IntegerImplementation, _equalToInteger, Integer_equalToInteger,           \
    0x71008ce2)                                                                \
  V(_IntegerImplementation, <, Integer_lessThan, 0xd309ff94)                   \
  V(_IntegerImplementation, <=, Integer_lessEqualThan, 0x02593175)             \
  V(_IntegerImplementation, >=, Integer_greaterEqualThan, 0x4aae9393)          \
  V(_IntegerImplementation, <<, Integer_shl, 0x2d253e1b)                       \

#define GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                    \
  V(_Int8List, [], Int8ArrayGetIndexed, 0xb8ab318e)                            \
  V(_Int8List, []=, Int8ArraySetIndexed, 0xd832152f)                           \
  V(_Uint8List, [], Uint8ArrayGetIndexed, 0x1e23b54e)                          \
  V(_Uint8List, []=, Uint8ArraySetIndexed, 0x24c120f3)                         \
  V(_ExternalUint8Array, [], ExternalUint8ArrayGetIndexed, 0x1e23b54e)         \
  V(_ExternalUint8Array, []=, ExternalUint8ArraySetIndexed, 0x24c120f3)        \
  V(_Uint8ClampedList, [], Uint8ClampedArrayGetIndexed, 0x1e23b54e)            \
  V(_Uint8ClampedList, []=, Uint8ClampedArraySetIndexed, 0x1ac0d693)           \
  V(_ExternalUint8ClampedArray, [], ExternalUint8ClampedArrayGetIndexed,       \
    0x1e23b54e)                                                                \
  V(_ExternalUint8ClampedArray, []=, ExternalUint8ClampedArraySetIndexed,      \
    0x1ac0d693)                                                                \
  V(_Int16List, [], Int16ArrayGetIndexed, 0x98a990ee)                          \
  V(_Int16List, []=, Int16ArraySetIndexed, 0x68b1d8ba)                         \
  V(_Uint16List, [], Uint16ArrayGetIndexed, 0x7c826cee)                        \
  V(_Uint16List, []=, Uint16ArraySetIndexed, 0x50f48031)                       \
  V(_Int32List, [], Int32ArrayGetIndexed, 0x9a47368d)                          \
  V(_Int32List, []=, Int32ArraySetIndexed, 0x46e65559)                         \
  V(_Uint32List, [], Uint32ArrayGetIndexed, 0xe9999c2d)                        \
  V(_Uint32List, []=, Uint32ArraySetIndexed, 0x3289c9d9)                       \
  V(_Int64List, [], Int64ArrayGetIndexed, 0xd30f90cd)                          \
  V(_Int64List, []=, Int64ArraySetIndexed, 0xa79b0f2f)                         \
  V(_Uint64List, [], Uint64ArrayGetIndexed, 0x0fd3f64d)                        \
  V(_Uint64List, []=, Uint64ArraySetIndexed, 0x72fc8067)                       \
  V(_Float64List, [], Float64ArrayGetIndexed, 0x0ccc6114)                      \
  V(_Float64List, []=, Float64ArraySetIndexed, 0xa6594c8d)                     \
  V(_Float32List, [], Float32ArrayGetIndexed, 0xe2ca6234)                      \
  V(_Float32List, []=, Float32ArraySetIndexed, 0x01a7a9bb)                     \
  V(_Float32x4List, [], Float32x4ArrayGetIndexed, 0xe48a60cd)                  \
  V(_Float32x4List, []=, Float32x4ArraySetIndexed, 0x85f79568)                 \
  V(_Int32x4List, [], Int32x4ArrayGetIndexed, 0xfa032945)                      \
  V(_Int32x4List, []=, Int32x4ArraySetIndexed, 0x6f45f1f8)                     \
  V(_Float64x2List, [], Float64x2ArrayGetIndexed, 0x2e4ca3f7)                  \
  V(_Float64x2List, []=, Float64x2ArraySetIndexed, 0x75cd3b10)                 \
  V(_TypedListBase, get:length, TypedListBaseLength, 0x5842648b)               \
  V(_ByteDataView, get:length, ByteDataViewLength, 0x5842648b)                 \
  V(_Float32x4, get:x, Float32x4GetX, 0x3a2af950)                              \
  V(_Float32x4, get:y, Float32x4GetY, 0x27bc5473)                              \
  V(_Float32x4, get:z, Float32x4GetZ, 0x5d87c009)                              \
  V(_Float32x4, get:w, Float32x4GetW, 0x3fc8048b)                              \
  V(_Float32x4, *, Float32x4Mul, 0xe541f0a7)                                   \
  V(_Float32x4, /, Float32x4Div, 0xc090a382)                                   \
  V(_Float32x4, -, Float32x4Sub, 0xdd23e06a)                                   \
  V(_Float32x4, +, Float32x4Add, 0xb7eb15f9)                                   \
  V(_Float64x2, *, Float64x2Mul, 0x37522aa6)                                   \
  V(_Float64x2, /, Float64x2Div, 0x12a0e142)                                   \
  V(_Float64x2, -, Float64x2Sub, 0x2f341a69)                                   \
  V(_Float64x2, +, Float64x2Add, 0x09fb4ff8)                                   \

#define GRAPH_CORE_INTRINSICS_LIST(V)                                          \
  V(_Array, get:length, ObjectArrayLength, 0x5842648b)                         \
  V(_Array, [], ObjectArrayGetIndexed, 0x78e668b1)                             \
  V(_List, _setIndexed, ObjectArraySetIndexedUnchecked, 0xe6212a10)            \
  V(_GrowableList, get:length, GrowableArrayLength, 0x5842648b)                \
  V(_GrowableList, get:_capacity, GrowableArrayCapacity, 0x7d911012)           \
  V(_GrowableList, _setData, GrowableArraySetData, 0xbdcbb43b)                 \
  V(_GrowableList, _setLength, GrowableArraySetLength, 0xcc0d6dd6)             \
  V(_GrowableList, [], GrowableArrayGetIndexed, 0x78e668b1)                    \
  V(_GrowableList, _setIndexed, GrowableArraySetIndexedUnchecked, 0x513c774f)  \
  V(_StringBase, get:length, StringBaseLength, 0x5842648b)                     \
  V(_OneByteString, codeUnitAt, OneByteStringCodeUnitAt, 0x17ea7d30)           \
  V(_TwoByteString, codeUnitAt, TwoByteStringCodeUnitAt, 0x17ea7d30)           \
  V(_ExternalOneByteString, codeUnitAt, ExternalOneByteStringCodeUnitAt,       \
    0x17ea7d30)                                                                \
  V(_ExternalTwoByteString, codeUnitAt, ExternalTwoByteStringCodeUnitAt,       \
    0x17ea7d30)                                                                \
  V(_Smi, ~, Smi_bitNegate, 0x82466cfc)                                        \
  V(_IntegerImplementation, +, Integer_add, 0x6f06d26c)                        \
  V(_IntegerImplementation, -, Integer_sub, 0x630fe15d)                        \
  V(_IntegerImplementation, *, Integer_mul, 0x467f35fa)                        \
  V(_IntegerImplementation, %, Integer_mod, 0xd447d814)                        \
  V(_IntegerImplementation, ~/, Integer_truncDivide, 0x8cfa2a80)               \
  V(_IntegerImplementation, unary-, Integer_negate, 0x914f7873)                \
  V(_IntegerImplementation, &, Integer_bitAnd, 0x4253b969)                     \
  V(_IntegerImplementation, |, Integer_bitOr, 0x45fe3321)                      \
  V(_IntegerImplementation, ^, Integer_bitXor, 0x8eeefc28)                     \
  V(_IntegerImplementation, >>, Integer_sar, 0x49d5f8c0)                       \
  V(_IntegerImplementation, >>>, Integer_shr, 0x2b4c3522)                      \
  V(_Double, unary-, DoubleFlipSignBit, 0x3d2a7c4b)                            \

#define GRAPH_INTRINSICS_LIST(V)                                               \
  GRAPH_CORE_INTRINSICS_LIST(V)                                                \
  GRAPH_TYPED_DATA_INTRINSICS_LIST(V)                                          \

#define DEVELOPER_LIB_INTRINSIC_LIST(V)                                        \
  V(::, _getDefaultTag, UserTag_defaultTag, 0x6c0b3cc5)                        \
  V(::, _getCurrentTag, Profiler_getCurrentTag, 0x70dc44ae)                    \
  V(::, _isDartStreamEnabled, Timeline_isDartStreamEnabled, 0xc96c23d3)        \
  V(::, _getNextTaskId, Timeline_getNextTaskId, 0x5b1c7f2b)                    \

#define INTERNAL_LIB_INTRINSIC_LIST(V)                                         \
  V(::, allocateOneByteString, AllocateOneByteString, 0x9e68b9f5)              \
  V(::, allocateTwoByteString, AllocateTwoByteString, 0xa62df592)              \
  V(::, writeIntoOneByteString, WriteIntoOneByteString, 0xd8640581)            \
  V(::, writeIntoTwoByteString, WriteIntoTwoByteString, 0xcfb90c4a)            \

#define ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                  \
  CORE_LIB_INTRINSIC_LIST(V)                                                   \
  DEVELOPER_LIB_INTRINSIC_LIST(V)                                              \
  INTERNAL_LIB_INTRINSIC_LIST(V)                                               \

#define ALL_INTRINSICS_LIST(V)                                                 \
  ALL_INTRINSICS_NO_INTEGER_LIB_LIST(V)                                        \
  CORE_INTEGER_LIB_INTRINSIC_LIST(V)

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ALL_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(_StringBase, [], StringBaseCharAt, 0xd0613adf)                             \
  V(_TypedList, _getInt8, ByteArrayBaseGetInt8, 0x16155054)                    \
  V(_TypedList, _getUint8, ByteArrayBaseGetUint8, 0x1771724a)                  \
  V(_TypedList, _getInt16, ByteArrayBaseGetInt16, 0x2e320a6f)                  \
  V(_TypedList, _getUint16, ByteArrayBaseGetUint16, 0x2fb36ad9)                \
  V(_TypedList, _getInt32, ByteArrayBaseGetInt32, 0x1909a12a)                  \
  V(_TypedList, _getUint32, ByteArrayBaseGetUint32, 0x194ee29b)                \
  V(_TypedList, _getInt64, ByteArrayBaseGetInt64, 0xf652341f)                  \
  V(_TypedList, _getUint64, ByteArrayBaseGetUint64, 0x2c4ced79)                \
  V(_TypedList, _getFloat32, ByteArrayBaseGetFloat32, 0xe8e81527)              \
  V(_TypedList, _getFloat64, ByteArrayBaseGetFloat64, 0xf81baa54)              \
  V(_TypedList, _getFloat32x4, ByteArrayBaseGetFloat32x4, 0xaf1e8105)          \
  V(_TypedList, _getInt32x4, ByteArrayBaseGetInt32x4, 0x5564e82b)              \
  V(_TypedList, _setInt8, ByteArrayBaseSetInt8, 0xe17ab7c2)                    \
  V(_TypedList, _setUint8, ByteArrayBaseSetInt8, 0xaf4b2b68)                   \
  V(_TypedList, _setInt16, ByteArrayBaseSetInt16, 0xbad7b447)                  \
  V(_TypedList, _setUint16, ByteArrayBaseSetInt16, 0xce13bc6f)                 \
  V(_TypedList, _setInt32, ByteArrayBaseSetInt32, 0xbdcc1f60)                  \
  V(_TypedList, _setUint32, ByteArrayBaseSetUint32, 0xb95817d2)                \
  V(_TypedList, _setInt64, ByteArrayBaseSetInt64, 0xc8bec39a)                  \
  V(_TypedList, _setUint64, ByteArrayBaseSetUint64, 0xda38a625)                \
  V(_TypedList, _setFloat32, ByteArrayBaseSetFloat32, 0x2f27a200)              \
  V(_TypedList, _setFloat64, ByteArrayBaseSetFloat64, 0x234b6cf2)              \
  V(_TypedList, _setFloat32x4, ByteArrayBaseSetFloat32x4, 0x38b79d7a)          \
  V(_TypedList, _setInt32x4, ByteArrayBaseSetInt32x4, 0x5cda767b)              \
  V(Object, get:runtimeType, ObjectRuntimeType, 0x03733c71)

// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, _List, ., kArrayCid, 0x4c8eae02)                             \
  V(_ListFilledFactory, _List, .filled, kArrayCid, 0x92756a31)                 \
  V(_ListGenerateFactory, _List, .generate, kArrayCid, 0x428498ce)             \
  V(_GrowableListFactory, _GrowableList, ., kGrowableObjectArrayCid,           \
    0x3c90606d)                                                                \
  V(_GrowableListFilledFactory, _GrowableList, .filled,                        \
    kGrowableObjectArrayCid, 0xeae18bb1)                                       \
  V(_GrowableListGenerateFactory, _GrowableList, .generate,                    \
    kGrowableObjectArrayCid, 0x7be49a4e)                                       \
  V(_GrowableListWithData, _GrowableList, ._withData, kGrowableObjectArrayCid, \
    0x19394cc1)                                                                \
  V(_Int8ArrayFactory, Int8List, ., kTypedDataInt8ArrayCid, 0x65ff4ca8)        \
  V(_Uint8ArrayFactory, Uint8List, ., kTypedDataUint8ArrayCid, 0xedd56a6f)     \
  V(_Uint8ClampedArrayFactory, Uint8ClampedList, .,                            \
    kTypedDataUint8ClampedArrayCid, 0x27f7ab75)                                \
  V(_Int16ArrayFactory, Int16List, ., kTypedDataInt16ArrayCid, 0xd0bf0d13)     \
  V(_Uint16ArrayFactory, Uint16List, ., kTypedDataUint16ArrayCid, 0x3ca76f8a)  \
  V(_Int32ArrayFactory, Int32List, ., kTypedDataInt32ArrayCid, 0x1b816740)     \
  V(_Uint32ArrayFactory, Uint32List, ., kTypedDataUint32ArrayCid, 0x2b210eab)  \
  V(_Int64ArrayFactory, Int64List, ., kTypedDataInt64ArrayCid, 0xfb63524f)     \
  V(_Uint64ArrayFactory, Uint64List, ., kTypedDataUint64ArrayCid, 0xe3c14418)  \
  V(_Float64ArrayFactory, Float64List, ., kTypedDataFloat64ArrayCid,           \
    0xa0b7c2b1)                                                                \
  V(_Float32ArrayFactory, Float32List, ., kTypedDataFloat32ArrayCid,           \
    0xa381dd1e)                                                                \
  V(_Float32x4ArrayFactory, Float32x4List, ., kTypedDataFloat32x4ArrayCid,     \
    0x0a6eefa8)

// clang-format on

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
