// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {


static RawClass* CreateTestClass(const char* name) {
  const Array& empty_array = Array::Handle(Object::empty_array());
  const String& class_name = String::Handle(Symbols::New(name));
  const Script& script = Script::Handle();
  const Class& cls =
      Class::Handle(Class::New(class_name, script, Scanner::kDummyTokenIndex));
  cls.set_interfaces(empty_array);
  cls.SetFunctions(empty_array);
  cls.SetFields(empty_array);
  return cls.raw();
}


TEST_CASE(ClassFinalizer) {
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(isolate, object_store->pending_classes());
  GrowableArray<const Class*> classes_1;
  classes_1.Add(&Class::Handle(CreateTestClass("BMW")));
  pending_classes.Add(*classes_1[0]);
  classes_1.Add(&Class::Handle(CreateTestClass("Porsche")));
  pending_classes.Add(*classes_1[1]);

  GrowableArray<const Class*> classes_2;
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Ferrari")));
  pending_classes.Add(*classes_2[0]);
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Fiat")));
  pending_classes.Add(*classes_2[1]);
  classes_2.Add(&Class::ZoneHandle(CreateTestClass("Alfa")));
  pending_classes.Add(*classes_2[2]);
  EXPECT(ClassFinalizer::FinalizePendingClasses());
  for (int i = 0; i < classes_1.length(); i++) {
    EXPECT(classes_1[i]->is_finalized());
  }
  for (int i = 0; i < classes_2.length(); i++) {
    EXPECT(classes_2[i]->is_finalized());
  }
  EXPECT(ClassFinalizer::FinalizePendingClasses());
}


TEST_CASE(ClassFinalize_Cycles) {
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(isolate, object_store->pending_classes());
  GrowableArray<const Class*> classes;
  classes.Add(&Class::Handle(CreateTestClass("Jungfrau")));
  pending_classes.Add(*classes[0]);
  classes.Add(&Class::Handle(CreateTestClass("Eiger")));
  pending_classes.Add(*classes[1]);
  // Create a cycle.
  classes[0]->set_super_type(
      Type::Handle(Type::NewNonParameterizedType(*classes[1])));
  classes[1]->set_super_type(
      Type::Handle(Type::NewNonParameterizedType(*classes[0])));
  EXPECT(!ClassFinalizer::FinalizePendingClasses());
}


static RawLibrary* NewLib(const char* url_chars) {
  String& url = String::ZoneHandle(Symbols::New(url_chars));
  return Library::New(url);
}


TEST_CASE(ClassFinalize_Resolve) {
  Isolate* isolate = Isolate::Current();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(isolate, object_store->pending_classes());
  Class& rhb = Class::Handle(CreateTestClass("RhB"));
  pending_classes.Add(rhb);
  Class& sbb = Class::Handle(CreateTestClass("SBB"));
  pending_classes.Add(sbb);
  Library& lib = Library::Handle(NewLib("TestLib"));
  lib.AddClass(rhb);
  lib.AddClass(sbb);
  const String& superclass_name = String::Handle(sbb.Name());
  const UnresolvedClass& unresolved = UnresolvedClass::Handle(
      UnresolvedClass::New(LibraryPrefix::Handle(),
                           superclass_name,
                           Scanner::kDummyTokenIndex));
  const TypeArguments& type_arguments = TypeArguments::Handle();
  rhb.set_super_type(Type::Handle(
      Type::New(Object::Handle(unresolved.raw()),
                type_arguments,
                Scanner::kDummyTokenIndex)));
  EXPECT(ClassFinalizer::FinalizePendingClasses());
}

}  // namespace dart
