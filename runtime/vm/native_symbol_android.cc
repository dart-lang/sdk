// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "vm/native_symbol.h"

#include <cxxabi.h>  // NOLINT
#include <dlfcn.h>   // NOLINT

// Even though it's not used in a PRODUCT build, __cxa_demangle() still ends up
// in the resulting binary for Android. Blowing it away by redefining it like
// so saves >90KB of binary size.
#if defined(PRODUCT)
extern "C" char* __cxa_demangle(const char* mangled_name,
                                char* buf,
                                size_t* n,
                                int* status) {
  if (status) {
    *status = -1;
  }
  return NULL;
}
#endif

namespace dart {

void NativeSymbolResolver::InitOnce() {}

void NativeSymbolResolver::ShutdownOnce() {}

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
  *dso_base = reinterpret_cast<uword>(info.dli_fbase);
  *dso_name = strdup(info.dli_fname);
  return true;
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
