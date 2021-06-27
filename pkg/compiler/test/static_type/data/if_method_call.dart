// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

staticMethod(a) => true;

class Super {
  superMethod(a) => true;
}

class Class extends Super {
  instanceMethod(a) => true;

  test(a) {
    if (super.superMethod(/*spec.dynamic*/ a is int)) {
      /*spec.int*/ a;
    }
    if (this. /*spec.invoke: [Class]->dynamic*/ instanceMethod(
        /*spec.dynamic*/ a is int)) {
      /*spec.int*/ a;
    }
  }
}

ifMethodCall(a) {
  if (staticMethod(/*spec.dynamic*/ a is int)) {
    /*spec.int*/ a;
  }
}

main() {
  ifMethodCall(null);
  new Class(). /*spec.invoke: [Class]->dynamic*/ test(null);
}
