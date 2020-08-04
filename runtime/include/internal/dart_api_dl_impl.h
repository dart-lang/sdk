/*
 * Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_INTERNAL_DART_API_DL_IMPL_H_
#define RUNTIME_INCLUDE_INTERNAL_DART_API_DL_IMPL_H_

// dart_native_api.h symbols can be called on any thread.
#define DART_NATIVE_API_DL_SYMBOLS(F)                                          \
  /***** dart_native_api.h *****/                                              \
  /* Dart_Port */                                                              \
  F(Dart_PostCObject)                                                          \
  F(Dart_PostInteger)                                                          \
  F(Dart_NewNativePort)                                                        \
  F(Dart_CloseNativePort)

// dart_api.h symbols can only be called on Dart threads.
#define DART_API_DL_SYMBOLS(F)                                                 \
  /***** dart_api.h *****/                                                     \
  /* Errors */                                                                 \
  F(Dart_IsError)                                                              \
  F(Dart_IsApiError)                                                           \
  F(Dart_IsUnhandledExceptionError)                                            \
  F(Dart_IsCompilationError)                                                   \
  F(Dart_IsFatalError)                                                         \
  F(Dart_GetError)                                                             \
  F(Dart_ErrorHasException)                                                    \
  F(Dart_ErrorGetException)                                                    \
  F(Dart_ErrorGetStackTrace)                                                   \
  F(Dart_NewApiError)                                                          \
  F(Dart_NewCompilationError)                                                  \
  F(Dart_NewUnhandledExceptionError)                                           \
  F(Dart_PropagateError)                                                       \
  /* Dart_Handle, Dart_PersistentHandle, Dart_WeakPersistentHandle */          \
  F(Dart_NewPersistentHandle)                                                  \
  F(Dart_SetPersistentHandle)                                                  \
  F(Dart_HandleFromPersistent)                                                 \
  F(Dart_DeletePersistentHandle)                                               \
  F(Dart_NewWeakPersistentHandle)                                              \
  F(Dart_HandleFromWeakPersistent)                                             \
  F(Dart_DeleteWeakPersistentHandle)                                           \
  F(Dart_UpdateExternalSize)                                                   \
  F(Dart_NewFinalizableHandle)                                                 \
  F(Dart_DeleteFinalizableHandle)                                              \
  F(Dart_UpdateFinalizableExternalSize)                                        \
  /* Dart_Port */                                                              \
  F(Dart_Post)                                                                 \
  F(Dart_NewSendPort)                                                          \
  F(Dart_SendPortGetId)                                                        \
  /* Scopes */                                                                 \
  F(Dart_EnterScope)                                                           \
  F(Dart_ExitScope)                                                            \
  /* Extenders */                                                              \
  F(Dart_Allocate)                                                             \
  F(Dart_AllocateWithNativeFields)                                             \
  F(Dart_BooleanValue)                                                         \
  F(Dart_ClassLibrary)                                                         \
  F(Dart_ClassName)                                                            \
  F(Dart_Cleanup)                                                              \
  F(Dart_ClosureFunction)                                                      \
  F(Dart_CreateIsolateGroup)                                                   \
  F(Dart_CreateIsolateGroupFromKernel)                                         \
  F(Dart_CurrentIsolate)                                                       \
  F(Dart_CurrentIsolateData)                                                   \
  F(Dart_CurrentIsolateGroup)                                                  \
  F(Dart_CurrentIsolateGroupData)                                              \
  F(Dart_DebugName)                                                            \
  F(Dart_DoubleValue)                                                          \
  F(Dart_DumpNativeStackTrace)                                                 \
  F(Dart_EmptyString)                                                          \
  F(Dart_EnterIsolate)                                                         \
  F(Dart_ExitIsolate)                                                          \
  F(Dart_False)                                                                \
  F(Dart_FunctionIsStatic)                                                     \
  F(Dart_FunctionName)                                                         \
  F(Dart_FunctionOwner)                                                        \
  F(Dart_GetClass)                                                             \
  F(Dart_GetDataFromByteBuffer)                                                \
  F(Dart_GetField)                                                             \
  F(Dart_GetImportsOfScheme)                                                   \
  F(Dart_GetLoadedLibraries)                                                   \
  F(Dart_GetMessageNotifyCallback)                                             \
  F(Dart_GetNativeArgument)                                                    \
  F(Dart_GetNativeArgumentCount)                                               \
  F(Dart_GetNativeArguments)                                                   \
  F(Dart_GetNativeBooleanArgument)                                             \
  F(Dart_GetNativeDoubleArgument)                                              \
  F(Dart_GetNativeFieldsOfArgument)                                            \
  F(Dart_GetNativeInstanceField)                                               \
  F(Dart_GetNativeInstanceFieldCount)                                          \
  F(Dart_GetNativeIntegerArgument)                                             \
  F(Dart_GetNativeIsolateGroupData)                                            \
  F(Dart_GetNativeResolver)                                                    \
  F(Dart_SetNativeResolver)                                                    \
  F(Dart_GetNativeStringArgument)                                              \
  F(Dart_GetNativeSymbol)                                                      \
  F(Dart_GetNonNullableType)                                                   \
  F(Dart_GetNullableType)                                                      \
  F(Dart_GetPeer)                                                              \
  F(Dart_GetStaticMethodClosure)                                               \
  F(Dart_GetStickyError)                                                       \
  F(Dart_GetType)                                                              \
  F(Dart_GetTypeOfExternalTypedData)                                           \
  F(Dart_GetTypeOfTypedData)                                                   \
  F(Dart_HasStickyError)                                                       \
  F(Dart_IdentityEquals)                                                       \
  F(Dart_InstanceGetType)                                                      \
  F(Dart_IntegerFitsIntoInt64)                                                 \
  F(Dart_IntegerFitsIntoUint64)                                                \
  F(Dart_IntegerToHexCString)                                                  \
  F(Dart_IntegerToInt64)                                                       \
  F(Dart_IntegerToUint64)                                                      \
  F(Dart_Invoke)                                                               \
  F(Dart_InvokeClosure)                                                        \
  F(Dart_InvokeConstructor)                                                    \
  F(Dart_IsBoolean)                                                            \
  F(Dart_IsByteBuffer)                                                         \
  F(Dart_IsClosure)                                                            \
  F(Dart_IsDouble)                                                             \
  F(Dart_IsExternalString)                                                     \
  F(Dart_IsFunction)                                                           \
  F(Dart_IsFuture)                                                             \
  F(Dart_IsInstance)                                                           \
  F(Dart_IsInteger)                                                            \
  F(Dart_IsKernel)                                                             \
  F(Dart_IsKernelIsolate)                                                      \
  F(Dart_IsLegacyType)                                                         \
  F(Dart_IsLibrary)                                                            \
  F(Dart_IsList)                                                               \
  F(Dart_IsMap)                                                                \
  F(Dart_IsNonNullableType)                                                    \
  F(Dart_IsNull)                                                               \
  F(Dart_IsNumber)                                                             \
  F(Dart_IsolateData)                                                          \
  F(Dart_IsolateFlagsInitialize)                                               \
  F(Dart_IsolateGroupData)                                                     \
  F(Dart_IsolateMakeRunnable)                                                  \
  F(Dart_IsolateServiceId)                                                     \
  F(Dart_IsPausedOnExit)                                                       \
  F(Dart_IsPausedOnStart)                                                      \
  F(Dart_IsPrecompiledRuntime)                                                 \
  F(Dart_IsServiceIsolate)                                                     \
  F(Dart_IsString)                                                             \
  F(Dart_IsStringLatin1)                                                       \
  F(Dart_IsTearOff)                                                            \
  F(Dart_IsType)                                                               \
  F(Dart_IsTypedData)                                                          \
  F(Dart_IsTypeVariable)                                                       \
  F(Dart_IsVariable)                                                           \
  F(Dart_IsVMFlagSet)                                                          \
  F(Dart_KernelIsolateIsRunning)                                               \
  F(Dart_KernelListDependencies)                                               \
  F(Dart_KernelPort)                                                           \
  F(Dart_KillIsolate)                                                          \
  F(Dart_LibraryHandleError)                                                   \
  F(Dart_LibraryResolvedUrl)                                                   \
  F(Dart_LibraryUrl)                                                           \
  F(Dart_ListGetAsBytes)                                                       \
  F(Dart_ListGetAt)                                                            \
  F(Dart_ListGetRange)                                                         \
  F(Dart_ListLength)                                                           \
  F(Dart_ListSetAsBytes)                                                       \
  F(Dart_ListSetAt)                                                            \
  F(Dart_LoadLibraryFromKernel)                                                \
  F(Dart_LoadScriptFromKernel)                                                 \
  F(Dart_LookupLibrary)                                                        \
  F(Dart_MapContainsKey)                                                       \
  F(Dart_MapGetAt)                                                             \
  F(Dart_MapKeys)                                                              \
  F(Dart_New)                                                                  \
  F(Dart_NewBoolean)                                                           \
  F(Dart_NewByteBuffer)                                                        \
  F(Dart_NewDouble)                                                            \
  F(Dart_NewExternalLatin1String)                                              \
  F(Dart_NewExternalTypedData)                                                 \
  F(Dart_NewExternalTypedDataWithFinalizer)                                    \
  F(Dart_NewExternalUTF16String)                                               \
  F(Dart_NewInteger)                                                           \
  F(Dart_NewIntegerFromHexCString)                                             \
  F(Dart_NewIntegerFromUint64)                                                 \
  F(Dart_NewList)                                                              \
  F(Dart_NewListOf)                                                            \
  F(Dart_NewListOfType)                                                        \
  F(Dart_NewListOfTypeFilled)                                                  \
  F(Dart_NewStringFromCString)                                                 \
  F(Dart_NewStringFromUTF16)                                                   \
  F(Dart_NewStringFromUTF32)                                                   \
  F(Dart_NewStringFromUTF8)                                                    \
  F(Dart_NewTypedData)                                                         \
  F(Dart_NotifyIdle)                                                           \
  F(Dart_NotifyLowMemory)                                                      \
  F(Dart_Null)                                                                 \
  F(Dart_ObjectEquals)                                                         \
  F(Dart_ObjectIsType)                                                         \
  F(Dart_PrepareToAbort)                                                       \
  F(Dart_ReThrowException)                                                     \
  F(Dart_RootLibrary)                                                          \
  F(Dart_ScopeAllocate)                                                        \
  F(Dart_SetBooleanReturnValue)                                                \
  F(Dart_SetDartLibrarySourcesKernel)                                          \
  F(Dart_SetDoubleReturnValue)                                                 \
  F(Dart_SetEnvironmentCallback)                                               \
  F(Dart_SetField)                                                             \
  F(Dart_SetIntegerReturnValue)                                                \
  F(Dart_SetLibraryTagHandler)                                                 \
  F(Dart_SetMessageNotifyCallback)                                             \
  F(Dart_SetNativeInstanceField)                                               \
  F(Dart_SetPausedOnExit)                                                      \
  F(Dart_SetPausedOnStart)                                                     \
  F(Dart_SetPeer)                                                              \
  F(Dart_SetReturnValue)                                                       \
  F(Dart_SetRootLibrary)                                                       \
  F(Dart_SetShouldPauseOnExit)                                                 \
  F(Dart_SetShouldPauseOnStart)                                                \
  F(Dart_SetStickyError)                                                       \
  F(Dart_SetWeakHandleReturnValue)                                             \
  F(Dart_ShouldPauseOnExit)                                                    \
  F(Dart_ShouldPauseOnStart)                                                   \
  F(Dart_ShutdownIsolate)                                                      \
  F(Dart_StartProfiling)                                                       \
  F(Dart_StopProfiling)                                                        \
  F(Dart_StringGetProperties)                                                  \
  F(Dart_StringLength)                                                         \
  F(Dart_StringStorageSize)                                                    \
  F(Dart_StringToCString)                                                      \
  F(Dart_StringToLatin1)                                                       \
  F(Dart_StringToUTF16)                                                        \
  F(Dart_StringToUTF8)                                                         \
  F(Dart_ThreadDisableProfiling)                                               \
  F(Dart_ThreadEnableProfiling)                                                \
  F(Dart_ThrowException)                                                       \
  F(Dart_ToString)                                                             \
  F(Dart_True)                                                                 \
  F(Dart_TypedDataAcquireData)                                                 \
  F(Dart_TypedDataReleaseData)                                                 \
  F(Dart_TypeDynamic)                                                          \
  F(Dart_TypeNever)                                                            \
  F(Dart_TypeToNonNullableType)                                                \
  F(Dart_TypeToNullableType)                                                   \
  F(Dart_TypeVoid)                                                             \
  F(Dart_VersionString)                                                        \
  F(Dart_WaitForEvent)                                                         \
  F(Dart_WriteProfileToTimeline)                                               \

#define DART_API_ALL_DL_SYMBOLS(F)                                             \
  DART_NATIVE_API_DL_SYMBOLS(F)                                                \
  DART_API_DL_SYMBOLS(F)

struct DartApiEntry {
  const char* name;
  void (*function)();
};

struct DartApi {
  const int major;
  const int minor;
  const DartApiEntry* const functions;
};

#endif /* RUNTIME_INCLUDE_INTERNAL_DART_API_DL_IMPL_H_ */ /* NOLINT */
