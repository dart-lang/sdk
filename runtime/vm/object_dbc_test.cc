// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/compiler/assembler/assembler.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
// For other architectures, this sequence does do an increment, hence the name.
// On DBC, we don't do an increment because generating an instance call here
// would be too complex.
void GenerateIncrement(Assembler* assembler) {
  __ Frame(1);
  __ LoadConstant(0, Smi::Handle(Smi::New(1)));
  __ Return(0);
}

// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  const String& string_object =
      String::ZoneHandle(String::New(str, Heap::kOld));
  __ PushConstant(string_object);
  __ ReturnTOS();
}

// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, intptr_t value) {
  const Smi& smi_object = Smi::ZoneHandle(Smi::New(value));
  __ PushConstant(smi_object);
  __ ReturnTOS();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
