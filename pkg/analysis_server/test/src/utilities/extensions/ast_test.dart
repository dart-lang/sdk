// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../services/search/search_engine_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitFileHeaderTest);
    defineReflectiveTests(FindSimplePrintInvocationTest);
  });
}

@reflectiveTest
class CompilationUnitFileHeaderTest extends PubPackageResolutionTest {
  Future<void> test_afterScriptTag_multiLine() async {
    await resolveTestCode('''
#! x
/* a */

class C {}
''');
    _assertTokens(['/* a */']);
  }

  Future<void> test_afterScriptTag_singleLine() async {
    await resolveTestCode('''
#! x
// a
// b

class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  Future<void> test_afterScriptTag_withDocComment_multiLine() async {
    await resolveTestCode('''
#! x
/* a */

/// b
class C {}
''');
    _assertTokens(['/* a */']);
  }

  Future<void> test_afterScriptTag_withDocComment_singleLine() async {
    await resolveTestCode('''
#! x
// a
// b

/// c
class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  Future<void> test_none() async {
    await resolveTestCode('''
class C {}
''');
    expect(result.unit.fileHeader, isEmpty);
  }

  Future<void> test_only_multiLine() async {
    await resolveTestCode('''
/* a */

class C {}
''');
    _assertTokens(['/* a */']);
  }

  Future<void> test_only_singleLine() async {
    await resolveTestCode('''
// a
// b

class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  Future<void> test_onlyDocComment_multiLine() async {
    await resolveTestCode('''
/** a */
class C {}
''');
    expect(result.unit.fileHeader, isEmpty);
  }

  Future<void> test_onlyDocComment_singleLine() async {
    await resolveTestCode('''
/// a
class C {}
''');
    expect(result.unit.fileHeader, isEmpty);
  }

  Future<void> test_withDocComment_multiLine() async {
    await resolveTestCode('''
/* a
*/

/// b
class C {}
''');
    _assertTokens(['/* a\n*/']);
  }

  Future<void> test_withDocComment_singleLine() async {
    await resolveTestCode('''
// a
// b

/// c
class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  Future<void> test_withDocComment_singleLine_noBlankLine() async {
    await resolveTestCode('''
// a
/// b
class C {}
''');
    _assertTokens(['// a']);
  }

  Future<void> test_withNonDocComment_multiLine_multiLine() async {
    await resolveTestCode('''
/* a */
/* b */
class C {}
''');
    _assertTokens(['/* a */']);
  }

  Future<void> test_withNonDocComment_multiLine_singleLine() async {
    await resolveTestCode('''
/* a */
// b
class C {}
''');
    _assertTokens(['/* a */']);
  }

  Future<void> test_withNonDocComment_singleLine_multiLine() async {
    await resolveTestCode('''
// a
// b
/* c */
class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  Future<void> test_withNonDocComment_singleLine_singleLine() async {
    await resolveTestCode('''
// a
// b

// c
class C {}
''');
    _assertTokens(['// a', '// b']);
  }

  /// Assert that the returned tokens have lexemes that match the [expected]
  /// comments.
  void _assertTokens(List<String> expected) {
    expect(
      result.unit.fileHeader.map((token) => token.lexeme),
      orderedEquals(expected),
    );
  }
}

@reflectiveTest
class FindSimplePrintInvocationTest extends PubPackageResolutionTest {
  Future<void> test_customPrint() async {
    await resolveTestCode('''
void print(String toPrint) {
}

void f() {
  print('hi');
}
''');
    var printIdentifier = findNode.simple('print(\'hi\'');
    var result = printIdentifier.findSimplePrintInvocation();
    expect(result, null);
  }

  Future<void> test_negative() async {
    await resolveTestCode('''
void f() {
  true ? print('hi') : print('false');
}
''');
    var printIdentifier = findNode.simple('print(\'false');
    var result = printIdentifier.findSimplePrintInvocation();
    expect(result, null);
  }

  Future<void> test_simplePrintInvocation() async {
    await resolveTestCode('''
void f() {
  print('hi');
}
''');
    var printIdentifier = findNode.simple('print');
    var expected = findNode.expressionStatement('print');
    var result = printIdentifier.findSimplePrintInvocation();
    expect(result, expected);
  }
}
