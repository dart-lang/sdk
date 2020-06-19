// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef String F(String returns, String arguments, [Map<String, String> named]);

/// Formats a type like `(String, [int], {bool name}) => double`.
String fn(String returns, String positional,
    [Map<String, String> named = const {}]) {
  var result = new StringBuffer();
  result.write("($positional");
  if (positional != "" && named.isNotEmpty) result.write(", ");
  if (named.isNotEmpty) {
    result.write("{");
    bool first = true;
    named.forEach((name, type) {
      if (first) {
        first = false;
      } else {
        result.write(", ");
      }
      result.write("$type $name");
    });
    result.write("}");
  }
  result.write(") => $returns");
  return result.toString();
}

main() {
  // Types that do not use class names - these can be checked on dart2js in
  // minified mode.

  check(fn('dynamic', ''), main); //        Top-level tear-off.
  check(fn('void', ''), Xyzzy.foo); //      Class static member tear-off.
  check(fn('void', 'Object'), new MyList().add); //  Instance tear-off.
  check(fn('int', ''), () => 1); //       closure.

  var s = new Xyzzy().runtimeType.toString();
  if (s.length <= 3) return; // dart2js --minify has minified names.

  Expect.equals('Xyzzy', s, 'runtime type of plain class prints as class name');

  check(fn('void', 'String, dynamic'), check);

  // Class static member tear-offs.
  check(fn('String', 'String, [String, dynamic]'), Xyzzy.opt);
  check(fn('String', 'String', {'a': 'String', 'b': 'dynamic'}), Xyzzy.nam);

  // Instance method tear-offs.
  check(fn('void', 'Object'), new MyList<String>().add);
  check(fn('void', 'Object'), new MyList<int>().add);
  check(fn('void', 'int'), new Xyzzy().intAdd);

  check(fn('String', 'Object'), new G<String, int>().foo);

  // Instance method with function parameter.
  var string2int = fn('int', 'String');
  check(fn('String', 'Object'), new G<String, int>().moo);
  check(fn('String', '$string2int'), new G<String, int>().higherOrder);

  // Closures.
  String localFunc(String a, String b, [Map<String, String> named]) => a + b;
  void localFunc2(int a) {
    print(a);
  }

  Expect.isTrue(localFunc is F);
  check(fn('String', 'String, String, [Map<String, String>]'), localFunc);
  check(fn('void', 'int'), localFunc2);
}

void check(String text, var thing) {
  var type = thing.runtimeType.toString();
  if (type == text) return;
  Expect.fail("""
Type print string does not match expectation
  Expected: '$text'
  Actual: '$type'
""");
}

class Xyzzy {
  static void foo() {}
  static String opt(String x, [String a, b]) {}
  static String nam(String x, {String a, b}) {}
  void intAdd(int x) {}
}

// Using 'MyList' instead of core lib 'List' keeps covariant parameter type of
// tear-offs 'Object' (legacy lib) instead of 'Object?' (opted-in lib).
class MyList<E> {
  void add(E value) {}
}

class G<U, V> {
  U foo(V x) => null;
  U moo(V f(U x)) => null;
  U higherOrder(int f(U x)) => null;
}
