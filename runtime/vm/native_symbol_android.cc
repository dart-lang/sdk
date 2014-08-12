// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "vm/native_symbol.h"

#include <dlfcn.h>  // NOLINT

namespace dart {

void NativeSymbolResolver::InitOnce() {
}


void NativeSymbolResolver::ShutdownOnce() {
}


char* NativeSymbolResolver::LookupSymbolName(uintptr_t pc, uintptr_t* start) {
  Dl_info info;
  int r = dladdr(reinterpret_cast<void*>(pc), &info);
  if (r == 0) {
    return NULL;
  }
  if (info.dli_sname == NULL) {
    return NULL;
  }
  if (start != NULL) {
    *start = reinterpret_cast<uintptr_t>(info.dli_saddr);
  }
  return strdup(info.dli_sname);
}


void NativeSymbolResolver::FreeSymbolName(char* name) {
  free(name);
}


}  // namespace dart

#endif  // defined(TARGET_OS_ANDROID)
