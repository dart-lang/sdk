// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(
    int,
    memory_limit_percent,
    80,
    "Percent of job/cgroup/system memory limit to use as VM memory limit");

bool VirtualMemory::InSamePage(uword address0, uword address1) {
  return (Utils::RoundDown(address0, PageSize()) ==
          Utils::RoundDown(address1, PageSize()));
}

void VirtualMemory::Truncate(intptr_t new_size) {
  ASSERT(Utils::IsAligned(new_size, PageSize()));
  ASSERT(new_size <= size());
  // We are not expected to call this with executable pages.
  ASSERT(OffsetToExecutableAlias() == 0);
  if (!InCage()) {
    if (reserved_.size() ==
        region_.size()) {  // Don't create holes in reservation.
      if (FreeSubSegment(reinterpret_cast<void*>(start() + new_size),
                         size() - new_size)) {
        reserved_.set_size(new_size);
      }
    }
  }
  region_.Subregion(region_, 0, new_size);
}

VirtualMemory* VirtualMemory::ForImagePage(void* pointer, uword size) {
  // Memory for precompilated instructions was allocated by the embedder, so
  // create a VirtualMemory without allocating.
  MemoryRegion region(pointer, size);
  MemoryRegion reserved(nullptr, 0);  // null reservation indicates VM should
                                      // not attempt to free this memory.
  VirtualMemory* memory = new VirtualMemory(region, reserved);
  ASSERT(!memory->vm_owns_region());
  return memory;
}

VirtualMemory* VirtualMemory::Adopt(void* pointer, uword size) {
  ForceCharge(size);
  MemoryRegion region(pointer, size);
  VirtualMemory* memory = new VirtualMemory(region, region);
  ASSERT(memory->vm_owns_region());
  return memory;
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
  page_size_ = QueryPageSize();

  InitExecutable();

  if ((FLAG_memory_limit_percent >= 0) && (FLAG_memory_limit_percent <= 100)) {
    size_t job_memory_limit = QueryJobMemoryLimit();
    limit_ = job_memory_limit / 100 * FLAG_memory_limit_percent;
    if (FLAG_verbose_gc) {
      OS::PrintErr("Set memory limit to %" Pd "\n", limit_);
    }
  }
}

}  // namespace dart
