// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// TODO(rnystrom): This test should be renamed since now it's just about
// testing that constructing an abstract class generates an error.

abstract class A {
  A() {}
}

void main() {
  /*@compile-error=unspecified*/ new A();
}