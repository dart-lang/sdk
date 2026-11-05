// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerToBeDeprecatedUseTest);
  });
}

@reflectiveTest
class AnalyzerToBeDeprecatedUseTest extends LintRuleTest {
  @override
  String get lintRule => 'analyzer_to_be_deprecated_use';

  @override
  void setUp() {
    super.setUp();
    newFile('$testPackageLibPath/to_be_deprecated.dart', r'''
class ToBeDeprecated {
  final String message;
  const ToBeDeprecated([this.message = '']);
}
''');
  }

  test_class_insideToBeDeprecatedClass() async {
    await assertNoDiagnostics(r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}

@ToBeDeprecated()
class C {
  void foo(A a) {}
}
''');
  }

  test_class_insideToBeDeprecatedLibrary() async {
    await assertNoDiagnostics(r'''
@ToBeDeprecated()
library;

import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}

void foo(A a) {}
''');
  }

  test_class_isExpression() async {
    await assertDiagnostics(
      r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}

bool foo(Object o) => o is A;
''',
      [lint(106, 1)],
    );
  }

  test_class_typeAnnotation() async {
    await assertDiagnostics(
      r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}

void foo(A a) {}
''',
      [
        lint(
          88,
          1,
          messageContainsAll: [
            "'A' is to be deprecated",
            RegExp(r'to be deprecated\. Use B instead\.$'),
          ],
        ),
      ],
    );
  }

  test_commentReference() async {
    await assertNoDiagnostics(r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}

/// Unlike [A].
void foo() {}
''');
  }

  test_exportDirective_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
class A {}
''');
    await assertNoDiagnostics(r'''
export 'a.dart' show A;
''');
  }

  test_getter() async {
    await assertDiagnostics(
      r'''
import 'to_be_deprecated.dart';

class A {
  @ToBeDeprecated('Use bar instead.')
  int get foo => 0;
}

int f(A a) => a.foo;
''',
      [lint(120, 3)],
    );
  }

  test_getter_insideToBeDeprecatedMethod() async {
    await assertNoDiagnostics(r'''
import 'to_be_deprecated.dart';

class A {
  @ToBeDeprecated('Use bar instead.')
  int get foo => 0;

  @ToBeDeprecated()
  int baz() => foo;
}
''');
  }

  test_importDirective_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'to_be_deprecated.dart';

@ToBeDeprecated('Use B instead.')
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

  test_notToBeDeprecated() async {
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
import 'to_be_deprecated.dart';

@ToBeDeprecated()
void foo() {}

void bar() {
  foo();
}
''',
      [
        lint(
          81,
          3,
          messageContainsAll: [
            RegExp(r"^'foo' is to be deprecated, .* to be deprecated\.$"),
          ],
        ),
      ],
    );
  }
}
