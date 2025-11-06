// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
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
// @dart = 3.6
// (pre tall-style)

Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

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
// @dart = 3.6
// (pre tall-style)

Object f(a, b) {
  f(f('a',
      'b'), 'b');
  return a;
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
// @dart = 3.6
// (pre tall-style)

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
  FixKind get kind => DartFixKind.addTrailingComma;

  Future<void> test_parse_literal_initialization() async {
    // ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

var r = const (1);
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

var r = const (1,);
''');
  }

  Future<void> test_parse_type_initialization() async {
    // ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

(int) record = const (1,);
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

(int,) record = const (1,);
''');
  }

  Future<void> test_warning_literal_assignment() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f((int,) r) {
  r = (1);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f((int,) r) {
  r = (1,);
}
''');
  }

  Future<void> test_warning_literal_initialization() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

(int,) r = (1);
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

(int,) r = (1,);
''');
  }

  Future<void> test_warning_literal_return() async {
    // WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

(int,) f() { return (1); }
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

(int,) f() { return (1,); }
''');
  }
}

@reflectiveTest
class AddTrailingCommaTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addTrailingComma;

  @override
  String get lintCode => LintNames.require_trailing_commas;

  Future<void> test_assert_initializer() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

class C {
  C(a) : assert(a,
    '');
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

class C {
  C(a) : assert(a,
    '',);
}
''');
  }

  Future<void> test_assert_statement() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(a, b) {
  assert(a ||
    b);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(a, b) {
  assert(a ||
    b,);
}
''');
  }

  Future<void> test_list_literal() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = [
    'a',
    'b'
  ];
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = [
    'a',
    'b',
  ];
  print(l);
}
''');
  }

  Future<void> test_list_literal_withNullAwareElement() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(String? s) {
  var l = [
    'a',
    // ignore: EXPERIMENT_NOT_ENABLED
    ?s
  ];
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(String? s) {
  var l = [
    'a',
    // ignore: EXPERIMENT_NOT_ENABLED
    ?s,
  ];
  print(l);
}
''');
  }

  Future<void> test_map_literal() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = {
    'a': 1,
    'b': 2
  };
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = {
    'a': 1,
    'b': 2,
  };
  print(l);
}
''');
  }

  Future<void> test_map_literal_withNullAwareKey() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(String? k) {
  var l = {
    'a': 1,
    // ignore: EXPERIMENT_NOT_ENABLED
    ?k: 2
  };
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(String? k) {
  var l = {
    'a': 1,
    // ignore: EXPERIMENT_NOT_ENABLED
    ?k: 2,
  };
  print(l);
}
''');
  }

  Future<void> test_map_literal_withNullAwareValue() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(int? v) {
  var l = {
    'a': 1,
    // ignore: EXPERIMENT_NOT_ENABLED
    'b': ?v
  };
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(int? v) {
  var l = {
    'a': 1,
    // ignore: EXPERIMENT_NOT_ENABLED
    'b': ?v,
  };
  print(l);
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f({a, b}) {
  f(a: 'a',
    b: 'b');
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f({a, b}) {
  f(a: 'a',
    b: 'b',);
}
''');
  }

  Future<void> test_parameters() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(a,
  b) {}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(a,
  b,) {}
''');
  }

  Future<void> test_positional() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(a, b) {
  f('a',
    'b');
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(a, b) {
  f('a',
    'b',);
}
''');
  }

  Future<void> test_set_literal() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = {
    'a',
    'b'
  };
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f() {
  var l = {
    'a',
    'b',
  };
  print(l);
}
''');
  }

  Future<void> test_set_literal_withNullAwareElement() async {
    await resolveTestCode('''
// @dart = 3.6
// (pre tall-style)

void f(String? s) {
  var l = {
    'a',
    // ignore: EXPERIMENT_NOT_ENABLED
    ?s
  };
  print(l);
}
''');
    await assertHasFix('''
// @dart = 3.6
// (pre tall-style)

void f(String? s) {
  var l = {
    'a',
    // ignore: EXPERIMENT_NOT_ENABLED
    ?s,
  };
  print(l);
}
''');
  }
}
