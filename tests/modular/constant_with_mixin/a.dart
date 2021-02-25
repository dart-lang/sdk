// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  const A({
    this.d = 3.14,
    this.s = 'default',
  });

  final double d;
  final String s;
}

class B extends A with M {
  const B({double d = 2.71}) : super(d: d);
}

mixin M on A {
  m1() {}
}

const sameModule = B();
