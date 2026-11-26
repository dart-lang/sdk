// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_FUCHSIA)

#include "vm/virtual_memory.h"

#include <fidl/fuchsia.kernel/cpp/fidl.h>
#include <lib/component/incoming/cpp/protocol.h>
#include <lib/zx/resource.h>
#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/isolate.h"
#include "vm/memory_region.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/thread.h"
#include "vm/virtual_memory_compressed.h"

namespace dart {

DECLARE_FLAG(bool, write_protect_code);

size_t VirtualMemory::page_size_ = 0;
RelaxedAtomic<size_t> VirtualMemory::used_ = {0};
size_t VirtualMemory::limit_ = SIZE_MAX;

static zx_handle_t vmex_resource_ = ZX_HANDLE_INVALID;

size_t VirtualMemory::QueryPageSize() {
  return zx_system_get_page_size();
}

size_t VirtualMemory::QueryJobMemoryLimit() {
  // zx_job_default() is the job for this process to create children. It is not
  // necessarily the job this process is in. Anyway, Zircon jobs as yet can only
  // limit memory by blocking the creation of VMOs completely.
  return zx_system_get_physmem();
}

void VirtualMemory::InitExecutable() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // If VmexResource is unavailable or does not return a valid handle then
  // this will be observed as failures from vmo_replace_as_executable below.
  if (auto client_end = component::Connect<fuchsia_kernel::VmexResource>();
      client_end.is_ok()) {
    if (auto result = fidl::Call(*client_end)->Get(); result.is_ok()) {
      vmex_resource_ = result->resource().release();
    }
  }
#endif
}

void VirtualMemory::Cleanup() {
  vmex_resource_ = ZX_HANDLE_INVALID;
  page_size_ = 0;
  ASSERT(used_.load() == 0);
  limit_ = SIZE_MAX;
}

static void Unmap(uword start, uword size) {
  if (size == 0) {
    return;
  }

  zx_status_t status = zx_vmar_unmap(zx_vmar_root_self(), start, size);
  if (status != ZX_OK) {
    FATAL("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
  }
}

VirtualMemory* VirtualMemory::AllocateAligned(intptr_t size,
                                              intptr_t alignment,
                                              bool is_executable,
                                              const char* name) {
  // When FLAG_write_protect_code is active, code memory (indicated by
  // is_executable = true) is allocated as non-executable and later
  // changed to executable via VirtualMemory::Protect, which requires
  // ZX_RIGHT_EXECUTE on the underlying VMO.
  ASSERT(Utils::IsAligned(size, page_size_));
  ASSERT(Utils::IsPowerOfTwo(alignment));
  ASSERT(Utils::IsAligned(alignment, page_size_));

  // Ignore executable for gen_snapshot/simulator, but still let the heap
  // track code and data pages separately.
  if (!VirtualMemory::ExecutesGeneratedCode()) {
    is_executable = false;
  }

  if (!TryCharge(size)) {
    return nullptr;
  }

  const zx_vm_option_t align_flag = Utils::ShiftForPowerOfTwo(alignment)
                                    << ZX_VM_ALIGN_BASE;
  ASSERT((ZX_VM_ALIGN_1KB <= align_flag) && (align_flag <= ZX_VM_ALIGN_4GB));

  zx_handle_t vmar = zx_vmar_root_self();
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status == ZX_ERR_NO_MEMORY) {
    Uncharge(size);
    return nullptr;
  } else if (status != ZX_OK) {
    FATAL("zx_vmo_create(0x%lx) failed: %s\n", size,
          zx_status_get_string(status));
  }

  if (name != nullptr) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  if (is_executable) {
    // Add ZX_RIGHT_EXECUTE permission to VMO, so it can be mapped
    // into memory as executable (now or later).
    status = zx_vmo_replace_as_executable(vmo, vmex_resource_, &vmo);
    if (status == ZX_ERR_NO_MEMORY) {
      zx_handle_close(vmo);
      Uncharge(size);
      return nullptr;
    } else if (status != ZX_OK) {
      FATAL("zx_vmo_replace_as_executable() failed: %s\n",
            zx_status_get_string(status));
    }
  }

  const zx_vm_option_t region_options =
      ZX_VM_PERM_READ | ZX_VM_PERM_WRITE | align_flag |
      ((is_executable && !FLAG_write_protect_code) ? ZX_VM_PERM_EXECUTE : 0);
  uword base;
  status = zx_vmar_map(vmar, region_options, 0, vmo, 0u, size, &base);
  if (status != ZX_OK) {
    zx_handle_close(vmo);
    Uncharge(size);
    return nullptr;
  }
  void* region_ptr = reinterpret_cast<void*>(base);
  MemoryRegion region(region_ptr, size);
  VirtualMemory* result = new VirtualMemory(region, region);
  zx_handle_close(vmo);

  return result;
}

VirtualMemory::~VirtualMemory() {
#if defined(DART_COMPRESSED_POINTERS)
  if (cage_ != nullptr) {
    cage_->Free(reserved_.pointer(), reserved_.size());
    return;
  }
#endif  // defined(DART_COMPRESSED_POINTERS)
  // Reserved region may be empty due to VirtualMemory::Truncate.
  if (vm_owns_region() && reserved_.size() != 0) {
    Unmap(reserved_.start(), reserved_.size());
    Uncharge(region_.size());
  }
}

bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  const uword start = reinterpret_cast<uword>(address);
  Unmap(start, size);
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

void VirtualMemory::DontNeed(void* address, intptr_t size) {
  uword start_address = reinterpret_cast<uword>(address);
  uword end_address = start_address + size;
  uword page_address = Utils::RoundDown(start_address, PageSize());
  zx_status_t status =
      zx_vmar_op_range(zx_vmar_root_self(), ZX_VMAR_OP_DONT_NEED, page_address,
                       end_address - page_address, nullptr, 0);
  if (status != ZX_OK) {
    FATAL("zx_vmar_op_range(DONTNEED, 0x%lx, 0x%lx) failed: %s\n", page_address,
          end_address - page_address, zx_status_get_string(status));
  }
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_FUCHSIA)
