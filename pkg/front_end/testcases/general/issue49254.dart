// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C3 extends B3 {
  C3(super.bar) : super();
}

class B3 extends A3 {
  var bar = A3.initializeFoo; // Error.
  B3(this.bar) : super();
}

class A3 {
  var foo = C3.new;
  A3();
  A3.initializeFoo(this.foo);
}
