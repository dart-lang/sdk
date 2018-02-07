// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that we prepare type variables for inlined super constructor calls.

import 'package:expect/expect.dart';

class A<T> {}

class SuperSuperClass<T> {
  var field;

  SuperSuperClass(this.field);

  m1() => field is A<int>;
  m2() => field is A<String>;
}

class SuperClass<T> extends SuperSuperClass<T> {
  SuperClass() : super(new A<T>());
}

class Class extends SuperClass<int> {}

@NoInline()
createClass() => new Class();

main() {
  var c = createClass();
  Expect.isTrue(c.m1());
  Expect.isFalse(c.m2());
}
