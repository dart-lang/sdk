// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef F1 = int Function(int);
typedef F2 = int Function(int);
typedef F3 = int Function(double);

@pragma('dart2js:noInline')
id(x) => x;

main() {
  var f1 = F1;
  var f2 = F2;
  var f3 = F3;
  Expect.isTrue(f1 == f2);
  var result12 = identical(f1, f2);
  Expect.isFalse(f1 == f3);
  Expect.isFalse(identical(f1, f3));
  Expect.isFalse(f2 == f3);
  Expect.isFalse(identical(f2, f3));

  var g1 = id(F1);
  var g2 = id(F2);
  var g3 = id(F3);
  Expect.isTrue(g1 == g2);
  Expect.equals(result12, identical(g1, g2));
  Expect.isFalse(g1 == g3);
  Expect.isFalse(identical(g1, g3));
  Expect.isFalse(g2 == g3);
  Expect.isFalse(identical(g2, g3));
}
