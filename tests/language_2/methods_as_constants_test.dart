// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

topLevelMethod() => 't';

const topLevelFieldForTopLevelMethod = topLevelMethod;
const topLevelFieldForStaticMethod = A.staticMethod;

class A {
  final Function closure;
  const A(this.closure);
  const A.defaultTopLevel([this.closure = topLevelMethod]);
  const A.defaultStatic([this.closure = staticMethod]);
  const A.defaultStatic2([this.closure = A.staticMethod]);
  run() => closure();

  static staticMethod() => 's';
  static const staticFieldForStaticMethod = staticMethod;
  static const staticFieldForTopLevelMethod = topLevelMethod;
}

main() {
  Expect.equals('t', (const A(topLevelMethod)).run());
  Expect.equals('s', (const A(A.staticMethod)).run());
  Expect.equals('t', (const A.defaultTopLevel()).run());
  Expect.equals('s', (const A.defaultStatic()).run());
  Expect.equals('s', (const A.defaultStatic2()).run());
  Expect.equals('t', (new A.defaultTopLevel()).run());
  Expect.equals('s', (new A.defaultStatic()).run());
  Expect.equals('s', (new A.defaultStatic2()).run());
  Expect.equals('t', topLevelFieldForTopLevelMethod());
  Expect.equals('s', topLevelFieldForStaticMethod());
  Expect.equals('t', A.staticFieldForTopLevelMethod());
  Expect.equals('s', A.staticFieldForStaticMethod());

  var map = const {'t': topLevelMethod, 's': A.staticMethod};
  Expect.equals('t', map['t']());
  Expect.equals('s', map['s']());
}
