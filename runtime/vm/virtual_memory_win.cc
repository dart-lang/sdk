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

VirtualMemory* VirtualMemory::ReserveInternal(intptr_t size) {
  void* address = VirtualAlloc(NULL, size, MEM_RESERVE, PAGE_NOACCESS);
  if (address == NULL) {
    return NULL;
  }
  MemoryRegion region(address, size);
  return new VirtualMemory(region);
}

VirtualMemory::~VirtualMemory() {
  if (!vm_owns_region() || (reserved_size_ == 0)) {
    return;
  }
  if (VirtualFree(address(), 0, MEM_RELEASE) == 0) {
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

bool VirtualMemory::Commit(uword addr,
                           intptr_t size,
                           bool executable,
                           const char* name) {
  ASSERT(Contains(addr));
  ASSERT(Contains(addr + size) || (addr + size == end()));
  int prot = executable ? PAGE_EXECUTE_READWRITE : PAGE_READWRITE;
  if (VirtualAlloc(reinterpret_cast<void*>(addr), size, MEM_COMMIT, prot) ==
      NULL) {
    return false;
  }
  return true;
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
