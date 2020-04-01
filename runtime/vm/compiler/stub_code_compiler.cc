// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/stub_code_compiler.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"

#define __ assembler->

namespace dart {

namespace compiler {

void StubCodeCompiler::GenerateInitStaticFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(InitStaticFieldABI::kFieldReg);
  __ CallRuntime(kInitStaticFieldRuntimeEntry, /*argument_count=*/1);
  __ Drop(2);
  __ LeaveStubFrame();
  __ Ret();
}

void StubCodeCompiler::GenerateInitInstanceFieldStub(Assembler* assembler) {
  __ EnterStubFrame();
  __ PushObject(NullObject());  // Make room for (unused) result.
  __ PushRegister(InitInstanceFieldABI::kInstanceReg);
  __ PushRegister(InitInstanceFieldABI::kFieldReg);
  __ CallRuntime(kInitInstanceFieldRuntimeEntry, /*argument_count=*/2);
  __ Drop(3);
  __ LeaveStubFrame();
  __ Ret();
}

}  // namespace compiler

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
