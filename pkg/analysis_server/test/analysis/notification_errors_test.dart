// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../src/utilities/mock_packages.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotificationErrorsTest);
  });
}

@reflectiveTest
class NotificationErrorsTest extends AbstractAnalysisTest {
  Folder pedanticFolder;
  Map<String, List<AnalysisError>> filesErrors = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    } else if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      var decoded = AnalysisFlushResultsParams.fromNotification(notification);
      for (var file in decoded.files) {
        filesErrors[file] = null;
      }
    }
  }

  @override
  void setUp() {
    registerLintRules();
    super.setUp();
    server.handlers = [
      AnalysisDomainHandler(server),
    ];
    pedanticFolder = MockPackages.instance.addPedantic(resourceProvider);
  }

  Future<void> test_analysisOptionsFile() async {
    var filePath = join(projectPath, 'analysis_options.yaml');
    var analysisOptionsFile = newFile(filePath, content: '''
linter:
  rules:
    - invalid_lint_rule_name
''').path;

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[analysisOptionsFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_analysisOptionsFile_packageInclude() async {
    var filePath = join(projectPath, 'analysis_options.yaml');
    var analysisOptionsFile = newFile(filePath, content: '''
include: package:pedantic/analysis_options.yaml
''').path;

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();

    // Verify there's an error for the import.
    var errors = filesErrors[analysisOptionsFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);

    // Write a package file that allows resolving the include.
    newFile('$projectPath/.packages', content: '''
pedantic:${pedanticFolder.toUri()}
''');

    // Ensure the errors disappear.
    await waitForTasksFinished();
    await pumpEventQueue();
    errors = filesErrors[analysisOptionsFile];
    expect(errors, hasLength(0));
  }

  Future<void> test_androidManifestFile() async {
    var filePath = join(projectPath, 'android', 'AndroidManifest.xml');
    var manifestFile = newFile(filePath, content: '''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''').path;
    newFile(join(projectPath, 'analysis_options.yaml'), content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[manifestFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_androidManifestFile_dotDirectoryIgnored() async {
    var filePath = join(projectPath, 'ios', '.symlinks', 'AndroidManifest.xml');
    var manifestFile = newFile(filePath, content: '''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''').path;
    newFile(join(projectPath, 'analysis_options.yaml'), content: '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify that the file wasn't analyzed.
    //
    var errors = filesErrors[manifestFile];
    expect(errors, isNull);
  }

  Future<void> test_dataFile() async {
    var filePath = join(projectPath, 'lib', 'fix_data.yaml');
    var dataFile = newFile(filePath, content: '''
version: 1
transforms:
''').path;

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[dataFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.COMPILE_TIME_ERROR);
  }

  Future<void> test_dotFolder_priority() async {
    // Files inside dotFolders should not generate error notifications even
    // if they are added to priority (priority affects only priority, not what
    // is analyzed).
    createProject();
    addTestFile('');
    var brokenFile =
        newFile(join(projectPath, '.dart_tool/broken.dart'), content: 'err')
            .path;

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[brokenFile], isNull);

    // Add to priority files and give chance for the file to be analyzed (if
    // it would).
    setPriorityFiles([brokenFile]);
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should still be no errors.
    expect(filesErrors[brokenFile], isNull);
  }

  Future<void> test_dotFolder_unopenedFile() async {
    // Files inside dotFolders are not analyzed. Sending requests that cause
    // them to be opened (such as hovers) should not result in error notifications
    // because there is no event that would flush them and they'd remain in the
    // editor forever.
    createProject();
    addTestFile('');
    var brokenFile =
        newFile(join(projectPath, '.dart_tool/broken.dart'), content: 'err')
            .path;

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[brokenFile], isNull);

    // Send a getHover request for the file that will cause it to be read from disk.
    await waitResponse(AnalysisGetHoverParams(brokenFile, 0).toRequest('0'));
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should be no errors because the file is not being analyzed.
    expect(filesErrors[brokenFile], isNull);
  }

  Future<void> test_excludedFolder() async {
    addAnalysisOptionsFile('''
analyzer:
  exclude:
    - excluded/**
''');
    createProject();
    var excludedFile =
        newFile(join(projectPath, 'excluded/broken.dart'), content: 'err').path;

    // There should be no errors initially.
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);

    // Triggering the file to be processed should still generate no errors.
    await waitResponse(AnalysisGetHoverParams(excludedFile, 0).toRequest('0'));
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);

    // Opening the file should still generate no errors.
    await waitResponse(
        AnalysisSetPriorityFilesParams([excludedFile]).toRequest('0'));
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);
  }

  Future<void> test_importError() async {
    createProject();

    addTestFile('''
import 'does_not_exist.dart';
''');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    var errors = filesErrors[testFile];
    // Verify that we are generating only 1 error for the bad URI.
    // https://github.com/dart-lang/sdk/issues/23754
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.COMPILE_TIME_ERROR);
    expect(error.message, startsWith("Target of URI doesn't exist"));
  }

  Future<void> test_lintError() async {
    var camelCaseTypesLintName = 'camel_case_types';

    newFile(join(projectPath, 'analysis_options.yaml'), content: '''
linter:
  rules:
    - $camelCaseTypesLintName
''');

    addTestFile('class a { }');

    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);

    await waitForTasksFinished();

    var testDriver = server.getAnalysisDriver(testFile);
    var lints = testDriver.analysisOptions.lintRules;

    // Registry should only contain single lint rule.
    expect(lints, hasLength(1));
    var lint = lints.first as LintRule;
    expect(lint.name, camelCaseTypesLintName);

    // Verify lint error result.
    var errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, join(projectPath, 'bin', 'test.dart'));
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    expect(error.message, lint.description);
  }

  Future<void> test_notInAnalysisRoot() async {
    createProject();
    var otherFile = newFile('/other.dart', content: 'UnknownType V;').path;
    addTestFile('''
import '/other.dart';
main() {
  print(V);
}
''');
    await waitForTasksFinished();
    expect(filesErrors[otherFile], isNull);
  }

  Future<void> test_overlay_dotFolder() async {
    // Files inside dotFolders should not generate error notifications even
    // if they have overlays added.
    createProject();
    addTestFile('');
    var brokenFile =
        newFile(join(projectPath, '.dart_tool/broken.dart'), content: 'err')
            .path;

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[brokenFile], isNull);

    // Add and overlay and give chance for the file to be analyzed (if
    // it would).
    await waitResponse(
      AnalysisUpdateContentParams({
        brokenFile: AddContentOverlay('err'),
      }).toRequest('1'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should still be no errors.
    expect(filesErrors[brokenFile], isNull);
  }

  Future<void> test_overlay_newFile() async {
    // Overlays added for files that don't exist on disk should still generate
    // error notifications. Removing the overlay if the file is not on disk
    // should clear the errors.
    createProject();
    addTestFile('');
    var brokenFile = convertPath(join(projectPath, 'broken.dart'));

    // Add and overlay and give chance for the file to be analyzed.
    await waitResponse(
      AnalysisUpdateContentParams({
        brokenFile: AddContentOverlay('err'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should now be errors.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));

    // Remove the overlay (this file no longer exists anywhere).
    await waitResponse(
      AnalysisUpdateContentParams({
        brokenFile: RemoveContentOverlay(),
      }).toRequest('1'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // Unlike other tests here, removing an overlay for a file that doesn't exist
    // on disk doesn't flush errors, but re-analyzes the missing file, which results
    // in an error notification of 0 errors rather than a flush.
    expect(filesErrors[brokenFile], isEmpty);
  }

  Future<void> test_overlay_newFileSavedBeforeRemoving() async {
    // Overlays added for files that don't exist on disk should still generate
    // error notifications. If the file is subsequently saved to disk before the
    // overlay is removed, the errors should not be flushed when the overlay is
    // removed.
    createProject();
    addTestFile('');
    var brokenFile = convertPath(join(projectPath, 'broken.dart'));

    // Add and overlay and give chance for the file to be analyzed.
    await waitResponse(
      AnalysisUpdateContentParams({
        brokenFile: AddContentOverlay('err'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should now be errors.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));

    // Write the file to disk.
    newFile(brokenFile, content: 'err');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // Remove the overlay.
    await waitResponse(
      AnalysisUpdateContentParams({
        brokenFile: RemoveContentOverlay(),
      }).toRequest('1'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // Errors should not have been flushed since the file still exists without
    // the overlay.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));
  }

  Future<void> test_ParserError() async {
    createProject();
    addTestFile('library lib');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    var errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, join(projectPath, 'bin', 'test.dart'));
    expect(error.location.offset, isPositive);
    expect(error.location.length, isNonNegative);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(error.message, isNotNull);
  }

  Future<void> test_pubspecFile() async {
    var filePath = join(projectPath, 'pubspec.yaml');
    var pubspecFile = newFile(filePath, content: '''
version: 1.3.2
''').path;

    var setRootsRequest =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(setRootsRequest);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[pubspecFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    //
    // Fix the error and verify the new results.
    //
    modifyFile(pubspecFile, '''
name: sample
version: 1.3.2
''');
    await waitForTasksFinished();
    await pumpEventQueue();

    errors = filesErrors[pubspecFile];
    expect(errors, hasLength(0));
  }

  Future<void> test_pubspecFile_lint() async {
    var optionsPath = join(projectPath, 'analysis_options.yaml');
    newFile(optionsPath, content: '''
linter:
  rules:
    - sort_pub_dependencies
''');

    var filePath = join(projectPath, 'pubspec.yaml');
    var pubspecFile = newFile(filePath, content: '''
name: sample

dependencies:
  b: any
  a: any
''').path;

    var setRootsRequest =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(setRootsRequest);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[pubspecFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    //
    // Fix the error and verify the new results.
    //
    modifyFile(pubspecFile, '''
name: sample

dependencies:
  a: any
  b: any
''');
    await waitForTasksFinished();
    await pumpEventQueue();

    errors = filesErrors[pubspecFile];
    expect(errors, hasLength(0));
  }

  Future<void> test_StaticWarning() async {
    createProject();
    addTestFile('''
enum E {e1, e2}

void f(E e) {
  switch (e) {
    case E.e1:
      print(0);
      break;
  }
}
''');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    var errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }
}
