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
    if (super.superMethod(/*{}*/ a is int)) {
      /*{a:[{true:int}|int]}*/ a;
    }
    if (this.instanceMethod(/*{}*/ a is int)) {
      /*{a:[{true:int}|int]}*/ a;
    }
  }
}

ifMethodCall(a) {
  if (staticMethod(/*{}*/ a is int)) {
    /*{a:[{true:int}|int]}*/ a;
  }
}

main() {
  ifMethodCall(null);
  new Class().test(null);
}
