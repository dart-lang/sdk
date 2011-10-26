// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ic_data.h"
#include "vm/object.h"

namespace dart {

// ICData is a ValueObject, therefore 'data' need not be a ZoneObject.
ICData::ICData(const Array& data) : data_(&data) {
  // Check consistency.
  ASSERT(data_->IsNull() || !String::Handle(FunctionName()).IsNull());
  ASSERT(data_->IsNull() || (NumberOfArgumentsChecked() > 0));
}


ICData::ICData(const String& function_name, intptr_t num_args_checked)
    : data_(NULL) {
  // Array contains: function-name, num_checked, NULL check sentinel (classes,
  // target).
  const intptr_t len = kChecksStartIndex + (num_args_checked + 1);
  data_ = &Array::ZoneHandle(Array::New(len, Heap::kOld));
  data_->SetAt(kNameIndex, function_name);
  data_->SetAt(kNumArgsCheckedIndex, Smi::Handle(Smi::New(num_args_checked)));
}


RawArray* ICData::data() const {
  return data_->raw();
}


void ICData::set_data(const Array& value) {
  data_ = &value;
  // Check consistency.
  ASSERT(data_->IsNull() || !String::Handle(FunctionName()).IsNull());
  ASSERT(data_->IsNull() || (NumberOfArgumentsChecked() > 0));
}


intptr_t ICData::ArrayElementsPerCheck() const {
  // Number of checked classes + target.
  return NumberOfArgumentsChecked() + 1;
}


intptr_t ICData::NumberOfArgumentsChecked() const {
  if (data_->IsNull()) return 0;
  Smi& result = Smi::Handle();
  result ^= data_->At(kNumArgsCheckedIndex);
  return result.Value();
}


intptr_t ICData::NumberOfChecks() const {
  if (data_->IsNull()) return 0;
  const intptr_t per_check = ArrayElementsPerCheck();
  // Subtract function-name, num-checked and sentinel
  intptr_t len = data_->Length() - kChecksStartIndex - per_check;
  ASSERT(len % per_check == 0);
  return len / per_check;
}


RawString* ICData::FunctionName() const {
  if (data_->IsNull()) return String::null();
  String& result = String::Handle();
  result ^= data_->At(kNameIndex);
  return result.raw();
}


void ICData::AddCheck(const GrowableArray<const Class*>& classes,
                      const Function& target) {
  ASSERT(!data_->IsNull());
  intptr_t old_number_of_checks = NumberOfChecks();
  intptr_t new_len = data_->Length() + ArrayElementsPerCheck();
  data_ = &Array::ZoneHandle(Array::Grow(*data_, new_len, Heap::kOld));
  SetCheckAt(old_number_of_checks, classes, target);
}


void ICData::SetCheckAt(intptr_t index,
                        const GrowableArray<const Class*>& classes,
                        const Function& target) {
  ASSERT(!data_->IsNull());
  ASSERT((0 <= index) && (index < NumberOfChecks()));
  intptr_t pos = kChecksStartIndex + ArrayElementsPerCheck() * index;
  ASSERT(classes.length() == NumberOfArgumentsChecked());
  for (intptr_t i = 0; i < classes.length(); i++) {
    // Null is used as terminating object, do not add it.
    ASSERT(!classes[i]->IsNull());
    // Contract says that the class of null (NullClass) cannot be added.
    ASSERT(!classes[i]->IsNullClass());
    data_->SetAt(pos++, *(classes[i]));
  }
  ASSERT(!target.IsNull());
  data_->SetAt(pos, target);
}


void ICData::GetCheckAt(intptr_t index,
                        GrowableArray<const Class*>* classes,
                        Function* target) const {
  ASSERT(classes != NULL);
  ASSERT(target != NULL);
  ASSERT((0 <= index) && (index < NumberOfChecks()));
  classes->Clear();
  intptr_t pos = 1 + 1 + ArrayElementsPerCheck() * index;
  for (intptr_t i = 0; i < NumberOfArgumentsChecked(); i++) {
    Class& cls = Class::ZoneHandle();
    cls ^= data_->At(pos++);
    classes->Add(&cls);
  }
  (*target) ^= data_->At(pos);
}

}  // namespace dart
