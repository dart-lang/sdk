// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' show Pointer, Struct, Union;

void checkValidWeakTarget(object, name) {
  if ((object == null) ||
      (object is bool) ||
      (object is num) ||
      (object is String) ||
      (object is Record) ||
      (object is Pointer) ||
      (object is Struct) ||
      (object is Union)) {
    throw ArgumentError.value(
      object,
      name,
      "Cannot be a string, number, boolean, record, null, Pointer, Struct or Union",
    );
  }
}
