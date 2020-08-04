/*
 * Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_DART_API_DL_H_
#define RUNTIME_INCLUDE_DART_API_DL_H_

#include "include/dart_api.h"
#include "include/dart_native_api.h"

/** \mainpage Dynamically Linked Dart API
 *
 * This exposes a subset of symbols from dart_api.h and dart_native_api.h
 * available in every Dart embedder through dynamic linking.
 *
 * All symbols are postfixed with _DL to indicate that they are dynamically
 * linked and to prevent conflicts with the original symbol.
 *
 * Link `dart_api_dl.cc` file into your library and invoke
 * `Dart_InitializeApiDL` with `NativeApi.initializeApiDLData`.
 */

intptr_t Dart_InitializeApiDL(void* data);

// IMPORTANT! Never update these signatures without properly updating
// DART_API_DL_MAJOR_VERSION and DART_API_DL_MINOR_VERSION.
//
// Verbatim copy of `dart_native_api.h` and `dart_api.h` symbols to trigger
// compile-time errors if the sybols in those files are updated without
// updating these.
//
// Function signatures and typedefs are carbon copied. Structs are typechecked
// nominally in C/C++, so they are not copied, instead a comment is added to
// their definition.
typedef int64_t Dart_Port_DL;

typedef void (*Dart_NativeMessageHandler_DL)(Dart_Port_DL dest_port_id,
                                             Dart_CObject* message);

DART_EXTERN_C bool (*Dart_PostCObject_DL)(Dart_Port_DL port_id,
                                          Dart_CObject* message);

DART_EXTERN_C bool (*Dart_PostInteger_DL)(Dart_Port_DL port_id,
                                          int64_t message);

DART_EXTERN_C Dart_Port_DL (*Dart_NewNativePort_DL)(
    const char* name,
    Dart_NativeMessageHandler_DL handler,
    bool handle_concurrently);

DART_EXTERN_C bool (*Dart_CloseNativePort_DL)(Dart_Port_DL native_port_id);

DART_EXTERN_C bool (*Dart_IsError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsApiError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsUnhandledExceptionError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsCompilationError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsFatalError_DL)(Dart_Handle handle);

DART_EXTERN_C const char* (*Dart_GetError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_ErrorHasException_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ErrorGetException_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ErrorGetStackTrace_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_NewApiError_DL)(const char* error);

DART_EXTERN_C Dart_Handle (*Dart_NewCompilationError_DL)(const char* error);

DART_EXTERN_C Dart_Handle (*Dart_NewUnhandledExceptionError_DL)(
    Dart_Handle exception);

DART_EXTERN_C void (*Dart_PropagateError_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ToString_DL)(Dart_Handle object);


DART_EXTERN_C bool (*Dart_IdentityEquals_DL)(Dart_Handle obj1,
                                             Dart_Handle obj2);

DART_EXTERN_C Dart_Handle (*Dart_HandleFromPersistent_DL)(
    Dart_PersistentHandle object);

DART_EXTERN_C Dart_Handle (*Dart_HandleFromWeakPersistent_DL)(
    Dart_WeakPersistentHandle object);

DART_EXTERN_C Dart_PersistentHandle (*Dart_NewPersistentHandle_DL)(
    Dart_Handle object);

DART_EXTERN_C void (*Dart_SetPersistentHandle_DL)(Dart_PersistentHandle obj1,
                                                  Dart_Handle obj2);

DART_EXTERN_C void (*Dart_DeletePersistentHandle_DL)(
    Dart_PersistentHandle object);

DART_EXTERN_C Dart_WeakPersistentHandle (*Dart_NewWeakPersistentHandle_DL)(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

DART_EXTERN_C void (*Dart_DeleteWeakPersistentHandle_DL)(
    Dart_WeakPersistentHandle object);

DART_EXTERN_C void (*Dart_UpdateExternalSize_DL)(
    Dart_WeakPersistentHandle object,
    intptr_t external_allocation_size);

DART_EXTERN_C Dart_FinalizableHandle (*Dart_NewFinalizableHandle_DL)(
    Dart_Handle object,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback);

DART_EXTERN_C void (*Dart_DeleteFinalizableHandle_DL)(
    Dart_FinalizableHandle object,
    Dart_Handle strong_ref_to_object);

DART_EXTERN_C void (*Dart_UpdateFinalizableExternalSize_DL)(
    Dart_FinalizableHandle object,
    Dart_Handle strong_ref_to_object,
    intptr_t external_allocation_size);

DART_EXTERN_C bool (*Dart_Post_DL)(Dart_Port_DL port_id, Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_NewSendPort_DL)(Dart_Port_DL port_id);

DART_EXTERN_C Dart_Handle (*Dart_SendPortGetId_DL)(Dart_Handle port,
                                                   Dart_Port_DL* port_id);

DART_EXTERN_C void (*Dart_EnterScope_DL)();

DART_EXTERN_C void (*Dart_ExitScope_DL)();

/* extenders*/

DART_EXTERN_C Dart_Handle (*Dart_Allocate_DL)(Dart_Handle type);

DART_EXTERN_C Dart_Handle (*Dart_AllocateWithNativeFields_DL)(
    Dart_Handle type,
    intptr_t num_native_fields,
    const intptr_t* native_fields);

DART_EXTERN_C Dart_Handle (*Dart_BooleanValue_DL)(Dart_Handle boolean_obj,
                                            bool* value);

DART_EXTERN_C Dart_Handle (*Dart_ClassLibrary_DL)(Dart_Handle cls_type);

DART_EXTERN_C Dart_Handle (*Dart_ClassName_DL)(Dart_Handle cls_type);

DART_EXTERN_C char* (*Dart_Cleanup_DL)();

DART_EXTERN_C Dart_Handle (*Dart_ClosureFunction_DL)(Dart_Handle closure);

DART_EXTERN_C Dart_Isolate (*Dart_CreateIsolateGroup_DL)(
    const char* script_uri,
    const char* name,
    const uint8_t* isolate_snapshot_data,
    const uint8_t* isolate_snapshot_instructions,
    Dart_IsolateFlags* flags,
    void* isolate_group_data,
    void* isolate_data,
    char** error);

DART_EXTERN_C Dart_Isolate (*Dart_CreateIsolateGroupFromKernel_DL)(
    const char* script_uri,
    const char* name,
    const uint8_t* kernel_buffer,
    intptr_t kernel_buffer_size,
    Dart_IsolateFlags* flags,
    void* isolate_group_data,
    void* isolate_data,
    char** error);

DART_EXTERN_C Dart_Isolate (*Dart_CurrentIsolate_DL)();

DART_EXTERN_C void* (*Dart_CurrentIsolateData_DL)();

DART_EXTERN_C Dart_IsolateGroup (*Dart_CurrentIsolateGroup_DL)();

DART_EXTERN_C void* (*Dart_CurrentIsolateGroupData_DL)();

DART_EXTERN_C Dart_Handle (*Dart_DebugName_DL)();

DART_EXTERN_C Dart_Handle (*Dart_DoubleValue_DL)(Dart_Handle double_obj,
                                           double* value);

DART_EXTERN_C void (*Dart_DumpNativeStackTrace_DL)(void* context);

DART_EXTERN_C Dart_Handle (*Dart_EmptyString_DL)();

DART_EXTERN_C void (*Dart_EnterIsolate_DL)(Dart_Isolate isolate);

DART_EXTERN_C void (*Dart_ExitIsolate_DL)();

DART_EXTERN_C Dart_Handle (*Dart_False_DL)();

DART_EXTERN_C Dart_Handle (*Dart_FunctionIsStatic_DL)(Dart_Handle function,
                                                bool* is_static);

DART_EXTERN_C Dart_Handle (*Dart_FunctionName_DL)(Dart_Handle function);

DART_EXTERN_C Dart_Handle (*Dart_FunctionOwner_DL)(Dart_Handle function);

DART_EXTERN_C Dart_Handle (*Dart_GetClass_DL)(Dart_Handle library,
                                        Dart_Handle class_name);

DART_EXTERN_C Dart_Handle (*Dart_GetDataFromByteBuffer_DL)(
    Dart_Handle byte_buffer);

DART_EXTERN_C Dart_Handle (*Dart_GetField_DL)(Dart_Handle container,
                                        Dart_Handle name);

DART_EXTERN_C Dart_Handle (*Dart_GetImportsOfScheme_DL)(Dart_Handle scheme);

DART_EXTERN_C Dart_Handle (*Dart_GetLoadedLibraries_DL)();

DART_EXTERN_C Dart_MessageNotifyCallback (*Dart_GetMessageNotifyCallback_DL)();

DART_EXTERN_C Dart_Handle (*Dart_GetNativeArguments_DL)(
    Dart_NativeArguments args,
    int num_arguments,
    const Dart_NativeArgument_Descriptor* arg_descriptors,
    Dart_NativeArgument_Value* arg_values);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeArgument_DL)(
    Dart_NativeArguments args,
    int index);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeBooleanArgument_DL)(
    Dart_NativeArguments args,
    int index,
    bool* value);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeDoubleArgument_DL)(
    Dart_NativeArguments args,
    int index,
    double* value);

DART_EXTERN_C int (*Dart_GetNativeArgumentCount_DL)(Dart_NativeArguments args);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeFieldsOfArgument_DL)(
    Dart_NativeArguments args,
    int arg_index,
    int num_fields,
    intptr_t* field_values);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeInstanceField_DL)(Dart_Handle obj,
                                                      int index,
                                                      intptr_t* value);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeInstanceFieldCount_DL)(
    Dart_Handle obj,
    int* count);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeIntegerArgument_DL)(
    Dart_NativeArguments args,
    int index,
    int64_t* value);

DART_EXTERN_C void* (*Dart_GetNativeIsolateGroupData_DL)(
    Dart_NativeArguments args);

DART_EXTERN_C Dart_Handle (*Dart_SetNativeResolver_DL)(Dart_Handle library,
    Dart_NativeEntryResolver resolver,
    Dart_NativeEntrySymbol symbol);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeResolver_DL)(Dart_Handle library, 
    Dart_NativeEntryResolver* resolver);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeStringArgument_DL)(
    Dart_NativeArguments args,
    int arg_index,
    void** peer);

DART_EXTERN_C Dart_Handle (*Dart_GetNativeSymbol_DL)(
    Dart_Handle library,
    Dart_NativeEntrySymbol* resolver);

DART_EXTERN_C Dart_Handle
(*Dart_GetNonNullableType_DL)(Dart_Handle library,
                        Dart_Handle class_name,
                        intptr_t number_of_type_arguments,
                        Dart_Handle* type_arguments);

DART_EXTERN_C Dart_Handle (*Dart_GetNullableType_DL)(
    Dart_Handle library,
    Dart_Handle class_name,
    intptr_t number_of_type_arguments,
    Dart_Handle* type_arguments);

DART_EXTERN_C Dart_Handle (*Dart_GetPeer_DL)(Dart_Handle object, void** peer);

DART_EXTERN_C Dart_Handle (*Dart_GetStaticMethodClosure_DL)(
    Dart_Handle library,
    Dart_Handle cls_type,
    Dart_Handle function_name);

DART_EXTERN_C Dart_Handle (*Dart_GetStickyError_DL)();

DART_EXTERN_C Dart_Handle (*Dart_GetType_DL)(Dart_Handle library,
                                       Dart_Handle class_name,
                                       intptr_t number_of_type_arguments,
                                       Dart_Handle* type_arguments);

DART_EXTERN_C Dart_TypedData_Type (*Dart_GetTypeOfExternalTypedData_DL)(
    Dart_Handle object);

DART_EXTERN_C Dart_TypedData_Type (*Dart_GetTypeOfTypedData_DL)(
    Dart_Handle object);

DART_EXTERN_C bool (*Dart_HasStickyError_DL)();

DART_EXTERN_C bool (*Dart_IdentityEquals_DL)(Dart_Handle obj1,
                                             Dart_Handle obj2);

DART_EXTERN_C Dart_Handle (*Dart_InstanceGetType_DL)(Dart_Handle instance);

DART_EXTERN_C Dart_Handle (*Dart_IntegerFitsIntoInt64_DL)(Dart_Handle integer,
                                                    bool* fits);

DART_EXTERN_C Dart_Handle (*Dart_IntegerFitsIntoUint64_DL)(Dart_Handle integer,
                                                     bool* fits);

DART_EXTERN_C Dart_Handle (*Dart_IntegerToHexCString_DL)(Dart_Handle integer,
                                                   const char** value);

DART_EXTERN_C Dart_Handle (*Dart_IntegerToInt64_DL)(Dart_Handle integer,
                                              int64_t* value);

DART_EXTERN_C Dart_Handle (*Dart_IntegerToUint64_DL)(Dart_Handle integer,
                                               uint64_t* value);

DART_EXTERN_C Dart_Handle (*Dart_Invoke_DL)(Dart_Handle target,
                                      Dart_Handle name,
                                      int number_of_arguments,
                                      Dart_Handle* arguments);

DART_EXTERN_C Dart_Handle
(*Dart_InvokeClosure_DL)(Dart_Handle closure,
                   int number_of_arguments,
                   Dart_Handle* arguments);

DART_EXTERN_C Dart_Handle
(*Dart_InvokeConstructor_DL)(Dart_Handle object,
                       Dart_Handle name,
                       int number_of_arguments,
                       Dart_Handle* arguments);

DART_EXTERN_C bool (*Dart_IsBoolean_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsByteBuffer_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsClosure_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsDouble_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsExternalString_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsFunction_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsFuture_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsInstance_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsInteger_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsKernel_DL)(const uint8_t* buffer,
    intptr_t buffer_size);

DART_EXTERN_C bool (*Dart_IsKernelIsolate_DL)(Dart_Isolate isolate);

DART_EXTERN_C Dart_Handle (*Dart_IsLegacyType_DL)(Dart_Handle type,
    bool* result);

DART_EXTERN_C bool (*Dart_IsLibrary_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsList_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsMap_DL)(Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_IsNonNullableType_DL)(Dart_Handle type,
                                                bool* result);

DART_EXTERN_C bool (*Dart_IsNull_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsNumber_DL)(Dart_Handle object);

DART_EXTERN_C void* (*Dart_IsolateData_DL)(Dart_Isolate isolate);

DART_EXTERN_C void (*Dart_IsolateFlagsInitialize_DL)(Dart_IsolateFlags* flags);

DART_EXTERN_C void* (*Dart_IsolateGroupData_DL)(Dart_Isolate isolate);

DART_EXTERN_C char* (*Dart_IsolateMakeRunnable_DL)(Dart_Isolate isolate);

DART_EXTERN_C const char* (*Dart_IsolateServiceId_DL)(Dart_Isolate isolate);

DART_EXTERN_C bool (*Dart_IsPausedOnExit_DL)();

DART_EXTERN_C bool (*Dart_IsPausedOnStart_DL)();

DART_EXTERN_C bool (*Dart_IsPrecompiledRuntime_DL)();

DART_EXTERN_C bool (*Dart_IsServiceIsolate_DL)(Dart_Isolate isolate);

DART_EXTERN_C bool (*Dart_IsString_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsStringLatin1_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsTearOff_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsType_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsTypedData_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IsTypeVariable_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsVariable_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsVMFlagSet_DL)(const char* flag_name);

DART_EXTERN_C bool (*Dart_KernelIsolateIsRunning_DL)();

DART_EXTERN_C Dart_KernelCompilationResult (*Dart_KernelListDependencies_DL)();

DART_EXTERN_C Dart_Port (*Dart_KernelPort_DL)();

DART_EXTERN_C void (*Dart_KillIsolate_DL)(Dart_Isolate isolate);

DART_EXTERN_C Dart_Handle (*Dart_LibraryHandleError_DL)(Dart_Handle library,
                                                  Dart_Handle error);

DART_EXTERN_C Dart_Handle (*Dart_LibraryResolvedUrl_DL)(Dart_Handle library);

DART_EXTERN_C Dart_Handle (*Dart_LibraryUrl_DL)(Dart_Handle library);

DART_EXTERN_C Dart_Handle (*Dart_ListGetAsBytes_DL)(Dart_Handle list,
                                              intptr_t offset,
                                              uint8_t* native_array,
                                              intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_ListGetAt_DL)(Dart_Handle list,
                                               intptr_t index);

DART_EXTERN_C Dart_Handle (*Dart_ListGetRange_DL)(Dart_Handle list,
                                            intptr_t offset,
                                            intptr_t length,
                                            Dart_Handle* result);

DART_EXTERN_C Dart_Handle (*Dart_ListLength_DL)(Dart_Handle list,
                                                intptr_t* length);

DART_EXTERN_C Dart_Handle (*Dart_ListSetAsBytes_DL)(Dart_Handle list,
                                              intptr_t offset,
                                              const uint8_t* native_array,
                                              intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_ListSetAt_DL)(Dart_Handle list,
                                         intptr_t index,
                                         Dart_Handle value);

DART_EXTERN_C Dart_Handle (*Dart_LoadLibraryFromKernel_DL)(
    const uint8_t* kernel_buffer,
    intptr_t kernel_buffer_size);

DART_EXTERN_C Dart_Handle (*Dart_LoadScriptFromKernel_DL)(
    const uint8_t* kernel_buffer,
    intptr_t kernel_size);

DART_EXTERN_C Dart_Handle (*Dart_LookupLibrary_DL)(Dart_Handle url);

DART_EXTERN_C Dart_Handle (*Dart_MapContainsKey_DL)(Dart_Handle map, 
                                                    Dart_Handle key);

DART_EXTERN_C Dart_Handle (*Dart_MapGetAt_DL)(Dart_Handle map, Dart_Handle key);

DART_EXTERN_C Dart_Handle (*Dart_MapKeys_DL)(Dart_Handle map);

DART_EXTERN_C Dart_Handle (*Dart_New_DL)(Dart_Handle type,
                                   Dart_Handle constructor_name,
                                   int number_of_arguments,
                                   Dart_Handle* arguments);

DART_EXTERN_C Dart_Handle (*Dart_NewBoolean_DL)(bool value);

DART_EXTERN_C Dart_Handle (*Dart_NewByteBuffer_DL)(Dart_Handle typed_data);

DART_EXTERN_C Dart_Handle (*Dart_NewDouble_DL)(double value);

DART_EXTERN_C Dart_Handle (*Dart_NewExternalLatin1String_DL)(
    const uint8_t* latin1_array,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

DART_EXTERN_C Dart_Handle (*Dart_NewExternalTypedData_DL)(
    Dart_TypedData_Type type,
    void* data,
    intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewExternalTypedDataWithFinalizer_DL)(
    Dart_TypedData_Type type,
    void* data,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

DART_EXTERN_C Dart_Handle (*Dart_NewExternalUTF16String_DL)(
    const uint16_t* utf16_array,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_WeakPersistentHandleFinalizer callback);

DART_EXTERN_C Dart_Handle (*Dart_NewInteger_DL)(int64_t value);

DART_EXTERN_C Dart_Handle (*Dart_NewIntegerFromHexCString_DL)(
    const char* value);

DART_EXTERN_C Dart_Handle (*Dart_NewIntegerFromUint64_DL)(uint64_t value);

DART_EXTERN_C Dart_Handle (*Dart_NewList_DL)(intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewListOf_DL)(Dart_CoreType_Id element_type_id,
                                         intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewListOfType_DL)(Dart_Handle element_type,
                                             intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewListOfTypeFilled_DL)(
    Dart_Handle element_type,
    Dart_Handle fill_object,
    intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewStringFromCString_DL)(const char* str);

DART_EXTERN_C Dart_Handle (*Dart_NewStringFromUTF16_DL)(
    const uint16_t* utf16_array,
    intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewStringFromUTF32_DL)(
    const int32_t* utf32_array,
    intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewStringFromUTF8_DL)(
    const uint8_t* utf8_array,
    intptr_t length);

DART_EXTERN_C Dart_Handle (*Dart_NewTypedData_DL)(Dart_TypedData_Type type,
                                            intptr_t length);

DART_EXTERN_C void (*Dart_NotifyIdle_DL)(int64_t deadline);

DART_EXTERN_C void (*Dart_NotifyLowMemory_DL)();

DART_EXTERN_C Dart_Handle (*Dart_Null_DL)();

DART_EXTERN_C Dart_Handle (*Dart_ObjectEquals_DL)(Dart_Handle obj1,
                                            Dart_Handle obj2,
                                            bool* equal);

DART_EXTERN_C Dart_Handle (*Dart_ObjectIsType_DL)(Dart_Handle object,
                                            Dart_Handle type,
                                            bool*  instanceof);

DART_EXTERN_C void (*Dart_PrepareToAbort_DL)();

DART_EXTERN_C Dart_Handle (*Dart_ReThrowException_DL)(Dart_Handle exception,
                                                Dart_Handle stacktrace);

DART_EXTERN_C Dart_Handle (*Dart_RootLibrary_DL)();

DART_EXTERN_C uint8_t* (*Dart_ScopeAllocate_DL)(intptr_t size);

DART_EXTERN_C void (*Dart_SetBooleanReturnValue_DL)(Dart_NativeArguments args,
                                              bool retval);

DART_EXTERN_C void (*Dart_SetDartLibrarySourcesKernel_DL)(
    const uint8_t* platform_kernel,
    const intptr_t platform_kernel_size);

DART_EXTERN_C void (*Dart_SetDoubleReturnValue_DL)(Dart_NativeArguments args,
                                             double retval);

DART_EXTERN_C Dart_Handle (*Dart_SetEnvironmentCallback_DL)(
    Dart_EnvironmentCallback callback);

DART_EXTERN_C Dart_Handle (*Dart_SetField_DL)(Dart_Handle container,
                                        Dart_Handle name,
                                        Dart_Handle value);

DART_EXTERN_C void (*Dart_SetIntegerReturnValue_DL)(Dart_NativeArguments args,
                                              int64_t retval);

DART_EXTERN_C Dart_Handle (*Dart_SetLibraryTagHandler_DL)(
    Dart_LibraryTagHandler handler);

DART_EXTERN_C void (*Dart_SetMessageNotifyCallback_DL)(
    Dart_MessageNotifyCallback message_notify_callback);

DART_EXTERN_C Dart_Handle (*Dart_SetNativeInstanceField_DL)(Dart_Handle obj,
                                                      int index,
                                                      intptr_t value);

DART_EXTERN_C void (*Dart_SetPausedOnExit_DL)(bool paused);

DART_EXTERN_C void (*Dart_SetPausedOnStart_DL)(bool paused);

DART_EXTERN_C Dart_Handle (*Dart_SetPeer_DL)(Dart_Handle object, void* peer);

DART_EXTERN_C void (*Dart_SetReturnValue_DL)(Dart_NativeArguments args,
                                       Dart_Handle retval);

DART_EXTERN_C Dart_Handle (*Dart_SetRootLibrary_DL)(Dart_Handle library);

DART_EXTERN_C void (*Dart_SetShouldPauseOnExit_DL)(bool should_pause);

DART_EXTERN_C void (*Dart_SetShouldPauseOnStart_DL)(bool should_pause);

DART_EXTERN_C void (*Dart_SetStickyError_DL)(Dart_Handle error);

DART_EXTERN_C void (*Dart_SetWeakHandleReturnValue_DL)(
    Dart_NativeArguments args,
    Dart_WeakPersistentHandle rval);

DART_EXTERN_C bool (*Dart_ShouldPauseOnExit_DL)();

DART_EXTERN_C bool (*Dart_ShouldPauseOnStart_DL)();

DART_EXTERN_C Dart_Handle
(*Dart_WaitForEvent_DL)(int64_t timeout_millis);

DART_EXTERN_C bool (*Dart_WriteProfileToTimeline_DL)(Dart_Port main_port, 
                                               char** error);

DART_EXTERN_C void (*Dart_ShutdownIsolate_DL)();

DART_EXTERN_C void (*Dart_StartProfiling_DL)();

DART_EXTERN_C void (*Dart_StopProfiling_DL)();

DART_EXTERN_C Dart_Handle (*Dart_StringGetProperties_DL)(Dart_Handle str,
                                                   intptr_t* char_size,
                                                   intptr_t* str_len,
                                                   void** peer);

DART_EXTERN_C Dart_Handle (*Dart_StringLength_DL)(Dart_Handle str, 
                                                  intptr_t* length);

DART_EXTERN_C Dart_Handle (*Dart_StringStorageSize_DL)(Dart_Handle str, 
                                                 intptr_t* size);

DART_EXTERN_C Dart_Handle (*Dart_StringToCString_DL)(Dart_Handle str,
                                               const char** cstr);

DART_EXTERN_C Dart_Handle (*Dart_StringToLatin1_DL)(Dart_Handle str,
                                              uint8_t* latin1_array,
                                              intptr_t* length);

DART_EXTERN_C Dart_Handle (*Dart_StringToUTF16_DL)(Dart_Handle str,
                                             uint16_t* utf16_array,
                                             intptr_t* length);

DART_EXTERN_C Dart_Handle (*Dart_StringToUTF8_DL)(Dart_Handle str,
                                            uint8_t** utf8_array,
                                            intptr_t* length);

DART_EXTERN_C void (*Dart_ThreadDisableProfiling_DL)();

DART_EXTERN_C void (*Dart_ThreadEnableProfiling_DL)();

DART_EXTERN_C Dart_Handle (*Dart_ThrowException_DL)(Dart_Handle exception);

DART_EXTERN_C Dart_Handle (*Dart_ToString_DL)(Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_True_DL)();

DART_EXTERN_C Dart_Handle (*Dart_TypedDataAcquireData_DL)(Dart_Handle object,
                                                    Dart_TypedData_Type* type,
                                                    void** data,
                                                    intptr_t* len);

DART_EXTERN_C Dart_Handle (*Dart_TypedDataReleaseData_DL)(Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_TypeDynamic_DL)();

DART_EXTERN_C Dart_Handle (*Dart_TypeNever_DL)();

DART_EXTERN_C Dart_Handle (*Dart_TypeToNonNullableType_DL)(Dart_Handle type);

DART_EXTERN_C Dart_Handle (*Dart_TypeToNullableType_DL)(Dart_Handle type);

DART_EXTERN_C Dart_Handle (*Dart_TypeVoid_DL)();

DART_EXTERN_C const char* (*Dart_VersionString_DL)();
// IMPORTANT! Never update these signatures without properly updating
// DART_API_DL_MAJOR_VERSION and DART_API_DL_MINOR_VERSION.
//
// End of verbatim copy.

#endif /* RUNTIME_INCLUDE_DART_API_DL_H_ */ /* NOLINT */
