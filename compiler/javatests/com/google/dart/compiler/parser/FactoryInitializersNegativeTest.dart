// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect syntax errors: Factory constructors cannot have initializers.

class A {
  int x;
  int y;
  factory A.foo(x,y) : this.x = 1 {
  }
}
