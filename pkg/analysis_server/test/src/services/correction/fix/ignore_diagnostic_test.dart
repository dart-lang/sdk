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

  Future<void> test_existingIgnores() async {
    await resolveTestCode('''
// Copyright header.

// ignore_for_file: foo

// Some other header.

/// main dartcode
void main(List<String> args) {
  var a = 1;
}
''');
    await assertHasFix('''
// Copyright header.

// ignore_for_file: foo, unused_local_variable

// Some other header.

/// main dartcode
void main(List<String> args) {
  var a = 1;
}
''');
  }

  Future<void> test_headers() async {
    await resolveTestCode('''
// Copyright header.

// Some other header.

/// main dartcode
void main(List<String> args) {
  var a = 1;
}
''');
    await assertHasFix('''
// Copyright header.

// Some other header.

// ignore_for_file: unused_local_variable

/// main dartcode
void main(List<String> args) {
  var a = 1;
}
''');
  }

  Future<void> test_noHeader() async {
    await resolveTestCode('''
void main(List<String> args) {
  var a = 1;
}
''');
    await assertHasFix('''
// ignore_for_file: unused_local_variable

void main(List<String> args) {
  var a = 1;
}
''');
  }
}

@reflectiveTest
class IgnoreDiagnosticLineTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IGNORE_ERROR_LINE;

  Future<void> test_existingIgnore() async {
    await resolveTestCode('''
void main(List<String> args) {
  // ignore: foo
  var a = 1;
}
''');
    await assertHasFix('''
void main(List<String> args) {
  // ignore: foo, unused_local_variable
  var a = 1;
}
''');
  }

  Future<void> test_unusedCode() async {
    await resolveTestCode('''
void main(List<String> args) {
  var a = 1;
}
''');
    await assertHasFix('''
void main(List<String> args) {
  // ignore: unused_local_variable
  var a = 1;
}
''');
  }
}
