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
  Expect.equals(42, neverParameter(null));

  var neverField = NeverField.initializingFormal(null);
  // Write.
  Expect.equals(null, neverField.n = null);
  // Read.
  Expect.equals(null, neverField.n);

  // Write.
  Expect.equals(null, topLevelNever = null);
  // Read.
  Expect.equals(null, topLevelNever);

  Expect.isFalse(isPromoteToNever(null));
  Expect.isFalse(isPromoteToNever_noIf(null));
  Expect.isTrue(isNotPromoteToNever(null));
  Expect.isTrue(isNotPromoteToNever_noIf(null));
  Expect.equals(42, equalNullPromoteToNever(() => null));
  Expect.equals(42, equalNullPromoteToNever_noIf(() => null));
  Expect.equals(42, notEqualNullPromoteToNever(() => null));
  Expect.equals(42, notEqualNullPromoteToNever_noIf(() => null));
  Expect.equals(42, nullEqualPromoteToNever(() => null));
  Expect.equals(42, nullEqualPromoteToNever_noIf(() => null));
  Expect.equals(42, nullNotEqualPromoteToNever(() => null));
  Expect.equals(42, nullNotEqualPromoteToNever_noIf(() => null));
  Expect.equals(42, unnecessaryIfNull(() => null, () => 42));
  Expect.equals(42, ifNullAssignLocal(null, () => 42));

  // Write.
  Expect.equals(null, C.staticField = null);

  // Read.
  Expect.equals(null, C.staticField);

  Expect.equals(42, ifNullAssignStatic(() => 42));
  Expect.equals(42, ifNullAssignStaticGetter_nullableSetter(() => 42));
  Expect.equals(42, ifNullAssignField(C(null), () => 42));
  Expect.equals(42, ifNullAssignGetter_nullableSetter(C(null), () => 42));
  Expect.equals(42, ifNullAssignGetter_implicitExtension(E(null), () => 42));
  Expect.equals(42, ifNullAssignGetter_explicitExtension(E(null), () => 42));
  Expect.equals(42, ifNullAssignIndex(<int>[null], () => 42));
  Expect.equals(42, ifNullAssignIndex_nullAware(<int>[null], () => 42));
  Expect.equals(42, ifNullAssignIndex_nullableSetter(C(null), () => 42));
  Expect.equals(42, ifNullAssignIndex_implicitExtension(E(null), () => 42));
  Expect.equals(42, ifNullAssignIndex_explicitExtension(E(null), () => 42));
  Expect.equals(42, ifNullAssignSuper(D(null), () => 42));
  Expect.equals(42, ifNullAssignSuper_nullableSetter(D(null), () => 42));
  Expect.equals(42, ifNullAssignSuperIndex(D(null), () => 42));
  Expect.equals(42, ifNullAssignNullAwareField(C(null), () => 42));
  Expect.equals(null, ifNullAssignNullAwareField(null, () => 42));
  Expect.equals(42, ifNullAssignNullAwareStatic(() => 42));

  unnecessaryNullAwareAccess(() => null);
  unnecessaryNullAwareAccess_methodOnObject(() => null);
  unnecessaryNullAwareAccess_cascaded_methodOnObject(() => null);
  unnecessaryNullAwareAccess_methodOnExtension(() => null);
  unnecessaryNullAwareAccess_cascaded_methodOnExtension(() => null);
  unnecessaryNullAwareAccess_methodOnExtension_explicit(() => null);
  unnecessaryNullAwareAccess_getter(() => null);
  unnecessaryNullAwareAccess_cascaded(() => null);
  unnecessaryNullAwareAccess_cascaded_getter(() => null);
  unnecessaryNullAwareAccess_getterOnObject(() => null);
  unnecessaryNullAwareAccess_cascaded_getterOnObject(() => null);
  unnecessaryNullAwareAccess_getterOnExtension(() => null);
  unnecessaryNullAwareAccess_cascaded_getterOnExtension(() => null);
  unnecessaryNullAwareAccess_getterOnExtension_explicit(() => null);

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

  Expect.equals(42, switchOnBool(null));

  Expect.throws(() {
    switchOnEnum(null);
  });
}

bool isCalled;

registerCallAndReturnNull() {
  isCalled = true;
  return null;
}

expectCall(void Function() f) {
  isCalled = false;
  f();
  Expect.isTrue(isCalled);
}
