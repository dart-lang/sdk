// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseSuperParametersTest);
  });
}

@reflectiveTest
class UseSuperParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'use_super_parameters';

  test_functionTypedFormalParameter() async {
    await assertDiagnostics(r'''
class A {
  A(int f(int i));
}
class B extends A {
  B(int f(int i)) : super(f);
}
''', [
      lint(53, 1),
    ]);
  }

  test_named() async {
    await assertDiagnostics(r'''
class A {
  const A({int? x, int? y});
}
class B extends A {
  const B({int? x, int? y}) : super(x: x, y: y);
}
''', [
      lint(69, 1),
    ]);
  }

  Future<void> test_named_oneWithNameChange() async {
    await assertDiagnostics('''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? z}) : super(x: x, y: z);
}
''', [
      lint(57, 1),
    ]);
  }

  test_named_someReferencedInBody() async {
    await assertDiagnostics(r'''
class A {
  A({int? x, int? y});
}
class B extends A {
  B({int? x, int? y}) : super(x: x, y: y) {
    print(x);
  }
}
''', [
      lint(57, 1, messageContains: "Convert 'y' to a super parameter"),
    ]);
  }

  test_named_thisParameter() async {
    await assertDiagnostics(r'''
class A {
  A({int? x, int? y});
}
class B extends A {
  int? x;
  B({this.x, int? y}) : super(x:x, y:y);
}
''', [
      lint(67, 1, messageContains: "Convert 'y' to a super parameter."),
    ]);
  }

  test_no_lint_forwardedOutOfOrder() async {
    await assertNoDiagnostics(r'''
class B {
  final int x;
  final int y;
  B(this.x, this.y);
}
class C extends B {
  C(int x, int y) : super(y, x);
}
''');
  }

  test_no_lint_invalid_fieldFormalParameter() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(x) {
    print(x);
  }
}
''');
  }

  Future<void> test_no_lint_named_nameChange() async {
    await assertNoDiagnostics('''
class A {
  A({int? x});
}
class B extends A {
  B({int? y}) : super(x: y);
}
''');
  }

  test_no_lint_named_noSuperInvocation() async {
    await assertNoDiagnostics(r'''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 1});
}
''');
  }

  test_no_lint_named_notGenerative() async {
    await assertNoDiagnostics(r'''
class A {
  A({required int x});
}
class B extends A {
  static List<B> instances = [];
  factory B({required int x}) => instances[x];
}
''');
  }

  test_no_lint_named_notPassed_unreferenced() async {
    await assertNoDiagnostics(r'''
class A {
  A({int x = 0});
}
class B extends A {
  B({int x = 0}) : super(x: 0);
}
''');
  }

  test_no_lint_named_notPassed_usedInExpression() async {
    await assertNoDiagnostics(r'''
class A {
  A({String x = ''});
}
class B extends A {
  B({required Object x}) : super(x: x.toString());
}
''');
  }

  test_no_lint_named_passedAsPositional() async {
    await assertNoDiagnostics(r'''
class A {
  A(String x);
}
class B extends A {
  B({required String x}) : super(x);
}
''');
  }

  test_no_lint_nonSimpleIdentifierArg() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x, int y, [int? z]);
}
class B extends A {
  B(int a, int b) : super(a, 2, b);
}
''');
  }

  test_no_lint_notAllForwarded() async {
    await assertNoDiagnostics(r'''
class B {
  final int x;
  final int y;
  B(this.x, this.y);
}
class C extends B {
  C(int x) : super(x, 0);
}
''');
  }

  test_no_lint_positionalReferencedInBody() async {
    await assertNoDiagnostics(r'''
class A {
  A.a(int x, int? y);
}
class B extends A {
  B(int x, int? y) : super.a(x, y) {
    print(x);
  }
}
''');
  }

  test_no_lint_positionalThisParameter() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x, int y);
}
class B extends A {
  int x;
  B(this.x, int y) : super(x, y);
}
''');
  }

  test_no_lint_referencedInBody() async {
    await assertNoDiagnostics(r'''
class A {
  A.a(int x, {int? y});
}
class B extends A {
  B(int x, {int? y}) : super.a(x, y: y) {
    print(x);
    print(y);
  }
}
''');
  }

  test_no_lint_referencedInBody_named() async {
    await assertNoDiagnostics(r'''
class A {
  A({int? x});
}
class B extends A {
  B({int? x}) : super(x: x) {
    print(x);
  }
}
''');
  }

  test_no_lint_referencedInBody_positional() async {
    await assertNoDiagnostics(r'''
class A {
  int x;
  A(this.x);
}
class B extends A {
  int y;
  B(this.y) : super(y);
}
''');
  }

  test_no_lint_requiredPositional_namedInSuper() async {
    await assertNoDiagnostics(r'''
class A {
  A({int? x});
}
class B extends A {
  B(int x) : super(x: x);
}
''');
  }

  test_no_lint_requiredPositional_noSuperInvocation() async {
    await assertNoDiagnostics(r'''
class A {
  A();
}
class B extends A {
  B(int x);
}
''');
  }

  test_no_lint_requiredPositional_notGenerative() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x);
}
class B extends A {
  static List<B> instances = [];
  factory B(int x) => instances[x];
}
''');
  }

  test_no_lint_requiredPositional_notPassed_unreferenced() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x);
}
class B extends A {
  B(int x) : super(0);
}
''');
  }

  test_no_lint_requiredPositional_notPassed_usedInExpression() async {
    await assertNoDiagnostics(r'''
class A {
  A(String x);
}
class B extends A {
  B(Object x) : super(x.toString());
}
''');
  }

  test_nonForwardingNamed() async {
    await assertDiagnostics(r'''
class A {
  A(int x, {int? foo});
}
class B extends A {
  B(int x, {int? foo}) : super(x, foo: 0);
}
''', [
      lint(58, 1),
    ]);
  }

  test_optionalPositional_inSuper() async {
    await assertDiagnostics(r'''
class A {
  A(int x, [int? y]);
}
class B extends A {
  B(int x) : super(x);
}
''', [
      lint(56, 1),
    ]);
  }

  test_optionalPositional_singleSuperParameter() async {
    await assertDiagnostics(r'''
class A {
  A(int x);
}
class B extends A {
  B([int x = 0]) : super(x);
}
''', [
      lint(46, 1),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3569
  test_repeatedParam() async {
    await assertNoDiagnostics(r'''
class Rect {
  Rect(this.width, this.height);

  final double width;
  final double height;
}

class Square extends Rect {
  Square(double dimension) : super(dimension, dimension);
}
''');
  }

  test_requiredPositional_allConvertible() async {
    await assertDiagnostics(r'''
class B {
  final int foo;
  final int bar;
  B(this.foo, this.bar);
}
class C extends B {
  C(int foo, int bar) : super(foo, bar);
}
''', [
      lint(93, 1),
    ]);
  }

  test_requiredPositional_mixedSuperParameters() async {
    await assertDiagnostics(r'''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int x, int y) : super(x, y: y);
}
''', [
      lint(56, 1),
    ]);
  }

  test_requiredPositional_someConvertible() async {
    await assertDiagnostics(r'''
class B {
  final int foo;
  final int bar;
  B(this.foo, this.bar);
}
class C extends B {
  C(int baz, int foo, int bar) : super(foo, bar);
}
''', [
      lint(93, 1),
    ]);
  }

  test_requiredPositional_withNamed() async {
    await assertDiagnostics(r'''
class A {
  A(int x, {int? y});
}
class B extends A {
  B(int x, {int? y}) : super(x, y: y);
}
''', [
      lint(56, 1),
    ]);
  }
}
