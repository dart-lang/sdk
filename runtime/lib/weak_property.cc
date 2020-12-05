// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(WeakProperty_getKey, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  return weak_property.key();
}

DEFINE_NATIVE_ENTRY(WeakProperty_setKey, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, key, arguments->NativeArgAt(1));
  weak_property.set_key(key);
  return Object::null();
}

DEFINE_NATIVE_ENTRY(WeakProperty_getValue, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  return weak_property.value();
}

DEFINE_NATIVE_ENTRY(WeakProperty_setValue, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(WeakProperty, weak_property,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(1));
  weak_property.set_value(value);
  return Object::null();
}

}  // namespace dart
