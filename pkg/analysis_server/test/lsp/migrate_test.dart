// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrateTest);
  });
}

@reflectiveTest
class MigrateTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    registerBuiltInFixGenerators();
  }

  Future<void> test_bumpSdkConstraint() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '^3.0.0'
''',
    );
    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.0.0 -> ^3.1.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.1.0'
''',
    );
  }

  Future<void> test_bumpSdkConstraint_emptyPubspec() async {
    await _setupProject(pubspecContent: '');
    await _assertMigrationResult(
      expectedSummary: 'No SDK constraints were bumped.',
    );
  }

  Future<void> test_bumpSdkConstraint_multiplePackages() async {
    await initialize();

    var project1Path = pathContext.join(projectFolderPath, 'project1');
    var project2Path = pathContext.join(projectFolderPath, 'project2');

    newFile(pathContext.join(project1Path, 'pubspec.yaml'), '''
name: project1
environment:
  sdk: '^3.0.0'
''');

    newFile(pathContext.join(project2Path, 'pubspec.yaml'), '''
name: project2
environment:
  sdk: '^3.2.0'
''');

    await _assertMigrationResult(
      uris: [Uri.file(project1Path), Uri.file(project2Path)],
      expectedSummary: '''
Bumped SDK constraints in 2 package(s):
- project1: ^3.0.0 -> ^3.1.0
- project2: ^3.2.0 -> ^3.3.0''',
    );
  }

  Future<void> test_bumpSdkConstraint_noneBumped() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
''',
    );
    await _assertMigrationResult(
      expectedSummary: 'No SDK constraints were bumped.',
    );
  }

  Future<void> test_bumpSdkConstraint_range() async {
    await _setupProject(
      pubspecContent: '''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
''',
    );
    await _assertMigrationResult(
      expectedSummary: contains('>=3.0.0 <4.0.0 -> >=3.1.0'),
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '>=3.1.0 <4.0.0'
''',
    );
  }

  Future<void> test_bumpSdkConstraint_skipped() async {
    var otherDirPath = convertPath('/other_project');
    var otherPubspecPath = pathContext.join(otherDirPath, 'pubspec.yaml');

    await _setupProject(
      pubspecContent: 'name: other_project',
      customPubspecFilePath: otherPubspecPath,
    );
    await _assertMigrationResult(
      uris: [Uri.file(otherDirPath)],
      expectedSummary: contains('- other_project: Skipped (not analyzed)'),
    );
  }

  Future<void> test_error_directoryWithoutPubspec() async {
    await initialize();

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The directory '$projectFolderPath' doesn't contain a 'pubspec.yaml' "
          'file.',
        ),
      ),
    );
  }

  Future<void> test_error_fileUri() async {
    await initialize();

    newFile(mainFilePath, '');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [mainFileUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The path '$mainFilePath' doesn't refer to a package or pub workspace"
          ' directory.',
        ),
      ),
    );
  }

  Future<void> test_error_fileUri_multipleWithOneInvalid() async {
    await initialize();

    newFile(pubspecFilePath, 'name: test_project');

    var validUri = projectFolderUri;
    var invalidUri = Uri.parse('http://example.com');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [validUri, invalidUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ServerErrorCodes.invalidFilePath,
        message: contains("URI scheme 'http' is not supported"),
      ),
    );
  }

  Future<void> test_error_invalidPubspec() async {
    await initialize();

    newFile(pubspecFilePath, 'invalid: [');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "Failed to parse 'pubspec.yaml' at '$projectFolderPath'",
        ),
      ),
    );
  }

  Future<void> test_error_nonExistentDirectory() async {
    await initialize();

    var dirUri = Uri.file(convertPath('/non/existent/dir'));
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [dirUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains("doesn't exist"),
      ),
    );
  }

  Future<void> test_error_workspacePackage() async {
    await initialize();

    newFile(pubspecFilePath, '''
name: test_project
resolution: workspace
''');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri]),
    );
    var response = await sendRequestToServer(request);

    expect(
      response.error,
      isResponseError(
        ErrorCodes.InvalidParams,
        message: contains(
          "The directory '$projectFolderPath' is part of a workspace and can't "
          'be migrated independently.',
        ),
      ),
    );
  }

  Future<void> test_preMigration_313() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x, var y) {}\n');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x, y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_preMigration_313_multipleFiles() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    var otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    newFile(mainFilePath, 'void m(final int x) {}\n');
    newFile(otherFilePath, 'void f(var y) {}\n');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> lib/other.dart
void f(y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_preMigration_313_multiplePackages() async {
    failTestOnErrorDiagnostic = false;
    var otherPackagePath = convertPath('/home/other_package');
    var otherPubspecPath = join(otherPackagePath, 'pubspec.yaml');
    var otherFilePath = join(otherPackagePath, 'lib', 'other.dart');

    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');

    newFile(otherPubspecPath, '''
name: other_package
environment:
  sdk: '^3.12.0'
''');
    newFile(otherFilePath, 'void f(var y) {}\n');

    await initialize(
      workspaceFolders: [projectFolderUri, toUri(otherPackagePath)],
    );

    await _assertMigrationResult(
      uris: [projectFolderUri, toUri(otherPackagePath)],
      expectedSummary: '''
Bumped SDK constraints in 2 package(s):
- test_project: ^3.12.0 -> ^3.13.0
- other_package: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> ../other_package/lib/other.dart
void f(y) {}
>>>>>>>>>> ../other_package/pubspec.yaml
name: other_package
environment:
  sdk: '^3.13.0'
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_preMigration_313_nestedAnalysisOptions() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    var analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');
    newFile(analysisOptionsPath, '');

    var aPath = join(projectFolderPath, 'lib', 'a.dart');
    newFile(aPath, 'void m(final int x) {}\n');

    var nestedAnalysisOptionsPath = join(
      projectFolderPath,
      'lib',
      'src',
      'analysis_options.yaml',
    );
    newFile(nestedAnalysisOptionsPath, '');

    var bPath = join(projectFolderPath, 'lib', 'src', 'b.dart');
    newFile(bPath, 'void f(final int y) {}\n');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/a.dart
void m(int x) {}
>>>>>>>>>> lib/src/b.dart
void f(int y) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_preMigration_313_noEdits() async {
    failTestOnErrorDiagnostic = false;
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(int x, y) {}\n');

    await initialize();

    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_preMigration_nestedPackage() async {
    failTestOnErrorDiagnostic = false;

    // Parent package
    newFile(pubspecFilePath, '''
name: test_project
environment:
  sdk: '^3.12.0'
''');
    newFile(mainFilePath, 'void m(final int x) {}\n');
    writeTestPackageConfig(languageVersion: '3.12');

    // Nested package in 'example/'
    var examplePath = join(projectFolderPath, 'example');
    var examplePubspecPath = join(examplePath, 'pubspec.yaml');
    var exampleMainPath = join(examplePath, 'lib', 'main.dart');
    newFile(examplePubspecPath, '''
name: example
environment:
  sdk: '^3.12.0'
''');
    newFile(exampleMainPath, 'void f(var y) {}\n');
    writePackageConfig(
      examplePath,
      packageName: 'example',
      languageVersion: '3.12',
    );

    await initialize();

    // Migrate ONLY the parent package.
    await _assertMigrationResult(
      expectedSummary: '''
Bumped SDK constraints in 1 package(s):
- test_project: ^3.12.0 -> ^3.13.0''',
      expectedEdit: '''
>>>>>>>>>> lib/main.dart
void m(int x) {}
>>>>>>>>>> pubspec.yaml
name: test_project
environment:
  sdk: '^3.13.0'
''',
    );
  }

  Future<void> test_validDirectory() async {
    await _setupProject(pubspecContent: 'name: test_project');
    await _assertMigrationResult();
  }

  Future<void> _assertMigrationResult({
    List<Uri>? uris,
    Object? expectedSummary,
    String? expectedEdit,
  }) async {
    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: uris ?? [projectFolderUri]),
    );
    var response = await sendRequestToServer(request);

    expect(response.error, isNull);

    var result = DartMigrateResult.fromJson(
      response.result as Map<String, Object?>,
    );
    if (expectedSummary != null) {
      expect(result.summary, expectedSummary);
    }
    if (expectedEdit != null) {
      verifyEdit(result.edit!, expectedEdit);
    }
  }

  Future<void> _setupProject({
    required String pubspecContent,
    String? customPubspecFilePath,
  }) async {
    await initialize();

    var pubspecPath = customPubspecFilePath ?? pubspecFilePath;
    newFile(pubspecPath, pubspecContent);
  }
}
