// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../src/utilities/mock_packages.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotificationErrorsTest);
  });
}

@reflectiveTest
class NotificationErrorsTest extends PubPackageAnalysisServerTest {
  late Folder pedanticFolder;
  Map<File, List<AnalysisError>?> filesErrors = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[getFile(decoded.file)] = decoded.errors;
    } else if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      var decoded = AnalysisFlushResultsParams.fromNotification(notification);
      for (var file in decoded.files) {
        filesErrors[getFile(file)] = null;
      }
    }
  }

  @override
  void setUp() {
    registerLintRules();
    super.setUp();
    server.pendingFilesRemoveOverlayDelay = const Duration(milliseconds: 10);
    pedanticFolder = MockPackages.instance.addPedantic(resourceProvider);
  }

  Future<void> test_analysisOptionsFile() async {
    var analysisOptions = newAnalysisOptionsYamlFile2(testPackageRootPath, '''
linter:
  rules:
    - invalid_lint_rule_name
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[analysisOptions]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, analysisOptions.path);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_analysisOptionsFile_packageInclude() async {
    var analysisOptions = newAnalysisOptionsYamlFile2(testPackageRootPath, '''
include: package:pedantic/analysis_options.yaml
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();

    // Verify there's an error for the import.
    var errors = filesErrors[analysisOptions]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, analysisOptions.path);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);

    // Write a package file that allows resolving the include.
    newPackageConfigJsonFile(
      testPackageRootPath,
      (PackageConfigFileBuilder()
            ..add(name: 'pedantic', rootPath: pedanticFolder.parent.path))
          .toContent(toUriStr: toUriStr),
    );

    // Ensure the errors disappear.
    await waitForTasksFinished();
    await pumpEventQueue();
    errors = filesErrors[analysisOptions]!;
    expect(errors, hasLength(0));
  }

  Future<void> test_androidManifestFile() async {
    var manifestPath =
        join(testPackageRootPath, 'android', 'AndroidManifest.xml');
    var manifestFile = newFile(manifestPath, '''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''');
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[manifestFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, manifestFile.path);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_androidManifestFile_dotDirectoryIgnored() async {
    var manifestPath =
        join(testPackageRootPath, 'ios', '.symlinks', 'AndroidManifest.xml');
    var manifestFile = newFile(manifestPath, '''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''').path;
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify that the file wasn't analyzed.
    //
    var errors = filesErrors[manifestFile];
    expect(errors, isNull);
  }

  Future<void> test_dartToolGeneratedProject_referencedByUserProject() async {
    // Although errors are not generated for dotfolders, their contents should
    // still be analyzed so that code that references them (for example
    // flutter_gen) should still be updated.
    final configPath =
        join(testPackageRootPath, '.dart_tool/package_config.json');
    final generatedProject = join(testPackageRootPath, '.dart_tool/foo');
    final generatedFile = join(generatedProject, 'lib', 'foo.dart');

    // Add the generated project into package_config.json.
    final config = PackageConfigFileBuilder();
    config.add(name: 'foo', rootPath: generatedProject);
    newFile(configPath, config.toContent(toUriStr: toUriStr));

    // Set up project that references the class prior to initial analysis.
    newFile(generatedFile, 'class A {}');
    addTestFile('''
import 'package:foo/foo.dart';
A? a;
    ''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[testFile], isEmpty);

    // Remove the class, which should cause the main project to have an analysis
    // error.
    modifyFile(generatedFile, '');

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[testFile], isNotEmpty);
  }

  Future<void> test_dataFile() async {
    var dataFile = newFile('$testPackageLibPath/fix_data.yaml', '''
version: 1
transforms:
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[dataFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, dataFile.path);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.COMPILE_TIME_ERROR);
  }

  Future<void> test_dotFolder_priority() async {
    // Files inside dotFolders should not generate error notifications even
    // if they are added to priority (priority affects only priority, not what
    // is analyzed).
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('');
    var brokenFile =
        newFile(join(testPackageRootPath, '.dart_tool/broken.dart'), 'err');

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
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('');
    var brokenFile =
        newFile('$testPackageRootPath/.dart_tool/broken.dart', 'err');

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[brokenFile], isNull);

    // Send a getHover request for the file that will cause it to be read from disk.
    await handleSuccessfulRequest(
      AnalysisGetHoverParams(brokenFile.path, 0).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should be no errors because the file is not being analyzed.
    expect(filesErrors[brokenFile], isNull);
  }

  Future<void> test_excludedFolder() async {
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  exclude:
    - excluded/**
''');
    await setRoots(included: [workspaceRootPath], excluded: []);
    var excludedFile =
        newFile('$testPackageRootPath/excluded/broken.dart', 'err');

    // There should be no errors initially.
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);

    // Triggering the file to be processed should still generate no errors.
    await handleSuccessfulRequest(
      AnalysisGetHoverParams(excludedFile.path, 0).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);

    // Opening the file should still generate no errors.
    await handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams([excludedFile.path]).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[excludedFile], isNull);
  }

  Future<void> test_importError() async {
    await setRoots(included: [workspaceRootPath], excluded: []);

    addTestFile('''
import 'does_not_exist.dart';
''');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    var errors = filesErrors[testFile]!;
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

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
linter:
  rules:
    - $camelCaseTypesLintName
''');

    addTestFile('class a { }');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();

    var lints = testFileAnalysisOptions.lintRules;

    // Registry should only contain single lint rule.
    expect(lints, hasLength(1));
    var lint = lints.first as LintRule;
    expect(lint.name, camelCaseTypesLintName);

    // Verify lint error result.
    var errors = filesErrors[testFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, testFile.path);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    expect(error.message, lint.description);
  }

  Future<void> test_notInAnalysisRoot() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    var otherFile = newFile('/other.dart', 'UnknownType V;');
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
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('');
    var brokenFile =
        newFile('$testPackageRootPath/.dart_tool/broken.dart', 'err');

    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    expect(filesErrors[brokenFile], isNull);

    // Add and overlay and give chance for the file to be analyzed (if
    // it would).
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        brokenFile.path: AddContentOverlay('err'),
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
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('');
    var brokenFile = getFile('$testPackageRootPath/broken.dart');

    // Add and overlay and give chance for the file to be analyzed.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        brokenFile.path: AddContentOverlay('err'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should now be errors.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));

    // Remove the overlay (this file no longer exists anywhere).
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        brokenFile.path: RemoveContentOverlay(),
      }).toRequest('1'),
    );

    // Wait for the timer to remove the overlay to fire.
    await Future.delayed(server.pendingFilesRemoveOverlayDelay);

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
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('');
    var brokenFile = getFile('$testPackageRootPath/broken.dart');

    // Add and overlay and give chance for the file to be analyzed.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        brokenFile.path: AddContentOverlay('err'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // There should now be errors.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));

    // Write the file to disk.
    brokenFile.writeAsStringSync('err');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // Remove the overlay.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        brokenFile.path: RemoveContentOverlay(),
      }).toRequest('1'),
    );
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);

    // Errors should not have been flushed since the file still exists without
    // the overlay.
    expect(filesErrors[brokenFile], hasLength(greaterThan(0)));
  }

  Future<void> test_ParserError() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    addTestFile('library lib');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    var errors = filesErrors[testFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, testFile.path);
    expect(error.location.offset, isPositive);
    expect(error.location.length, isNonNegative);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(error.message, isNotNull);
  }

  Future<void> test_pubspecFile() async {
    var pubspecFile = newPubspecYamlFile(testPackageRootPath, '''
version: 1.3.2
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[pubspecFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, pubspecFile.path);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    //
    // Fix the error and verify the new results.
    //
    pubspecFile.writeAsStringSync('''
name: sample
version: 1.3.2
''');
    await waitForTasksFinished();
    await pumpEventQueue();

    errors = filesErrors[pubspecFile]!;
    expect(errors, hasLength(0));
  }

  Future<void> test_pubspecFile_lint() async {
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
linter:
  rules:
    - sort_pub_dependencies
''');

    var pubspecFile = newPubspecYamlFile(testPackageRootPath, '''
name: sample

dependencies:
  b: any
  a: any
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    var errors = filesErrors[pubspecFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, pubspecFile.path);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    //
    // Fix the error and verify the new results.
    //
    pubspecFile.writeAsStringSync('''
name: sample

dependencies:
  a: any
  b: any
''');
    await waitForTasksFinished();
    await pumpEventQueue();

    errors = filesErrors[pubspecFile]!;
    expect(errors, hasLength(0));
  }

  Future<void> test_StaticWarning() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
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
    var errors = filesErrors[testFile]!;
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }
}
