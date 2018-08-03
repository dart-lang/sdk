// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"

#include "bin/builtin.h"
#include "bin/io_natives.h"

namespace dart {
namespace bin {

// Lists the native function implementing basic logging facility.
#define BUILTIN_NATIVE_LIST(V) V(Builtin_PrintString, 1)

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} BuiltinEntries[] = {BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)};

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
    if ((strcmp(function_name, entry->name_) == 0) &&
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
void FUNCTION_NAME(Builtin_PrintString)(Dart_NativeArguments args) {
  Dart_EnterScope();
  intptr_t length = 0;
  uint8_t* chars = NULL;
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  Dart_Handle result = Dart_StringToUTF8(str, &chars, &length);
  if (Dart_IsError(result)) {
    // TODO(turnidge): Consider propagating some errors here.  What if
    // an isolate gets interrupted by the embedder in the middle of
    // Dart_StringToUTF8?  We need to make sure not to swallow the
    // interrupt.
    fputs(Dart_GetError(result), stdout);
  } else {
    fwrite(chars, sizeof(*chars), length, stdout);
  }
  fputc('\n', stdout);
  fflush(stdout);
  Dart_ExitScope();
}

}  // namespace bin
}  // namespace dart
