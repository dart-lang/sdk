// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "vm/virtual_memory.h"

#include <memoryapi.h>
#include <processthreadsapi.h>
#include <psapi.h>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/isolate.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/thread.h"
#include "vm/virtual_memory_compressed.h"

namespace dart {

DECLARE_FLAG(bool, write_protect_code);

size_t VirtualMemory::page_size_ = 0;
RelaxedAtomic<size_t> VirtualMemory::used_ = {0};
size_t VirtualMemory::limit_ = SIZE_MAX;

static intptr_t allocation_granule = 0;

size_t VirtualMemory::QueryPageSize() {
  SYSTEM_INFO info;
  GetSystemInfo(&info);
  const size_t page_size = info.dwPageSize;
  allocation_granule = info.dwAllocationGranularity;
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

size_t VirtualMemory::QueryJobMemoryLimit() {
  size_t system_limit = SIZE_MAX;
  size_t job_limit = SIZE_MAX;
  size_t process_limit = SIZE_MAX;

  MEMORYSTATUSEX memory_status = {};
  memory_status.dwLength = sizeof(memory_status);
  if (GlobalMemoryStatusEx(&memory_status)) {
    system_limit = memory_status.ullTotalPhys;
  }

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit_info = {};
  if (QueryInformationJobObject(nullptr, JobObjectExtendedLimitInformation,
                                &limit_info, sizeof(limit_info), nullptr)) {
    if ((limit_info.BasicLimitInformation.LimitFlags &
         JOB_OBJECT_LIMIT_JOB_MEMORY) != 0) {
      job_limit = limit_info.JobMemoryLimit;
    }
    if ((limit_info.BasicLimitInformation.LimitFlags &
         JOB_OBJECT_LIMIT_PROCESS_MEMORY) != 0) {
      process_limit = limit_info.ProcessMemoryLimit;
    }
  }

  return Utils::Minimum(system_limit, Utils::Minimum(job_limit, process_limit));
}

static void* AllocateAlignedImpl(intptr_t size,
                                 intptr_t alignment,
                                 DWORD type,
                                 DWORD prot,
                                 void** out_reserved_address,
                                 intptr_t* out_reserved_size) {
  MEM_ADDRESS_REQUIREMENTS requirements = {};
  requirements.Alignment = Utils::Maximum(alignment, allocation_granule);
  MEM_EXTENDED_PARAMETER param = {};
  param.Type = MemExtendedParameterAddressRequirements;
  param.Pointer = &requirements;
  void* address = VirtualAlloc2(nullptr, nullptr, size, type, prot, &param, 1);
  if (address == nullptr) {
    return nullptr;
  }
  *out_reserved_address = address;
  *out_reserved_size = size;
  return address;
}

void VirtualMemory::InitExecutable() {}

void VirtualMemory::Cleanup() {
  page_size_ = 0;
  ASSERT(used_.load() == 0);
  limit_ = SIZE_MAX;
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

  // Ignore executable for gen_snapshot/simulator, but still let the heap
  // track code and data pages separately.
  if (!VirtualMemory::ExecutesGeneratedCode()) {
    is_executable = false;
  }

  if (!TryCharge(size)) {
    return nullptr;
  }

  int prot = (is_executable && !FLAG_write_protect_code)
                 ? PAGE_EXECUTE_READWRITE
                 : PAGE_READWRITE;
  void* reserved_address;
  intptr_t reserved_size;
  void* aligned_address = AllocateAlignedImpl(
      size, alignment, MEM_COMMIT, prot, &reserved_address, &reserved_size);
  if (aligned_address == nullptr) {
    Uncharge(size);
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
  void* reserved_address;
  intptr_t reserved_size;
  void* aligned_address =
      AllocateAlignedImpl(size, alignment, MEM_RESERVE, PAGE_NOACCESS,
                          &reserved_address, &reserved_size);
  if (aligned_address == nullptr) {
    return nullptr;
  }
  MemoryRegion region(aligned_address, size);
  MemoryRegion reserved(reserved_address, reserved_size);
  VirtualMemory* result = new VirtualMemory(region, reserved);
  result->reserved_only_ = true;
  return result;
}

bool VirtualMemory::Commit(void* address, intptr_t size, const char* name) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  if (!TryCharge(size)) {
    return false;
  }
  void* result = VirtualAlloc(address, size, MEM_COMMIT, PAGE_READWRITE);
  if (result == nullptr) {
    int error = GetLastError();
    if ((error == ERROR_COMMITMENT_LIMIT) ||
        (error == ERROR_NOT_ENOUGH_MEMORY) ||
        (error == ERROR_NOT_ENOUGH_QUOTA)) {
      Uncharge(size);
      return false;
    }
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to commit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  return true;
}

void VirtualMemory::Decommit(void* address, intptr_t size) {
  ASSERT(Utils::IsAligned(address, PageSize()));
  ASSERT(Utils::IsAligned(size, PageSize()));
  bool result = VirtualFree(address, size, MEM_DECOMMIT);
  if (!result) {
    int error = GetLastError();
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Failed to decommit: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  Uncharge(size);
}

VirtualMemory::~VirtualMemory() {
  // Note that the size of the reserved region might be set to 0 by
  // Truncate(0, true) but that does not actually release the mapping
  // itself. The only way to release the mapping is to invoke VirtualFree
  // with original base pointer and MEM_RELEASE.
#if defined(DART_COMPRESSED_POINTERS)
  if (cage_ != nullptr) {
    cage_->Free(reserved_.pointer(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  if (!vm_owns_region()) {
    return;
  }
  if (VirtualFree(reserved_.pointer(), 0, MEM_RELEASE) == 0) {
    int error = GetLastError();
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("VirtualFree failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  if (!reserved_only_) {
    Uncharge(region_.size());
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  if (VirtualFree(address, size, MEM_DECOMMIT) == 0) {
    int error = GetLastError();
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("VirtualFree failed: %d (%s)", error,
          Utils::StrError(error, error_buf, kBufferSize));
  }
  Uncharge(size);
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
    int error = GetLastError();
    char buffer[1024];
    FATAL("VirtualProtect failed %d (%s)\n", error,
          Utils::StrError(error, buffer, sizeof(buffer)));
  }
}

void VirtualMemory::DontNeed(void* address, intptr_t size) {}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
