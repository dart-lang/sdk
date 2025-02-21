// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireTrailingCommasTest);
  });
}

@reflectiveTest
class RequireTrailingCommasTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.require_trailing_commas;

  test_argumentList_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text',
      'Text');
}
void g(Object p1, Object p2) {}
''',
      [lint(71, 1)],
    );
  }

  test_argumentList_multiLine_containsFunctionalBlockBody_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    () {
    },
    p3: 'Text',
  );
}
void g(Object p1, Object p2, {Object? p3}) {}
''');
  }

  test_argumentList_multiLine_containsFunctionBlockBody() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(() {
  }, 'Text');
}
void g(Object p1, Object p2) {}
''',
      [lint(67, 1)],
    );
  }

  test_argumentList_multiLine_containsFunctionBlockBody_endsWithNamed() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', () {
  }, p3: 'Text');
}
void g(Object p1, Object p2, {Object? p3}) {}
''',
      [lint(79, 1)],
    );
  }

  test_argumentList_multiLine_containsFunctionBlockBody_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    () {
    },
    'Text',
  );
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_containsListLiteral() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g([
    'one',
    'two',
  ], 'Text');
}
void g(Object p1, Object p2) {}
''',
      [lint(86, 1)],
    );
  }

  test_argumentList_multiLine_containsMapLiteral() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g({
    'one': 'Text',
    'two': 'Text',
  }, 'Text');
}
void g(Object p1, Object p2) {}
''',
      [lint(102, 1)],
    );
  }

  test_argumentList_multiLine_containsMapLiteral_withTrailingComma() async {
    await assertNoDiagnostics(r'''
void f() {
  g('map literal', {
    'one': 'Text',
    'two': 'Text',
  });
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_containsSetLiteral() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g({
    'one',
    'two',
  }, 'Text');
}
void g(Object p1, Object p2) {}
''',
      [lint(86, 1)],
    );
  }

  test_argumentList_multiLine_endsWithConstantListLiteral() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    const ['one', 'two'],
  );
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithFunctionBlockBody() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text',
      () {}); // LINT
}
void g(Object p1, Object p2) {}
''',
      [lint(70, 1)],
    );
  }

  test_argumentList_multiLine_endsWithFunctionBlockBody_multiLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
    g('test', () {
    });
}
void g(Object p1, Object p2, {Object? p3}) {}
''');
  }

  test_argumentList_multiLine_endsWithFunctionBlockBody_multiLine_named() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', 'Text', p3: () {
  });
}
void g(Object p1, Object p2, {Object? p3}) {}
''',
      [lint(79, 1)],
    );
  }

  test_argumentList_multiLine_endsWithFunctionBlockBody_multiLine_named_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    'Text',
    p3: () {
    },
  );
}
void g(Object p1, Object p2, {Object? p3}) {}
''');
  }

  test_argumentList_multiLine_endsWithFunctionBlockBody_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    () {},
  );
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithListLiteral() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', [
    'one',
    'two',
  ]);
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithListLiteral_onSingleLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text',
      const ['one', 'two']);
}
void g(Object p1, Object p2) {}
''',
      [lint(85, 1)],
    );
  }

  test_argumentList_multiLine_endsWithListLiteral_withTrailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', const [
    'one',
    'two',
  ]);
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithMapLiteral() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text',
      const {'one': '1', 'two': '2', 'three': '3'}); // LINT
}
void g(Object p1, Object p2) {}
''',
      [lint(109, 1)],
    );
  }

  test_argumentList_multiLine_endsWithMapLiteral_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    const {'one': '1', 'two': '2', 'three': '3'},
  );
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithMapLiteral_withTrailingComma() async {
    await assertNoDiagnostics(r'''
void f() {
  g('Text', const {
    'one': '1',
    'two': '2',
  });
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithSetLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  g('Text', {
    'one',
    'two',
  });
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_endsWithSetLiteral_withTrailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', const {
    'one',
    'two',
  });
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_multiLineString() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  print("""
Text
""");
}
''');
  }

  /// A representative test to ensure the lint is disabled when the language is 3.7 or higher.
  test_argumentList_multiLine_post37() async {
    await assertNoDiagnostics(r'''
void f() {
  g('Text',
      'Text');
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_multiLine_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g(
    'Text',
    'Text',
  );
}
void g(Object p1, Object p2) {}
''');
  }

  test_argumentList_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  g('Text', 'Text');
}
void g(Object p1, Object p2) {}
''');
  }

  test_assertStateent_multiLine_message_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(
    false,
    'Text',
  );
}
''');
  }

  test_assertStatement_closure() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(() {
    return true;
  }());
}
''');
  }

  test_assertStatement_closure_message() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(() {
    return true;
  }(), 'Text');
}
''',
      [lint(91, 1)],
    );
  }

  test_assertStatement_closure_message_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(
    () {
      return true;
    }(),
    'Text',
  );
}
''');
  }

  test_assertStatement_message() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(false, 'Text');
}
''');
  }

  test_assertStatement_multiLine_message() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(false,
      'Text');
}
''',
      [lint(75, 1)],
    );
  }

  test_assertStatement_oneArgument_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert('Text'
      .isNotEmpty);
}
''',
      [lint(80, 1)],
    );
  }

  test_assertStatement_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  assert(
    'Text'.isNotEmpty,
  );
}
''');
  }

  test_constructorAssertInitializer_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C()
      : assert(true,
            'Text');
}
''',
      [lint(91, 1)],
    );
  }

  test_constructorAssertInitializer_multiLine_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C()
      : assert(
          true,
          'Text',
        );
}
''');
  }

  test_function_parameters_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void method4(int one,
    int two) {}
''',
      [lint(69, 1)],
    );
  }

  test_function_parameters_multiLine_withComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f(
  int one,
  int two,
) {}
''');
  }

  test_function_parameters_withNamed_mulitLine_withComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f(
  int one, {
  int? two,
}) {}
''');
  }

  test_function_parameters_withNamed_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f(int one,
    {int two = 2}) {}
''',
      [lint(68, 1)],
    );
  }

  test_function_parameters_withNamed_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void method1(Object p1, Object p2, {Object? param3, Object? param4}) {}
''');
  }

  test_functionLiteral_parameters_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  (int one,
      int two)
      {};
}
''',
      [lint(72, 1)],
    );
  }

  test_functionLiteral_parameters_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  (a, b) {};
}
''');
  }

  test_listLiteral_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = [
    1,
    if (true) 2
  ];
}
''',
      [lint(84, 1)],
    );
  }

  test_listLiteral_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = [1, if (true) 2];
}
''');
  }

  test_mapLiteral_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = {
    1: 1,
    if (true) 2: 2
  };
}
''',
      [lint(90, 1)],
    );
  }

  test_mapLiteral_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = {1: 1, if (true) 2: 2};
}
''');
  }

  test_parameterList_multiLine_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C(
    Object p1,
    Object p2,
    Object p3,
  );
}
''');
  }

  test_parameterList_multiLineDefaultValue_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C(Object p1, Object p2,
      [Object p3 = const [
        'Text',
      ]]);
}
''',
      [lint(122, 1)],
    );
  }

  test_parameterList_multiLineDefaultValue_multiLine_trailingComma() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C(
    Object p1,
    Object p2, [
    Object p3 = const [
      'Text',
    ],
  ]);
}
''');
  }

  test_parameterList_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C(Object p1, Object p2);
}
''');
  }

  test_parameterList_singleLine_blankLineBefore() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

class C {
  C(
      Object p1, Object p2, Object p3);
}
''',
      [lint(88, 1)],
    );
  }

  test_setLiteral_multiLine() async {
    await assertDiagnostics(
      r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = {
    1,
    if (true) 2
  };
}
''',
      [lint(84, 1)],
    );
  }

  test_setLiteral_singleLine() async {
    await assertNoDiagnostics(r'''
// @dart = 3.6
// (pre tall-style)

void f() {
  var x = {1, if (true) 2};
}
''');
  }
}
