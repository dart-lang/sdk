// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  // Skip on Windows.
  if (Platform.isWindows) {
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(BlazeChangesTest);
  });
}

@reflectiveTest
class BlazeChangesTest extends AbstractAnalysisServerIntegrationTest {
  var processedNotification = Completer<void>();

  /// Path to the `command.log` file.
  ///
  /// Writing to it should trigger our change detection to run.
  late String commandLogPath;

  late String blazeRoot;
  late String tmpPath;
  late String workspacePath;
  late String blazeOutPath;
  late String blazeBinPath;
  late String blazeGenfilesPath;
  late Directory oldSourceDirectory;

  String inTmpDir(String relative) =>
      path.join(tmpPath, relative.replaceAll('/', path.separator));

  String inWorkspace(String relative) =>
      path.join(workspacePath, relative.replaceAll('/', path.separator));

  @override
  Future<void> setUp() async {
    await super.setUp();
    oldSourceDirectory = sourceDirectory;

    tmpPath = Directory(Directory.systemTemp
            .createTempSync('analysisServer')
            .resolveSymbolicLinksSync())
        .path;
    workspacePath = inTmpDir('workspace_root');
    writeFile(inWorkspace(file_paths.blazeWorkspaceMarker), '');

    sourceDirectory = Directory(inWorkspace('third_party/dart/project'));
    sourceDirectory.createSync(recursive: true);

    blazeRoot = inTmpDir('blaze_root');
    Directory(blazeRoot).createSync(recursive: true);

    blazeOutPath = '$blazeRoot/execroot/blaze_workspace/blaze-out';
    blazeBinPath = '$blazeRoot/execroot/blaze_workspace/blaze-out/bin';
    blazeGenfilesPath =
        '$blazeRoot/execroot/blaze_workspace/blaze-out/genfiles';

    Directory(inTmpDir(blazeOutPath)).createSync(recursive: true);
    Directory(inTmpDir(blazeBinPath)).createSync(recursive: true);
    Directory(inTmpDir(blazeGenfilesPath)).createSync(recursive: true);

    commandLogPath = inTmpDir('$blazeRoot/command.log');
  }

  @override
  Future<void> tearDown() async {
    Directory(tmpPath).deleteSync(recursive: true);
    sourceDirectory = oldSourceDirectory;
    await super.tearDown();
  }

  // Add a bit more time -- the isolate take a while to start when the test is
  // not run from a snapshot.
  @TestTimeout(Timeout.factor(2))
  Future<void> test_blazeChanges() async {
    await testChangesImpl('blaze');
  }

  Future<void> testChangesImpl(String prefix) async {
    var testFile = inWorkspace('${sourceDirectory.path}/lib/test.dart');

    var errors = <AnalysisError>[];
    onAnalysisErrors.listen((event) {
      if (event.file == testFile) {
        errors.addAll(event.errors);
        processedNotification.complete();
      }
    });
    resetCompleterAndErrors() async {
      // This is necessary because our polling uses modification timestamps
      // whose resolution seems to be too small for a test like this (i.e., we
      // write to the `command.log` file, but if the modification timestamp
      // doesn't change, we won't detect the change).
      await Future.delayed(Duration(seconds: 1));
      errors.clear();
      processedNotification = Completer();
    }

    writeFile(testFile, r'''
import 'generated.dart';
void f() { my_fun(); }
''');
    await standardAnalysisSetup();

    await processedNotification.future;
    expect(errors, isNotEmpty);
    var error = errors.singleWhere((e) => e.code == 'uri_does_not_exist',
        orElse: () => throw "'uri_does_not_exist' error was not found");
    expect(error.message, contains('generated.dart'));

    // This seems to be necessary (at least when running the test from source),
    // because it takes a while for the watcher isolate to start.
    await Future.delayed(Duration(seconds: 10));

    await resetCompleterAndErrors();
    var generatedFilePath = inWorkspace(
        '$blazeGenfilesPath/third_party/dart/project/lib/generated.dart');
    writeFile(generatedFilePath, 'my_fun() {}');
    _createSymlinks(prefix);
    writeFile(commandLogPath, 'Build completed successfully');

    await processedNotification.future;
    expect(errors, isEmpty);

    // Now let's write a file that does not define `my_fun` -- we should get an
    // error again.
    await resetCompleterAndErrors();
    writeFile(generatedFilePath, 'different_fun() {}');
    writeFile(commandLogPath, 'Build completed');

    await processedNotification.future;
    expect(errors, isNotEmpty);

    // Now delete the file completely.
    await resetCompleterAndErrors();
    File(generatedFilePath).deleteSync();
    _deleteSymlinks(prefix);
    writeFile(commandLogPath, 'Build did NOT complete successfully');

    await processedNotification.future;
    expect(errors, isNotEmpty);

    // And finally re-add the correct file -- errors should go away once again.
    await resetCompleterAndErrors();
    writeFile(generatedFilePath, 'my_fun() {}');
    _createSymlinks(prefix);
    writeFile(commandLogPath, 'Build completed successfully');

    await processedNotification.future;
    expect(errors, isEmpty);
  }

  void _createSymlinks(String prefix) {
    Link(inWorkspace('$prefix-out')).createSync(blazeOutPath);
    Link(inWorkspace('$prefix-bin')).createSync(blazeBinPath);
    Link(inWorkspace('$prefix-genfiles')).createSync(blazeGenfilesPath);
  }

  void _deleteSymlinks(String prefix) {
    Link(inWorkspace('$prefix-out')).deleteSync();
    Link(inWorkspace('$prefix-bin')).deleteSync();
    Link(inWorkspace('$prefix-genfiles')).deleteSync();
  }
}
