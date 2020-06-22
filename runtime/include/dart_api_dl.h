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

DART_EXTERN_C bool (*Dart_Post_DL)(Dart_Port_DL port_id, Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_NewSendPort_DL)(Dart_Port_DL port_id);

DART_EXTERN_C Dart_Handle (*Dart_SendPortGetId_DL)(Dart_Handle port,
                                                   Dart_Port_DL* port_id);

DART_EXTERN_C void (*Dart_EnterScope_DL)();

DART_EXTERN_C void (*Dart_ExitScope_DL)();
// IMPORTANT! Never update these signatures without properly updating
// DART_API_DL_MAJOR_VERSION and DART_API_DL_MINOR_VERSION.
//
// End of verbatim copy.

#endif /* RUNTIME_INCLUDE_DART_API_DL_H_ */ /* NOLINT */