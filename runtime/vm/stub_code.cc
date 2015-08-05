// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/assembler.h"
#include "vm/disassembler.h"
#include "vm/flags.h"
#include "vm/object_store.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, disassemble_stubs, false, "Disassemble generated stubs.");

#define STUB_CODE_DECLARE(name)                                                \
  StubEntry* StubCode::name##_entry_ = NULL;
VM_STUB_CODE_LIST(STUB_CODE_DECLARE);
#undef STUB_CODE_DECLARE


StubEntry::StubEntry(const Code& code)
    : code_(code.raw()),
      entry_point_(code.EntryPoint()),
      size_(code.Size()),
      label_(code.EntryPoint()) {
}


// Visit all object pointers.
void StubEntry::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&code_));
}


#define STUB_CODE_GENERATE(name)                                               \
  code ^= Generate("_stub_"#name, StubCode::Generate##name##Stub);             \
  name##_entry_ = new StubEntry(code);


void StubCode::InitOnce() {
  // Generate all the stubs.
  Code& code = Code::Handle();
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE);
}


#undef STUB_CODE_GENERATE


void StubCode::Init(Isolate* isolate) { }


void StubCode::VisitObjectPointers(ObjectPointerVisitor* visitor) {
}


bool StubCode::InInvocationStub(uword pc) {
  uword entry = StubCode::InvokeDartCode_entry()->EntryPoint();
  uword size = StubCode::InvokeDartCodeSize();
  return (pc >= entry) && (pc < (entry + size));
}


bool StubCode::InJumpToExceptionHandlerStub(uword pc) {
  uword entry = StubCode::JumpToExceptionHandler_entry()->EntryPoint();
  uword size = StubCode::JumpToExceptionHandlerSize();
  return (pc >= entry) && (pc < (entry + size));
}


RawCode* StubCode::GetAllocationStubForClass(const Class& cls) {
  Isolate* isolate = Isolate::Current();
  const Error& error = Error::Handle(isolate, cls.EnsureIsFinalized(isolate));
  ASSERT(error.IsNull());
  if (cls.id() == kArrayCid) {
    return AllocateArray_entry()->code();
  }
  Code& stub = Code::Handle(isolate, cls.allocation_stub());
  if (stub.IsNull()) {
    Assembler assembler;
    const char* name = cls.ToCString();
    uword patch_code_offset = 0;
    uword entry_patch_offset = 0;
    StubCode::GenerateAllocationStubForClass(
        &assembler, cls, &entry_patch_offset, &patch_code_offset);
    stub ^= Code::FinalizeCode(name, &assembler);
    stub.set_owner(cls);
    cls.set_allocation_stub(stub);
    if (FLAG_disassemble_stubs) {
      LogBlock lb(Isolate::Current());
      ISL_Print("Code for allocation stub '%s': {\n", name);
      DisassembleToStdout formatter;
      stub.Disassemble(&formatter);
      ISL_Print("}\n");
      const ObjectPool& object_pool = ObjectPool::Handle(
          Instructions::Handle(stub.instructions()).object_pool());
      object_pool.DebugPrint();
    }
    stub.set_entry_patch_pc_offset(entry_patch_offset);
    stub.set_patch_code_pc_offset(patch_code_offset);
  }
  return stub.raw();
}


const StubEntry* StubCode::UnoptimizedStaticCallEntry(
    intptr_t num_args_tested) {
  switch (num_args_tested) {
    case 0:
      return ZeroArgsUnoptimizedStaticCall_entry();
    case 1:
      return OneArgUnoptimizedStaticCall_entry();
    case 2:
      return TwoArgsUnoptimizedStaticCall_entry();
    default:
      UNIMPLEMENTED();
      return NULL;
  }
}


RawCode* StubCode::Generate(const char* name,
                            void (*GenerateStub)(Assembler* assembler)) {
  Assembler assembler;
  GenerateStub(&assembler);
  const Code& code = Code::Handle(Code::FinalizeCode(name, &assembler));
  if (FLAG_disassemble_stubs) {
    LogBlock lb(Isolate::Current());
    ISL_Print("Code for stub '%s': {\n", name);
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    ISL_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(
        Instructions::Handle(code.instructions()).object_pool());
    object_pool.DebugPrint();
  }
  return code.raw();
}


const char* StubCode::NameOfStub(uword entry_point) {
#define VM_STUB_CODE_TESTER(name)                                              \
  if ((name##_entry() != NULL) &&                                              \
      (entry_point == name##_entry()->EntryPoint())) {                         \
    return ""#name;                                                            \
  }
  VM_STUB_CODE_LIST(VM_STUB_CODE_TESTER);
#undef VM_STUB_CODE_TESTER
  return NULL;
}

}  // namespace dart
