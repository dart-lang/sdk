// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'regress_22443_lib.dart' deferred as D;
import 'package:expect/expect.dart';

int fooCount = 0;

foo() {
  fooCount++;
  return new D.LazyClass();
}

main() {
  var caughtIt = false;
  try {
    foo();
  } catch (e) {
    caughtIt = true;
  }
  ;
  D.loadLibrary().then((_) {
    foo();
    Expect.isTrue(caughtIt);
    Expect.equals(2, fooCount);
  });
}
