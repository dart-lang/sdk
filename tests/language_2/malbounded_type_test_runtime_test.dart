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
  Expect.isFalse(m is Super<int>);
  var s = new Super<int>();
  Expect.isFalse(s is Malbounded1);
  Expect.isFalse(s is Malbounded2);
  Expect.isTrue(s is Super

      );
}
