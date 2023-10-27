// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
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

void check(String text, var thing) {
  var type = thing.runtimeType.toString();
  if (type == text) return;
  Expect.fail("""
Type print string does not match expectation
  Expected: '$text'
  Actual: '$type'
""");
}

const testRunnerKey = 'test_runner.configuration';

/// Is the test running on a test configuration with VM obfuscation enabled?
final bool isObfuscated = (() {
  if (const bool.hasEnvironment(testRunnerKey)) {
    const config = String.fromEnvironment(testRunnerKey);
    return config.contains('obfuscate');
  }
  return false;
})();
