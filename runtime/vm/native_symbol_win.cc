// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "vm/lockers.h"
#include "vm/native_symbol.h"
#include "vm/os.h"
#include "vm/os_thread.h"

#include <dbghelp.h>  // NOLINT

namespace dart {

static bool running_ = false;
static Mutex* lock_ = nullptr;

void NativeSymbolResolver::Init() {
  ASSERT(running_ == false);
  if (lock_ == nullptr) {
    lock_ = new Mutex();
  }
  running_ = true;

// Symbol resolution API's used in this file are not supported
// when compiled in UWP.
#ifndef DART_TARGET_OS_WINDOWS_UWP
  SymSetOptions(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
  HANDLE hProcess = GetCurrentProcess();
  if (!SymInitialize(hProcess, nullptr, TRUE)) {
    DWORD error = GetLastError();
    OS::PrintErr("Failed to init NativeSymbolResolver (SymInitialize %" Pu32
                 ")\n",
                 error);
    return;
  }
#endif
}

void NativeSymbolResolver::Cleanup() {
  MutexLocker lock(lock_);
  if (!running_) {
    return;
  }
  running_ = false;
#ifndef DART_TARGET_OS_WINDOWS_UWP
  HANDLE hProcess = GetCurrentProcess();
  if (!SymCleanup(hProcess)) {
    DWORD error = GetLastError();
    OS::PrintErr("Failed to shutdown NativeSymbolResolver (SymCleanup  %" Pu32
                 ")\n",
                 error);
  }
#endif
}

const char* NativeSymbolResolver::LookupSymbolName(uword pc, uword* start) {
#ifdef DART_TARGET_OS_WINDOWS_UWP
  return nullptr;
#else
  const intptr_t kMaxNameLength = 2048;
  const intptr_t kSymbolInfoSize = sizeof(SYMBOL_INFO);  // NOLINT.
  static char buffer[kSymbolInfoSize + kMaxNameLength];
  MutexLocker lock(lock_);
  if (!running_) {
    return nullptr;
  }
  if (start != nullptr) {
    *start = 0;
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
    return nullptr;
  }
  if (start != nullptr) {
    *start = pc - displacement;
  }
  return Utils::StrDup(pSymbol->Name);
#endif  // ifdef DART_TARGET_OS_WINDOWS_UWP
}

void NativeSymbolResolver::FreeSymbolName(const char* name) {
  free(const_cast<char*>(name));
}

bool NativeSymbolResolver::LookupSharedObject(uword pc,
                                              uword* dso_base,
                                              const char** dso_name) {
#ifdef DART_TARGET_OS_WINDOWS_UWP
  return false;
#else
  IMAGEHLP_MODULE64 info = {};
  info.SizeOfStruct = sizeof(info);
  if (!SymGetModuleInfo64(GetCurrentProcess(), pc, &info)) {
    return false;
  }
  if (dso_base != nullptr) {
    *dso_base = info.BaseOfImage;
  }
  if (dso_name != nullptr) {
    *dso_name = Utils::StrDup(info.ImageName);
  }
  return true;
#endif  // ifdef DART_TARGET_OS_WINDOWS_UWP
}

void NativeSymbolResolver::AddSymbols(const char* dso_name,
                                      void* buffer,
                                      size_t size) {
  OS::PrintErr("warning: Dart_AddSymbols has no effect on Windows\n");
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
