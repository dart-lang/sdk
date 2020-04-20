// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "vm/virtual_memory.h"

#include <sys/mman.h>
#include <unistd.h>
#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/memory_region.h"
#include "vm/os.h"
#include "vm/os_thread.h"

// #define VIRTUAL_MEMORY_LOGGING 1
#if defined(VIRTUAL_MEMORY_LOGGING)
#define LOG_ERR(msg, ...)                                                      \
  OS::PrintErr("VMVM: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#define LOG_INFO(msg, ...)                                                     \
  OS::PrintErr("VMVM: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(VIRTUAL_MEMORY_LOGGING)

namespace dart {

DECLARE_FLAG(bool, dual_map_code);
DECLARE_FLAG(bool, write_protect_code);

uword VirtualMemory::page_size_ = 0;

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

void VirtualMemory::Init() {
  page_size_ = CalculatePageSize();
}

static void Unmap(zx_handle_t vmar, uword start, uword end) {
  ASSERT(start <= end);
  const uword size = end - start;
  if (size == 0) {
    return;
  }

  zx_status_t status = zx_vmar_unmap(vmar, start, size);
  if (status != ZX_OK) {
    FATAL1("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
  }
}

bool VirtualMemory::DualMappingEnabled() {
  return FLAG_dual_map_code;
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect, which requires
  // ZX_RIGHT_EXECUTE on the underlying VMO.
  //
  // If FLAG_dual_map_code is active, the executable mapping will be mapped RX
  // immediately and never changes protection until it is eventually unmapped.
  //
  // In addition, dual mapping of the same underlying code memory is provided.
  const bool dual_mapping =
      is_executable && FLAG_write_protect_code && FLAG_dual_map_code;

  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, page_size_));

  const zx_vm_option_t align_flag = Utils::ShiftForPowerOfTwo(alignment)
                                    << ZX_VM_ALIGN_BASE;
  ASSERT((ZX_VM_ALIGN_1KB <= align_flag) && (align_flag <= ZX_VM_ALIGN_4GB));

  zx_handle_t vmar = zx_vmar_root_self();
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmo_create(0x%lx) failed: %s\n", size,
            zx_status_get_string(status));
    return NULL;
  }

  if (name != NULL) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  if (is_executable) {
    // Add ZX_RIGHT_EXECUTE permission to VMO, so it can be mapped
    // into memory as executable (now or later).
    status = zx_vmo_replace_as_executable(vmo, ZX_HANDLE_INVALID, &vmo);
    if (status != ZX_OK) {
      LOG_ERR("zx_vmo_replace_as_executable() failed: %s\n",
              zx_status_get_string(status));
      return NULL;
    }
  }

  const zx_vm_option_t region_options =
      ZX_VM_PERM_READ | ZX_VM_PERM_WRITE | align_flag |
      ((is_executable && !FLAG_write_protect_code) ? ZX_VM_PERM_EXECUTE : 0);
  uword base;
  status = zx_vmar_map(vmar, region_options, 0, vmo, 0u, size, &base);
  LOG_INFO("zx_vmar_map(%u, 0x%lx, 0x%lx)\n", region_options, base, size);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_map(%u, 0x%lx, 0x%lx) failed: %s\n", region_options, base,
            size, zx_status_get_string(status));
    return NULL;
  }
  void* region_ptr = reinterpret_cast<void*>(base);
  MemoryRegion region(region_ptr, size);

  VirtualMemory* result;

  if (dual_mapping) {
    // The mapping will be RX and stays that way until it will eventually be
    // unmapped.
    const zx_vm_option_t alias_options =
        ZX_VM_PERM_READ | ZX_VM_PERM_EXECUTE | align_flag;
    status = zx_vmar_map(vmar, alias_options, 0, vmo, 0u, size, &base);
    LOG_INFO("zx_vmar_map(%u, 0x%lx, 0x%lx)\n", alias_options, base, size);
    if (status != ZX_OK) {
      LOG_ERR("zx_vmar_map(%u, 0x%lx, 0x%lx) failed: %s\n", alias_options, base,
              size, zx_status_get_string(status));
      const uword region_base = reinterpret_cast<uword>(region_ptr);
      Unmap(vmar, region_base, region_base + size);
      return NULL;
    }
    void* alias_ptr = reinterpret_cast<void*>(base);
    ASSERT(region_ptr != alias_ptr);
    MemoryRegion alias(alias_ptr, size);
    result = new VirtualMemory(region, alias, region);
  } else {
    result = new VirtualMemory(region, region, region);
  }
  zx_handle_close(vmo);
  return result;
}

VirtualMemory::~VirtualMemory() {
  // Reserved region may be empty due to VirtualMemory::Truncate.
  if (vm_owns_region() && reserved_.size() != 0) {
    Unmap(zx_vmar_root_self(), reserved_.start(), reserved_.end());
    LOG_INFO("zx_vmar_unmap(0x%lx, 0x%lx) success\n", reserved_.start(),
             reserved_.size());

    const intptr_t alias_offset = AliasOffset();
    if (alias_offset != 0) {
      Unmap(zx_vmar_root_self(), reserved_.start() + alias_offset,
            reserved_.end() + alias_offset);
      LOG_INFO("zx_vmar_unmap(0x%lx, 0x%lx) success\n",
               reserved_.start() + alias_offset, reserved_.size());
    }
  }
}

void VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  const uword start = reinterpret_cast<uword>(address);
  Unmap(zx_vmar_root_self(), start, start + size);
  LOG_INFO("zx_vmar_unmap(0x%p, 0x%lx) success\n", address, size);
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT(thread == nullptr || thread->IsMutatorThread() ||
         thread->isolate() == nullptr ||
         thread->isolate()->mutator_thread()->IsAtSafepoint());
#endif
  const uword start_address = reinterpret_cast<uword>(address);
  const uword end_address = start_address + size;
  const uword page_address = Utils::RoundDown(start_address, PageSize());
  uint32_t prot = 0;
  switch (mode) {
    case kNoAccess:
      prot = 0;
      break;
    case kReadOnly:
      prot = ZX_VM_PERM_READ;
      break;
    case kReadWrite:
      prot = ZX_VM_PERM_READ | ZX_VM_PERM_WRITE;
      break;
    case kReadExecute:
      prot = ZX_VM_PERM_READ | ZX_VM_PERM_EXECUTE;
      break;
    case kReadWriteExecute:
      prot = ZX_VM_PERM_READ | ZX_VM_PERM_WRITE | ZX_VM_PERM_EXECUTE;
      break;
  }
  zx_status_t status = zx_vmar_protect(zx_vmar_root_self(), prot, page_address,
                                       end_address - page_address);
  LOG_INFO("zx_vmar_protect(%u, 0x%lx, 0x%lx)\n", prot, page_address,
           end_address - page_address);
  if (status != ZX_OK) {
    FATAL3("zx_vmar_protect(0x%lx, 0x%lx) failed: %s\n", page_address,
           end_address - page_address, zx_status_get_string(status));
  }
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
