// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  /*bl*/
  Foo foo = new Foo();
  foo.foo();
  /*nbb:0:1*/
}

class Foo {
  foo() {
    return /*bc:1*/ bar() + /*bc:2*/ baz /*nbc*/ ();
    /*nbb:0:1*/
  }

  bar() {
    return 42;
    /*nbb:0:1*/
  }

  baz() {
    return 42;
    /*nbb:0:1*/
  }
}
