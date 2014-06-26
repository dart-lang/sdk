// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "include/dart_api.h"

#include "platform/assert.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/io_natives.h"
#include "bin/platform.h"

namespace dart {
namespace bin {

// Lists the native functions implementing basic functionality in
// standalone dart, such as printing, file I/O, and platform information.
// Advanced I/O classes like sockets and process management are implemented
// using functions listed in io_natives.cc.
#define BUILTIN_NATIVE_LIST(V)                                                 \
  V(Crypto_GetRandomBytes, 1)                                                  \
  V(Directory_Exists, 1)                                                       \
  V(Directory_Create, 1)                                                       \
  V(Directory_Current, 0)                                                      \
  V(Directory_SetCurrent, 1)                                                   \
  V(Directory_SystemTemp, 0)                                                   \
  V(Directory_CreateTemp, 1)                                                   \
  V(Directory_Delete, 2)                                                       \
  V(Directory_Rename, 2)                                                       \
  V(Directory_List, 3)                                                         \
  V(File_Open, 2)                                                              \
  V(File_Exists, 1)                                                            \
  V(File_GetFD, 1)                                                             \
  V(File_Close, 1)                                                             \
  V(File_ReadByte, 1)                                                          \
  V(File_WriteByte, 2)                                                         \
  V(File_Read, 2)                                                              \
  V(File_ReadInto, 4)                                                          \
  V(File_WriteFrom, 4)                                                         \
  V(File_Position, 1)                                                          \
  V(File_SetPosition, 2)                                                       \
  V(File_Truncate, 2)                                                          \
  V(File_Length, 1)                                                            \
  V(File_LengthFromPath, 1)                                                    \
  V(File_Stat, 1)                                                              \
  V(File_LastModified, 1)                                                      \
  V(File_Flush, 1)                                                             \
  V(File_Create, 1)                                                            \
  V(File_CreateLink, 2)                                                        \
  V(File_LinkTarget, 1)                                                        \
  V(File_Delete, 1)                                                            \
  V(File_DeleteLink, 1)                                                        \
  V(File_Rename, 2)                                                            \
  V(File_Copy, 2)                                                              \
  V(File_RenameLink, 2)                                                        \
  V(File_ResolveSymbolicLinks, 1)                                              \
  V(File_OpenStdio, 1)                                                         \
  V(File_GetStdioHandleType, 1)                                                \
  V(File_GetType, 2)                                                           \
  V(File_AreIdentical, 2)                                                      \
  V(Logger_PrintString, 1)                                                     \
  V(Builtin_LoadScript, 2)                                                     \
  V(Builtin_LoadLibrarySource, 4)                                              \
  V(Builtin_AsyncLoadError, 2)                                                 \
  V(Builtin_DoneLoading, 0)                                                    \


BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {
  BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)
};


/**
 * Looks up native functions in both libdart_builtin and libdart_io.
 */
Dart_NativeFunction Builtin::NativeLookup(Dart_Handle name,
                                          int argument_count,
                                          bool* auto_setup_scope) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  ASSERT(function_name != NULL);
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  int num_entries = sizeof(BuiltinEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BuiltinEntries[i]);
    if (!strcmp(function_name, entry->name_) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return IONativeLookup(name, argument_count, auto_setup_scope);
}


const uint8_t* Builtin::NativeSymbol(Dart_NativeFunction nf) {
  int num_entries = sizeof(BuiltinEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(BuiltinEntries[i]);
    if (reinterpret_cast<Dart_NativeFunction>(entry->function_) == nf) {
      return reinterpret_cast<const uint8_t*>(entry->name_);
    }
  }
  return IONativeSymbol(nf);
}


// Implementation of native functions which are used for some
// test/debug functionality in standalone dart mode.
void FUNCTION_NAME(Logger_PrintString)(Dart_NativeArguments args) {
  intptr_t length = 0;
  uint8_t* chars = NULL;
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  Dart_Handle result = Dart_StringToUTF8(str, &chars, &length);
  if (Dart_IsError(result)) {
    // TODO(turnidge): Consider propagating some errors here.  What if
    // an isolate gets interrupted by the embedder in the middle of
    // Dart_StringToUTF8?  We need to make sure not to swallow the
    // interrupt.
    fprintf(stdout, "%s\n", Dart_GetError(result));
  } else {
    // Uses fwrite to support printing NUL bytes.
    fwrite(chars, 1, length, stdout);
    fputs("\n", stdout);
  }
  fflush(stdout);
}

}  // namespace bin
}  // namespace dart
