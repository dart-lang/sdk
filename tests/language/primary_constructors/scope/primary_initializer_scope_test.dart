// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The primary initializer scope is the current scope for the initializing
// expression, if any, of each non-late instance variable declaration.
//
// It is also the current scope for the initializer list in the body part of the
// primary constructor, if any.

// SharedOptions=--enable-experiment=primary-constructors

import "package:expect/expect.dart";

class InitializingExpression(int x) {
  int y = x;
  int z = x + 1;
}

class Initializer(final int x, int y) {
  final int z;
  this : z = x + y;
}

class Shadow(int x) {
  // `x` here refers to the parameter `x`, not the field `x` below.
  int y = x;
  int x = 0;
}

class Late(int x) {
  // This `x` refers to the field `x`, not the parameter `x`.
  late int y = x;
  int x = 100;
}

String t = 'top level';

class TopLevel(String t) {
  String instance = t;
  late String lateInstance = t;
}

main() {
  var initExpr = InitializingExpression(10);
  Expect.equals(10, initExpr.y);
  Expect.equals(11, initExpr.z);

  var initializer = Initializer(10, 20);
  Expect.equals(30, initializer.z);

  var shadow = Shadow(20);
  Expect.equals(20, shadow.y);
  Expect.equals(0, shadow.x);

  var late = Late(40);
  Expect.equals(100, late.y);

  var topLevel = TopLevel('parameter');
  Expect.equals(topLevel.instance, 'parameter');
  Expect.equals(topLevel.lateInstance, 'top level');
}
