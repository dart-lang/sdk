// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTrailingCommaBulkTest);
    defineReflectiveTests(AddTrailingCommaInFileTest);
    defineReflectiveTests(AddTrailingCommaTest);
    defineReflectiveTests(AddTrailingCommaRecordTest);
  });
}

@reflectiveTest
class AddTrailingCommaBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.require_trailing_commas;

  Future<void> test_bulk() async {
    await resolveTestCode('''
Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    await assertHasFix('''
Object f(a, b) {
  f(f('a',
      'b',), 'b',);
  return a;
}
''');
  }
}

@reflectiveTest
class AddTrailingCommaInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.require_trailing_commas]);
    await resolveTestCode(r'''
Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
Object f(a, b) {
  f(f('a',
      'b',), 'b',);
  return a;
}
''');
  }
}

@reflectiveTest
class AddTrailingCommaRecordTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_TRAILING_COMMA;

  Future<void> test_parse_literal_initialization() async {
    // ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
var r = const (1);
''');
    await assertHasFix('''
var r = const (1,);
''');
  }

  Future<void> test_parse_type_initialization() async {
    // ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
(int) record = const (1,);    
''');
    await assertHasFix('''
(int,) record = const (1,);    
''');
  }

  Future<void> test_warning_literal_assignment() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
void f((int,) r) {
  r = (1);
}
''');
    await assertHasFix('''
void f((int,) r) {
  r = (1,);
}
''');
  }

  Future<void> test_warning_literal_initialization() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
(int,) r = (1);
''');
    await assertHasFix('''
(int,) r = (1,);
''');
  }

  Future<void> test_warning_literal_return() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
(int,) f() { return (1); }
''');
    await assertHasFix('''
(int,) f() { return (1,); }
''');
  }
}

@reflectiveTest
class AddTrailingCommaTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_TRAILING_COMMA;

  @override
  String get lintCode => LintNames.require_trailing_commas;

  Future<void> test_assert_initializer() async {
    await resolveTestCode('''
class C {
  C(a) : assert(a,
    '');
}
''');
    await assertHasFix('''
class C {
  C(a) : assert(a,
    '',);
}
''');
  }

  Future<void> test_assert_statement() async {
    await resolveTestCode('''
void f(a, b) {
  assert(a ||
    b);
}
''');
    await assertHasFix('''
void f(a, b) {
  assert(a ||
    b,);
}
''');
  }

  @failingTest
  Future<void> test_list_literal() async {
    await resolveTestCode('''
void f() {
  var l = [
    'a',
    'b'
  ];
  print(l);
}
''');
    await assertHasFix('''
void f() {
  var l = [
    'a',
    'b',
  ];
  print(l);
}
''');
  }

  @failingTest
  Future<void> test_map_literal() async {
    await resolveTestCode('''
void f() {
  var l = {
    'a': 1,
    'b': 2
  };
  print(l);
}
''');
    await assertHasFix('''
void f() {
  var l = {
    'a': 1,
    'b': 2,
  };
  print(l);
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
void f({a, b}) {
  f(a: 'a',
    b: 'b');
}
''');
    await assertHasFix('''
void f({a, b}) {
  f(a: 'a',
    b: 'b',);
}
''');
  }

  Future<void> test_parameters() async {
    await resolveTestCode('''
void f(a,
  b) {}
''');
    await assertHasFix('''
void f(a,
  b,) {}
''');
  }

  Future<void> test_positional() async {
    await resolveTestCode('''
void f(a, b) {
  f('a',
    'b');
}
''');
    await assertHasFix('''
void f(a, b) {
  f('a',
    'b',);
}
''');
  }

  @failingTest
  Future<void> test_set_literal() async {
    await resolveTestCode('''
void f() {
  var l = {
    'a',
    'b'
  };
  print(l);
}
''');
    await assertHasFix('''
void f() {
  var l = {
    'a',
    'b',
  };
  print(l);
}
''');
  }
}
