// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ic_data.h"
#include "vm/code_index_table.h"
#include "vm/unit_test.h"

namespace dart {

static RawFunction* GetDummyTarget(const char* name) {
  const String& function_name = String::Handle(String::NewSymbol(name));
  const bool is_static = false;
  const bool is_const = false;
  return Function::New(function_name,
                       RawFunction::kFunction,
                       is_static,
                       is_const,
                       0);
}


static bool SameClassArrays(const GrowableArray<const Class*>& a,
                            const GrowableArray<const Class*>& b) {
  if (a.length() != b.length()) {
    return false;
  }
  for (int i = 0; i < a.length(); i++) {
    if (a[i]->raw() != b[i]->raw()) {
      return false;
    }
  }
  return true;
}


TEST_CASE(ICDataTest) {
  const String& name = String::Handle(String::New("Luxemburgerli"));
  ICData ic_data(name, 1);
  EXPECT_EQ(1, ic_data.NumberOfArgumentsChecked());
  EXPECT_EQ(0, ic_data.NumberOfChecks());
  EXPECT_EQ(name.raw(), ic_data.FunctionName());
  GrowableArray<const Class*> classes;
  const Function& target = Function::Handle(GetDummyTarget(name.ToCString()));
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Class& smi_class = Class::ZoneHandle(object_store->smi_class());
  classes.Add(&smi_class);
  ic_data.AddCheck(classes, target);

  EXPECT_EQ(1, ic_data.NumberOfArgumentsChecked());
  EXPECT_EQ(1, ic_data.NumberOfChecks());
  EXPECT_EQ(name.raw(), ic_data.FunctionName());

  GrowableArray<const Class*> test_classes;
  Function& test_target = Function::Handle();
  ic_data.GetCheckAt(0, &test_classes, &test_target);

  EXPECT(SameClassArrays(classes, test_classes));
  EXPECT_EQ(target.raw(), test_target.raw());

  const Function& new_target =
       Function::Handle(GetDummyTarget(name.ToCString()));
  ic_data.SetCheckAt(0, classes, new_target);
  ic_data.GetCheckAt(0, &test_classes, &test_target);

  EXPECT(SameClassArrays(classes, test_classes));
  EXPECT_EQ(new_target.raw(), test_target.raw());
}

}  // namespace dart
