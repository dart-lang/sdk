// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect failure - final constructor redirects to non-const constructor.

class A {
  const A(x) : this.foo(x);
  A.foo(this.x) { }
  var x;
}
