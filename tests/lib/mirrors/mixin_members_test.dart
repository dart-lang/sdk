// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_members_test;

@MirrorsUsed(targets: "mixin_members_test")
import "dart:mirrors";

import "package:expect/expect.dart";

import 'stringify.dart';

abstract class Fooer {
  foo1();
}

class S implements Fooer {
  foo1() {}
  foo2() {}
}

class M1 {
  bar1() {}
  bar2() {}
}

class M2 {
  baz1() {}
  baz2() {}
}

class C extends S with M1, M2 {}

membersOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && !v.isConstructor) result[k] = v;
    if (v is VariableMirror) result[k] = v;
  });
  return result;
}

main() {
  ClassMirror cm = reflectClass(C);
  ClassMirror sM1M2 = cm.superclass;
  ClassMirror sM1 = sM1M2.superclass;
  ClassMirror s = sM1.superclass;
  expect('{}', membersOf(cm));
  expect(
      '[s(baz1), s(baz2)]',
      // TODO(ahe): Shouldn't have to sort.
      sort(membersOf(sM1M2).keys),
      '(S with M1, M2).members');
  expect('[s(M2)]', simpleNames(sM1M2.superinterfaces),
      '(S with M1, M2).superinterfaces');
  expect(
      '[s(bar1), s(bar2)]',
      // TODO(ahe): Shouldn't have to sort.
      sort(membersOf(sM1).keys),
      '(S with M1).members');
  expect('[s(M1)]', simpleNames(sM1.superinterfaces),
      '(S with M1).superinterfaces');
  expect(
      '[s(foo1), s(foo2)]',
      // TODO(ahe): Shouldn't have to sort.
      sort(membersOf(s).keys),
      's.members');
  expect('[s(Fooer)]', simpleNames(s.superinterfaces), 's.superinterfaces');
  Expect.equals(s, reflectClass(S));
}
