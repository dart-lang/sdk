// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests we can still use `sealed` as an identifier.

import "package:expect/expect.dart";

class SealedField {
  int sealed = 0;
}

class SealedMethod {
  int sealed() => 1;
  int foo(int sealed) => sealed;
  int? foo1([int? sealed]) => sealed;
  int? foo2({int? sealed}) => sealed;
}

class SealedVariable {
  int foo() {
    var sealed = 2;
    return sealed;
  }
}

main() {
  var sealedField = SealedField();
  var sealedMethod = SealedMethod();
  var sealedVariable = SealedVariable();

  Expect.equals(0, sealedField.sealed);

  Expect.equals(1, sealedMethod.sealed());
  Expect.equals(1, sealedMethod.foo(1));
  Expect.equals(1, sealedMethod.foo1(1));
  Expect.equals(1, sealedMethod.foo2(sealed: 1));

  Expect.equals(2, sealedVariable.foo());
}
