// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests we can still use `base` as an identifier.

import 'package:expect/expect.dart';

class base {
  int x = 0;
}

class BaseField {
  int base = 0;
}

class BaseMethod {
  int base() => 1;
  int foo(int base) => base;
  int? foo1([int? base]) => base;
  int? foo2({int? base}) => base;
}

class BaseVariable {
  int foo() {
    var base = 2;
    return base;
  }
}

class BaseAsType {
  int foo(base x) => x.x;
  base foo1 = base();
}

main() {
  var baseClass = base();
  var baseField = BaseField();
  var baseMethod = BaseMethod();
  var baseVariable = BaseVariable();
  var baseAsType = BaseAsType();

  Expect.equals(0, baseClass.x);

  Expect.equals(0, baseField.base);

  Expect.equals(1, baseMethod.base());
  Expect.equals(1, baseMethod.foo(1));
  Expect.equals(1, baseMethod.foo1(1));
  Expect.equals(1, baseMethod.foo2(base: 1));

  Expect.equals(2, baseVariable.foo());

  Expect.equals(0, baseAsType.foo(base()));
  Expect.equals(0, baseAsType.foo1.x);
}
