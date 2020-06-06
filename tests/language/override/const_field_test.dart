// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

import 'package:expect/expect.dart';

class A {
  final field;
  const A(this.field);
}

class B extends A {
  final field;
  const B(this.field, fieldA) : super(fieldA);
  get fieldA => super.field;
}

main() {
  const b = B(1, 2);
  Expect.equals(1, b.field);
  Expect.equals(2, b.fieldA);
}
