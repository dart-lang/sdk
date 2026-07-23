// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateEnumConstantTest);
  });
}

@reflectiveTest
class CreateEnumConstantTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createEnumConstant;

  Future<void> test_add() async {
    await resolveTestCode('''
enum E {ONE}

E e() {
  return E.TWO;
}
''');
    await assertHasFix('''
enum E {ONE, TWO}

E e() {
  return E.TWO;
}
''', matchFixMessage: "Create enum constant 'TWO'");
  }

  Future<void> test_add_dotShorthand() async {
    await resolveTestCode('''
enum E { ONE }

E e() {
  return .TWO;
}
''');
    await assertHasFix('''
enum E { ONE, TWO }

E e() {
  return .TWO;
}
''', matchFixMessage: "Create enum constant 'TWO'");
  }

  Future<void> test_differentLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E {ONE}
''');

    await resolveTestCode('''
import 'a.dart';

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {ONE, TWO}
''', target: '$testPackageLibPath/a.dart');
  }

  Future<void> test_differentLibrary_dotShorthand() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E { ONE }
''');

    await resolveTestCode('''
import 'a.dart';

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E { ONE, TWO }
''', target: '$testPackageLibPath/a.dart');
  }

  Future<void> test_dotShorthandFactoryEmpty() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
  factory E.f() => ONE;
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
  factory E.f() => ONE;
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_dotShorthandFactoryEmptyRedirect() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
  factory E.f() => ONE;
  factory E.g() = E.f;
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
  factory E.f() => ONE;
  factory E.g() = E.f;
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_dotShorthandFactoryWithRequired() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  final int i;
  const E(this.i);
  factory E.f({required int i, required String s}) => ONE;
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1), TWO(i);

  final int i;
  const E(this.i);
  factory E.f({required int i, required String s}) => ONE;
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_dotShorthandFactoryWithRequiredRedirect() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  final int i;
  const E(this.i);
  factory E.f({required int i, required String s}) => ONE;
  factory E.g({required int i, required String s}) = E.f;
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1), TWO(i);

  final int i;
  const E(this.i);
  factory E.f({required int i, required String s}) => ONE;
  factory E.g({required int i, required String s}) = E.f;
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_factory_beforeGenerative() async {
    await resolveTestCode('''
enum E {
  ONE;

  factory E.f() => ONE;
  const E();
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  factory E.f() => ONE;
  const E();
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_mixed() async {
    await resolveTestCode('''
enum E {
  ONE(1, s: 'hello');

  final int i;
  final String s;
  const E(this.i, {required this.s});
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1, s: 'hello'), TWO(i, s: s);

  final int i;
  final String s;
  const E(this.i, {required this.s});
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named_dotShorthand() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_named_factory() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named_factory_dotShorthand() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_named_named() async {
    await resolveTestCode('''
enum E {
  ONE.something(), TWO.other();

  const E.something();
  const E.other();
}

E e() {
  return E.THREE;
}
''');

    await assertNoFix();
  }

  Future<void> test_named_named_dotShorthand() async {
    await resolveTestCode('''
enum E {
  ONE.something(), TWO.other();

  const E.something();
  const E.other();
}

E e() {
  return .THREE;
}
''');

    await assertNoFix();
  }

  Future<void> test_named_nonZeroParameters() async {
    await resolveTestCode('''
enum E {
  ONE.named(1);

  final int i;
  const E.named(this.i);
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(1), TWO.named(i);

  final int i;
  const E.named(this.i);
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named_nonZeroParameters_dotShorthand() async {
    await resolveTestCode('''
enum E {
  ONE.named(1);

  final int i;
  const E.named(this.i);
}

E e() {
  return .TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(1), TWO.named(i);

  final int i;
  const E.named(this.i);
}

E e() {
  return .TWO;
}
''');
  }

  Future<void> test_named_unnamed() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
  const E();
}

E e() {
  return E.TWO;
}
''');

    await assertNoFix();
  }

  Future<void> test_namedConstructor_withRequired() async {
    await resolveTestCode('''
enum E {
  ONE.other(1);

  const E.other(int x);
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.other(1), TWO.other(x);

  const E.other(int x);
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_namedPrimary() async {
    await resolveTestCode('''
enum E.named() {
  one.named();
}

E e = E.two;
''');

    await assertHasFix('''
enum E.named() {
  one.named(), two.named();
}

E e = E.two;
''');
  }

  Future<void> test_namedPrimary_nonZeroParameters() async {
    await resolveTestCode('''
enum E.named(final int i) {
  one.named(1);
}

E e = E.two;
''');

    await assertHasFix('''
enum E.named(final int i) {
  one.named(1), two.named(i);
}

E e = E.two;
''');
  }

  Future<void> test_optionalNamedWithDefault() async {
    await resolveTestCode('''
enum E {
  ONE(i: 1);

  const E({int i = 0});
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(i: 1), TWO;

  const E({int i = 0});
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_optionalPositionalWithDefault() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  const E([int i = 0]);
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1), TWO;

  const E([int i = 0]);
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_requiredNamed() async {
    await resolveTestCode('''
enum E {
  ONE(s: 'hello');

  final String s;
  const E({required this.s});
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(s: 'hello'), TWO(s: s);

  final String s;
  const E({required this.s});
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  final int value;
  const E(this.value);
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1), TWO(value);

  final int value;
  const E(this.value);
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_toEmpty_braces() async {
    await resolveTestCode('''
enum E {}

void f() {
  E.ONE;
}
''');
    await assertHasFix(
      '''
enum E { ONE }

void f() {
  E.ONE;
}
''',
      filter: (e) {
        // Filter to ignore enum_without_constants
        return e.diagnosticCode == diag.undefinedEnumConstant;
      },
    );
  }

  Future<void> test_toEmpty_dotShorthand() async {
    await resolveTestCode('''
enum E {}

E e() {
  return .ONE;
}
''');
    await assertHasFix(
      '''
enum E { ONE }

E e() {
  return .ONE;
}
''',
      filter: (e) {
        // Filter to ignore enum_without_constants
        return e.diagnosticCode == diag.dotShorthandUndefinedGetter;
      },
    );
  }

  Future<void> test_toEmpty_semicolon() async {
    await resolveTestCode('''
enum E;

void f() {
  E.ONE;
}
''');
    await assertHasFix(
      '''
enum E { ONE }

void f() {
  E.ONE;
}
''',
      filter: (e) {
        // Filter to ignore enum_without_constants
        return e.diagnosticCode == diag.undefinedEnumConstant;
      },
    );
  }

  Future<void> test_undefinedIdentifier_contextType() async {
    await resolveTestCode('''
enum E { a }

void f() {
  E x = b;
}
''');
    await assertHasFix('''
enum E { a, b }

void f() {
  E x = b;
}
''', filter: (e) => e.diagnosticCode == diag.undefinedIdentifier);
  }

  Future<void> test_undefinedIdentifier_insideEnumMethod() async {
    await resolveTestCode('''
enum E {
  a;
  void m() {
    E x = b;
  }
}
''');
    await assertHasFix('''
enum E {
  a, b;
  void m() {
    E x = b;
  }
}
''', filter: (e) => e.diagnosticCode == diag.undefinedIdentifier);
  }

  Future<void> test_undefinedIdentifier_notEnum_noFix() async {
    await resolveTestCode('''
void f() {
  int x = b;
}
''');
    await assertNoFix(
      filter: (e) => e.diagnosticCode == diag.undefinedIdentifier,
    );
  }

  Future<void> test_undefinedIdentifier_returnType() async {
    await resolveTestCode('''
enum E { a }

E f() => b;
''');
    await assertHasFix('''
enum E { a, b }

E f() => b;
''');
  }

  Future<void> test_undefinedIdentifier_withConstructor() async {
    await resolveTestCode('''
enum E {
  a(1);
  final int i;
  const E(this.i);
}

void f() {
  E x = b;
}
''');
    await assertHasFix('''
enum E {
  a(1), b(i);
  final int i;
  const E(this.i);
}

void f() {
  E x = b;
}
''', filter: (e) => e.diagnosticCode == diag.undefinedIdentifier);
  }

  Future<void> test_unnamed() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_unnamed_factory() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_unnamed_nonZeroParameters() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  final int i;
  const E(this.i);
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE(1), TWO(i);

  final int i;
  const E(this.i);
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_unnamedPrimary() async {
    await resolveTestCode('''
enum E() {
  one;
}

E e = E.two;
''');

    await assertHasFix('''
enum E() {
  one, two;
}

E e = E.two;
''');
  }

  Future<void> test_unnamedPrimary_nonZeroParameters() async {
    await resolveTestCode('''
enum E(final int i) {
  one(1);
}

E e = E.two;
''');

    await assertHasFix('''
enum E(final int i) {
  one(1), two(i);
}

E e = E.two;
''');
  }
}
