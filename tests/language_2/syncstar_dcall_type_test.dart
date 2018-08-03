// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that TypeErrors happen for sync* methods without creating iterator.

import 'package:expect/expect.dart';

Iterable<int> iota(int n) sync* {
  for (int i = 0; i < n; i++) yield i;
}

class C {
  Iterable<int> add(int n) sync* {
    yield n;
  }
}

main() {
  dynamic f = iota;
  Expect.throwsTypeError(() => f('ten'));
  Expect.throwsTypeError(() => f(4.7));

  dynamic o = new C();
  Expect.throwsTypeError(() => o.add('ten'));
  Expect.throwsTypeError(() => o.add(4.7));
}
