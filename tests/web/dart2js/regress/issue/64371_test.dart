// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

String f(int i) {
  final (int, int)? r = switch (i) {
    0 => (1, 2),
    1 => null,
    _ => (i, i),
  };
  if (r == null) return 'null';
  return '${r.$1}';
}

void main() {
  Expect.equals('null', f(1));
  Expect.equals('1', f(0));
  Expect.equals('5', f(5));
}
