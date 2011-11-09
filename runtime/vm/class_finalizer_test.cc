// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/class_finalizer.h"
#include "vm/unit_test.h"

namespace dart {


static RawClass* CreateTestClass(const char* name) {
  const Array& empty_array = Array::Handle(Array::Empty());
  const String& class_name = String::Handle(String::NewSymbol(name));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(Class::New(class_name, script));
  cls.set_interfaces(empty_array);
  cls.SetFunctions(empty_array);
  cls.SetFields(empty_array);
  return cls.raw();
}


TEST_CASE(ClassFinalizer) {
  ClassFinalizer::ExpectClassesToFinalize();
  GrowableArray<const Class*> classes_1;
  classes_1.Add(&Class::ZoneHandle(CreateTestClass("BMW")));
  classes_1.Add(&Class::ZoneHandle(CreateTestClass("Porsche")));
  ClassFinalizer::AddClassesToFinalize(classes_1);
  GrowableArray<const Class*> classes_2;
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Ferrari")));
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Fiat")));
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Alfa")));
  ClassFinalizer::AddClassesToFinalize(classes_2);
  EXPECT(ClassFinalizer::FinalizeAllClasses());
  for (int i = 0; i < classes_1.length(); i++) {
    EXPECT(classes_1[i]->is_finalized());
  }
  for (int i = 0; i < classes_2.length(); i++) {
    EXPECT(classes_2[i]->is_finalized());
  }
  EXPECT(ClassFinalizer::FinalizeAllClasses());
}


TEST_CASE(ClassFinalize_Cycles) {
  ClassFinalizer::ExpectClassesToFinalize();
  GrowableArray<const Class*> classes;
  classes.Add(&Class::ZoneHandle(CreateTestClass("Jungfrau")));
  classes.Add(&Class::ZoneHandle(CreateTestClass("Eiger")));
  // Create a cycle.
  classes[0]->set_super_type(
      Type::Handle(Type::NewNonParameterizedType(*classes[1])));
  classes[1]->set_super_type(
      Type::Handle(Type::NewNonParameterizedType(*classes[0])));
  ClassFinalizer::AddClassesToFinalize(classes);
  EXPECT(!ClassFinalizer::FinalizeAllClasses());
}


static RawLibrary* NewLib(const char* url_chars) {
  String& url = String::ZoneHandle(String::NewSymbol(url_chars));
  return Library::New(url);
}


TEST_CASE(ClassFinalize_Resolve) {
  ClassFinalizer::ExpectClassesToFinalize();
  GrowableArray<const Class*> classes;
  Class& rhb = Class::ZoneHandle(CreateTestClass("RhB"));
  Class& sbb = Class::ZoneHandle(CreateTestClass("SBB"));
  Library& lib = Library::Handle(NewLib("TestLib"));
  classes.Add(&rhb);
  classes.Add(&sbb);
  lib.AddClass(rhb);
  lib.AddClass(sbb);
  const String& superclass_name = String::Handle(sbb.Name());
  const UnresolvedClass& unresolved = UnresolvedClass::Handle(
      UnresolvedClass::New(0, String::Handle(), superclass_name));
  TypeArguments& type_arguments = TypeArguments::Handle();
  rhb.set_super_type(Type::Handle(Type::NewParameterizedType(
      Object::Handle(unresolved.raw()), type_arguments)));
  ClassFinalizer::AddClassesToFinalize(classes);
  EXPECT(ClassFinalizer::FinalizeAllClasses());
}

}  // namespace dart
