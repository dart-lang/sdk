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
    defineReflectiveTests(ConvertQuotesBulkTest);
    defineReflectiveTests(ConvertQuotesInFileTest);
    defineReflectiveTests(ConvertQuotesTest);
  });
}

@reflectiveTest
class ConvertQuotesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_escaping_inner_quotes;

  Future<void> test_string_in_interpolation_string() async {
    await resolveTestCode(r'''
void f() {
  print('a\'${'b\'c'}\'d');
}
''');
    await assertHasFix(r'''
void f() {
  print("a'${"b'c"}'d");
}
''');
  }
}

@reflectiveTest
class ConvertQuotesInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.avoid_escaping_inner_quotes]);
    await resolveTestCode(r'''
void f() {
  print("a\"b\"c");
  print('d\'e\'f');
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
void f() {
  print('a"b"c');
  print("d'e'f");
}
''');
  }
}

@reflectiveTest
class ConvertQuotesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_QUOTES;

  @override
  String get lintCode => LintNames.avoid_escaping_inner_quotes;

  Future<void> test_backslash() async {
    await resolveTestCode(r'''
void f() {
  print('\\\'b\'\$');
}
''');
    await assertHasFix(r'''
void f() {
  print("\\'b'\$");
}
''');
  }

  Future<void> test_double_quotes() async {
    await resolveTestCode(r'''
void f() {
  print("a\"\"c");
}
''');
    await assertHasFix(r'''
void f() {
  print('a""c');
}
''');
  }

  Future<void> test_interpolation() async {
    await resolveTestCode(r'''
void f(String d) {
  print('a\'b\'c $d');
}
''');
    await assertHasFix(r'''
void f(String d) {
  print("a'b'c $d");
}
''');
  }

  Future<void> test_interpolation_string() async {
    await resolveTestCode(r'''
void f(String d) {
  print('a\'b\'c ${d.length}');
}
''');
    await assertHasFix(r'''
void f(String d) {
  print("a'b'c ${d.length}");
}
''');
  }

  Future<void> test_single_quotes() async {
    await resolveTestCode(r'''
void f() {
  print('a\'b\'c');
}
''');
    await assertHasFix(r'''
void f() {
  print("a'b'c");
}
''');
  }

  Future<void> test_string_in_interpolation_string() async {
    await resolveTestCode(r'''
void f() {
  print('a${'b\'c'}d');
}
''');
    await assertHasFix(r'''
void f() {
  print('a${"b'c"}d');
}
''');
  }
}
