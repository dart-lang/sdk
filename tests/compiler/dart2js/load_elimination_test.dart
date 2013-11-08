// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST_ONE = """
class A {
  var a = 42;
}

void main() {
  new A().a = 54;
  return new A().a;
}
""";

const String TEST_TWO = """
class A {
  var a = 42;
}

void main() {
  return new A().a;
}
""";

const String TEST_THREE = """
class A {
  var a = 42;
}

void main() {
  var a = new A();
  return a.a + a.a;
}
""";

const String TEST_FOUR = """
class A {
  var a = 42;
}

var list = [];
void main() {
  new A().a = 54;
  var a = new A();
  list.add(a);
  return a.a + a.a;
}
""";

const String TEST_FIVE = """
class A {
  var a = 42;
}

var list = [];
void main() {
  var a = new A();
  list.add(a);
  return a.a + a.a;
}
""";

const String TEST_SIX = """
class A {
  var a = 42;
}

var list = [new A()];
void main() {
  var a = new A();
  var b = list[0];
  b.a = 52;
  return a.a + a.a;
}
""";

const String TEST_SEVEN = """
class A {
  var a = 42;
}

var list = [new A(), new A()];
void main() {
  var a = list[0];
  a.a = 32;
  return a.a;
}
""";

const String TEST_EIGHT = """
class A {
  var a = 42;
}

var list = [new A(), new A()];
void main() {
  var a = list[0];
  a.a = 32;
  var b = list[1];
  b.a = 42;
  return a.a;
}
""";

const String TEST_NINE = """
class A {
  var a = 42;
}

void main() {
  var a = new A();
  (() => a.a = 2)();
  return a.a;
}
""";

const String TEST_TEN = """
class A {
  var a = 42;
}

void main() {
  var a = new A();
  a.a = 2;
  return a.a;
}
""";

const String TEST_ELEVEN = """
class A {
  var a;
  var b;
  A(this.a);
  A.bar(this.b);

  foo() {
    () => 42;
    b.a = 2;
  }
}

void main() {
  var a = new A(42);
  var b = new A.bar(a);
  b.foo();
  return a.a;
}
""";


main() {
  test(String code, Function f) {
    asyncTest(() => compileAll(code, disableInlining: false).then((generated) {
      Expect.isTrue(f(generated));
    }));
  }
  test(TEST_ONE, (generated) => generated.contains('return 42'));
  test(TEST_TWO, (generated) => generated.contains('return 42'));
  test(TEST_THREE, (generated) => generated.contains('return 84'));
  test(TEST_FOUR, (generated) => generated.contains('return t1 + t1'));
  test(TEST_FIVE, (generated) => generated.contains('return 84'));
  test(TEST_SIX, (generated) => generated.contains('return 84'));
  test(TEST_SEVEN, (generated) => generated.contains('return 32'));
  test(TEST_EIGHT, (generated) => generated.contains('return a.a'));
  test(TEST_NINE, (generated) => generated.contains('return a.a'));
  test(TEST_TEN, (generated) => generated.contains('return 2'));
  test(TEST_ELEVEN, (generated) => generated.contains('return a.a'));
}
