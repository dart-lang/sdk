// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that a super field in an initializer is an error.

class B {
  var a;
  B() : this.a = 1 {}
}

class A extends B {
  A() : super(), this.a = 1 {}
}
