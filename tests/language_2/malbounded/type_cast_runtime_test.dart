// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}
class Malbounded1 implements Super

  {}
class Malbounded2 extends Super

  {}

main() {
  var m = new Malbounded1();
  Expect.throwsTypeError(() => m as Super<int>);
  var s = new Super<int>();
  Expect.throwsTypeError(() => s as Malbounded1);
  Expect.throwsTypeError(() => s as Malbounded2);
  s as Super

      ;
}
