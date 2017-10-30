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
  if (!vm_owns_region() || (reserved_.size() == 0)) {
    return;
  }
  if (VirtualFree(reserved_.pointer(), 0, MEM_RELEASE) == 0) {
    FATAL("VirtualFree failed");
  }
}

bool VirtualMemory::FreeSubSegment(int32_t handle,
                                   void* address,
                                   intptr_t size) {
  // On Windows only the entire segment returned by VirtualAlloc
  // can be freed. Therefore we will have to waste these unused
  // virtual memory sub-segments.
  return false;
}

bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
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
  bool result = VirtualProtect(reinterpret_cast<void*>(page_address),
                               end_address - page_address, prot, &old_prot);
  return result;
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
