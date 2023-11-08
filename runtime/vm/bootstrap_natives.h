// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BOOTSTRAP_NATIVES_H_
#define RUNTIME_VM_BOOTSTRAP_NATIVES_H_

#include "vm/native_entry.h"

// bootstrap dart natives used in the core dart library.

namespace dart {

// List of bootstrap native entry points used in the core dart library.
// V(function_name, argument_count)
#define BOOTSTRAP_NATIVE_LIST(V)                                               \
  V(AsyncStarMoveNext_debuggerStepCheck, 1)                                    \
  V(DartAsync_fatal, 1)                                                        \
  V(Object_equals, 2)                                                          \
  V(Object_getHash, 1)                                                         \
  V(Object_toString, 1)                                                        \
  V(Object_runtimeType, 1)                                                     \
  V(Object_haveSameRuntimeType, 2)                                             \
  V(Object_instanceOf, 4)                                                      \
  V(Object_simpleInstanceOf, 2)                                                \
  V(Function_apply, 2)                                                         \
  V(Closure_equals, 2)                                                         \
  V(Closure_computeHash, 1)                                                    \
  V(AbstractType_equality, 2)                                                  \
  V(AbstractType_getHashCode, 1)                                               \
  V(AbstractType_toString, 1)                                                  \
  V(Type_equality, 2)                                                          \
  V(LibraryPrefix_isLoaded, 1)                                                 \
  V(LibraryPrefix_setLoaded, 1)                                                \
  V(LibraryPrefix_loadingUnit, 1)                                              \
  V(LibraryPrefix_issueLoad, 1)                                                \
  V(Identical_comparison, 2)                                                   \
  V(Integer_bitAndFromInteger, 2)                                              \
  V(Integer_bitOrFromInteger, 2)                                               \
  V(Integer_bitXorFromInteger, 2)                                              \
  V(Integer_addFromInteger, 2)                                                 \
  V(Integer_subFromInteger, 2)                                                 \
  V(Integer_mulFromInteger, 2)                                                 \
  V(Integer_truncDivFromInteger, 2)                                            \
  V(Integer_moduloFromInteger, 2)                                              \
  V(Integer_greaterThanFromInteger, 2)                                         \
  V(Integer_equalToInteger, 2)                                                 \
  V(Integer_fromEnvironment, 3)                                                \
  V(Integer_parse, 1)                                                          \
  V(Integer_shlFromInteger, 2)                                                 \
  V(Integer_shrFromInteger, 2)                                                 \
  V(Integer_ushrFromInteger, 2)                                                \
  V(Bool_fromEnvironment, 3)                                                   \
  V(Bool_hasEnvironment, 2)                                                    \
  V(Capability_factory, 1)                                                     \
  V(Capability_equals, 2)                                                      \
  V(Capability_get_hashcode, 1)                                                \
  V(RawReceivePort_factory, 2)                                                 \
  V(RawReceivePort_get_id, 1)                                                  \
  V(RawReceivePort_closeInternal, 1)                                           \
  V(RawReceivePort_setActive, 2)                                               \
  V(RawReceivePort_getActive, 1)                                               \
  V(SendPort_get_id, 1)                                                        \
  V(SendPort_get_hashcode, 1)                                                  \
  V(SendPort_sendInternal_, 2)                                                 \
  V(Smi_bitNegate, 1)                                                          \
  V(Smi_bitLength, 1)                                                          \
  V(SuspendState_instantiateClosureWithFutureTypeArgument, 2)                  \
  V(Mint_bitNegate, 1)                                                         \
  V(Mint_bitLength, 1)                                                         \
  V(Developer_debugger, 2)                                                     \
  V(Developer_getIsolateIdFromSendPort, 1)                                     \
  V(Developer_getObjectId, 1)                                                  \
  V(Developer_getServerInfo, 1)                                                \
  V(Developer_getServiceMajorVersion, 0)                                       \
  V(Developer_getServiceMinorVersion, 0)                                       \
  V(Developer_inspect, 1)                                                      \
  V(Developer_lookupExtension, 1)                                              \
  V(Developer_registerExtension, 2)                                            \
  V(Developer_log, 8)                                                          \
  V(Developer_postEvent, 2)                                                    \
  V(Developer_webServerControl, 3)                                             \
  V(Developer_NativeRuntime_buildId, 0)                                        \
  V(Developer_NativeRuntime_writeHeapSnapshotToFile, 1)                        \
  V(Developer_reachability_barrier, 0)                                         \
  V(Double_getIsNegative, 1)                                                   \
  V(Double_getIsInfinite, 1)                                                   \
  V(Double_getIsNaN, 1)                                                        \
  V(Double_add, 2)                                                             \
  V(Double_sub, 2)                                                             \
  V(Double_mul, 2)                                                             \
  V(Double_div, 2)                                                             \
  V(Double_remainder, 2)                                                       \
  V(Double_modulo, 2)                                                          \
  V(Double_greaterThanFromInteger, 2)                                          \
  V(Double_equalToInteger, 2)                                                  \
  V(Double_greaterThan, 2)                                                     \
  V(Double_equal, 2)                                                           \
  V(Double_doubleFromInteger, 2)                                               \
  V(Double_round, 1)                                                           \
  V(Double_floor, 1)                                                           \
  V(Double_ceil, 1)                                                            \
  V(Double_truncate, 1)                                                        \
  V(Double_toInt, 1)                                                           \
  V(Double_parse, 3)                                                           \
  V(Double_toString, 1)                                                        \
  V(Double_toStringAsFixed, 2)                                                 \
  V(Double_toStringAsExponential, 2)                                           \
  V(Double_toStringAsPrecision, 2)                                             \
  V(Double_flipSignBit, 1)                                                     \
  V(RegExp_factory, 6)                                                         \
  V(RegExp_getPattern, 1)                                                      \
  V(RegExp_getIsMultiLine, 1)                                                  \
  V(RegExp_getIsCaseSensitive, 1)                                              \
  V(RegExp_getIsUnicode, 1)                                                    \
  V(RegExp_getIsDotAll, 1)                                                     \
  V(RegExp_getGroupCount, 1)                                                   \
  V(RegExp_getGroupNameMap, 1)                                                 \
  V(RegExp_ExecuteMatch, 3)                                                    \
  V(RegExp_ExecuteMatchSticky, 3)                                              \
  V(List_allocate, 2)                                                          \
  V(List_getIndexed, 2)                                                        \
  V(List_setIndexed, 3)                                                        \
  V(List_getLength, 1)                                                         \
  V(List_slice, 4)                                                             \
  V(ImmutableList_from, 4)                                                     \
  V(StringBase_createFromCodePoints, 3)                                        \
  V(StringBase_substringUnchecked, 3)                                          \
  V(StringBase_joinReplaceAllResult, 4)                                        \
  V(StringBase_intern, 1)                                                      \
  V(StringBuffer_createStringFromUint16Array, 3)                               \
  V(OneByteString_substringUnchecked, 3)                                       \
  V(OneByteString_allocateFromOneByteList, 3)                                  \
  V(TwoByteString_allocateFromTwoByteList, 3)                                  \
  V(String_getHashCode, 1)                                                     \
  V(String_getLength, 1)                                                       \
  V(String_charAt, 2)                                                          \
  V(String_codeUnitAt, 2)                                                      \
  V(String_concat, 2)                                                          \
  V(String_fromEnvironment, 3)                                                 \
  V(String_toLowerCase, 1)                                                     \
  V(String_toUpperCase, 1)                                                     \
  V(String_concatRange, 3)                                                     \
  V(Math_doublePow, 2)                                                         \
  V(Random_initialSeed, 0)                                                     \
  V(SecureRandom_getBytes, 1)                                                  \
  V(DateTime_currentTimeMicros, 0)                                             \
  V(DateTime_timeZoneName, 1)                                                  \
  V(DateTime_timeZoneOffsetInSeconds, 1)                                       \
  V(AssertionError_throwNew, 3)                                                \
  V(AssertionError_throwNewSource, 4)                                          \
  V(Error_throwWithStackTrace, 2)                                              \
  V(StackTrace_current, 0)                                                     \
  V(TypeError_throwNew, 4)                                                     \
  V(Stopwatch_now, 0)                                                          \
  V(Stopwatch_frequency, 0)                                                    \
  V(Timeline_getNextTaskId, 0)                                                 \
  V(Timeline_getTraceClock, 0)                                                 \
  V(Timeline_isDartStreamEnabled, 0)                                           \
  V(Timeline_reportTaskEvent, 5)                                               \
  V(TypedData_Int8Array_new, 2)                                                \
  V(TypedData_Uint8Array_new, 2)                                               \
  V(TypedData_Uint8ClampedArray_new, 2)                                        \
  V(TypedData_Int16Array_new, 2)                                               \
  V(TypedData_Uint16Array_new, 2)                                              \
  V(TypedData_Int32Array_new, 2)                                               \
  V(TypedData_Uint32Array_new, 2)                                              \
  V(TypedData_Int64Array_new, 2)                                               \
  V(TypedData_Uint64Array_new, 2)                                              \
  V(TypedData_Float32Array_new, 2)                                             \
  V(TypedData_Float64Array_new, 2)                                             \
  V(TypedData_Float32x4Array_new, 2)                                           \
  V(TypedData_Int32x4Array_new, 2)                                             \
  V(TypedData_Float64x2Array_new, 2)                                           \
  V(TypedDataBase_length, 1)                                                   \
  V(TypedDataBase_setClampedRange, 5)                                          \
  V(TypedData_GetInt8, 2)                                                      \
  V(TypedData_SetInt8, 3)                                                      \
  V(TypedData_GetUint8, 2)                                                     \
  V(TypedData_SetUint8, 3)                                                     \
  V(TypedData_GetInt16, 2)                                                     \
  V(TypedData_SetInt16, 3)                                                     \
  V(TypedData_GetUint16, 2)                                                    \
  V(TypedData_SetUint16, 3)                                                    \
  V(TypedData_GetInt32, 2)                                                     \
  V(TypedData_SetInt32, 3)                                                     \
  V(TypedData_GetUint32, 2)                                                    \
  V(TypedData_SetUint32, 3)                                                    \
  V(TypedData_GetInt64, 2)                                                     \
  V(TypedData_SetInt64, 3)                                                     \
  V(TypedData_GetUint64, 2)                                                    \
  V(TypedData_SetUint64, 3)                                                    \
  V(TypedData_GetFloat32, 2)                                                   \
  V(TypedData_SetFloat32, 3)                                                   \
  V(TypedData_GetFloat64, 2)                                                   \
  V(TypedData_SetFloat64, 3)                                                   \
  V(TypedData_GetFloat32x4, 2)                                                 \
  V(TypedData_SetFloat32x4, 3)                                                 \
  V(TypedData_GetInt32x4, 2)                                                   \
  V(TypedData_SetInt32x4, 3)                                                   \
  V(TypedData_GetFloat64x2, 2)                                                 \
  V(TypedData_SetFloat64x2, 3)                                                 \
  V(TypedDataView_ByteDataView_new, 4)                                         \
  V(TypedDataView_Int8ArrayView_new, 4)                                        \
  V(TypedDataView_Uint8ArrayView_new, 4)                                       \
  V(TypedDataView_Uint8ClampedArrayView_new, 4)                                \
  V(TypedDataView_Int16ArrayView_new, 4)                                       \
  V(TypedDataView_Uint16ArrayView_new, 4)                                      \
  V(TypedDataView_Int32ArrayView_new, 4)                                       \
  V(TypedDataView_Uint32ArrayView_new, 4)                                      \
  V(TypedDataView_Int64ArrayView_new, 4)                                       \
  V(TypedDataView_Uint64ArrayView_new, 4)                                      \
  V(TypedDataView_Float32ArrayView_new, 4)                                     \
  V(TypedDataView_Float64ArrayView_new, 4)                                     \
  V(TypedDataView_Float32x4ArrayView_new, 4)                                   \
  V(TypedDataView_Int32x4ArrayView_new, 4)                                     \
  V(TypedDataView_Float64x2ArrayView_new, 4)                                   \
  V(TypedDataView_offsetInBytes, 1)                                            \
  V(TypedDataView_typedData, 1)                                                \
  V(TypedDataView_UnmodifiableByteDataView_new, 4)                             \
  V(TypedDataView_UnmodifiableInt8ArrayView_new, 4)                            \
  V(TypedDataView_UnmodifiableUint8ArrayView_new, 4)                           \
  V(TypedDataView_UnmodifiableUint8ClampedArrayView_new, 4)                    \
  V(TypedDataView_UnmodifiableInt16ArrayView_new, 4)                           \
  V(TypedDataView_UnmodifiableUint16ArrayView_new, 4)                          \
  V(TypedDataView_UnmodifiableInt32ArrayView_new, 4)                           \
  V(TypedDataView_UnmodifiableUint32ArrayView_new, 4)                          \
  V(TypedDataView_UnmodifiableInt64ArrayView_new, 4)                           \
  V(TypedDataView_UnmodifiableUint64ArrayView_new, 4)                          \
  V(TypedDataView_UnmodifiableFloat32ArrayView_new, 4)                         \
  V(TypedDataView_UnmodifiableFloat64ArrayView_new, 4)                         \
  V(TypedDataView_UnmodifiableFloat32x4ArrayView_new, 4)                       \
  V(TypedDataView_UnmodifiableInt32x4ArrayView_new, 4)                         \
  V(TypedDataView_UnmodifiableFloat64x2ArrayView_new, 4)                       \
  V(Float32x4_fromDoubles, 4)                                                  \
  V(Float32x4_splat, 1)                                                        \
  V(Float32x4_fromInt32x4Bits, 2)                                              \
  V(Float32x4_fromFloat64x2, 2)                                                \
  V(Float32x4_zero, 1)                                                         \
  V(Float32x4_add, 2)                                                          \
  V(Float32x4_negate, 1)                                                       \
  V(Float32x4_sub, 2)                                                          \
  V(Float32x4_mul, 2)                                                          \
  V(Float32x4_div, 2)                                                          \
  V(Float32x4_cmplt, 2)                                                        \
  V(Float32x4_cmplte, 2)                                                       \
  V(Float32x4_cmpgt, 2)                                                        \
  V(Float32x4_cmpgte, 2)                                                       \
  V(Float32x4_cmpequal, 2)                                                     \
  V(Float32x4_cmpnequal, 2)                                                    \
  V(Float32x4_scale, 2)                                                        \
  V(Float32x4_abs, 1)                                                          \
  V(Float32x4_clamp, 3)                                                        \
  V(Float32x4_getX, 1)                                                         \
  V(Float32x4_getY, 1)                                                         \
  V(Float32x4_getZ, 1)                                                         \
  V(Float32x4_getW, 1)                                                         \
  V(Float32x4_getSignMask, 1)                                                  \
  V(Float32x4_shuffle, 2)                                                      \
  V(Float32x4_shuffleMix, 3)                                                   \
  V(Float32x4_setX, 2)                                                         \
  V(Float32x4_setY, 2)                                                         \
  V(Float32x4_setZ, 2)                                                         \
  V(Float32x4_setW, 2)                                                         \
  V(Float32x4_min, 2)                                                          \
  V(Float32x4_max, 2)                                                          \
  V(Float32x4_sqrt, 1)                                                         \
  V(Float32x4_reciprocal, 1)                                                   \
  V(Float32x4_reciprocalSqrt, 1)                                               \
  V(Float64x2_fromDoubles, 2)                                                  \
  V(Float64x2_splat, 1)                                                        \
  V(Float64x2_zero, 1)                                                         \
  V(Float64x2_fromFloat32x4, 2)                                                \
  V(Float64x2_add, 2)                                                          \
  V(Float64x2_negate, 1)                                                       \
  V(Float64x2_sub, 2)                                                          \
  V(Float64x2_mul, 2)                                                          \
  V(Float64x2_div, 2)                                                          \
  V(Float64x2_scale, 2)                                                        \
  V(Float64x2_abs, 1)                                                          \
  V(Float64x2_clamp, 3)                                                        \
  V(Float64x2_getX, 1)                                                         \
  V(Float64x2_getY, 1)                                                         \
  V(Float64x2_getSignMask, 1)                                                  \
  V(Float64x2_setX, 2)                                                         \
  V(Float64x2_setY, 2)                                                         \
  V(Float64x2_min, 2)                                                          \
  V(Float64x2_max, 2)                                                          \
  V(Float64x2_sqrt, 1)                                                         \
  V(Int32x4_fromInts, 4)                                                       \
  V(Int32x4_fromBools, 4)                                                      \
  V(Int32x4_fromFloat32x4Bits, 2)                                              \
  V(Int32x4_or, 2)                                                             \
  V(Int32x4_and, 2)                                                            \
  V(Int32x4_xor, 2)                                                            \
  V(Int32x4_add, 2)                                                            \
  V(Int32x4_sub, 2)                                                            \
  V(Int32x4_getX, 1)                                                           \
  V(Int32x4_getY, 1)                                                           \
  V(Int32x4_getZ, 1)                                                           \
  V(Int32x4_getW, 1)                                                           \
  V(Int32x4_setX, 2)                                                           \
  V(Int32x4_setY, 2)                                                           \
  V(Int32x4_setZ, 2)                                                           \
  V(Int32x4_setW, 2)                                                           \
  V(Int32x4_getSignMask, 1)                                                    \
  V(Int32x4_shuffle, 2)                                                        \
  V(Int32x4_shuffleMix, 3)                                                     \
  V(Int32x4_getFlagX, 1)                                                       \
  V(Int32x4_getFlagY, 1)                                                       \
  V(Int32x4_getFlagZ, 1)                                                       \
  V(Int32x4_getFlagW, 1)                                                       \
  V(Int32x4_setFlagX, 2)                                                       \
  V(Int32x4_setFlagY, 2)                                                       \
  V(Int32x4_setFlagZ, 2)                                                       \
  V(Int32x4_setFlagW, 2)                                                       \
  V(Int32x4_select, 3)                                                         \
  V(Isolate_exit_, 2)                                                          \
  V(Isolate_getCurrentRootUriStr, 0)                                           \
  V(Isolate_getDebugName, 1)                                                   \
  V(Isolate_getPortAndCapabilitiesOfCurrentIsolate, 0)                         \
  V(Isolate_registerKernelBlob, 1)                                             \
  V(Isolate_unregisterKernelBlob, 1)                                           \
  V(Isolate_sendOOB, 2)                                                        \
  V(Isolate_spawnFunction, 10)                                                 \
  V(Isolate_spawnUri, 12)                                                      \
  V(GrowableList_allocate, 2)                                                  \
  V(GrowableList_getIndexed, 2)                                                \
  V(GrowableList_setIndexed, 3)                                                \
  V(GrowableList_getLength, 1)                                                 \
  V(GrowableList_getCapacity, 1)                                               \
  V(GrowableList_setLength, 2)                                                 \
  V(GrowableList_setData, 2)                                                   \
  V(Internal_unsafeCast, 1)                                                    \
  V(Internal_nativeEffect, 1)                                                  \
  V(Internal_collectAllGarbage, 0)                                             \
  V(Internal_makeListFixedLength, 1)                                           \
  V(Internal_makeFixedListUnmodifiable, 1)                                     \
  V(Internal_extractTypeArguments, 2)                                          \
  V(Internal_prependTypeArguments, 4)                                          \
  V(Internal_boundsCheckForPartialInstantiation, 2)                            \
  V(Internal_allocateOneByteString, 1)                                         \
  V(Internal_allocateTwoByteString, 1)                                         \
  V(Internal_writeIntoOneByteString, 3)                                        \
  V(Internal_writeIntoTwoByteString, 3)                                        \
  V(Internal_deoptimizeFunctionsOnStack, 0)                                    \
  V(Internal_randomInstructionsOffsetInsideAllocateObjectStub, 0)              \
  V(InvocationMirror_unpackTypeArguments, 2)                                   \
  V(NoSuchMethodError_existingMethodSignature, 3)                              \
  V(Uri_isWindowsPlatform, 0)                                                  \
  V(UserTag_new, 2)                                                            \
  V(UserTag_label, 1)                                                          \
  V(UserTag_defaultTag, 0)                                                     \
  V(UserTag_makeCurrent, 1)                                                    \
  V(Profiler_getCurrentTag, 0)                                                 \
  V(VMService_SendIsolateServiceMessage, 2)                                    \
  V(VMService_SendRootServiceMessage, 1)                                       \
  V(VMService_SendObjectRootServiceMessage, 1)                                 \
  V(VMService_OnStart, 0)                                                      \
  V(VMService_OnExit, 0)                                                       \
  V(VMService_OnServerAddressChange, 1)                                        \
  V(VMService_ListenStream, 2)                                                 \
  V(VMService_CancelStream, 1)                                                 \
  V(VMService_RequestAssets, 0)                                                \
  V(VMService_DecodeAssets, 1)                                                 \
  V(VMService_AddUserTagsToStreamableSampleList, 1)                            \
  V(VMService_RemoveUserTagsFromStreamableSampleList, 1)                       \
  V(Ffi_asFunctionInternal, 2)                                                 \
  V(Ffi_createNativeCallableListener, 2)                                       \
  V(Ffi_createNativeCallableIsolateLocal, 3)                                   \
  V(Ffi_deleteNativeCallable, 1)                                               \
  V(Ffi_updateNativeCallableKeepIsolateAliveCounter, 1)                        \
  V(Ffi_dl_open, 1)                                                            \
  V(Ffi_dl_close, 1)                                                           \
  V(Ffi_dl_lookup, 2)                                                          \
  V(Ffi_dl_getHandle, 1)                                                       \
  V(Ffi_dl_providesSymbol, 2)                                                  \
  V(Ffi_dl_processLibrary, 0)                                                  \
  V(Ffi_dl_executableLibrary, 0)                                               \
  V(Ffi_GetFfiNativeResolver, 0)                                               \
  V(DartApiDLInitializeData, 0)                                                \
  V(DartApiDLMajorVersion, 0)                                                  \
  V(DartApiDLMinorVersion, 0)                                                  \
  V(DartNativeApiFunctionPointer, 1)                                           \
  V(TransferableTypedData_factory, 2)                                          \
  V(TransferableTypedData_materialize, 1)

// List of bootstrap native entry points used in the dart:mirror library.
#define MIRRORS_BOOTSTRAP_NATIVE_LIST(V)                                       \
  V(Mirrors_makeLocalClassMirror, 1)                                           \
  V(Mirrors_makeLocalTypeMirror, 1)                                            \
  V(Mirrors_instantiateGenericType, 2)                                         \
  V(Mirrors_mangleName, 2)                                                     \
  V(MirrorReference_equals, 2)                                                 \
  V(MirrorSystem_libraries, 0)                                                 \
  V(MirrorSystem_isolate, 0)                                                   \
  V(IsolateMirror_loadUri, 1)                                                  \
  V(InstanceMirror_invoke, 5)                                                  \
  V(InstanceMirror_invokeGetter, 3)                                            \
  V(InstanceMirror_invokeSetter, 4)                                            \
  V(InstanceMirror_computeType, 1)                                             \
  V(ClosureMirror_function, 1)                                                 \
  V(TypeMirror_subtypeTest, 2)                                                 \
  V(ClassMirror_libraryUri, 1)                                                 \
  V(ClassMirror_supertype, 1)                                                  \
  V(ClassMirror_supertype_instantiated, 1)                                     \
  V(ClassMirror_interfaces, 1)                                                 \
  V(ClassMirror_interfaces_instantiated, 1)                                    \
  V(ClassMirror_mixin, 1)                                                      \
  V(ClassMirror_mixin_instantiated, 2)                                         \
  V(ClassMirror_members, 3)                                                    \
  V(ClassMirror_constructors, 3)                                               \
  V(LibraryMirror_members, 2)                                                  \
  V(LibraryMirror_libraryDependencies, 2)                                      \
  V(ClassMirror_invoke, 5)                                                     \
  V(ClassMirror_invokeGetter, 3)                                               \
  V(ClassMirror_invokeSetter, 4)                                               \
  V(ClassMirror_invokeConstructor, 5)                                          \
  V(ClassMirror_type_variables, 1)                                             \
  V(ClassMirror_type_arguments, 1)                                             \
  V(LibraryMirror_fromPrefix, 1)                                               \
  V(LibraryMirror_invoke, 5)                                                   \
  V(LibraryMirror_invokeGetter, 3)                                             \
  V(LibraryMirror_invokeSetter, 4)                                             \
  V(TypeVariableMirror_owner, 1)                                               \
  V(TypeVariableMirror_upper_bound, 1)                                         \
  V(DeclarationMirror_location, 1)                                             \
  V(DeclarationMirror_metadata, 1)                                             \
  V(FunctionTypeMirror_call_method, 2)                                         \
  V(FunctionTypeMirror_parameters, 2)                                          \
  V(FunctionTypeMirror_return_type, 1)                                         \
  V(MethodMirror_owner, 2)                                                     \
  V(MethodMirror_parameters, 2)                                                \
  V(MethodMirror_return_type, 2)                                               \
  V(MethodMirror_source, 1)                                                    \
  V(ParameterMirror_type, 3)                                                   \
  V(VariableMirror_type, 2)

#define BOOTSTRAP_FFI_NATIVE_LIST(V)                                           \
  V(FinalizerEntry_SetExternalSize, void, (Dart_Handle, intptr_t))             \
  V(Pointer_asTypedListFinalizerAllocateData, void*, ())                       \
  V(Pointer_asTypedListFinalizerCallbackPointer, void*, ())

class BootstrapNatives : public AllStatic {
 public:
  static Dart_NativeFunction Lookup(Dart_Handle name,
                                    int argument_count,
                                    bool* auto_setup_scope);

  // For use with @Native.
  static void* LookupFfiNative(const char* name, uintptr_t argument_count);

  static const uint8_t* Symbol(Dart_NativeFunction nf);

#define DECLARE_BOOTSTRAP_NATIVE(name, ignored)                                \
  static ObjectPtr DN_##name(Thread* thread, Zone* zone,                       \
                             NativeArguments* arguments);

  BOOTSTRAP_NATIVE_LIST(DECLARE_BOOTSTRAP_NATIVE)
#if !defined(DART_PRECOMPILED_RUNTIME)
  MIRRORS_BOOTSTRAP_NATIVE_LIST(DECLARE_BOOTSTRAP_NATIVE)
#endif
#undef DECLARE_BOOTSTRAP_NATIVE

#define DECLARE_BOOTSTRAP_FFI_NATIVE(name, return_type, argument_types)        \
  static return_type FN_##name argument_types;
  BOOTSTRAP_FFI_NATIVE_LIST(DECLARE_BOOTSTRAP_FFI_NATIVE)
#undef DECLARE_BOOTSTRAP_FFI_NATIVE
};

}  // namespace dart

#endif  // RUNTIME_VM_BOOTSTRAP_NATIVES_H_
