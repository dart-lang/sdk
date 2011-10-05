// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ic_stubs.h"

#include "vm/object.h"

namespace dart {

ICData::ICData(const Code& ic_stub) : ic_stub_(ic_stub) {
  ASSERT(!ic_stub_.IsNull());
}


intptr_t ICData::NumberOfClasses() const {
  const Array& data = Array::Handle(ic_stub_.ic_data());
  Smi& smi = Smi::Handle();
  smi ^= data.At(0);
  return smi.Value();
}


intptr_t ICData::NumberOfChecks() const {
  intptr_t number_of_classes = NumberOfClasses();
  const Array& data = Array::Handle(ic_stub_.ic_data());
  intptr_t length = data.Length();
  // First element is number of classes (N), followed by a group of elements,
  // each element consisting of N classes + 1 target.
  return (length - 1) / (number_of_classes + 1);
}


void ICData::GetCheckAt(intptr_t index,
                        GrowableArray<const Class*>* classes,
                        Function* target) const {
  ASSERT(classes != NULL);
  ASSERT(target != NULL);
  ASSERT((0 <= index) && (index < NumberOfChecks()));
  classes->Clear();
  const Array& data = Array::Handle(ic_stub_.ic_data());
  intptr_t num_classes = NumberOfClasses();
  intptr_t pos = 1 + (num_classes + 1) * index;
  for (intptr_t i = 0; i < num_classes; i++) {
    Class& cls = Class::ZoneHandle();
    cls ^= data.At(pos++);
    classes->Add(&cls);
  }
  (*target) ^= data.At(pos);
}


void ICData::SetCheckAt(intptr_t index,
                        const GrowableArray<const Class*>& classes,
                        const Function& target) {
  ASSERT((0 <= index) && (index < NumberOfChecks()));
  const Array& data = Array::Handle(ic_stub_.ic_data());
  intptr_t num_classes = NumberOfClasses();
  intptr_t pos = 1 + (num_classes + 1) * index;
  for (intptr_t i = 0; i < num_classes; i++) {
    data.SetAt(pos++, *(classes[i]));
  }
  data.SetAt(pos, target);
}


void ICData::SetICDataArray(intptr_t num_classes, intptr_t num_checks) {
  intptr_t len = 1 + (num_classes + 1) * num_checks;
  const Array& ic_data = Array::Handle(Array::New(len));
  ic_data.SetAt(0, Smi::Handle(Smi::New(num_classes)));
  ic_stub_.set_ic_data(ic_data);
}


void ICData::Print() {
  intptr_t number_of_checks = NumberOfChecks();
  GrowableArray<const Class*> temp_classes;
  Function& temp_target = Function::Handle();
  for (intptr_t i = 0; i < number_of_checks; i++) {
    GetCheckAt(i, &temp_classes, &temp_target);
    for (intptr_t k = 0; k < temp_classes.length(); k++) {
      OS::Print("  %d. %s\n", k, temp_classes[k]->ToCString());
    }
    OS::Print("=> %s\n", temp_target.ToCString());
  }
}


void ICData::ChangeTargets(const Function& from, const Function& to) {
  if (from.raw() == to.raw()) {
    return;
  }
  intptr_t n = NumberOfChecks();
  GrowableArray<const Class*> temp_classes;
  Function& temp_function = Function::Handle();
  for (int i = 0; i < n; i++) {
    GetCheckAt(i, &temp_classes, &temp_function);
    if (temp_function.raw() == from.raw()) {
      SetCheckAt(i, temp_classes, to);
    }
  }
}


void ICData::CheckIsSame(const GrowableArray<const Class*>* classes,
                         const GrowableArray<const Function*>* targets) const {
  ASSERT(NumberOfClasses() == 1);  // Test only for 1-class checks.
  intptr_t number_of_checks = NumberOfChecks();
  ASSERT((classes == NULL) || (classes->length() == number_of_checks));
  ASSERT((targets == NULL) || (targets->length() == number_of_checks));
  if (classes != NULL) {
    GrowableArray<const Class*> ic_data_classes;
    GrowableArray<const Code*> ic_data_targets;
    GrowableArray<const Class*> temp_classes;
    Function& temp_target = Function::Handle();
    for (intptr_t i = 0; i < number_of_checks; i++) {
      GetCheckAt(i, &temp_classes, &temp_target);
      ASSERT(temp_classes.length() == 1);
      const Class* cls = temp_classes[0];
      intptr_t found_at = -1;
      for (intptr_t k = 0; k < classes->length(); k++) {
        // Check that all classes exist.
        if ((*classes)[k]->raw() == cls->raw()) {
          found_at = k;
          break;
        }
      }
      ASSERT(found_at != -1);
      if ((*targets)[found_at]->raw() != temp_target.raw()) {
        UNREACHABLE();
      }
    }
  }
}

}  // namespace dart

