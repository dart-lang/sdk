// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "vm/virtual_memory.h"

#include "platform/assert.h"
#include "vm/os.h"

#include "vm/isolate.h"

namespace dart {

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::InitOnce() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  page_size_ = info.dwPageSize;
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  int prot = is_executable ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE;
  void* address = VirtualAlloc(NULL, size, MEM_RESERVE | MEM_COMMIT, prot);
  if (address == NULL) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region, region);
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsAligned(alignment, page_size_));
  intptr_t reserved_size = size + alignment;
  int prot = is_executable ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE;
  void* address = VirtualAlloc(NULL, reserved_size, MEM_RESERVE, prot);
  if (address == NULL) {
    return NULL;
  }

  void* aligned_address = reinterpret_cast<void*>(
      Utils::RoundUp(reinterpret_cast<uword>(address), alignment));
  if (VirtualAlloc(aligned_address, size, MEM_COMMIT, prot) !=
      aligned_address) {
    VirtualFree(address, reserved_size, MEM_RELEASE);
    return NULL;
  }

  MemoryRegion region(aligned_address, size);
  MemoryRegion reserved(address, reserved_size);
  return new VirtualMemory(region, reserved);
}

VirtualMemory::~VirtualMemory() {
  // Note that the size of the reserved region might be set to 0 by
  // Truncate(0, true) but that does not actually release the mapping
  // itself. The only way to release the mapping is to invoke VirtualFree
  // with original base pointer and MEM_RELEASE.
  if (!vm_owns_region()) {
    return;
  }
  if (VirtualFree(reserved_.pointer(), 0, MEM_RELEASE) == 0) {
    FATAL1("VirtualFree failed: Error code %d\n", GetLastError());
  }
}

bool VirtualMemory::FreeSubSegment(void* address,
                                   intptr_t size) {
  if (VirtualFree(address, size, MEM_DECOMMIT) == 0) {
    FATAL1("VirtualFree failed: Error code %d\n", GetLastError());
  }
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  ASSERT(Thread::Current()->IsMutatorThread() ||
         Isolate::Current()->mutator_thread()->IsAtSafepoint());
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
    FATAL1("VirtualProtect failed %d\n", GetLastError());
  }
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
