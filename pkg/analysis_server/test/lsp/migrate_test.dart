// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
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
      expectedPubspecContent: '''
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
      expectedPubspecContent: '''
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

  Future<void> test_validDirectory() async {
    await _setupProject(pubspecContent: 'name: test_project');
    await _assertMigrationResult();
  }

  Future<void> _assertMigrationResult({
    List<Uri>? uris,
    Object? expectedSummary,
    String? expectedPubspecContent,
    String expectedPubspecPath = 'pubspec.yaml',
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
    if (expectedPubspecContent != null) {
      var workspaceEdit = result.edit!;
      var expectedContent =
          '''
>>>>>>>>>> $expectedPubspecPath
$expectedPubspecContent''';

      verifyEdit(workspaceEdit, expectedContent);
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
