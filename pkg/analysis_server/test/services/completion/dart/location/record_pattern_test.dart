// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:linter/src/lint_names.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternTest);
  });
}

@reflectiveTest
class RecordPatternTest extends AbstractCompletionDriverTest
    with RecordPatternTestCases {}

mixin RecordPatternTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    registerLintRules();
    var oldFilter = printerConfiguration.filter;
    printerConfiguration.filter = (suggestion) {
      if (oldFilter(suggestion)) {
        return true;
      }
      var label = suggestion.displayText;
      if (label == null) {
        return false;
      }
      return identifierRegExp.hasMatch(label);
    };
  }

  Future<void> test_assignmentContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  (^: ) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_assignmentContext_namedField_withName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  int v01;
  (f01: ^) = x0;
}
''');
    assertResponse(r'''
suggestions
  v01
    kind: localVariable
  x0
    kind: parameter
  final
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_declarationContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (^: ) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_declarationContext_namedField_name_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (f^: ) = x0;
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
  }

  Future<void>
  test_declarationContext_namedField_name_type_changesNothing() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: [LintNames.always_specify_types]),
    );
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (^: ) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_declarationContext_namedField_withoutName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  var (: ^) = x0;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void>
  test_declarationContext_namedField_withoutName_pattern_types() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: [LintNames.always_specify_types]),
    );
    await computeSuggestions('''
void f(({int f01, String f02, double g01}) x0) {
  var (: ^) = x0;
}
''');
    assertResponse(r'''
suggestions
  String f02
    kind: identifier
  double g01
    kind: identifier
  int f01
    kind: identifier
''');
  }

  Future<void> test_empty() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case (^)
  }
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_expectedType_namedField_forElement() async {
    await computeSuggestions('''
List<({int f01})> f() {
  return [
    for (int i = 0; i < 10; i++)
      (^),
  ];
}
''');
    assertResponse(r'''
suggestions
  |f01: |
    kind: namedArgument
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_expectedType_namedField_ifElement() async {
    await computeSuggestions('''
List<({int f01})> f() {
  return [
    if (1 == 1)
      (^),
  ];
}
''');
    assertResponse(r'''
suggestions
  |f01: |
    kind: namedArgument
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_matchingContext_namedField_name() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (^: )) {}
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_afterField() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (f01: 0, ^: )) {}
}
''');
    assertResponse(r'''
suggestions
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void>
  test_matchingContext_namedField_name_afterField_implicitName() async {
    await computeSuggestions('''
void f(({int f01, int f02, int f03}) x0) {
  if (x0 case (:var f01, ^: )) {}
}
''');
    assertResponse(r'''
suggestions
  f02
    kind: identifier
  f03
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_beforeField() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (^: , f01: 0)) {}
}
''');
    assertResponse(r'''
suggestions
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_name_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (f^: )) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
  }

  Future<void> test_matchingContext_namedField_withoutName_pattern() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: ^)) {}
}
''');
    assertResponse(r'''
suggestions
  final
    kind: keyword
  var
    kind: keyword
  var f01
    kind: identifier
  var f02
    kind: identifier
  var g01
    kind: identifier
''');
  }

  Future<void>
  test_matchingContext_namedField_withoutName_pattern_afterVar() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: var ^)) {}
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
  g01
    kind: identifier
''');
  }

  Future<void>
  test_matchingContext_namedField_withoutName_pattern_afterVar_partial() async {
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: var f^)) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
  }

  Future<void>
  test_matchingContext_namedField_withoutName_pattern_final() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: [LintNames.prefer_final_locals]),
    );
    await computeSuggestions('''
void f(({int f01, int f02, int g01}) x0) {
  if (x0 case (: ^)) {}
}
''');
    assertResponse(r'''
suggestions
  final
    kind: keyword
  final f01
    kind: identifier
  final f02
    kind: identifier
  final g01
    kind: identifier
  var
    kind: keyword
''');
  }

  Future<void>
  test_matchingContext_namedField_withoutName_pattern_type() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: [LintNames.always_specify_types]),
    );
    await computeSuggestions('''
void f(({int f01, String f02, double g01}) x0) {
  if (x0 case (: ^)) {}
}
''');
    assertResponse(r'''
suggestions
  String f02
    kind: identifier
  double g01
    kind: identifier
  final
    kind: keyword
  int f01
    kind: identifier
  var
    kind: keyword
''');
  }

  Future<void>
  test_matchingContext_namedField_withoutName_pattern_type_final() async {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(
        rules: [LintNames.always_specify_types, LintNames.prefer_final_locals],
      ),
    );
    await computeSuggestions('''
void f(({int f01, String f02, double g01}) x0) {
  if (x0 case (: ^)) {}
}
''');
    assertResponse(r'''
suggestions
  final
    kind: keyword
  final String f02
    kind: identifier
  final double g01
    kind: identifier
  final int f01
    kind: identifier
  var
    kind: keyword
''');
  }

  Future<void> test_noObjectGetters() async {
    allowedIdentifiers = {'hashCode'};
    await computeSuggestions('''
void f(({int f01, int f02}) record) {
  var (:^) = record;
}
''');
    assertResponse(r'''
suggestions
  f01
    kind: identifier
  f02
    kind: identifier
''');
  }

  Future<void> test_noVarKeyword_afterVar() async {
    await computeSuggestions('''
void f((int, int) record) {
  var (:^) = record;
}
''');
    assertResponse(r'''
suggestions
''');
  }
}
