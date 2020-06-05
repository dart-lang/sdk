// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_LINUX)

#include "platform/memory_sanitizer.h"
#include "vm/native_symbol.h"
#include "vm/os.h"

#include <cxxabi.h>  // NOLINT
#include <dlfcn.h>   // NOLINT

namespace dart {

void NativeSymbolResolver::Init() {}

void NativeSymbolResolver::Cleanup() {}

char* NativeSymbolResolver::LookupSymbolName(uword pc, uword* start) {
  Dl_info info;
  int r = dladdr(reinterpret_cast<void*>(pc), &info);
  if (r == 0) {
    return NULL;
  }
  if (info.dli_sname == NULL) {
    return NULL;
  }
  if (start != NULL) {
    *start = reinterpret_cast<uword>(info.dli_saddr);
  }
  int status = 0;
  size_t len = 0;
  char* demangled = abi::__cxa_demangle(info.dli_sname, NULL, &len, &status);
  MSAN_UNPOISON(demangled, len);
  if (status == 0) {
    return demangled;
  }
  return strdup(info.dli_sname);
}

void NativeSymbolResolver::FreeSymbolName(char* name) {
  free(name);
}

bool NativeSymbolResolver::LookupSharedObject(uword pc,
                                              uword* dso_base,
                                              char** dso_name) {
  Dl_info info;
  int r = dladdr(reinterpret_cast<void*>(pc), &info);
  if (r == 0) {
    return false;
  }
  if (dso_base != nullptr) {
    *dso_base = reinterpret_cast<uword>(info.dli_fbase);
  }
  if (dso_name != nullptr) {
    *dso_name = strdup(info.dli_fname);
  }
  return true;
}

void NativeSymbolResolver::AddSymbols(const char* dso_name,
                                      void* buffer,
                                      size_t size) {
  OS::PrintErr("warning: Dart_AddSymbols has no effect on Linux\n");
}

}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
