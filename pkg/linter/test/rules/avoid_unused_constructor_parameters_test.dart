// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnusedConstructorParametersTest);
  });
}

@reflectiveTest
class AvoidUnusedConstructorParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_unused_constructor_parameters;

  test_augmentationClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A { }
''');

    await assertDiagnostics(r'''
part of 'a.dart';

augment class A {
  A(int a);
}
''', [
      lint(41, 5),
    ]);
  }

  test_augmentedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  A(int a);
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class A {
  augment A.new(int a);
}
''');
  }

  test_deprecated() async {
    await assertNoDiagnostics(r'''
class C {
  C(@Deprecated('') int p);
}
''');
  }

  test_externalConstructor() async {
    await assertNoDiagnostics(r'''
class C {
  external C(int p);
}
''');
  }

  test_fieldFormalParameter() async {
    await assertNoDiagnostics(r'''
class C {
  int p;
  C({this.p = 0});
}
''');
  }

  test_namedAsWildcards() async {
    // https://github.com/dart-lang/linter/issues/1793
    await assertNoDiagnostics(r'''
class C {
  C(int _, int __);
}
''');
  }

  test_namedParameter_hasDefault() async {
    await assertDiagnostics(r'''
class C {
  C({int c = 0});
}
''', [
      lint(15, 9),
    ]);
  }

  test_noParameters() async {
    await assertNoDiagnostics(r'''
class C {
  C();
}
''');
  }

  test_redirectingConstructor1() async {
    await assertDiagnostics(r'''
class C {
  C.named(int p);
  factory C(int p) = C.named;
}
''', [
      lint(20, 5),
    ]);
  }

  test_redirectingConstructor2() async {
    await assertNoDiagnostics(r'''
class C {
  int p;
  C.named(this.p);
  factory C(int p) => C.named(p);
}
''');
  }

  test_super() async {
    await assertNoDiagnostics(r'''
class A {
  String a;
  String b;
  A(this.a, this.b);
}
class B extends A {
  B(super.a, super.b);
}
''');
  }

  test_unused_optionalPositional() async {
    await assertDiagnostics(r'''
class C {
  C([int p = 0]) {}
}
''', [
      lint(15, 9),
    ]);
  }

  test_unused_requiredPositional() async {
    await assertDiagnostics(r'''
class C {
  C(int p);
}
''', [
      lint(14, 5),
    ]);
  }

  test_usedInConstructorBody() async {
    await assertNoDiagnostics(r'''
class C {
  C({int p = 0}) {
   p;
  }
}
''');
  }

  test_usedInConstructorInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  int f;
  C({int p = 0}) : f = p;
}
''');
  }

  test_usedInRedirectingInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  int p;
  C(this.p);
  C.named(int p) : this(p);
}
''');
  }

  test_usedInSuperInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  int p;
  C(this.p);
}

class D extends C {
  D(int p) : super(p);
}
''');
  }

  test_wildcardParam() async {
    await assertNoDiagnostics(r'''
class C {
 C(int _);
}
''');
  }

  test_wildcardParam_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
 C(int _);
}
''');
  }
}
