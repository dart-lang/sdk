// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing redefinition of reserved names as static const fields.
// Bug #587.

import "package:expect/expect.dart";

class Field {
  static const name = 'Foo';
}

class StaticConstFieldReservedNameTest {
  static testMain() {
    Expect.equals('Foo', Field.name);
  }
}

void main() {
  StaticConstFieldReservedNameTest.testMain();
}
