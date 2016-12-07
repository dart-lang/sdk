// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  getThis() => this;
}

main() {
  var a = new A();
  Expect.isTrue(a == a.getThis());
  Expect.isTrue(identical(a, a.getThis()));
}
