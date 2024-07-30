// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IgnoreDiagnosticAnalysisOptionFileTest);
    defineReflectiveTests(IgnoreDiagnosticLineTest);
    defineReflectiveTests(IgnoreDiagnosticFileTest);
  });
}

@reflectiveTest
class IgnoreDiagnosticAnalysisOptionFileTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IGNORE_ERROR_ANALYSIS_FILE;

  @override
  void setUp() {
    useLineEndingsForPlatform = true;
    super.setUp();
  }

  Future<void> test_addFixToExistingErrorMap() async {
    createAnalysisOptionsFile(
      errors: {'unused_label': 'ignore'},
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix(
      '''
analyzer:
  errors:
    unused_label: ignore
    unused_local_variable: ignore
''',
      target: analysisOptionsPath,
    );
  }

  Future<void> test_emptyAnalysisOptionsFile() async {
    // This overwrites the file created by `super.setUp` method.
    writeBlankAnalysisOptionsFile();

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix(
      '''
analyzer:
  errors:
    unused_local_variable: ignore
''',
      target: analysisOptionsPath,
    );
  }

  Future<void> test_invalidAnalysisOptionsFormat() async {
    // This overwrites the file created by `super.setUp` method.
    // Note: a label without a value is an `invalid_section_format` for dart.
    writeAnalysisOptionsFile('''
analyzer:
  linter:
''');

    await resolveTestCode('''
  void f() {
    var a = 1;
  }
  ''');
    await assertNoFix();
  }

  Future<void> test_noAnalysisOptionsFile() async {
    // TODO(osaxma): we should be able to prevent creating the file in the first
    //  place. Overriding `setUp` won't solve the issue since it's marked with
    //  `@mustCallSuper` and does several other operations besides creating the
    //  file. See discussion at:
    //  https://dart-review.googlesource.com/c/sdk/+/352220
    //
    // This deletes the file created by `super.setUp` method.
    resourceProvider.getFile(analysisOptionsPath).delete();
    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_noAnalyzerLabel() async {
    writeBlankAnalysisOptionsFile();

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix(
      '''
analyzer:
  errors:
    unused_local_variable: ignore
''',
      target: analysisOptionsPath,
    );
  }

  Future<void> test_noErrorLabel() async {
    createAnalysisOptionsFile(
      // To create a valid `analyzer` label, we add a `cannot-ignore` label.
      // This also  implicitly tests when unrelated label is in `cannot-ignore`
      cannotIgnore: ['unused_label'],
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertHasFix(
      '''
analyzer:
  errors:
    unused_local_variable: ignore
  cannot-ignore:
    - unused_label
''',
      target: analysisOptionsPath,
    );
  }

  Future<void> test_noFixWhenErrorIsIgnored() async {
    createAnalysisOptionsFile(
      errors: {'unused_local_variable': 'ignore'},
    );

    await resolveTestCode('''
void f() {
  var a = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_onlyIncludeLabel() async {
    // This overwrites the file created by `super.setUp` method.
    // Having a newline is important because yaml_edit copies existing
    // newlines and we want to test the current platforms EOLs.
    // The content is normalized in newFile().
    writeAnalysisOptionsFile('''
include: package:lints/recommended.yaml
''');

    await resolveTestCode('''
  void f() {
    var a = 1;
  }
  ''');
    await assertHasFix(
      '''
include: package:lints/recommended.yaml
analyzer:
  errors:
    unused_local_variable: ignore
''',
      target: analysisOptionsPath,
    );
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

  void writeBlankAnalysisOptionsFile() {
    // Include a newline because yaml_edit will copy existing newlines and
    // this newline will be normalized for the current platform. Without it,
    // yaml_edit will produce new content using \n on Windows which may not
    // match the expectations here depending on Git EOL settings.
    writeAnalysisOptionsFile('\n');
  }
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

  Future<void> test_noHeader_oneLine() async {
    await resolveTestCode('var _a = 1;');
    await assertHasFix('''
// ignore_for_file: unused_element

var _a = 1;''');
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

  Future<void> test_unusedCode_firstLine() async {
    await resolveTestCode('''
var _a = 1;
''');
    await assertHasFix('''
// ignore: unused_element
var _a = 1;
''');
  }

  Future<void> test_unusedCode_oneLine() async {
    await resolveTestCode('var _a = 1;');
    await assertHasFix('''
// ignore: unused_element
var _a = 1;''');
  }
}
