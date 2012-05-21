// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"

#include <stdlib.h>
#include <string.h>

#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "platform/assert.h"


// List all native functions implemented in standalone dart that is used
// to inject additional functionality e.g: Logger, file I/O, socket I/O etc.
#define BUILTIN_NATIVE_LIST(V)                                                 \
  V(Directory_Exists, 1)                                                       \
  V(Directory_Create, 1)                                                       \
  V(Directory_Current, 0)                                                      \
  V(Directory_CreateTemp, 1)                                                   \
  V(Directory_Delete, 2)                                                       \
  V(Directory_NewServicePort, 0)                                               \
  V(EventHandler_Start, 1)                                                     \
  V(EventHandler_SendData, 4)                                                  \
  V(Exit, 1)                                                                   \
  V(File_Open, 2)                                                              \
  V(File_Exists, 1)                                                            \
  V(File_Close, 1)                                                             \
  V(File_ReadByte, 1)                                                          \
  V(File_WriteByte, 2)                                                         \
  V(File_WriteString, 2)                                                       \
  V(File_ReadList, 4)                                                          \
  V(File_WriteList, 4)                                                         \
  V(File_Position, 1)                                                          \
  V(File_SetPosition, 2)                                                       \
  V(File_Truncate, 2)                                                          \
  V(File_Length, 1)                                                            \
  V(File_LengthFromName, 1)                                                    \
  V(File_Flush, 1)                                                             \
  V(File_Create, 1)                                                            \
  V(File_Delete, 1)                                                            \
  V(File_Directory, 1)                                                         \
  V(File_FullPath, 1)                                                          \
  V(File_OpenStdio, 1)                                                         \
  V(File_GetStdioHandleType, 1)                                                \
  V(File_NewServicePort, 0)                                                    \
  V(Logger_PrintString, 1)                                                     \
  V(Platform_NumberOfProcessors, 0)                                            \
  V(Platform_OperatingSystem, 0)                                               \
  V(Platform_PathSeparator, 0)                                                 \
  V(Platform_LocalHostname, 0)                                                 \
  V(Platform_Environment, 0)                                                   \
  V(Process_Start, 10)                                                         \
  V(Process_Kill, 2)                                                           \
  V(ServerSocket_CreateBindListen, 4)                                          \
  V(ServerSocket_Accept, 2)                                                    \
  V(Socket_CreateConnect, 3)                                                   \
  V(Socket_Available, 1)                                                       \
  V(Socket_ReadList, 4)                                                        \
  V(Socket_WriteList, 4)                                                       \
  V(Socket_GetPort, 1)                                                         \
  V(Socket_GetRemotePeer, 1)                                                   \
  V(Socket_GetError, 1)                                                        \
  V(Socket_GetStdioHandle, 2)                                                  \
  V(Socket_NewServicePort, 0)


BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {
  BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)
};


Dart_NativeFunction Builtin::NativeLookup(Dart_Handle name,
                                          int argument_count) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  ASSERT(function_name != NULL);
  int num_entries = sizeof(BuiltinEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BuiltinEntries[i]);
    if (!strcmp(function_name, entry->name_)) {
      if (entry->argument_count_ == argument_count) {
        return reinterpret_cast<Dart_NativeFunction>(entry->function_);
      } else {
        // Wrong number of arguments.
        // TODO(regis): Should we pass a buffer for error reporting?
        return NULL;
      }
    }
  }
  return NULL;
}


// Implementation of native functions which are used for some
// test/debug functionality in standalone dart mode.

void Builtin::PrintString(FILE* out, Dart_Handle str) {
  const uint8_t* characters = NULL;
  intptr_t length;
  Dart_Handle result = Dart_StringToBytes(str, &characters, &length);
  if (Dart_IsError(result)) {
    // TODO(turnidge): Consider propagating some errors here.  What if
    // an isolate gets interrupted by the embedder in the middle of
    // Dart_StringToBytes?  We need to make sure not to swallow the
    // interrupt.
    fputs(Dart_GetError(result), out);
  } else {
    fwrite(characters, sizeof(*characters), length, out);
  }
  fputc('\n', out);
  fflush(out);
}


void FUNCTION_NAME(Logger_PrintString)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Builtin::PrintString(stdout, Dart_GetNativeArgument(args, 0));
  Dart_ExitScope();
}

void FUNCTION_NAME(Exit)(Dart_NativeArguments args) {
  Dart_EnterScope();
  int64_t status = 0;
  // Ignore result if passing invalid argument and just exit 0.
  DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &status);
  Dart_ExitScope();
  exit(status);
}


void Builtin::SetNativeResolver(Builtin::BuiltinLibraryId id) {
  Dart_Handle url;
  if (id == Builtin::kBuiltinLibrary) {
    url = Dart_NewString(DartUtils::kBuiltinLibURL);
  } else {
    ASSERT(id == Builtin::kIOLibrary);
    url = Dart_NewString(DartUtils::kIOLibURL);
  }
  Dart_Handle builtin_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(builtin_lib);
  // Setup the native resolver for built in library functions.
  Dart_Handle result = Dart_SetNativeResolver(builtin_lib, NativeLookup);
  DART_CHECK_VALID(result);
}
