// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'mocks.dart';
import 'utils/tree_string_sink.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainBlazeTest);
    defineReflectiveTests(AnalysisDomainPubTest);
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class AnalysisDomainBlazeTest extends _AnalysisDomainTest {
  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  String get myPackageTestFilePath => '$myPackageLibPath/test.dart';

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/${file_paths.blazeWorkspaceMarker}', '');
  }

  Future<void> test_fileSystem_changeFile_buildFile_legacy() async {
    // Make it a Blaze package.
    newBlazeBuildFile(myPackageRootPath, r'''
# foo
''');

    newFile(myPackageTestFilePath, '''
void f(int? a) {}
''');

    await setRoots(included: [myPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // No errors after initial analysis.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/dart/my/lib/test.dart
  errors: empty
''');

    // Change BUILD file, nothing interesting.
    newBlazeBuildFile(myPackageRootPath, r'''
# bar
''');

    await pumpEventQueue(times: 5000);
    await server.onAnalysisComplete;

    // BUILD file change caused rebuilding analysis contexts.
    assertNotificationsText(r'''
AnalysisFlush
  /home/dart/my/lib/test.dart
AnalysisErrors
  file: /home/dart/my/lib/test.dart
  errors: empty
''');
  }
}

@reflectiveTest
class AnalysisDomainPubTest extends _AnalysisDomainTest {
  Future<void> test_fileSystem_addFile_analysisOptions() async {
    deleteTestPackageAnalysisOptionsFile();

    _createFilesWithErrors([
      '$testPackageLibPath/a.dart',
      '$testPackageLibPath/b.dart',
    ]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Both a.dart and b.dart are analyzed.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    // Write the options file that excludes b.dart
    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await pumpEventQueue(times: 5000);
    await server.onAnalysisComplete;

    // Errors for all files were flushed, b.dart is not reported.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/a.dart
  /home/test/lib/b.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_analysisOptions_analysis() async {
    deleteTestPackageAnalysisOptionsFile();
    _createFilesWithErrors([
      '$testPackageLibPath/a.dart',
    ]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Add 'analysis_options.yaml' that has an error.
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  error:
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Both files were analyzed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/a.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_androidManifestXml() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    newFile('$testPackageLibPath/a.dart', '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    newFile('$testPackageRootPath/AndroidManifest.xml', '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No touch-screen.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_dart() async {
    // We have to create the folder, otherwise there is nothing to watch.
    newFolder(testPackageLibPath);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart yet.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
''');

    _createFilesWithErrors([
      '$testPackageLibPath/a.dart',
    ]);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We created a.dart, so it should be analyzed.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_dart_dotFolder() async {
    var aPath = '$testPackageLibPath/.foo/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newFile(bPath, r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    newFile(aPath, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    // We added a.dart with `A`, so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_addFile_dart_excluded() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(bPath, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We don't have a.dart, so the import cannot be resolved.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    newFile(aPath, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    // We added a.dart with `A`, so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_addFile_fixDataFolderYaml() async {
    var path = '$testPackageLibPath/fix_data/foo.yaml';

    newFile('$testPackageLibPath/a.dart', '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // No `fix_data.yaml` to analyze yet.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Create it, will be analyzed.
    newFile(path, '0: 1');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    // We don't recreate analysis contexts.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/fix_data/foo.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/fix_data/foo.yaml
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // No `fix_data.yaml` to analyze yet.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Create it, will be analyzed.
    newFile(path, '0: 1');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // And it has errors.
    // We don't recreate analysis contexts.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var aPath = '$aaaRootPath/lib/a.dart';

    newFile(aPath, '''
class A {}
''');

    newFile(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We cannot resolve `package:aaa/a.dart`
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');

    // Write `package_config.json`, recreate analysis contexts.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We rebuilt analysis contexts.
    // We have `A` in 'package:aaa/a.dart', so no errors.
    // Errors are not reported for packages.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/test.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_addFile_pubspec_analysis() async {
    var aPath = '$testPackageLibPath/a.dart';
    var pubspecPath = '$testPackageRootPath/pubspec.yaml';

    newFile(aPath, 'error');

    // Write an empty file to force a new analysis context.
    // We look for `pubspec.yaml` files only in analysis context roots.
    newAnalysisOptionsYamlFile(testPackageRootPath, '');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Add a non-Dart file that we know how to analyze.
    newFile(pubspecPath, '''
name: sample
dependencies: true
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We rebuilt analysis contexts.
    // All files were analyzed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/a.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_addFile_unrelated() async {
    var aPath = '$testPackageLibPath/a.dart';
    var unrelatedPath = '$testPackageRootPath/unrelated.txt';

    newFile(aPath, 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Add an unrelated file, no analysis.
    newFile(unrelatedPath, 'anything');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No analysis.
    assertNotificationsText(r'''
''');
  }

  Future<void> test_fileSystem_changeFile_analysisOptions() async {
    var optionsPath = '$testPackageRootPath/analysis_options.yaml';
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';
    var cPath = '$testPackageLibPath/c.dart';

    _createFilesWithErrors([aPath, bPath, cPath]);

    // Exclude 'b.dart' from analysis.
    newFile(optionsPath, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only 'a.dart' and 'c.dart' are analyzed, because 'b.dart' is excluded.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/c.dart
  errors: notEmpty
''');

    // Exclude 'c.dart' from analysis.
    newFile(optionsPath, r'''
analyzer:
  exclude:
    - lib/c.dart
''');

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Analysis contexts were rebuilt.
    // Only 'a.dart' and 'b.dart' analyzed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/a.dart
  /home/test/lib/c.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_changeFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', '');

    // Has an error - no touch screen.
    newFile(path, '<manifest/>');

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Update the file, so analyze it.
    newFile(path, '<manifest/>');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // An error was reported.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_changeFile_dart() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newFile(aPath, r'''
class A2 {}
''');

    newFile(bPath, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    // Update a.dart so that b.dart has no error.
    newFile(aPath, 'class A {}');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // The update of a.dart fixed the error in b.dart
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_changeFile_dart_dotFolder() async {
    var aPath = '$testPackageLibPath/.foo/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newFile(aPath, r'''
class B {}
''');

    newFile(bPath, r'''
import '.foo/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    // We have `B`, not `A`, in a.dart, so has errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    newFile(aPath, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // 'a.dart' is in a dot-folder, so excluded from analysis.
    // We changed a.dart, to have `A`, so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_changeFile_dart_excluded() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(aPath, r'''
class B {}
''');

    newFile(bPath, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    // We have `B`, not `A`, in a.dart, so has errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');

    newFile(aPath, r'''
class A {}
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We changed a.dart, to have `A`, so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_changeFile_fixDataFolderYaml() async {
    var path = '$testPackageLibPath/fix_data/foo.yaml';

    newFile('$testPackageLibPath/a.dart', '');

    // This file has an error.
    newFile(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // The file was analyzed.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data/foo.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Replace with the content that does not have errors.
    newFile(path, r'''
version: 1
transforms: []
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No errors in `foo.yaml` anymore.
    // We don't recreate analysis contexts.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/fix_data/foo.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data/foo.yaml
  errors: empty
''');
  }

  Future<void> test_fileSystem_changeFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', '');

    // This file has an error.
    newFile(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // The file was analyzed.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Replace with the content that does not have errors.
    newFile(path, r'''
version: 1
transforms: []
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // No errors in `fix_data.yaml` anymore.
    // We don't recreate analysis contexts.
    // TODO(scheglov): Why duplicate analysis?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: empty
''');
  }

  Future<void> test_fileSystem_changeFile_hasOverlay_removeOverlay() async {
    newFile(testFilePath, '');

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay(''),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The test file (overlay) is analyzed, no errors.
    await _waitAnalysisComplete();
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');

    // Change the file, has errors.
    newFile(testFilePath, 'error');

    // But the overlay is still present, so the file is not analyzed.
    await _waitAnalysisComplete();
    assertNotificationsText(r'''
''');

    // Remove the overlay, now the file will be read.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: RemoveContentOverlay(),
      }).toRequest('0'),
    );

    // The file has errors.
    await _waitAnalysisComplete();
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_changeFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var aPath = '$aaaRootPath/lib/a.dart';

    newFile(aPath, '''
class A {}
''');

    newFile(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // The default `package_config.json` is without `package:aaa`.
    // We cannot resolve `package:aaa/a.dart`
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');

    // Write `package_config.json`, recreate analysis contexts.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    // Errors are not reported for packages.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/test.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');
  }

  Future<void> test_fileSystem_deleteFile_analysisOptions() async {
    var optionsPath = '$testPackageRootPath/analysis_options.yaml';
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([aPath, bPath]);

    // Exclude b.dart from analysis.
    newFile(optionsPath, r'''
analyzer:
  exclude:
    - lib/b.dart
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Only a.dart is analyzed, because b.dart is excluded.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Delete the options file.
    deleteFile(optionsPath);

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // Errors for a.dart were flushed, a.dart and b.dart analyzed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/a.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_deleteFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', '');

    // Has an error - no touch screen.
    newFile(path, '<manifest/>');

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // An error was reported.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/AndroidManifest.xml
''');
  }

  /// Tests that deleting and re-creating a file while an overlay is active
  /// keeps the diagnotics when the overlay is then removed, then removes them
  /// when the file is deleted.
  ///
  /// https://github.com/dart-lang/sdk/issues/53475
  Future<void> test_fileSystem_deleteFile_createFile_withOverlay_dart() async {
    var aPath = convertPath('$testPackageLibPath/a.dart');

    _createFilesWithErrors([aPath]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Initial file has errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Set the overlay, with a different content.
    // We get another notification with errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        aPath: AddContentOverlay('error2'),
      }).toRequest('0'),
    );
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Delete the file, we have the overlay, so no notifications.
    deleteFile(aPath);
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
''');

    // Re-creating the file, we have the overlay, so no notifications.
    _createFilesWithErrors([aPath]);
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
''');

    // Remove the overlay, the file has different content, so notification.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        aPath: RemoveContentOverlay(),
      }).toRequest('1'),
    );
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Delete the file, errors are now gone.
    deleteFile(aPath);
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/a.dart
''');
  }

  Future<void> test_fileSystem_deleteFile_dart() async {
    var aPath = '$testPackageLibPath/a.dart';

    _createFilesWithErrors([aPath]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // a.dart was analyzed
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    deleteFile(aPath);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, its errors should be flushed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/a.dart
''');
  }

  Future<void> test_fileSystem_deleteFile_dart_excluded() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, r'''
analyzer:
  exclude:
    - "**/a.dart"
''');

    newFile(aPath, r'''
class A {}
''');

    newFile(bPath, r'''
import 'a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We excluded 'a.dart' from analysis, no errors notification for it.
    // We have `A` in a.dart, so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: empty
''');

    deleteFile(aPath);
    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We deleted a.dart, so `A` cannot be resolved.
    // TODO(scheglov): Should we get flush for a.dart also?
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');
  }

  Future<void> test_fileSystem_deleteFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    newFile('$testPackageLibPath/a.dart', '');

    // This file has an error.
    newFile(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // The file was analyzed.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');

    // Delete the file.
    deleteFile(path);
    await pumpEventQueue();

    // We received a flush notification.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/fix_data.yaml
''');
  }

  @FailingTest(
      issue: 'https://github.com/dart-lang/sdk/issues/55580', reason: '''
-------- Actual --------

AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/test.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
------------------------
''')
  Future<void> test_fileSystem_deleteFile_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var aPath = '$aaaRootPath/lib/a.dart';

    newFile(aPath, '''
class A {}
''');

    // Write the empty file, without `package:aaa`.
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');

    // Delete `package_config.json`, recreate analysis contexts.
    deleteFile(
      '$testPackageRootPath/.dart_tool/package_config.json',
    );

    await pumpEventQueue();
    await server.onAnalysisComplete;

    // We cannot resolve 'package:aaa/a.dart', so errors.
    // Errors are not reported for packages.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/analysis_options.yaml
  /home/test/lib/test.dart
  /home/test/pubspec.yaml
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');
  }

  /// Tests that deleting a file does not clear diagnostics if there's still
  /// an active overlay for the file.
  ///
  /// https://github.com/dart-lang/sdk/issues/53475
  Future<void> test_fileSystem_deleteFile_withOverlay_dart() async {
    var aPath = convertPath('$testPackageLibPath/a.dart');

    _createFilesWithErrors([aPath]);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // Initial file has errors.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Set overlay with different content, with errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        aPath: AddContentOverlay('error2'),
      }).toRequest('0'),
    );
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Delete file, has the overlay, no notifications.
    deleteFile(aPath);
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
''');

    // After removing the overlay, errors are gone.
    // TODO(scheglov): why not flush?
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        aPath: RemoveContentOverlay(),
      }).toRequest('1'),
    );
    await pumpEventQueue();
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: empty
''');
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
    await server.onAnalysisComplete;

    // a.dart and c.dart are priority files.
    // So, they are analyzed before b.dart and d.dart
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/foo/lib/a.dart
  errors: empty
AnalysisErrors
  file: /home/bar/lib/c.dart
  errors: empty
AnalysisErrors
  file: /home/foo/lib/b.dart
  errors: empty
AnalysisErrors
  file: /home/bar/lib/d.dart
  errors: empty
''');
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
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([aPath, bPath]);

    await setRoots(included: [aPath], excluded: []);

    // Only a.dart is included, so b.dart is not analyzed.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_includedFile_setRoots() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    _createFilesWithErrors([aPath, bPath]);

    // Include only single file.
    await setRoots(included: [aPath], excluded: []);
    await server.onAnalysisComplete;

    // So, only a.dart is analyzed, and b.dart is not.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');

    // Include the folder that contains both a.dart and b.dart
    await setRoots(included: [testPackageRootPath], excluded: []);
    await server.onAnalysisComplete;

    // So, both a.dart and b.dart are analyzed.
    assertNotificationsText(r'''
AnalysisFlush
  /home/test/lib/a.dart
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/b.dart
  errors: notEmpty
''');
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
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/foo/1.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/foo/2.dart
  errors: notEmpty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_includedFolder_analysisOptions_exclude() async {
    var aPath = '$testPackageLibPath/a.dart';
    var bPath = '$testPackageLibPath/b.dart';

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  exclude:
    - "**/b.dart"
''');

    _createFilesWithErrors([aPath, bPath]);

    await setRoots(included: [workspaceRootPath], excluded: []);

    // b.dart is excluded using the options file.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  @FailingTest(reason: 'Not implemented in ContextLocator')
  Future<void> test_setRoots_includedFolder_excludedFile() async {
    var aPath = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([aPath, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: [excluded_path],
    );
    await server.onAnalysisComplete;

    fail('Not implemented');
  }

  Future<void> test_setRoots_includedFolder_excludedFolder() async {
    var aPath = '$testPackageLibPath/a.dart';
    var excluded_path = '$testPackageRootPath/excluded/b.dart';

    _createFilesWithErrors([aPath, excluded_path]);

    await setRoots(
      included: [workspaceRootPath],
      excluded: ['$testPackageRootPath/excluded'],
    );
    await server.onAnalysisComplete;

    // a.dart is analyzed, but b.dart is in the excluded folder.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_includedFolder_notExisting() async {
    var existingFolder_path = '$testPackageLibPath/exiting';
    var notExistingFolder_path = '$testPackageLibPath/notExisting';
    var existingFile_path = '$existingFolder_path/1.dart';

    _createFilesWithErrors([
      existingFile_path,
    ]);

    await setRoots(included: [
      existingFolder_path,
      notExistingFolder_path,
    ], excluded: []);
    await server.onAnalysisComplete;

    // The not existing root does not prevent analysis of the existing one.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/exiting/1.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_notDartFile_analysisOptions_excluded() async {
    deleteTestPackageAnalysisOptionsFile();
    var aPath = '$testPackageLibPath/a.dart';
    var optionsPath = '$testPackageRootPath/analysis_options.yaml';

    newFile(aPath, 'error');

    // 'analysis_options.yaml' that has an error and excludes itself.
    newFile(optionsPath, '''
analyzer:
  exclude:
    - analysis_options.yaml
  error:
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_notDartFile_androidManifestXml() async {
    var path = '$testPackageRootPath/AndroidManifest.xml';

    newFile('$testPackageLibPath/a.dart', '');

    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  optional-checks:
    chrome-os-manifest-checks: true
''');

    newFile(path, '<manifest/>');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // No touch-screen.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/AndroidManifest.xml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
''');
  }

  Future<void> test_setRoots_notDartFile_fixDataYaml() async {
    var path = '$testPackageLibPath/fix_data.yaml';

    // `lib/fix_data.yaml` will be analyzed.
    newFile(path, '0: 1');

    await setRoots(included: [workspaceRootPath], excluded: []);

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: notEmpty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
''');
  }

  Future<void> test_setRoots_notDartFile_fixDataYaml_empty() async {
    var path = '$testPackageLibPath/fix_data.yaml';
    newFile(path, '');

    await setRoots(included: [workspaceRootPath], excluded: []);

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
''');
  }

  Future<void> test_setRoots_notDartFile_fixDataYaml_onlyComments() async {
    var path = '$testPackageLibPath/fix_data.yaml';
    newFile(path, '# one\n#two');

    await setRoots(included: [workspaceRootPath], excluded: []);

    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/fix_data.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
''');
  }

  Future<void> test_setRoots_notDartFile_pubspec_excluded() async {
    deleteTestPackageAnalysisOptionsFile();
    var aPath = '$testPackageLibPath/a.dart';
    var optionsPath = '$testPackageRootPath/analysis_options.yaml';

    newFile(aPath, 'error');

    writeTestPackagePubspecYamlFile('''
name:
  - error
''');

    // 'analysis_options.yaml' that excludes pubspec.yaml.
    newFile(optionsPath, '''
analyzer:
  exclude:
    - pubspec.yaml
''');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // No pubspec.yaml
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/a.dart
  errors: notEmpty
''');
  }

  Future<void> test_setRoots_packageConfigJsonFile() async {
    var aaaRootPath = '/packages/aaa';
    var aPath = '$aaaRootPath/lib/a.dart';

    newFile(aPath, '''
class A {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRootPath),
    );

    newFile(testFilePath, '''
import 'package:aaa/a.dart';
void f(A a) {}
''');

    // create project and wait for analysis
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    // We have `A` in 'package:aaa/a.dart', so no errors.
    // Errors are not reported for packages.
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');
  }

  Future<void> test_updateContent_addOverlay() async {
    newFile(testFilePath, 'error');

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The file in the file system has errors.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');

    // Add an overlay without errors.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay(''),
      }).toRequest('0'),
    );

    // A new errors notification was received, no errors.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');
  }

  Future<void> test_updateContent_changeOverlay() async {
    newFile(testFilePath, '');

    // Add the content with an error.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay('var v = 0'),
      }).toRequest('0'),
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    // The overlay has an error.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/analysis_options.yaml
  errors: empty
AnalysisErrors
  file: /home/test/pubspec.yaml
  errors: empty
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: notEmpty
''');

    // Add the missing `;`.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: ChangeContentOverlay([
          SourceEdit(9, 0, ';'),
        ]),
      }).toRequest('0'),
    );

    // A new errors notification was received, no errors.
    await server.onAnalysisComplete;
    assertNotificationsText(r'''
AnalysisErrors
  file: /home/test/lib/test.dart
  errors: empty
''');
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
    newFile(testFilePath, initialContent);

    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;

    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay(initialContent),
      }).toRequest('0'),
    );

    var response = await handleRequest(
      AnalysisUpdateContentParams({
        testFile.path: ChangeContentOverlay([edit]),
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
      await pumpEventQueue();
      await server.onAnalysisComplete;
    }
  }
}

@reflectiveTest
class SetSubscriptionsTest extends PubPackageAnalysisServerTest {
  Map<File, List<HighlightRegion>> filesHighlights = {};

  final Completer<void> _resultsAvailable = Completer();

  @override
  void processNotification(Notification notification) {
    super.processNotification(notification);
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      filesHighlights[getFile(params.file)] = params.regions;
      _resultsAvailable.complete();
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('int V = 42;');
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_noSuchFile() async {
    var file = getFile('/no-such-file.dart');
    addTestFile('// no matter');
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_external() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''');
    writePackageConfig(
      convertPath('/project'),
      config: (PackageConfigFileBuilder()
        ..add(name: 'pkgA', rootPath: convertPath('/packages/pkgA'))),
    );
    //
    addTestFile('''
import 'package:pkgA/libA.dart';
void f() {
  new A();
}
''');
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_inRoot() async {
    var pkgA = convertPath('/pkgA');
    var pkgB = convertPath('/pkgA');
    var pkgFileA = newFile('$pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''');
    newFile('$pkgA/lib/libB.dart', '''
import 'package:pkgA/libA.dart';
void f() {
  new A();
}
''');
    // add 'pkgA' and 'pkgB' as projects
    await setRoots(included: [pkgA, pkgB], excluded: []);
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFileA], isNull);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFileA);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFileA], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_notUsed() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', '''
library lib_a;
class A {}
''');
    writePackageConfig(
      convertPath('/project'),
      config: (PackageConfigFileBuilder()
        ..add(name: 'pkgA', rootPath: convertPath('/packages/pkgA'))),
    );
    //
    addTestFile('// no "pkgA" reference');
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // make it a priority file, so make analyzable
    server.setPriorityFiles('0', [pkgFile.path]);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  Future<void> test_afterAnalysis_sdkFile() async {
    var file = getFile('/sdk/lib/core/core.dart');
    addTestFile('// no matter');
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[file], isNull);
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isNotEmpty);
  }

  Future<void> test_beforeAnalysis() async {
    addTestFile('int V = 42;');
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_sentToPlugins() async {
    if (!AnalysisServer.supportsPlugins) return;
    addTestFile('int V = 42;');
    // subscribe
    await addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    var params = pluginManager.analysisSetSubscriptionsParams!;
    var subscriptions = params.subscriptions;
    expect(subscriptions, hasLength(1));
    var files = subscriptions[plugin.AnalysisService.HIGHLIGHTS];
    expect(files, [testFile.path]);
  }
}

class _AnalysisDomainTest extends PubPackageAnalysisServerTest {
  final configuration = _NotificationPrinterConfiguration();
  final List<(String, Object)> notifications = [];

  void assertNotificationsText(String expected) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    _NotificationPrinter(
      configuration: configuration,
      resourceProvider: resourceProvider,
      sink: sink,
    ).writeNotifications(notifications);
    notifications.clear();

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
    }
    expect(actual, expected);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      var decoded = AnalysisFlushResultsParams.fromNotification(notification);
      notifications.add((notification.event, decoded));
    }
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      notifications.add((notification.event, decoded));
    }
  }

  /// Create files with a content that has a compile time error.
  void _createFilesWithErrors(List<String> paths) {
    for (var path in paths) {
      newFile(path, 'error');
    }
  }
}

class _NotificationPrinter {
  final _NotificationPrinterConfiguration configuration;
  final ResourceProvider resourceProvider;
  final TreeStringSink sink;

  _NotificationPrinter({
    required this.configuration,
    required this.resourceProvider,
    required this.sink,
  });

  void writeNotifications(List<(String, Object)> notifications) {
    for (var entry in notifications) {
      _writeNotification(entry.$1, entry.$2);
    }
  }

  void _writelnFile(String path, {String? name}) {
    sink.writeIndentedLine(() {
      if (name != null) {
        sink.write('$name: ');
      }
      var file = resourceProvider.getFile(path);
      sink.write(file.posixPath);
    });
  }

  void _writeNotification(String event, Object notification) {
    switch (notification) {
      case AnalysisFlushResultsParams():
        var files = notification.files.sorted();
        sink.writeElements('AnalysisFlush', files, _writelnFile);
      case AnalysisErrorsParams():
        sink.writelnWithIndent('AnalysisErrors');
        sink.withIndent(() {
          _writelnFile(name: 'file', notification.file);
          if (configuration.withAnalysisErrorDetails) {
            throw UnimplementedError();
          } else if (notification.errors.isNotEmpty) {
            sink.writelnWithIndent('errors: notEmpty');
          } else {
            sink.writelnWithIndent('errors: empty');
          }
        });
      default:
        throw UnimplementedError('${notification.runtimeType}');
    }
  }
}

class _NotificationPrinterConfiguration {
  bool withAnalysisErrorDetails = false;
}
