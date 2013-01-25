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
  UNIMPLEMENTED();
}


void Simulator::InitOnce() {
}

}  // namespace dart

#endif  // !defined(HOST_ARCH_MIPS)

#endif  // defined TARGET_ARCH_MIPS
