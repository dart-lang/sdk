// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/runtime_entry.h"

#include "vm/simulator.h"
#include "vm/stub_code.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#define __ assembler->

uword RuntimeEntry::GetEntryPoint() const {
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(function());
#if defined(USING_SIMULATOR)
  // Redirection to leaf runtime calls supports a maximum of 4 arguments passed
  // in registers (maximum 2 double arguments for leaf float runtime calls).
  ASSERT(argument_count() >= 0);
  ASSERT(!is_leaf() || (!is_float() && (argument_count() <= 4)) ||
         (argument_count() <= 2));
  Simulator::CallKind call_kind =
      is_leaf() ? (is_float() ? Simulator::kLeafFloatRuntimeCall
                              : Simulator::kLeafRuntimeCall)
                : Simulator::kRuntimeCall;
  entry =
      Simulator::RedirectExternalReference(entry, call_kind, argument_count());
#endif
  return entry;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
