// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js inference. Class9.field9b should be known to be
// potentially `null`.

import 'package:expect/expect.dart';

class Class9 {
  var field9a;
  var field9b;

  Class9() : field9a = 42 {
    field9b = field9a;
  }
}

class SubClass9a extends Class9 {
  var field9b;

  SubClass9a() : field9b = 42;

  get access => super.field9b;
}

class SubClass9b extends Class9 {}

subclassField5() {
  new Class9();
  new SubClass9b();
  return new SubClass9a().access;
}

main() {
  Expect.isTrue(subclassField5() == null);
}
