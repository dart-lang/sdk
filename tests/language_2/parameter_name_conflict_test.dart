// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

foo(t0) {
  var a = t0, b = baz(), c = bar();
  if (t0 == 'foo') {
    // Force a SSA swapping problem where dart2js used to use 't0' as
    // a temporary variable.
    var tmp = c;
    c = b;
    b = tmp;
  }

  Expect.equals('foo', a);
  Expect.equals('foo', t0);
  Expect.equals('bar', b);
  Expect.equals('baz', c);
}

bar() => 'bar';
baz() => 'baz';

main() {
  foo('foo');
}
