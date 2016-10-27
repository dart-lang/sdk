// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  var field;

  get getField {
    return field;
  }

  set setField(value) {
    field = value;
    return null;
  }
}

main() {
  var result;
  var a = new A();

  Expect.isTrue(a.field == null);
  Expect.isTrue(a.getField == null);

  result = (a.field = 42);
  Expect.isTrue(result == 42);
  Expect.isTrue(a.field == 42);
  Expect.isTrue(a.getField == 42);

  result = (a.setField = 99);
  Expect.isTrue(result == 99);
  Expect.isTrue(a.field == 99);
  Expect.isTrue(a.getField == 99);
}
