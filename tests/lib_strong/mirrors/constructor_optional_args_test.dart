// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructor_test;

@MirrorsUsed(targets: const [A])
import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  factory A([x, y]) = B;
  factory A.more([x, y]) = B.more;
  factory A.oneMore(x, [y]) = B.more;
}

class B implements A {
  final _x, _y, _z;

  B([x = 'x', y = 'y'])
      : _x = x,
        _y = y,
        _z = null;

  B.more([x = 'x', y = 'y', z = 'z'])
      : _x = x,
        _y = y,
        _z = z;

  toString() => 'B(x=$_x, y=$_y, z=$_z)';
}

main() {
  var d1 = new A(1);
  Expect.equals('B(x=1, y=y, z=null)', '$d1', 'direct 1');

  var d2 = new A.more(1);
  Expect.equals('B(x=1, y=y, z=z)', '$d2', 'direct 2');

  ClassMirror cm = reflectClass(A);

  var v1 = cm.newInstance(const Symbol(''), []).reflectee;
  var v2 = cm.newInstance(const Symbol(''), [1]).reflectee;
  var v3 = cm.newInstance(const Symbol(''), [2, 3]).reflectee;

  Expect.equals('B(x=x, y=y, z=null)', '$v1', 'unnamed 1');
  Expect.equals('B(x=1, y=y, z=null)', '$v2', 'unnamed 2');
  Expect.equals('B(x=2, y=3, z=null)', '$v3', 'unnamed 3');

  var m1 = cm.newInstance(const Symbol('more'), []).reflectee;
  var m2 = cm.newInstance(const Symbol('more'), [1]).reflectee;
  var m3 = cm.newInstance(const Symbol('more'), [2, 3]).reflectee;

  Expect.equals('B(x=x, y=y, z=z)', '$m1', 'more 1');
  Expect.equals('B(x=1, y=y, z=z)', '$m2', 'more 2');
  Expect.equals('B(x=2, y=3, z=z)', '$m3', 'more 3');

  var o1 = cm.newInstance(const Symbol('oneMore'), [1]).reflectee;
  var o2 = cm.newInstance(const Symbol('oneMore'), [2, 3]).reflectee;

  Expect.equals('B(x=1, y=y, z=z)', '$o1', 'oneMore one arg');
  Expect.equals('B(x=2, y=3, z=z)', '$o2', 'oneMore two args');
}
