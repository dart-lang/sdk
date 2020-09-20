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
    isPromoteToNever_noIf(null);
  });

  Expect.throws(() {
    isNotPromoteToNever(null);
  });

  Expect.throws(() {
    isNotPromoteToNever_noIf(null);
  });

  Expect.throws(() {
    equalNullPromoteToNever(() => null);
  });

  Expect.throws(() {
    equalNullPromoteToNever_noIf(() => null);
  });

  Expect.throws(() {
    notEqualNullPromoteToNever(() => null);
  });

  Expect.throws(() {
    notEqualNullPromoteToNever_noIf(() => null);
  });

  Expect.throws(() {
    nullEqualPromoteToNever(() => null);
  });

  Expect.throws(() {
    nullEqualPromoteToNever_noIf(() => null);
  });

  Expect.throws(() {
    nullNotEqualPromoteToNever(() => null);
  });

  Expect.throws(() {
    nullNotEqualPromoteToNever_noIf(() => null);
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

  C.staticField = null;
  Expect.throws(() {
    ifNullAssignStaticGetter_nullableSetter(() => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignField(C(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignGetter_nullableSetter(C(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignGetter_implicitExtension(
        E(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignGetter_explicitExtension(
        E(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex(<int>[null], () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex_nullAware(<int>[null], () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex_nullableSetter(C(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex_implicitExtension(
        E(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignIndex_explicitExtension(
        E(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignSuper(D(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignSuper_nullableSetter(D(null), () => throw "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    ifNullAssignSuperIndex(D(null), () => throw "should not reach");
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
    unnecessaryNullAwareAccess_methodOnObject(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded_methodOnObject(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_methodOnExtension(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded_methodOnExtension(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_methodOnExtension_explicit(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_getter(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded_getter(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_getterOnObject(() => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded_getterOnObject(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_getterOnExtension(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_cascaded_getterOnExtension(
        () => null, "should not reach");
  }, (error) => error != "should not reach");

  Expect.throws(() {
    unnecessaryNullAwareAccess_getterOnExtension_explicit(
        () => null, "should not reach");
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
