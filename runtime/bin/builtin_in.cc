// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

// The string on the next line will be filled in with the contents of the
// builtin.dart file.
// This string forms the content of builtin functionality which is injected
// into standalone dart to provide some test/debug functionality.
static const char Builtin_source_[] = {
  %s
};


// List all native functions implemented in standalone dart that is used
// to inject additional functionality e.g: Logger, file I/O, socket I/O etc.
#define BUILTIN_NATIVE_LIST(V)                                                 \
  V(Logger_PrintString, 1)                                                     \
  V(Directory_List, 7)                                                         \
  V(Directory_Exists, 2)                                                       \
  V(Directory_Create, 2)                                                       \
  V(Directory_Delete, 2)                                                       \
  V(File_OpenFile, 3)                                                          \
  V(File_Exists, 1)                                                            \
  V(File_Close, 1)                                                             \
  V(File_ReadByte, 1)                                                          \
  V(File_WriteByte, 2)                                                         \
  V(File_WriteString, 2)                                                       \
  V(File_ReadList, 4)                                                          \
  V(File_WriteList , 4)                                                        \
  V(File_Position, 1)                                                          \
  V(File_Length, 1)                                                            \
  V(File_Flush, 1)                                                             \
  V(EventHandler_Start, 1)                                                     \
  V(EventHandler_SendData, 4)                                                  \
  V(Process_Start, 8)                                                          \
  V(Process_Kill, 2)                                                           \
  V(Process_Exit, 2)                                                           \
  V(Socket_CreateConnect, 3)                                                   \
  V(Socket_Available, 1)                                                       \
  V(Socket_ReadList, 4)                                                        \
  V(Socket_WriteList, 4)                                                       \
  V(Socket_GetPort, 1)                                                         \
  V(ServerSocket_CreateBindListen, 4)                                          \
  V(ServerSocket_Accept, 2)                                                    \


BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {
  BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)
};


static Dart_NativeFunction native_lookup(Dart_Handle name,
                                         int argument_count) {
  Dart_Result result = Dart_StringToCString(name);
  assert(Dart_IsValidResult(result));
  const char* function_name = Dart_GetResultAsCString(result);
  assert(function_name != NULL);
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


void Builtin_LoadLibrary() {
  Dart_Handle url = Dart_NewString(DartUtils::kBuiltinLibURL);
  Dart_Result result = Dart_LookupLibrary(url);
  if (Dart_IsValidResult(result)) {
    // Builtin library already loaded.
    return;
  }

  // Load the library.
  Dart_Handle source = Dart_NewString(Builtin_source_);
  result = Dart_LoadLibrary(url, source);
  assert(Dart_IsValidResult(result));
  Dart_Handle builtin_lib = Dart_GetResult(result);

  // Lookup the core libraries and inject the builtin library into them.
  result = Dart_LookupLibrary(Dart_NewString("dart:core"));
  assert(Dart_IsValidResult(result));
  Dart_Handle core_lib = Dart_GetResult(result);
  result = Dart_LibraryImportLibrary(core_lib, builtin_lib);
  assert(Dart_IsValidResult(result));

  result = Dart_LookupLibrary(Dart_NewString("dart:coreimpl"));
  assert(Dart_IsValidResult(result));
  Dart_Handle coreimpl_lib = Dart_GetResult(result);
  result = Dart_LibraryImportLibrary(coreimpl_lib, builtin_lib);
  assert(Dart_IsValidResult(result));
  result = Dart_LibraryImportLibrary(builtin_lib, coreimpl_lib);
  assert(Dart_IsValidResult(result));

  // Create a native wrapper "FileNativeWrapper" so that we can add a
  // native field to store the OS file handle for implementing all the
  // file operations. The class "File" extends "FileNativeWrapper".
  Dart_Handle name = Dart_NewString("FileNativeWrapper");
  const int kNumFileFields = 1;
  result = Dart_CreateNativeWrapperClass(builtin_lib, name, kNumFileFields);
  assert(Dart_IsValidResult(result));

  // Create a native wrapper "EventHandlerNativeWrapper" so that we can add a
  // native field to store the event handle for implementing all
  // event operations.
  name = Dart_NewString("EventHandlerNativeWrapper");
  const int kNumEventHandlerFields = 1;
  result = Dart_CreateNativeWrapperClass(builtin_lib,
                                         name,
                                         kNumEventHandlerFields);
  assert(Dart_IsValidResult(result));
}


void Builtin_ImportLibrary(Dart_Handle library) {
  Builtin_LoadLibrary();

  Dart_Handle url = Dart_NewString(DartUtils::kBuiltinLibURL);
  Dart_Result result = Dart_LookupLibrary(url);
  assert(Dart_IsValidResult(result));
  Dart_Handle builtin_lib = Dart_GetResult(result);
  result = Dart_LibraryImportLibrary(library, builtin_lib);
  assert(Dart_IsValidResult(result));
}


void Builtin_SetNativeResolver() {
  Dart_Handle url = Dart_NewString(DartUtils::kBuiltinLibURL);
  Dart_Result result = Dart_LookupLibrary(url);
  assert(Dart_IsValidResult(result));
  Dart_Handle builtin_lib = Dart_GetResult(result);
  result = Dart_SetNativeResolver(builtin_lib, native_lookup);
  assert(Dart_IsValidResult(result));
}
