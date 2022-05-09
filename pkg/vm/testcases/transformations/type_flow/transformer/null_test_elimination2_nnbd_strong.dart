// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of null test in a conditional expression of
// a different static type.

bool _defaultCheck([dynamic _]) => true;

void testStaticTypeOfConditional<T>(bool Function(T error)? check, Object e) {
  // Verify that null test elimination leaves unsafeCast here to
  // keep static type of 'check ?? _defaultCheck' expression.
  if (e is T && (check ?? _defaultCheck)(e)) {
    print('ok');
  }
}

void main() {
  testStaticTypeOfConditional<String>((_) => true, 'hi');
}
