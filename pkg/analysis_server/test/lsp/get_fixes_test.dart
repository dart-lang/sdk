// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetFixesTest);
  });
}

@reflectiveTest
class GetFixesTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();

    registerLintRules();
    registerBuiltInFixGenerators();

    // Enable this so we can verify we get annotations back (which would allow
    // grouping, etc but also show up in our edit verifier strings below).
    setChangeAnnotationSupport();
  }

  Future<void> test_filter_diagnosticCodes() async {
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - always_specify_types # fix
    - prefer_single_quotes # don't fix
    - prefer_is_empty      # fix
    ''');

    newFile(mainFilePath, '''
var a = '';
String b = "";
bool c = ''.length == 0;
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      diagnosticCodes: [
        diag.alwaysSpecifyTypesReplaceKeyword.lowerCaseName,
        diag.preferIsEmptyUseIsEmpty.lowerCaseName,
      ],
    );
    var result = await getWorkspaceFixes(params);

    // Expect fixes for always_specify_types and prefer_is_empty
    // but not for prefer_single_quotes.
    verifyResult(
      result,
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Add type annotation: line 1
>>>>>>>>>>   Replace with 'isEmpty': line 3
String a = '';
String b = "";
bool c = ''.isEmpty;
''',
      '''
lib/main.dart:
    always_specify_types: 1
    prefer_is_empty: 1
''',
    );
  }

  Future<void> test_iterative() async {
    // Use lints that will fire on different iterations. var -> final -> const.
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''');

    newFile(mainFilePath, '''
void f() {
  var a = 'test';
  var b = 'test';
}
''');

    await initialize();

    var result = await getWorkspaceFixes();

    // Expect two fixes from two different passes, merged together.
    verifyResult(
      result,
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 2, line 3
void f() {
  const a = 'test';
  const b = 'test';
}
''',
      '''
lib/main.dart:
    prefer_final_locals: 2
    prefer_const_declarations: 2
''',
    );
  }

  Future<void> test_iterativeDartAndPubspec_ifNoCodes() async {
    failTestOnErrorDiagnostic = false;

    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''');

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;

void f() {
  var a = 'test';
}
''');

    await initialize();

    var result = await getWorkspaceFixes();

    verifyResult(
      result,
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 4
import 'package:path/path.dart' as path;

void f() {
  const a = 'test';
}
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''',
      '''
lib/main.dart:
    prefer_final_locals: 1
    prefer_const_declarations: 1
pubspec.yaml:
    missing_dependency: 1
''',
    );
  }

  Future<void> test_iterativeDartAndPubspec_ifSpecificCodes() async {
    failTestOnErrorDiagnostic = false;

    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_final_locals
    - prefer_const_declarations
    ''');

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;

void f() {
  var a = 'test';
}
''');

    await initialize();

    var result = await getWorkspaceFixes(
      DartGetWorkspaceFixesParams(
        diagnosticCodes: [
          diag.preferFinalLocals.lowerCaseName,
          diag.preferConstDeclarations.lowerCaseName,
          diag.missingDependency.lowerCaseName,
        ],
      ),
    );

    verifyResult(
      result,
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 4
import 'package:path/path.dart' as path;

void f() {
  const a = 'test';
}
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''',
      '''
lib/main.dart:
    prefer_final_locals: 1
    prefer_const_declarations: 1
pubspec.yaml:
    missing_dependency: 1
''',
    );
  }

  Future<void> test_multiple() async {
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - always_specify_types
    - prefer_single_quotes
    - prefer_is_empty
    ''');

    newFile(mainFilePath, '''
var a = '';
String b = "";
bool c = ''.length == 0;
''');

    await initialize();

    var result = await getWorkspaceFixes();

    // Expect fixes for all three diagnostics.
    verifyResult(
      result,
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Add type annotation: line 1
>>>>>>>>>>   Convert to single quoted string: line 2, line 2
>>>>>>>>>>   Replace with 'isEmpty': line 3
String a = '';
String b = '';
bool c = ''.isEmpty;
''',
      '''
lib/main.dart:
    always_specify_types: 1
    prefer_single_quotes: 1
    prefer_is_empty: 1
''',
    );
  }

  Future<void> test_pubspec_excluded_ifNonPubspecCodes() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      // Filtered to another code means we shouldn't get the pubspec fix.
      diagnosticCodes: [diag.preferSingleQuotes.lowerCaseName],
    );
    var result = await getWorkspaceFixes(params);

    expect(result.edit, isNull);
  }

  Future<void> test_pubspec_included_ifCode_migrateDesignWidgets() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      diagnosticCodes: [diag.migrateDesignWidgets.lowerCaseName],
    );
    var result = await getWorkspaceFixes(params);

    verifyResult(
      result,
      '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''',
      '''
pubspec.yaml:
    missing_dependency: 1
''',
    );
  }

  Future<void> test_pubspec_included_ifCode_missingDependency() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      diagnosticCodes: [diag.missingDependency.lowerCaseName],
    );
    var result = await getWorkspaceFixes(params);

    verifyResult(
      result,
      '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''',
      '''
pubspec.yaml:
    missing_dependency: 1
''',
    );
  }

  Future<void> test_pubspec_included_ifNoCodes() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:args/args.dart' as args;
import 'package:path/path.dart' as path;
''');

    await initialize();

    var result = await getWorkspaceFixes();

    verifyResult(
      result,
      '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  args: any
  path: any
''',
      '''
pubspec.yaml:
    missing_dependency: 1
''',
    );
  }

  void verifyResult(
    DartGetWorkspaceFixesResult result,
    String expectedEdits,
    String expectedDetails,
  ) {
    verifyEdit(result.edit!, expectedEdits);

    var detailsString = StringBuffer();
    for (var detail in result.details) {
      detailsString.writeln('${relativePath(fromUri(detail.uri))}:');
      for (var fix in detail.fixes) {
        detailsString.writeln('    ${fix.code}: ${fix.occurrences}');
      }
    }

    expect(detailsString.toString(), expectedDetails);
  }
}
