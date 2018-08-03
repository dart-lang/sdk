// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include <dlfcn.h>  // NOLINT
#include "bin/extensions.h"

#include "platform/assert.h"

namespace dart {
namespace bin {

const char* kVmSnapshotDataSymbolName = "kDartVmSnapshotData";
const char* kVmSnapshotInstructionsSymbolName = "kDartVmSnapshotInstructions";
const char* kIsolateSnapshotDataSymbolName = "kDartIsolateSnapshotData";
const char* kIsolateSnapshotInstructionsSymbolName =
    "kDartIsolateSnapshotInstructions";

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  return dlopen(library_file, RTLD_LAZY);
}

void* Extensions::ResolveSymbol(void* lib_handle, const char* symbol) {
  dlerror();
  return dlsym(lib_handle, symbol);
}

void Extensions::UnloadLibrary(void* lib_handle) {
  dlerror();
  int result = dlclose(lib_handle);
  ASSERT(result == 0);
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

#endif  // defined(HOST_OS_MACOS)
