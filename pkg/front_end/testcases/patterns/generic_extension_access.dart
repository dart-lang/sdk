// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<T> {}

class J<T> extends I<T> {}

class A<T> extends J<T> {}

int counter = 0;

extension<T> on I<T> {
  num get member {
    counter++;
    return T == num ? 0.5 : -1;
  }
}

num method1(I<num> i) => switch (i) {
      I<num>(:var member) when member < 0 => member,
      I<int>(:var member) when member < 0 => member,
      I<num>(:var member) => -member,
    };

// TODO(johnniwinther): This should be exhaustive.
num method2(A<num> i) => switch (i) {
      I<num>(:int member) => member,
      J<num>(:double member) => member,
    };

main() {
  counter = 0;
  expect(-1, method1(A<int>()));
  expect(2, counter);

  counter = 0;
  expect(-0.5, method1(A<num>()));
  expect(1, counter);

  counter = 0;
  expect(-0.5, method1(A<double>()));
  expect(1, counter);

  counter = 0;
  expect(0.5, method2(A<int>()));
  expect(1, counter);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
