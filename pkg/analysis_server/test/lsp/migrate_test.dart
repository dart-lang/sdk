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
        message: contains("doesn't contain a 'pubspec.yaml' file."),
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
          "doesn't refer to a package or pub workspace directory.",
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
          "is part of a workspace and can't be migrated independently.",
        ),
      ),
    );
  }

  Future<void> test_validDirectory() async {
    await initialize();

    newFile(pubspecFilePath, 'name: test_project');

    var request = makeRequest(
      CustomMethods.migrate,
      DartMigrateParams(uris: [projectFolderUri]),
    );
    var response = await sendRequestToServer(request);

    expect(response.error, isNull);
  }
}
