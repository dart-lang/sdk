// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(compiler::Assembler* assembler) {
  __ movq(RAX, compiler::Immediate(0));
  __ pushq(RAX);
  __ incq(compiler::Address(RSP, 0));
  __ movq(RCX, compiler::Address(RSP, 0));
  __ incq(RCX);
  __ popq(RAX);
  __ movq(RAX, RCX);
  __ ret();
}

// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(compiler::Assembler* assembler,
                               const char* str) {
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ EnterStubFrame();
  __ LoadObject(RAX, string_object);
  __ LeaveStubFrame();
  __ ret();
}

// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(compiler::Assembler* assembler, intptr_t value) {
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  __ movq(RAX,
          compiler::Immediate(reinterpret_cast<int64_t>(smi_object.raw())));
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
