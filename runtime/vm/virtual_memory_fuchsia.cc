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

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::Init() {
  page_size_ = getpagesize();
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmo_create(%ld) failed: %s\n", size,
            zx_status_get_string(status));
    return NULL;
  }

  if (name != NULL) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  if (is_executable) {
    // Add ZX_PERM_EXECUTE permission to VMO, so it can be mapped
    // into memory as executable.
    status = zx_vmo_replace_as_executable(vmo, ZX_HANDLE_INVALID, &vmo);
    if (status != ZX_OK) {
      LOG_ERR("zx_vmo_replace_as_executable() failed: %s\n",
              zx_status_get_string(status));
      return NULL;
    }
  }

  const uint32_t flags = ZX_VM_PERM_READ | ZX_VM_PERM_WRITE |
                         (is_executable ? ZX_VM_PERM_EXECUTE : 0);
  uword address;
  status = zx_vmar_map(zx_vmar_root_self(), flags, 0, vmo, 0, size, &address);
  zx_handle_close(vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_map(%u, %ld) failed: %s\n", flags, size,
            zx_status_get_string(status));
    return NULL;
  }
  LOG_INFO("zx_vmar_map(%u,%ld) success\n", flags, size);

  MemoryRegion region(reinterpret_cast<void*>(address), size);
  return new VirtualMemory(region, region);
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsAligned(alignment, page_size_));
  intptr_t allocated_size = size + alignment;

  zx_handle_t vmar = zx_vmar_root_self();
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(allocated_size, 0u, &vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmo_create(%ld) failed: %s\n", size,
            zx_status_get_string(status));
    return NULL;
  }

  if (name != NULL) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  if (is_executable) {
    // Add ZX_PERM_EXECUTE permission to VMO, so it can be mapped
    // into memory as executable.
    status = zx_vmo_replace_as_executable(vmo, ZX_HANDLE_INVALID, &vmo);
    if (status != ZX_OK) {
      LOG_ERR("zx_vmo_replace_as_executable() failed: %s\n",
              zx_status_get_string(status));
      return NULL;
    }
  }

  const zx_vm_option_t options = ZX_VM_PERM_READ | ZX_VM_PERM_WRITE |
                                 (is_executable ? ZX_VM_PERM_EXECUTE : 0);
  uword base;
  status = zx_vmar_map(vmar, options, 0u, vmo, 0u, allocated_size, &base);
  zx_handle_close(vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_map(%u, %ld) failed: %s\n", flags, size,
            zx_status_get_string(status));
    return NULL;
  }

  uword aligned_base = Utils::RoundUp(base, alignment);
  ASSERT(base <= aligned_base);

  if (base != aligned_base) {
    uword extra_leading_size = aligned_base - base;
    status = zx_vmar_unmap(vmar, base, extra_leading_size);
    if (status != ZX_OK) {
      FATAL1("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
    }
    allocated_size -= extra_leading_size;
  }

  if (allocated_size != size) {
    uword extra_trailing_size = allocated_size - size;
    status = zx_vmar_unmap(vmar, aligned_base + size, extra_trailing_size);
    if (status != ZX_OK) {
      FATAL1("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
    }
  }

  MemoryRegion region(reinterpret_cast<void*>(aligned_base), size);
  return new VirtualMemory(region, region);
}

VirtualMemory::~VirtualMemory() {
  // Reserved region may be empty due to VirtualMemory::Truncate.
  if (vm_owns_region() && reserved_.size() != 0) {
    zx_status_t status =
        zx_vmar_unmap(zx_vmar_root_self(), reserved_.start(), reserved_.size());
    if (status != ZX_OK) {
      FATAL3("zx_vmar_unmap(%lx, %lx) failed: %s\n", reserved_.start(),
             reserved_.size(), zx_status_get_string(status));
    }
    LOG_INFO("zx_vmar_unmap(%lx, %lx) success\n", reserved_.start(),
             reserved_.size());
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  zx_status_t status = zx_vmar_unmap(
      zx_vmar_root_self(), reinterpret_cast<uintptr_t>(address), size);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_unmap(%p, %lx) failed: %s\n", address, size,
            zx_status_get_string(status));
    return false;
  }
  LOG_INFO("zx_vmar_unmap(%p, %lx) success\n", address, size);
  return true;
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
#if defined(DEBUG)
  Thread* thread = Thread::Current();
  ASSERT((thread == nullptr) || thread->IsMutatorThread() ||
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
  if (status != ZX_OK) {
    FATAL3("zx_vmar_protect(%lx, %lx) failed: %s\n", page_address,
           end_address - page_address, zx_status_get_string(status));
  }
  LOG_INFO("zx_vmar_protect(%lx, %lx, %x) success\n", page_address,
           end_address - page_address, prot);
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
