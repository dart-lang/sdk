// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->


// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(Assembler* assembler) {
  __ Push(ZR);
  __ lw(TMP1, Address(SP, 0));
  __ addiu(TMP1, TMP1, Immediate(1));
  __ sw(TMP1, Address(SP, 0));
  __ lw(TMP1, Address(SP, 0));
  __ addiu(TMP1, TMP1, Immediate(1));
  __ Pop(V0);
  __ mov(V0, TMP1);
  __ Ret();
}


// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  __ EnterDartFrame(0);  // To setup pp.
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ LoadObject(V0, string_object);
  __ LeaveDartFrameAndReturn();
}


// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value) {
  // No need to setup pp, since Smis are not stored in the object pool.
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  __ LoadObject(V0, smi_object);
  __ Ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
