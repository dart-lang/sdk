// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

// Only build the simulator if not compiling for real MIPS hardware.
#if !defined(HOST_ARCH_MIPS)

#include "vm/simulator.h"

#include "vm/assembler.h"
#include "vm/constants_mips.h"
#include "vm/disassembler.h"

namespace dart {

Simulator::Simulator() {
  UNIMPLEMENTED();
}


Simulator::~Simulator() {
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate->set_simulator(NULL);
  }
}


// Get the active Simulator for the current isolate.
Simulator* Simulator::Current() {
  Simulator* simulator = Isolate::Current()->simulator();
  if (simulator == NULL) {
    simulator = new Simulator();
    Isolate::Current()->set_simulator(simulator);
  }
  return simulator;
}


void Simulator::InitOnce() {
}


int64_t Simulator::Call(int32_t entry,
                        int32_t parameter0,
                        int32_t parameter1,
                        int32_t parameter2,
                        int32_t parameter3,
                        int32_t parameter4) {
  UNIMPLEMENTED();
  return 0LL;
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_MIPS)

#endif  // defined TARGET_ARCH_MIPS
