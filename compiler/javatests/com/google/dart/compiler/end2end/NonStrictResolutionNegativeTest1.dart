// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// uses experimental flag: --warn_no_such_type that allows compilation 
// to succeed even when types fail to resolve. in the case below, the 
// application should throw a runtime error.

class A {
  A();
}

main() {
  A a = new A();
  Expect.equals(a.foo(123), 1);
}
