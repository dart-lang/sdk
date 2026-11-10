// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerV1AstUseTest);
  });
}

@reflectiveTest
class AnalyzerV1AstUseTest extends LintRuleTest {
  @override
  String get lintRule => 'analyzer_v1_ast_use';

  @override
  void setUp() {
    super.setUp();
    newFile('$testPackageLibPath/v1_ast.dart', r'''
class V1Ast {
  final String message;
  const V1Ast([this.message = '']);
}
''');
  }

  test_class_insideV1AstClass() async {
    await assertNoDiagnostics(r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}

@V1Ast()
class C {
  void foo(A a) {}
}
''');
  }

  test_class_insideV1AstLibrary() async {
    await assertNoDiagnostics(r'''
@V1Ast()
library;

import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}

void foo(A a) {}
''');
  }

  test_class_isExpression() async {
    await assertDiagnostics(
      r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}

bool foo(Object o) => o is A;
''',
      [lint(97, 1)],
    );
  }

  test_class_typeAnnotation() async {
    await assertDiagnostics(
      r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}

void foo(A a) {}
''',
      [
        lint(
          79,
          1,
          messageContainsAll: [
            "'A' is part of the V1 AST API",
            RegExp(r'V1 AST API\. The V2 counterpart is B\.$'),
          ],
        ),
      ],
    );
  }

  test_commentReference() async {
    await assertNoDiagnostics(r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}

/// Unlike [A].
void foo() {}
''');
  }

  test_exportDirective_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}
''');
    await assertNoDiagnostics(r'''
export 'a.dart' show A;
''');
  }

  test_getter() async {
    await assertDiagnostics(
      r'''
import 'v1_ast.dart';

class A {
  @V1Ast('The V2 counterpart is bar.')
  int get foo => 0;
}

int f(A a) => a.foo;
''',
      [lint(111, 3)],
    );
  }

  test_getter_insideV1AstMethod() async {
    await assertNoDiagnostics(r'''
import 'v1_ast.dart';

class A {
  @V1Ast('The V2 counterpart is bar.')
  int get foo => 0;

  @V1Ast()
  int baz() => foo;
}
''');
  }

  test_importDirective_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'v1_ast.dart';

@V1Ast('The V2 counterpart is B.')
class A {}
''');
    await assertDiagnostics(
      r'''
import 'a.dart' show A;

void foo(A a) {}
''',
      [lint(34, 1)],
    );
  }

  test_notV1Ast() async {
    await assertNoDiagnostics(r'''
class A {
  int get foo => 0;
}

int f(A a) => a.foo;
''');
  }

  test_topLevelFunction() async {
    await assertDiagnostics(
      r'''
import 'v1_ast.dart';

@V1Ast()
void foo() {}

void bar() {
  foo();
}
''',
      [
        lint(
          62,
          3,
          messageContainsAll: [
            RegExp(r"^'foo' is part of the V1 AST API, .* V1 AST API\.$"),
          ],
        ),
      ],
    );
  }
}
