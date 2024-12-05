// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingOverrideOfMustBeOverriddenTest);
  });
}

@reflectiveTest
class MissingOverrideOfMustBeOverriddenTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_field() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 86, 1),
    ]);
  }

  test_field_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;

  @mustBeOverridden
  void m() {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO, 121, 1,
          messageContains: ["'f'", "'m'"]),
    ]);
  }

  test_field_overriddenWithField() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  int f = 0;
}
''');
  }

  test_field_overriddenWithGetterSetterPair() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  int get f => 0;

  void set f(int value) {}
}
''');
  }

  test_field_overriddenWithOnlyGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
  int get f => 0;
}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 86, 1),
    ]);
  }

  test_finalField_overriddenWithOnlyGetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  final int f = 0;
}

class B extends A {
  int get f => 0;
}
''');
  }

  test_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 91, 1),
    ]);
  }

  test_getter_overriddenWithField() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}

class B extends A {
  int f = 0;
}
''');
  }

  test_getter_overriddenWithGetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}

class B extends A {
  int get f => 0;
}
''');
  }

  test_method_directMixin() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 87, 1),
    ]);
  }

  test_method_directSuperclass() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 87, 1),
    ]);
  }

  test_method_directSuperclass_three() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}

  @mustBeOverridden
  void n() {}

  @mustBeOverridden
  void o() {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS, 157,
          1),
    ]);
  }

  test_method_directSuperclass_two() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}

  @mustBeOverridden
  void n() {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO, 122, 1),
    ]);
  }

  test_method_hasAbstractOverride_isOkBecauseNotConcreteClass() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

abstract class B extends A {
  void m();
}
''');
  }

  test_method_hasConcreteOverride() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {
  void m() {}
}
''');
  }

  test_method_hasNoSuchMethod() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {
  dynamic noSuchMethod(Invocation invocation) => null;
}
''');
  }

  test_method_indirectMixin() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {
  void m() {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 121, 1),
    ]);
  }

  test_method_indirectSuperclass() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {
  void m() {}
}

class C extends B {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 124, 1),
    ]);
  }

  test_method_indirectSuperclass_oneErrorPerName() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {
  @mustBeOverridden
  void m() {}
}

class C extends B {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 144, 1),
    ]);
  }

  test_method_mixinApplication() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

mixin A {
  @mustBeOverridden
  void m() {}
}

class B = Object with A;
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 87, 1),
    ]);
  }

  test_method_notVisible() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void _m() {}
}
''');

    await assertNoErrorsInCode('''
import 'package:test/a.dart';

class B extends A {}
''');
  }

  test_method_overriddenWithMethod_wildcardParams() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class C {
  @mustBeOverridden
  void m(int x) {}
}

class A extends C {
  @override
  void m(int _) {}
}
''');
  }

  test_method_overriddenWithMethod_wildcardParams_preWildcards() async {
    await assertNoErrorsInCode('''
// @dart = 3.4
// (pre wildcard-variables)

import 'package:meta/meta.dart';

class C {
  @mustBeOverridden
  void m(int x) {}
}

class A extends C {
  @override
  void m(int _) {}
}
''');
  }

  test_method_sealedClassIsImplicitlyAbstract() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

sealed class B extends A {}
''');
  }

  test_method_superconstraint_isOkBecauseMixinsAreNotConcrete() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

mixin M on A {}
''');
  }

  test_operator_directSuperclass() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int operator+(int number) => 7;
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 107, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void set f(int value) {}
}

class B extends A {}
''', [
      error(WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE, 100, 1),
    ]);
  }
}
