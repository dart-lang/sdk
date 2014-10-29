// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/verified_memory.h"

namespace dart {

#if defined(DEBUG)

DEFINE_FLAG(bool, verified_mem, false,
            "Enable write-barrier verification mode (slow, DEBUG only).");
DEFINE_FLAG(int, verified_mem_max_reserve_mb, (kWordSize <= 4) ? 16 : 32,
            "When verified_mem is true, largest supported reservation (MB).");


VirtualMemory* VerifiedMemory::ReserveInternal(intptr_t size) {
  if (size > offset()) {
    FATAL1("Requested reservation of %" Pd " bytes exceeds the limit. "
           "Use --verified_mem_max_reserve_mb to increase it.", size);
  }
  VirtualMemory* result = VirtualMemory::Reserve(size + offset());
  if (result != NULL) {
    // Commit the offset part of the reservation (writable, not executable).
    result->Commit(result->start() + offset(), size, /* executable = */ false);
    // Truncate without unmapping, so that the returned object looks like
    // a normal 'size' bytes reservation (but VirtualMemory will correctly
    // unmap the entire original reservation on destruction).
    result->Truncate(size, /* try_unmap = */ false);
  }
  return result;
}

#endif  // DEBUG

}  // namespace dart
