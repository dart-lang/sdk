// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/45270

void main() {
  // Function.apply.
  test<int?>(42);
  test<int?>(null);

  // Dynamic closure calls.
  test2<int?>(42);
  test2<int?>(null);
}

void test<T>(T value) {
  final f = (T inner) {
    print('f inner=$inner T=$T');
  };
  Function.apply(f, [value]);
}

void test2<T>(T value) {
  dynamic f = (T inner) {
    print('f inner=$inner T=$T');
  };
  f(value);
}
