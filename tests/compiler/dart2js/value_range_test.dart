// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const int REMOVED = 0;
const int ABOVE_ZERO = 1;
const int BELOW_LENGTH = 2;
const int KEPT = 3;

final List TESTS = [
"""
main() {
  var a = new List();
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main(value) {
  var a = new List();
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
ABOVE_ZERO,

"""
main(check) {
  // Make sure value is an int.
  var value = check ? 42 : 54;
  var a = new List(value);
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
REMOVED,

"""
main() {
  var a = new List();
  return a[0];
}
""",
KEPT,

"""
main() {
  var a = new List();
  return a.removeLast();
}
""",
KEPT,

"""
main() {
  var a = new List(4);
  return a[0];
}
""",
REMOVED,

"""
main() {
  var a = new List(4);
  return a.removeLast();
}
""",
REMOVED,

"""
main(value) {
  var a = new List(value);
  return a[value];
}
""",
KEPT,

"""
main(value) {
  var a = new List(1024);
  return a[1023 & value];
}
""",
REMOVED,

"""
main(value) {
  var a = new List(1024);
  return a[1024 & value];
}
""",
ABOVE_ZERO,

"""
main(value) {
  var a = new List();
  return a[1];
}
""",
ABOVE_ZERO
];

expect(String code, int kind) {
  String generated = compile(code);
  switch (kind) {
    case REMOVED:
      Expect.isTrue(!generated.contains('ioore'));
      break;

    case ABOVE_ZERO:
      Expect.isTrue(!generated.contains('> 0'));
      Expect.isTrue(generated.contains('ioore'));
      break;

    case BELOW_LENGTH:
      Expect.isTrue(!generated.contains('||'));
      Expect.isTrue(generated.contains('ioore'));
      break;

    case KEPT:
      Expect.isTrue(generated.contains('ioore'));
      break;
  }
}


main() {
  for (int i = 0; i < TESTS.length;  i += 2) {
    expect(TESTS[i], TESTS[i + 1]);
  }
}
