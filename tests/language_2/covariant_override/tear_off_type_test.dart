// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// If a parameter is directly or indirectly a covariant override, its type in
// the method tear-off should become Object.

typedef void TakeInts(int a, int b, int c, int d, int e);
typedef void TakeObjectsAndInts(Object a, int b, Object c, int d, int e);
typedef void TakeObjects(Object a, Object b, Object c, Object d, Object e);

typedef void TakeOptionalInts([int a, int b, int c, int d]);
typedef void TakeOptionalObjectsAndInts([Object a, int b, Object c, int d]);

typedef void TakeNamedInts({int a, int b, int c, int d});
typedef void TakeNamedObjectsAndInts({Object a, int b, Object c, int d});

class M1 {
  method(covariant int a, int b) {}
}

class M2 {
  method(int a, covariant int b) {}
}

class C extends Object with M1, M2 {}

class Direct {
  void positional(covariant int a, int b, covariant int c, int d, int e) {}
  void optional([covariant int a, int b, covariant int c, int d]) {}
  void named({covariant int a, int b, covariant int c, int d}) {}
}

class Inherited extends Direct {}

// ---

class Override1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Override2 extends Override1 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Override3 extends Override2 {
  void method(int a, int b, int c, int d, int e) {}
}

// ---

abstract class Implement1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Implement2 {
  void method(int a, covariant int b, int c, int d, int e) {}
}

class Implement3 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Implement4 implements Implement3 {
  void method(int a, int b, int c, covariant int d, int e) {}
}

class Implement5 implements Implement1, Implement2, Implement4 {
  void method(int a, int b, int c, int d, covariant int e) {}
}

// ---

class Interface1 {
  void method(covariant int a, int b, int c, int d, int e) {}
}

class Interface2 {
  void method(int a, covariant int b, int c, int d, int e) {}
}

class Mixin1 {
  void method(int a, int b, covariant int c, int d, int e) {}
}

class Mixin2 {
  void method(int a, int b, int c, covariant int d, int e) {}
}

class Superclass {
  void method(int a, int b, int c, int d, covariant int e) {}
}

class Mixed extends Superclass
    with Mixin1, Mixin2
    implements Interface1, Interface2 {}

void main() {
  testDirect();
  testInherited();
  testOverriden();
  testImplemented();
  testMixed();
}

void testDirect() {
  var positional = new Direct().positional;
  Expect.isTrue(positional is TakeInts);
  Expect.isTrue(positional is TakeObjectsAndInts);

  var optional = new Direct().optional;
  Expect.isTrue(optional is TakeOptionalInts);
  Expect.isTrue(optional is TakeOptionalObjectsAndInts);

  var named = new Direct().named;
  Expect.isTrue(named is TakeNamedInts);
  Expect.isTrue(named is TakeNamedObjectsAndInts);
}

void testInherited() {
  var positional = new Inherited().positional;
  Expect.isTrue(positional is TakeInts);
  Expect.isTrue(positional is TakeObjectsAndInts);

  var optional = new Inherited().optional;
  Expect.isTrue(optional is TakeOptionalInts);
  Expect.isTrue(optional is TakeOptionalObjectsAndInts);

  var named = new Inherited().named;
  Expect.isTrue(named is TakeNamedInts);
  Expect.isTrue(named is TakeNamedObjectsAndInts);
}

void testOverriden() {
  var method2 = new Override2().method;
  Expect.isTrue(method2 is TakeInts);
  Expect.isTrue(method2 is TakeObjectsAndInts);

  var method3 = new Override3().method;
  Expect.isTrue(method3 is TakeInts);
  Expect.isTrue(method3 is TakeObjectsAndInts);
}

void testImplemented() {
  var method = new Implement5().method;
  Expect.isTrue(method is TakeInts);
  Expect.isTrue(method is TakeObjects);
}

void testMixed() {
  // TODO(rnystrom): https://github.com/dart-lang/sdk/issues/28395
  var method = new Mixed().method;
  Expect.isTrue(method is TakeInts);
  Expect.isTrue(method is TakeObjects);
}
