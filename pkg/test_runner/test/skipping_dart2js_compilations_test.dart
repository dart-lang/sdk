// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=skipping_dart2js_compilations_helper.dart

/*
 * This test makes sure that the "skipping Dart2Js compilations if the output is
 * already up to date" feature does work as it should.
 * Therefore this test ensures that compilations are only skipped if the last
 * modified date of the output of a dart2js compilation is newer than
 *   - the dart application to compile (including it's dependencies)
 *   - the dart2js snapshot
 * Furthermore it ensures that a compilation is not skipped if any of the
 * necessary files could not be found (dart2js snapshots, previous dart2js
 * output (+deps file), dart application)
 */

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';

import 'package:test_runner/src/command.dart';
import 'package:test_runner/src/command_output.dart';
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/repository.dart';
import 'package:test_runner/src/test_case.dart';

/// This class is reponsible for setting up the files necessary for this test
/// as well as touching a file.
class FileUtils {
  Directory tempDir;
  File testJs;
  File testJsDeps;
  File testDart;
  File testSnapshot;

  FileUtils(
      {bool createJs,
      bool createJsDeps,
      bool createDart,
      bool createSnapshot}) {
    tempDir = Directory.systemTemp
        .createTempSync('dart_skipping_dart2js_compilations');
    if (createJs) {
      testJs = _createFile(testJsFilePath);
      _writeToFile(testJs, "test.js content");
    }
    if (createSnapshot) {
      testSnapshot = _createFile(testSnapshotFilePath);
      _writeToFile(testSnapshot, "dart2js snapshot");
    }
    if (createDart) {
      testDart = _createFile(testDartFilePath);
      _writeToFile(testDart, "dart code");
    }
    if (createJsDeps) {
      testJsDeps = _createFile(testJsDepsFilePath);
      var path = Path(tempDir.path).append("test.dart").absolute;
      _writeToFile(testJsDeps, "file://$path");
    }
  }

  void cleanup() {
    if (testJs != null) testJs.deleteSync();
    if (testJsDeps != null) testJsDeps.deleteSync();
    if (testDart != null) testDart.deleteSync();
    if (testSnapshot != null) testSnapshot.deleteSync();

    // if the script did run, it created this file, so we need to delete it
    var file = File(scriptOutputPath.toNativePath());
    if (file.existsSync()) {
      file.deleteSync();
    }

    tempDir.deleteSync();
  }

  Path get scriptOutputPath {
    return Path(tempDir.path).append('created_if_command_did_run.txt').absolute;
  }

  Path get testDartFilePath {
    return Path(tempDir.path).append('test.dart').absolute;
  }

  Path get testJsFilePath {
    return Path(tempDir.path).append('test.js').absolute;
  }

  Path get testJsDepsFilePath {
    return Path(tempDir.path).append('test.js.deps').absolute;
  }

  Path get testSnapshotFilePath {
    return Path(tempDir.path).append('test_dart2js.snapshot').absolute;
  }

  void touchFile(File file) {
    _writeToFile(file, _readFile(file));
  }

  void _writeToFile(File file, String content) {
    if (content != null) {
      var fd =
          File(file.resolveSymbolicLinksSync()).openSync(mode: FileMode.write);
      fd.writeStringSync(content);
      fd.closeSync();
    }
  }

  String _readFile(File file) {
    return file.readAsStringSync();
  }

  File _createFile(Path path) {
    var file = File(path.toNativePath());
    file.createSync();
    return file;
  }
}

class CommandCompletedHandler {
  FileUtils fileUtils;
  final bool _shouldHaveRun;

  CommandCompletedHandler(this.fileUtils, this._shouldHaveRun);

  void processCompletedTest(CommandOutput output) {
    Expect.equals(0, output.exitCode);
    Expect.equals(0, output.stderr.length);
    if (_shouldHaveRun) {
      Expect.equals(0, output.stdout.length);
      Expect.isTrue(
          File(fileUtils.scriptOutputPath.toNativePath()).existsSync());
    } else {
      Expect.isFalse(
          File(fileUtils.scriptOutputPath.toNativePath()).existsSync());
    }
  }
}

Command makeCompilationCommand(String testName, FileUtils fileUtils) {
  var createFileScript = Platform.script
      .resolve('skipping_dart2js_compilations_helper.dart')
      .toFilePath();
  var executable = Platform.executable;
  var arguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..add(createFileScript)
    ..add(fileUtils.scriptOutputPath.toNativePath());
  var bootstrapDeps = [Uri.parse("file://${fileUtils.testSnapshotFilePath}")];
  return CompilationCommand('dart2js', fileUtils.testJsFilePath.toNativePath(),
      bootstrapDeps, executable, arguments, {},
      alwaysCompile: false);
}

void main() {
  // This script is in [sdk]/pkg/test_runner/test.
  Repository.uri = Platform.script.resolve('../../..');

  var fs_noTestJs = FileUtils(
      createJs: false,
      createJsDeps: true,
      createDart: true,
      createSnapshot: true);
  var fs_noTestJsDeps = FileUtils(
      createJs: true,
      createJsDeps: false,
      createDart: true,
      createSnapshot: true);
  var fs_noTestDart = FileUtils(
      createJs: true,
      createJsDeps: true,
      createDart: false,
      createSnapshot: true);
  var fs_noTestSnapshot = FileUtils(
      createJs: true,
      createJsDeps: true,
      createDart: true,
      createSnapshot: false);
  var fs_notUpToDate_snapshot = FileUtils(
      createJs: true,
      createJsDeps: true,
      createDart: true,
      createSnapshot: true);
  var fs_notUpToDate_dart = FileUtils(
      createJs: true,
      createJsDeps: true,
      createDart: true,
      createSnapshot: true);
  var fs_upToDate = FileUtils(
      createJs: true,
      createJsDeps: true,
      createDart: true,
      createSnapshot: true);
  void cleanup() {
    fs_noTestJs.cleanup();
    fs_noTestJsDeps.cleanup();
    fs_noTestDart.cleanup();
    fs_noTestSnapshot.cleanup();
    fs_notUpToDate_snapshot.cleanup();
    fs_notUpToDate_dart.cleanup();
    fs_upToDate.cleanup();
  }

  void touchFilesAndRunTests() {
    fs_notUpToDate_snapshot.touchFile(fs_notUpToDate_snapshot.testSnapshot);
    fs_notUpToDate_dart.touchFile(fs_notUpToDate_dart.testDart);
    fs_upToDate.touchFile(fs_upToDate.testJs);

    Future runTest(String name, FileUtils fileUtils, bool shouldRun) {
      var completedHandler = CommandCompletedHandler(fileUtils, shouldRun);
      var command = makeCompilationCommand(name, fileUtils) as ProcessCommand;
      var process = RunningProcess(command, 60);
      return process.run().then((CommandOutput output) {
        completedHandler.processCompletedTest(output);
      });
    }

    // We run the tests in sequence, so that if one of them fails we clean up
    // everything and throw.
    runTest("fs_noTestJs", fs_noTestJs, true).then((_) {
      return runTest("fs_noTestJsDeps", fs_noTestJsDeps, true);
    }).then((_) {
      return runTest("fs_noTestDart", fs_noTestDart, true);
    }).then((_) {
      return runTest("fs_noTestSnapshot", fs_noTestSnapshot, true);
    }).then((_) {
      return runTest("fs_notUpToDate_snapshot", fs_notUpToDate_snapshot, true);
    }).then((_) {
      return runTest("fs_notUpToDate_dart", fs_notUpToDate_dart, true);
    }).then((_) {
      // This is the only test where all dependencies are present and the
      // test.js file is newer than all the others. So we pass 'false' for
      // shouldRun.
      return runTest("fs_upToDate", fs_upToDate, false);
    }).catchError((error) {
      cleanup();
      throw error;
    }).then((_) {
      cleanup();
    });
  }

  // We need to wait some time to make sure that the files we 'touch' get a
  // bigger timestamp than the old ones
  Timer(const Duration(seconds: 1), touchFilesAndRunTests);
}
