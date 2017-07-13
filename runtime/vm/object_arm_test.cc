// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(Assembler* assembler) {
  __ LoadImmediate(R0, 0);
  __ Push(R0);
  __ ldr(IP, Address(SP, 0));
  __ add(IP, IP, Operand(1));
  __ str(IP, Address(SP, 0));
  __ ldr(IP, Address(SP, 0));
  __ add(IP, IP, Operand(1));
  __ Pop(R0);
  __ mov(R0, Operand(IP));
  __ Ret();
}

// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  __ EnterDartFrame(0);  // To setup pp.
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ LoadObject(R0, string_object);
  __ LeaveDartFrame();
  __ Ret();
}

// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value) {
  // No need to setup pp, since Smis are not stored in the object pool.
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  __ LoadObject(R0, smi_object);
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
