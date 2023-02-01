// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  const Class1();

  bool operator ==(Object other) {
    return true;
  }
}

const Class1 c1 = const Class1();

test1(o) {
  switch (o) {
    case c1:
      return true;
    default:
      return false;
  }
}

class Class2 {
  const Class2();

  bool operator ==(Object other) {
    return false;
  }
}

const Class2 c2 = const Class2();

test2(o) {
  switch (o) {
    case c2:
      return true;
    default:
      return false;
  }
}

main() {
  expect(true, test1(const Class1()));
  expect(true, test1(new Class1()));
  expect(true, test1(0));
  expect(false, test1(null));

  expect(false, test2(const Class2()));
  expect(false, test2(new Class2()));
  expect(false, test2(0));
  expect(false, test2(null));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
