// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitReopenTest);
    defineReflectiveTests(ImplicitReopenInducedModifierTest);
  });
}

@reflectiveTest
class ImplicitReopenInducedModifierTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'implicit_reopen';

  test_inducedFinal() async {
    await assertDiagnostics(r'''
final class F {}
sealed class S extends F {}
base class C extends S {}
''', [
      lint(56, 1),
    ]);
  }

  test_inducedFinal_base_interface() async {
    await assertDiagnostics(r'''
base class C {}
interface class D {}
sealed class E extends D implements C {}
base class B extends E {}
''', [
      lint(89, 1),
    ]);
  }

  test_inducedFinal_baseMixin_interface() async {
    await assertDiagnostics(r'''
interface class D {}
base mixin G {}
sealed class H extends D with G {}
base class B extends H {}
''', [
      lint(83, 1),
    ]);
  }

  test_inducedFinal_interface_base_ok() async {
    await assertDiagnostics(r'''
interface class S {}
base class I {}
sealed class A extends S implements I {}
class C extends A {}
''', [
      // No lint.
      error(CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED,
          84, 1),
    ]);
  }

  test_inducedFinal_mixin_finalClass() async {
    await assertDiagnostics(r'''
final class S {}
mixin M {}
sealed class A extends S with M {}
base class B extends A {}
''', [
      lint(74, 1),
    ]);
  }

  test_inducedInterface() async {
    await assertDiagnostics(r'''
interface class I {}
sealed class S extends I {}
class C extends S {}
''', [
      lint(55, 1),
    ]);
  }

  test_inducedInterface_base() async {
    await assertDiagnostics(r'''
interface class I {}
sealed class S extends I {}
base class C extends S {}
''', [
      lint(60, 1),
    ]);
  }

  test_inducedInterface_base_mixin_interface() async {
    await assertDiagnostics(r'''
interface class S {}
mixin M {}
sealed class A extends S with M {}
base class C extends A {}
''', [
      lint(78, 1),
    ]);
  }

  test_inducedInterface_mixin_interface() async {
    await assertDiagnostics(r'''
interface class S {}
mixin M {}
sealed class A extends S with M {}
class C extends A {}
''', [
      lint(73, 1),
    ]);
  }

  test_inducedInterface_twoLevels() async {
    await assertDiagnostics(r'''
interface class I {}
sealed class S extends I {}
sealed class S2 extends S {}
class C extends S2 {}
''', [
      lint(84, 1),
    ]);
  }

  test_subtypingFinalError_ok() async {
    await assertDiagnostics(r'''
final class F {}
sealed class S extends F {}
class C extends S {}
''', [
      // No lint.
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          51, 1),
    ]);
  }
}

@reflectiveTest
class ImplicitReopenTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'implicit_reopen';

  test_class_classFinal_ok() async {
    await assertDiagnostics(r'''
final class F {}

class C extends F {}
''', [
      // No lint.
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          24, 1),
    ]);
  }

  test_class_classInterface() async {
    await assertDiagnostics(r'''
interface class I {}

class C extends I {}
''', [
      lint(28, 1),
    ]);
  }

  test_class_classInterface_outsideLib_ok() async {
    newFile('$testPackageLibPath/a.dart', r'''
interface class I {}
''');

    await assertDiagnostics(r'''
import 'a.dart';

class C extends I {}
''', [
      // No lint.
      error(CompileTimeErrorCode.INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY,
          34, 1),
    ]);
  }

  test_class_classInterface_reopened_ok() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

interface class I {}

@reopen
class C extends I {}
''');
  }

  test_classBase_classFinal() async {
    await assertDiagnostics(r'''
final class F {}

base class B extends F {}
''', [
      lint(29, 1),
    ]);
  }

  test_classBase_classInterface() async {
    await assertDiagnostics(r'''
interface class I {}

base class B extends I {}
''', [
      lint(33, 1),
    ]);
  }

  test_classFinal_classInterface_ok() async {
    await assertNoDiagnostics(r'''
interface class I {}

final class C extends I {}
''');
  }

  test_classMixin_classInterface_ok() async {
    await assertDiagnostics(r'''
interface class I {}

mixin class M extends I {}
''', [
      // No lint.
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT, 44,
          1),
    ]);
  }

  test_classTypeAlias_class_classInterface() async {
    await assertDiagnostics(r'''
interface class I {}
mixin M {}
class C = I with M;
''', [
      lint(38, 1),
    ]);
  }

  test_classTypeAlias_classBase_classFinal() async {
    await assertDiagnostics(r'''
final class C {}
mixin M {}
base class D = C with M;
''', [
      lint(39, 1),
    ]);
  }

  test_classTypeAlias_classBase_classFinal_reopened() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

final class C {}
mixin M {}
@reopen
base class D = C with M;
''');
  }

  test_mixin_classInterface_ok() async {
    await assertDiagnostics(r'''
interface class I {}

mixin M extends I {}
''', [
      // No lint.
      error(ParserErrorCode.EXPECTED_INSTEAD, 30, 7),
    ]);
  }
}
