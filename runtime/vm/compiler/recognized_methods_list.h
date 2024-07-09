// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
#define RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_

namespace dart {

// clang-format off
// (libary, class-name, function-name, recognized enum, fingerprint).
// When adding a new function, add a 0 as the fingerprint and run the build in
// debug mode to get the correct fingerprint from the mismatch error.
#define OTHER_RECOGNIZED_LIST(V)                                               \
  V(AsyncLibrary, _FutureListener, handleValue, FutureListenerHandleValue,     \
    0xec08b9f2)                                                                \
  V(AsyncLibrary, _SuspendState, get:_functionData,                            \
    SuspendState_getFunctionData, 0x7272eaae)                                  \
  V(AsyncLibrary, _SuspendState, set:_functionData,                            \
    SuspendState_setFunctionData, 0x2b4950eb)                                  \
  V(AsyncLibrary, _SuspendState, get:_thenCallback,                            \
    SuspendState_getThenCallback, 0x2b81e561)                                  \
  V(AsyncLibrary, _SuspendState, set:_thenCallback,                            \
    SuspendState_setThenCallback, 0x751f9d1e)                                  \
  V(AsyncLibrary, _SuspendState, get:_errorCallback,                           \
    SuspendState_getErrorCallback, 0xaeacef2f)                                 \
  V(AsyncLibrary, _SuspendState, set:_errorCallback,                           \
    SuspendState_setErrorCallback, 0xc3ebebec)                                 \
  V(AsyncLibrary, _SuspendState, _clone, SuspendState_clone, 0xadfd28e0)       \
  V(AsyncLibrary, _SuspendState, _resume, SuspendState_resume, 0x5d5d6cc9)     \
  V(ConvertLibrary, _Utf8Decoder, _scan, Utf8DecoderScan, 0xb9801ae2)          \
  V(CoreLibrary, ::, identical, ObjectIdentical, 0x03f96b55)                   \
  V(CoreLibrary, Object, Object., ObjectConstructor, 0xab6d6cf2)               \
  V(CoreLibrary, _Array, [], ObjectArrayGetIndexed, 0x78d7e092)                \
  V(CoreLibrary, _GrowableList, [], GrowableArrayGetIndexed, 0x78d7e092)       \
  V(CoreLibrary, _List, ., ObjectArrayAllocate, 0x4c802222)                    \
  V(CoreLibrary, _List, []=, ObjectArraySetIndexed, 0x3a23c6fa)                \
  V(CoreLibrary, _GrowableList, ._withData, GrowableArrayAllocateWithData,     \
    0x192ac0e1)                                                                \
  V(CoreLibrary, _GrowableList, []=, GrowableArraySetIndexed, 0x3a23c6fa)      \
  V(CoreLibrary, _Record, get:_fieldNames, Record_fieldNames, 0x68c8319e)      \
  V(CoreLibrary, _Record, get:_numFields, Record_numFields, 0x7ba4f393)        \
  V(CoreLibrary, _Record, get:_shape, Record_shape, 0x70c40933)                \
  V(CoreLibrary, _Record, _fieldAt, Record_fieldAt, 0xb47fa0b3)                \
  V(CoreLibrary, _StringBase, _interpolate, StringBaseInterpolate, 0xa2c902d2) \
  V(CoreLibrary, _StringBase, codeUnitAt, StringBaseCodeUnitAt, 0x17dbf511)    \
  V(CoreLibrary, _IntegerImplementation, toDouble, IntegerToDouble,            \
    0x97557386)                                                                \
  V(CoreLibrary, _Double, _add, DoubleAdd, 0xea494b67)                         \
  V(CoreLibrary, _Double, _sub, DoubleSub, 0x282a346e)                         \
  V(CoreLibrary, _Double, _mul, DoubleMul, 0x1f7bafac)                         \
  V(CoreLibrary, _Double, _div, DoubleDiv, 0x28601fd1)                         \
  V(CoreLibrary, _Double, _modulo, DoubleMod, 0xfd967c6e)                      \
  V(CoreLibrary, _Double, _remainder, DoubleRem, 0xf0f458d2)                   \
  V(CoreLibrary, _Double, ceil, DoubleCeilToInt, 0xcedbc005)                   \
  V(CoreLibrary, _Double, ceilToDouble, DoubleCeilToDouble, 0x5efeb358)        \
  V(CoreLibrary, _Double, floor, DoubleFloorToInt, 0x2a1527c8)                 \
  V(CoreLibrary, _Double, floorToDouble, DoubleFloorToDouble, 0x5497afc7)      \
  V(CoreLibrary, _Double, roundToDouble, DoubleRoundToDouble, 0x562cae7f)      \
  V(CoreLibrary, _Double, toInt, DoubleToInteger, 0x67520167)                  \
  V(CoreLibrary, _Double, truncateToDouble, DoubleTruncateToDouble,            \
    0x62b76ad8)                                                                \
  V(CoreLibrary, _FinalizerImpl, get:_callback, Finalizer_getCallback,         \
    0x1841a538)                                                                \
  V(CoreLibrary, _FinalizerImpl, set:_callback, Finalizer_setCallback,         \
    0xacee4675)                                                                \
  V(CoreLibrary, _WeakProperty, get:key, WeakProperty_getKey, 0xdde3cca2)      \
  V(CoreLibrary, _WeakProperty, set:key, WeakProperty_setKey, 0x961cf19f)      \
  V(CoreLibrary, _WeakProperty, get:value, WeakProperty_getValue, 0xd2d572ee)  \
  V(CoreLibrary, _WeakProperty, set:value, WeakProperty_setValue, 0x8b0e97eb)  \
  V(CoreLibrary, _WeakReference, get:target, WeakReference_getTarget,          \
    0xc972f9ca)                                                                \
  V(CoreLibrary, _WeakReference, set:_target, WeakReference_setTarget,         \
    0xc70c51ba)                                                                \
  V(CoreLibrary, _Smi, get:hashCode, Smi_hashCode, 0x75c3b512)                 \
  V(CoreLibrary, _Mint, get:hashCode, Mint_hashCode, 0x75c3b512)               \
  V(CoreLibrary, _Double, get:hashCode, Double_hashCode, 0x75c3b8d3)           \
  V(CollectionLibrary, _HashVMBase, get:_index, LinkedHashBase_getIndex,       \
    0x88095a1c)                                                                \
  V(CollectionLibrary, _HashVMBase, set:_index, LinkedHashBase_setIndex,       \
    0xa2a17c58)                                                                \
  V(CollectionLibrary, _HashVMBase, get:_data, LinkedHashBase_getData,         \
    0x2c6e46c3)                                                                \
  V(CollectionLibrary, _HashVMBase, set:_data, LinkedHashBase_setData,         \
    0x40dad7ff)                                                                \
  V(CollectionLibrary, _HashVMBase, get:_usedData, LinkedHashBase_getUsedData, \
    0x46eb7c2d)                                                                \
  V(CollectionLibrary, _HashVMBase, set:_usedData, LinkedHashBase_setUsedData, \
    0xb3ab6fe9)                                                                \
  V(CollectionLibrary, _HashVMBase, get:_hashMask, LinkedHashBase_getHashMask, \
    0x4ef1afdc)                                                                \
  V(CollectionLibrary, _HashVMBase, set:_hashMask, LinkedHashBase_setHashMask, \
    0xbbb1a398)                                                                \
  V(CollectionLibrary, _HashVMBase, get:_deletedKeys,                          \
    LinkedHashBase_getDeletedKeys, 0x50f0ace0)                                 \
  V(CollectionLibrary, _HashVMBase, set:_deletedKeys,                          \
    LinkedHashBase_setDeletedKeys, 0xbdb0a09c)                                 \
  V(CollectionLibrary, _HashVMImmutableBase, get:_data,                        \
    ImmutableLinkedHashBase_getData, 0x2c6e46c3)                               \
  V(CollectionLibrary, _HashVMImmutableBase, get:_indexNullable,               \
    ImmutableLinkedHashBase_getIndex, 0xfd6a643b)                              \
  V(CollectionLibrary, _HashVMImmutableBase, set:_index,                       \
    ImmutableLinkedHashBase_setIndexStoreRelease, 0xa2a17c58)                  \
  V(DeveloperLibrary, ::, get:extensionStreamHasListener,                      \
    ExtensionStreamHasListener, 0xfa975305)                                    \
  V(DeveloperLibrary, ::, debugger, Debugger, 0xf0aaff14)                      \
  V(FfiLibrary, _NativeFinalizer, get:_callback, NativeFinalizer_getCallback,  \
    0x5c965d35)                                                                \
  V(FfiLibrary, _NativeFinalizer, set:_callback, NativeFinalizer_setCallback,  \
    0xb1055132)                                                                \
  V(FfiLibrary, ::, _abi, FfiAbi, 0x7c2d9fb5)                                  \
  V(FfiLibrary, ::, _ffiCall, FfiCall, 0x610a5d82)                             \
  V(FfiLibrary, ::, _nativeCallbackFunction, FfiNativeCallbackFunction,        \
    0x3fd896dc)                                                                \
  V(FfiLibrary, ::, _nativeAsyncCallbackFunction,                              \
    FfiNativeAsyncCallbackFunction, 0xbeb62bd9)                                \
  V(FfiLibrary, ::, _nativeIsolateLocalCallbackFunction,                       \
    FfiNativeIsolateLocalCallbackFunction, 0x03d3193f)                         \
  V(FfiLibrary, ::, _loadAbiSpecificInt, FfiLoadAbiSpecificInt, 0x77ead473)    \
  V(FfiLibrary, ::, _loadAbiSpecificIntAtIndex, FfiLoadAbiSpecificIntAtIndex,  \
    0xaaab3b82)                                                                \
  V(FfiLibrary, ::, _loadInt8, FfiLoadInt8, 0x0ee7cbd7)                        \
  V(FfiLibrary, ::, _loadInt16, FfiLoadInt16, 0xec271d2e)                      \
  V(FfiLibrary, ::, _loadInt32, FfiLoadInt32, 0xee052bc4)                      \
  V(FfiLibrary, ::, _loadInt64, FfiLoadInt64, 0xded2aba4)                      \
  V(FfiLibrary, ::, _loadUint8, FfiLoadUint8, 0xe13108d2)                      \
  V(FfiLibrary, ::, _loadUint16, FfiLoadUint16, 0x0cb948eb)                    \
  V(FfiLibrary, ::, _loadUint32, FfiLoadUint32, 0xf6517c56)                    \
  V(FfiLibrary, ::, _loadUint64, FfiLoadUint64, 0x04e8e9cd)                    \
  V(FfiLibrary, ::, _loadFloat, FfiLoadFloat, 0xf8bc6c9d)                      \
  V(FfiLibrary, ::, _loadFloatUnaligned, FfiLoadFloatUnaligned, 0xc8abc83f)    \
  V(FfiLibrary, ::, _loadDouble, FfiLoadDouble, 0xf6efae59)                    \
  V(FfiLibrary, ::, _loadDoubleUnaligned, FfiLoadDoubleUnaligned, 0xc981a579)  \
  V(FfiLibrary, ::, _loadPointer, FfiLoadPointer, 0x99eaf904)                  \
  V(FfiLibrary, ::, _storeAbiSpecificInt, FfiStoreAbiSpecificInt, 0xc6ec40c1)  \
  V(FfiLibrary, ::, _storeAbiSpecificIntAtIndex,                               \
    FfiStoreAbiSpecificIntAtIndex, 0x5b77195f)                                 \
  V(FfiLibrary, ::, _storeInt8, FfiStoreInt8, 0xdf339b0d)                      \
  V(FfiLibrary, ::, _storeInt16, FfiStoreInt16, 0xd830df33)                    \
  V(FfiLibrary, ::, _storeInt32, FfiStoreInt32, 0xfbc9185e)                    \
  V(FfiLibrary, ::, _storeInt64, FfiStoreInt64, 0xf1b6f97b)                    \
  V(FfiLibrary, ::, _storeUint8, FfiStoreUint8, 0x0550bef7)                    \
  V(FfiLibrary, ::, _storeUint16, FfiStoreUint16, 0xe2e096df)                  \
  V(FfiLibrary, ::, _storeUint32, FfiStoreUint32, 0xe5bad4c6)                  \
  V(FfiLibrary, ::, _storeUint64, FfiStoreUint64, 0xe2bc1e3a)                  \
  V(FfiLibrary, ::, _storeFloat, FfiStoreFloat, 0x6467d8be)                    \
  V(FfiLibrary, ::, _storeFloatUnaligned, FfiStoreFloatUnaligned, 0x5fed7a43)  \
  V(FfiLibrary, ::, _storeDouble, FfiStoreDouble, 0x427c74a4)                  \
  V(FfiLibrary, ::, _storeDoubleUnaligned, FfiStoreDoubleUnaligned,            \
    0x3db1bf9b)                                                                \
  V(FfiLibrary, ::, _storePointer, FfiStorePointer, 0x8b4bcd59)                \
  V(FfiLibrary, ::, _fromAddress, FfiFromAddress, 0x81010e21)                  \
  V(FfiLibrary, Pointer, get:address, FfiGetAddress, 0x7cc16ffe)               \
  V(FfiLibrary, Native, _addressOf, FfiNativeAddressOf, 0x83966d9d)            \
  V(FfiLibrary, ::, _asExternalTypedDataInt8, FfiAsExternalTypedDataInt8,      \
    0x766cf299)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataInt16, FfiAsExternalTypedDataInt16,    \
    0xd07fe5c7)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataInt32, FfiAsExternalTypedDataInt32,    \
    0x38077547)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataInt64, FfiAsExternalTypedDataInt64,    \
    0xaf8d33fc)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataUint8, FfiAsExternalTypedDataUint8,    \
    0x35057435)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataUint16, FfiAsExternalTypedDataUint16,  \
    0x89880a3b)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataUint32, FfiAsExternalTypedDataUint32,  \
    0xd255c842)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataUint64, FfiAsExternalTypedDataUint64,  \
    0x06a15dc6)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataFloat, FfiAsExternalTypedDataFloat,    \
    0x6f294a0d)                                                                \
  V(FfiLibrary, ::, _asExternalTypedDataDouble, FfiAsExternalTypedDataDouble,  \
    0x40b0c5e2)                                                                \
  V(FfiLibrary, ::, _memCopy, MemCopy, 0x27323056)                             \
  V(FfiLibrary, ::, _checkNotDeeplyImmutable, CheckNotDeeplyImmutable,         \
    0x56383704)                                                                \
  V(InternalLibrary, ClassID, getID, ClassIDgetID, 0xdc6e70ca)                 \
  V(InternalLibrary, ::, _nativeEffect, NativeEffect, 0x5360b6d1)              \
  V(InternalLibrary, ::, reachabilityFence, ReachabilityFence, 0x72f213bf)     \
  V(InternalLibrary, ::, get:has63BitSmis, Has63BitSmis, 0xf5fe3f31)           \
  V(InternalLibrary, ::, copyRangeFromUint8ListToOneByteString,                \
    CopyRangeFromUint8ListToOneByteString, 0xcc3444c2)                         \
  V(InternalLibrary, FinalizerBase, get:_allEntries,                           \
    FinalizerBase_getAllEntries, 0xf022daab)                                   \
  V(InternalLibrary, FinalizerBase, set:_allEntries,                           \
    FinalizerBase_setAllEntries, 0x8eec0928)                                   \
  V(InternalLibrary, FinalizerBase, get:_detachments,                          \
    FinalizerBase_getDetachments, 0x2f47f776)                                  \
  V(InternalLibrary, FinalizerBase, set:_detachments,                          \
    FinalizerBase_setDetachments, 0x78720633)                                  \
  V(InternalLibrary, FinalizerBase, _exchangeEntriesCollectedWithNull,         \
    FinalizerBase_exchangeEntriesCollectedWithNull, 0x6c740d3b)                \
  V(InternalLibrary, FinalizerBase, _setIsolate, FinalizerBase_setIsolate,     \
    0xbcdac792)                                                                \
  V(InternalLibrary, FinalizerBase, get:_isolateFinalizers,                    \
    FinalizerBase_getIsolateFinalizers, 0x70d8272c)                            \
  V(InternalLibrary, FinalizerBase, set:_isolateFinalizers,                    \
    FinalizerBase_setIsolateFinalizers, 0xb3c95529)                            \
  V(InternalLibrary, FinalizerEntry, allocate, FinalizerEntry_allocate,        \
    0xe09dc0b8)                                                                \
  V(InternalLibrary, FinalizerEntry, get:value, FinalizerEntry_getValue,       \
    0xf5aca217)                                                                \
  V(InternalLibrary, FinalizerEntry, get:detach, FinalizerEntry_getDetach,     \
    0x16ffc1a8)                                                                \
  V(InternalLibrary, FinalizerEntry, get:token, FinalizerEntry_getToken,       \
    0x047442b2)                                                                \
  V(InternalLibrary, FinalizerEntry, set:token, FinalizerEntry_setToken,       \
    0x63ac552f)                                                                \
  V(InternalLibrary, FinalizerEntry, get:next, FinalizerEntry_getNext,         \
    0x70e5bfe4)                                                                \
  V(InternalLibrary, FinalizerEntry, get:externalSize,                         \
    FinalizerEntry_getExternalSize, 0x47c23923)                                \
  V(IsolateLibrary, _RawReceivePort, get:sendPort, ReceivePort_getSendPort,    \
    0xe69e58ad)                                                                \
  V(IsolateLibrary, _RawReceivePort, get:_handler, ReceivePort_getHandler,     \
    0xf1d64a73)                                                                \
  V(IsolateLibrary, _RawReceivePort, set:_handler, ReceivePort_setHandler,     \
    0x56ff3b70)                                                                \
  V(MathLibrary, ::, min, MathMin, 0x63eb7469)                                 \
  V(MathLibrary, ::, max, MathMax, 0xf9320c82)                                 \
  V(MathLibrary, ::, _doublePow, MathDoublePow, 0x428b8405)                    \
  V(MathLibrary, ::, _intPow, MathIntPow, 0xab39e81a)                          \
  V(MathLibrary, ::, _sin, MathSin, 0x17bdb243)                                \
  V(MathLibrary, ::, _cos, MathCos, 0xf4776585)                                \
  V(MathLibrary, ::, _tan, MathTan, 0xeafd3d77)                                \
  V(MathLibrary, ::, _asin, MathAsin, 0x29c7bdde)                              \
  V(MathLibrary, ::, _acos, MathAcos, 0x1fed891b)                              \
  V(MathLibrary, ::, _atan, MathAtan, 0x10dd4932)                              \
  V(MathLibrary, ::, _atan2, MathAtan2, 0x58b7d993)                            \
  V(MathLibrary, ::, _sqrt, MathSqrt, 0x02fb1bd0)                              \
  V(MathLibrary, ::, _exp, MathExp, 0x00d7e810)                                \
  V(MathLibrary, ::, _log, MathLog, 0x09916ca2)                                \
  V(NativeWrappersLibrary, ::, _getNativeField, GetNativeField, 0x9ff68786)    \
  V(TypedDataLibrary, _Int8List, [], Int8ArrayGetIndexed, 0x23133682)          \
  V(TypedDataLibrary, _ExternalInt8Array, [], ExternalInt8ArrayGetIndexed,     \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Int8ArrayView, [], Int8ArrayViewGetIndexed, 0x23133682) \
  V(TypedDataLibrary, _Uint8List, [], Uint8ArrayGetIndexed, 0x23133682)        \
  V(TypedDataLibrary, _ExternalUint8Array, [], ExternalUint8ArrayGetIndexed,   \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Uint8ArrayView, [], Uint8ArrayViewGetIndexed,           \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Uint8ClampedList, [], Uint8ClampedArrayGetIndexed,      \
    0x23133682)                                                                \
  V(TypedDataLibrary, _ExternalUint8ClampedArray, [],                          \
    ExternalUint8ClampedArrayGetIndexed, 0x23133682)                           \
  V(TypedDataLibrary, _Uint8ClampedArrayView, [],                              \
    Uint8ClampedArrayViewGetIndexed, 0x23133682)                               \
  V(TypedDataLibrary, _Int16List, [], Int16ArrayGetIndexed, 0x23133682)        \
  V(TypedDataLibrary, _ExternalInt16Array, [], ExternalInt16ArrayGetIndexed,   \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Int16ArrayView, [], Int16ArrayViewGetIndexed,           \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Uint16List, [], Uint16ArrayGetIndexed, 0x23133682)      \
  V(TypedDataLibrary, _ExternalUint16Array, [], ExternalUint16ArrayGetIndexed, \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Uint16ArrayView, [], Uint16ArrayViewGetIndexed,         \
    0x23133682)                                                                \
  V(TypedDataLibrary, _Int32List, [], Int32ArrayGetIndexed, 0x231332c1)        \
  V(TypedDataLibrary, _ExternalInt32Array, [], ExternalInt32ArrayGetIndexed,   \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Int32ArrayView, [], Int32ArrayViewGetIndexed,           \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Uint32List, [], Uint32ArrayGetIndexed, 0x231332c1)      \
  V(TypedDataLibrary, _ExternalUint32Array, [], ExternalUint32ArrayGetIndexed, \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Uint32ArrayView, [], Uint32ArrayViewGetIndexed,         \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Int64List, [], Int64ArrayGetIndexed, 0x231332c1)        \
  V(TypedDataLibrary, _ExternalInt64Array, [], ExternalInt64ArrayGetIndexed,   \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Int64ArrayView, [], Int64ArrayViewGetIndexed,           \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Uint64List, [], Uint64ArrayGetIndexed, 0x231332c1)      \
  V(TypedDataLibrary, _ExternalUint64Array, [], ExternalUint64ArrayGetIndexed, \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Uint64ArrayView, [], Uint64ArrayViewGetIndexed,         \
    0x231332c1)                                                                \
  V(TypedDataLibrary, _Float32List, [], Float32ArrayGetIndexed, 0x07764e5c)    \
  V(TypedDataLibrary, _ExternalFloat32Array, [],                               \
    ExternalFloat32ArrayGetIndexed, 0x07764e5c)                                \
  V(TypedDataLibrary, _Float32ArrayView, [], Float32ArrayViewGetIndexed,       \
    0x07764e5c)                                                                \
  V(TypedDataLibrary, _Float64List, [], Float64ArrayGetIndexed, 0x07764e5c)    \
  V(TypedDataLibrary, _ExternalFloat64Array, [],                               \
    ExternalFloat64ArrayGetIndexed, 0x07764e5c)                                \
  V(TypedDataLibrary, _Float64ArrayView, [], Float64ArrayViewGetIndexed,       \
    0x07764e5c)                                                                \
  V(TypedDataLibrary, _Float32x4List, [], Float32x4ArrayGetIndexed,            \
    0xb0e90a43)                                                                \
  V(TypedDataLibrary, _ExternalFloat32x4Array, [],                             \
    ExternalFloat32x4ArrayGetIndexed, 0xb0e90a43)                              \
  V(TypedDataLibrary, _Float32x4ArrayView, [], Float32x4ArrayViewGetIndexed,   \
    0xb0e90a43)                                                                \
  V(TypedDataLibrary, _Float64x2List, [], Float64x2ArrayGetIndexed,            \
    0x5fc75359)                                                                \
  V(TypedDataLibrary, _ExternalFloat64x2Array, [],                             \
    ExternalFloat64x2ArrayGetIndexed, 0x5fc75359)                              \
  V(TypedDataLibrary, _Float64x2ArrayView, [], Float64x2ArrayViewGetIndexed,   \
    0x5fc75359)                                                                \
  V(TypedDataLibrary, _Int32x4List, [], Int32x4ArrayGetIndexed, 0x4959642b)    \
  V(TypedDataLibrary, _ExternalInt32x4Array, [],                               \
    ExternalInt32x4ArrayGetIndexed, 0x4959642b)                                \
  V(TypedDataLibrary, _Int32x4ArrayView, [], Int32x4ArrayViewGetIndexed,       \
    0x4959642b)                                                                \
  V(TypedDataLibrary, _TypedList, _getInt8, TypedList_GetInt8, 0x1606c835)     \
  V(TypedDataLibrary, _TypedList, _getUint8, TypedList_GetUint8, 0x1762ea2b)   \
  V(TypedDataLibrary, _TypedList, _getInt16, TypedList_GetInt16, 0x2e238250)   \
  V(TypedDataLibrary, _TypedList, _getUint16, TypedList_GetUint16, 0x2fa4e2ba) \
  V(TypedDataLibrary, _TypedList, _getInt32, TypedList_GetInt32, 0x18fb190b)   \
  V(TypedDataLibrary, _TypedList, _getUint32, TypedList_GetUint32, 0x19405a7c) \
  V(TypedDataLibrary, _TypedList, _getInt64, TypedList_GetInt64, 0xf643ac00)   \
  V(TypedDataLibrary, _TypedList, _getUint64, TypedList_GetUint64, 0x2c3e655a) \
  V(TypedDataLibrary, _TypedList, _getFloat32, TypedList_GetFloat32,           \
    0xe8d98d08)                                                                \
  V(TypedDataLibrary, _TypedList, _getFloat64, TypedList_GetFloat64,           \
    0xf80d2235)                                                                \
  V(TypedDataLibrary, _TypedList, _getFloat32x4, TypedList_GetFloat32x4,       \
    0xaf0ff8e6)                                                                \
  V(TypedDataLibrary, _TypedList, _getFloat64x2, TypedList_GetFloat64x2,       \
    0x544018c1)                                                                \
  V(TypedDataLibrary, _TypedList, _getInt32x4, TypedList_GetInt32x4,           \
    0x5556600c)                                                                \
  V(TypedDataLibrary, _TypedList, _setInt8, TypedList_SetInt8, 0xe16c2fa3)     \
  V(TypedDataLibrary, _TypedList, _setUint8, TypedList_SetUint8, 0xaf3ca349)   \
  V(TypedDataLibrary, _TypedList, _setInt16, TypedList_SetInt16, 0xbac92c28)   \
  V(TypedDataLibrary, _TypedList, _setUint16, TypedList_SetUint16, 0xce053450) \
  V(TypedDataLibrary, _TypedList, _setInt32, TypedList_SetInt32, 0xbdbd9741)   \
  V(TypedDataLibrary, _TypedList, _setUint32, TypedList_SetUint32, 0xb9498fb3) \
  V(TypedDataLibrary, _TypedList, _setInt64, TypedList_SetInt64, 0xc8b03b7b)   \
  V(TypedDataLibrary, _TypedList, _setUint64, TypedList_SetUint64, 0xda2a1e06) \
  V(TypedDataLibrary, _TypedList, _setFloat32, TypedList_SetFloat32,           \
    0x2f1919e1)                                                                \
  V(TypedDataLibrary, _TypedList, _setFloat64, TypedList_SetFloat64,           \
    0x233ce4d3)                                                                \
  V(TypedDataLibrary, _TypedList, _setFloat32x4, TypedList_SetFloat32x4,       \
    0x38a9155b)                                                                \
  V(TypedDataLibrary, _TypedList, _setFloat64x2, TypedList_SetFloat64x2,       \
    0xbacdc340)                                                                \
  V(TypedDataLibrary, _TypedList, _setInt32x4, TypedList_SetInt32x4,           \
    0x5ccbee5c)                                                                \
  V(TypedDataLibrary, ByteData, ., ByteDataFactory, 0x0f140a3b)                \
  V(TypedDataLibrary, _ByteDataView, get:offsetInBytes,                        \
    ByteDataViewOffsetInBytes, 0x60b1da6c)                                     \
  V(TypedDataLibrary, _ByteDataView, get:_typedData, ByteDataViewTypedData,    \
    0xb9b44479)                                                                \
  V(TypedDataLibrary, _TypedListView, get:offsetInBytes,                       \
    TypedDataViewOffsetInBytes, 0x60b1da6c)                                    \
  V(TypedDataLibrary, _TypedListView, get:_typedData, TypedDataViewTypedData,  \
    0xb9b44479)                                                                \
  V(TypedDataLibrary, _ByteDataView, ._, TypedData_ByteDataView_factory,       \
    0x3169ff7d)                                                                \
  V(TypedDataLibrary, _Int8ArrayView, ._, TypedData_Int8ArrayView_factory,     \
    0x4438fdcb)                                                                \
  V(TypedDataLibrary, _Uint8ArrayView, ._, TypedData_Uint8ArrayView_factory,   \
    0x95e37496)                                                                \
  V(TypedDataLibrary, _Uint8ClampedArrayView, ._,                              \
    TypedData_Uint8ClampedArrayView_factory, 0x051c646a)                       \
  V(TypedDataLibrary, _Int16ArrayView, ._, TypedData_Int16ArrayView_factory,   \
    0x48f0ffdc)                                                                \
  V(TypedDataLibrary, _Uint16ArrayView, ._, TypedData_Uint16ArrayView_factory, \
    0x9fdbb233)                                                                \
  V(TypedDataLibrary, _Int32ArrayView, ._, TypedData_Int32ArrayView_factory,   \
    0xe2cc967a)                                                                \
  V(TypedDataLibrary, _Uint32ArrayView, ._, TypedData_Uint32ArrayView_factory, \
    0x8665a6a2)                                                                \
  V(TypedDataLibrary, _Int64ArrayView, ._, TypedData_Int64ArrayView_factory,   \
    0x12aa3ab0)                                                                \
  V(TypedDataLibrary, _Uint64ArrayView, ._, TypedData_Uint64ArrayView_factory, \
    0x25a95afe)                                                                \
  V(TypedDataLibrary, _Float32ArrayView, ._,                                   \
    TypedData_Float32ArrayView_factory, 0xdc797845)                            \
  V(TypedDataLibrary, _Float64ArrayView, ._,                                   \
    TypedData_Float64ArrayView_factory, 0xcb594118)                            \
  V(TypedDataLibrary, _Float32x4ArrayView, ._,                                 \
    TypedData_Float32x4ArrayView_factory, 0x66419ac1)                          \
  V(TypedDataLibrary, _Int32x4ArrayView, ._,                                   \
    TypedData_Int32x4ArrayView_factory, 0x04934906)                            \
  V(TypedDataLibrary, _Float64x2ArrayView, ._,                                 \
    TypedData_Float64x2ArrayView_factory, 0x42c547a5)                          \
  V(TypedDataLibrary, _UnmodifiableByteDataView, ._,                           \
    TypedData_UnmodifiableByteDataView_factory, 0x9ae1040c)                    \
  V(TypedDataLibrary, _UnmodifiableInt8ArrayView, ._,                          \
    TypedData_UnmodifiableInt8ArrayView_factory, 0x4f0e318b)                   \
  V(TypedDataLibrary, _UnmodifiableUint8ArrayView, ._,                         \
    TypedData_UnmodifiableUint8ArrayView_factory, 0x442b7c4a)                  \
  V(TypedDataLibrary, _UnmodifiableUint8ClampedArrayView, ._,                  \
    TypedData_UnmodifiableUint8ClampedArrayView_factory, 0x6a3bdd0e)           \
  V(TypedDataLibrary, _UnmodifiableInt16ArrayView, ._,                         \
    TypedData_UnmodifiableInt16ArrayView_factory, 0xb6cb193b)                  \
  V(TypedDataLibrary, _UnmodifiableUint16ArrayView, ._,                        \
    TypedData_UnmodifiableUint16ArrayView_factory, 0xa6bea3d7)                 \
  V(TypedDataLibrary, _UnmodifiableInt32ArrayView, ._,                         \
    TypedData_UnmodifiableInt32ArrayView_factory, 0x48e066e5)                  \
  V(TypedDataLibrary, _UnmodifiableUint32ArrayView, ._,                        \
    TypedData_UnmodifiableUint32ArrayView_factory, 0x9508a275)                 \
  V(TypedDataLibrary, _UnmodifiableInt64ArrayView, ._,                         \
    TypedData_UnmodifiableInt64ArrayView_factory, 0x7635c145)                  \
  V(TypedDataLibrary, _UnmodifiableUint64ArrayView, ._,                        \
    TypedData_UnmodifiableUint64ArrayView_factory, 0x3ffeb983)                 \
  V(TypedDataLibrary, _UnmodifiableFloat32ArrayView, ._,                       \
    TypedData_UnmodifiableFloat32ArrayView_factory, 0x5406ef8a)                \
  V(TypedDataLibrary, _UnmodifiableFloat64ArrayView, ._,                       \
    TypedData_UnmodifiableFloat64ArrayView_factory, 0xbf6cd86c)                \
  V(TypedDataLibrary, _UnmodifiableFloat32x4ArrayView, ._,                     \
    TypedData_UnmodifiableFloat32x4ArrayView_factory, 0x5f08d69b)              \
  V(TypedDataLibrary, _UnmodifiableInt32x4ArrayView, ._,                       \
    TypedData_UnmodifiableInt32x4ArrayView_factory, 0xf65dddb3)                \
  V(TypedDataLibrary, _UnmodifiableFloat64x2ArrayView, ._,                     \
    TypedData_UnmodifiableFloat64x2ArrayView_factory, 0x6d8c5a1b)              \
  V(TypedDataLibrary, Int8List, ., TypedData_Int8Array_factory, 0x65f0bd07)    \
  V(TypedDataLibrary, Uint8List, ., TypedData_Uint8Array_factory, 0xedc6dace)  \
  V(TypedDataLibrary, Uint8ClampedList, .,                                     \
    TypedData_Uint8ClampedArray_factory, 0x27e91bd4)                           \
  V(TypedDataLibrary, Int16List, ., TypedData_Int16Array_factory, 0xd0b07d72)  \
  V(TypedDataLibrary, Uint16List, ., TypedData_Uint16Array_factory,            \
    0x3c98dfe9)                                                                \
  V(TypedDataLibrary, Int32List, ., TypedData_Int32Array_factory, 0x1b72d79f)  \
  V(TypedDataLibrary, Uint32List, ., TypedData_Uint32Array_factory,            \
    0x2b127f0a)                                                                \
  V(TypedDataLibrary, Int64List, ., TypedData_Int64Array_factory, 0xfb54c2ae)  \
  V(TypedDataLibrary, Uint64List, ., TypedData_Uint64Array_factory,            \
    0xe3b2b477)                                                                \
  V(TypedDataLibrary, Float32List, ., TypedData_Float32Array_factory,          \
    0xa3734d7d)                                                                \
  V(TypedDataLibrary, Float64List, ., TypedData_Float64Array_factory,          \
    0xa0a93310)                                                                \
  V(TypedDataLibrary, Float32x4List, ., TypedData_Float32x4Array_factory,      \
    0x0a606007)                                                                \
  V(TypedDataLibrary, Int32x4List, ., TypedData_Int32x4Array_factory,          \
    0x59fa98ed)                                                                \
  V(TypedDataLibrary, Float64x2List, ., TypedData_Float64x2Array_factory,      \
    0xecade3e9)                                                                \
  V(TypedDataLibrary, _TypedListBase, _memMove1, TypedData_memMove1,           \
    0xd267f3d0)                                                                \
  V(TypedDataLibrary, _TypedListBase, _memMove2, TypedData_memMove2,           \
    0xed299fd6)                                                                \
  V(TypedDataLibrary, _TypedListBase, _memMove4, TypedData_memMove4,           \
    0xcfd4eb46)                                                                \
  V(TypedDataLibrary, _TypedListBase, _memMove8, TypedData_memMove8,           \
    0xd1ca5745)                                                                \
  V(TypedDataLibrary, _TypedListBase, _memMove16, TypedData_memMove16,         \
    0x077790f5)                                                                \
  V(TypedDataLibrary, ::, _typedDataIndexCheck, TypedDataIndexCheck,           \
    0x7912cea9)                                                                \
  V(TypedDataLibrary, ::, _byteDataByteOffsetCheck, ByteDataByteOffsetCheck,   \
    0xbaf71484)                                                                \
  V(TypedDataLibrary, Float32x4, _Float32x4FromDoubles, Float32x4FromDoubles,  \
    0x1828616b)                                                                \
  V(TypedDataLibrary, Float32x4, Float32x4.zero, Float32x4Zero, 0xd3992842)    \
  V(TypedDataLibrary, Float32x4, _Float32x4Splat, Float32x4Splat, 0x13883b03)  \
  V(TypedDataLibrary, Float32x4, Float32x4.fromInt32x4Bits,                    \
    Int32x4ToFloat32x4, 0x7eb87d82)                                            \
  V(TypedDataLibrary, Float32x4, Float32x4.fromFloat64x2,                      \
    Float64x2ToFloat32x4, 0x50a175cd)                                          \
  V(TypedDataLibrary, _Float32x4, shuffle, Float32x4Shuffle, 0xa7d4a02b)       \
  V(TypedDataLibrary, _Float32x4, shuffleMix, Float32x4ShuffleMix, 0x7983ab0c) \
  V(TypedDataLibrary, _Float32x4, get:signMask, Float32x4GetSignMask,          \
    0x7c4dfa2a)                                                                \
  V(TypedDataLibrary, _Float32x4, equal, Float32x4Equal, 0x443dd5b6)           \
  V(TypedDataLibrary, _Float32x4, greaterThan, Float32x4GreaterThan,           \
    0x523065bf)                                                                \
  V(TypedDataLibrary, _Float32x4, greaterThanOrEqual,                          \
    Float32x4GreaterThanOrEqual, 0x4e5149f7)                                   \
  V(TypedDataLibrary, _Float32x4, lessThan, Float32x4LessThan, 0x49fb595d)     \
  V(TypedDataLibrary, _Float32x4, lessThanOrEqual, Float32x4LessThanOrEqual,   \
    0x465a3b80)                                                                \
  V(TypedDataLibrary, _Float32x4, notEqual, Float32x4NotEqual, 0x64321d83)     \
  V(TypedDataLibrary, _Float32x4, min, Float32x4Min, 0xe40186d2)               \
  V(TypedDataLibrary, _Float32x4, max, Float32x4Max, 0xc63108a3)               \
  V(TypedDataLibrary, _Float32x4, scale, Float32x4Scale, 0xa39a3042)           \
  V(TypedDataLibrary, _Float32x4, sqrt, Float32x4Sqrt, 0xe4d9e2f2)             \
  V(TypedDataLibrary, _Float32x4, reciprocalSqrt, Float32x4ReciprocalSqrt,     \
    0xddbada78)                                                                \
  V(TypedDataLibrary, _Float32x4, reciprocal, Float32x4Reciprocal, 0xd4350ab2) \
  V(TypedDataLibrary, _Float32x4, unary-, Float32x4Negate, 0xe68eac52)         \
  V(TypedDataLibrary, _Float32x4, abs, Float32x4Abs, 0xeb296688)               \
  V(TypedDataLibrary, _Float32x4, clamp, Float32x4Clamp, 0x77b05a1d)           \
  V(TypedDataLibrary, _Float32x4, _withX, Float32x4WithX, 0xa2fa87ef)          \
  V(TypedDataLibrary, _Float32x4, _withY, Float32x4WithY, 0x9b9c9c83)          \
  V(TypedDataLibrary, _Float32x4, _withZ, Float32x4WithZ, 0x97b916e0)          \
  V(TypedDataLibrary, _Float32x4, _withW, Float32x4WithW, 0x95160a9b)          \
  V(TypedDataLibrary, Float64x2, _Float64x2FromDoubles, Float64x2FromDoubles,  \
    0xd83bc891)                                                                \
  V(TypedDataLibrary, Float64x2, Float64x2.zero, Float64x2Zero, 0x82777158)    \
  V(TypedDataLibrary, Float64x2, _Float64x2Splat, Float64x2Splat, 0x5af65404)  \
  V(TypedDataLibrary, Float64x2, Float64x2.fromFloat32x4,                      \
    Float32x4ToFloat64x2, 0x6e8a84a6)                                          \
  V(TypedDataLibrary, _Float64x2, get:x, Float64x2GetX, 0x3a1c6d70)            \
  V(TypedDataLibrary, _Float64x2, get:y, Float64x2GetY, 0x27adc893)            \
  V(TypedDataLibrary, _Float64x2, unary-, Float64x2Negate, 0x956cf568)         \
  V(TypedDataLibrary, _Float64x2, abs, Float64x2Abs, 0x9a07af9e)               \
  V(TypedDataLibrary, _Float64x2, clamp, Float64x2Clamp, 0xfdbefd73)           \
  V(TypedDataLibrary, _Float64x2, sqrt, Float64x2Sqrt, 0x93b82c08)             \
  V(TypedDataLibrary, _Float64x2, get:signMask, Float64x2GetSignMask,          \
    0x7c4dfa2a)                                                                \
  V(TypedDataLibrary, _Float64x2, scale, Float64x2Scale, 0x52787958)           \
  V(TypedDataLibrary, _Float64x2, _withX, Float64x2WithX, 0x51d8d105)          \
  V(TypedDataLibrary, _Float64x2, _withY, Float64x2WithY, 0x4a7ae599)          \
  V(TypedDataLibrary, _Float64x2, min, Float64x2Min, 0x3611c492)               \
  V(TypedDataLibrary, _Float64x2, max, Float64x2Max, 0x18414663)               \
  V(TypedDataLibrary, Int32x4, _Int32x4FromInts, Int32x4FromInts, 0xa8e3a570)  \
  V(TypedDataLibrary, Int32x4, _Int32x4FromBools, Int32x4FromBools,            \
    0xf54f7808)                                                                \
  V(TypedDataLibrary, Int32x4, Int32x4.fromFloat32x4Bits, Float32x4ToInt32x4,  \
    0x45555da1)                                                                \
  V(TypedDataLibrary, _Int32x4, get:flagX, Int32x4GetFlagX, 0xc281ec18)        \
  V(TypedDataLibrary, _Int32x4, get:flagY, Int32x4GetFlagY, 0xddf222f8)        \
  V(TypedDataLibrary, _Int32x4, get:flagZ, Int32x4GetFlagZ, 0xeb9bbe4b)        \
  V(TypedDataLibrary, _Int32x4, get:flagW, Int32x4GetFlagW, 0xf4bbd08c)        \
  V(TypedDataLibrary, _Int32x4, get:signMask, Int32x4GetSignMask, 0x7c4dfa2a)  \
  V(TypedDataLibrary, _Int32x4, shuffle, Int32x4Shuffle, 0x4044fa13)           \
  V(TypedDataLibrary, _Int32x4, shuffleMix, Int32x4ShuffleMix, 0x4fcb1cdc)     \
  V(TypedDataLibrary, _Int32x4, select, Int32x4Select, 0x68ad87e0)             \
  V(TypedDataLibrary, _Int32x4, _withFlagX, Int32x4WithFlagX, 0xb7c1e8a3)      \
  V(TypedDataLibrary, _Int32x4, _withFlagY, Int32x4WithFlagY, 0xa8b283e6)      \
  V(TypedDataLibrary, _Int32x4, _withFlagZ, Int32x4WithFlagZ, 0xa7e87094)      \
  V(TypedDataLibrary, _Int32x4, _withFlagW, Int32x4WithFlagW, 0xb316e198)      \

// List of assembler intrinsics:
// (library, class-name, function-name, intrinsification method, fingerprint).
#define ASM_INTRINSICS_LIST(V)                                                 \
  V(CoreLibrary, _Smi, get:bitLength, Smi_bitLength, 0x7a97f52b)               \
  V(CoreLibrary, _BigIntImpl, _lsh, Bigint_lsh, 0x3fc5ff22)                    \
  V(CoreLibrary, _BigIntImpl, _rsh, Bigint_rsh, 0xddf6be5f)                    \
  V(CoreLibrary, _BigIntImpl, _absAdd, Bigint_absAdd, 0x2aa56271)              \
  V(CoreLibrary, _BigIntImpl, _absSub, Bigint_absSub, 0x70f0b1eb)              \
  V(CoreLibrary, _BigIntImpl, _mulAdd, Bigint_mulAdd, 0x3d39643d)              \
  V(CoreLibrary, _BigIntImpl, _sqrAdd, Bigint_sqrAdd, 0x8f977e85)              \
  V(CoreLibrary, _BigIntImpl, _estimateQuotientDigit,                          \
    Bigint_estimateQuotientDigit, 0x16b87188)                                  \
  V(CoreLibrary, _BigIntMontgomeryReduction, _mulMod, Montgomery_mulMod,       \
    0xdc817794)                                                                \
  V(CoreLibrary, _Double, >, Double_greaterThan, 0x7af3b847)                   \
  V(CoreLibrary, _Double, >=, Double_greaterEqualThan, 0x4aa007b3)             \
  V(CoreLibrary, _Double, <, Double_lessThan, 0xd2fb73b4)                      \
  V(CoreLibrary, _Double, <=, Double_lessEqualThan, 0x024aa595)                \
  V(CoreLibrary, _Double, ==, Double_equal, 0xe9189b0a)                        \
  V(CoreLibrary, _Double, +, Double_add, 0xa7c8119f)                           \
  V(CoreLibrary, _Double, -, Double_sub, 0x9ab51df0)                           \
  V(CoreLibrary, _Double, *, Double_mul, 0xdc3c27ed)                           \
  V(CoreLibrary, _Double, /, Double_div, 0xd26ab629)                           \
  V(CoreLibrary, _Double, get:isNaN, Double_getIsNaN, 0xd46bef53)              \
  V(CoreLibrary, _Double, get:isInfinite, Double_getIsInfinite, 0xc4ddb412)    \
  V(CoreLibrary, _Double, get:isNegative, Double_getIsNegative, 0xd45438d1)    \
  V(CoreLibrary, _Double, _mulFromInteger, Double_mulFromInteger, 0xecd1beaf)  \
  V(CoreLibrary, _Double, .fromInteger, DoubleFromInteger, 0x7cf2c1d9)         \
  V(CoreLibrary, _RegExp, _ExecuteMatch, RegExp_ExecuteMatch, 0x98f4bd89)      \
  V(CoreLibrary, _RegExp, _ExecuteMatchSticky, RegExp_ExecuteMatchSticky,      \
    0x91c0704f)                                                                \
  V(CoreLibrary, Object, ==, ObjectEquals, 0x463b5870)                         \
  V(CoreLibrary, Object, get:runtimeType, ObjectRuntimeType, 0x0364b091)       \
  V(CoreLibrary, Object, _haveSameRuntimeType, ObjectHaveSameRuntimeType,      \
    0xce314ad5)                                                                \
  V(CoreLibrary, _StringBase, get:hashCode, String_getHashCode, 0x75c3bc94)    \
  V(CoreLibrary, _StringBase, get:_identityHashCode, String_identityHash,      \
    0x47885152)                                                                \
  V(CoreLibrary, _StringBase, get:isEmpty, StringBaseIsEmpty, 0x9859c593)      \
  V(CoreLibrary, _StringBase, _substringMatches, StringBaseSubstringMatches,   \
    0x85202ab2)                                                                \
  V(CoreLibrary, _StringBase, [], StringBaseCharAt, 0xd052aeff)                \
  V(CoreLibrary, _OneByteString, get:hashCode, OneByteString_getHashCode,      \
    0x75c3bc94)                                                                \
  V(CoreLibrary, _OneByteString, _substringUncheckedNative,                    \
    OneByteString_substringUnchecked, 0x9afb019e)                              \
  V(CoreLibrary, _OneByteString, ==, OneByteString_equality, 0x4e8cc609)       \
  V(CoreLibrary, _TwoByteString, ==, TwoByteString_equality, 0x4e8cc609)       \
  V(CoreLibrary, _AbstractType, get:hashCode, AbstractType_getHashCode,        \
    0x75c3bc94)                                                                \
  V(CoreLibrary, _AbstractType, ==, AbstractType_equality, 0x463b50ee)         \
  V(CoreLibrary, _Type, ==, Type_equality, 0x463b50ee)                         \
  V(CoreLibrary, ::, _getHash, Object_getHash, 0xc5f2df98)                     \
  V(CoreLibrary, _IntegerImplementation, >, Integer_greaterThan, 0xd9c2551b)   \
  V(CoreLibrary, _IntegerImplementation, ==, Integer_equal, 0x025d83d3)        \
  V(CoreLibrary, _IntegerImplementation, _equalToInteger,                      \
    Integer_equalToInteger, 0x70f20102)                                        \
  V(CoreLibrary, _IntegerImplementation, <, Integer_lessThan, 0xd2fb73b4)      \
  V(CoreLibrary, _IntegerImplementation, <=, Integer_lessEqualThan,            \
    0x024aa595)                                                                \
  V(CoreLibrary, _IntegerImplementation, >=, Integer_greaterEqualThan,         \
    0x4aa007b3)                                                                \
  V(CoreLibrary, _IntegerImplementation, <<, Integer_shl, 0x2d16ae7a)          \
  V(DeveloperLibrary, ::, _getDefaultTag, UserTag_defaultTag, 0x6bfcb0e5)      \
  V(DeveloperLibrary, ::, _getCurrentTag, Profiler_getCurrentTag, 0x70cdb8ce)  \
  V(DeveloperLibrary, ::, _isDartStreamEnabled, Timeline_isDartStreamEnabled,  \
    0xc95d97f3)                                                                \
  V(DeveloperLibrary, ::, _getNextTaskId, Timeline_getNextTaskId, 0x5b0df34b)  \
  V(InternalLibrary, ::, allocateOneByteString, AllocateOneByteString,         \
    0x9e5a2e15)                                                                \
  V(InternalLibrary, ::, allocateTwoByteString, AllocateTwoByteString,         \
    0xa61f69b2)                                                                \
  V(InternalLibrary, ::, writeIntoOneByteString, WriteIntoOneByteString,       \
    0xd85579a1)                                                                \
  V(InternalLibrary, ::, writeIntoTwoByteString, WriteIntoTwoByteString,       \
    0xcfaa806a)                                                                \

// List of graph intrinsics:
// (library, class-name, function-name, intrinsification method, fingerprint).
#define GRAPH_INTRINSICS_LIST(V)                                               \
  V(CoreLibrary, _Array, get:length, ObjectArrayLength, 0x5833d8ab)            \
  V(CoreLibrary, _List, _setIndexed, ObjectArraySetIndexedUnchecked,           \
    0xe6129e30)                                                                \
  V(CoreLibrary, _GrowableList, get:length, GrowableArrayLength, 0x5833d8ab)   \
  V(CoreLibrary, _GrowableList, get:_capacity, GrowableArrayCapacity,          \
    0x7d828432)                                                                \
  V(CoreLibrary, _GrowableList, _setData, GrowableArraySetData, 0xbdbd285b)    \
  V(CoreLibrary, _GrowableList, _setLength, GrowableArraySetLength,            \
    0xcbfee1f6)                                                                \
  V(CoreLibrary, _GrowableList, _setIndexed, GrowableArraySetIndexedUnchecked, \
    0x512deb6f)                                                                \
  V(CoreLibrary, _StringBase, get:length, StringBaseLength, 0x5833d8ab)        \
  V(CoreLibrary, _Smi, ~, Smi_bitNegate, 0x8237e11c)                           \
  V(CoreLibrary, _IntegerImplementation, +, Integer_add, 0x6ef842cb)           \
  V(CoreLibrary, _IntegerImplementation, -, Integer_sub, 0x630151bc)           \
  V(CoreLibrary, _IntegerImplementation, *, Integer_mul, 0x4670a659)           \
  V(CoreLibrary, _IntegerImplementation, %, Integer_mod, 0x708e24f8)           \
  V(CoreLibrary, _IntegerImplementation, ~/, Integer_truncDivide, 0x29407764)  \
  V(CoreLibrary, _IntegerImplementation, unary-, Integer_negate, 0x9140e8d2)   \
  V(CoreLibrary, _IntegerImplementation, &, Integer_bitAnd, 0x424529c8)        \
  V(CoreLibrary, _IntegerImplementation, |, Integer_bitOr, 0x45efa380)         \
  V(CoreLibrary, _IntegerImplementation, ^, Integer_bitXor, 0x8ee06c87)        \
  V(CoreLibrary, _IntegerImplementation, >>, Integer_sar, 0x49c7691f)          \
  V(CoreLibrary, _IntegerImplementation, >>>, Integer_shr, 0x2b3da581)         \
  V(CoreLibrary, _Double, unary-, DoubleFlipSignBit, 0x3d1bf06b)               \
  V(TypedDataLibrary, _Int8List, []=, Int8ArraySetIndexed, 0x02e93049)         \
  V(TypedDataLibrary, _Uint8List, []=, Uint8ArraySetIndexed, 0xc8ef5e7d)       \
  V(TypedDataLibrary, _ExternalUint8Array, []=, ExternalUint8ArraySetIndexed,  \
    0xc8ef5e7d)                                                                \
  V(TypedDataLibrary, _Uint8ClampedList, []=, Uint8ClampedArraySetIndexed,     \
    0x44f383c5)                                                                \
  V(TypedDataLibrary, _ExternalUint8ClampedArray, []=,                         \
    ExternalUint8ClampedArraySetIndexed, 0x44f383c5)                           \
  V(TypedDataLibrary, _Int16List, []=, Int16ArraySetIndexed, 0x3c444b9c)       \
  V(TypedDataLibrary, _Uint16List, []=, Uint16ArraySetIndexed, 0x96d4fe9c)     \
  V(TypedDataLibrary, _Int32List, []=, Int32ArraySetIndexed, 0x7ce3fb7c)       \
  V(TypedDataLibrary, _Uint32List, []=, Uint32ArraySetIndexed, 0xe4f7d33c)     \
  V(TypedDataLibrary, _Int64List, []=, Int64ArraySetIndexed, 0x671bf23c)       \
  V(TypedDataLibrary, _Uint64List, []=, Uint64ArraySetIndexed, 0x5e1499dc)     \
  V(TypedDataLibrary, _Float64List, []=, Float64ArraySetIndexed, 0x84c8ac62)   \
  V(TypedDataLibrary, _Float32List, []=, Float32ArraySetIndexed, 0x5e23a4a2)   \
  V(TypedDataLibrary, _Float32x4List, []=, Float32x4ArraySetIndexed,           \
    0xadb196fb)                                                                \
  V(TypedDataLibrary, _Int32x4List, []=, Int32x4ArraySetIndexed, 0xf37c3bf3)   \
  V(TypedDataLibrary, _Float64x2List, []=, Float64x2ArraySetIndexed,           \
    0xf3086b45)                                                                \
  V(TypedDataLibrary, _TypedListBase, get:length, TypedListBaseLength,         \
    0x5833d8ab)                                                                \
  V(TypedDataLibrary, _ByteDataView, get:length, ByteDataViewLength,           \
    0x5833d8ab)                                                                \
  V(TypedDataLibrary, _Float32x4, get:x, Float32x4GetX, 0x3a1c6d70)            \
  V(TypedDataLibrary, _Float32x4, get:y, Float32x4GetY, 0x27adc893)            \
  V(TypedDataLibrary, _Float32x4, get:z, Float32x4GetZ, 0x5d793429)            \
  V(TypedDataLibrary, _Float32x4, get:w, Float32x4GetW, 0x3fb978ab)            \
  V(TypedDataLibrary, _Float32x4, *, Float32x4Mul, 0xe53364c7)                 \
  V(TypedDataLibrary, _Float32x4, /, Float32x4Div, 0xc08217a2)                 \
  V(TypedDataLibrary, _Float32x4, -, Float32x4Sub, 0xdd15548a)                 \
  V(TypedDataLibrary, _Float32x4, +, Float32x4Add, 0xb7dc8a19)                 \
  V(TypedDataLibrary, _Float64x2, *, Float64x2Mul, 0x37439ec6)                 \
  V(TypedDataLibrary, _Float64x2, /, Float64x2Div, 0x12925562)                 \
  V(TypedDataLibrary, _Float64x2, -, Float64x2Sub, 0x2f258e89)                 \
  V(TypedDataLibrary, _Float64x2, +, Float64x2Add, 0x09ecc418)                 \

#define RECOGNIZED_LIST(V)                                                     \
  OTHER_RECOGNIZED_LIST(V)                                                     \
  ASM_INTRINSICS_LIST(V)                                                       \
  GRAPH_INTRINSICS_LIST(V)                                                     \

// A list of core functions that internally dispatch based on received id.
#define POLYMORPHIC_TARGET_LIST(V)                                             \
  V(CoreLibrary, _StringBase, [], StringBaseCharAt, 0xd052aeff)                \
  V(TypedDataLibrary, _TypedList, _getInt8, TypedList_GetInt8, 0x1606c835)     \
  V(TypedDataLibrary, _TypedList, _getUint8, TypedList_GetUint8, 0x1762ea2b)   \
  V(TypedDataLibrary, _TypedList, _getInt16, TypedList_GetInt16, 0x2e238250)   \
  V(TypedDataLibrary, _TypedList, _getUint16, TypedList_GetUint16, 0x2fa4e2ba) \
  V(TypedDataLibrary, _TypedList, _getInt32, TypedList_GetInt32, 0x18fb190b)   \
  V(TypedDataLibrary, _TypedList, _getUint32, TypedList_GetUint32, 0x19405a7c) \
  V(TypedDataLibrary, _TypedList, _getInt64, TypedList_GetInt64, 0xf643ac00)   \
  V(TypedDataLibrary, _TypedList, _getUint64, TypedList_GetUint64, 0x2c3e655a) \
  V(TypedDataLibrary, _TypedList, _getFloat32, TypedList_GetFloat32,           \
    0xe8d98d08)                                                                \
  V(TypedDataLibrary, _TypedList, _getFloat64, TypedList_GetFloat64,           \
    0xf80d2235)                                                                \
  V(TypedDataLibrary, _TypedList, _getFloat32x4, TypedList_GetFloat32x4,       \
    0xaf0ff8e6)                                                                \
  V(TypedDataLibrary, _TypedList, _getInt32x4, TypedList_GetInt32x4,           \
    0x5556600c)                                                                \
  V(TypedDataLibrary, _TypedList, _setInt8, TypedList_SetInt8, 0xe16c2fa3)     \
  V(TypedDataLibrary, _TypedList, _setUint8, TypedList_SetInt8, 0xaf3ca349)    \
  V(TypedDataLibrary, _TypedList, _setInt16, TypedList_SetInt16, 0xbac92c28)   \
  V(TypedDataLibrary, _TypedList, _setUint16, TypedList_SetInt16, 0xce053450)  \
  V(TypedDataLibrary, _TypedList, _setInt32, TypedList_SetInt32, 0xbdbd9741)   \
  V(TypedDataLibrary, _TypedList, _setUint32, TypedList_SetUint32, 0xb9498fb3) \
  V(TypedDataLibrary, _TypedList, _setInt64, TypedList_SetInt64, 0xc8b03b7b)   \
  V(TypedDataLibrary, _TypedList, _setUint64, TypedList_SetUint64, 0xda2a1e06) \
  V(TypedDataLibrary, _TypedList, _setFloat32, TypedList_SetFloat32,           \
    0x2f1919e1)                                                                \
  V(TypedDataLibrary, _TypedList, _setFloat64, TypedList_SetFloat64,           \
    0x233ce4d3)                                                                \
  V(TypedDataLibrary, _TypedList, _setFloat32x4, TypedList_SetFloat32x4,       \
    0x38a9155b)                                                                \
  V(TypedDataLibrary, _TypedList, _setInt32x4, TypedList_SetInt32x4,           \
    0x5ccbee5c)                                                                \
  V(CoreLibrary, Object, get:runtimeType, ObjectRuntimeType, 0x0364b091)       \

// List of recognized list factories:
// (factory-name-symbol, class-name-string, constructor-name-string,
//  result-cid, fingerprint).
#define RECOGNIZED_LIST_FACTORY_LIST(V)                                        \
  V(_ListFactory, CoreLibrary, _List, ., kArrayCid, 0x4c802222)                \
  V(_ListFilledFactory, CoreLibrary, _List, .filled, kArrayCid, 0x9266de51)    \
  V(_ListGenerateFactory, CoreLibrary, _List, .generate, kArrayCid,            \
    0x42760cee)                                                                \
  V(_GrowableListFactory, CoreLibrary, _GrowableList, .,                       \
    kGrowableObjectArrayCid, 0x3c81d48d)                                       \
  V(_GrowableListFilledFactory, CoreLibrary, _GrowableList, .filled,           \
    kGrowableObjectArrayCid, 0xead2ffd1)                                       \
  V(_GrowableListGenerateFactory, CoreLibrary, _GrowableList, .generate,       \
    kGrowableObjectArrayCid, 0x7bd60e6e)                                       \
  V(_GrowableListWithData, CoreLibrary, _GrowableList, ._withData,             \
    kGrowableObjectArrayCid, 0x192ac0e1)                                       \
  V(_Int8ArrayFactory, TypedDataLibrary, Int8List, ., kTypedDataInt8ArrayCid,  \
    0x65f0bd07)                                                                \
  V(_Uint8ArrayFactory, TypedDataLibrary, Uint8List, .,                        \
    kTypedDataUint8ArrayCid, 0xedc6dace)                                       \
  V(_Uint8ClampedArrayFactory, TypedDataLibrary, Uint8ClampedList, .,          \
    kTypedDataUint8ClampedArrayCid, 0x27e91bd4)                                \
  V(_Int16ArrayFactory, TypedDataLibrary, Int16List, .,                        \
    kTypedDataInt16ArrayCid, 0xd0b07d72)                                       \
  V(_Uint16ArrayFactory, TypedDataLibrary, Uint16List, .,                      \
    kTypedDataUint16ArrayCid, 0x3c98dfe9)                                      \
  V(_Int32ArrayFactory, TypedDataLibrary, Int32List, .,                        \
    kTypedDataInt32ArrayCid, 0x1b72d79f)                                       \
  V(_Uint32ArrayFactory, TypedDataLibrary, Uint32List, .,                      \
    kTypedDataUint32ArrayCid, 0x2b127f0a)                                      \
  V(_Int64ArrayFactory, TypedDataLibrary, Int64List, .,                        \
    kTypedDataInt64ArrayCid, 0xfb54c2ae)                                       \
  V(_Uint64ArrayFactory, TypedDataLibrary, Uint64List, .,                      \
    kTypedDataUint64ArrayCid, 0xe3b2b477)                                      \
  V(_Float64ArrayFactory, TypedDataLibrary, Float64List, .,                    \
    kTypedDataFloat64ArrayCid, 0xa0a93310)                                     \
  V(_Float32ArrayFactory, TypedDataLibrary, Float32List, .,                    \
    kTypedDataFloat32ArrayCid, 0xa3734d7d)                                     \
  V(_Float32x4ArrayFactory, TypedDataLibrary, Float32x4List, .,                \
    kTypedDataFloat32x4ArrayCid, 0x0a606007)

// clang-format on

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RECOGNIZED_METHODS_LIST_H_
