// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
    int a;
    A(this.a);
    A.foo(int x, int y);
}

class B extends A {
    int b1;
    int b2;
    B(int x) : this.b1 = x, super(x), this.b2 = x, super.foo(x, x);
}
