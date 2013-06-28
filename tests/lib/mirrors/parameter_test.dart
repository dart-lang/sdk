// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of [ParameterMirror].
library test.parameter_test;

@MirrorsUsed(targets: 'test.parameter_test', override: '*')
import 'dart:mirrors';

import 'stringify.dart';

class B {
  B();
  B.foo(int x);
  B.bar(int z, x);
}

main() {
  var constructors = reflectClass(B).constructors;

  expect('{B: Method(s(B) in s(B), constructor), '
         'B.bar: Method(s(B.bar) in s(B), constructor), '
         'B.foo: Method(s(B.foo) in s(B), constructor)}',
         constructors);

  var unnamedConstructor = constructors[new Symbol('B')];

  expect('[]', unnamedConstructor.parameters);
  expect('Type(s(B) in s(test.parameter_test), top-level)',
         unnamedConstructor.returnType);

  var fooConstructor = constructors[new Symbol('B.foo')];
  expect('[Parameter(s(x) in s(B.foo),'
         ' type = Type(s(int) in s(dart.core), top-level))]',
         fooConstructor.parameters);
  expect('Type(s(B) in s(test.parameter_test), top-level)',
         fooConstructor.returnType);

  var barConstructor = constructors[new Symbol('B.bar')];
  expect('[Parameter(s(z) in s(B.bar),'
         ' type = Type(s(int) in s(dart.core), top-level)), '
         'Parameter(s(x) in s(B.bar),'
         ' type = Type(s(dynamic), top-level))]',
         barConstructor.parameters);
  expect('Type(s(B) in s(test.parameter_test), top-level)',
         barConstructor.returnType);

  print(constructors);
}
