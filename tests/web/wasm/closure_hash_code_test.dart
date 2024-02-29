// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Check closure (tear-off, instantiation, static) equality, hash code, and
// identities.
//
// In principle principle unequal objects can have the same hash code, but it's
// very unlikely in this test. So we also check that if two closures are not
// equal then they should have different hash codes.

void staticFunction() {}

void genericStaticFunction<T>(T t) {}

class C {
  void memberFunction() {}

  void genericMemberFunction<T>(T t) {}
}

void main() {
  var functionExpression = () {};

  var genericFunctionExpression = <T>(T t) {};

  check(functionExpression, functionExpression, equal: true, isIdentical: true);
  check(genericFunctionExpression, genericFunctionExpression,
      equal: true, isIdentical: true);
  check(genericFunctionExpression<int>, genericFunctionExpression<int>,
      equal: true, isIdentical: false);

  check(() {}, () {}, equal: false, isIdentical: false);

  check(staticFunction, staticFunction, equal: true, isIdentical: true);
  check(genericStaticFunction, genericStaticFunction,
      equal: true, isIdentical: true);
  check(genericStaticFunction<int>, genericStaticFunction<int>,
      equal: true, isIdentical: true);

  final o1 = C();

  check(o1.memberFunction, o1.memberFunction, equal: true, isIdentical: false);
  check(o1.genericMemberFunction, o1.genericMemberFunction,
      equal: true, isIdentical: false);
  check(o1.genericMemberFunction<int>, o1.genericMemberFunction<int>,
      equal: true, isIdentical: false);

  final o2 = C();

  check(o1.memberFunction, o2.memberFunction, equal: false, isIdentical: false);
  check(o1.genericMemberFunction, o2.genericMemberFunction,
      equal: false, isIdentical: false);
  check(o1.genericMemberFunction<int>, o2.genericMemberFunction<int>,
      equal: false, isIdentical: false);
}

void check(Object? o1, Object? o2,
    {required bool equal, required bool isIdentical}) {
  (equal ? Expect.equals : Expect.notEquals)(o1, o2);
  (equal ? Expect.equals : Expect.notEquals)(o1.hashCode, o2.hashCode);

  (isIdentical ? Expect.isTrue : Expect.isFalse)(identical(o1, o2));
}
