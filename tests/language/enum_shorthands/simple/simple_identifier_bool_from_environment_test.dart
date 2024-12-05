// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When the context type is a language-defined bool (`if`, `||`, `while`),
// using an enum shorthand will match the `fromEnvironment` member in the
// `bool` class.

// SharedOptions=--enable-experiment=enum-shorthands -Da=true

import 'package:expect/expect.dart';

void main() {
  var now = DateTime.now().millisecondsSinceEpoch;
  var yes = now > 0;
  var no = now < 0;

  Expect.equals(no || const .fromEnvironment("a"), true, "||");
  Expect.equals(const .fromEnvironment("a") || no, true);
  Expect.equals(yes && const .fromEnvironment("a"), true);
  Expect.equals(const .fromEnvironment("a") && yes, true);
  Expect.equals(!const .fromEnvironment("a"), false);

  if (const .fromEnvironment("a")) {
    // Success.
  } else {
    Expect.fail("Didn't find a");
  }

  var counter = 0;
  while (const .fromEnvironment("a")) {
    counter++;
    break;
  }
  Expect.equals(counter, 1, "while loop condition");

  counter = 0;
  do {
    counter++;
    if (counter == 2) break;
  } while (const .fromEnvironment("a"));
  Expect.equals(counter, 2, "do-while loop condition");

  counter = 0;
  for (; const .fromEnvironment("a");) {
    counter++;
    break;
  }
  Expect.equals(counter, 1, "for loop condition");

  if (now case > 0 when const .fromEnvironment("a")) {
    // Success.
  } else {
    Expect.fail("if-case when");
  }

  switch (now) {
    case > 0 when const .fromEnvironment("a"):
      break;
    case _:
      Expect.fail("switch case when");
  }

  var expressionResult = switch (now) {
    > 0 when const .fromEnvironment("a") => "success",
    _ => "failure",
  };
  Expect.equals(expressionResult, "success", "switch expression case when");
}
