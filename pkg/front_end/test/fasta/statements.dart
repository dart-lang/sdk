// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  try {
    return;
  } finally {
    print("Hello from finally block!");
  }
}

bar() async {
  await for (var x in []) {
    yield x;
    yield* x;
  }
}

main() {
  do {
    print("Hello from do-while!");
  } while(false);
  do var x = print("Hello from do-while!"); while(false);

  for (String s in ["Hello from for-in!"]) {
    print(s);
  }
  for (String s in ["Hello from for-in without block!"])
    print(s);
  var s;
  for (s in ["Hello from for-in without decl!"]) {
    print(s);
  }
  for (s in ["Hello from for-in without decl and block!"])
    print(s);
  a: b: c: print("Hello from labeled statement!");
  try {
    try {
      throw "Hello from rethrow!";
    } catch (e) {
      rethrow;
    }
  } catch (e) {
    print(e);
  }
  foo();
  bool done = false;
  while (!done) {
    done = true;
    print("Hello from while!");
  }
  ; // Testing empty statement.
  assert(true);
  assert(true, "Hello from assert!");
  try {
    assert(false, "Hello from assert!");
  } catch (e) {
    print(e);
  }
  switch (1) {
    case 1:
    case 2:
      print("Hello from switch case!");
      break;
    default:
      break;
  }
  switch (4) {
    L2: case 2:
      print("Hello from case 2!");
      break;
    L1: case 1:
      print("Hello from case 1!");
      continue L2;
    L0: case 0:
      print("Hello from case 0!");
      continue L1;
    case 4:
      print("Hello from case 4!");
      continue LD;
    LD: default:
      continue L0;
  }
  switch (4) {
    L0: case 1:
      print("Hello from next case 1");
      break;
    default:
      continue L0;
  }
  int i = 0;
  do {
    print("Hello from do-while!");
    if (++i < 3) continue;
    break;
  } while (true);
  i = 0;
  OUTER: while (true) {
    print("Hello from while!");
    if (++i < 3) continue OUTER;
    break OUTER;
  }
}
