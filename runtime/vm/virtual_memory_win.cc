// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "vm/virtual_memory.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/os.h"
#include "vm/virtual_memory_compressed.h"

namespace dart {

DECLARE_FLAG(bool, write_protect_code);

uword VirtualMemory::page_size_ = 0;
VirtualMemory* VirtualMemory::compressed_heap_ = nullptr;

intptr_t VirtualMemory::CalculatePageSize() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  const intptr_t page_size = info.dwPageSize;
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

static void* AllocateAlignedImpl(intptr_t size,
                                 intptr_t alignment,
                                 intptr_t reserved_size,
                                 int prot,
                                 void** out_reserved_address) {
  void* address = VirtualAlloc(nullptr, reserved_size, MEM_RESERVE, prot);
  if (address == nullptr) {
    return nullptr;
  }

  void* aligned_address = reinterpret_cast<void*>(
      Utils::RoundUp(reinterpret_cast<uword>(address), alignment));
  if (VirtualAlloc(aligned_address, size, MEM_COMMIT, prot) !=
      aligned_address) {
    VirtualFree(address, reserved_size, MEM_RELEASE);
    return nullptr;
  }

  if (out_reserved_address != nullptr) {
    *out_reserved_address = address;
  }
  return aligned_address;
}

void VirtualMemory::Init() {
  if (FLAG_old_gen_heap_size < 0 || FLAG_old_gen_heap_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --old_gen_heap_size %d is larger than"
        " the physically addressable range, using 0(unlimited) instead.`\n",
        FLAG_old_gen_heap_size);
    FLAG_old_gen_heap_size = 0;
  }
  if (FLAG_new_gen_semi_max_size < 0 ||
      FLAG_new_gen_semi_max_size > kMaxAddrSpaceMB) {
    OS::PrintErr(
        "warning: value specified for --new_gen_semi_max_size %d is larger"
        " than the physically addressable range, using %" Pd " instead.`\n",
        FLAG_new_gen_semi_max_size, kDefaultNewGenSemiMaxSize);
    FLAG_new_gen_semi_max_size = kDefaultNewGenSemiMaxSize;
  }
  page_size_ = CalculatePageSize();
#if defined(DART_COMPRESSED_POINTERS)
  ASSERT(compressed_heap_ == nullptr);
  compressed_heap_ = Reserve(kCompressedHeapSize, kCompressedHeapAlignment);
  if (compressed_heap_ == nullptr) {
    int error = GetLastError();
    FATAL("Failed to reserve region for compressed heap: %d", error);
  }
  VirtualMemoryCompressedHeap::Init(compressed_heap_->address(),
                                    compressed_heap_->size());
#endif  // defined(DART_COMPRESSED_POINTERS)
}

void VirtualMemory::Cleanup() {
#if defined(DART_COMPRESSED_POINTERS)
  delete compressed_heap_;
  compressed_heap_ = nullptr;
  VirtualMemoryCompressedHeap::Cleanup();
#endif  // defined(DART_COMPRESSED_POINTERS)
}

bool VirtualMemory::DualMappingEnabled() {
  return false;
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              bool is_compressed,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect.
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));

#if defined(DART_COMPRESSED_POINTERS)
  if (is_compressed) {
    RELEASE_ASSERT(!is_executable);
    MemoryRegion region =
        VirtualMemoryCompressedHeap::Allocate(size, alignment);
    if (region.pointer() == nullptr) {
      return nullptr;
    }
    Commit(region.pointer(), region.size());
    return new VirtualMemory(region, region);
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  intptr_t reserved_size = size + alignment - PageSize();
  int prot = (is_executable && !FLAG_write_protect_code)
                 ? PAGE_EXECUTE_READWRITE
                 : PAGE_READWRITE;

  void* reserved_address;
  void* aligned_address = AllocateAlignedImpl(size, alignment, reserved_size,
                                              prot, &reserved_address);
  if (aligned_address == nullptr) {
    return nullptr;
  }

  MemoryRegion region(aligned_address, size);
  MemoryRegion reserved(reserved_address, reserved_size);
  return new VirtualMemory(region, reserved);
}

VirtualMemory* VirtualMemory::Reserve(intptr_t size, intptr_t alignment) {
  ASSERT(Utils::IsAligned(size, PageSize()));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, PageSize()));
  intptr_t reserved_size = size + alignment - PageSize();
  void* reserved_address =
      VirtualAlloc(nullptr, reserved_size, MEM_RESERVE, PAGE_NOACCESS);
  if (reserved_address == nullptr) {
    return nullptr;
  }

  void* aligned_address = reinterpret_cast<void*>(
      Utils::RoundUp(reinterpret_cast<uword>(reserved_address), alignment));
  MemoryRegion region(aligned_address, size);
  MemoryRegion reserved(reserved_address, reserved_size);
  return new VirtualMemory(region, reserved);
}

void VirtualMemory::Commit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  void* result = VirtualAlloc(address, size, MEM_COMMIT, PAGE_READWRITE);
  if (result == nullptr) {
    int error = GetLastError();
    FATAL("Failed to commit: %d\n", error);
  }
}

void VirtualMemory::Decommit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  bool result = VirtualFree(address, size, MEM_DECOMMIT);
  if (!result) {
    int error = GetLastError();
    FATAL("Failed to decommit: %d\n", error);
  }
}

VirtualMemory::~VirtualMemory() {
  // Note that the size of the reserved region might be set to 0 by
  // Truncate(0, true) but that does not actually release the mapping
  // itself. The only way to release the mapping is to invoke VirtualFree
  // with original base pointer and MEM_RELEASE.
#if defined(DART_COMPRESSED_POINTERS)
  if (VirtualMemoryCompressedHeap::Contains(reserved_.pointer())) {
    Decommit(reserved_.pointer(), reserved_.size());
    VirtualMemoryCompressedHeap::Free(reserved_.pointer(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (!vm_owns_region()) {
    return;
  }
  if (VirtualFree(reserved_.pointer(), 0, MEM_RELEASE) == 0) {
    FATAL("VirtualFree failed: Error code %d\n", GetLastError());
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
#if defined(DART_COMPRESSED_POINTERS)
  // Don't free the sub segment if it's managed by the compressed pointer heap.
  if (VirtualMemoryCompressedHeap::Contains(address)) {
    return false;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (VirtualFree(address, size, MEM_DECOMMIT) == 0) {
    FATAL("VirtualFree failed: Error code %d\n", GetLastError());
  }
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsDartMutatorThread() ||
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
    FATAL("VirtualProtect failed %d\n", GetLastError());
  }
}

void VirtualMemory::DontNeed(void* address, intptr_t size) {}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
