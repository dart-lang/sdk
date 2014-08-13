// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/cha.h"
#include "vm/class_finalizer.h"
#include "vm/globals.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(ClassHierarchyAnalysis) {
  const char* kScriptChars =
      "class A {"
      "  foo() { }"
      "  bar() { }"
      "}\n"
      "class B extends A {"
      "}\n"
      "class C extends B {"
      "  foo() { }"
      "}\n"
      "class D extends A {"
      "  foo() { }"
      "  bar() { }"
      "}\n";

  TestCase::LoadTestScript(kScriptChars, NULL);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(name));
  EXPECT(!lib.IsNull());

  const Class& class_a = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("A"))));
  EXPECT(!class_a.IsNull());
  const intptr_t class_a_id = class_a.id();

  const Class& class_b = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("B"))));
  EXPECT(!class_b.IsNull());
  const intptr_t class_b_id = class_b.id();

  const Class& class_c = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("C"))));
  EXPECT(!class_c.IsNull());
  const intptr_t class_c_id = class_c.id();

  const Class& class_d = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("D"))));
  EXPECT(!class_d.IsNull());
  const intptr_t class_d_id = class_d.id();

  const String& function_foo_name = String::Handle(String::New("foo"));
  const String& function_bar_name = String::Handle(String::New("bar"));

  const Function& class_a_foo =
      Function::Handle(class_a.LookupDynamicFunction(function_foo_name));
  EXPECT(!class_a_foo.IsNull());

  const Function& class_a_bar =
      Function::Handle(class_a.LookupDynamicFunction(function_bar_name));
  EXPECT(!class_a_bar.IsNull());

  const Function& class_c_foo =
      Function::Handle(class_c.LookupDynamicFunction(function_foo_name));
  EXPECT(!class_c_foo.IsNull());

  const Function& class_d_foo =
      Function::Handle(class_d.LookupDynamicFunction(function_foo_name));
  EXPECT(!class_d_foo.IsNull());

  const Function& class_d_bar =
      Function::Handle(class_d.LookupDynamicFunction(function_bar_name));
  EXPECT(!class_d_bar.IsNull());

  ZoneGrowableArray<intptr_t>* a_subclass_ids =
      CHA::GetSubclassIdsOf(class_a_id);
  EXPECT_EQ(3, a_subclass_ids->length());
  EXPECT_EQ(class_b_id, (*a_subclass_ids)[0]);
  EXPECT_EQ(class_c_id, (*a_subclass_ids)[1]);
  EXPECT_EQ(class_d_id, (*a_subclass_ids)[2]);
  ZoneGrowableArray<intptr_t>* b_subclass_ids =
      CHA::GetSubclassIdsOf(class_b_id);
  EXPECT_EQ(1, b_subclass_ids->length());
  EXPECT_EQ(class_c_id, (*b_subclass_ids)[0]);
  ZoneGrowableArray<intptr_t>* c_subclass_ids =
      CHA::GetSubclassIdsOf(class_c_id);
  EXPECT_EQ(0, c_subclass_ids->length());
  ZoneGrowableArray<intptr_t>* d_subclass_ids =
      CHA::GetSubclassIdsOf(class_d_id);
  EXPECT_EQ(0, d_subclass_ids->length());

  ZoneGrowableArray<Function*>* foos =
      CHA::GetNamedInstanceFunctionsOf(*a_subclass_ids, function_foo_name);
  EXPECT_EQ(2, foos->length());
  EXPECT_EQ(class_c_foo.raw(), (*foos)[0]->raw());
  EXPECT_EQ(class_d_foo.raw(), (*foos)[1]->raw());

  ZoneGrowableArray<Function*>* class_a_foo_overrides =
      CHA::GetOverridesOf(class_a_foo);
  EXPECT_EQ(2, class_a_foo_overrides->length());
  EXPECT_EQ(class_c_foo.raw(), (*class_a_foo_overrides)[0]->raw());
  EXPECT_EQ(class_d_foo.raw(), (*class_a_foo_overrides)[1]->raw());

  ZoneGrowableArray<Function*>* bars =
      CHA::GetNamedInstanceFunctionsOf(*a_subclass_ids, function_bar_name);
  EXPECT_EQ(1, bars->length());
  EXPECT_EQ(class_d_bar.raw(), (*bars)[0]->raw());

  ZoneGrowableArray<Function*>* class_a_bar_overrides =
      CHA::GetOverridesOf(class_a_bar);
  EXPECT_EQ(1, class_a_bar_overrides->length());
  EXPECT_EQ(class_d_bar.raw(), (*class_a_bar_overrides)[0]->raw());

  EXPECT(CHA::HasSubclasses(kInstanceCid));
  EXPECT(!CHA::HasSubclasses(kSmiCid));
  EXPECT(!CHA::HasSubclasses(kNullCid));
  EXPECT(!CHA::HasSubclasses(kDynamicCid));
  EXPECT(!CHA::HasSubclasses(kVoidCid));
  EXPECT(CHA::HasSubclasses(class_a_id));
  EXPECT(CHA::HasSubclasses(class_b_id));
  EXPECT(!CHA::HasSubclasses(class_c_id));
  EXPECT(!CHA::HasSubclasses(class_d_id));

  class Class& function_impl_class =
      Class::Handle(Type::Handle(Isolate::Current()->object_store()->
          function_impl_type()).type_class());
  EXPECT(CHA::HasSubclasses(function_impl_class.id()));
}

}  // namespace dart
