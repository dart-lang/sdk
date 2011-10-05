// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(x) : this.foo(x);
  A.foo(x) : this.bar(x, x * 2);
  A.bar(x,y) : this(x + y);
}
