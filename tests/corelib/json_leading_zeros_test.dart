// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a trimmed-down version of json_test to isolate a difference between
// IE and other runtimes.

library json_test;

import "dart:json";

bool badFormat(e) => e is FormatException;

void testThrows(json) {
  Expect.throws(() => parse(json), badFormat);
}

testNumbers() {
  // Positive tests for number formats.
  var integerList = ["0","9","9999"];
  var signList = ["", "-"];
  var fractionList = ["", ".0", ".1", ".99999"];
  var exponentList = [""];
  for (var exphead in ["e", "E", "e-", "E-", "e+", "E+"]) {
    for (var expval in ["0", "1", "200"]) {
      exponentList.add("$exphead$expval");
    }
  }

  // Negative tests (syntax error).
  // testError thoroughly tests the given parts with a lot of valid
  // values for the other parts.
  testError({signs, integers, fractions, exponents}) {
    def(value, defaultValue) {
      if (value == null) return defaultValue;
      if (value is List) return value;
      return [value];
    }
    signs = def(signs, signList);
    integers = def(integers, integerList);
    fractions = def(fractions, fractionList);
    exponents = def(exponents, exponentList);
    for (var integer in integers) {
      for (var sign in signs) {
        for (var fraction in fractions) {
          for (var exponent in exponents) {
            var literal = "$sign$integer$fraction$exponent";
            testThrows(literal);
          }
        }
      }
    }
  }
  // Initial zero only allowed for zero integer part.
  testError(integers: ["00", "01"]);
}

main() {
  testNumbers();
}
