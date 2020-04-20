// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var calls = <String>[];

abstract class A {
  bool _done = true;
  var a = calls.add('A()') as dynamic;
}

abstract class B {
  B.protected() {
    calls.add('B.protected()');
  }
}

class C extends B with A {
  C() : super.protected() {
    calls.add('C()');
  }
}

void main() {
  var c = new C();
  Expect.isTrue(c._done);
  Expect.equals(calls.join(', '), 'A(), B.protected(), C()');
}
