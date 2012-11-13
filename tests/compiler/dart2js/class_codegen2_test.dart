// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST_ONE = r"""
class A { foo() => 499; }
class B { bar() => 42; }

main() {
  new A().foo();
  new B().bar();
}
""";

const String TEST_TWO = r"""
class A {
  foo() => 499;
  bar() => 42;
}

main() {
  new A().foo();
  new A().bar();
}
""";

const String TEST_THREE = r"""
class A {
  foo() => 499;
  bar() => 42;
}

class B extends A {
  foo() => -499;
  bar() => -42;
}

var y;
foo(i) {
  if (0 != i) {
    y--;
    foo(i - 1);
    y++;
  }
}

makeStaticInliningHard() {
  y = 0;
  foo(10);
  return 0 == y;
}


// id returns [x] in a way that should be difficult to predict statically.
id(x) {
  y = x;
  foo(10);
  return y;
}

main() {
  var a = new A();
  var b = new B();
  var x = a;
  if (makeStaticInliningHard()) x = b;
  x.foo();
  x.bar();
}
""";

const String TEST_FOUR = r"""
class A { foo() => 499; }

foo(f) { f(); }

main() {
  foo(new A().foo);
}
""";

main() {
  // At some point Dart2js generated bad object literals with dangling commas:
  // { a: true, }. Make sure this doesn't happen again.
  RegExp danglingComma = new RegExp(r',[ \n]*}');
  String generated = compileAll(TEST_ONE);
  Expect.isFalse(danglingComma.hasMatch(generated));

  generated = compileAll(TEST_TWO);
  Expect.isFalse(danglingComma.hasMatch(generated));

  generated = compileAll(TEST_THREE);
  Expect.isFalse(danglingComma.hasMatch(generated));

  generated = compileAll(TEST_FOUR);
  Expect.isFalse(danglingComma.hasMatch(generated));
}
