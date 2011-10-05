// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect error - parameter initializer is not valid in ordinary methods.

class A {
   A(this.x) { }
   A.myctor(this.x) { }
   foo(Object y, this.x) { } // expect to fail.
   Object x;
}
