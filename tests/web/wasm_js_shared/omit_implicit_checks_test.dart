// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks
// dart2wasmOptions=--omit-implicit-checks

import 'package:expect/expect.dart';
import 'package:expect/config.dart';

final kTrue = int.parse('1') == 1;

void main() {
  // This test is specific to testing dart2wasm & dart2js.
  if (!isDart2jsConfiguration && !isDart2WasmConfiguration) return;

  testExplicitAsCheck();

  testCovariantMethodCheck();
  testDynamicCall();
  testCovariantKeyword();
}

void testExplicitAsCheck() {
  final dynamic x = kTrue ? A() : B();
  Expect.throws(() => x as B);
}

void testCovariantMethodCheck() {
  final List<dynamic> list = kTrue ? <String>['a'] : <int>[1];
  list.add('b');
  list.add(3);
  Expect.equals('a', list[0]);
  Expect.equals('b', list[1]);
  Expect.equals(3, list[2]);
}

void testDynamicCall() {
  final dynamic a = kTrue ? (List a) => 'closure($a)' : A();
  Expect.equals('closure(B)', a(B()));
}

void testCovariantKeyword() {
  final object = kTrue ? B() : A();

  // Normally the `covariant String` would cause a type error to be thrown, but
  // due to --omit-implicit-checks it works just fine.
  Expect.equals('B.foo(42)', object.foo(42));
}

class A {
  String foo(Object arg) => 'A.foo($arg)';
}

class B extends A {
  String foo(covariant String arg) => 'B.foo($arg)';

  String toString() => 'B';
}
