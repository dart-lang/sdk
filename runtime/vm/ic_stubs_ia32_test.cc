// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_index_table.h"
#include "vm/ic_stubs.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {


#define __ assembler->

ASSEMBLER_TEST_GENERATE(NotAnIc, assembler) {
  __ nop();
  __ addl(EAX, Immediate(1));
  __ ret();
}

#undef __

ASSEMBLER_TEST_RUN(NotAnIc, entry) {
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  bool is_ic = ICStubs::RecognizeICStub(entry, &classes, &targets);
  EXPECT_EQ(false, is_ic);
  EXPECT_EQ(0, classes.length());
  EXPECT_EQ(0, targets.length());
}


TEST_CASE(UnresolvedIcTest) {
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  uword entry = StubCode::CallInstanceFunctionLabel().address();
  bool is_ic = ICStubs::RecognizeICStub(entry, &classes, &targets);
  EXPECT_EQ(true, is_ic);
  EXPECT_EQ(0, classes.length());
  EXPECT_EQ(0, targets.length());
}


static RawFunction* GetDummyTarget(const char* name) {
  Assembler assembler;
  assembler.ret();
  const Code& code =
      Code::Handle(Code::FinalizeCode(name, &assembler));
  const String& function_name =
      String::ZoneHandle(String::NewSymbol(name));
  const Function& function = Function::Handle(Function::New(
      function_name, RawFunction::kFunction, true, false, 0));
  function.SetCode(code);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  code_index_table->AddFunction(function);
  return function.raw();
}


TEST_CASE(SmiIcTest) {
  const Function& function = Function::Handle(GetDummyTarget("Dummy"));
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->smi_class()));
  targets.Add(&function);
  const Code& ic_stub =
      Code::Handle(ICStubs::GetICStub(classes, targets));
  ASSERT(!ic_stub.IsNull());
  classes.Clear();
  targets.Clear();
  bool is_ic = ICStubs::RecognizeICStub(
      ic_stub.EntryPoint(), &classes, &targets);
  EXPECT_EQ(true, is_ic);
  EXPECT(classes.length() == targets.length());
  EXPECT_EQ(1, classes.length());
  EXPECT(classes[0]->raw() == Isolate::Current()->object_store()->smi_class());
  EXPECT(targets[0]->raw() == function.raw());
}


TEST_CASE(NonSmiIcTest) {
  const Function& function = Function::Handle(GetDummyTarget("Dummy"));
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->array_class()));
  targets.Add(&function);
  Code& ic_stub = Code::Handle(ICStubs::GetICStub(classes, targets));
  ASSERT(!ic_stub.IsNull());
  classes.Clear();
  targets.Clear();
  bool is_ic =
      ICStubs::RecognizeICStub(ic_stub.EntryPoint(), &classes, &targets);
  EXPECT_EQ(true, is_ic);
  EXPECT(classes.length() == targets.length());
  EXPECT_EQ(1, classes.length());
  EXPECT(classes[0]->raw() ==
      Isolate::Current()->object_store()->array_class());
  EXPECT(targets[0]->raw() == function.raw());

  // Also check for always-ic-miss case (e.g. with null receiver).
  classes.Clear();
  targets.Clear();
  ic_stub = ICStubs::GetICStub(classes, targets);
  EXPECT(classes.length() == targets.length());
  EXPECT(classes.is_empty());
}

TEST_CASE(MixedIcTest) {
  const Function& function = Function::Handle(GetDummyTarget("Dummy"));
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->array_class()));
  targets.Add(&function);
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->smi_class()));
  targets.Add(&function);
  const Code& ic_stub = Code::Handle(ICStubs::GetICStub(classes, targets));
  ASSERT(!ic_stub.IsNull());
  GrowableArray<const Class*> new_classes;
  GrowableArray<const Function*> new_targets;
  bool is_ic = ICStubs::RecognizeICStub(
      ic_stub.EntryPoint(), &new_classes, &new_targets);
  EXPECT_EQ(true, is_ic);
  EXPECT(new_classes.length() == new_targets.length());
  EXPECT_EQ(2, new_classes.length());
  for (int i = 0; i < classes.length(); i++) {
    EXPECT(ICStubs::IndexOfClass(new_classes, *classes[i]) >= 0);
    EXPECT(targets[i]->raw() == function.raw());
  }
}


TEST_CASE(ManyClassesICTest) {
  const Function& function1 = Function::Handle(GetDummyTarget("Dummy1"));
  const Function& function2 = Function::Handle(GetDummyTarget("Dummy2"));
  GrowableArray<const Class*> classes;
  GrowableArray<const Function*> targets;
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->array_class()));
  targets.Add(&function1);
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->double_class()));
  targets.Add(&function1);
  classes.Add(
      &Class::ZoneHandle(Isolate::Current()->object_store()->bool_class()));
  targets.Add(&function2);
  EXPECT_EQ(3, classes.length());
  const Code& ic_stub = Code::Handle(ICStubs::GetICStub(classes, targets));
  ASSERT(!ic_stub.IsNull());
  GrowableArray<const Class*> new_classes;
  GrowableArray<const Function*> new_targets;
  bool is_ic = ICStubs::RecognizeICStub(
      ic_stub.EntryPoint(), &new_classes, &new_targets);
  EXPECT_EQ(true, is_ic);
  EXPECT(new_classes.length() == new_targets.length());
  EXPECT_EQ(3, new_classes.length());
  for (int i = 0; i < new_classes.length(); i++) {
    if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->array_class()) {
      EXPECT_EQ(function1.raw(), new_targets[i]->raw());
    } else if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->double_class()) {
      EXPECT_EQ(function1.raw(), new_targets[i]->raw());
    } else if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->bool_class()) {
      EXPECT_EQ(function2.raw(), new_targets[i]->raw());
    } else {
      UNREACHABLE();
    }
  }
  ICStubs::PatchTargets(ic_stub.EntryPoint(),
                        Code::Handle(function1.code()).EntryPoint(),
                        Code::Handle(function2.code()).EntryPoint());
  is_ic = ICStubs::RecognizeICStub(
      ic_stub.EntryPoint(), &new_classes, &new_targets);
  EXPECT_EQ(true, is_ic);
  EXPECT(new_classes.length() == new_targets.length());
  EXPECT_EQ(3, new_classes.length());
  for (int i = 0; i < new_classes.length(); i++) {
    if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->array_class()) {
      EXPECT_EQ(function2.raw(), new_targets[i]->raw());
    } else if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->double_class()) {
      EXPECT_EQ(function2.raw(), new_targets[i]->raw());
    } else if (new_classes[i]->raw() ==
        Isolate::Current()->object_store()->bool_class()) {
      EXPECT_EQ(function2.raw(), new_targets[i]->raw());
    } else {
      UNREACHABLE();
    }
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
