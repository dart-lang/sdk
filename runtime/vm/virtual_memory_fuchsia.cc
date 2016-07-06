// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/virtual_memory.h"

#include <unistd.h>  // NOLINT

#include "platform/assert.h"
#include "vm/os.h"

namespace dart {

uword VirtualMemory::page_size_ = 0;


void VirtualMemory::InitOnce() {
  page_size_ = getpagesize();
}


VirtualMemory* VirtualMemory::ReserveInternal(intptr_t size) {
  UNIMPLEMENTED();
  return NULL;
}


VirtualMemory::~VirtualMemory() {
  UNIMPLEMENTED();
}


bool VirtualMemory::FreeSubSegment(void* address, intptr_t size) {
  UNIMPLEMENTED();
  return false;
}


bool VirtualMemory::Commit(uword addr, intptr_t size, bool executable) {
  UNIMPLEMENTED();
  return false;
}


bool VirtualMemory::Protect(void* address, intptr_t size, Protection mode) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
