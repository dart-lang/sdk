// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/debugger.h"
#include "vm/instructions_kbc.h"

namespace dart {

#ifndef PRODUCT

void CodeBreakpoint::SetBytecodeBreak() {
  ASSERT(!is_enabled_);
  ASSERT(!Isolate::Current()->is_using_old_bytecode_instructions());
  // TODO(regis): Register pc_ (or the token pos range including pc_) with the
  // interpreter as a debug break address.
  is_enabled_ = true;
}

void CodeBreakpoint::UnsetBytecodeBreak() {
  ASSERT(is_enabled_);
  // TODO(regis): Unregister pc_ (or the token pos range including pc_) with the
  // interpreter as a debug break address.
  is_enabled_ = false;
}
#endif  // !PRODUCT

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
