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

static bool ContainsCid(const GrowableArray<Class*>& classes, intptr_t cid) {
  for (intptr_t i = 0; i < classes.length(); ++i) {
    if (classes[i]->id() == cid) return true;
  }
  return false;
}


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

  const Class& class_b = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("B"))));
  EXPECT(!class_b.IsNull());

  const Class& class_c = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("C"))));
  EXPECT(!class_c.IsNull());

  const Class& class_d = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New("D"))));
  EXPECT(!class_d.IsNull());

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

  CHA cha(Isolate::Current());

  EXPECT(cha.HasSubclasses(kInstanceCid));
  EXPECT(!cha.HasSubclasses(kSmiCid));
  EXPECT(!cha.HasSubclasses(kNullCid));

  EXPECT(cha.HasSubclasses(class_a));
  EXPECT(cha.HasSubclasses(class_b));
  EXPECT(!cha.HasSubclasses(class_c));
  EXPECT(!cha.HasSubclasses(class_d));

  EXPECT(!ContainsCid(cha.leaf_classes(), class_a.id()));
  EXPECT(!ContainsCid(cha.leaf_classes(), class_b.id()));
  EXPECT(ContainsCid(cha.leaf_classes(), class_c.id()));
  EXPECT(ContainsCid(cha.leaf_classes(), class_d.id()));

  const Class& function_impl_class =
      Class::Handle(Type::Handle(Isolate::Current()->object_store()->
          function_impl_type()).type_class());
  EXPECT(cha.HasSubclasses(function_impl_class.id()));
}

}  // namespace dart
