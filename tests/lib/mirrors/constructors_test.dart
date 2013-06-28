// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructors_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'stringify.dart';

class Foo {
}

class Bar {
  Bar();
}

class Baz {
  Baz.named();
}

class Biz {
  Biz();
  Biz.named();
}

main() {
  MirrorSystem mirrors = currentMirrorSystem();
  ClassMirror fooMirror = reflectClass(Foo);
  Map<Symbol, MethodMirror> fooConstructors = fooMirror.constructors;
  ClassMirror barMirror = reflectClass(Bar);
  Map<Symbol, MethodMirror> barConstructors = barMirror.constructors;
  ClassMirror bazMirror = reflectClass(Baz);
  Map<Symbol, MethodMirror> bazConstructors = bazMirror.constructors;
  ClassMirror bizMirror = reflectClass(Biz);
  Map<Symbol, MethodMirror> bizConstructors = bizMirror.constructors;

  expect('{Foo: Method(s(Foo) in s(Foo), constructor)}', fooConstructors);
  expect('{Bar: Method(s(Bar) in s(Bar), constructor)}', barConstructors);
  expect('{Baz.named: Method(s(Baz.named) in s(Baz), constructor)}',
         bazConstructors);
  expect('{Biz: Method(s(Biz) in s(Biz), constructor),'
         ' Biz.named: Method(s(Biz.named) in s(Biz), constructor)}',
         bizConstructors);
  print(bizConstructors);

  expect('[]', fooConstructors.values.single.parameters);
  expect('[]', barConstructors.values.single.parameters);
  expect('[]', bazConstructors.values.single.parameters);
  for (var constructor in bizConstructors.values) {
    expect('[]', constructor.parameters);
  }

  expect('[s()]',
         fooConstructors.values.map((m) => m.constructorName).toList());
  expect('[s()]',
         barConstructors.values.map((m) => m.constructorName).toList());
  expect('[s(named)]',
         bazConstructors.values.map((m) => m.constructorName).toList());
  expect('[s(), s(named)]',
         bizConstructors.values.map((m) => m.constructorName).toList()
             ..sort(compareSymbols));
}
