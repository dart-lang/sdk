// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When the context type is a language-defined bool (`if`, `||`, `while`),
// using an enum shorthand will match the `tryParse` member in the `bool` class.

// SharedOptions=--enable-experiment=enum-shorthands

import 'package:expect/expect.dart';

void main() {
  var now = DateTime.now().millisecondsSinceEpoch;
  var yes = now > 0;
  var no = now < 0;
  var text = 'true';

  Expect.equals(no || .tryParse(text)!, true, "||");
  Expect.equals(.tryParse(text)! || no, true);
  Expect.equals(yes && .tryParse(text)!, true);
  Expect.equals(.tryParse(text)! && yes, true);
  Expect.equals(!.tryParse(text)!, false);

  if (.tryParse(text)!) {
    // Success.
  } else {
    Expect.fail("Didn't find banana");
  }

  var counter = 0;
  while (.tryParse(text)!) {
    counter++;
    break;
  }
  Expect.equals(counter, 1, "while loop condition");

  counter = 0;
  do {
    counter++;
    if (counter == 2) break;
  } while (.tryParse(text)!);
  Expect.equals(counter, 2, "do-while loop condition");

  counter = 0;
  for (; .tryParse(text)!;) {
    counter++;
    break;
  }
  Expect.equals(counter, 1, "for loop condition");

  if (now case > 0 when .tryParse(text)!) {
    // Success.
  } else {
    Expect.fail("if-case when");
  }

  switch (now) {
    case > 0 when .tryParse(text)!:
      break;
    case _:
      Expect.fail("switch case when");
  }

  var expressionResult = switch (now) {
    > 0 when .tryParse(text)! => "success",
    _ => "failure",
  };
  Expect.equals(expressionResult, "success", "switch expression case when");
}
