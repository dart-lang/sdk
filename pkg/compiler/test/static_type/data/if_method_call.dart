// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

staticMethod(a) => true;

class Super {
  superMethod(a) => true;
}

class Class extends Super {
  instanceMethod(a) => true;

  test(a) {
    if (super.superMethod(/*dynamic*/ a is int)) {
      /*dynamic*/ a;
    }
    if (this
        . /*invoke: [Class]->dynamic*/ instanceMethod(/*dynamic*/ a is int)) {
      /*dynamic*/ a;
    }
  }
}

ifMethodCall(a) {
  if (staticMethod(/*dynamic*/ a is int)) {
    /*dynamic*/ a;
  }
}

main() {
  ifMethodCall(null);
  Class(). /*invoke: [Class]->dynamic*/ test(null);
}
