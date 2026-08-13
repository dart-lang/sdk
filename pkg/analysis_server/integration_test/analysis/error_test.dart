// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorIntegrationTest);
  });
}

@reflectiveTest
class AnalysisErrorIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_analysisRootDoesNotExist() async {
    var packagePath = sourcePath('package');
    var filePath = sourcePath('package/lib/test.dart');
    var content = '''
void f() {
  print(null) // parse error: missing ';'
}''';
    await sendServerSetSubscriptions([ServerService.STATUS]);

    await sendAnalysisUpdateContent({filePath: AddContentOverlay(content)});
    // Usually we get `server.status` pair of `true/false` here.

    await sendAnalysisSetAnalysisRoots([packagePath], []);
    // Usually we get `server.status` pair of `true/false` here.

    // There is no guarantee how many times `server.status` will switch.
    // So, we just wait for the errors.
    // We should received them, eventually.
    while (currentAnalysisErrors[filePath] == null) {
      await pumpEventQueue();
    }

    expect(currentAnalysisErrors[filePath], isList);
    var errors = existingErrorsForFile(filePath);
    expect(errors, hasLength(1));
    expect(errors[0].location.file, equals(filePath));
  }

  @SkippedTest(
    reason:
        'Analysis roots created after watchers are set up are not '
        'currently detected',
  )
  Future<void> test_analysisRootDoesNotExist_createdLater() async {
    var packagePath = sourcePath('package');
    var filePath = sourcePath('package/lib/test.dart');
    var content = 'invalidCode';
    await sendServerSetSubscriptions([ServerService.STATUS]);
    await sendAnalysisSetAnalysisRoots([packagePath], []);
    await analysisFinished;

    // Expect no errors because folder/file do not exist.
    expect(currentAnalysisErrors[filePath], isNull);

    // Create folder/file and wait for analysis to complete.
    writeFile(filePath, content);
    await analysisFinished;

    // Expect errors from the invalid code.
    expect(currentAnalysisErrors[filePath], isNotNull);
  }

  @SkippedTest(
    reason:
        'Analysis roots created after watchers are set up are not '
        'currently detected',
  )
  Future<void> test_analysisRootDoesNotExist_deletedAndRecreated() async {
    // To simplify testing, use two analysis roots. When we delete one of them
    // we can use the notification of diagnostics sent for the other as
    // validation that contexts were rebuilt.
    var rootToKeepPath = sourcePath('packageKeep');
    var filetoKeepPath = sourcePath('packageKeep/lib/test.dart');
    var rootToDeletePath = sourcePath('packageDelete');
    var fileToDeletePath = sourcePath('packageDelete/lib/test.dart');
    var content = 'invalidCode';

    // Create the folders/files up-front.
    writeFile(filetoKeepPath, content);
    writeFile(fileToDeletePath, content);

    await sendServerSetSubscriptions([ServerService.STATUS]);
    await sendAnalysisSetAnalysisRoots([rootToKeepPath, rootToDeletePath], []);
    await analysisFinished;

    // Expect errors from the invalid code.
    expect(currentAnalysisErrors[fileToDeletePath], isNotNull);

    // Start listening for the kept root being re-analyzed as a signal that
    // the original rebuild has completed.
    var keptFileDiagnostics = onAnalysisErrors.firstWhere(
      (params) => params.file == filetoKeepPath,
    );

    // Delete the folder.
    deleteFolder(rootToDeletePath);
    await analysisFinished;
    await keptFileDiagnostics;

    // Expect the errors were removed.
    expect(currentAnalysisErrors[fileToDeletePath], isNull);

    // Re-create the folder/file.
    writeFile(fileToDeletePath, content);
    await analysisFinished;

    // Expect errors returned.
    expect(currentAnalysisErrors[fileToDeletePath], isNotNull);
  }

  Future<void> test_contextMessage() async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
void f() {
  x = 0;
  int x = 1;
  x;
}''');
    await standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors = existingErrorsForFile(pathname);
    var error = errors.single;
    expect(
      error.message,
      "Local variable 'x' can't be referenced before it is declared.",
    );
    expect(
      error.contextMessages!.single.message,
      "The declaration of 'x' is here.",
    );
  }

  Future<void> test_detect_simple_error() async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
void f() {
  print(null) // parse error: missing ';'
}''');
    await standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors = existingErrorsForFile(pathname);
    expect(errors, hasLength(1));
    expect(errors[0].location.file, equals(pathname));
  }
}
