// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  var _ = 1;
  int _ = 2;
  _ = 3; // Compile-time error.

  var _ = 2, _ = 2;

  int test2() => 1;
  var _ = test2();

  late bool _;
  late int _, _ = 3, x = 2;
  late int _ = 3, _ = 3;

  const _ = 2 + 3; // This evaluate to the constant 5.
  const int _ = 3, _ = 3;

  const dynamic d = 'string';
  const _ = 2 + d; // This should result in a compile-time error.
}
