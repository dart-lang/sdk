// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect error - parameter initializer cannot initialize static fields.

class A {
   A(this.x) { } // expect error - cannot use param initializer to initialize a static field.
   static Object x;
}
