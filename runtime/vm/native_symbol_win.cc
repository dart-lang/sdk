// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "vm/lockers.h"
#include "vm/native_symbol.h"
#include "vm/os_thread.h"

#include <dbghelp.h>  // NOLINT

namespace dart {

static bool running_ = false;
static Mutex* lock_ = NULL;

void NativeSymbolResolver::InitOnce() {
  ASSERT(running_ == false);
  lock_ = new Mutex();
  running_ = true;
  SymSetOptions(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
  HANDLE hProcess = GetCurrentProcess();
  if (!SymInitialize(hProcess, NULL, TRUE)) {
    DWORD error = GetLastError();
    printf("Failed to init NativeSymbolResolver (SymInitialize %d)\n", error);
    return;
  }
}

void NativeSymbolResolver::ShutdownOnce() {
  MutexLocker lock(lock_);
  if (!running_) {
    return;
  }
  running_ = false;
  HANDLE hProcess = GetCurrentProcess();
  if (!SymCleanup(hProcess)) {
    DWORD error = GetLastError();
    printf("Failed to shutdown NativeSymbolResolver (SymCleanup  %d)\n", error);
  }
}

char* NativeSymbolResolver::LookupSymbolName(uintptr_t pc, uintptr_t* start) {
  static const intptr_t kMaxNameLength = 2048;
  static const intptr_t kSymbolInfoSize = sizeof(SYMBOL_INFO);  // NOLINT.
  static char buffer[kSymbolInfoSize + kMaxNameLength];
  static char name_buffer[kMaxNameLength];
  MutexLocker lock(lock_);
  if (!running_) {
    return NULL;
  }
  if (start != NULL) {
    *start = NULL;
  }
  memset(&buffer[0], 0, sizeof(buffer));
  HANDLE hProcess = GetCurrentProcess();
  DWORD64 address = static_cast<DWORD64>(pc);
  PSYMBOL_INFO pSymbol = reinterpret_cast<PSYMBOL_INFO>(&buffer[0]);
  pSymbol->SizeOfStruct = kSymbolInfoSize;
  pSymbol->MaxNameLen = kMaxNameLength;
  DWORD64 displacement;
  BOOL r = SymFromAddr(hProcess, address, &displacement, pSymbol);
  if (r == FALSE) {
    return NULL;
  }
  if (start != NULL) {
    *start = pc - displacement;
  }
  return strdup(pSymbol->Name);
}

void NativeSymbolResolver::FreeSymbolName(char* name) {
  free(name);
}

bool NativeSymbolResolver::LookupSharedObject(uword pc,
                                              uword* dso_base,
                                              char** dso_name) {
  return false;
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
