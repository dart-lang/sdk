// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/thread_interrupter.h"

#include "platform/assert.h"

namespace dart {

void ThreadInterrupter::InterruptThread(OSThread* thread) {
  UNIMPLEMENTED();
}


void ThreadInterrupter::InstallSignalHandler() {
  UNIMPLEMENTED();
}


void ThreadInterrupter::RemoveSignalHandler() {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
