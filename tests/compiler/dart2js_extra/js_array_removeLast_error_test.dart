// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that optimized JSArray removeLast() calls generate the same error as
// dynamically dispatched calls.

import 'package:expect/expect.dart';

@NoInline()
@AssumeDynamic()
confuse(x) => x;

Error getError(action()) {
  try {
    action();
    Expect.fail('must throw');
  } catch (e) {
    return e;
  }
}

main() {
  fault1() {
    return confuse([]).removeLast();
  }

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    // This one should be optimized since [a] is a growable JSArray.
    return a.removeLast();
  }

  var e1 = getError(fault1);
  var e2 = getError(fault2);

  Expect.equals('$e1', '$e2');
}
