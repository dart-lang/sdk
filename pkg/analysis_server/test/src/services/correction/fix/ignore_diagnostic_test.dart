// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IgnoreDiagnosticLineTest);
    defineReflectiveTests(IgnoreDiagnosticFileTest);
  });
}

@reflectiveTest
class IgnoreDiagnosticFileTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IGNORE_ERROR_FILE;

  Future<void> test_cannotIgnore_other() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      cannotIgnore: ['unused_label'],
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix('''
// ignore_for_file: unused_local_variable

void f() {
  var a = 1;
}
''');
  }

  Future<void> test_existingIgnores() async {
    await resolveTestCode('''
// Copyright header.

// ignore_for_file: referenced_before_declaration

// Some other header.

/// some comment
void f() {
  a = 2;
  var a = 1;
}
''');
    await assertHasFix('''
// Copyright header.

// ignore_for_file: referenced_before_declaration, unused_local_variable

// Some other header.

/// some comment
void f() {
  a = 2;
  var a = 1;
}
''');
  }

  Future<void> test_headers() async {
    await resolveTestCode('''
// Copyright header.

// Some other header.

/// some comment
void f() {
  var a = 1;
}
''');
    await assertHasFix('''
// Copyright header.

// Some other header.

// ignore_for_file: unused_local_variable

/// some comment
void f() {
  var a = 1;
}
''');
  }

  Future<void> test_noHeader() async {
    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix('''
// ignore_for_file: unused_local_variable

void f() {
  var a = 1;
}
''');
  }

  Future<void> test_unignorable() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      cannotIgnore: ['unused_local_variable'],
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class IgnoreDiagnosticLineTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IGNORE_ERROR_LINE;

  Future<void> test_cannotIgnore_other() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      cannotIgnore: ['unused_label'],
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix('''
void f() {
  // ignore: unused_local_variable
  var a = 1;
}
''');
  }

  Future<void> test_dartdoc_getter() async {
    await resolveTestCode('''
/// AA
String get _AA => '';
''');
    await assertHasFix('''
/// AA
// ignore: unused_element
String get _AA => '';
''');
  }

  Future<void> test_existingIgnore() async {
    await resolveTestCode('''
void f() {
  // ignore: undefined_identifier
  var a = b;
}
''');
    await assertHasFix('''
void f() {
  // ignore: undefined_identifier, unused_local_variable
  var a = b;
}
''');
  }

  Future<void> test_unignorable() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      cannotIgnore: ['unused_local_variable'],
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_unusedCode() async {
    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix('''
void f() {
  // ignore: unused_local_variable
  var a = 1;
}
''');
  }
}
