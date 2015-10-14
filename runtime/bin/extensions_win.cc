// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/extensions.h"
#include "bin/utils.h"
#include "bin/utils_win.h"


namespace dart {
namespace bin {

const char* kPrecompiledLibraryName = "precompiled.dll";
const char* kPrecompiledSymbolName = "_kInstructionsSnapshot";

Dart_Handle Extensions::LoadExtensionLibrary(const char* library_file,
                                             void** library_handle) {
  ASSERT(library_handle != NULL);
  *library_handle = LoadLibraryW(StringUtilsWin::Utf8ToWide(library_file));
  if (*library_handle == NULL) {
    OSError err;
    return Dart_NewApiError(err.message());
  }
  return Dart_Null();
}

Dart_Handle Extensions::ResolveSymbol(void* lib_handle,
                                      const char* symbol,
                                      void** init_function) {
  ASSERT(init_function != NULL);
  *init_function = GetProcAddress(
      reinterpret_cast<HMODULE>(lib_handle), symbol);
  if (*init_function == NULL) {
    OSError err;
    return Dart_NewApiError(err.message());
  }
  return Dart_Null();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
