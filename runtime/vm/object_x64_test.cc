// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/assert.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->


// Generate a simple dart code sequence.
// This is used to test Code and Instruction object creation.
void GenerateIncrement(Assembler* assembler) {
  __ Unimplemented("GenerateIncrement");
}


// Generate a dart code sequence that embeds a string object in it.
// This is used to test Embedded String objects in the instructions.
void GenerateEmbedStringInCode(Assembler* assembler, const char* str) {
  __ Unimplemented("GenerateEmbedStringInCode");
}


// Generate a dart code sequence that embeds a smi object in it.
// This is used to test Embedded Smi objects in the instructions.
void GenerateEmbedSmiInCode(Assembler* assembler, int value) {
  __ Unimplemented("GenerateEmbedSmiInCode");
}


// Generate code for a simple static dart function that returns 42.
// This is used to test invocation of dart functions from C++.
void GenerateReturn42(Assembler* assembler) {
  __ Unimplemented("GenerateReturn42");
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
