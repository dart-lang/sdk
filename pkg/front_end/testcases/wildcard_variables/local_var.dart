// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  var _ = 1;
  int _ = 2;
  _ = 3;

  var _ = 2, _ = 2;

  int test2() => 1;
  var _ = test2();

  late bool _;
  late int _, _ = 3, x = 2;
  late int _ = 3, _ = 3;
}
