// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that ensure that documentation comments are being generated correctly.
library;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentationTest1);
    defineReflectiveTests(DocumentationTest2);
  });
}

@reflectiveTest
class DocumentationTest1 extends AbstractCompletionDriverTest
    with DocumentationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class DocumentationTest2 extends AbstractCompletionDriverTest
    with DocumentationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin DocumentationTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    printerConfiguration.withDocumentation = true;
  }

  Future<void> test_classMember() async {
    var docLines = r'''
  /// My documentation.
  /// Short description.
  ///
  /// Longer description.
''';

    await computeSuggestions('''
class C {
$docLines
  int f0;

$docLines
  m0() {}

$docLines
  int get g0 => 0;

  void f() {^}
}''');
    assertResponse(r'''
suggestions
  f0
    kind: field
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  g0
    kind: getter
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  m0
    kind: methodInvocation
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
''');
  }

  Future<void> test_macro() async {
    await computeSuggestions('''
/**
 * {@template template_name}
 * Macro contents on
 * multiple lines.
 * {@endtemplate}
 */
library;

/// {@macro template_name}
///
/// With an additional line.
int x0 = 0;

void f() {^}
''');
    assertResponse(r'''
suggestions
  x0
    kind: topLevelVariable
    docComplete: Macro contents on\nmultiple lines.\n\nWith an additional line.
    docSummary: Macro contents on\nmultiple lines.
''');
  }

  Future<void> test_topLevel() async {
    var docLines = r'''
/// My documentation.
/// Short description.
///
/// Longer description.
''';

    await computeSuggestions('''
$docLines
mixin class C0 {}

$docLines
class M0 = Object with C0;

$docLines
enum E0 {a, b, c}

$docLines
void f0() {}

$docLines
int v0 = 0;

void f() {^}
}''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  C0
    kind: class
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  C0
    kind: constructorInvocation
  E0
    kind: enum
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  M0
    kind: class
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  M0
    kind: constructorInvocation
  f0
    kind: functionInvocation
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  v0
    kind: topLevelVariable
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
''');
    } else {
      assertResponse(r'''
suggestions
  C0
    kind: class
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  C0
    kind: constructorInvocation
  E0
    kind: enum
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  M0
    kind: class
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  f0
    kind: functionInvocation
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
  v0
    kind: topLevelVariable
    docComplete: My documentation.\nShort description.\n\nLonger description.
    docSummary: My documentation.\nShort description.
''');
    }
  }
}
