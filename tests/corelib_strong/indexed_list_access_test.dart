// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Check that indexed access to lists throws correct exception if index
// is not int.

main() {
  checkList(new List(10));
  var growable = new List();
  growable.add(1);
  growable.add(1);
  checkList(growable);
}

checkList(var list) {
  // Check unoptimized.
  Expect.isFalse(checkCatch(getIt, list, 1));
  Expect.isTrue(checkCatch(getIt, list, "hi"));
  Expect.isFalse(checkCatch(putIt, list, 1));
  Expect.isTrue(checkCatch(putIt, list, "hi"));
  // Optimize 'getIt' and 'putIt'.
  for (int i = 0; i < 2000; i++) {
    putIt(list, 1);
    getIt(list, 1);
  }
  Expect.isTrue(checkCatch(getIt, list, "hi"));
  Expect.isTrue(checkCatch(putIt, list, "hi"));
}

checkCatch(var f, var list, var index) {
  try {
    f(list, index);
  } on ArgumentError catch (e) {
    return true;
  } on TypeError catch (t) {
    return true; // thrown in type checked mode.
  }
  return false;
}

getIt(var a, var i) {
  return a[i];
}

putIt(var a, var i) {
  a[i] = null;
}
