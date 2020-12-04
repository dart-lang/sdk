// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/cha.h"
#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/globals.h"
#include "vm/resolver.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#define Z (thread->zone())

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

  TransitionNativeToVM transition(thread);
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  const String& name = String::Handle(String::New(TestCase::url()));
  const Library& lib = Library::Handle(Library::LookupLibrary(thread, name));
  EXPECT(!lib.IsNull());

  const Class& class_a =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "A"))));
  EXPECT(!class_a.IsNull());
  EXPECT(class_a.EnsureIsFinalized(thread) == Error::null());

  const Class& class_b =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "B"))));
  EXPECT(!class_b.IsNull());

  const Class& class_c =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "C"))));
  EXPECT(!class_c.IsNull());
  EXPECT(class_c.EnsureIsFinalized(thread) == Error::null());

  const Class& class_d =
      Class::Handle(lib.LookupClass(String::Handle(Symbols::New(thread, "D"))));
  EXPECT(!class_d.IsNull());
  EXPECT(class_d.EnsureIsFinalized(thread) == Error::null());

  const String& function_foo_name = String::Handle(String::New("foo"));
  const String& function_bar_name = String::Handle(String::New("bar"));

  const Function& class_a_foo = Function::Handle(
      Resolver::ResolveDynamicFunction(Z, class_a, function_foo_name));
  EXPECT(!class_a_foo.IsNull());

  const Function& class_a_bar = Function::Handle(
      Resolver::ResolveDynamicFunction(Z, class_a, function_bar_name));
  EXPECT(!class_a_bar.IsNull());

  const Function& class_c_foo = Function::Handle(
      Resolver::ResolveDynamicFunction(Z, class_c, function_foo_name));
  EXPECT(!class_c_foo.IsNull());

  const Function& class_d_foo = Function::Handle(
      Resolver::ResolveDynamicFunction(Z, class_d, function_foo_name));
  EXPECT(!class_d_foo.IsNull());

  const Function& class_d_bar = Function::Handle(
      Resolver::ResolveDynamicFunction(Z, class_d, function_bar_name));
  EXPECT(!class_d_bar.IsNull());

  CHA cha(thread);

  EXPECT(cha.HasSubclasses(kInstanceCid));
  EXPECT(!cha.HasSubclasses(kSmiCid));
  EXPECT(!cha.HasSubclasses(kNullCid));

  EXPECT(CHA::HasSubclasses(class_a));
  EXPECT(CHA::HasSubclasses(class_b));
  EXPECT(!CHA::HasSubclasses(class_c));
  cha.AddToGuardedClasses(class_c, /*subclass_count=*/0);
  EXPECT(!CHA::HasSubclasses(class_d));
  cha.AddToGuardedClasses(class_d, /*subclass_count=*/0);

  EXPECT(!cha.IsGuardedClass(class_a.id()));
  EXPECT(!cha.IsGuardedClass(class_b.id()));
  EXPECT(cha.IsGuardedClass(class_c.id()));
  EXPECT(cha.IsGuardedClass(class_d.id()));

  const Class& closure_class =
      Class::Handle(Isolate::Current()->object_store()->closure_class());
  EXPECT(!cha.HasSubclasses(closure_class.id()));
}

}  // namespace dart
