// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The body of a primary constructor body uses the primary parameter scope.
// Instance variables are accessable in this scope, but not any declaring
// parameters, super parameters, or initializing formals.

// SharedOptions=--enable-experiment=primary-constructors

import "package:expect/expect.dart";

class C1(var int x) {
  this {
    x++;
  }
}

class C2(var String x) {
  String Function() captureAtDeclaration = () => x;
  String Function() captureInInitializer;
  String Function()? captureInBody;

  this : captureInInitializer = (() => x) {
    captureInBody = () => x;
  }
}

main() {
  var c1 = C1(1);
  Expect.equals(c1.x, 2);

  var c2 = C2('old');
  Expect.equals(c2.captureAtDeclaration(), 'old');
  Expect.equals(c2.captureInInitializer(), 'old');
  Expect.equals(c2.captureInBody!(), 'old');
  c2.x = 'new';
  Expect.equals(c2.captureAtDeclaration(), 'old');
  Expect.equals(c2.captureInInitializer(), 'old');
  Expect.equals(c2.captureInBody!(), 'new');
}
