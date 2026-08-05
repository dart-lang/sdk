// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UsePrimaryConstructorsInClassTest);
    defineReflectiveTests(UsePrimaryConstructorsInEnumTest);
  });
}

@reflectiveTest
class UsePrimaryConstructorsInClassTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_primary_constructors;

  test_class_withDefaultConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
class [!C!];
''');
  }

  test_class_withExternalConstructor() async {
    await assertNoDiagnostics(r'''
class C {
  external C();
}
''');
  }

  test_class_withFactory() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C.[!a!]();
  factory C.b() => C.a();
}
''');
  }

  test_class_withMultipleLevelsOfRedirect() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C.[!a!]();
  C.b() : this.a();
  C.c() : this.b();
}
''');
  }

  test_class_withMultipleRoots() async {
    await assertNoDiagnostics(r'''
class C {
  C.a();
  C.b();
}
''');
  }

  test_class_withPrimaryConstructor() async {
    await assertNoDiagnostics(r'''
class C();
''');
  }

  test_class_withSingleGenerativeConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!C!]();
}
''');
  }

  test_class_withSingleLevelOfRedirect() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C.[!a!]();
  C.b() : this.a();
}
''');
  }
}

@reflectiveTest
class UsePrimaryConstructorsInEnumTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_primary_constructors;

  test_enum_withDefaultConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
enum [!E!] {
  a, b, c
}
''');
  }

  test_enum_withFactory() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  a, b, c;

  [!E!]();
  factory E.f() => b;
}
''');
  }

  test_enum_withMultipleLevelsOfRedirect() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  a.e(), b.f(), c.g();

  E.[!e!]();
  E.f() : this.e();
  E.g() : this.f();
}
''');
  }

  test_enum_withPrimaryConstructor() async {
    await assertNoDiagnostics(r'''
enum E() {
  a, b, c;
}
''');
  }

  test_enum_withSingleGenerativeConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  a, b, c;

  [!E!]();
}
''');
  }

  test_enum_withSingleLevelOfRedirect() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  a.e(), b.f();

  E.[!e!]();
  E.f() : this.e();
}
''');
  }

  test_enums_withExternalConstructor() async {
    await assertNoDiagnostics(r'''
enum E {
  a, b, c;

  external E();
}
''');
  }
}
