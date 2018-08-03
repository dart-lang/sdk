// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef String F(String returns, String arguments, [Map<String, String> named]);
F fn;

/// Formats types the VM way: `(String, [int], {bool name}) => double`.
String form1(String returns, String positional,
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

/// Formats types the dart2js way: `double Function(String, [int], {bool name})`.
String form2(String returns, String positional,
    [Map<String, String> named = const {}]) {
  var result = new StringBuffer();
  result.write("$returns Function");
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
  result.write(")");
}

F detectForm() {
  var s = main.runtimeType.toString();
  if (s.contains('=>')) return form1;
  if (s.contains('Function')) return form2;
  Expect.fail('"$s" contains neither "=>", nor "Function"');
}

main() {
  fn = detectForm();

  // Types that do not use class names - these can be checked on dart2js in
  // minified mode.

  check(fn('dynamic', ''), main); //        Top-level tear-off.
  check(fn('void', ''), Xyzzy.foo); //      Class static member tear-off.
  check(fn('void', 'Object'), [].add); //  Instance tear-off.
  check(fn('int', ''), () => 1); //       closure.

  var s = new Xyzzy().runtimeType.toString();
  if (s.length <= 3) return; // dart2js --minify has minified names.

  Expect.equals('Xyzzy', s, 'runtime type of plain class prints as class name');

  check(fn('void', 'String, dynamic'), check);

  // Class static member tear-offs.
  check(fn('String', 'String, [String, dynamic]'), Xyzzy.opt);
  check(fn('String', 'String', {'a': 'String', 'b': 'dynamic'}), Xyzzy.nam);

  // Instance method tear-offs.
  check(fn('void', 'Object'), <String>[].add);
  check(fn('void', 'Object'), <int>[].add);
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

class G<U, V> {
  U foo(V x) => null;
  U moo(V f(U x)) => null;
  U higherOrder(int f(U x)) => null;
}
