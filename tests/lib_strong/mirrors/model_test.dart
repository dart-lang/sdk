// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.model_test;

import 'package:expect/expect.dart';

import 'model.dart';

isNoSuchMethodError(e) => e is NoSuchMethodError;

main() {
  var a = new A();
  var b = new B();
  var c = new C();

  Expect.isNull(a.field);
  Expect.equals('B:get field', b.field);
  Expect.equals('B:get field', c.field);

  a.field = 42;
  b.field = 87;
  c.field = 89;
  Expect.equals(42, a.field);
  Expect.equals('B:get field', b.field);
  Expect.equals('B:get field', c.field);
  Expect.equals(89, fieldC);

  Expect.equals('A:instanceMethod(7)', a.instanceMethod(7));
  Expect.equals('B:instanceMethod(9)', b.instanceMethod(9));
  Expect.equals('C:instanceMethod(13)', c.instanceMethod(13));

  Expect.equals('A:get accessor', a.accessor);
  Expect.equals('B:get accessor', b.accessor);
  Expect.equals('C:get accessor', c.accessor);

  a.accessor = 'foo';
  b.accessor = 'bar';
  c.accessor = 'baz';

  Expect.equals('foo', accessorA);
  Expect.equals('bar', accessorB);
  Expect.equals('baz', accessorC);

  Expect.equals('aMethod', a.aMethod());
  Expect.equals('aMethod', b.aMethod());
  Expect.equals('aMethod', c.aMethod());

  Expect.throws(() {
    a.bMethod();
  }, isNoSuchMethodError);
  Expect.equals('bMethod', b.bMethod());
  Expect.equals('bMethod', c.bMethod());

  Expect.throws(() {
    a.cMethod();
  }, isNoSuchMethodError);
  Expect.throws(() {
    b.cMethod();
  }, isNoSuchMethodError);
  Expect.equals('cMethod', c.cMethod());
}
