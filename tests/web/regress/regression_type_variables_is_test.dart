// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Bar<X> implements Baz {}

class Baz {}

var g;

abstract class Foo<A extends Baz> {
  final bool thing = g is A;
}

class Qux extends Foo<Baz> {}

main() {
  g = new Baz();
  var f = new Qux();
  Expect.isTrue(f.thing);
  g = 'ello';
  var f2 = new Qux();
  Expect.isFalse(f2.thing);
}
