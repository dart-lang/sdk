// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
void foo(bar) {
  for (int i = 0; i < 1; i++) {
    print(1 + bar);
    print(1 + bar);
  }
}
""";

// Check that modulo does not have any side effect and we are
// GVN'ing the length of [:list:].
const String TEST_TWO = r"""
void foo(a) {
  var list = new List<int>();
  list[0] = list[0 % a];
  list[1] = list[1 % a];
}
""";

// Check that is checks get GVN'ed.
const String TEST_THREE = r"""
void foo(a) {
  print(42);  // Make sure numbers are used.
  print(a is num);
  print(a is num);
}
""";

// Check that instructions that don't have a builtin equivalent can
// still be GVN'ed.
const String TEST_FOUR = r"""
void foo(a) {
  print(1 >> a);
  print(1 >> a);
}
""";

// Check that [HCheck] instructions do not prevent GVN.
const String TEST_FIVE = r"""
class A {
  final int foo;
  A(this.foo);
}

class B {}

main() {
  helper([new A(32), new A(21), new B(), null][0]);
}

helper(A a) {
  var b = a.foo;
  var c = a.foo;
  if (a is B) {
    c = (a as dynamic).foo;
  }
  return b + c;
}
""";

// Check that a gvn'able instruction in the loop header gets hoisted.
const String TEST_SIX = r"""
class A {
  @pragma('dart2js:noElision')
  final field = 54;
}

main() {
  dynamic a = new A();
  while (a.field == 54) { a.field = 42; }
}
""";

// Check that a gvn'able instruction that may throw in the loop header
// gets hoisted.
const String TEST_SEVEN = r"""
class A {
  final field;
  A() : field = null;
  A.bar() : field = 42;
}

main() {
  dynamic a = new A();
  dynamic b = new A.bar();
  while (a.field == 54) { a.field = 42; b.field = 42; }
}
""";

// Check that a check in a loop header gets hoisted.
const String TEST_EIGHT = r"""
class A {
  final field;
  A() : field = null;
  A.bar() : field = 42;
}

main() {
  dynamic a = new A();
  dynamic b = new A.bar();
  for (int i = 0; i < a.field; i++) { a.field = 42; b.field = 42; }
}
""";

main() {
  asyncTest(() async {
    await compile(TEST_ONE, entry: 'foo', check: (String generated) {
      RegExp regexp = RegExp(r"1 \+ [a-z]+");
      checkNumberOfMatches(regexp.allMatches(generated).iterator, 1);
    });
    await compile(TEST_TWO, entry: 'foo', check: (String generated) {
      checkNumberOfMatches(RegExp("length").allMatches(generated).iterator, 1);
    });
    await compile(TEST_THREE, entry: 'foo', check: (String generated) {
      checkNumberOfMatches(RegExp("number").allMatches(generated).iterator, 1);
    });
    await compile(TEST_FOUR, entry: 'foo', check: (String generated) {
      checkNumberOfMatches(RegExp("shr").allMatches(generated).iterator, 1);
    });

    await compileAll(TEST_FIVE).then((generated) {
      checkNumberOfMatches(RegExp(r"\.foo;").allMatches(generated).iterator, 1);
      checkNumberOfMatches(
          RegExp(r"get\$foo\(").allMatches(generated).iterator, 0);
    });
    await compileAll(TEST_SIX).then((generated) {
      Expect.isTrue(generated.contains('for (t1 = a.field === 54; t1;)'));
    });
    await compileAll(TEST_SEVEN).then((generated) {
      Expect.isTrue(generated.contains('for (t1 = a.field === 54; t1;)'));
    });
    await compileAll(TEST_EIGHT).then((generated) {
      Expect.isTrue(generated.contains('for (; i < t1; ++i)'));
    });
  });
}
