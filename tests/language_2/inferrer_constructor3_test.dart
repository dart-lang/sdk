// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to optimistically infer the
// wrong types for fields because of generative constructors being
// inlined.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

class A {
  var field;
  A(this.field);
}

dynamic c = () => new List(42)[0];

main() {
  bar();
  // Defeat type inferencing.
  new A(c());
  doIt();
  bar();
}

@DontInline()
doIt() {
  () => 42;
  var c = new A(null);
  Expect.throwsNoSuchMethodError(() => c.field + 42);
}

@DontInline()
bar() {
  () => 42;
  return inlineLevel1();
}

inlineLevel1() {
  return inlineLevel2();
}

inlineLevel2() {
  return inlineLevel3();
}

inlineLevel3() {
  return inlineLevel4();
}

inlineLevel4() {
  return new A(42);
}
