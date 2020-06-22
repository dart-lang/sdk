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
  /* Dart_Port */                                                              \
  F(Dart_Post)                                                                 \
  F(Dart_NewSendPort)                                                          \
  F(Dart_SendPortGetId)                                                        \
  /* Scopes */                                                                 \
  F(Dart_EnterScope)                                                           \
  F(Dart_ExitScope)

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
