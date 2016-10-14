// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/extensions.h"
#include <dlfcn.h>  // NOLINT

namespace dart {
namespace bin {

const char* kPrecompiledVMIsolateSymbolName = "_kVmIsolateSnapshot";
const char* kPrecompiledIsolateSymbolName = "_kIsolateSnapshot";
const char* kPrecompiledInstructionsSymbolName = "_kInstructionsSnapshot";
const char* kPrecompiledDataSymbolName = "_kDataSnapshot";

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  return dlopen(library_file, RTLD_LAZY);
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  dlerror();
  return dlsym(lib_handle, symbol);
}

Dart_Handle Extensions::GetError() {
  const char* err_str = dlerror();
  if (err_str != NULL) {
    return Dart_NewApiError(err_str);
  }
  return Dart_Null();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
