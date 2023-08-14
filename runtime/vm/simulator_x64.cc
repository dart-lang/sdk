// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <setjmp.h>  // NOLINT
#include <stdlib.h>

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

// Only build the simulator if not compiling for real X64 hardware.
#if defined(USING_SIMULATOR)

#include "vm/simulator.h"

#include "vm/heap/safepoint.h"
#include "vm/isolate.h"

namespace dart {

// Get the active Simulator for the current isolate.
Simulator* Simulator::Current() {
  Isolate* isolate = Isolate::Current();
  Simulator* simulator = isolate->simulator();
  if (simulator == nullptr) {
    NoSafepointScope no_safepoint;
    simulator = new Simulator();
    isolate->set_simulator(simulator);
  }
  return simulator;
}

void Simulator::Init() {}

Simulator::Simulator() {}

Simulator::~Simulator() {
  Isolate* isolate = Isolate::Current();
  if (isolate != nullptr) {
    isolate->set_simulator(nullptr);
  }
}

int64_t Simulator::Call(int64_t entry,
                        int64_t parameter0,
                        int64_t parameter1,
                        int64_t parameter2,
                        int64_t parameter3,
                        bool fp_return,
                        bool fp_args) {
  UNIMPLEMENTED();
}

void Simulator::JumpToFrame(uword pc, uword sp, uword fp, Thread* thread) {
  UNIMPLEMENTED();
}

uword Simulator::RedirectExternalReference(uword function,
                                           CallKind call_kind,
                                           int argument_count) {
  return 0;
}

uword Simulator::FunctionForRedirect(uword redirect) {
  return 0;
}

}  // namespace dart

#endif  // !defined(USING_SIMULATOR)

#endif  // defined TARGET_ARCH_RISCV
