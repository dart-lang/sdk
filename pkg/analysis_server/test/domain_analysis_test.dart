// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'domain_completion_test.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainBazelTest);
    defineReflectiveTests(AnalysisDomainPubTest);
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class AnalysisDomainBazelTest extends _AnalysisDomainTest {
  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  String get myPackageTestFilePath => '$myPackageLibPath/test.dart';

  @override
  void setUp() {
    super.setUp();
    newFile2('$workspaceRootPath/WORKSPACE', '');
  }

  Future<void> test_fileSystem_changeFile_buildFile() async {
    // This BUILD file does not enable null safety.
    newBazelBuildFile(myPackageRootPath, '');

    newFile2(myPackageTestFilePath, '''
void f(int? a) {}
''');

    await setRoots(included: [myPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Cannot use `int?` without enabling null safety.
    assertHasErrors(myPackageTestFilePath);

    // Enable null safety.
    newBazelBuildFile(myPackageRootPath, '''
dart_package(null_safety = True)
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have null safety enabled, so no errors.
    assertNoErrors(myPackageTestFilePath);
  }
}

@reflectiveTest
class AnalysisDomainPubTest extends _AnalysisDomainTest {
  Future<void> test_fileSystem_addFile_analysisOptions() async {
    deleteTestPackageAnalysisOptionsFile();
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Both a.dart and b.dart are analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [],
    );

    // Write the options file that excludes b.dart
    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for all files were flushed, and only a.dart is reported again.
    _assertFlushedResults([a_path, b_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  Future<void> test_fileSystem_addFile_analysisOptions_analysis() async {
    deleteTestPackageAnalysisOptionsFile();
    var a_path = '$testPackageLibPath/a.dart';
    var options_path = '$testPackageRootPath/analysis_options.yaml';

    newFile2(a_path, 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [options_path],
    );

    // Add 'analysis_options.yaml' that has an error.
    newFile2(options_path, '''
analyzer:
  error:
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Both files were analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, options_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_fileSystem_addFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile2('$testPackageLibPath/a.dart', '');

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    newFile2(path, '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No touch-screen.
    assertHasErrors(path);
  }

  Future<void> test_fileSystem_addFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';

    // We have to create the folder, otherwise there is nothing to watch.
    newFolder(testPackageLibPath);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart yet.
    assertNoErrorsNotification(a_path);

    _createFilesWithErrors([a_path]);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We created a.dart, so it should be analyzed.
    assertHasErrors(a_path);
  }

  Future<void> test_fileSystem_addFile_dart_dotFolder() async {
    var a_path = '$testPackageLibPath/.foo/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newFile2(b_path, r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertHasErrors(b_path);

    newFile2(a_path, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We added a.dart with `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_addFile_dart_excluded() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile2(b_path, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertHasErrors(b_path);

    newFile2(a_path, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We added a.dart with `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_addFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile2('$testPackageLibPath/a.dart', '');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // No `fix_data.yaml` to analyze yet.
    assertNoErrorsNotification(path);

    // Create it, will be analyzed.
    newFile2(path, '0: 1');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    assertHasErrors(path);

    // We don't recreate analysis contexts.
    _assertFlushedResults([]);
  }

  Future<void> test_fileSystem_addFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile2(a_path, '''
class A {}
''');

    newFile2(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `package_config.json`, recreate analysis contexts.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_addFile_pubspec_analysis() async {
    var a_path = '$testPackageLibPath/a.dart';
    var pubspec_path = '$testPackageRootPath/pubspec.yaml';

    newFile2(a_path, 'error');

    // Write an empty file to force a new analysis context.
    // We look for `pubspec.yaml` files only in analysis context roots.
    newAnalysisOptionsYamlFile2(testPackageRootPath, '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [pubspec_path],
    );

    // Add a non-Dart file that we know how to analyze.
    newFile2(pubspec_path, '''
name: sample
dependencies: true
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Both files were analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, pubspec_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_fileSystem_addFile_unrelated() async {
    var a_path = '$testPackageLibPath/a.dart';
    var unrelated_path = '$testPackageRootPath/unrelated.txt';

    newFile2(a_path, 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [unrelated_path],
    );

    // Add an unrelated file, no analysis.
    newFile2(unrelated_path, 'anything');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No analysis.
    _assertFlushedResults([]);
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [a_path]);
  }

  Future<void> test_fileSystem_changeFile_analysisOptions() async {
    var options_path = '$testPackageRootPath/analysis_options.yaml';
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';
    var c_path = '$testPackageLibPath/c.dart';

    _createFilesWithErrors([a_path, b_path, c_path]);

    // Exclude b.dart from analysis.
    newFile2(options_path, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only a.dart is analyzed, because b.dart is excluded.
    _assertAnalyzedFiles(
      hasErrors: [a_path, c_path],
      notAnalyzed: [b_path],
    );

    // Exclude c.dart from analysis.
    newFile2(options_path, r'''
analyzer:
  exclude:
    - lib/c.dart
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for all files were flushed, a.dart and b.dart analyzed.
    _assertFlushedResults([options_path, a_path, c_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      noErrors: [options_path],
      notAnalyzed: [c_path],
    );
  }

  Future<void> test_fileSystem_changeFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile2('$testPackageLibPath/a.dart', '');

    // Has an error - no touch screen.
    newFile2(path, '<manifest/>');

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // Forget and check that we did.
    forgetReceivedErrors();
    assertNoErrorsNotification(path);

    // Update the file, so analyze it.
    newFile2(path, '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // An error was reported.
    assertHasErrors(path);
  }

  Future<void> test_fileSystem_changeFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newFile2(a_path, r'''
class A2 {}
''');

    newFile2(b_path, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    assertNoErrors(a_path);
    assertHasErrors(b_path);
    forgetReceivedErrors();

    // Update a.dart so that b.dart has no error.
    newFile2(a_path, 'class A {}');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // The update of a.dart fixed the error in b.dart
    assertNoErrors(a_path);
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_dart_dotFolder() async {
    var a_path = '$testPackageLibPath/.foo/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newFile2(a_path, r'''
class B {}
''');

    newFile2(b_path, r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We have `B`, not `A`, in a.dart, so has errors.
    assertHasErrors(b_path);

    newFile2(a_path, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    assertNoErrorsNotification(a_path);

    // We changed a.dart, to have `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_dart_excluded() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile2(a_path, r'''
class B {}
''');

    newFile2(b_path, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We have `B`, not `A`, in a.dart, so has errors.
    assertHasErrors(b_path);

    newFile2(a_path, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We changed a.dart, to have `A`, so no errors.
    assertNoErrors(b_path);
  }

  Future<void> test_fileSystem_changeFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile2('$testPackageLibPath/a.dart', '');

    // This file has an error.
    newFile2(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file was analyzed.
    assertHasErrors(path);

    // Replace with the context that does not have errors.
    newFile2(path, r'''
version: 1
transforms: []
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    assertNoErrors(path);

    // We don't recreate analysis contexts.
    _assertFlushedResults([]);
  }

  Future<void> test_fileSystem_changeFile_hasOverlay_removeOverlay() async {
    newFile2(testFilePath, '');

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(''),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The test file (overlay) is analyzed, no errors.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      noErrors: [testFilePathPlatform],
      notAnalyzed: [],
    );

    // Change the file, has errors.
    newFile2(testFilePath, 'error');

    // But the overlay is still present, so the file is not analyzed.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      notAnalyzed: [testFilePathPlatform],
    );

    // Ask to remove the overlay, still active, start a timer.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: RemoveContentOverlay(),
      }).toRequest('0'),
    );

    // Wait for the timer to remove the overlay to fire.
    await Future.delayed(server.pendingFilesRemoveOverlayDelay);

    // The file has errors.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [testFilePathPlatform],
      noErrors: [],
      notAnalyzed: [],
    );
  }

  Future<void>
      test_fileSystem_changeFile_hasOverlay_removeOverlay_delayed() async {
    // Use long delay, so that it does not happen.
    server.pendingFilesRemoveOverlayDelay = const Duration(seconds: 300);

    newFile2(testFilePath, '');

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(''),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The test file (overlay) is analyzed, no errors.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      noErrors: [testFilePathPlatform],
      notAnalyzed: [],
    );

    // Change the file, has errors.
    modifyFile(testFilePath, 'error');

    // But the overlay is still present, so the file is not analyzed.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      notAnalyzed: [testFilePathPlatform],
    );

    // Ask to remove the overlay, still active, start a timer.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: RemoveContentOverlay(),
      }).toRequest('0'),
    );

    // Long timer, so still not analyzed.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      notAnalyzed: [testFilePathPlatform],
    );

    // Change the file again, has errors.
    newFile2(testFilePath, 'error');

    // The timer cancelled on the watch event, and the file analyzed.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [testFilePathPlatform],
      noErrors: [],
      notAnalyzed: [],
    );
  }

  Future<void> test_fileSystem_changeFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile2(a_path, '''
class A {}
''');

    newFile2(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // The default `package_config.json` is without `package:aaa`.
    // We cannot resolve `package:aaa/a.dart`
    assertHasErrors(testFilePath);

    // Write `package_config.json`, recreate analysis contexts.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_deleteFile_analysisOptions() async {
    var options_path = '$testPackageRootPath/analysis_options.yaml';
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    // Exclude b.dart from analysis.
    newFile2(options_path, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only a.dart is analyzed, because b.dart is excluded.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );

    // Delete the options file.
    deleteFile(options_path);

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for a.dart were flushed, a.dart and b.dart analyzed.
    _assertFlushedResults([options_path, a_path]);
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [options_path],
    );
  }

  Future<void> test_fileSystem_deleteFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile2('$testPackageLibPath/a.dart', '');

    // Has an error - no touch screen.
    newFile2(path, '<manifest/>');

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // An error was reported.
    _assertAnalyzedFiles(hasErrors: [path], notAnalyzed: []);

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [path]);
  }

  Future<void> test_fileSystem_deleteFile_dart() async {
    var a_path = '$testPackageLibPath/a.dart';

    _createFilesWithErrors([a_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertHasErrors(a_path);

    deleteFile(a_path);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, its errors should be flushed.
    _assertFlushedResults([a_path]);
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_fileSystem_deleteFile_dart_excluded() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile2(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile2(a_path, r'''
class A {}
''');

    newFile2(b_path, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    assertNoErrorsNotification(a_path);

    // We have `A` in a.dart, so no errors.
    assertNoErrors(b_path);

    deleteFile(a_path);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, so `A` cannot be resolved.
    assertHasErrors(b_path);
  }

  Future<void> test_fileSystem_deleteFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile2('$testPackageLibPath/a.dart', '');

    // This file has an error.
    newFile2(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file was analyzed.
    _assertAnalyzedFiles(hasErrors: [path], notAnalyzed: []);

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    _assertAnalyzedFiles(hasErrors: [], notAnalyzed: [path]);
  }

  Future<void> test_fileSystem_deleteFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile2(a_path, '''
class A {}
''');

    // Write the empty file, without `package:aaa`.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile2(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // Delete `package_config.json`, recreate analysis contexts.
    deleteFile(
      '$testPackageRootPath/.dart_tool/package_config.json',
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We cannot resolve 'package:aaa/a.dart', so errors.
    assertHasErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  /// This test ensures that when an `addOverlay` cancels any pending
  /// `removeOverlay` timer, it also removes it, so that a subsequent watch
  /// event does not still try to process it.
  Future<void>
      test_fileSystem_removeOverlay_addOverlay_changeFile_changeOverlay() async {
    // Use long delay, so that it does not happen.
    server.pendingFilesRemoveOverlayDelay = const Duration(seconds: 300);

    newFile2(testFilePath, '');

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(''),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The test file (overlay) is analyzed, no errors.
    await _waitAnalysisComplete();
    _assertAnalyzedFiles(
      hasErrors: [],
      noErrors: [testFilePathPlatform],
      notAnalyzed: [],
    );

    // Ask to remove the overlay, still active, start a timer.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: RemoveContentOverlay(),
      }).toRequest('0'),
    );

    // Re-add an overlay. Should cancel the timer and replace the overlay.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(''),
      }).toRequest('0'),
    );

    // Change the file to trigger the watcher. Since the request above should
    // have cancelled (and removed) the timer, this should not do anything
    // (specifically, it should not remove the new overlay).
    modifyFile(testFilePath, 'error');

    // The overlay should still be present, so we should be able to change it.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: ChangeContentOverlay(
          [SourceEdit(0, 0, '//')],
        ),
      }).toRequest('0'),
    );
  }

  Future<void> test_setPriorityFiles() async {
    var a = getFile('$workspaceRootPath/foo/lib/a.dart');
    var b = getFile('$workspaceRootPath/foo/lib/b.dart');
    var c = getFile('$workspaceRootPath/bar/lib/c.dart');
    var d = getFile('$workspaceRootPath/bar/lib/d.dart');

    a.writeAsStringSync('');
    b.writeAsStringSync('');
    c.writeAsStringSync('');
    d.writeAsStringSync('');

    await handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams(
        [a.path, c.path],
      ).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    var hasPath = <String>{};
    for (var notification in analysisErrorsNotifications) {
      var path = notification.file;
      if (!hasPath.add(path)) {
        fail('Duplicate: $path');
      } else if (path == a.path || path == c.path) {
        if (hasPath.contains(b.path) || hasPath.contains(d.path)) {
          fail('Priority after non-priority');
        }
      }
    }
  }

  Future<void> test_setPriorityFiles_notAbsolute() async {
    var response = await handleRequest(
      AnalysisSetPriorityFilesParams(
        ['a.dart'],
      ).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_FILE_PATH_FORMAT,
      ),
    );
  }

  Future<void> test_setPriorityFiles_withoutRoots() async {
    await handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams(
        [convertPath('$testPackageLibPath/a.dart')],
      ).toRequest('0'),
    );
  }

  Future<void> test_setRoots_excluded_notAbsolute() async {
    var response = await handleRequest(
      AnalysisSetAnalysisRootsParams(
        [workspaceRootPath],
        ['foo'],
        packageRoots: {},
      ).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_FILE_PATH_FORMAT,
      ),
    );
  }

  Future<void> test_setRoots_excluded_notNormalized() async {
    var response = await handleRequest(
      AnalysisSetAnalysisRootsParams(
        [workspaceRootPath],
        [convertPath('/foo/../bar')],
        packageRoots: {},
      ).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_FILE_PATH_FORMAT,
      ),
    );
  }

  Future<void> test_setRoots_included_notAbsolute() async {
    var response = await handleRequest(
      AnalysisSetAnalysisRootsParams(
        ['foo'],
        [],
        packageRoots: {},
      ).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_FILE_PATH_FORMAT,
      ),
    );
  }

  Future<void> test_setRoots_included_notNormalized() async {
    var response = await handleRequest(
      AnalysisSetAnalysisRootsParams(
        [convertPath('/foo/../bar')],
        [],
        packageRoots: {},
      ).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_FILE_PATH_FORMAT,
      ),
    );
  }

  Future<void> test_setRoots_includedFile() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [a_path], excluded: []);

    // Only a.dart is included, so b.dart is not analyzed.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  Future<void> test_setRoots_includedFile_setRoots() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([a_path, b_path]);

    // Include only single file.
    await setRoots(included: [a_path], excluded: []);
    await server.onAnalysisComplete;

    // So, only a.dart is analyzed, and b.dart is not.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );

    // Include the folder that contains both a.dart and b.dart
    await setRoots(included: [testPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // So, both a.dart and b.dart are analyzed.
    _assertAnalyzedFiles(
      hasErrors: [a_path, b_path],
      notAnalyzed: [],
    );
  }

  Future<void> test_setRoots_includedFileFolder() async {
    var includedFile = '$testPackageLibPath/a.dart';
    var includedFolder = '$testPackageLibPath/foo';
    var includedFolderFile1 = '$includedFolder/1.dart';
    var includedFolderFile2 = '$includedFolder/2.dart';
    var notIncludedFile = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([
      includedFile,
      includedFolderFile1,
      includedFolderFile2,
      notIncludedFile,
    ]);

    await setRoots(included: [includedFile, includedFolder], excluded: []);
    await server.onAnalysisComplete;

    // We can combine a file, and a folder as included paths.
    // And the file that is not in there is not analyzed.
    _assertAnalyzedFiles(hasErrors: [
      includedFile,
      includedFolderFile1,
      includedFolderFile2,
    ], notAnalyzed: [
      notIncludedFile,
    ]);
  }

  Future<void> test_setRoots_includedFolder_analysisOptions_exclude() async {
    var a_path = '$testPackageLibPath/a.dart';
    var b_path = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  exclude:
    - "**/b.dart"
''');

    _createFilesWithErrors([a_path, b_path]);

    await setRoots(included: [workspaceRootPath], excluded: []);

    // b.dart is excluded using the options file.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [b_path],
    );
  }

  @FailingTest(reason: 'Not implemented in ContextLocator')
  Future<void> test_setRoots_includedFolder_excludedFile() async {
    var a_path = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([a_path, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: [excluded_path],
    );
    await server.onAnalysisComplete;

    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [excluded_path],
    );
  }

  Future<void> test_setRoots_includedFolder_excludedFolder() async {
    var a_path = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([a_path, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: ['$testPackageRootPath/excluded'],
    );
    await server.onAnalysisComplete;

    // a.dart is analyzed, but b.dart is in the excluded folder.
    _assertAnalyzedFiles(
      hasErrors: [a_path],
      notAnalyzed: [excluded_path],
    );
  }

  Future<void> test_setRoots_includedFolder_notExisting() async {
    var existingFolder_path = '$testPackageLibPath/exiting';
    var notExistingFolder_path = '$testPackageLibPath/notExisting';
    var existingFile_path = '$existingFolder_path/1.dart';
    var notExistingFile_path = '$notExistingFolder_path/1.dart';

    _createFilesWithErrors([
      existingFile_path,
    ]);

    await setRoots(included: [
      existingFolder_path,
      notExistingFolder_path,
    ], excluded: []);
    await server.onAnalysisComplete;

    // The not existing root does not prevent analysis of the existing one.
    _assertAnalyzedFiles(hasErrors: [
      existingFile_path,
    ], notAnalyzed: [
      notExistingFile_path,
    ]);
  }

  Future<void> test_setRoots_notDartFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile2('$testPackageLibPath/a.dart', '');

    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    newFile2(path, '<manifest/>');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // No touch-screen.
    assertHasErrors(path);
  }

  Future<void> test_setRoots_notDartFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    // `lib/fix_data.yaml` will be analyzed.
    newFile2(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    assertHasErrors(path);
  }

  Future<void> test_setRoots_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var a_path = '$aaaRootPath/lib/a.dart';

    newFile2(a_path, '''
class A {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile2(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    // create project and wait for analysis
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNoErrors(testFilePath);

    // errors are not reported for packages
    assertNoErrorsNotification(a_path);
  }

  Future<void> test_updateContent_addOverlay() async {
    newFile2('$testFilePath', 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file in the file system has errors.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [testFilePathPlatform],
      noErrors: [],
      notAnalyzed: [],
    );

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(''),
      }).toRequest('0'),
    );

    // A new errors notification was received, no errors.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [],
      noErrors: [testFilePathPlatform],
      notAnalyzed: [],
    );
  }

  Future<void> test_updateContent_changeOverlay() async {
    newFile2('$testFilePath', '');

    // Add the content with an error.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay('var v = 0'),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The overlay has an error.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [testFilePathPlatform],
      noErrors: [],
      notAnalyzed: [],
    );

    // Add the missing `;`.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: ChangeContentOverlay([
          SourceEdit(9, 0, ';'),
        ]),
      }).toRequest('0'),
    );

    // A new errors notification was received, no errors.
    await server.onAnalysisComplete;
    _assertAnalyzedFiles(
      hasErrors: [],
      noErrors: [testFilePathPlatform],
      notAnalyzed: [],
    );
  }

  Future<void> test_updateContent_notAbsolute() async {
    var response = await handleRequest(
      AnalysisUpdateContentParams({
        'a.dart': AddContentOverlay(''),
      }).toRequest('0'),
    );
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_updateContent_outOfRange_beyondEnd() {
    return _updateContent_outOfRange('012', SourceEdit(0, 5, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeLength() {
    return _updateContent_outOfRange('', SourceEdit(3, -1, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeOffset() {
    return _updateContent_outOfRange('', SourceEdit(-1, 3, 'foo'));
  }

  Future<void> _updateContent_outOfRange(
    String initialContent,
    SourceEdit edit,
  ) async {
    newFile2('$testFilePath', initialContent);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay(initialContent),
      }).toRequest('0'),
    );

    var response = await handleRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: ChangeContentOverlay([edit]),
      }).toRequest('0'),
    );

    expect(
      response,
      isResponseFailure(
        '0',
        RequestErrorCode.INVALID_OVERLAY_CHANGE,
      ),
    );
  }

  /// Pump the event queue, so that watch events are processed.
  /// Wait for analysis to complete.
  /// Repeat a few times, eventually there will be no work to do.
  Future<void> _waitAnalysisComplete() async {
    for (var i = 0; i < 128; i++) {
      pumpEventQueue();
      await server.onAnalysisComplete;
    }
  }
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisTest {
  Map<String, List<HighlightRegion>> filesHighlights = {};

  final Completer<void> _resultsAvailable = Completer();

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      filesHighlights[params.file] = params.regions;
      _resultsAvailable.complete();
    }
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('int V = 42;');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_noSuchFile() async {
    var file = convertPath('/no-such-file.dart');
    addTestFile('// no matter');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_external() async {
    var pkgFile = newFile2('/packages/pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''').path;
    newPackageConfigJsonFile(
      '/project',
      (PackageConfigFileBuilder()
            ..add(name: 'pkgA', rootPath: '/packages/pkgA'))
          .toContent(toUriStr: toUriStr),
    );
    //
    addTestFile('''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_inRoot() async {
    var pkgA = convertPath('/pkgA');
    var pkgB = convertPath('/pkgA');
    var pkgFileA = newFile2('$pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''').path;
    newFile2('$pkgA/lib/libB.dart', '''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    // add 'pkgA' and 'pkgB' as projects
    newFolder(projectPath);
    await setRoots(included: [pkgA, pkgB], excluded: []);
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFileA], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFileA);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFileA], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_notUsed() async {
    var pkgFile = newFile2('/packages/pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''').path;
    newPackageConfigJsonFile(
      '/project',
      (PackageConfigFileBuilder()
            ..add(name: 'pkgA', rootPath: '/packages/pkgA'))
          .toContent(toUriStr: toUriStr),
    );
    //
    addTestFile('// no "pkgA" reference');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // make it a priority file, so make analyzable
    server.setPriorityFiles('0', [pkgFile]);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_sdkFile() async {
    var file = convertPath('/sdk/lib/core/core.dart');
    addTestFile('// no matter');
    await createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[file], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isNotEmpty);
  }

  Future<void> test_beforeAnalysis() async {
    addTestFile('int V = 42;');
    await createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('int V = 42;');
    await createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    var params = pluginManager.analysisSetSubscriptionsParams!;
    var subscriptions = params.subscriptions;
    expect(subscriptions, hasLength(1));
    var files = subscriptions[plugin.AnalysisService.HIGHLIGHTS];
    expect(files, [testFile]);
  }
}

class _AnalysisDomainTest extends PubPackageAnalysisServerTest {
  final List<AnalysisErrorsParams> analysisErrorsNotifications = [];
  final Map<String, List<AnalysisError>> filesErrors = {};

  /// The files for which `analysis.flushResults` was received.
  final List<String> flushResults = [];

  void assertHasErrors(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isNotEmpty, reason: path);
  }

  void assertNoErrors(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isEmpty, reason: path);
  }

  void assertNoErrorsNotification(String path) {
    path = convertPath(path);
    expect(filesErrors[path], isNull, reason: path);
  }

  void forgetReceivedErrors() {
    filesErrors.clear();
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      var decoded = AnalysisFlushResultsParams.fromNotification(notification);
      flushResults.addAll(decoded.files);
      decoded.files.forEach(filesErrors.remove);
    }
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      analysisErrorsNotifications.add(decoded);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  void _assertAnalyzedFiles({
    required List<String> hasErrors,
    List<String> noErrors = const [],
    required List<String> notAnalyzed,
  }) {
    for (var path in hasErrors) {
      assertHasErrors(path);
    }

    for (var path in noErrors) {
      assertNoErrors(path);
    }

    for (var path in notAnalyzed) {
      assertNoErrorsNotification(path);
    }

    filesErrors.clear();
  }

  void _assertFlushedResults(List<String> paths) {
    var convertedPaths = paths.map(convertPath).toList();
    expect(flushResults, unorderedEquals(convertedPaths));
    flushResults.clear();
  }

  /// Create files with a content that has a compile time error.
  /// So, when analyzed, these files will satisfy [assertHasErrors].
  void _createFilesWithErrors(List<String> paths) {
    for (var path in paths) {
      newFile2(path, 'error');
    }
  }
}
