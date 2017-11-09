// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=warning*/

class A {
  String operator +(int i) => '';
}

test(int i, String s, A a) {
  i = 1;
  /*@warning=InvalidAssignment*/ i = s;
  i ??= 1;
  /*@warning=InvalidAssignment*/ i ??= s;
  a = new A();
  /*@warning=InvalidAssignment*/ a += 1;
}

main() {}
