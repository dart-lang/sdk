// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// Two loop variables
test1() async {
  var r = 0;
  label:
  for (var i = 1,
          j =
      await //# await_in_init: ok
              10;
      i < 10 &&
          j >
      await //# await_in_condition: ok
              -5;
      j--,
      i +=
      await //# await_in_update: ok
          1) {
    if (i <
        await //# await_in_body: ok
            5 ||
        j < -5) {
      continue label;
    }
    r++;
  }
  Expect.equals(5, r);
}

// One loop variable
test2() async {
  var r = 0;
  label:
  for (var i =
     await //# await_in_init: ok
          0;
      i <
     await //# await_in_condition: ok
          10;
      i +=
     await //# await_in_update: ok
          1) {
    if (i <
        await //# await_in_body: ok
        5) {
      continue label;
    }
    r++;
  }
  Expect.equals(5, r);
}

// Variable not declared in initializer;
test3() async {
  var r = 0, i, j;
  label:
  for (i =
      await //# await_in_init: ok
          0;
      i <
      await //# await_in_condition: ok
          10;
      i +=
      await //# await_in_update: ok
          1) {
    if (i <
        await //# await_in_body: ok
        5) {
      continue label;
    }
    r++;
  }
  Expect.equals(5, r);
}

// Nested loop
test4() async {
  var r = 0;
  label:
  for (var i =
      await //# await_in_init: ok
          0;
      i <
      await //# await_in_condition: ok
          10;
      i +=
      await //# await_in_update: ok
          1) {
    if (i <
        await //# await_in_body: ok
        5) {
      for (int i = 0; i < 10; i++) {
        continue label;
      }
    }
    r++;
  }
  Expect.equals(5, r);
}

test() async {
  await test1();
  await test2();
  await test3();
  await test4();
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
