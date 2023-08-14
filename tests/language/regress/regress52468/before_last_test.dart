// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Nest an unevaluated constant inside a record constant.
//
// Similar to simple_test.dart, but ensure the logic works also when the
// unevaluated constant is not the last record entry (tracks properly managing
// the internal state of unevaluated constnats on sequence of subexpressions).
//
// Regression test for https://github.com/dart-lang/sdk/issues/52468
const unevaluated = const bool.fromEnvironment('a.b.c') ? 1 : 2;
const list = <(int, int, int)>[(0, unevaluated, 2)];
const list2 = <(int, int, int)>[(0, 1, unevaluated)];
main() {
  print(list);
  print(list2);
}
