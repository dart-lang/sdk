// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(WeakProperty_new, 2) {
  GET_NATIVE_ARGUMENT(Instance, key, arguments->At(0));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->At(1));
  const WeakProperty& weak_property = WeakProperty::Handle(WeakProperty::New());
  weak_property.set_key(key);
  weak_property.set_value(value);
  arguments->SetReturn(weak_property);
}


DEFINE_NATIVE_ENTRY(WeakProperty_getKey, 1) {
  GET_NATIVE_ARGUMENT(WeakProperty, weak_property, arguments->At(0));
  const Object& key = Object::Handle(weak_property.key());
  arguments->SetReturn(key);
}


DEFINE_NATIVE_ENTRY(WeakProperty_getValue, 1) {
  GET_NATIVE_ARGUMENT(WeakProperty, weak_property, arguments->At(0));
  const Object& value = Object::Handle(weak_property.value());
  arguments->SetReturn(value);
}


DEFINE_NATIVE_ENTRY(WeakProperty_setValue, 2) {
  GET_NATIVE_ARGUMENT(WeakProperty, weak_property, arguments->At(0));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->At(1));
  weak_property.set_value(value);
}

}  // namespace dart
