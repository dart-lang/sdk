// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/extensions.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

const char* kPrecompiledVMIsolateSymbolName = "_kVmIsolateSnapshot";
const char* kPrecompiledIsolateSymbolName = "_kIsolateSnapshot";
const char* kPrecompiledInstructionsSymbolName = "_kInstructionsSnapshot";
const char* kPrecompiledDataSymbolName = "_kDataSnapshot";

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  SetLastError(0);
  return LoadLibraryW(StringUtilsWin::Utf8ToWide(library_file));
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  SetLastError(0);
  return GetProcAddress(reinterpret_cast<HMODULE>(lib_handle), symbol);
}

Dart_Handle Extensions::GetError() {
  int last_error = GetLastError();
  if (last_error != 0) {
    OSError err;
    return Dart_NewApiError(err.message());
  }
  return Dart_Null();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
