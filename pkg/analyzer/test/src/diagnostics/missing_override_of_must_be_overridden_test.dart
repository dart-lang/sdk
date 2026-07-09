// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingOverrideOfMustBeOverriddenTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'f'.
''');
  }

  test_field_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A(@mustBeOverridden var int f);

class B(super.f) extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'f'.
''');
  }

  test_field_method() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;

  @mustBeOverridden
  void m() {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenTwo] Missing a required override of 'm' and 'f'.
''');
  }

  test_field_overriddenWithField() async {
    await resolveTestCodeWithDiagnostics('''
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

  test_field_overriddenWithField_inPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B(var int f) extends A;
''');
  }

  test_field_overriddenWithGetterSetterPair() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}

class B extends A {
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'f'.
  int get f => 0;
}
''');
  }

  test_finalField_overriddenWithOnlyGetter() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'f'.
''');
  }

  test_getter_overriddenWithField() async {
    await resolveTestCodeWithDiagnostics('''
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

  test_getter_overriddenWithField_inPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}

class B(var int f) extends A;
''');
  }

  test_getter_overriddenWithGetter() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_directSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_directSuperclass_three() async {
    await resolveTestCodeWithDiagnostics('''
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
//    ^
// [diag.missingOverrideOfMustBeOverriddenThreePlus] Missing a required override of 'm', 'n', and 1 more.
''');
  }

  test_method_directSuperclass_two() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}

  @mustBeOverridden
  void n() {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenTwo] Missing a required override of 'm' and 'n'.
''');
  }

  test_method_hasAbstractOverride_isOkBecauseNotConcreteClass() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}

class A with M {
  void m() {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_indirectSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

class B extends A {
  void m() {}
}

class C extends B {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_indirectSuperclass_oneErrorPerName() async {
    await resolveTestCodeWithDiagnostics('''
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
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_mixinApplication() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

mixin A {
  @mustBeOverridden
  void m() {}
}

class B = Object with A;
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'm'.
''');
  }

  test_method_notVisible() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void _m() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'package:test/a.dart';

class B extends A {}
''');
  }

  test_method_overriddenWithMethod_wildcardParams() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

sealed class B extends A {}
''');
  }

  test_method_superconstraint_isOkBecauseMixinsAreNotConcrete() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}

mixin M on A {}
''');
  }

  test_operator_directSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int operator+(int number) => 7;
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of '+'.
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void set f(int value) {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of 'f'.
''');
  }

  test_unary_operator() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void operator -() {}
}

class B extends A {}
//    ^
// [diag.missingOverrideOfMustBeOverriddenOne] Missing a required override of '-'.
''');
  }

  test_unary_operator_overriden() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  void operator -() {}
}

class B extends A {
  @override
  void operator -() {}
}
''');
  }
}
