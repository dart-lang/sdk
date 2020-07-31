// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String TEST_1 = """
class A {
  var a = 42;
}

main() {
  new A().a = 54;
  return new A().a;
}
""";

const String TEST_2 = """
class A {
  var a = 42;
}

main() {
  return new A().a;
}
""";

const String TEST_3 = """
class A {
  var a = 42;
}

main() {
  var a = new A();
  return a.a + a.a;
}
""";

const String TEST_4 = """
class A {
  var a = 42;
}

var list = [];
main() {
  new A().a = 54;
  var a = new A();
  list.add(a);
  return a.a + a.a;
}
""";

const String TEST_5 = """
class A {
  var a = 42;
}

var list = [];
main() {
  var a = new A();
  list.add(a);
  return a.a + a.a;
}
""";

const String TEST_6 = """
class A {
  var a = 42;
}

var list = [new A()];
main() {
  var a = new A();
  var b = list[0];
  b.a = 52;
  return a.a + a.a;
}
""";

const String TEST_7 = """
class A {
  var a = 42;
}

var list = [new A(), new A()];
main() {
  var a = list[0];
  a.a = 32;
  return a.a;
}
""";

const String TEST_8 = """
class A {
  var a = 42;
}

var list = [new A(), new A()];
main() {
  var a = list[0];
  a.a = 32;
  var b = list[1];
  b.a = 42;
  return a.a;
}
""";

const String TEST_9 = """
class A {
  var a = 42;
}

main() {
  var a = new A();
  (() => a.a = 2)();
  return a.a;
}
""";

const String TEST_10 = """
class A {
  var a = 42;
}

main() {
  var a = new A();
  a.a = 2;
  return a.a;
}
""";

const String TEST_11 = """
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

main() {
  var a = new A(42);
  var b = new A.bar(a);
  b.foo();
  return a.a;
}
""";

const String TEST_12 = """
var a;
var b;

main() {
  a = 10;
  b = 4;
  return a - b;
}
""";

const String TEST_13 = """
var a = [1, 2];

main() {
  a[0] = 10;
  a[1] = 4;
  return a[0] - a[1];
}
""";

const String TEST_14 = """
var a = [1, 2];
var b = [1, 2];

main() {
  a[0] = 10;
  b[0] = 4;
  return a[0];
}
""";

const String TEST_15 = """
var a;

main() {
  a = 42;
  if (true) {
  }
  return a;
}
""";

const String TEST_16 = """
var a;

main() {
  a = false;
  if (main() && main()) {
    a = true;
  }
  return a;
}
""";

const String TEST_17 = """
var a;
int x = 0;

main() {
  (print)(x++);
  if (x == 0) {
    a = true;
  } else {
    a = false;
  }
  return a;
}
""";

const String TEST_18 = """

main() {
  var a = [42, true];
  if (a[1]) {
    a[0] = 1;
  } else {
    a[0] = 2;
  }
  return a[0];
}
""";

main() {
  runTests() async {
    test(String code, Pattern expected) async {
      String generated = await compile(code,
          disableInlining: false, disableTypeInference: false);
      Expect.isTrue(
          generated.contains(expected),
          "Generated code didn't contain '$expected'.\n"
          "Test:\n$code, Generated:\n$generated");
    }

    await test(TEST_1, 'return 42');
    await test(TEST_2, 'return 42');
    await test(TEST_3, 'return 84');
    await test(TEST_4, 'return t1 + t1');
    await test(TEST_5, 'return 84');
    await test(TEST_6, 'return 84');
    await test(TEST_7, RegExp('return( .* =)? 32'));
    await test(TEST_8, 'return a.a');
    await test(TEST_9, 'return a.a');
    await test(TEST_10, 'return 2');
    await test(TEST_11, 'return a.a');
    await test(TEST_12, 'return 6');
    await test(TEST_13, 'return 6');
    await test(TEST_14, 'return t1[0]');
    await test(TEST_15, 'return 42');
    await test(TEST_16, 'return \$.a');
    await test(TEST_17,
        RegExp(r'return (t1|\$\.x === 0 \? \$\.a = true : \$\.a = false);'));
    await test(TEST_18, 'return t1');
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
