// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C {
  final field;
  const C(this.field);
}

const c1 = const C(0.0);
const c2 = const C(0);
const c3 = const C(0.5 + 0.5);
const c4 = const C(1);

main() {
  Expect.equals('0.0', test(c1)); //# 01: ok
  Expect.equals('0', test(c2)); //  //# 02: ok
  Expect.equals('1.0', test(c3)); //# 03: ok
  Expect.equals('1', test(c4)); //  //# 04: ok
}

String test(C c) {
  switch (c) {
    case const C(0.0):
      return '0.0';
    case const C(0):
      return '0';
    case const C(1.0):
      return '1.0';
    case const C(1):
      return '1';
  }
  return null;
}
