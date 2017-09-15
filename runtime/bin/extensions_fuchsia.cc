// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/extensions.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <launchpad/vmo.h>
#include <zircon/dlfcn.h>
#include <fdio/io.h>

#include "platform/assert.h"

namespace dart {
namespace bin {

const char* kVmSnapshotDataSymbolName = "_kDartVmSnapshotData";
const char* kVmSnapshotInstructionsSymbolName = "_kDartVmSnapshotInstructions";
const char* kIsolateSnapshotDataSymbolName = "_kDartIsolateSnapshotData";
const char* kIsolateSnapshotInstructionsSymbolName =
    "_kDartIsolateSnapshotInstructions";

void* Extensions::LoadExtensionLibrary(const char* library_file) {
  int fd = open(library_file, O_RDONLY);
  if (fd < 0) {
    return NULL;
  }
  zx_handle_t vmo;
  zx_status_t status = fdio_get_vmo(fd, &vmo);
  close(fd);
  if (status != ZX_OK) {
    return NULL;
  }
  return dlopen_vmo(vmo, RTLD_LAZY);
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

#endif  // defined(HOST_OS_FUCHSIA)
