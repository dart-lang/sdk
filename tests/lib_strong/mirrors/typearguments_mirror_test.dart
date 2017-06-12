// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

import 'package:expect/expect.dart';
import 'stringify.dart';
import 'dart:mirrors';

class Foo<T> {}

class Bar<T, R> {}

main() {
  var cm = reflectClass(Foo);
  var cm1 = reflect((new Foo<String>())).type;

  Expect.notEquals(cm, cm1);
  Expect.isFalse(cm1.isOriginalDeclaration);
  Expect.isTrue(cm.isOriginalDeclaration);

  Expect.equals(cm, cm1.originalDeclaration);

  Expect.equals(cm, reflectClass(Foo));
  Expect.equals(cm, reflectClass((new Foo().runtimeType)));
  Expect.equals(cm1, reflect(new Foo<String>()).type);

  expect('[]', cm.typeArguments);
  expect('[Class(s(String) in s(dart.core), top-level)]', cm1.typeArguments);

  cm = reflect(new Bar<List, Set>()).type;
  cm1 = reflect(new Bar<List, Set<String>>()).type;

  var cm2 = reflect(new Bar<List<String>, Set>()).type;
  var cm3 = reflect(new Bar<List<String>, Set<String>>()).type;

  expect(
      '[Class(s(List) in s(dart.core), top-level),'
      ' Class(s(Set) in s(dart.core), top-level)]',
      cm.typeArguments);
  expect(
      '[Class(s(List) in s(dart.core), top-level),'
      ' Class(s(Set) in s(dart.core), top-level)]',
      cm1.typeArguments);
  expect(
      '[Class(s(List) in s(dart.core), top-level),'
      ' Class(s(Set) in s(dart.core), top-level)]',
      cm2.typeArguments);
  expect(
      '[Class(s(List) in s(dart.core), top-level),'
      ' Class(s(Set) in s(dart.core), top-level)]',
      cm3.typeArguments);

  expect('[Class(s(String) in s(dart.core), top-level)]',
      cm1.typeArguments[1].typeArguments);
  expect('[Class(s(String) in s(dart.core), top-level)]',
      cm2.typeArguments[0].typeArguments);
  expect('[Class(s(String) in s(dart.core), top-level)]',
      cm3.typeArguments[0].typeArguments);
  expect('[Class(s(String) in s(dart.core), top-level)]',
      cm3.typeArguments[1].typeArguments);

  var cm4 = reflect(new Bar<Bar<List, Set>, String>()).type;

  expect(
      '[Class(s(Bar) in s(lib), top-level),'
      ' Class(s(String) in s(dart.core), top-level)]',
      cm4.typeArguments);
  expect(
      '[Class(s(List) in s(dart.core), top-level), '
      'Class(s(Set) in s(dart.core), top-level)]',
      cm4.typeArguments[0].typeArguments);
}
