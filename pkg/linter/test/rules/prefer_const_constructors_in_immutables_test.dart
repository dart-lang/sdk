// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstConstructorsInImmutablesTest);
  });
}

@reflectiveTest
class PreferConstConstructorsInImmutablesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_constructors_in_immutables';

  test_assertInitializer_canBeConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class C {
  C.named(a) : assert(a != null);
}
''', [
      lint(57, 1),
    ]);
  }

  test_assertInitializer_cannotBeConst() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class C {
  C.named(a) : assert(a.toString() == 'string');
}
''');
  }

  test_implicitSuperConstructorInvocation_undefined() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class A {
  const A.named();
}

class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          99, 1),
    ]);
  }

  test_returnOfInvalidType() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class F {
  factory F.fc() => null;
}
''', [
      // No lint
      error(
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR, 75, 4),
    ]);
  }
}
