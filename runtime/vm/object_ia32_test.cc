// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(Assembler* assembler) {
  __ movl(EAX, Immediate(0));
  __ pushl(EAX);
  __ incl(Address(ESP, 0));
  __ movl(ECX, Address(ESP, 0));
  __ incl(ECX);
  __ popl(EAX);
  __ movl(EAX, ECX);
  __ ret();
}

// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ LoadObject(EAX, string_object);
  __ ret();
}

// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value) {
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  __ LoadObject(EAX, smi_object);
  __ ret();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
