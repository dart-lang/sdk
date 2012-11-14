// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_natives.h"

#include <stdlib.h>
#include <string.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "platform/assert.h"


// Lists the native functions implementing advanced dart:io classes.
// Some classes, like File and Directory, list their implementations in
// builtin_natives.cc instead.
#define IO_NATIVE_LIST(V)                                                      \
  V(Common_IsBuiltinList, 1)                                                   \
  V(Crypto_GetRandomBytes, 1)                                                  \
  V(EventHandler_Start, 1)                                                     \
  V(EventHandler_SendData, 4)                                                  \
  V(Platform_NumberOfProcessors, 0)                                            \
  V(Platform_OperatingSystem, 0)                                               \
  V(Platform_PathSeparator, 0)                                                 \
  V(Platform_LocalHostname, 0)                                                 \
  V(Platform_Environment, 0)                                                   \
  V(Process_Start, 10)                                                         \
  V(Process_Kill, 3)                                                           \
  V(ServerSocket_CreateBindListen, 4)                                          \
  V(ServerSocket_Accept, 2)                                                    \
  V(Socket_CreateConnect, 3)                                                   \
  V(Socket_Available, 1)                                                       \
  V(Socket_Read, 2)                                                            \
  V(Socket_ReadList, 4)                                                        \
  V(Socket_WriteList, 4)                                                       \
  V(Socket_GetPort, 1)                                                         \
  V(Socket_GetRemotePeer, 1)                                                   \
  V(Socket_GetError, 1)                                                        \
  V(Socket_GetStdioHandle, 2)                                                  \
  V(Socket_NewServicePort, 0)                                                  \
  V(TlsSocket_Connect, 3)                                                      \
  V(TlsSocket_Destroy, 1)                                                      \
  V(TlsSocket_Handshake, 1)                                                    \
  V(TlsSocket_Init, 1)                                                         \
  V(TlsSocket_ProcessBuffer, 2)                                                \
  V(TlsSocket_RegisterHandshakeCompleteCallback, 2)                            \
  V(TlsSocket_SetCertificateDatabase, 1)

IO_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} IOEntries[] = {
  IO_NATIVE_LIST(REGISTER_FUNCTION)
};


Dart_NativeFunction IONativeLookup(Dart_Handle name,
                                   int argument_count) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  ASSERT(function_name != NULL);
  int num_entries = sizeof(IOEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(IOEntries[i]);
    if (!strcmp(function_name, entry->name_) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return NULL;
}
