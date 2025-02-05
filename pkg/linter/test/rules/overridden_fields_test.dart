// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverriddenFieldsTest);
  });
}

@reflectiveTest
class OverriddenFieldsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.overridden_fields;

  test_augmentationClass() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class O {
  final a = '';
}

class A extends O { }
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  final a = '';
}
''');

    await assertNoDiagnosticsInFile(a.path);
    await assertDiagnosticsInFile(b.path, [
      lint(45, 1),
    ]);
  }

  test_augmentedField() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class O {
  final a = '';
}

class A extends O {
  @override
  final a = '';
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  augment final a = '';
}
''');

    await assertDiagnosticsInFile(a.path, [
      lint(85, 1),
    ]);
    await assertNoDiagnosticsInFile(b.path);
  }

  test_conflictingFieldAndMethod() async {
    await assertDiagnostics(r'''
class A {
  int x() => 0;
}

class B extends A {
  int x = 9;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 55, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/2874
  test_conflictingStaticAndInstance() async {
    await assertNoDiagnostics(r'''
class A {
  static final String field = 'value';
}

class B extends A {
  String field = 'otherValue';
}
''');
  }

  test_extendingClass_multipleDeclarations() async {
    await assertDiagnostics(r'''
class A {
  int y = 1;
}
class B extends A {
  final x = 1, y = 2;
}
''', [
      lint(60, 1),
    ]);
  }

  test_extendingClass_overridingAbstract() async {
    await assertNoDiagnostics(r'''
abstract class A {
  abstract int x;
}
class B extends A {
  @override
  int x = 1;
}
''');
  }

  test_extendingClass_staticField() async {
    await assertNoDiagnostics(r'''
class A {
  static int x = 1;
}
class B extends A {
  static int x = 2;
}
''');
  }

  test_extendsClass_indirectly() async {
    await assertDiagnostics(r'''
class A {
  int x = 0;
}
class B extends A {}
class C extends B {
  @override
  int x = 1;
}
''', [
      lint(84, 1),
    ]);
  }

  test_externalLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int? public;
}
''');
    await assertDiagnostics(r'''
import 'a.dart';
class B extends A {
  int? public;
}
''', [
      lint(44, 6),
    ]);
  }

  test_externalLibraryWithPrivateField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int? _private;
}
''');
    await assertDiagnostics(r'''
import 'a.dart';
class B extends A {
  int? _private;
}
''', [
      error(WarningCode.UNUSED_FIELD, 44, 8),
    ]);
  }

  test_fieldOverridesGetter() async {
    await assertNoDiagnostics(r'''
class A {
  int get a => 0;
}
class B extends A {
  @override
  int a = 1;
}
''');
  }

  test_implementingClass() async {
    await assertNoDiagnostics(r'''
class A {
  int x = 1;
}
class B implements A {
  @override
  int x = 2;
}
''');
  }

  test_mixingInMixin() async {
    await assertDiagnostics(r'''
mixin M {
  int x = 1;
}
class A with M {
  @override
  int x = 2;
}
''', [
      lint(60, 1),
    ]);
  }

  test_mixingInMixin_overridingAbstract() async {
    await assertNoDiagnostics(r'''
mixin M {
  abstract int x;
}
class A with M {
  @override
  int x = 2;
}
''');
  }

  test_mixinInheritsFromNotObject() async {
    // See: https://github.com/dart-lang/linter/issues/2969
    // Preserves existing testing logic but has so many misuses of mixins that
    // that it's hard to know how much tested logic is intentional.
    await assertDiagnostics(r'''
class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Bad1 extends Base {
  @override
  final x = 1, field = 'ipsum';
}

class GC11 extends Bad1 {
  @override
  Object something = 'done';

  Object gc33 = 'gc33';
}

class GC13 extends Object with Bad1 {
  @override
  Object something = 'done';

  @override
  Object field = 'lint';
}

abstract class GC21 extends GC11 {
  @override
  Object something = 'done';
}

class GC23 extends Object with GC13 {
  @override
  Object something = 'done';

  @override
  Object field = 'lint';
}

abstract class GC31 extends GC13 {
  @override
  Object something = 'done';
}

abstract class GC32 implements GC13 {
  @override
  Object something = 'done';
}

class GC33 extends GC21 with GC13 {
  @override
  Object something = 'done';

  @override
  Object gc33 = 'yada';
}

class GC34 extends GC33 {
  @override
  var x = 3;

  @override
  Object gc33 = 'yada';
}
''', [
      error(WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD, 120, 1),
      lint(127, 5),
      lint(194, 9),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 273, 4),
      lint(301, 9),
      lint(343, 5),
      lint(418, 9),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 472, 4),
      lint(500, 9),
      lint(542, 5),
      lint(617, 9),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 751, 4),
      lint(779, 9),
      lint(821, 4),
      lint(883, 1),
      lint(912, 4),
    ]);
  }

  test_mixinSuperclassConstraint() async {
    await assertDiagnostics(r'''
class A {
  int x = 1;
}
mixin M on A {
  @override
  final x = 1;
}
''', [
      lint(60, 1),
    ]);
  }

  test_overridingAbstractField() async {
    await assertNoDiagnostics(r'''
abstract class A {
  abstract int x;
}

class B extends A {
  @override
  int x = 1;
}
''');
  }

  test_privateFieldInSameLibrary() async {
    await assertDiagnostics(r'''
class A {
  int _x = 0;
}

class B extends A {
  int _x = 9;
}
''', [
      error(WarningCode.UNUSED_FIELD, 16, 2),
      lint(53, 2),
      error(WarningCode.UNUSED_FIELD, 53, 2),
    ]);
  }

  test_publicFieldInSameLibrary() async {
    await assertDiagnostics(r'''
class A {
  int x = 0;
}

class B extends A {
  int x = 9;
}
''', [
      lint(52, 1),
    ]);
  }

  test_recursiveInterfaceInheritance() async {
    // Produces a recursive_interface_inheritance diagnostic.
    await assertDiagnostics(r'''
class A extends B {}
class B extends A {
  int field = 0;
}
''', [
      // No lint
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
  }
}
