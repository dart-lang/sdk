// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test that function literals are parsed correctly in initializers.

class A {
  final x;
  static foo(f) => f();

  A.parenthesized(y) : x = (() => y);
  A.stringLiteral(y) : x = "**${() => y}--";
  A.listLiteral(y) : x = [() => y];
  A.mapLiteral(y) : x = {"fun": () => y};
  A.arg(y) : x = foo(() => y);
}

main() {
  var a, f;
  a = new A.parenthesized(499);
  f = a.x;
  Expect.isTrue(f is Function);
  Expect.equals(499, f());

  // The toString of closures is not specified. Just make sure that there is no
  // crash.
  a = new A.stringLiteral(42);
  Expect.isTrue(a.x.startsWith("**"));
  Expect.isTrue(a.x.endsWith("--"));

  a = new A.listLiteral(99);
  f = a.x[0];
  Expect.isTrue(f is Function);
  Expect.equals(99, f());

  a = new A.mapLiteral(314);
  f = a.x["fun"];
  Expect.isTrue(f is Function);
  Expect.equals(314, f());

  a = new A.arg(123);
  Expect.equals(123, a.x);
}
