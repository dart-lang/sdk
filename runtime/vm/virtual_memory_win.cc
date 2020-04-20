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

DECLARE_FLAG(bool, write_protect_code);

uword VirtualMemory::page_size_ = 0;

intptr_t VirtualMemory::CalculatePageSize() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  const intptr_t page_size = info.dwPageSize;
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

void VirtualMemory::Init() {
  page_size_ = CalculatePageSize();
}

bool VirtualMemory::DualMappingEnabled() {
  return false;
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  intptr_t reserved_size = size + alignment - PageSize();
  int prot = (is_executable && !FLAG_write_protect_code)
                 ? PAGE_EXECUTE_READWRITE
                 : PAGE_READWRITE;
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

void VirtualMemory::FreeSubSegment(void* address,
                                   intptr_t size) {
  if (VirtualFree(address, size, MEM_DECOMMIT) == 0) {
    FATAL1("VirtualFree failed: Error code %d\n", GetLastError());
  }
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsMutatorThread() ||
         thread->isolate() == nullptr ||
         thread->isolate()->mutator_thread()->IsAtSafepoint());
#endif
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
