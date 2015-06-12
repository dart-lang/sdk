// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library PlatformExecutableTest;

import "dart:io";

const _SCRIPT_KEY = '_test_script';

void expectEquals(a, b) {
  if (a != b) {
    throw 'Expected: $a\n'
          '  Actual: $b';
  }
}

void verify(String exePath, {String altPath}) {
  var env = {_SCRIPT_KEY: 'yes'};
  if (altPath != null) {
    env['PATH'] = altPath;
  }

  var processResult = Process.runSync(exePath, [scriptPath],
      includeParentEnvironment: false, runInShell: true, environment: env);

  if (processResult.exitCode != 0) {
    throw 'Error with process\n'
          '$scriptPath'
          'Exit code: ${processResult.exitCode}\n'
          '   STDOUT: ${processResult.stdout}\n'
          '   STDERR: ${processResult.stderr}\n';
  }

  var result = processResult.stdout.trim();
  expectEquals(Platform.executable, result);
}

void testDartExecShouldNotBeInCurrentDir() {
  var type = FileSystemEntity.typeSync(platformExeName);
  expectEquals(FileSystemEntityType.NOT_FOUND, type);
}

void testShouldSucceedWithEmptyPathEnvironment() {
  var command = Platform.isWindows ? 'cmd' : 'ls';
  Process.runSync(command, [],
                  includeParentEnvironment: false,
                  environment: {_SCRIPT_KEY: 'yes', 'PATH': ''});
}

void testShouldSucceedWithSourcePlatformExecutable() {
  verify(Platform.executable);
}

void testExeSymLinked(Directory dir) {
  var dirUri = new Uri.directory(dir.path);
  var link = new Link.fromUri(dirUri.resolve('dart_exe_link'));
  link.createSync(Platform.executable);
  verify(link.path);
}

void testPathToDirWithExeSymLinked(Directory dir) {
  var dirUri = new Uri.directory(dir.path);
  var link = new Link.fromUri(dirUri.resolve('dart_exe_link'));
  link.createSync(Platform.executable);
  verify('dart_exe_link', altPath: dir.path);
}

/// Create a sym-link to the SDK directory and run 'dart' from that path
void testExeDirSymLinked(Directory dir) {
  var dirUri = new Uri.directory(dir.path);

  var linkDirUri = dirUri.resolve('dart_bin_dir_link');
  var link = new Link.fromUri(linkDirUri);

  var exeFile = new File(Platform.executable);

  link.createSync(exeFile.parent.path);

  var linkedBin =
      new Uri.directory(linkDirUri.toFilePath()).resolve(platformExeName);

  verify(linkedBin.toFilePath());
}

void testPathPointsToSymLinkedSDKPath(Directory dir) {
  var dirUri = new Uri.directory(dir.path);

  var linkDirUri = dirUri.resolve('dart_bin_dir_link');
  var link = new Link.fromUri(linkDirUri);

  var exeFile = new File(Platform.executable);

  link.createSync(exeFile.parent.path);

  verify(platformExeName, altPath: link.path);
}

void testPathToSDKDir() {
  var exeFile = new File(Platform.executable);
  var binDirPath = exeFile.parent.path;

  verify(platformExeName, altPath: binDirPath);
}

void withTempDir(void test(Directory dir)) {
  var tempDir = Directory.systemTemp.createTempSync('dart.sdk.test.');
  try {
    test(tempDir);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

String get platformExeName {
  var raw = new Uri.file(Platform.executable);
  return raw.pathSegments.last;
}

String get scriptPath => Platform.script.toFilePath();

void main() {
  if (Platform.environment.containsKey(_SCRIPT_KEY)) {
    print(Platform.executable);
    return;
  }

  testDartExecShouldNotBeInCurrentDir();
  testShouldSucceedWithSourcePlatformExecutable(); /// 00: ok
  // dart:io does not support linking to files in Windows.
  if (!Platform.isWindows) {
    withTempDir(testExeSymLinked); /// 01: ok
  }
  withTempDir(testExeDirSymLinked); /// 02: ok
  testPathToSDKDir(); /// 03: ok
  withTempDir(testPathPointsToSymLinkedSDKPath); /// 04: ok
  // dart:io does not support linking to files in Windows.
  if (!Platform.isWindows) {
    withTempDir(testPathToDirWithExeSymLinked); /// 05: ok
  }
  testShouldSucceedWithEmptyPathEnvironment(); /// 06: ok
}
