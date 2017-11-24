// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new Foo();
  // Comment to push the ending brace back a bit.
/*s:3*/
}

class Foo {
  Foo() {
    /*bl*/ /*s:1*/ print('hi');
    // Comment to push the ending brace back a bit.
    /*s:2*/
  }
}
