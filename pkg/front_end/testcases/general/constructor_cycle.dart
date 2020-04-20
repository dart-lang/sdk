// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.foo() : this.bar();
  A.bar() : this.foo();
  A.baz() : this.foo();
  A() : this();
}

main() {}
