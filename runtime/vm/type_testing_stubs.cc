// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/type_testing_stubs.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"

#define __ assembler->

namespace dart {

DECLARE_FLAG(bool, disassemble_stubs);

RawInstructions* TypeTestingStubGenerator::DefaultCodeForType(
    const AbstractType& type) {
  // During bootstrapping we have no access to stubs yet, so we'll just return
  // `null` and patch these later in `Object::FinishInitOnce()`.
  if (!StubCode::HasBeenInitialized()) {
    ASSERT(type.IsType());
    const intptr_t cid = Type::Cast(type).type_class_id();
    ASSERT(cid == kDynamicCid || cid == kVoidCid || cid == kVectorCid);
    return Instructions::null();
  }

  if (type.IsType() || type.IsTypeParameter() || type.IsTypeRef()) {
    return Code::InstructionsOf(StubCode::DefaultTypeTest_entry()->code());
  } else {
    ASSERT(type.IsBoundedType() || type.IsMixinAppType());
    return Code::InstructionsOf(StubCode::UnreachableTypeTest_entry()->code());
  }
}

TypeTestingStubFinder::TypeTestingStubFinder() : code_(Code::Handle()) {}

RawInstructions* TypeTestingStubFinder::LookupByAddresss(
    uword entry_point) const {
  code_ = StubCode::DefaultTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }
  code_ = StubCode::UnreachableTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return code_.instructions();
  }

  UNREACHABLE();
  return NULL;
}

const char* TypeTestingStubFinder::StubNameFromAddresss(
    uword entry_point) const {
  // First test the 2 common ones:
  code_ = StubCode::DefaultTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return "TypeTestingStub_Default";
  }
  code_ = StubCode::UnreachableTypeTest_entry()->code();
  if (entry_point == code_.UncheckedEntryPoint()) {
    return "TypeTestingStub_Unreachable";
  }

  UNREACHABLE();
  return NULL;
}

#undef __

}  // namespace dart
