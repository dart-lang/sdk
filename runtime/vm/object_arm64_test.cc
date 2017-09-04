// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(Assembler* assembler) {
  __ EnterFrame(1 * kWordSize);
  __ movz(R0, Immediate(0), 0);
  __ Push(R0);
  __ add(R0, R0, Operand(1));
  __ str(R0, Address(SP));
  __ ldr(R1, Address(SP));
  __ add(R1, R1, Operand(1));
  __ Pop(R0);
  __ mov(R0, R1);
  __ LeaveFrame();
  __ ret();
}

// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ EnterStubFrame();
  __ LoadObject(R0, string_object);
  __ LeaveStubFrame();
  __ ret();
}

// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value) {
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  const int64_t val = reinterpret_cast<int64_t>(smi_object.raw());
  __ LoadImmediate(R0, val);
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
