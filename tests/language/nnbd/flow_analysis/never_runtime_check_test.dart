// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// Requirements=nnbd-weak

// Validates that mixed-mode programs have runtime checks to ensure that code
// that should be unreachable is not executed even when a legacy types causes
// the unreachable code to be reached.

import 'package:expect/expect.dart';

import 'never_runtime_check_nnbd.dart';

class AImpl implements A {
  Never get getter => null;
  Never method() => null;
  Never operator +(int other) => null;
  Never operator [](int other) => null;
}

main() {
  Expect.throws(() {
    neverParameter(null);
  });

  Expect.throws(() {
    NeverField().n = null;
  });

  Expect.throws(() {
    // Write.
    topLevelNever = null;
  });

  Expect.throws(() {
    // Read.
    topLevelNever;
  });

  Expect.throws(() {
    NeverField.initializingFormal(null);
  });

  Expect.throws(() {
    isPromoteToNever(null);
  });

  Expect.throws(() {
    isNotPromoteToNever(null);
  });

  Expect.throws(() {
    equalNullPromoteToNever(() => null);
  });

  Expect.throws(() {
    notEqualNullPromoteToNever(() => null);
  });

  Expect.throws(() {
    nullEqualPromoteToNever(() => null);
  });

  Expect.throws(() {
    nullNotEqualPromoteToNever(() => null);
  });

  Expect.throws(() {
    unnecessaryIfNull(() => null, () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignLocal(null, () => throw "should not reach");
  }, (error) => error != "should not reach");

  C.staticField = null;
  Expect.throws(() {
    ifNullAssignStatic(() => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignField(C(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex(<int>[null], () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignSuper(D(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignNullAwareField(C(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.equals(
      ifNullAssignNullAwareField(null, () => throw "should not reach"), null);

  C.staticField = null;
  Expect.throws(() {
    ifNullAssignNullAwareStatic(() => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    getterReturnsNever(AImpl());
  });

  Expect.throws(() {
    methodReturnsNever(AImpl());
  });

  Expect.throws(() {
    operatorReturnsNever(AImpl());
  });

  Expect.throws(() {
    indexReturnsNever(AImpl());
  });

  Expect.throws(() {
    returnsNeverInExpression(AImpl());
  });

  Expect.throws(() {
    returnsNeverInVariable(AImpl());
  });

  Expect.throws(() {
    switchOnBool(null);
  });

  Expect.throws(() {
    switchOnEnum(null);
  });
}
