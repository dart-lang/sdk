// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/virtual_memory.h"

#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <sys/mman.h>
#include <unistd.h>

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/memory_region.h"
#include "vm/os.h"

// #define VIRTUAL_MEMORY_LOGGING 1
#if defined(VIRTUAL_MEMORY_LOGGING)
#define LOG_ERR(msg, ...)                                                      \
  OS::PrintErr("VMVM: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#define LOG_INFO(msg, ...)                                                     \
  OS::Print("VMVM: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(VIRTUAL_MEMORY_LOGGING)

namespace dart {

uword VirtualMemory::page_size_ = 0;


void VirtualMemory::InitOnce() {
  page_size_ = getpagesize();
}


VirtualMemory* VirtualMemory::ReserveInternal(intptr_t size) {
  mx_handle_t vmar = MX_HANDLE_INVALID;
  uword addr = 0;
  const uint32_t flags = MX_VM_FLAG_COMPACT | MX_VM_FLAG_CAN_MAP_SPECIFIC |
                         MX_VM_FLAG_CAN_MAP_READ | MX_VM_FLAG_CAN_MAP_WRITE |
                         MX_VM_FLAG_CAN_MAP_EXECUTE;
  mx_status_t status =
      mx_vmar_allocate(mx_vmar_root_self(), 0, size, flags, &vmar, &addr);
  if (status != NO_ERROR) {
    LOG_ERR("mx_vmar_allocate(size = %ld) failed: %s\n", size,
            mx_status_get_string(status));
    return NULL;
  }

  MemoryRegion region(reinterpret_cast<void*>(addr), size);
  return new VirtualMemory(region, vmar);
}


VirtualMemory::~VirtualMemory() {
  if (!embedder_allocated()) {
    mx_handle_t vmar = static_cast<mx_handle_t>(handle());
    mx_status_t status = mx_vmar_destroy(vmar);
    if (status != NO_ERROR) {
      LOG_ERR("mx_vmar_destroy failed: %s\n", mx_status_get_string(status));
    }
    status = mx_handle_close(vmar);
    if (status != NO_ERROR) {
      LOG_ERR("mx_handle_close failed: %s\n", mx_status_get_string(status));
    }
  }
}


bool VirtualMemory::FreeSubSegment(int32_t handle,
                                   void* address,
                                   intptr_t size) {
  mx_handle_t vmar = static_cast<mx_handle_t>(handle);
  mx_status_t status =
      mx_vmar_unmap(vmar, reinterpret_cast<uintptr_t>(address), size);
  if (status != NO_ERROR) {
    LOG_ERR("mx_vmar_unmap failed: %s\n", mx_status_get_string(status));
    return false;
  }
  return true;
}


bool VirtualMemory::Commit(uword addr, intptr_t size, bool executable) {
  ASSERT(Contains(addr));
  ASSERT(Contains(addr + size) || (addr + size == end()));
  mx_handle_t vmo = MX_HANDLE_INVALID;
  mx_status_t status = mx_vmo_create(size, 0u, &vmo);
  if (status != NO_ERROR) {
    LOG_ERR("mx_vmo_create(%ld) failed: %s\n", size,
            mx_status_get_string(status));
    return false;
  }

  mx_handle_t vmar = static_cast<mx_handle_t>(handle());
  const size_t offset = addr - start();
  const uint32_t flags = MX_VM_FLAG_SPECIFIC | MX_VM_FLAG_PERM_READ |
                         MX_VM_FLAG_PERM_WRITE | MX_VM_FLAG_PERM_EXECUTE;
  uintptr_t mapped_addr;
  status = mx_vmar_map(vmar, offset, vmo, 0, size, flags, &mapped_addr);
  if (status != NO_ERROR) {
    mx_handle_close(vmo);
    LOG_ERR("mx_vmar_map(%ld, %ld, %u) failed: %s\n", offset, size, flags,
            mx_status_get_string(status));
    return false;
  }
  if (addr != mapped_addr) {
    LOG_ERR("mx_vmar_map: addr != mapped_addr: %lx != %lx\n", addr,
            mapped_addr);
    return false;
  }
  return true;
}


bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  return true;
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
