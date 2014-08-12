// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/lockers.h"
#include "vm/native_symbol.h"
#include "vm/thread.h"

#include <dbghelp.h>  // NOLINT

namespace dart {

static bool running_ = false;
static Mutex* lock_ = NULL;

void NativeSymbolResolver::InitOnce() {
  ASSERT(running_ == false);
  lock_ = new Mutex();
  running_ = true;
#if 0
  SymSetOptions(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
  HANDLE hProcess = GetCurrentProcess();
  if (!SymInitialize(hProcess, NULL, TRUE)) {
    DWORD error = GetLastError();
    printf("Failed to init NativeSymbolResolver (SymInitialize %d)\n", error);
    return;
  }
#endif
}


void NativeSymbolResolver::ShutdownOnce() {
  MutexLocker lock(lock_);
  if (!running_) {
    return;
  }
  running_ = false;
#if 0
  HANDLE hProcess = GetCurrentProcess();
  if (!SymCleanup(hProcess)) {
    DWORD error = GetLastError();
    printf("Failed to shutdown NativeSymbolResolver (SymCleanup  %d)\n", error);
  }
#endif
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
#if 0
  memset(&buffer[0], 0, sizeof(buffer));
  HANDLE hProcess = GetCurrentProcess();
  DWORD64 address = static_cast<DWORD64>(pc);
  PSYMBOL_INFO pSymbol = reinterpret_cast<PSYMBOL_INFO>(&buffer[0]);
  pSymbol->SizeOfStruct = kSymbolInfoSize;
  pSymbol->MaxNameLen = kMaxNameLength;
  BOOL r = SymFromAddr(hProcess, address, NULL, pSymbol);
  if (r == FALSE) {
    return NULL;
  }
  return strdup(pSymbol->Name);
#endif
  return NULL;
}


void NativeSymbolResolver::FreeSymbolName(char* name) {
  free(name);
}


}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
