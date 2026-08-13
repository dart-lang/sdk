// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_FUCHSIA)

#include "bin/virtual_memory.h"

#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

uword VirtualMemory::page_size_ = 0;

intptr_t VirtualMemory::CalculatePageSize() {
  const intptr_t page_size = getpagesize();
  ASSERT(page_size != 0);
  ASSERT(Utils::IsPowerOfTwo(page_size));
  return page_size;
}

VirtualMemory* VirtualMemory::Allocate(intptr_t size,
                                       bool is_executable,
                                       const char* name) {
  ASSERT(Utils::IsAligned(size, page_size_));
  zx_handle_t vmar = zx_vmar_root_self();
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status != ZX_OK) {
    return nullptr;
  }

  if (name != nullptr) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  if (is_executable) {
    // Add ZX_RIGHT_EXECUTE permission to VMO, so it can be mapped
    // into memory as executable (now or later).
    status = zx_vmo_replace_as_executable(vmo, ZX_HANDLE_INVALID, &vmo);
    if (status != ZX_OK) {
      zx_handle_close(vmo);
      return nullptr;
    }
  }

  const zx_vm_option_t region_options =
      ZX_VM_PERM_READ | ZX_VM_PERM_WRITE |
      (is_executable ? ZX_VM_PERM_EXECUTE : 0);
  uword base;
  status = zx_vmar_map(vmar, region_options, 0, vmo, 0u, size, &base);
  zx_handle_close(vmo);
  if (status != ZX_OK) {
    return nullptr;
  }

  return new VirtualMemory(reinterpret_cast<void*>(base), size);
}

VirtualMemory::~VirtualMemory() {
  if (address_ != nullptr) {
    zx_status_t status = zx_vmar_unmap(
        zx_vmar_root_self(), reinterpret_cast<uword>(address_), size_);
    if (status != ZX_OK) {
      FATAL("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
    }
  }
}

void VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
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
    FATAL("zx_vmar_protect(0x%lx, 0x%lx) failed: %s\n", page_address,
          end_address - page_address, zx_status_get_string(status));
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA)
