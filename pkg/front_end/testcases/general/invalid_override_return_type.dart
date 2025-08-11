// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}
class B extends A {}

class Super {
  B foo() => new B();
}

class Sub extends Super {
  A foo() => new A();
}
