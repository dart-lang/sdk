// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js inference. Class.field6b should be known to be
// potentially `null`.

import 'package:expect/expect.dart';

class Class6 {
  var field6a;
  var field6b;

  Class6() : field6a = 42 {
    field6b = field6a;
  }
}

class SubClass6 extends Class6 {
  var field6b;

  SubClass6() : field6b = 42;

  get access => super.field6b;
}

subclassField2() {
  new Class6();
  return new SubClass6().access;
}

main() {
  Expect.isTrue(subclassField2() == null);
}
