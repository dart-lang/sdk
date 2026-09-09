// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExhaustiveCasesTestLanguage219);
    defineReflectiveTests(ExhaustiveCasesTest);
  });
}

abstract class BaseExhaustiveCasesTest extends LintRuleTest {
  final _enumWithMissingCaseSource = r'''
enum ActualEnum { e, f }

void f(ActualEnum value) {
  switch (value) {
    case ActualEnum.e:
  }
}
''';

  @override
  String get lintRule => LintNames.exhaustive_cases;

  Future<void> test_class_enumLike_allCases() async {
    await assertNoDiagnostics(r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void ok(E e) {
  switch (e) {
    case E.e:
      break;
    case E.f:
      break;
    case E.g:
      break;
  }
}
''');
  }

  Future<void> test_class_enumLike_deprecatedAliases() async {
    await assertDiagnostics(
      r'''
class DeprecatedFields {
  final int i;
  const DeprecatedFields._(this.i);

  @deprecated
  static const oldFoo = newFoo;
  static const newFoo = DeprecatedFields._(1);
  static const bar = DeprecatedFields._(2);
  static const baz = DeprecatedFields._(3);
}

void dep(DeprecatedFields e) {
  switch (e) {
    case DeprecatedFields.newFoo:
      break;
    case DeprecatedFields.bar:
      break;
    case DeprecatedFields.baz:
      break;
  }

  switch (e) {
    case DeprecatedFields.newFoo:
      break;
    case DeprecatedFields.baz:
      break;
  }

  switch (e) {
    case DeprecatedFields.oldFoo:
      break;
    case DeprecatedFields.bar:
      break;
    case DeprecatedFields.baz:
      break;
  }
}
''',
      [lint(449, 10)],
    );
  }

  Future<void> test_class_enumLike_importPrefixed() async {
    newFile('$testPackageLibPath/e.dart', '''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}
''');

    await assertDiagnostics(
      r'''
import 'e.dart' as prefixed;

void e(prefixed.E e) {
  switch(e) {
    case prefixed.E.e :
      print('e');
      break;
    case prefixed.E.f :
      print('e');
  }
}
''',
      [lint(55, 9)],
    );
  }

  Future<void> test_class_enumLike_missingCase() async {
    await assertDiagnostics(
      r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void e(E e) {
  switch (e) {
    case E.e:
      break;
    case E.f:
  }
}
''',
      [lint(147, 10)],
    );
  }

  Future<void> test_class_enumLike_parenthesizedCases() async {
    await assertNoDiagnostics(r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void okParenthesized(E e) {
  switch (e) {
    case (E.e):
      break;
    case ((E.f)):
      break;
    case (E.g):
      break;
  }
}
''');
  }

  Future<void> test_class_enumLike_withDefault() async {
    await assertNoDiagnostics(r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void okDefault(E e) {
  switch (e) {
    case E.e:
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_class_notEnumLike_publicConstructor() async {
    await assertNoDiagnostics(r'''
class PublicCons {
  const PublicCons();
  static const e = PublicCons();
  static const f = PublicCons();
}

void p(PublicCons e) {
  switch (e) {
    case PublicCons.e:
  }
}
''');
  }

  Future<void> test_class_notEnumLike_singleConstant() async {
    await assertNoDiagnostics(r'''
class TooFew {
  const TooFew._();

  static const e = TooFew._();
}

void t(TooFew e) {
  switch (e) {
    case TooFew.e:
  }
}
''');
  }

  Future<void> test_class_notEnumLike_subclassed() async {
    await assertNoDiagnostics(r'''
class Subclassed {
  const Subclassed._();

  static const e = Subclassed._();
  static const f = Subclassed._();
  static const g = Subclassed._();
}

class Subclass extends Subclassed {
  Subclass() : super._();
}

void s(Subclassed e) {
  switch (e) {
    case Subclassed.e:
  }
}
''');
  }
}

@reflectiveTest
class ExhaustiveCasesTest extends BaseExhaustiveCasesTest {
  Future<void> test_class_enumLike_dotShorthand_missingCase() async {
    await assertDiagnosticsFromMarkup(r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void fn(E e) {
  [!switch (e)!] {
    case .e:
      break;
    case .f:
  }
}
''');
  }

  Future<void> test_class_enumLike_dotShorthand_withDefault() async {
    await assertNoDiagnostics(r'''
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void fn(E e) {
  switch (e) {
    case .e:
      break;
    default:
      break;
  }
}
''');
  }

  Future<void> test_class_notEnumLike_publicConstructor_dotShorthand() async {
    await assertNoDiagnostics(r'''
class PublicCons {
  const PublicCons();
  static const e = PublicCons();
  static const f = PublicCons();
}

void p(PublicCons e) {
  switch (e) {
    case .e:
  }
}
''');
  }

  Future<void> test_class_notEnumLike_singleConstant_dotShorthand() async {
    await assertNoDiagnostics(r'''
class TooFew {
  const TooFew._();

  static const e = TooFew._();
}

void t(TooFew e) {
  switch (e) {
    case .e:
  }
}
''');
  }

  Future<void> test_class_notEnumLike_subclassed_dotShorthand() async {
    await assertNoDiagnostics(r'''
class Subclassed {
  const Subclassed._();

  static const e = Subclassed._();
  static const f = Subclassed._();
  static const g = Subclassed._();
}

class Subclass extends Subclassed {
  Subclass() : super._();
}

void s(Subclassed e) {
  switch (e) {
    case .e:
  }
}
''');
  }

  test_enum_missingCase() async {
    await assertDiagnostics(_enumWithMissingCaseSource, [
      error(diag.nonExhaustiveSwitchStatement, 55, 6),
    ]);
  }

  Future<void> test_extensionType_enumLike_allCases() async {
    await assertNoDiagnostics(r'''
extension type const E._(int i) {
  static const E a = E._(1);
  static const E b = E._(2);
}

void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
  }
}
''');
  }

  Future<void> test_extensionType_enumLike_deprecatedAlias() async {
    await assertNoDiagnostics(r'''
extension type const E._(int i) {
  @deprecated
  static const E oldA = a;
  static const E a = E._(1);
  static const E b = E._(2);
}

void f(E e) {
  switch (e) {
    case E.oldA:
      break;
    case E.b:
  }
}
''');
  }

  Future<void> test_extensionType_enumLike_dotShorthand_missingCase() async {
    await assertDiagnosticsFromMarkup(r'''
extension type const E._(int i) {
  static const E a = E._(1);
  static const E b = E._(2);
}

void f(E e) {
  [!switch (e)!] {
    case .a:
  }
}
''');
  }

  Future<void> test_extensionType_enumLike_missingCase() async {
    await assertDiagnosticsFromMarkup(r'''
extension type const E._(int i) {
  static const E a = E._(1);
  static const E b = E._(2);
  static const E c = E._(3);
}

void f(E e) {
  [!switch (e)!] {
    case E.a:
      break;
    case E.b:
  }
}
''');
  }

  Future<void> test_extensionType_enumLike_withDefault() async {
    await assertNoDiagnostics(r'''
extension type const E._(int i) {
  static const E a = E._(1);
  static const E b = E._(2);
}

void f(E e) {
  switch (e) {
    case E.a:
      break;
    default:
  }
}
''');
  }

  Future<void> test_extensionType_notEnumLike_publicConstructor() async {
    await assertNoDiagnostics(r'''
extension type const E(int i) {
  static const E a = E(1);
  static const E b = E(2);
}

void f(E e) {
  switch (e) {
    case E.a:
  }
}
''');
  }

  Future<void> test_extensionType_notEnumLike_singleConstant() async {
    await assertNoDiagnostics(r'''
extension type const E._(int i) {
  static const E a = E._(1);
}

void f(E e) {
  switch (e) {}
}
''');
  }
}

@reflectiveTest
class ExhaustiveCasesTestLanguage219 extends BaseExhaustiveCasesTest
    with LanguageVersion219Mixin {
  test_enum_missingCase() async {
    await assertDiagnostics(_enumWithMissingCaseSource, [
      error(diag.missingEnumConstantInSwitch, 55, 14),
    ]);
  }
}
