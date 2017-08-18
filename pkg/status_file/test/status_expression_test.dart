// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "package:status_file/environment.dart";
import "package:status_file/src/expression.dart";

class TestEnvironment implements Environment {
  final Map<String, String> _values;

  TestEnvironment(this._values);

  void validate(String name, String value, List<String> errors) {
    throw new UnimplementedError();
  }

  /// Looks up the value of the variable with [name].
  String lookUp(String name) => _values[name];

  operator []=(String key, String value) => _values[key] = value;
}

main() {
  testExpression();
  testSyntaxError();
  testBoolean();
  testNotBoolean();
  testNotEqual();
}

void testExpression() {
  var expression = Expression
      .parse(r" $mode == debug && ($arch == chromium || $arch == dartc) ");
  Expect.equals(r"$mode == debug && ($arch == chromium || $arch == dartc)",
      expression.toString());

  // Test BooleanExpression.evaluate().
  var environment = new TestEnvironment({"arch": "dartc", "mode": "debug"});

  Expect.isTrue(expression.evaluate(environment));
  environment["mode"] = "release";
  Expect.isFalse(expression.evaluate(environment));
  environment["arch"] = "ia32";
  Expect.isFalse(expression.evaluate(environment));
  environment["mode"] = "debug";
  Expect.isFalse(expression.evaluate(environment));
  environment["arch"] = "chromium";
  Expect.isTrue(expression.evaluate(environment));
}

void testSyntaxError() {
  var input = r"($arch == (-dartc || $arch == chromium) && $mode == release";
  Expect.throws(() {
    Expression.parse(input);
  }, (e) => e.toString() == "FormatException: Syntax error in '$input'");
}

void testBoolean() {
  var expression =
      Expression.parse(r"  $arch == ia32 && $checked || $mode == release    ");
  Expect.equals(
      r"$arch == ia32 && $checked || $mode == release", expression.toString());

  // Test BooleanExpression.evaluate().
  var environment =
      new TestEnvironment({"arch": "ia32", "checked": "true", "mode": "debug"});

  Expect.isTrue(expression.evaluate(environment));
  environment["mode"] = "release";
  Expect.isTrue(expression.evaluate(environment));
  environment["checked"] = "false";
  Expect.isTrue(expression.evaluate(environment));
  environment["mode"] = "debug";
  Expect.isFalse(expression.evaluate(environment));
  environment["arch"] = "arm";
  Expect.isFalse(expression.evaluate(environment));
  environment["checked"] = "true";
  Expect.isFalse(expression.evaluate(environment));
}

void testNotBoolean() {
  var expression =
      Expression.parse(r"  $arch == ia32 && ! $checked || $mode == release ");
  Expect.equals(
      r"$arch == ia32 && !$checked || $mode == release", expression.toString());

  var environment = new TestEnvironment(
      {"arch": "ia32", "checked": "false", "mode": "debug"});

  Expect.isTrue(expression.evaluate(environment));
  environment["mode"] = "release";
  Expect.isTrue(expression.evaluate(environment));
  environment["checked"] = "true";
  Expect.isTrue(expression.evaluate(environment));
  environment["mode"] = "debug";
  Expect.isFalse(expression.evaluate(environment));
  environment["arch"] = "arm";
  Expect.isFalse(expression.evaluate(environment));
  environment["checked"] = "false";
  Expect.isFalse(expression.evaluate(environment));
}

void testNotEqual() {
  // Test the != operator.
  var expression = Expression.parse(r"$compiler == dart2js && $runtime != ie9");
  Expect.equals(
      r"$compiler == dart2js && $runtime != ie9", expression.toString());

  // Test BooleanExpression.evaluate().
  var environment = new TestEnvironment({
    "compiler": "none",
    "runtime": "ie9",
  });

  Expect.isFalse(expression.evaluate(environment));
  environment["runtime"] = "chrome";
  Expect.isFalse(expression.evaluate(environment));

  environment["compiler"] = "dart2js";
  environment["runtime"] = "ie9";
  Expect.isFalse(expression.evaluate(environment));
  environment["runtime"] = "chrome";
  Expect.isTrue(expression.evaluate(environment));
}
