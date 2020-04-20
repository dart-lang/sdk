// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 17382.

import 'package:expect/expect.dart';

var mCalled = false;

m(x) {
  mCalled = true;
  return x;
}

main() {
  try {
    tl(m(0)); /*@compile-error=unspecified*/
  } catch (e) {}
  Expect.isTrue(mCalled);
}
