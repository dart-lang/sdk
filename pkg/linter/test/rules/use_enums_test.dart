// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseEnumsTest);
  });
}

@reflectiveTest
class UseEnumsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_enums;

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class C {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class C {
  static const a = C._(1);
  static const b = C._(2);
  final int i;
  const C._(this.i);
}
''');

    await assertDiagnosticsInFile(a.path, [
      // TODO(pq): update when augmentation contributed fields are considered.
      // See: https://github.com/dart-lang/linter/issues/4900
    ]);
    await assertNoDiagnosticsInFile(b.path);
  }

  test_constructor_private() async {
    await assertDiagnostics(
      r'''
class A {
  static const A a = A._(1);
  static const A b = A._(2);
  final int value;
  const A._(this.value);
}
''',
      [lint(6, 1)],
    );
  }

  test_extendsObject() async {
    await assertDiagnostics(
      r'''
class A extends Object {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
''',
      [lint(6, 1)],
    );
  }

  test_multiDeclaration() async {
    await assertDiagnostics(
      r'''
class A {
  static const A a = A._(), b = A._();
  const A._();
}
''',
      [lint(6, 1)],
    );
  }

  test_no_lint_abstract() async {
    await assertNoDiagnostics(r'''
abstract class A {
  static const A a = B();
  static const A b = B();
  const A();
}
class B extends A {
  const B();
}
''');
  }

  test_no_lint_constructor_factory() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A();
  static const A b = A();
  factory A.f(int index) {
    throw '!';
  }
  const A();
}
''');
  }

  test_no_lint_constructor_named() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A.x();
  static const A b = A.x();
  const A.x();
}
''');
  }

  test_no_lint_constructor_public() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A(1);
  static const A b = A(2);
  final int index;
  const A(this.index);
}
''');
  }

  test_no_lint_constructorUsedInConstructor() async {
    await assertDiagnostics(
      r'''
class _E {
  static const _E a = _E();
  static const _E b = _E();

  const _E({_E e = const _E()});
}
''',
      [
        // No lint.
        error(diag.recursiveConstantConstructor, 76, 2),
        // We are reversing the deprecation: This code will remain a `HintCode`.
        error(diag.unusedElementParameter, 83, 1),
      ],
    );
  }

  test_no_lint_constructorUsedOutsideClass() async {
    await assertNoDiagnostics(r'''
class _E {
  static const _E a = _E();
  static const _E b = _E();

  const _E();
}

_E get e => _E();
''');
  }

  test_no_lint_extended() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
class B extends A {
  const B() : super._();
}
''');
  }

  test_no_lint_extends_notObject() async {
    await assertNoDiagnostics(r'''
class O {
  const O();
}
class A extends O {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
''');
  }

  test_no_lint_factoryAll() async {
    await assertNoDiagnostics(r'''
class _E {
  static _E c = _E();
  static _E d = _E();

  factory _E() => c;
}
''');
  }

  test_no_lint_factorySome() async {
    await assertNoDiagnostics(r'''
class _E {
  static _E c0 = _E._();
  static _E c1 = _E();

  factory _E() => c0;
  const _E._();
}
''');
  }

  test_no_lint_implemented() async {
    await assertNoDiagnostics('''
class _E {
  static const _E c = _E();
  static const _E d = _E();

  const _E();
}
class F implements _E  {}
''');
  }

  test_no_lint_implements_index_field() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
  final int index = 0;
}
''');
  }

  test_no_lint_implements_index_getter() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
  int get index => 0;
}
''');
  }

  test_no_lint_implements_values_field() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
  static final List<A> values = [a, b];
}
''');
  }

  test_no_lint_implements_values_method() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
  static List<A> values() => [];
}
''');
  }

  test_no_lint_nonConstConstructor() async {
    // TODO(pq): consider relaxing the lint to flag cases w/o a const
    // but all final fields.
    await assertNoDiagnostics('''
class _E {
  static final _E a = _E();
  static final _E b = _E();

  _E();
}
''');
  }

  test_no_lint_nonInstanceCreationInitialization() async {
    await assertNoDiagnostics(r'''
class _E {
  static const _E a = _E();
  static const _E b = a;

  const _E();
}
''');
  }

  test_no_lint_overrides_equals() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A();
  static const A b = A();
  const A();
  @override
  bool operator ==(Object other) => false;
}
''');
  }

  test_no_lint_overrides_hashCode() async {
    await assertNoDiagnostics(r'''
class A {
  static const A a = A();
  static const A b = A();
  const A();
  @override
  int get hashCode => 0;
}
''');
  }

  test_primaryConstructor_hashCode() async {
    await assertNoDiagnostics(r'''
class const A._(final int hashCode) {
  static const A a = A._(1);
  static const A b = A._(2);
}
''');
  }

  test_primaryConstructor_index() async {
    await assertNoDiagnostics(r'''
class const A._(final int index) {
  static const A a = A._(1);
  static const A b = A._(2);
}
''');
  }

  test_primaryConstructor_noLint_nonConst() async {
    await assertNoDiagnostics(r'''
class _A(int x) {
  static final _A a = _A(1);
  static final _A b = _A(2);
}
''');
  }

  test_primaryConstructor_private() async {
    await assertDiagnostics(
      r'''
class const A._(final int value) {
  static const A a = A._(1);
  static const A b = A._(2);
}
''',
      [lint(12, 1)],
    );
  }

  test_primaryConstructor_public() async {
    await assertNoDiagnostics(r'''
class const A(final int value) {
  static const A a = A(1);
  static const A b = A(2);
}
''');
  }

  test_primaryConstructor_values() async {
    await assertNoDiagnostics(r'''
class const A._(final int values) {
  static const A a = A._(1);
  static const A b = A._(2);
}
''');
  }

  test_referencedFactoryConstructor() async {
    await assertDiagnostics(
      r'''
class _E {
  static const _E c = _E();
  static const _E d = _E();

  const _E();

  factory _E.withValue(int x) => c;
}

_E e = _E.withValue(0);
''',
      [lint(6, 2)],
    );
  }

  test_simple_hasPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
''');
    await assertDiagnostics(
      r'''
part 'a.dart';
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
''',
      [lint(21, 1)],
    );
  }

  test_simple_private() async {
    await assertDiagnostics(
      r'''
class _A {
  static const _A a = _A();
  static const _A b = _A();
  const _A();
}
''',
      [lint(6, 2)],
    );
  }

  test_simple_public() async {
    await assertDiagnostics(
      r'''
class A {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
''',
      [lint(6, 1)],
    );
  }

  test_withMixin() async {
    await assertDiagnostics(
      r'''
mixin class M { }
class A with M {
  static const A a = A._();
  static const A b = A._();
  const A._();
}
''',
      [lint(24, 1)],
    );
  }
}
