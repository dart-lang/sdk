// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

class A<T extends num> { }

class B<T> {
  test() {
    new A() as A<T>;  /// static type warning
  }
}

main () {
  var b = new B<String>();
  if (isCheckedMode()) {
    Expect.throws(() => b.test(), (e) => e is TypeError);
  } else {
    b.test();
  }
}
