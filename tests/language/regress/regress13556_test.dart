// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash when resolving the
// @B() annotation.

class A {
  final a;
  const A({this.a});
}

class B extends A {
  const B();
}

@B()
main() {}
