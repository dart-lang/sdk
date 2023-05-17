// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"

#include "platform/assert.h"
#include "platform/utils.h"

#if defined(DART_HOST_OS_MACOS)
#include <mach/mach.h>
#endif

namespace dart {

bool VirtualMemory::InSamePage(uword address0, uword address1) {
  return (Utils::RoundDown(address0, PageSize()) ==
          Utils::RoundDown(address1, PageSize()));
}

void VirtualMemory::Truncate(intptr_t new_size) {
  ASSERT(Utils::IsAligned(new_size, PageSize()));
  ASSERT(new_size <= size());
  if (reserved_.size() ==
      region_.size()) {  // Don't create holes in reservation.
    if (FreeSubSegment(reinterpret_cast<void*>(start() + new_size),
                       size() - new_size)) {
      reserved_.set_size(new_size);
      if (AliasOffset() != 0) {
        FreeSubSegment(reinterpret_cast<void*>(alias_.start() + new_size),
                       alias_.size() - new_size);
      }
    }
  }
  region_.Subregion(region_, 0, new_size);
  alias_.Subregion(alias_, 0, new_size);
}

VirtualMemory* VirtualMemory::ForImagePage(void* pointer, uword size) {
  // Memory for precompilated instructions was allocated by the embedder, so
  // create a VirtualMemory without allocating.
  MemoryRegion region(pointer, size);
  MemoryRegion reserved(nullptr, 0);  // null reservation indicates VM should
                                      // not attempt to free this memory.
  VirtualMemory* memory = new VirtualMemory(region, region, reserved);
  ASSERT(!memory->vm_owns_region());
  return memory;
}

VirtualMemory* VirtualMemory::DuplicateRX() {
#if defined(DART_HOST_OS_MACOS)
  // Mac is special cased because iOS doesn't allow allocating new executable
  // memory, so the default approach would fail. We are allowed to make new
  // mappings of existing executable memory using vm_remap though, which is
  // effectively the same for non-writable memory.
  const mach_port_t task = mach_task_self();
  const vm_address_t source_address = reinterpret_cast<vm_address_t>(address());
  const vm_size_t mem_size = size();
  vm_prot_t current_protection = VM_PROT_READ | VM_PROT_EXECUTE;
  vm_prot_t max_protection = current_protection;
  vm_address_t target_address = 0;
  kern_return_t status =
      vm_remap(task, &target_address, mem_size,
               /*mask=*/0,
               /*flags=anywhere*/ 1, task, source_address,
               /*copy=*/true, &current_protection, &max_protection,
               /*inheritance=*/VM_INHERIT_NONE);
  if (status != KERN_SUCCESS) {
    return nullptr;
  }
  const MemoryRegion region(reinterpret_cast<void*>(target_address), mem_size);
  return new VirtualMemory(region, region);

#else   // defined(DART_HOST_OS_MACOS)
  // TODO(liama): Use dual mapping on platforms where it's supported.
  VirtualMemory* const memory = VirtualMemory::Allocate(
      size(), /*is_executable=*/true, /*is_compressed=*/false,
      "VirtualMemory::DuplicateRX");
  if (memory == nullptr) {
    return nullptr;
  }
  // This is safe because the old memory can't overlap with the new memory.
  memcpy(memory->address(), address(), size());  // NOLINT
  memory->Protect(kReadExecute);
  return memory;
#endif  // defined(DART_HOST_OS_MACOS)
}

}  // namespace dart
