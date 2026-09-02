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
    verifyEdit(result.edit!, '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Add type annotation: line 1
>>>>>>>>>>   Replace with 'isEmpty': line 3
String a = '';
String b = "";
bool c = ''.isEmpty;
''');
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
}
''');

    await initialize();

    var result = await getWorkspaceFixes();

    // Expect two fixes from two different passes, merged together.
    verifyEdit(result.edit!, '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 2
void f() {
  const a = 'test';
}
''');
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
  path.join();
}
''');

    await initialize();

    var result = await getWorkspaceFixes();

    verifyEdit(result.edit!, '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 4
import 'package:path/path.dart' as path;

void f() {
  const a = 'test';
  path.join();
}
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''');
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
  path.join();
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

    verifyEdit(result.edit!, '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Make final, Replace 'final' with 'const': line 4
import 'package:path/path.dart' as path;

void f() {
  const a = 'test';
  path.join();
}
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''');
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
    verifyEdit(result.edit!, '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Add type annotation: line 1
>>>>>>>>>>   Convert to single quoted string: line 2, line 2
>>>>>>>>>>   Replace with 'isEmpty': line 3
String a = '';
String b = '';
bool c = ''.isEmpty;
''');
  }

  Future<void> test_pubspec_excluded_ifNonPubspecCodes() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;

void f() {
  path.join();
}
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

void f() {
  path.join();
}
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      diagnosticCodes: [diag.migrateDesignWidgets.lowerCaseName],
    );
    var result = await getWorkspaceFixes(params);

    verifyEdit(result.edit!, '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''');
  }

  Future<void> test_pubspec_included_ifCode_missingDependency() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;

void f() {
  path.join();
}
''');

    await initialize();

    var params = DartGetWorkspaceFixesParams(
      diagnosticCodes: [diag.missingDependency.lowerCaseName],
    );
    var result = await getWorkspaceFixes(params);

    verifyEdit(result.edit!, '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''');
  }

  Future<void> test_pubspec_included_ifNoCodes() async {
    failTestOnErrorDiagnostic = false;

    newPubspecYamlFile(projectFolderPath, '''
name: x
''');

    newFile(mainFilePath, '''
import 'package:path/path.dart' as path;

void f() {
  path.join();
}
''');

    await initialize();

    var result = await getWorkspaceFixes();

    verifyEdit(result.edit!, '''
>>>>>>>>>> pubspec.yaml
>>>>>>>>>>   Update pubspec with the missing dependencies: line 2
name: x
dependencies:
  path: any
''');
  }
}
