// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(WeakProperty_new, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(1));
  const WeakProperty& weak_property = WeakProperty::Handle(WeakProperty::New());
  weak_property.set_key(key);
  weak_property.set_value(value);
  return weak_property.raw();
}

DEFINE_NATIVE_ENTRY(WeakProperty_getKey, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  return weak_property.key();
}

DEFINE_NATIVE_ENTRY(WeakProperty_getValue, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  return weak_property.value();
}

DEFINE_NATIVE_ENTRY(WeakProperty_setValue, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(1));
  weak_property.set_value(value);
  return Object::null();
}

}  // namespace dart
