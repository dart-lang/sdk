// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/debugger.h"
#include "vm/instructions_kbc.h"
#include "vm/interpreter.h"

namespace dart {

#ifndef PRODUCT
void CodeBreakpoint::SetBytecodeBreakpoint() {
  ASSERT(!is_enabled_);
  is_enabled_ = true;
  Interpreter::Current()->set_is_debugging(true);
}

void CodeBreakpoint::UnsetBytecodeBreakpoint() {
  ASSERT(is_enabled_);
  is_enabled_ = false;
  if (!Isolate::Current()->single_step() &&
      !Isolate::Current()->debugger()->HasEnabledBytecodeBreakpoints()) {
    Interpreter::Current()->set_is_debugging(false);
  }
}

bool Debugger::HasEnabledBytecodeBreakpoints() const {
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != nullptr) {
    if (cbpt->IsEnabled() && cbpt->IsInterpreted()) {
      return true;
    }
    cbpt = cbpt->next();
  }
  return false;
}

bool Debugger::HasBytecodeBreakpointAt(const KBCInstr* next_pc) const {
  CodeBreakpoint* cbpt = code_breakpoints_;
  while (cbpt != nullptr) {
    if ((reinterpret_cast<uword>(next_pc)) == cbpt->pc_ && cbpt->IsEnabled()) {
      ASSERT(cbpt->IsInterpreted());
      return true;
    }
    cbpt = cbpt->next();
  }
  return false;
}
#endif  // !PRODUCT

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
