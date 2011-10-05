// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that a static field in an initializer is an error.

class A {
  static var a;
  A() : this.a = 1 {}
}
