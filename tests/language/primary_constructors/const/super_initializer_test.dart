// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for issue 63506.

import 'package:expect/expect.dart';

class B {
  final int i;

  const new({required this.i});
}

class const C({required int i}) extends B {
  this : super(i: i);
}

main() {
  B c0 = C(i: 0);
  Expect.equals(0, c0.i);

  B c1 = const C(i: 1);
  Expect.equals(1, c1.i);
}
