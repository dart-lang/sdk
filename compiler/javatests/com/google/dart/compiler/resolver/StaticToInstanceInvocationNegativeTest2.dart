// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// case 2 - qualified - expect failure.

class A {
  static foo() { this.bar(); }
  bar() { }
}
