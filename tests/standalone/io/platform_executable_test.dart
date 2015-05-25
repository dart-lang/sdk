// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library PlatformExecutableTest;

import "dart:io";

import "package:expect/expect.dart";

const CLIENT_SCRIPT = "platform_executable_script.dart";

void verify(String exePath, {String altPath}) {
  var env = {};
  if (altPath != null) {
    env['PATH'] = altPath;
  }

  var processResult = Process.runSync(exePath, [scriptPath],
      includeParentEnvironment: false, runInShell: true, environment: env);

  var result = processResult.stdout.trim();
  Expect.equals(Platform.executable, result);
}

void testDartExecShouldNotBeInCurrentDir() {
  var type = FileSystemEntity.typeSync(platformExeName);
  Expect.equals(FileSystemEntityType.NOT_FOUND, type);
}

void testShouldFailOutsidePath() {
  Expect.throws(() => Process.runSync(platformExeName, [scriptPath],
      includeParentEnvironment: false));
}

void testShouldSucceedWithSourcePlatformExecutable() {
  print('*** Running normally');
  verify(Platform.executable);
}

void testExeSymLinked(Directory dir) {
  var dirUri = new Uri.directory(dir.path);
  var link = new Link.fromUri(dirUri.resolve('dart_exe_link'));
  link.createSync(Platform.executable);
  print('*** Creating a sym-link to the executable');
  verify(link.path);
}

void testPathToDirWithExeSymLinked(Directory dir) {
  var dirUri = new Uri.directory(dir.path);
  var link = new Link.fromUri(dirUri.resolve('dart_exe_link'));
  link.createSync(Platform.executable);
  print('*** Path to a directory that contains a sym-link to dart bin');
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

  print('*** Running in a sym-linked directory');
  verify(linkedBin.toFilePath());
}

void testPathPointsToSymLinkedSDKPath(Directory dir) {
  var dirUri = new Uri.directory(dir.path);

  var linkDirUri = dirUri.resolve('dart_bin_dir_link');
  var link = new Link.fromUri(linkDirUri);

  var exeFile = new File(Platform.executable);

  link.createSync(exeFile.parent.path);

  print('*** Path points to a sym-linked SDK dir');
  verify(platformExeName, altPath: link.path);
}

void testPathToSDKDir() {
  var exeFile = new File(Platform.executable);
  var binDirPath = exeFile.parent.path;

  print('*** Running with PATH env set to environment - fixed in 16994 - thanks!');
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

String get scriptPath => Platform.script.resolve(CLIENT_SCRIPT).toString();

void main() {
  testDartExecShouldNotBeInCurrentDir();
  testShouldFailOutsidePath();
  testShouldSucceedWithSourcePlatformExecutable(); /// 00: ok
  withTempDir(testExeSymLinked); /// 01: ok
  withTempDir(testExeDirSymLinked); /// 02: ok
  testPathToSDKDir(); /// 03: ok
  withTempDir(testPathPointsToSymLinkedSDKPath); /// 04: ok
  withTempDir(testPathToDirWithExeSymLinked); /// 05: ok
}
