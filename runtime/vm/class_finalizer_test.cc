// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_finalizer.h"
#include "platform/assert.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static RawClass* CreateTestClass(const char* name) {
  const String& class_name =
      String::Handle(Symbols::New(Thread::Current(), name));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  cls.set_interfaces(Object::empty_array());
  cls.SetFunctions(Object::empty_array());
  cls.SetFields(Object::empty_array());
  return cls.raw();
}

TEST_CASE(ClassFinalizer) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(zone, object_store->pending_classes());
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
  EXPECT(ClassFinalizer::ProcessPendingClasses());
  for (int i = 0; i < classes_1.length(); i++) {
    EXPECT(classes_1[i]->is_type_finalized());
  }
  for (int i = 0; i < classes_2.length(); i++) {
    EXPECT(classes_2[i]->is_type_finalized());
  }
  EXPECT(ClassFinalizer::AllClassesFinalized());
  EXPECT(ClassFinalizer::ProcessPendingClasses());
}

TEST_CASE(ClassFinalize_Cycles) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(zone, object_store->pending_classes());
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
  EXPECT(!ClassFinalizer::ProcessPendingClasses());
}

static RawLibrary* NewLib(const char* url_chars) {
  String& url = String::ZoneHandle(Symbols::New(Thread::Current(), url_chars));
  return Library::New(url);
}

TEST_CASE(ClassFinalize_Resolve) {
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  ObjectStore* object_store = isolate->object_store();
  const GrowableObjectArray& pending_classes =
      GrowableObjectArray::Handle(zone, object_store->pending_classes());
  Class& rhb = Class::Handle(CreateTestClass("RhB"));
  pending_classes.Add(rhb);
  Class& sbb = Class::Handle(CreateTestClass("SBB"));
  pending_classes.Add(sbb);
  Library& lib = Library::Handle(NewLib("TestLib"));
  lib.AddClass(rhb);
  lib.AddClass(sbb);
  const String& superclass_name = String::Handle(sbb.Name());
  const UnresolvedClass& unresolved =
      UnresolvedClass::Handle(UnresolvedClass::New(
          LibraryPrefix::Handle(), superclass_name, TokenPosition::kNoSource));
  const TypeArguments& type_arguments = TypeArguments::Handle();
  rhb.set_super_type(
      Type::Handle(Type::New(Object::Handle(unresolved.raw()), type_arguments,
                             TokenPosition::kNoSource)));
  EXPECT(ClassFinalizer::ProcessPendingClasses());
}

}  // namespace dart
