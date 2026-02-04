// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MODULE_SNAPSHOT_H_
#define RUNTIME_VM_MODULE_SNAPSHOT_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/snapshot.h"
#include "vm/thread.h"

namespace dart {
namespace module_snapshot {

ApiErrorPtr ReadModuleSnapshot(Thread* thread,
                               const Snapshot* snapshot,
                               const uint8_t* instructions_buffer);

}  // namespace module_snapshot
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_MODULE_SNAPSHOT_H_
