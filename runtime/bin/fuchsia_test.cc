// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <dart_api.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bin/log.h"
#include "platform/assert.h"

const char* kBuiltinScript =
    "_printString(String line) native \"Builtin_PrintString\";\n"
    "_getPrintClosure() => _printString;\n";

const char* kHelloWorldScript = "main() { print(\"Hello, Fuchsia!\"); }";

namespace dart {
namespace bin {

// vm_isolate_snapshot_buffer points to a snapshot for the vm isolate if we
// link in a snapshot otherwise it is initialized to NULL.
extern const uint8_t* vm_isolate_snapshot_buffer;

// isolate_snapshot_buffer points to a snapshot for an isolate if we link in a
// snapshot otherwise it is initialized to NULL.
extern const uint8_t* isolate_snapshot_buffer;

static void Builtin_PrintString(Dart_NativeArguments args) {
  intptr_t length = 0;
  uint8_t* chars = NULL;
  Dart_Handle str = Dart_GetNativeArgument(args, 0);
  Dart_Handle result = Dart_StringToUTF8(str, &chars, &length);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  // Uses fwrite to support printing NUL bytes.
  intptr_t res = fwrite(chars, 1, length, stdout);
  ASSERT(res == length);
  fputs("\n", stdout);
  fflush(stdout);
}

static Dart_NativeFunction NativeLookup(Dart_Handle name,
                                        int argument_count,
                                        bool* auto_setup_scope) {
  const char* function_name = NULL;
  Dart_Handle err = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(err);
  *auto_setup_scope = true;
  if (strcmp(function_name, "Builtin_PrintString") == 0) {
    return reinterpret_cast<Dart_NativeFunction>(Builtin_PrintString);
  }
  return NULL;
}

static const uint8_t* NativeSymbol(Dart_NativeFunction nf) {
  if (reinterpret_cast<Dart_NativeFunction>(Builtin_PrintString) == nf) {
    return reinterpret_cast<const uint8_t*>("Builtin_PrintString");
  }
  return NULL;
}

static Dart_Handle PrepareBuiltinLibrary(const char* script) {
  Log::Print("Creating builtin library uri\n");
  Dart_Handle builtin_uri = Dart_NewStringFromCString("builtin_uri");
  DART_CHECK_VALID(builtin_uri);

  Log::Print("Creating builtin library script string\n");
  Dart_Handle builtin_script = Dart_NewStringFromCString(script);
  DART_CHECK_VALID(builtin_script);

  Log::Print("Loading builtin library\n");
  Dart_Handle status =
      Dart_LoadLibrary(builtin_uri, Dart_Null(), builtin_script, 0, 0);
  DART_CHECK_VALID(status);

  Log::Print("Looking up builtin library\n");
  Dart_Handle builtin_library = Dart_LookupLibrary(builtin_uri);
  DART_CHECK_VALID(builtin_library);

  Log::Print("Setting up native resolver for builtin library\n");
  status = Dart_SetNativeResolver(builtin_library, NativeLookup, NativeSymbol);
  DART_CHECK_VALID(status);

  return builtin_library;
}

static Dart_Handle PrepareScriptLibrary(const char* script) {
  Log::Print("Creating script URI string\n");
  Dart_Handle script_uri = Dart_NewStringFromCString("script_uri");
  DART_CHECK_VALID(script_uri);

  Log::Print("Creating script string\n");
  Dart_Handle script_string = Dart_NewStringFromCString(script);
  DART_CHECK_VALID(script_string);

  Log::Print("Loading script into new library\n");
  Dart_Handle status =
      Dart_LoadLibrary(script_uri, Dart_Null(), script_string, 0, 0);
  DART_CHECK_VALID(status);

  Log::Print("Looking up script library\n");
  Dart_Handle library = Dart_LookupLibrary(script_uri);
  DART_CHECK_VALID(library);

  return library;
}

static Dart_Handle LoadInternalLibrary() {
  Log::Print("Creating internal library uri string\n");
  Dart_Handle url = Dart_NewStringFromCString("dart:_internal");
  DART_CHECK_VALID(url);

  Log::Print("Looking up internal library\n");
  Dart_Handle internal_library = Dart_LookupLibrary(url);
  DART_CHECK_VALID(internal_library);

  return internal_library;
}

static void PreparePrintClosure(Dart_Handle builtin_library,
                                Dart_Handle internal_library) {
  Log::Print("Creating _getPrintClosure name string\n");
  Dart_Handle get_print_closure_name =
      Dart_NewStringFromCString("_getPrintClosure");
  DART_CHECK_VALID(get_print_closure_name);

  Log::Print("Invoking _getPrintClosure\n");
  Dart_Handle print_closure = Dart_Invoke(
      builtin_library, get_print_closure_name, 0, NULL);
  DART_CHECK_VALID(print_closure);

  Log::Print("Creating _printClosure name string\n");
  Dart_Handle print_closure_name = Dart_NewStringFromCString("_printClosure");
  DART_CHECK_VALID(print_closure_name);

  Log::Print("Setting _printClosure to result of _getPrintClosure\n");
  Dart_Handle status = Dart_SetField(
      internal_library, print_closure_name, print_closure);
  DART_CHECK_VALID(status);
}

int Main() {
  Log::Print("Calling Dart_SetVMFlags\n");
  if (!Dart_SetVMFlags(0, NULL)) {
    FATAL("Failed to set flags\n");
  }
  Log::Print("Calling Dart_Initialize\n");
  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  init_params.vm_isolate_snapshot = vm_isolate_snapshot_buffer;
  char* error = Dart_Initialize(&init_params);
  if (error != NULL) {
    FATAL1("VM initialization failed: %s\n", error);
  }

  Log::Print("Creating Isolate\n");
  Dart_Isolate isolate = Dart_CreateIsolate(
      "script_uri",
      "main",
      isolate_snapshot_buffer,
      NULL,
      NULL,
      &error);
  if (isolate == NULL) {
    FATAL1("Dart_CreateIsolate failed: %s\n", error);
  }

  Log::Print("Entering Scope\n");
  Dart_EnterScope();

  Dart_Handle library = PrepareScriptLibrary(kHelloWorldScript);

  Dart_Handle builtin_library = PrepareBuiltinLibrary(kBuiltinScript);

  Log::Print("Finalizing loading\n");
  Dart_Handle status = Dart_FinalizeLoading(false);
  DART_CHECK_VALID(status);

  Dart_Handle internal_library = LoadInternalLibrary();

  PreparePrintClosure(builtin_library, internal_library);

  Log::Print("Creating main string\n");
  Dart_Handle main_name = Dart_NewStringFromCString("main");
  DART_CHECK_VALID(main_name);

  Log::Print("---- Invoking main() ----\n");
  status = Dart_Invoke(library, main_name, 0, NULL);
  DART_CHECK_VALID(status);
  Log::Print("---- main() returned ----\n");

  Log::Print("Exiting Scope\n");
  Dart_ExitScope();
  Log::Print("Shutting down the isolate\n");
  Dart_ShutdownIsolate();

  Log::Print("Calling Dart_Cleanup\n");
  error = Dart_Cleanup();
  if (error != NULL) {
    FATAL1("VM Cleanup failed: %s\n", error);
  }

  Log::Print("Success!\n");
  return 0;
}

}  // namespace bin
}  // namespace dart

int main(void) {
  return dart::bin::Main();
}
