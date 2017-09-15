// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "vm/virtual_memory.h"

#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>
#include <sys/mman.h>
#include <unistd.h>

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
  OS::Print("VMVM: %s:%d: " msg, __FILE__, __LINE__, ##__VA_ARGS__)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(VIRTUAL_MEMORY_LOGGING)

namespace dart {

// The Zircon system call to protect memory regions (zx_vmar_protect) takes a
// VM area (vmar) handle as first argument. We call VirtualMemory::Protect()
// from the memory freelist code in vm/freelist.cc where the vmar handle is not
// available. Additionally, there is no zx_vmar system call to retrieve a handle
// for the leaf vmar given an address. Thus, when memory protections are
// enabled, we maintain a sorted list of our leaf vmar handles that we can
// query by address in calls to VirtualMemory::Protect().
class VmarList : public AllStatic {
 public:
  static void AddVmar(zx_handle_t vmar, uword addr, intptr_t size);
  static void RemoveVmar(uword addr);
  static zx_handle_t LookupVmar(uword addr);

 private:
  static intptr_t LookupVmarIndexLocked(uword addr);

  struct VmarListElement {
    zx_handle_t vmar;
    uword addr;
    intptr_t size;
  };

  static Mutex* vmar_array_lock_;
  static MallocGrowableArray<VmarListElement> vmar_array_;
};

Mutex* VmarList::vmar_array_lock_ = new Mutex();
MallocGrowableArray<VmarList::VmarListElement> VmarList::vmar_array_;

void VmarList::AddVmar(zx_handle_t vmar, uword addr, intptr_t size) {
  MutexLocker ml(vmar_array_lock_);
  LOG_INFO("AddVmar(%d, %lx, %ld)\n", vmar, addr, size);
  // Sorted insert in increasing order.
  const intptr_t length = vmar_array_.length();
  intptr_t idx;
  for (idx = 0; idx < length; idx++) {
    const VmarListElement& m = vmar_array_.At(idx);
    if (m.addr >= addr) {
      break;
    }
  }
#if defined(DEBUG)
  if ((length > 0) && (idx < (length - 1))) {
    const VmarListElement& m = vmar_array_.At(idx);
    ASSERT(m.addr != addr);
  }
#endif
  LOG_INFO("AddVmar(%d, %lx, %ld) at index = %ld\n", vmar, addr, size, idx);
  VmarListElement new_mapping;
  new_mapping.vmar = vmar;
  new_mapping.addr = addr;
  new_mapping.size = size;
  vmar_array_.InsertAt(idx, new_mapping);
}

intptr_t VmarList::LookupVmarIndexLocked(uword addr) {
  // Binary search for the vmar containing addr.
  intptr_t imin = 0;
  intptr_t imax = vmar_array_.length();
  while (imax >= imin) {
    const intptr_t imid = ((imax - imin) / 2) + imin;
    const VmarListElement& mapping = vmar_array_.At(imid);
    if ((mapping.addr + mapping.size) <= addr) {
      imin = imid + 1;
    } else if (mapping.addr > addr) {
      imax = imid - 1;
    } else {
      return imid;
    }
  }
  return -1;
}

zx_handle_t VmarList::LookupVmar(uword addr) {
  MutexLocker ml(vmar_array_lock_);
  LOG_INFO("LookupVmar(%lx)\n", addr);
  const intptr_t idx = LookupVmarIndexLocked(addr);
  if (idx == -1) {
    LOG_ERR("LookupVmar(%lx) NOT FOUND\n", addr);
    return ZX_HANDLE_INVALID;
  }
  LOG_INFO("LookupVmar(%lx) found at %ld\n", addr, idx);
  return vmar_array_[idx].vmar;
}

void VmarList::RemoveVmar(uword addr) {
  MutexLocker ml(vmar_array_lock_);
  LOG_INFO("RemoveVmar(%lx)\n", addr);
  const intptr_t idx = LookupVmarIndexLocked(addr);
  ASSERT(idx != -1);
#if defined(DEBUG)
  zx_handle_t vmar = vmar_array_[idx].vmar;
#endif
  // Swap idx to the end, and then RemoveLast()
  const intptr_t length = vmar_array_.length();
  for (intptr_t i = idx; i < length - 1; i++) {
    vmar_array_.Swap(i, i + 1);
  }
#if defined(DEBUG)
  const VmarListElement& mapping = vmar_array_.Last();
  ASSERT(mapping.vmar == vmar);
#endif
  vmar_array_.RemoveLast();
}

uword VirtualMemory::page_size_ = 0;

void VirtualMemory::InitOnce() {
  page_size_ = getpagesize();
}

VirtualMemory* VirtualMemory::ReserveInternal(intptr_t size) {
  ASSERT(Utils::IsAligned(size, page_size_));
  zx_handle_t vmar = ZX_HANDLE_INVALID;
  uword addr = 0;
  const uint32_t flags = ZX_VM_FLAG_COMPACT | ZX_VM_FLAG_CAN_MAP_SPECIFIC |
                         ZX_VM_FLAG_CAN_MAP_READ | ZX_VM_FLAG_CAN_MAP_WRITE |
                         ZX_VM_FLAG_CAN_MAP_EXECUTE;
  zx_status_t status =
      zx_vmar_allocate(zx_vmar_root_self(), 0, size, flags, &vmar, &addr);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_allocate(size = %ld) failed: %s\n", size,
            zx_status_get_string(status));
    return NULL;
  }
  VmarList::AddVmar(vmar, addr, size);
  MemoryRegion region(reinterpret_cast<void*>(addr), size);
  return new VirtualMemory(region, vmar);
}

VirtualMemory::~VirtualMemory() {
  if (vm_owns_region()) {
    zx_handle_t vmar = static_cast<zx_handle_t>(handle());
    zx_status_t status = zx_vmar_destroy(vmar);
    if (status != ZX_OK) {
      LOG_ERR("zx_vmar_destroy failed: %s\n", zx_status_get_string(status));
    }
    status = zx_handle_close(vmar);
    if (status != ZX_OK) {
      LOG_ERR("zx_handle_close failed: %s\n", zx_status_get_string(status));
    }
    VmarList::RemoveVmar(start());
  }
}

bool VirtualMemory::FreeSubSegment(int32_t handle,
                                   void* address,
                                   intptr_t size) {
  zx_handle_t vmar = static_cast<zx_handle_t>(handle);
  zx_status_t status =
      zx_vmar_unmap(vmar, reinterpret_cast<uintptr_t>(address), size);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_unmap failed: %s\n", zx_status_get_string(status));
    return false;
  }
  return true;
}

bool VirtualMemory::Commit(uword addr,
                           intptr_t size,
                           bool executable,
                           const char* name) {
  ASSERT(Contains(addr));
  ASSERT(Contains(addr + size) || (addr + size == end()));
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, 0u, &vmo);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmo_create(%ld) failed: %s\n", size,
            zx_status_get_string(status));
    return false;
  }

  if (name != NULL) {
    zx_object_set_property(vmo, ZX_PROP_NAME, name, strlen(name));
  }

  zx_handle_t vmar = static_cast<zx_handle_t>(handle());
  const size_t offset = addr - start();
  const uint32_t flags = ZX_VM_FLAG_SPECIFIC | ZX_VM_FLAG_PERM_READ |
                         ZX_VM_FLAG_PERM_WRITE |
                         (executable ? ZX_VM_FLAG_PERM_EXECUTE : 0);
  uintptr_t mapped_addr;
  status = zx_vmar_map(vmar, offset, vmo, 0, size, flags, &mapped_addr);
  if (status != ZX_OK) {
    zx_handle_close(vmo);
    LOG_ERR("zx_vmar_map(%ld, %ld, %u) failed: %s\n", offset, size, flags,
            zx_status_get_string(status));
    return false;
  }
  if (addr != mapped_addr) {
    zx_handle_close(vmo);
    LOG_ERR("zx_vmar_map: addr != mapped_addr: %lx != %lx\n", addr,
            mapped_addr);
    return false;
  }
  zx_handle_close(vmo);
  LOG_INFO("Commit(%lx, %ld, %s): success\n", addr, size,
           executable ? "executable" : "");
  return true;
}

bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  ASSERT(Thread::Current()->IsMutatorThread() ||
         Isolate::Current()->mutator_thread()->IsAtSafepoint());
  const uword start_address = reinterpret_cast<uword>(address);
  const uword end_address = start_address + size;
  const uword page_address = Utils::RoundDown(start_address, PageSize());
  zx_handle_t vmar = VmarList::LookupVmar(page_address);
  ASSERT(vmar != ZX_HANDLE_INVALID);
  uint32_t prot = 0;
  switch (mode) {
    case kNoAccess:
      // ZX-426: zx_vmar_protect() requires at least on permission.
      prot = ZX_VM_FLAG_PERM_READ;
      break;
    case kReadOnly:
      prot = ZX_VM_FLAG_PERM_READ;
      break;
    case kReadWrite:
      prot = ZX_VM_FLAG_PERM_READ | ZX_VM_FLAG_PERM_WRITE;
      break;
    case kReadExecute:
      prot = ZX_VM_FLAG_PERM_READ | ZX_VM_FLAG_PERM_EXECUTE;
      break;
    case kReadWriteExecute:
      prot = ZX_VM_FLAG_PERM_READ | ZX_VM_FLAG_PERM_WRITE |
             ZX_VM_FLAG_PERM_EXECUTE;
      break;
  }
  zx_status_t status =
      zx_vmar_protect(vmar, page_address, end_address - page_address, prot);
  if (status != ZX_OK) {
    LOG_ERR("zx_vmar_protect(%lx, %lx, %x) success: %s\n", page_address,
            end_address - page_address, prot, zx_status_get_string(status));
    return false;
  }
  LOG_INFO("zx_vmar_protect(%lx, %lx, %x) success\n", page_address,
           end_address - page_address, prot);
  return true;
}

}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
