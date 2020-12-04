// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_finalizer.h"
#include "platform/assert.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static ClassPtr CreateTestClass(const char* name) {
  Thread* thread = Thread::Current();
  const String& class_name = String::Handle(Symbols::New(thread, name));
  const Script& script = Script::Handle();
  const Class& cls = Class::Handle(Class::New(
      Library::Handle(), class_name, script, TokenPosition::kNoSource));
  cls.set_interfaces(Object::empty_array());
  cls.set_is_declaration_loaded();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  cls.SetFunctions(Object::empty_array());
  cls.SetFields(Object::empty_array());
  return cls.raw();
}

ISOLATE_UNIT_TEST_CASE(ClassFinalizer) {
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

}  // namespace dart
