// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var staticClosure;
int staticMethod() => 42;

class B {
  var instanceClosure;
  var nullField;
  int instanceMethod() => 43;
}

checkUntyped(closure) {
  Expect.isTrue(closure is Function);
}

checkTyped(int closure()) {
  Expect.isTrue(closure is Function);
}

checkTypedNull(int closure()) {
  Expect.isFalse(closure is Function);
}

checkUntypedNull(closure) {
  Expect.isFalse(closure is Function);
}

main() {
  staticClosure = () => 44;
  B b = new B();
  b.instanceClosure = () => 45;

  closureStatement() => 46;
  var closureExpression = () => 47;

  checkUntyped(staticClosure);
  checkTyped(staticClosure);

  checkUntyped(staticMethod);
  checkTyped(staticMethod);

  checkUntyped(b.instanceClosure);
  checkTyped(b.instanceClosure);

  checkUntyped(b.instanceMethod);
  checkTyped(b.instanceMethod);

  checkUntyped(closureStatement);
  checkTyped(closureStatement);

  checkUntyped(closureExpression);
  checkTyped(closureExpression);

  checkTypedNull(b.nullField);
  checkUntypedNull(b.nullField);
}
