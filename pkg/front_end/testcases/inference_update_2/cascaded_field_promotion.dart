// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles cascades.

class C {
  final Object? _field;
  C(this._field);
}

void cascadedPropertyAccess(C c) {
  c._field as int;
  c.._field.toString();
}

void cascadedNullAwarePropertyAccess(C? c) {
  c?.._field!.toString().._field.toString();
  c?._field;
}

void cascadedInvocation(C c) {
  c._field as int Function();
  c.._field().toString();
}

main() {}
