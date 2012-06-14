// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bar() => {'bar' : 21};
foo() => 'bar';

main() {
  var f = foo();
  // The following code will bailout because bar() does not return an array.
  int a = bar()[f];
  // The aborting if.
  if (a == 42) {
    Expect.fail('Should not enter here');
    return;
  }
  Expect.equals(21, a);
}
