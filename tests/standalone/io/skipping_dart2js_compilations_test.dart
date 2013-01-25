// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * This test makes sure that the "skipping Dart2Js compilations if the output is
 * already up to date" feature does work as it should.
 * Therefore this test ensures that compilations are only skipped if the last
 * modified date of the output of a dart2js compilation is newer than
 *   - the the dart application to compile (including it's dependencies)
 *   - the dart2js snapshot
 * Furtheremore it ensure that a compilations is not skipped if any of the
 * necessary files could not be found (dart2js snapshots, previous dart2js
 * output (+deps file), dart application)
 */

import 'dart:async';
import 'dart:io';
import 'dart:uri';
import '../../../tools/testing/dart/test_suite.dart' as suite;
import '../../../tools/testing/dart/test_runner.dart' as runner;
import '../../../tools/testing/dart/test_options.dart' as options;
import '../../../tools/testing/dart/status_file_parser.dart' as status;

/**
 * This class is reponsible for setting up the files necessary for this test
 * as well as touching a file.
 */
class FileUtils {
  Directory tempDir;
  File testJs;
  File testJsDeps;
  File testDart;
  File testSnapshot;

  FileUtils({bool createJs,
             bool createJsDeps,
             bool createDart,
             bool createSnapshot}) {
    tempDir = new Directory('').createTempSync();
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
      var path = suite.TestUtils.absolutePath(new Path(tempDir.path))
          .append("test.dart");
      _writeToFile(testJsDeps, "file://$path");
    }
  }

  void cleanup() {
    if (testJs != null) testJs.deleteSync();
    if (testJsDeps != null) testJsDeps.deleteSync();
    if (testDart != null) testDart.deleteSync();
    if (testSnapshot != null) testSnapshot.deleteSync();

    // if the script did run, it created this file, so we need to delete it
    File file = new File(scriptOutputPath.toNativePath());
    if (file.existsSync()) {
      file.deleteSync();
    }

    tempDir.deleteSync();
  }

  Path get scriptOutputPath {
    return suite.TestUtils.absolutePath(new Path(tempDir.path)
        .append('created_if_command_did_run.txt'));
  }

  Path get testDartFilePath {
    return suite.TestUtils.absolutePath(new Path(tempDir.path)
        .append('test.dart'));
  }

  Path get testJsFilePath {
    return suite.TestUtils.absolutePath(new Path(tempDir.path)
        .append('test.js'));
  }

  Path get testJsDepsFilePath {
    return suite.TestUtils.absolutePath(new Path(tempDir.path)
        .append('test.js.deps'));
  }

  Path get testSnapshotFilePath {
    return suite.TestUtils.absolutePath(new Path(tempDir.path)
        .append('test_dart2js.snapshot'));
  }

  void touchFile(File file) {
    _writeToFile(file, _readFile(file));
  }

  void _writeToFile(File file, String content) {
    if (content != null) {
      var fd = new File(file.fullPathSync()).openSync(FileMode.WRITE);
      fd.writeStringSync(content);
      fd.closeSync();
    }
  }

  String _readFile(File file) {
    return file.readAsStringSync();
  }

  File _createFile(Path path) {
    var file = new File(path.toNativePath());
    file.createSync();
    return file;
  }
}

class TestCompletedHandler {
  FileUtils fileUtils;
  DateTime _expectedTimestamp;
  bool _shouldHaveRun;

  TestCompletedHandler(FileUtils this.fileUtils, bool this._shouldHaveRun);

  void processCompletedTest(runner.TestCase testCase) {
    var output = testCase.lastCommandOutput;

    Expect.isFalse(output.unexpectedOutput);
    Expect.isTrue(output.stderr.length == 0);
    if (_shouldHaveRun) {
      Expect.isTrue(output.stdout.length == 0);
      Expect.isTrue(new File(fileUtils.scriptOutputPath.toNativePath())
          .existsSync());
    } else {
      Expect.isFalse(new File(fileUtils.scriptOutputPath.toNativePath())
          .existsSync());
    }
    fileUtils.cleanup();
  }
}

runner.TestCase makeTestCase(String testName,
                             TestCompletedHandler completedHandler) {
  var fileUtils = completedHandler.fileUtils;
  var config = new options.TestOptionsParser().parse(['--timeout', '2'])[0];
  var scriptDirPath = new Path(new Options().script).directoryPath;
  var createFileScript = scriptDirPath.
      append('skipping_dart2js_compilations_helper.dart').toNativePath();
  var executable = new Options().executable;
  var arguments = [createFileScript, fileUtils.scriptOutputPath.toNativePath()];
  var bootstrapDeps = [
      new Uri("file://${fileUtils.testSnapshotFilePath}")];
  var commands = [new runner.CompilationCommand(
      fileUtils.testJsFilePath.toNativePath(),
      false,
      bootstrapDeps,
      executable,
      arguments)];
  return new runner.TestCase(
      testName,
      commands,
      config,
      completedHandler.processCompletedTest,
      new Set<String>.from([status.PASS]));
}

void main() {
  var fs_noTestJs = new FileUtils(createJs: false,
                                  createJsDeps: true,
                                  createDart: true,
                                  createSnapshot: true);
  var fs_noTestJsDeps = new FileUtils(createJs: true,
                                      createJsDeps: false,
                                      createDart: true,
                                      createSnapshot: true);
  var fs_noTestDart = new FileUtils(createJs: true,
                                    createJsDeps: true,
                                    createDart: false,
                                    createSnapshot: true);
  var fs_noTestSnapshot = new FileUtils(createJs: true,
                                        createJsDeps: true,
                                        createDart: true,
                                        createSnapshot: false);
  var fs_notUpToDate_snapshot = new FileUtils(createJs: true,
                                              createJsDeps: true,
                                              createDart: true,
                                              createSnapshot: true);
  var fs_notUpToDate_dart = new FileUtils(createJs: true,
                                          createJsDeps: true,
                                          createDart: true,
                                          createSnapshot: true);
  var fs_upToDate = new FileUtils(createJs: true,
                                  createJsDeps: true,
                                  createDart: true,
                                  createSnapshot: true);

  void touchFilesAndRunTests(Timer unused) {
    fs_notUpToDate_snapshot.touchFile(fs_notUpToDate_snapshot.testSnapshot);
    fs_notUpToDate_dart.touchFile(fs_notUpToDate_dart.testDart);
    fs_upToDate.touchFile(fs_upToDate.testJs);

    void runTest(String name, FileUtils fileUtils, bool shouldRun) {
      new runner.RunningProcess(makeTestCase(name,
          new TestCompletedHandler(fileUtils, shouldRun))).start();
    }
    runTest("fs_noTestJs", fs_noTestJs, true);
    runTest("fs_noTestJsDeps", fs_noTestJsDeps, true);
    runTest("fs_noTestDart", fs_noTestDart, true);
    runTest("fs_noTestSnapshot", fs_noTestSnapshot, true);
    runTest("fs_notUpToDate_snapshot", fs_notUpToDate_snapshot, true);
    runTest("fs_notUpToDate_dart", fs_notUpToDate_dart, true);
    // This is the only test where all dependencies are present and the test.js
    // file is newer than all the others. So we pass 'false' for shouldRun.
    runTest("fs_upToDate", fs_upToDate, false);
  }
  // We need to wait some time to make sure that the files we 'touch' get a
  // bigger timestamp than the old ones
  new Timer(1000, touchFilesAndRunTests);
}
