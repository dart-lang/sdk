// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/virtual_memory.h"

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

uword VirtualMemory::page_size_ = 0;

intptr_t VirtualMemory::CalculatePageSize() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  const intptr_t page_size = info.dwPageSize;
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, PageSize()));
  int prot = is_executable ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE;
  void* address = VirtualAlloc(nullptr, size, MEM_RESERVE | MEM_COMMIT, prot);
  if (address == nullptr) {
    return nullptr;
  }
  return new VirtualMemory(address, size);
}

VirtualMemory::~VirtualMemory() {
  if (address_ != nullptr) {
    if (VirtualFree(address_, 0, MEM_RELEASE) == 0) {
      FATAL("VirtualFree failed: Error code %d\n", GetLastError());
    }
  }
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
  DWORD prot = 0;
  switch (mode) {
    case kNoAccess:
      prot = PAGE_NOACCESS;
      break;
    case kReadOnly:
      prot = PAGE_READONLY;
      break;
    case kReadWrite:
      prot = PAGE_READWRITE;
      break;
    case kReadExecute:
      prot = PAGE_EXECUTE_READ;
      break;
    case kReadWriteExecute:
      prot = PAGE_EXECUTE_READWRITE;
      break;
  }
  DWORD old_prot = 0;
  if (VirtualProtect(reinterpret_cast<void*>(page_address),
                     end_address - page_address, prot, &old_prot) == 0) {
    FATAL("VirtualProtect failed %d\n", GetLastError());
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
