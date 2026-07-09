// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Nest an unevaluated constant inside a record constant.
//
// Regression test for https://github.com/dart-lang/sdk/issues/52468
const unevaluated = const bool.fromEnvironment('a.b.c') ? 1 : 2;
const list = <(int, int)>[(0, unevaluated)];
const list2 = <int>[unevaluated];
main() {
  print(list);
  print(list2);
}
